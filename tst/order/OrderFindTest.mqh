#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"
#include "../../src/order/OrderFilter.mqh"
#include "../../src/order/OrderFind.mqh"


class OrderFindTest {
    public:
        void getOrdersListTest();
        void getFilteredOrdersListTest();

    private:
        OrderFind orderFind_;

        void buildOrderMocks(Order & []);
};

void OrderFindTest::getOrdersListTest() {
    UnitTest unitTest("getOrdersListTest");

    // This test checks the real functionality of orderFind
    orderFind_.setMockedOrders();

    const int randomOrderPos = 5;

    double previouslySelectedOpenPrice = 0;
    if (OrderSelect(randomOrderPos, SELECT_BY_POS, MODE_HISTORY)) {
        previouslySelectedOpenPrice = OrderOpenPrice();
    } else {
        ThrowException(__FUNCTION__, "Could not select order");
    }

    Order orders[];

    orderFind_.getOrdersList(orders);

    unitTest.assertEquals(
        OrdersTotal(),
        ArraySize(orders)
    );

    ArrayFree(orders);
    orderFind_.getOrdersList(orders, MODE_HISTORY);

    if (previouslySelectedOpenPrice != 0) {
        unitTest.assertEquals(
            previouslySelectedOpenPrice,
            OrderOpenPrice()
        );
    }

    unitTest.assertEquals(
        OrdersHistoryTotal(),
        ArraySize(orders)
    );

    if (OrdersHistoryTotal() > randomOrderPos) {
        unitTest.assertEquals(
            OrderMagicNumber(),
            orders[OrdersHistoryTotal() - randomOrderPos - 1].magicNumber
        );

        unitTest.assertEquals(
            OrderTicket(),
            orders[OrdersHistoryTotal() - randomOrderPos - 1].ticket
        );

        unitTest.assertEquals(
            OrderStopLoss(),
            orders[OrdersHistoryTotal() - randomOrderPos - 1].stopLoss
        );

        unitTest.assertEquals(
            OrderType(),
            orders[OrdersHistoryTotal() - randomOrderPos - 1].type
        );

        unitTest.assertEquals(
            OrderOpenPrice(),
            orders[OrdersHistoryTotal() - randomOrderPos - 1].openPrice
        );

        unitTest.assertEquals(
            OrderComment(),
            orders[OrdersHistoryTotal() - randomOrderPos - 1].comment
        );
    } else {
        Print("getOrdersListTest(): skipping some assertions for short history..");
    }
}

void OrderFindTest::getFilteredOrdersListTest() {
    UnitTest unitTest("getFilteredOrdersListTest");

    const datetime filterDate = (datetime) "2020-09-01";

    Order orders[];
    buildOrderMocks(orders);
    orderFind_.setMockedOrders(orders);

    OrderFilter orderFilter;
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    int totalOrders = ArraySize(orders);

    unitTest.assertEquals(
        totalOrders,
        ArraySize(orders)
    );

    orderFilter.symbolFamily.add(SymbolFamily("EURUSD"));
    orderFind_.getFilteredOrdersList(orders, orderFilter);
    totalOrders--;

    unitTest.assertEquals(
        totalOrders,
        ArraySize(orders)
    );

    for (int i = 0; i < ArraySize(orders); i++) {
        unitTest.assertNotEquals(
            "GBPUSD",
            orders[i].symbol
        );
    }

    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFind_.getFilteredOrdersList(orders, orderFilter);
    totalOrders--;

    unitTest.assertEquals(
        totalOrders,
        ArraySize(orders)
    );

    for (int i = 0; i < ArraySize(orders); i++) {
        unitTest.assertNotEquals(
            999999999,
            orders[i].magicNumber
        );
    }

    orderFilter.profit.setFilterType(Exclude);
    orderFilter.profit.add(0);
    orderFind_.getFilteredOrdersList(orders, orderFilter);
    totalOrders--;

    unitTest.assertEquals(
        totalOrders,
        ArraySize(orders)
    );

    for (int i = 0; i < ArraySize(orders); i++) {
        unitTest.assertNotEquals(
            0.0,
            orders[i].profit
        );
    }

    orderFilter.symbol.add("EURUSD");
    orderFind_.getFilteredOrdersList(orders, orderFilter);
    totalOrders--;

    unitTest.assertEquals(
        totalOrders,
        ArraySize(orders)
    );

    for (int i = 0; i < ArraySize(orders); i++) {
        unitTest.assertEquals(
            "EURUSD",
            orders[i].symbol
        );
    }

    orderFilter.closeTime.setFilterType(Greater);
    orderFilter.closeTime.add(filterDate);
    orderFind_.getFilteredOrdersList(orders, orderFilter);
    totalOrders -= 2;

    unitTest.assertEquals(
        totalOrders,
        ArraySize(orders)
    );

    for (int i = 0; i < ArraySize(orders); i++) {
        unitTest.assertTrue(
            orders[i].closeTime > filterDate
        );
    }
}

void OrderFindTest::buildOrderMocks(Order & orders[]) {
    const int initialOrders = 7;
    ArrayResize(orders, initialOrders);

    orders[0].magicNumber = 2044030;
    orders[0].type = OP_BUYSTOP;
    orders[0].symbol = "EURJPY";
    orders[0].symbolFamily = SymbolFamily(orders[0].symbol);
    orders[0].profit = 0;

    orders[1].magicNumber = 2044060;
    orders[1].type = OP_SELLSTOP;
    orders[1].symbol = "EURUSD";
    orders[1].symbolFamily = SymbolFamily(orders[1].symbol);
    orders[1].profit = 25.5;
    orders[1].closeTime = (datetime) "2020-06-30 19:40";

    orders[2].magicNumber = 2044240;
    orders[2].type = OP_BUY;
    orders[2].symbol = "EURUSD";
    orders[2].symbolFamily = SymbolFamily(orders[2].symbol);
    orders[2].profit = -12.6;
    orders[2].closeTime = (datetime) "2020-10-30 11:30";

    orders[3].magicNumber = 2044030;
    orders[3].type = OP_BUY;
    orders[3].symbol = "GBPUSD";
    orders[3].symbolFamily = SymbolFamily(orders[3].symbol);

    orders[4].magicNumber = 999999999;
    orders[4].type = OP_SELL;
    orders[4].symbol = "EURUSD";
    orders[4].symbolFamily = SymbolFamily(orders[4].symbol);

    orders[5].magicNumber = 2044240;
    orders[5].type = OP_BUYSTOP;
    orders[5].symbol = "EURUSD";
    orders[5].symbolFamily = SymbolFamily(orders[5].symbol);
    orders[5].profit = 47.23;
    orders[5].closeTime = (datetime) "2020-08-12";

    orders[6].magicNumber = 2044060;
    orders[6].type = OP_SELLSTOP;
    orders[6].symbol = "EURJPY";
    orders[6].symbolFamily = SymbolFamily(orders[6].symbol);
    orders[6].profit = -20.45;
}
