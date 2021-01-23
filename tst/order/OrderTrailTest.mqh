#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"
#include "../../src/order/OrderTrail.mqh"


class OrderTrailTest: public OrderTrail {
    public:
        void splitPositionTest();
        void breakEvenStopLossTest();
        void closeSufferingOrderTest();
        void calculateSufferingFactorTest();
};

void OrderTrailTest::splitPositionTest() {
    UnitTest unitTest("splitPositionTest");

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_BUY;
    order.openPrice = GetPrice(order.symbol);
    order.comment = "A P60";

    double newStopLoss = order.openPrice - 4 * Pip(order.symbol);

    if (!SPLIT_POSITION) {
        unitTest.assertFalse(
            splitPosition(order, newStopLoss)
        );
        return;
    }

    unitTest.assertTrue(
        splitPosition(order, newStopLoss)
    );

    order.comment = "P60";

    unitTest.assertFalse(
        splitPosition(order, newStopLoss)
    );

    order.comment = "A P60";
    order.type = OP_BUYSTOP;

    unitTest.assertFalse(
        splitPosition(order, newStopLoss)
    );

    order.type = OP_SELL;

    unitTest.assertFalse(
        splitPosition(order, newStopLoss)
    );

    order.type = OP_BUY;

    unitTest.assertFalse(
        splitPosition(order, newStopLoss + Pip(order.symbol))
    );

    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H4;
    order.comment = "A P240";

    unitTest.assertTrue(
        splitPosition(order, order.openPrice - 8 * Pip(order.symbol))
    );
}

void OrderTrailTest::breakEvenStopLossTest() {
    UnitTest unitTest("breakEvenStopLossTest");

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_BUY;
    order.openPrice = iExtreme(Max, 0) - 5 * Pip(order.symbol);
    order.stopLoss = order.openPrice - 10 * Pip(order.symbol);

    unitTest.assertEquals(
        order.stopLoss,
        breakEvenStopLoss(order)
    );

    order.openPrice = iExtreme(Max, 0) - 7 * Pip(order.symbol);
    order.stopLoss = order.openPrice - 10 * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice - 4 * Pip(order.symbol),
        breakEvenStopLoss(order)
    );

    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H4;
    order.openPrice = iExtreme(Max, 0) - 9 * Pip(order.symbol);
    order.stopLoss = order.openPrice - 20 * Pip(order.symbol);

    unitTest.assertEquals(
        order.stopLoss,
        breakEvenStopLoss(order)
    );

    order.openPrice = iExtreme(Max, 0) - 14 * Pip(order.symbol);
    order.stopLoss = order.openPrice - 20 * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice - 8 * Pip(order.symbol),
        breakEvenStopLoss(order)
    );

    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.type = OP_SELL;
    order.openPrice = iExtreme(Min, 0) + 9 * Pip(order.symbol);
    order.stopLoss = order.openPrice + 20 * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice + 4 * Pip(order.symbol),
        breakEvenStopLoss(order)
    );

    order.openPrice = iExtreme(Min, 0) + 27 * Pip(order.symbol);
    order.stopLoss = order.openPrice + 20 * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice,
        breakEvenStopLoss(order)
    );
}

void OrderTrailTest::closeSufferingOrderTest() {
    UnitTest unitTest("closeSufferingOrderTest");

    Order order;
    order.type = OP_BUY;
    order.comment = NULL;

    double newStopLoss = GetPrice() + 5 * Pip();

    unitTest.assertFalse(
        closeSufferingOrder(order, newStopLoss)
    );

    order.comment = "A P";

    unitTest.assertTrue(
        closeSufferingOrder(order, newStopLoss)
    );

    order.type = OP_SELL;

    unitTest.assertFalse(
        closeSufferingOrder(order, newStopLoss)
    );

    newStopLoss = GetPrice() - 5 * Pip();

    unitTest.assertTrue(
        closeSufferingOrder(order, newStopLoss)
    );
}

void OrderTrailTest::calculateSufferingFactorTest() {
    UnitTest unitTest("calculateSufferingFactorTest");

    Order order;
    order.symbol = Symbol();
    order.comment = "A P";
    order.stopLoss = 1.1;
    order.openTime = TimeCurrent();

    double newStopLoss = order.stopLoss;

    unitTest.assertEquals(
        1.0,
        calculateSufferingFactor(order, newStopLoss)
    );

    order.openTime = TimeCurrent() - 10 - 60 * 15;

    unitTest.assertEquals(
        0.75,
        calculateSufferingFactor(order, newStopLoss)
    );

    order.openTime = TimeCurrent() - 10 - 60 * 30;

    unitTest.assertEquals(
        0.5,
        calculateSufferingFactor(order, newStopLoss)
    );

    order.openTime = TimeCurrent() - 10 - 60 * 45;

    unitTest.assertEquals(
        0.25,
        calculateSufferingFactor(order, newStopLoss)
    );

    order.openTime = TimeCurrent() - 10 - 60 * 60;

    unitTest.assertEquals(
        0.0,
        calculateSufferingFactor(order, newStopLoss)
    );

    newStopLoss = order.stopLoss + 5 * Pip();

    unitTest.assertEquals(
        1.0,
        calculateSufferingFactor(order, newStopLoss)
    );

    order.comment = "asdf";
    newStopLoss = order.stopLoss;

    unitTest.assertEquals(
        1.0,
        calculateSufferingFactor(order, newStopLoss)
    );
}
