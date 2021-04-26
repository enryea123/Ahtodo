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
        void calculateTrailingStopLossTest();
        void getPreviousExtremeTest();
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
    order.stopLoss = iExtreme(Max, 0) - 100 * Pip(order.symbol);

    if (SPLIT_POSITION) {
        order.openPrice = iExtreme(Max, 0) - (BREAKEVEN_STEPS_SPLIT.getKeys(0) - 1) * Pip(order.symbol);

        unitTest.assertEquals(
            order.stopLoss,
            calculateBreakEvenStopLoss(order)
        );

        order.openPrice = iExtreme(Max, 0) - (BREAKEVEN_STEPS_SPLIT.getKeys(0) + 1) * Pip(order.symbol);

        unitTest.assertEquals(
            order.openPrice + BREAKEVEN_STEPS_SPLIT.getValues(0) * Pip(order.symbol),
            calculateBreakEvenStopLoss(order)
        );

        order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H4;
        order.openPrice = iExtreme(Max, 0) - (BREAKEVEN_STEPS_SPLIT.getKeys(0) + 1) * Pip(order.symbol);

        unitTest.assertEquals(
            order.stopLoss,
            calculateBreakEvenStopLoss(order)
        );

        order.openPrice = iExtreme(Max, 0) - (PeriodFactor(PERIOD_H4) *
            BREAKEVEN_STEPS_SPLIT.getKeys(0) + 1) * Pip(order.symbol);

        unitTest.assertEquals(
            order.openPrice + PeriodFactor(PERIOD_H4) * BREAKEVEN_STEPS_SPLIT.getValues(0) * Pip(order.symbol),
            calculateBreakEvenStopLoss(order)
        );

        order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
        order.type = OP_SELL;
        order.openPrice = iExtreme(Min, 0) + (BREAKEVEN_STEPS_SPLIT.getKeys(0) + 1) * Pip(order.symbol);
        order.stopLoss = iExtreme(Min, 0) + 100 * Pip(order.symbol);

        unitTest.assertEquals(
            order.openPrice - BREAKEVEN_STEPS_SPLIT.getValues(0) * Pip(order.symbol),
            calculateBreakEvenStopLoss(order)
        );
    } else {
        order.openPrice = iExtreme(Max, 0) - (BREAKEVEN_STEPS.getKeys(0) - 1) * Pip(order.symbol);

        unitTest.assertEquals(
            order.stopLoss,
            calculateBreakEvenStopLoss(order)
        );

        order.openPrice = iExtreme(Max, 0) - (BREAKEVEN_STEPS.getKeys(0) + 1) * Pip(order.symbol);

        unitTest.assertEquals(
            order.openPrice + BREAKEVEN_STEPS.getValues(0) * Pip(order.symbol),
            calculateBreakEvenStopLoss(order)
        );

        order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H4;
        order.openPrice = iExtreme(Max, 0) - (BREAKEVEN_STEPS.getKeys(0) + 1) * Pip(order.symbol);

        unitTest.assertEquals(
            order.stopLoss,
            calculateBreakEvenStopLoss(order)
        );

        order.openPrice = iExtreme(Max, 0) - (PeriodFactor(PERIOD_H4) *
            BREAKEVEN_STEPS.getKeys(0) + 1) * Pip(order.symbol);

        unitTest.assertEquals(
            order.openPrice + PeriodFactor(PERIOD_H4) * BREAKEVEN_STEPS.getValues(0) * Pip(order.symbol),
            calculateBreakEvenStopLoss(order)
        );

        order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
        order.type = OP_SELL;
        order.openPrice = iExtreme(Min, 0) + (BREAKEVEN_STEPS.getKeys(0) + 1) * Pip(order.symbol);
        order.stopLoss = iExtreme(Min, 0) + 100 * Pip(order.symbol);

        unitTest.assertEquals(
            order.openPrice - BREAKEVEN_STEPS.getValues(0) * Pip(order.symbol),
            calculateBreakEvenStopLoss(order)
        );
    }
}

