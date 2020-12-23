#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

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

        bool findBestOrder(Order &, Order &);

        void deleteAllOrders();
        void deletePendingOrders();

    protected:
        OrderFind orderFind_;

        static const double lossLimiterTime_;
        static const double maxAllowedLossesPercent_;

    private:
        static const int smallerStopLossBufferPips_;

        void deduplicateDiscriminatedOrders(Discriminator);
        void deleteOrdersFromList(Order & []);
        void deleteSingleOrder(Order &);
};

const double OrderManage::lossLimiterTime_ = 8 * 3600;
const double OrderManage::maxAllowedLossesPercent_ = PERCENT_RISK * 5 / 100;

const int OrderManage::smallerStopLossBufferPips_ = 1;

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
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    return (ArraySize(orders) > 0);
}

/**
 * Ensures that only one open or correlated pending order at a time is present.
 * If it finds more orders, it deletes the worst ones.
 */
void OrderManage::deduplicateOrders() {
    deduplicateDiscriminatedOrders(Max);
    deduplicateDiscriminatedOrders(Min);
}

/**
 * Deduplicates correlated orders in one direction.
 */
void OrderManage::deduplicateDiscriminatedOrders(Discriminator discriminator) {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily());

    orderFilter.type.setFilterType(Exclude);

    if (discriminator == Max) {
        orderFilter.type.add(OP_SELLSTOP, OP_SELLLIMIT);
    } else {
        orderFilter.type.add(OP_BUYSTOP, OP_BUYLIMIT);
    }

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    int bestOrderIndex = 0;

    for (int i = 0; i < ArraySize(orders); i++) {
        for (int j = 0; j < ArraySize(orders); j++) {
            if (i != j) {
                bestOrderIndex = findBestOrder(orders[i], orders[j]) ? i : j;
            }
        }
    }

    ArrayRemove(orders, bestOrderIndex);

    if (ArraySize(orders) > 0) {
        deleteOrdersFromList(orders);
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
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    if (ArraySize(orders) > 0) {
        deleteAllOrders();

        const string exceptionMessage = StringConcatenate(
            "Emergency switchOff invoked for magicNumber: ", orders[0].magicNumber);

        if (UNIT_TESTS_COMPLETED) {
            ThrowFatalException(__FUNCTION__, exceptionMessage);
        } else {
            ThrowException(__FUNCTION__, exceptionMessage);
        }
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
    orderFilter.closeTime.add(TimeCurrent() - lossLimiterTime_);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter, MODE_HISTORY);

    double totalLosses = 0;

    for (int order = 0; order < ArraySize(orders); order++) {
        totalLosses -= orders[order].profit;

        if (totalLosses > AccountEquity() * maxAllowedLossesPercent_) {
            deleteAllOrders();

            const string exceptionMessage = StringConcatenate(
                "Emergency switchOff invoked for total losses: ", totalLosses);

            if (UNIT_TESTS_COMPLETED) {
                ThrowFatalException(__FUNCTION__, exceptionMessage);
            } else {
                ThrowException(__FUNCTION__, exceptionMessage);
            }

            return;
        }
    }
}

/**
 * Finds the best of two orders by comparing the type and the stopLoss size. Returns true if the first one is better.
 */
bool OrderManage::findBestOrder(Order & order1, Order & order2) {
    if (order1.type == OP_BUY || order1.type == OP_SELL) {
        return true;
    }
    if (order2.type == OP_BUY || order2.type == OP_SELL) {
        return false;
    }

    if (order1.getStopLossPips() < order2.getStopLossPips() + smallerStopLossBufferPips_) {
        return true;
    }

    return false;
}

/**
 * Delete all the orders of the current symbol and period.
 */
void OrderManage::deleteAllOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(MagicNumber());
    orderFilter.symbol.add(Symbol());

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    deleteOrdersFromList(orders);
}

/**
 * Delete all the pending orders of the current symbol and period.
 */
void OrderManage::deletePendingOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(MagicNumber());
    orderFilter.symbol.add(Symbol());

    orderFilter.type.setFilterType(Exclude);
    orderFilter.type.add(OP_BUY, OP_SELL);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

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
    if (!UNIT_TESTS_COMPLETED) {
        // Needed for unit tests
        orderFind_.deleteMockedOrder(order);
        return;
    }

    const int ticket = order.ticket;
    bool deletedOrder = false;

    if (order.type == OP_BUY || order.type == OP_SELL) {
        deletedOrder = OrderClose(ticket, order.lots, order.closePrice, 3);
    } else {
        deletedOrder = OrderDelete(ticket);
    }

    if (deletedOrder) {
        Print(__FUNCTION__, " | Deleted order: ", ticket);
    } else {
        ThrowException(__FUNCTION__, StringConcatenate("Failed to delete order: ", ticket));
    }
}
