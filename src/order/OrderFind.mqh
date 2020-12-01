#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "Order.mqh"


class OrderFind {
    public:
        void getOrdersList(Order & [], bool);
        void getFilteredOrdersList(Order & [], OrderFilter &, bool);

        // static previouslySelectedOrder? Need to reset selected position every time?
        // Small class that does it in the constructor and destructor? Dangerous, should be after every method.
        // What if there can be only 1 method call per instance, and after that isSpoiled_ or isUsed_ = true?
        // Or maybe the destructor is called after every method? IDK
};

void OrderFind::getOrdersList(Order & orders[], bool isModeTrades = true) {
    const int previouslySelectedOrder = OrderTicket();

    const int pool = isModeTrades ? MODE_TRADES : MODE_HISTORY;
    const int poolOrders = isModeTrades ? OrdersTotal() : OrdersHistoryTotal();
    const int baseArraySize = isModeTrades ? 10 : 500;
    ArrayResize(orders, baseArraySize, baseArraySize);

    int index = 0;
    for (int order = poolOrders - 1; order >= 0; order--) {
        if (!OrderSelect(order, SELECT_BY_POS, pool)) {
            continue;
        }

        ArrayResize(orders, index + 1, baseArraySize);
        orders[index].magicNumber = OrderMagicNumber();
        orders[index].ticket = OrderTicket();
        orders[index].type = OrderType();
        orders[index].lots = OrderLots();
        orders[index].openPrice = OrderOpenPrice();
        orders[index].closePrice = OrderClosePrice();
        orders[index].profit = OrderProfit();
        orders[index].commment = OrderComment();
        orders[index].symbol = OrderSymbol();
        orders[index].closeTime = OrderCloseTime();
        index++;
    }

    ArrayResize(orders, index);

    if (previouslySelectedOrder != 0 && !OrderSelect(previouslySelectedOrder, SELECT_BY_TICKET)) {
        ThrowException(__FUNCTION__, "Could not select back previous order");
    }
}

void OrderFind::getFilteredOrdersList(Order & orders[], OrderFilter & filter, bool isModeTrades = true) {
    getOrdersList(orders, isModeTrades);

    for (int i = ArraySize(orders) - 1; i >= 0; i--) {
        if (filter.byMagicNumber(orders[i].magicNumber) ||
            filter.byTicket(orders[i].ticket) ||
            filter.byType(orders[i].type) ||
            filter.byOpenPrice(orders[i].openPrice) ||
            filter.byProfit(orders[i].profit) ||
            filter.byCommment(orders[i].commment) ||
            filter.bySymbol(orders[i].symbol) || // later correlated symbols by passing and checking only EUR
            filter.bySymbolFamily(SymbolFamily(orders[i].symbol)) ||
            filter.byCloseTime(orders[i].closeTime)) {

            ArrayRemove(orders, i);
        }
    }
}