void OrderTrailTest::calculateTrailingStopLossTest() {
    UnitTest unitTest("calculateTrailingStopLossTest");

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_BUY;
    order.comment = "S10";

    const double currentPrice = GetPrice();
    const int stopLossPips = SPLIT_POSITION ? (int) AverageTrueRange() : order.getStopLossPipsFromComment();

    order.openPrice = currentPrice - 0.6 * stopLossPips * Pip(order.symbol);
    order.stopLoss = order.openPrice - stopLossPips * Pip(order.symbol);

    double expected = order.stopLoss;

    unitTest.assertEquals(
        expected,
        calculateTrailingStopLoss(order)
    );

    order.openPrice = currentPrice - 2.6 * stopLossPips * Pip(order.symbol);
    order.stopLoss = order.openPrice - stopLossPips * Pip(order.symbol);

    expected = order.stopLoss;

    unitTest.assertEquals(
        expected,
        calculateTrailingStopLoss(order)
    );

    order.stopLoss = order.openPrice;

    expected = MathMax(order.stopLoss, getPreviousExtreme(Min, TRAILING_STEPS.get(2)) -
        TRAILING_BUFFER_PIPS * Pip(order.symbol));

    unitTest.assertEquals(
        expected,
        calculateTrailingStopLoss(order)
    );

    order.openPrice = currentPrice - 3.2 * stopLossPips * Pip(order.symbol);
    order.stopLoss = order.openPrice;

    expected = MathMax(order.stopLoss, getPreviousExtreme(Min, TRAILING_STEPS.get(3)) -
        TRAILING_BUFFER_PIPS * Pip(order.symbol));

    unitTest.assertEquals(
        expected,
        calculateTrailingStopLoss(order)
    );

    order.openPrice = currentPrice - 9.0 * stopLossPips * Pip(order.symbol);
    order.stopLoss = order.openPrice;

    expected = MathMax(order.stopLoss, getPreviousExtreme(Min, TRAILING_STEPS.get(4)) -
        TRAILING_BUFFER_PIPS * Pip(order.symbol));

    unitTest.assertEquals(
        expected,
        calculateTrailingStopLoss(order)
    );

    order.type = OP_SELL;
    order.openPrice = currentPrice + 4.3 * stopLossPips * Pip(order.symbol);
    order.stopLoss = order.openPrice;

    expected = MathMin(order.stopLoss, getPreviousExtreme(Max, TRAILING_STEPS.get(4)) +
        TRAILING_BUFFER_PIPS * Pip(order.symbol));

    unitTest.assertEquals(
        expected,
        calculateTrailingStopLoss(order)
    );
}

void OrderTrailTest::getPreviousExtremeTest() {
    UnitTest unitTest("getPreviousExtremeTest");

    Discriminator discriminator = Max;

    double candle0 = iExtreme(discriminator, 0);
    double candle1 = iExtreme(discriminator, 1);
    double candle2 = iExtreme(discriminator, 2);
    double candle3 = iExtreme(discriminator, 3);
    double candle4 = iExtreme(discriminator, 4);

    double previousExtreme = MathMax(candle0, MathMax(MathMax(candle1, candle2), MathMax(candle3, candle4)));

    unitTest.assertEquals(
        previousExtreme,
        getPreviousExtreme(discriminator, 4)
    );

    unitTest.assertEquals(
        MathMax(candle0, candle1),
        getPreviousExtreme(discriminator, 1)
    );

    unitTest.assertEquals(
        candle0,
        getPreviousExtreme(discriminator, 0)
    );

    discriminator = Min;

    candle0 = iExtreme(discriminator, 0);
    candle1 = iExtreme(discriminator, 1);
    candle2 = iExtreme(discriminator, 2);
    candle3 = iExtreme(discriminator, 3);
    candle4 = iExtreme(discriminator, 4);

    previousExtreme = MathMin(candle0, MathMin(MathMin(candle1, candle2), MathMin(candle3, candle4)));

    unitTest.assertEquals(
        previousExtreme,
        getPreviousExtreme(discriminator, 4)
    );

    unitTest.assertEquals(
        -1.0,
        getPreviousExtreme(discriminator, -1)
    );
}

void OrderTrailTest::closeDrawningOrderTest() {
    UnitTest unitTest("closeDrawningOrderTest");

    const double price = GetPrice();

    Order order;
    order.symbol = Symbol();

    double newStopLoss = price + 5 * Pip();

    unitTest.assertFalse(
        closeDrawningOrder(order, newStopLoss)
    );

    order.type = OP_BUY;
    order.comment = "A P";
    order.openPrice = price;
    order.stopLoss = order.openPrice - 17 * Pip(order.symbol);

    unitTest.assertTrue(
        closeDrawningOrder(order, newStopLoss)
    );

    order.type = OP_SELL;

    unitTest.assertFalse(
        closeDrawningOrder(order, newStopLoss)
    );

    order.stopLoss = order.openPrice + 17 * Pip(order.symbol);

    newStopLoss = price - 5 * Pip();

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
