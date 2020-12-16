#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"
#include "../../src/order/OrderManage.mqh"


/**
 * This class exposes the protected methods of OrderManage for testing
 */
class OrderManageExposed: public OrderManage {
    public:
        void _setMockedOrders() {setMockedOrders();}
        void _setMockedOrders(Order & v) {setMockedOrders(v);}
        void _setMockedOrders(Order & v[]) {setMockedOrders(v);}
        void _getMockedOrders(Order & v[]) {getMockedOrders(v);}
};


class OrderManageTest {
    public:
        void areThereOpenOrdersTest();
        void areThereRecentOrdersTest();
        void areThereBetterOrdersTest();
        void deduplicateOrdersTest();
        void emergencySwitchOffTest();
        void lossLimiterTest();
        void deleteAllOrdersTest();
        void deletePendingOrdersTest();

    private:
        OrderManageExposed orderManageExposed_;
};

void OrderManageTest::areThereOpenOrdersTest() {
    UnitTest unitTest("areThereOpenOrdersTest");

    Order order;
    order.magicNumber = 2044060;
    order.symbolFamily = SymbolFamily();
    order.type = OP_SELLSTOP;

    orderManageExposed_._setMockedOrders(order);
    unitTest.assertFalse(
        orderManageExposed_.areThereOpenOrders()
    );

    order.type = OP_BUY;
    orderManageExposed_._setMockedOrders(order);

    unitTest.assertTrue(
        orderManageExposed_.areThereOpenOrders()
    );

    order.symbolFamily = "CIAO";
    orderManageExposed_._setMockedOrders(order);

    unitTest.assertFalse(
        orderManageExposed_.areThereOpenOrders()
    );

    order.symbolFamily = SymbolFamily();
    order.magicNumber = 999999;
    orderManageExposed_._setMockedOrders(order);

    unitTest.assertFalse(
        orderManageExposed_.areThereOpenOrders()
    );

    orderManageExposed_._setMockedOrders();
}

void OrderManageTest::areThereRecentOrdersTest() {
    UnitTest unitTest("areThereRecentOrdersTest");

    const datetime filterDate = (datetime) "2020-09-01";

    Order order;
    order.magicNumber = 2044060;
    order.symbolFamily = SymbolFamily();
    order.type = OP_SELL;
    order.closeTime = (datetime) "2020-08-20";

    orderManageExposed_._setMockedOrders(order);

    unitTest.assertFalse(
        orderManageExposed_.areThereRecentOrders(filterDate)
    );

    order.closeTime = (datetime) "2020-09-20";
    orderManageExposed_._setMockedOrders(order);

    unitTest.assertTrue(
        orderManageExposed_.areThereRecentOrders(filterDate)
    );

    order.type = OP_SELLSTOP;
    orderManageExposed_._setMockedOrders(order);

    unitTest.assertFalse(
        orderManageExposed_.areThereRecentOrders(filterDate)
    );

    order.type = OP_BUY;
    order.symbolFamily = "CIAO";
    orderManageExposed_._setMockedOrders(order);

    unitTest.assertFalse(
        orderManageExposed_.areThereRecentOrders(filterDate)
    );

    orderManageExposed_._setMockedOrders();
}

