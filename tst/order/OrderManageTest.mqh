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
};


class OrderManageTest {
    public:
        void areThereOpenOrdersTest();
        void areThereRecentOrdersTest();
        void areThereBetterOrdersTest();

//        void deduplicateOrdersTest();
//        void emergencySwitchOffTest();
//        void lossLimiterTest();

// guarda cosa manca

//        void deleteAllOrders();
//        void deletePendingOrders();

// probabilmente queste no
//        void deleteOrdersFromList(Order & []);
//        void deleteSingleOrder(Order &);

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

    Order order;
    order.magicNumber = 2044060;
    order.symbol = Symbol();
    order.symbolFamily = SymbolFamily();
    order.type = OP_SELLSTOP;
    order.ticket = 1234;
    order.openPrice = 1.1000;
    order.stopLoss = 1.1010;
    order.comment = "M1.0";

    orderManageExposed_._setMockedOrders(order);

    const double stopLossSize = MathAbs(order.stopLoss - order.openPrice);

    unitTest.assertTrue(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize, 1)
    );

    unitTest.assertTrue(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize * 1.2, 1)
    );

    unitTest.assertTrue(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize, 0.8)
    );

    unitTest.assertFalse(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize, 1.2)
    );

    unitTest.assertFalse(
        orderManageExposed_.areThereBetterOrders(OP_SELLSTOP, stopLossSize * 0.9, 1)
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

    orderManageExposed_._setMockedOrders();
}
