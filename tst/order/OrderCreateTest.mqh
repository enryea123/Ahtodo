#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"
#include "../../src/order/OrderCreate.mqh"


class OrderCreateTest: public OrderCreate {
    public:
        void areThereRecentOrdersTest();
        void areThereBetterOrdersTest();
        void buildOrderCommentTest();
        void getSizeFactorFromCommentTest();
};

void OrderCreateTest::areThereRecentOrdersTest() {
    UnitTest unitTest("areThereRecentOrdersTest");

    const datetime filterDate = (datetime) "2020-09-01";

    Order order;
    order.magicNumber = 2044060;
    order.symbolFamily = SymbolFamily();
    order.type = OP_SELL;
    order.closeTime = (datetime) "2020-08-20";

    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereRecentOrders(filterDate)
    );

    order.closeTime = (datetime) "2020-09-20";
    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereRecentOrders(filterDate)
    );

    order.type = OP_SELLSTOP;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereRecentOrders(filterDate)
    );

    order.type = OP_BUY;
    order.symbolFamily = "CIAO";
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereRecentOrders(filterDate)
    );

    orderFind_.setMockedOrders();
}

void OrderCreateTest::areThereBetterOrdersTest() {
    UnitTest unitTest("areThereBetterOrdersTest");

    const double stopLossSize = 20 * Pips();

    Order order;
    order.magicNumber = 2044060;
    order.symbol = Symbol();
    order.symbolFamily = SymbolFamily();
    order.type = OP_SELLSTOP;
    order.ticket = 1234;
    order.openPrice = GetAsk(order.symbol);
    order.stopLoss = order.openPrice + stopLossSize;

    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize, 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 1.2, 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 0.8, 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELL, stopLossSize * 0.8, 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize - 0.5 * Pips(), 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize - 2 * Pips(), 0)
    );

    order.type = OP_BUYSTOP;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 1.2, 0)
    );

    order.type = OP_BUY;
    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 0.8, 0)
    );

    order.type = OP_SELLSTOP;
    order.symbolFamily = "CIAO";
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize, 0)
    );

    order.symbolFamily = SymbolFamily();
    order.magicNumber = 999999;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize, 0)
    );

    order.magicNumber = 2044060;

    Order orders[];
    ArrayResize(orders, 2);
    orders[0] = order;
    orders[1] = order;
    orders[1].stopLoss = order.openPrice + stopLossSize / 2;

    orderFind_.setMockedOrders(orders);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 0.6, 0)
    );

    orderFind_.setMockedOrders();
}

void OrderCreateTest::buildOrderCommentTest() {
    UnitTest unitTest("buildOrderCommentTest");

/// commento riguardante lo split degli ordini ed il commmento  (oppure si potrebbe fare che non contenga #from? dipende dal broker quello)

    unitTest.assertEquals(
        "A P60 M1 R3 S10",
        buildOrderComment(PERIOD_H1, 1, 3, 10)
    );

    unitTest.assertEquals(
        "A P240 M1.2 R2.8 S12",
        buildOrderComment(PERIOD_H4, 1.2, 2.8, 12)
    );

    // It truncates a long comment
    unitTest.assertEquals(
        "A P30 M1.3 R2.5 S123",
        buildOrderComment(PERIOD_M30, 1.3, 2.5, 123456789)
    );
}

void OrderCreateTest::getSizeFactorFromCommentTest() {
    UnitTest unitTest("getSizeFactorFromCommentTest");

    string comment = "A P30 M1.3 R3 S10";

    unitTest.assertEquals(
        1.3,
        getSizeFactorFromComment(comment)
    );

    comment = "A P30 M1 R3 S10";

    unitTest.assertEquals(
        1.0,
        getSizeFactorFromComment(comment)
    );

    comment = "M0.8";

    unitTest.assertEquals(
        0.8,
        getSizeFactorFromComment(comment)
    );

    comment = "A P30 W1 R3 S10";

    unitTest.assertEquals(
        -1.0,
        getSizeFactorFromComment(comment)
    );

    comment = "W1";

    unitTest.assertEquals(
        -1.0,
        getSizeFactorFromComment(comment)
    );

    comment = "asdasdM123asdasd";

    unitTest.assertEquals(
        123.0,
        getSizeFactorFromComment(comment)
    );
}