void OrderManageTest::areThereBetterOrdersTest() {
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
    order.comment = "M1.0";

    orderManageExposed_._setMockedOrders(order);

    unitTest.assertTrue(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize, 1)
    );

    orderManageExposed_._setMockedOrders(order);

    unitTest.assertTrue(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize * 1.2, 1)
    );

    orderManageExposed_._setMockedOrders(order);

    unitTest.assertTrue(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize, 0.8)
    );

    order.magicNumber = 2044030;
    orderManageExposed_._setMockedOrders(order);

    unitTest.assertTrue(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize, 0.8)
    );

    orderManageExposed_._setMockedOrders(order);

    unitTest.assertTrue(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize - Pips(), 1)
    );

    order.type = OP_BUYSTOP;
    orderManageExposed_._setMockedOrders(order);

    unitTest.assertFalse(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize * 1.2, 0.8)
    );

    order.type = OP_BUY;
    orderManageExposed_._setMockedOrders(order);

    unitTest.assertTrue(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize * 0.8, 1.2)
    );

    order.type = OP_SELLSTOP;
    order.symbolFamily = "CIAO";
    orderManageExposed_._setMockedOrders(order);

    unitTest.assertFalse(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize, 1)
    );

    order.symbolFamily = SymbolFamily();
    order.magicNumber = 999999;
    orderManageExposed_._setMockedOrders(order);

    unitTest.assertFalse(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize, 1)
    );

    if (Period() != PERIOD_H4) {
        order.magicNumber = 2044240;

        orderManageExposed_._setMockedOrders(order);

        unitTest.assertFalse(
            orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize * 0.5, 0.8)
        );

        orderManageExposed_._setMockedOrders(order);

        unitTest.assertTrue(
            orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize * 0.5, 0.5)
        );

        orderManageExposed_._setMockedOrders(order);

        unitTest.assertFalse(
            orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize, 1.2)
        );

        orderManageExposed_._setMockedOrders(order);

        unitTest.assertFalse(
            orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize * 0.6, 1)
        );
    } else {
        order.magicNumber = 2044240;

        orderManageExposed_._setMockedOrders(order);

        unitTest.assertFalse(
            orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize, 1.2)
        );

        orderManageExposed_._setMockedOrders(order);

        unitTest.assertTrue(
            orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize, 1)
        );

        orderManageExposed_._setMockedOrders(order);

        unitTest.assertFalse(
            orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize * 0.6, 1)
        );

        order.magicNumber = 2044060;

        orderManageExposed_._setMockedOrders(order);

        unitTest.assertTrue(
            orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize, 1.2)
        );

        orderManageExposed_._setMockedOrders(order);

        unitTest.assertTrue(
            orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize * 0.8, 1)
        );

        orderManageExposed_._setMockedOrders(order);

        unitTest.assertFalse(
            orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize * 0.8, 2.5)
        );
    }

    order.magicNumber = 2044060;

    Order orders[];
    ArrayResize(orders, 2);
    orders[0] = order;
    orders[1] = order;
    orders[1].stopLoss = order.openPrice + stopLossSize / 2;

    orderManageExposed_._setMockedOrders(orders);

    unitTest.assertTrue(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize * 0.6, 1)
    );

    orderManageExposed_._setMockedOrders();
}

void OrderManageTest::deduplicateOrdersTest() {
    UnitTest unitTest("deduplicateOrdersTest");

    Order orders[];
    ArrayResize(orders, 1);
    orders[0].magicNumber = 2044060;
    orders[0].symbolFamily = SymbolFamily();
    orders[0].type = OP_SELLSTOP;

    Order mockedOrders[];

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.deduplicateOrders();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        orders,
        mockedOrders
    );

    ArrayResize(orders, 2);
    orders[1] = orders[0];
    ArrayFree(mockedOrders);

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.deduplicateOrders();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1,
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[0],
        mockedOrders[0]
    );

    orders[0].symbolFamily = "CIAO";
    ArrayFree(mockedOrders);

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.deduplicateOrders();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        orders,
        mockedOrders
    );

    orders[0].symbolFamily = SymbolFamily();

    orders[1].type = OP_BUYSTOP;
    ArrayFree(mockedOrders);

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.deduplicateOrders();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        orders,
        mockedOrders
    );

    orders[1].type = OP_SELL;
    ArrayResize(orders, 3);
    orders[2] = orders[0];
    ArrayFree(mockedOrders);

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.deduplicateOrders();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1,
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[1],
        mockedOrders[0]
    );

    orderManageExposed_._setMockedOrders();
}

void OrderManageTest::emergencySwitchOffTest() {
    UnitTest unitTest("emergencySwitchOffTest");

    Order orders[];
    ArrayResize(orders, 3);
    orders[0].magicNumber = BotMagicNumber();
    orders[1].magicNumber = BotMagicNumber();
    orders[2].magicNumber = (BotMagicNumber() == 2044240) ? 2044060 : 2044240;
    orders[0].symbol = Symbol();
    orders[1].symbol = orders[0].symbol;
    orders[2].symbol = orders[0].symbol;

    Order mockedOrders[];

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.emergencySwitchOff();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        3,
        ArraySize(mockedOrders)
    );

    orders[1].magicNumber = 9999999;
    ArrayFree(mockedOrders);

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.emergencySwitchOff();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        2, // deleteAllOrders() only deletes orders with BotMagicNumber()
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[2],
        mockedOrders[0]
    );

    unitTest.assertEquals(
        orders[1],
        mockedOrders[1]
    );

    orderManageExposed_._setMockedOrders();
}

