#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"
#include "../../src/order/OrderCreate.mqh"


/**
 * This class exposes the protected methods of OrderCreate for testing
 */
class OrderCreateExposed: public OrderCreate {
    public:
        bool _areThereRecentOrders(datetime v) {return areThereRecentOrders(v);}
        bool _areThereBetterOrders(int v1, double v2, double v3) {return areThereBetterOrders(v1, v2, v3);}

        int _calculateOrderTypeFromSetups(int v) {return calculateOrderTypeFromSetups(v);}
        int _morningLookBackCandles(int v) {return morningLookBackCandles(v);}
        double _calculateSizeFactor(int v1, double v2, string v3) {return calculateSizeFactor(v1, v2, v3);}
        double _calculateOrderLots(double v1, double v2, double v3) {return calculateOrderLots(v1, v2, v3);}
        string _buildOrderComment(double v1, double v2, double v3) {return buildOrderComment(v1, v2, v3);}

        void _deleteMockedOrder(Order & v) {deleteMockedOrder(v);}
        void _setMockedOrders() {setMockedOrders();}
        void _setMockedOrders(Order & v[]) {setMockedOrders(v);}
};


class OrderCreateTest {
    public:
        void areThereRecentOrdersTest();
        void areThereBetterOrdersTest();

//        void deduplicateOrdersTest();
//        void emergencySwitchOffTest();
//        void lossLimiterTest();

// probabilmente queste no
//        void deleteAllOrders();
//        void deletePendingOrders();
//        void deleteOrdersFromList(Order & []);
//        void deleteSingleOrder(Order &);

    private:
        OrderCreateExposed orderCreateExposed_;
};

void OrderCreateTest::areThereRecentOrdersTest() {
    UnitTest unitTest("areThereRecentOrdersTest");

    const datetime filterDate = (datetime) "2020-09-01";

    Order orders[];
    ArrayResize(orders, 1);
    orders[0].magicNumber = 2044060;
    orders[0].symbolFamily = SymbolFamily();
    orders[0].type = OP_SELL;
    orders[0].closeTime = (datetime) "2020-08-20";

    orderCreateExposed_._setMockedOrders(orders);

    unitTest.assertFalse(
        orderCreateExposed_._areThereRecentOrders(filterDate)
    );

    orders[0].closeTime = (datetime) "2020-09-20";
    orderCreateExposed_._setMockedOrders(orders);

    unitTest.assertTrue(
        orderCreateExposed_._areThereRecentOrders(filterDate)
    );

    orders[0].type = OP_SELLSTOP;
    orderCreateExposed_._setMockedOrders(orders);

    unitTest.assertFalse(
        orderCreateExposed_._areThereRecentOrders(filterDate)
    );

    orders[0].type = OP_BUY;
    orders[0].symbolFamily = "CIAO";
    orderCreateExposed_._setMockedOrders(orders);

    unitTest.assertFalse(
        orderCreateExposed_._areThereRecentOrders(filterDate)
    );

    orderCreateExposed_._setMockedOrders();
}

void OrderCreateTest::areThereBetterOrdersTest() {
    UnitTest unitTest("areThereBetterOrdersTest");

    double stopLossSize, sizeFactor;

    Order orders[];
    ArrayResize(orders, 1);
    orders[0].magicNumber = 2044060;
    orders[0].symbol = Symbol();
    orders[0].symbolFamily = SymbolFamily();
    orders[0].type = OP_SELLSTOP;
    orders[0].ticket = 1234;
    orders[0].openPrice = 1.1000;
    orders[0].stopLoss = 1.1010;

    orderCreateExposed_._setMockedOrders(orders);

    stopLossSize = MathAbs(orders[0].stopLoss - orders[0].openPrice);
    sizeFactor = orderCreateExposed_._calculateSizeFactor(orders[0].type, orders[0].openPrice, orders[0].symbol);

    unitTest.assertTrue(
        orderCreateExposed_._areThereBetterOrders(OP_SELLSTOP, stopLossSize, sizeFactor)
    );

    sizeFactor++;

    unitTest.assertFalse(
        orderCreateExposed_._areThereBetterOrders(OP_SELLSTOP, stopLossSize, sizeFactor), "2"
    );

//    stopLossSize = MathAbs(orders[0].stopLoss - orders[0].openPrice) - 10 * Pips();
//    sizeFactor = orderCreateExposed_._calculateSizeFactor(orders[0].type, orders[0].openPrice, orders[0].symbol);
//
//    unitTest.assertFalse(
//        orderCreateExposed_._areThereBetterOrders(OP_SELLSTOP, stopLossSize, sizeFactor)
//    );



//    orders[0].type = OP_SELLSTOP;
//    orderCreateExposed_._setMockedOrders(orders);
//
//    unitTest.assertFalse(
//        orderCreateExposed_._areThereRecentOrders(filterDate)
//    );

    orderCreateExposed_._setMockedOrders();
}
