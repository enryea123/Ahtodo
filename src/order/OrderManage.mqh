#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "Order.mqh"
#include "OrderFind.mqh"


class OrderManage {
    public:
        bool areThereOpenOrders(); // 1. these 3 to be run in order by the manager, before the if(Put vs Trail)
        bool isLossLimiterEnabled();

        //void deletePendingOrdersIfAntipattern(); // 2
        void emergencySwitchOff(); // 3

        void deleteSingleOrder(Order); // per ora pubblico

    protected:
        void deleteAllOrders();
        void deletePendingOrders(int, string);
        void deletePendingOrders(int & [], string);

    private:
        void deleteOrdersFromList(Order & []);
};

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

bool OrderManage::isLossLimiterEnabled() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);

    orderFilter.profit.setFilterType(Exclude);
    orderFilter.profit.add(0);

    orderFilter.closeTime.setFilterType(Greater);
    orderFilter.closeTime.add(GetDate() - (5 + 1) * 86400); // lossLimiterDays = 5;

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter, MODE_HISTORY);

    double maximumPercentLoss = 0.05;
    double totalGains = 0;

    for (int order = 0; order < ArraySize(orders); order++) {
        totalGains += orders[order].profit;

        if (totalGains <= - AccountEquity() * maximumPercentLoss) {
            deleteAllOrders();
            return true;
        }
    }

    return false;
}

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

// Not necessary to have a specific function for this now. There are actually a few different deletePending functions
//void OrderManage::deletePendingOrdersIfAntipattern() {
//    if (FoundAntiPattern(1)) {
//        deletePendingOrders(ALLOWED_MAGIC_NUMBERS, Symbol());
//    }
//}

void OrderManage::deleteAllOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(BotMagicNumber());
    orderFilter.symbol.add(Symbol());

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter);

    deleteOrdersFromList(orders);
}

void OrderManage::deletePendingOrders(int magicNumber = NULL, string symbolOrFamily = NULL) {
    int magicNumbers[];
    if (magicNumber != NULL) {
        ArrayResize(magicNumbers, 1);
        magicNumbers[0] = NULL;
    }

    deletePendingOrders(magicNumbers, symbolOrFamily);
}

void OrderManage::deletePendingOrders(int & magicNumbers[], string symbolOrFamily = NULL) {
    if (symbolOrFamily == NULL) {
        symbolOrFamily = Symbol();
    }

    OrderFilter orderFilter;
    orderFilter.type.setFilterType(Exclude);
    orderFilter.type.add(OP_BUY, OP_SELL);

    if (ArraySize(magicNumbers) > 0 && magicNumbers[0] != NULL) { // could change once I understand the usages
        orderFilter.magicNumber.add(magicNumbers);
    }
    if (StringLen(symbolOrFamily) == 3) {
        orderFilter.symbolFamily.add(symbolOrFamily);
    } else {
        orderFilter.symbol.add(symbolOrFamily);
    }

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter);

    deleteOrdersFromList(orders);
}

void OrderManage::deleteOrdersFromList(Order & orders[]) {
    for (int i = ArraySize(orders) - 1; i >= 0; i--) {
        deleteSingleOrder(orders[i]);
    }
}

void OrderManage::deleteSingleOrder(Order order) {
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
