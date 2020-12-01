#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "Order.mqh"
#include "OrderFind.mqh"


class OrderManage {
    public:
        bool areThereOpenOrders(); // these 3 to be run in order by the manager, before the if(Put vs Trail)
        void deleteAllOrders();
        void deletePendingOrdersIfAntipattern();
        void emergencySwitchOff();
};

bool OrderManage::areThereOpenOrders() {
    Order orders[];
    OrderFilter filter;
    OrderFind orderFind;

    filter.type(OP_BUY, OP_SELL);
    filter.symbolFamily(SymbolFamily());

    orderFind.getFilteredOrdersList(orders, filter);

    return (ArraySize(orders) > 0) ? true : false;
}

void OrderManage::emergencySwitchOff() {
    Order orders[];
    OrderFind orderFind;

    orderFind.getOrdersList(orders);

    for (int order = 0; order < ArraySize(orders); order++) {
        const int magicNumber = orders[order].magicNumber;
        if (IsUnknownMagicNumber(magicNumber)) {
            deleteAllOrders();

            ThrowFatalException(__FUNCTION__, StringConcatenate(
                "Emergency switchOff invoked for magicNumber: ", magicNumber));
        }
    }
}

void OrderManage::deletePendingOrdersIfAntipattern() {
    if (!FoundAntiPattern(1)) {
        return;
    }

    Order orders[];
    OrderFilter filter;
    OrderFind orderFind;

    filter.type(OP_BUYLIMIT, OP_BUYSTOP, OP_SELLLIMIT, OP_SELLSTOP);
    filter.magicNumber(BotMagicNumber());
    filter.symbol(Symbol());

    orderFind.getFilteredOrdersList(orders, filter);

    for (int order = 0; order < ArraySize(orders); order++) {
        const int ticket = orders[order].ticket;
        const bool deletedOrder = OrderDelete(ticket);

        if (deletedOrder) {
            Print("Deleted order ", ticket, " for AntiPattern");
        } else {
            ThrowException(__FUNCTION__, StringConcatenate("Failed to delete order: ", ticket));
        }
    }
}

void OrderManage::deleteAllOrders() {
    Order orders[];
    OrderFilter filter;
    OrderFind orderFind;

    filter.magicNumber(BotMagicNumber());
    filter.symbol(Symbol());

    orderFind.getFilteredOrdersList(orders, filter);

    if (ArraySize(orders) > 0) {
        Print("Deleting all ", ArraySize(orders), " orders..");
    }

    for (int order = 0; order < ArraySize(orders); order++) {
        const int ticket = orders[order].ticket;
        bool deletedOrder = false;

        if (orders[order].type == OP_BUY || orders[order].type == OP_SELL) {
            deletedOrder = OrderClose(ticket, orders[order].lots, orders[order].closePrice, 3);
        } else {
            deletedOrder = OrderDelete(ticket);
        }

        if (!deletedOrder) {
            ThrowException(__FUNCTION__, StringConcatenate("Failed to delete order: ", ticket));
        }
    }
}
