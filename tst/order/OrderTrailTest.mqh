#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"
#include "../../src/order/OrderTrail.mqh"


class OrderTrailTest: public OrderTrail {
    public:
        void splitPositionTest();
        void calculateBreakEvenStopLossTest();
        void closeDrawningOrderTest();
        void calculateSufferingStopLossTest();
};

void OrderTrailTest::splitPositionTest() {
    UnitTest unitTest("splitPositionTest");

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_BUY;
    order.openPrice = iExtreme(order.getDiscriminator(), 0) - 8 * Pip(order.symbol);
    order.comment = "A P60";

    if (!SPLIT_POSITION) {
        unitTest.assertFalse(
            splitPosition(order)
        );
        return;
    }

    unitTest.assertTrue(
        splitPosition(order)
    );

    order.comment = "P60";

    unitTest.assertFalse(
        splitPosition(order)
    );

    order.comment = "A P60";
    order.type = OP_BUYSTOP;

    unitTest.assertFalse(
        splitPosition(order)
    );

    order.type = OP_SELL;

    order.openPrice = iExtreme(order.getDiscriminator(), 0) - 3 * Pip(order.symbol);

    unitTest.assertFalse(
        splitPosition(order)
    );

    order.type = OP_BUY;

    order.openPrice = iExtreme(order.getDiscriminator(), 0) - 2 * Pip(order.symbol);

    unitTest.assertFalse(
        splitPosition(order)
    );

    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H4;
    order.comment = "A P240";

    order.openPrice = iExtreme(order.getDiscriminator(), 0) - 15 * Pip(order.symbol);

    unitTest.assertTrue(
        splitPosition(order)
    );
}

void OrderTrailTest::calculateBreakEvenStopLossTest() {
    UnitTest unitTest("calculateBreakEvenStopLossTest");

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_BUY;
    order.openPrice = iExtreme(Max, 0) - 5 * Pip(order.symbol);
    order.stopLoss = order.openPrice - 10 * Pip(order.symbol);

    unitTest.assertEquals(
        order.stopLoss,
        calculateBreakEvenStopLoss(order)
    );

    order.openPrice = iExtreme(Max, 0) - 7 * Pip(order.symbol);
    order.stopLoss = order.openPrice - 10 * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice - 4 * Pip(order.symbol),
        calculateBreakEvenStopLoss(order)
    );

    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H4;
    order.openPrice = iExtreme(Max, 0) - 9 * Pip(order.symbol);
    order.stopLoss = order.openPrice - 20 * Pip(order.symbol);

    unitTest.assertEquals(
        order.stopLoss,
        calculateBreakEvenStopLoss(order)
    );

    order.openPrice = iExtreme(Max, 0) - 14 * Pip(order.symbol);
    order.stopLoss = order.openPrice - 20 * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice - 8 * Pip(order.symbol),
        calculateBreakEvenStopLoss(order)
    );

    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.type = OP_SELL;
    order.openPrice = iExtreme(Min, 0) + 9 * Pip(order.symbol);
    order.stopLoss = order.openPrice + 20 * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice + 4 * Pip(order.symbol),
        calculateBreakEvenStopLoss(order)
    );

    order.openPrice = iExtreme(Min, 0) + 27 * Pip(order.symbol);
    order.stopLoss = order.openPrice + 20 * Pip(order.symbol);

    unitTest.assertEquals(
        order.openPrice,
        calculateBreakEvenStopLoss(order)
    );
}

void OrderTrailTest::closeDrawningOrderTest() {
    UnitTest unitTest("closeDrawningOrderTest");

    Order order;
    order.symbol = Symbol();
    order.type = OP_BUY;
    order.comment = NULL;

    double newStopLoss = GetPrice() + 5 * Pip();

    unitTest.assertFalse(
        closeDrawningOrder(order, newStopLoss)
    );

    order.comment = "A P";

    unitTest.assertTrue(
        closeDrawningOrder(order, newStopLoss)
    );

    order.type = OP_SELL;

    unitTest.assertFalse(
        closeDrawningOrder(order, newStopLoss)
    );

    newStopLoss = GetPrice() - 5 * Pip();

    unitTest.assertTrue(
        closeDrawningOrder(order, newStopLoss)
    );
}

void OrderTrailTest::calculateSufferingStopLossTest() {
    UnitTest unitTest("calculateSufferingStopLossTest");

    Order order;
    order.magicNumber = MagicNumber();
    order.type = OP_BUY;
    order.symbol = Symbol();
    order.comment = "A P";
    order.openPrice = 1;
    order.stopLoss = order.openPrice - 20 * PeriodFactor() * Pip();
    order.openTime = TimeCurrent();

    double newStopLoss = order.stopLoss;

    unitTest.assertEquals(
        newStopLoss,
        calculateSufferingStopLoss(order)
    );

    order.openTime = TimeCurrent() - 10 - 60 * 15;
    newStopLoss = order.openPrice - 15 * PeriodFactor() * Pip();

    if (SUFFERING_STOPLOSS) {
        unitTest.assertEquals(
            newStopLoss,
            calculateSufferingStopLoss(order)
        );
    } else {
        unitTest.assertEquals(
            order.stopLoss,
            calculateSufferingStopLoss(order)
        );

        // If !SUFFERING_STOPLOSS one test is enough
        return;
    }

    // Checking that it returns the same value after multiple calls
    unitTest.assertEquals(
        newStopLoss,
        calculateSufferingStopLoss(order)
    );
    unitTest.assertEquals(
        newStopLoss,
        calculateSufferingStopLoss(order)
    );

    order.openTime = TimeCurrent() - 10 - 60 * 30;
    newStopLoss = order.openPrice - 10 * PeriodFactor() * Pip();

    unitTest.assertEquals(
        newStopLoss,
        calculateSufferingStopLoss(order)
    );

    order.openTime = TimeCurrent() - 10 - 60 * 45;
    newStopLoss = order.openPrice - 5 * PeriodFactor() * Pip();

    unitTest.assertEquals(
        newStopLoss,
        calculateSufferingStopLoss(order)
    );

    order.openTime = TimeCurrent() - 10 - 60 * 60;
    newStopLoss = order.openPrice;

    unitTest.assertEquals(
        newStopLoss,
        calculateSufferingStopLoss(order)
    );

    order.type = OP_SELL;
    order.openTime = TimeCurrent() - 10 - 60 * 45;
    order.stopLoss = order.openPrice + 20 * PeriodFactor() * Pip();
    newStopLoss = order.openPrice + 5 * PeriodFactor() * Pip();

    unitTest.assertEquals(
        newStopLoss,
        calculateSufferingStopLoss(order)
    );

    order.comment = "A P";
    order.type = OP_SELLSTOP;
    newStopLoss = order.stopLoss;

    unitTest.assertEquals(
        newStopLoss,
        calculateSufferingStopLoss(order)
    );
}
