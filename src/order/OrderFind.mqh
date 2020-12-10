#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "Order.mqh"


class OrderFind {
    public:
        void getFilteredOrdersList(Order & [], OrderFilter &, int);

    private:
        void getOrdersList(Order & [], int);
};

void OrderFind::getFilteredOrdersList(Order & orders[], OrderFilter & orderFilter, int pool = MODE_TRADES) {
    getOrdersList(orders, pool);

    for (int i = ArraySize(orders) - 1; i >= 0; i--) {
        if (orderFilter.closeTime.get(orders[i].closeTime) ||
            orderFilter.magicNumber.get(orders[i].magicNumber) ||
            orderFilter.profit.get(orders[i].profit) ||
            orderFilter.symbol.get(orders[i].symbol) ||
            orderFilter.symbolFamily.get(SymbolFamily(orders[i].symbolFamily)) ||
            orderFilter.type.get(orders[i].type)) {
            ArrayRemove(orders, i);
        }
    }
}

void OrderFind::getOrdersList(Order & orders[], int pool = MODE_TRADES) {
    const int previouslySelectedOrder = OrderTicket();

    if (pool != MODE_TRADES && pool != MODE_HISTORY) {
        ThrowException(__FUNCTION__, StringConcatenate("Unsupported pool: ", pool));
        return;
    }

    const bool isModeTrades = (pool == MODE_TRADES);

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
        orders[index].period = OrderMagicNumber() - BOT_MAGIC_NUMBER;
        orders[index].ticket = OrderTicket();
        orders[index].type = OrderType();
        orders[index].lots = OrderLots();
        orders[index].openPrice = OrderOpenPrice();
        orders[index].closePrice = OrderClosePrice();
        orders[index].profit = OrderProfit();
        orders[index].stopLoss = OrderStopLoss();
        orders[index].takeProfit = OrderTakeProfit();
        orders[index].commment = OrderComment();
        orders[index].symbol = OrderSymbol();
        orders[index].closeTime = OrderCloseTime();
        index++;
    }

    ArrayResize(orders, index);

    if (previouslySelectedOrder != 0 && !OrderSelect(previouslySelectedOrder, SELECT_BY_TICKET)) {
        ThrowException(__FUNCTION__, "Could not select back previous order: ", previouslySelectedOrder);
    }
}
