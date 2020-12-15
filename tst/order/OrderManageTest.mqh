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
        void _setMockedOrders(Order & v[]) {setMockedOrders(v);}
};


class OrderManageTest {
    public:
        void areThereOpenOrdersTest();
//        void deduplicateOrdersTest();
//        void emergencySwitchOffTest();
//        void lossLimiterTest();

// 2 nuove spostate da testare

// probabilmente queste no
//        void deleteAllOrders();
//        void deletePendingOrders();
//        void deleteOrdersFromList(Order & []);
//        void deleteSingleOrder(Order &);

    private:
        OrderManageExposed orderManageExposed_;
};

void OrderManageTest::areThereOpenOrdersTest() {
    UnitTest unitTest("areThereOpenOrdersTest");

    Order orders[];
    ArrayResize(orders, 1);
    orders[0].magicNumber = 2044060;
    orders[0].symbolFamily = SymbolFamily();
    orders[0].type = OP_SELLSTOP;

    orderManageExposed_._setMockedOrders(orders);
    unitTest.assertFalse(
        orderManageExposed_.areThereOpenOrders()
    );

    orders[0].type = OP_BUY;
    orderManageExposed_._setMockedOrders(orders);

    unitTest.assertTrue(
        orderManageExposed_.areThereOpenOrders()
    );

    orders[0].symbolFamily = "CIAO";
    orderManageExposed_._setMockedOrders(orders);

    unitTest.assertFalse(
        orderManageExposed_.areThereOpenOrders()
    );

    orders[0].symbolFamily = SymbolFamily();
    orders[0].magicNumber = 999999;
    orderManageExposed_._setMockedOrders(orders);

    unitTest.assertFalse(
        orderManageExposed_.areThereOpenOrders()
    );

    orderManageExposed_._setMockedOrders();
}
