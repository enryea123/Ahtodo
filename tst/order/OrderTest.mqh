#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"


class OrderTest {
    public:
        void getPeriodTest();
        void getStopLossPipsTest();
        void isOpenTest();
        void isBuyTest();
        void getDiscriminatorTest();
};

void OrderTest::getPeriodTest() {
    UnitTest unitTest("getPeriodTest");

    Order order;

    unitTest.assertEquals(
        -1,
        order.getPeriod()
    );

    order.magicNumber = 123;

    unitTest.assertEquals(
        -1,
        order.getPeriod()
    );

    order.magicNumber = 2044060;

    unitTest.assertEquals(
        60,
        order.getPeriod()
    );
}

void OrderTest::getStopLossPipsTest() {
    UnitTest unitTest("getStopLossPipsTest");

    Order order;

    unitTest.assertEquals(
        -1.0,
        order.getStopLossPips()
    );

    order.openPrice = 1.1;
    order.stopLoss = 1.101;

    unitTest.assertEquals(
        -1.0,
        order.getStopLossPips()
    );

    order.symbol = "EURUSD";

    unitTest.assertEquals(
        10.0,
        order.getStopLossPips()
    );

    order.openPrice = 1.101;
    order.stopLoss = 1.1;
    order.symbol = "EURJPY";

    unitTest.assertEquals(
        0.1,
        order.getStopLossPips()
    );
}

void OrderTest::isOpenTest() {
    UnitTest unitTest("isOpenTest");

    Order order;

    unitTest.assertFalse(
        order.isOpen()
    );

    order.type = OP_BUYSTOP;

    unitTest.assertFalse(
        order.isOpen()
    );

    order.type = OP_BUY;

    unitTest.assertTrue(
        order.isOpen()
    );
}

void OrderTest::isBuyTest() {
    UnitTest unitTest("isBuyTest");

    Order order;

    unitTest.assertFalse(
        order.isBuy()
    );

    order.type = OP_SELL;

    unitTest.assertFalse(
        order.isBuy()
    );

    order.type = OP_BUYSTOP;

    unitTest.assertTrue(
        order.isBuy()
    );
}

void OrderTest::getDiscriminatorTest() {
    UnitTest unitTest("getDiscriminatorTest");

    Order order;

    unitTest.assertEquals(
        Min,
        order.getDiscriminator()
    );

    order.type = OP_BUY;

    unitTest.assertEquals(
        Max,
        order.getDiscriminator()
    );

    order.type = OP_SELLLIMIT;

    unitTest.assertEquals(
        Min,
        order.getDiscriminator()
    );
}
