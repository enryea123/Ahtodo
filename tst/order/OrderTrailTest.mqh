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
};

void OrderTrailTest::splitPositionTest() {
    UnitTest unitTest("splitPositionTest");

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_BUY;
    order.openPrice = GetAsk(order.symbol);
    order.comment = "A P60";

    double newStopLoss = order.openPrice - 4 * Pips(order.symbol);

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
        splitPosition(order, newStopLoss + Pips(order.symbol))
    );

    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H4;
    order.comment = "A P240";

    unitTest.assertTrue(
        splitPosition(order, order.openPrice - 10 * Pips(order.symbol))
    );
}

void OrderTrailTest::breakEvenStopLossTest() {
    UnitTest unitTest("breakEvenStopLossTest");


    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_BUY;
    order.openPrice = iExtreme(Max, 0) - 5 * Pips(order.symbol);
    order.stopLoss = order.openPrice - 10 * Pips(order.symbol);

    unitTest.assertEquals(
        order.stopLoss,
        breakEvenStopLoss(order)
    );

    order.openPrice = iExtreme(Max, 0) - 7 * Pips(order.symbol);
    order.stopLoss = order.openPrice - 10 * Pips(order.symbol);

    unitTest.assertEquals(
        order.openPrice - 4 * Pips(order.symbol),
        breakEvenStopLoss(order)
    );

    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H4;
    order.openPrice = iExtreme(Max, 0) - 9 * Pips(order.symbol);
    order.stopLoss = order.openPrice - 20 * Pips(order.symbol);

    unitTest.assertEquals(
        order.stopLoss,
        breakEvenStopLoss(order)
    );

    order.openPrice = iExtreme(Max, 0) - 14 * Pips(order.symbol);
    order.stopLoss = order.openPrice - 20 * Pips(order.symbol);

    unitTest.assertEquals(
        order.openPrice - 10 * Pips(order.symbol),
        breakEvenStopLoss(order)
    );

    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.type = OP_SELL;
    order.openPrice = iExtreme(Min, 0) + 9 * Pips(order.symbol);
    order.stopLoss = order.openPrice + 20 * Pips(order.symbol);

    unitTest.assertEquals(
        order.openPrice + 4 * Pips(order.symbol),
        breakEvenStopLoss(order)
    );

    order.openPrice = iExtreme(Min, 0) + 27 * Pips(order.symbol);
    order.stopLoss = order.openPrice + 20 * Pips(order.symbol);

    unitTest.assertEquals(
        order.openPrice,
        breakEvenStopLoss(order)
    );
}
