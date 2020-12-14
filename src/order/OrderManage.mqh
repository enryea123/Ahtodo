#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "Order.mqh"
#include "OrderFilter.mqh"
#include "OrderFind.mqh"


class OrderManage {
    public:
        bool areThereOpenOrders();

        void deduplicateOrders();
        void emergencySwitchOff();
        void lossLimiter();

        void deleteAllOrders();
        void deletePendingOrders();
        void deleteOrdersFromList(Order & []);
        void deleteSingleOrder(Order &);

    private:
        static const int lossLimiterHours_;
        static const int lossLimiterMaxPercentLoss_;
        static const int maximumOpenedOrders_;
        static const int maximumCorrelatedPendingOrders_;
};

const int OrderManage::lossLimiterHours_ = 8;
const int OrderManage::lossLimiterMaxPercentLoss_ = 5;
const int OrderManage::maximumOpenedOrders_ = 1;
const int OrderManage::maximumCorrelatedPendingOrders_ = 1;

/**
 * Checks if there are any already opened orders,
 * across all timeframes and correlated symbols.
 */
bool OrderManage::areThereOpenOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily());
    orderFilter.type.add(OP_BUY, OP_SELL);

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter);

    return (ArraySize(orders) > 0);
}

/**
 * Ensures that only one open or correlated pending order at a time is present.
 * If it finds more orders, it deletes the duplicated ones, starting from the newests.
 */
void OrderManage::deduplicateOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily());

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter);

    int pendingOrdersBuy = 0;
    int pendingOrdersSell = 0;

    for (int order = 0; order < ArraySize(orders); order++) {
        const int type = orders[order].type;

        if (type == OP_BUY || type == OP_SELL) {
            if (ArraySize(orders) != maximumOpenedOrders_) {
                ArrayRemove(orders, order);
                deleteOrdersFromList(orders);
            }
            return;
        }

        if (type == OP_BUYSTOP || type == OP_BUYLIMIT) {
            pendingOrdersBuy++;

            if (pendingOrdersBuy > maximumCorrelatedPendingOrders_) {
                deleteSingleOrder(orders[order]);
                pendingOrdersBuy--;
            }
        } else if (type == OP_SELLSTOP || type == OP_SELLLIMIT) {
            pendingOrdersSell++;

            if (pendingOrdersSell > maximumCorrelatedPendingOrders_) {
                deleteSingleOrder(orders[order]);
                pendingOrdersSell--;
            }
        }
    }
}

/**
 * Checks if an order with an unknown magicNumber exists.
 * In that case, it deletes all the orders and removes the bot.
 */
void OrderManage::emergencySwitchOff() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.setFilterType(Exclude);
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter);

    if (ArraySize(orders) > 0) {
        deleteAllOrders();

        ThrowFatalException(__FUNCTION__, StringConcatenate(
            "Emergency switchOff invoked for magicNumber: ", orders[0].magicNumber));
    }
}

/**
 * Checks if the recent losses of the bot have been too high,
 * and in that case deletes all the orders and removes the bot.
 */
void OrderManage::lossLimiter() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);

    orderFilter.profit.setFilterType(Exclude);
    orderFilter.profit.add(0);

    orderFilter.closeTime.setFilterType(Greater);
    orderFilter.closeTime.add(TimeCurrent() - lossLimiterHours_ * 3600);

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter, MODE_HISTORY);

    const double maxAllowedLosses = AccountEquity() * lossLimiterMaxPercentLoss_ * PERCENT_RISK / 100;

    double totalLosses = 0;

    for (int order = 0; order < ArraySize(orders); order++) {
        totalLosses -= orders[order].profit;

        if (totalLosses > maxAllowedLosses) {
            deleteAllOrders();
            ThrowFatalException(__FUNCTION__, StringConcatenate(
                "Emergency switchOff invoked for total losses: ", totalLosses));
            return;
        }
    }
}

/**
 * Delete all the orders of the current symbol and period.
 */
void OrderManage::deleteAllOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(BotMagicNumber());
    orderFilter.symbol.add(Symbol());

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter);

    deleteOrdersFromList(orders);
}

/**
 * Delete all the pending orders of the current symbol and period.
 */
void OrderManage::deletePendingOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(BotMagicNumber());
    orderFilter.symbol.add(Symbol());

    orderFilter.type.setFilterType(Exclude);
    orderFilter.type.add(OP_BUY, OP_SELL);

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter);

    deleteOrdersFromList(orders);
}

/**
 * Delete all the orders from a list.
 */
void OrderManage::deleteOrdersFromList(Order & orders[]) {
    for (int i = ArraySize(orders) - 1; i >= 0; i--) {
        deleteSingleOrder(orders[i]);
    }
}

/**
 * Delete a single order.
 */
void OrderManage::deleteSingleOrder(Order & order) {
    const int ticket = order.ticket;

    bool deletedOrder = false;

    if (order.type == OP_BUY || order.type == OP_SELL) {
        deletedOrder = OrderClose(ticket, order.lots, order.closePrice, 3);
    } else {
        deletedOrder = OrderDelete(ticket); /// fare che non funziona davvero nei primi 10 secondi di esecuzione (unit test), usando funzione bool gia creata
    }

    if (deletedOrder) {
        Print(__FUNCTION__, " | Deleted order: ", ticket);
    } else {
        ThrowException(__FUNCTION__, StringConcatenate("Failed to delete order: ", ticket));
    }
}
