#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"
#include "../../src/order/OrderCreate.mqh"


/**
 * This class exposes the protected methods of OrderCreate for testing
 */
class OrderCreateExposed: public OrderCreate {
    public:
//        bool _areThereRecentOrders(datetime v) {return areThereRecentOrders(v);}
//        bool _areThereBetterOrders(int v1, double v2, double v3) {return areThereBetterOrders(v1, v2, v3);}

        int _calculateOrderTypeFromSetups(int v) {return calculateOrderTypeFromSetups(v);}
        int _morningLookBackCandles(int v) {return morningLookBackCandles(v);}
        double _calculateSizeFactor(int v1, double v2, string v3) {return calculateSizeFactor(v1, v2, v3);}
        double _calculateOrderLots(double v1, double v2, double v3) {return calculateOrderLots(v1, v2, v3);}
};


class OrderCreateTest {
    public:

//        void deduplicateOrdersTest();
//        void emergencySwitchOffTest();
//        void lossLimiterTest();


    private:
        OrderCreateExposed orderCreateExposed_;
};
