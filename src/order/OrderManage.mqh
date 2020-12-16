#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "Order.mqh"
#include "OrderFilter.mqh"
#include "OrderFind.mqh"


class OrderManage {
    public:
        bool areThereOpenOrders();
        bool areThereRecentOrders(datetime);
        bool areThereBetterOrders(int, double, double);

        void deduplicateOrders();
        void emergencySwitchOff();
        void lossLimiter();

        void deleteAllOrders();
        void deletePendingOrders();

        static const double lossLimiterTime_;
        static const double maxAllowedLossesPercent_;

    protected:
        void deleteMockedOrder(Order &);
        void setMockedOrders();
        void setMockedOrders(Order &);
        void setMockedOrders(Order & []);
        void getMockedOrders(Order & []);

    private:
        OrderFind orderFind_;

        static const int betterSetupBufferPips_;
        static const int maximumOpenedOrders_;
        static const int maximumCorrelatedPendingOrders_;

        void deleteOrdersFromList(Order & []);
        void deleteSingleOrder(Order &);
};

const double OrderManage::lossLimiterTime_ = 8 * 3600;
const double OrderManage::maxAllowedLossesPercent_ = PERCENT_RISK * 5 / 100;

const int OrderManage::betterSetupBufferPips_ = 2;
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
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    return (ArraySize(orders) > 0);
}

/**
 * Checks if there have been any recent correlated open orders, so that it can be waited before placing new ones.
 */
bool OrderManage::areThereRecentOrders(datetime date) {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily());
    orderFilter.type.add(OP_BUY, OP_SELL);

    orderFilter.closeTime.setFilterType(Greater);
    orderFilter.closeTime.add(date);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter, MODE_HISTORY);

    if (ArraySize(orders) > 0) {
        return true;
    }

    return false;
}

/**
 * Checks if there are other pending orders. In case they are with worst setups it deletes them.
 */
bool OrderManage::areThereBetterOrders(int orderType, double stopLossSize, double sizeFactor) {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily());
    orderFilter.type.add(orderType);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    for (int order = 0; order < ArraySize(orders); order++) {
        const double openPrice = orders[order].openPrice;
        const double stopLoss = orders[order].stopLoss;
        const int period = orders[order].magicNumber - BOT_MAGIC_NUMBER;
        const string symbol = orders[order].symbol;

        const int newStopLossPips = MathRound(stopLossSize / Pips() / PeriodFactor());
        const int oldStopLossPips = MathRound(MathAbs(openPrice - stopLoss) / Pips(symbol) / PeriodFactor(period));
        const double newSizeFactorWeight = sizeFactor / PeriodFactor();
        const double oldSizeFactorWeight = getSizeFactorFromComment(orders[order].comment) / PeriodFactor(period);

        const bool isNewStopLossSmaller = (oldStopLossPips - newStopLossPips > betterSetupBufferPips_);
        const bool isNewSizeWeightBigger = (newSizeFactorWeight > oldSizeFactorWeight);

        if (isNewSizeWeightBigger || (newSizeFactorWeight == oldSizeFactorWeight && isNewStopLossSmaller)) {
            deleteSingleOrder(orders[order]);
        }
    }

    // Including also open orders that might have been created in the meantime
    orderFilter.type.add(OP_BUY, OP_SELL);

    ArrayFree(orders);
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    if (ArraySize(orders) > 0) {
        return true;
    }

    return false;
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
    orderFind_.getFilteredOrdersList(orders, orderFilter);

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
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    if (ArraySize(orders) > 0) {
        deleteAllOrders();

        const string exceptionMessage = StringConcatenate(
            "Emergency switchOff invoked for magicNumber: ", orders[0].magicNumber);

        if (INITIALIZATION_COMPLETED) {
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

            if (INITIALIZATION_COMPLETED) {
                ThrowFatalException(__FUNCTION__, exceptionMessage);
            } else {
                ThrowException(__FUNCTION__, exceptionMessage);
            }

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
    orderFind_.getFilteredOrdersList(orders, orderFilter);

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
    if (INITIALIZATION_COMPLETED) {
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
    } else {
        deleteMockedOrder(order);
    }
}

void OrderManage::deleteMockedOrder(Order & order) {
    orderFind_.deleteMockedOrder(order);
}

void OrderManage::setMockedOrders() {
    orderFind_.setMockedOrders();
}

void OrderManage::setMockedOrders(Order & order) {
    orderFind_.setMockedOrders(order);
}

void OrderManage::setMockedOrders(Order & orders[]) {
    orderFind_.setMockedOrders(orders);
}

void OrderManage::getMockedOrders(Order & orders[]) {
    orderFind_.getMockedOrders(orders);
}








double getSizeFactorFromComment(string comment) { /// needed a small class for comment creation
    string splittedComment[];
    StringSplit(comment, StringGetCharacter(" ", 0), splittedComment);

    for (int i = 0; i < ArraySize(splittedComment); i++) {
        if (StringContains(splittedComment[i], "M")) {
            StringSplit(splittedComment[i], StringGetCharacter("M", 0), splittedComment);
            break;
        }
    }
    //Alert(splittedComment[1]);
    if (ArraySize(splittedComment) == 2) {
        return (double) splittedComment[1];
    }

    return ThrowException(-1, __FUNCTION__, "Could not get sizeFactor from comment");
}