void OrderManageTest::lossLimiterTest() {
    UnitTest unitTest("lossLimiterTest");

    const double maxAllowedLosses = AccountEquity() * orderManageExposed_.maxAllowedLossesPercent_;

    Order orders[];
    ArrayResize(orders, 3);
    orders[0].magicNumber = BotMagicNumber();
    orders[1].magicNumber = BotMagicNumber();
    orders[2].magicNumber = 9999999;
    orders[0].symbol = Symbol();
    orders[1].symbol = orders[0].symbol;
    orders[2].symbol = orders[0].symbol;

    orders[0].profit = 50.4;
    orders[1].profit = 0;
    orders[2].profit = -50;

    orders[0].closeTime = TimeCurrent();
    orders[1].closeTime = orders[0].closeTime;
    orders[2].closeTime = orders[0].closeTime;

    Order mockedOrders[];

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.lossLimiter();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        orders,
        mockedOrders
    );

    orders[0].profit = - maxAllowedLosses / 2;
    orders[1].profit = - maxAllowedLosses / 2 + 1;
    ArrayFree(mockedOrders);

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.lossLimiter();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        orders,
        mockedOrders
    );

    orders[1].profit = - maxAllowedLosses;
    ArrayFree(mockedOrders);

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.lossLimiter();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1, // deleteAllOrders() only deletes orders with BotMagicNumber()
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[2],
        mockedOrders[0]
    );

    orders[1].closeTime = TimeCurrent() - orderManageExposed_.lossLimiterTime_ - 10;
    ArrayFree(mockedOrders);

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.lossLimiter();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        orders,
        mockedOrders
    );

    orderManageExposed_._setMockedOrders();
}

void OrderManageTest::deleteAllOrdersTest() {
    UnitTest unitTest("deleteAllOrdersTest");

    Order orders[];
    ArrayResize(orders, 2);
    orders[0].magicNumber = BotMagicNumber();
    orders[0].symbol = Symbol();
    orders[1] = orders[0];

    Order mockedOrders[];

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.deleteAllOrders();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        0,
        ArraySize(mockedOrders)
    );

    orders[0].symbol = "CIAO";
    ArrayFree(mockedOrders);

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.deleteAllOrders();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1,
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[0],
        mockedOrders[0]
    );

    orders[0].symbol = Symbol();
    orders[0].magicNumber = (BotMagicNumber() == 2044240) ? 2044060 : 2044240;
    ArrayFree(mockedOrders);

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.deleteAllOrders();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1,
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[0],
        mockedOrders[0]
    );

    orderManageExposed_._setMockedOrders();
}

void OrderManageTest::deletePendingOrdersTest() {
    UnitTest unitTest("deletePendingOrdersTest");

    Order orders[];
    ArrayResize(orders, 2);
    orders[0].magicNumber = BotMagicNumber();
    orders[0].symbol = Symbol();
    orders[0].type = OP_BUYSTOP;
    orders[1] = orders[0];
    orders[1].type = OP_SELLSTOP;

    Order mockedOrders[];

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.deletePendingOrders();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        0,
        ArraySize(mockedOrders)
    );

    orders[0].symbol = "CIAO";
    ArrayFree(mockedOrders);

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.deletePendingOrders();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1,
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[0],
        mockedOrders[0]
    );

    orders[0].symbol = Symbol();
    orders[1].type = OP_SELL;
    ArrayFree(mockedOrders);

    orderManageExposed_._setMockedOrders(orders);
    orderManageExposed_.deletePendingOrders();
    orderManageExposed_._getMockedOrders(mockedOrders);

    unitTest.assertEquals(
        1,
        ArraySize(mockedOrders)
    );

    unitTest.assertEquals(
        orders[1],
        mockedOrders[0]
    );

    orderManageExposed_._setMockedOrders();
}
