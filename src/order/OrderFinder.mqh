#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "Order.mqh"


class OrderFinder {
    public:
        void getOrdersList(Order & [], bool);
        void getFilteredOrdersList(Order & [], OrderFilter &);

        // static previouslySelectedOrder? Need to reset selected position every time?
        // Small class that does it in the constructor and destructor? Dangerous, should be after every method.
        // What if there can be only 1 method call per instance, and after that isSpoiled_ or isUsed_ = true?
        // Or maybe the destructor is called after every method? IDK
};

void OrderFinder::getOrdersList(Order & orders[], bool isModeTrades = true) {
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
        orders[index].openPrice = OrderOpenPrice();
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

void OrderFinder::getFilteredOrdersList(Order & orders[], OrderFilter & filter) {
    for (int i = ArraySize(orders) - 1; i >= 0; i--) {
        if (filter.byMagicNumber(orders[i].magicNumber) ||
            filter.byTicket(orders[i].ticket) ||
            filter.byType(orders[i].type) ||
            filter.byOpenPrice(orders[i].openPrice) ||
            filter.byProfit(orders[i].profit) ||
            filter.byCommment(orders[i].commment) ||
            filter.bySymbol(orders[i].symbol) || // later correlated symbols by passing and checking only EUR
            filter.byCloseTime(orders[i].closeTime)) {

            ArrayRemove(orders, i);
        }
    }
}

//#include "src/order/Order.mqh"
//#include "src/order/OrderFinder.mqh"
//void OnInit() {
//    OrderFinder orderFinder;
//
//    Order ordersHistory[];
//    orderFinder.getOrdersList(ordersHistory, false);
//    Alert("MODE_HISTORY ArraySize(orders) = ", ArraySize(ordersHistory));
//
//    Order orders[];
//    orderFinder.getOrdersList(orders);
//    Alert("MODE_TRADES ArraySize(orders) = ", ArraySize(orders));
//    for (int order = 0; order < ArraySize(orders); order++) {
//        Alert("OPENED orders[", order, "] = ", orders[order].ticket);
//    }
//
//    OrderFilter filter;
//    filter.symbol("EURUSD");
//    filter.symbol("EURJPY", "AUDUSD");
//    filter.type(OP_SELL, OP_BUYSTOP, OP_BUYLIMIT);
//
//    orderFinder.getFilteredOrdersList(orders, filter);
//    Alert("MODE_TRADES ArraySize(orders) = ", ArraySize(orders));
//    for (order = 0; order < ArraySize(orders); order++) { // int order
//        Alert("OPENED orders[", order, "] = ", orders[order].ticket);
//    }
//}
