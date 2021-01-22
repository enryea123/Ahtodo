#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/order/Order.mqh"
#include "../../src/order/OrderCreate.mqh"


class OrderCreateTest: public OrderCreate {
    public:
        void areThereRecentOrdersTest();
        void areThereBetterOrdersTest();
        void calculateOrderTypeFromSetupsTest();
        void calculateTakeProfitFactorTest();
        void calculateSizeFactorTest();
        void calculateOrderLotsTest();
        void getPercentRiskTest();
        void buildOrderCommentTest();
        void getSizeFactorFromCommentTest();
};

void OrderCreateTest::areThereRecentOrdersTest() {
    UnitTest unitTest("areThereRecentOrdersTest");

    const datetime filterDate = (datetime) "2020-09-01";

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_SELL;
    order.closeTime = (datetime) "2020-08-20";

    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereRecentOrders(filterDate)
    );

    order.closeTime = (datetime) "2020-09-20";
    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereRecentOrders(filterDate)
    );

    order.type = OP_SELLSTOP;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereRecentOrders(filterDate)
    );

    order.type = OP_BUY;
    order.symbol = "CIAO";
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereRecentOrders(filterDate)
    );

    orderFind_.deleteAllMockedOrders();
}

void OrderCreateTest::areThereBetterOrdersTest() {
    UnitTest unitTest("areThereBetterOrdersTest");

    const double stopLossSize = 20 * Pip();

    Order order;
    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;
    order.symbol = Symbol();
    order.type = OP_SELLSTOP;
    order.ticket = 1234;
    order.openPrice = GetAsk(order.symbol);
    order.stopLoss = order.openPrice + stopLossSize;

    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize, 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 1.2, 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 0.8, 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELL, stopLossSize * 0.8, 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize - 0.5 * Pip(), 0)
    );

    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize - 2 * Pip(), 0)
    );

    order.type = OP_BUYSTOP;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 1.2, 0)
    );

    order.type = OP_BUY;
    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 0.8, 0)
    );

    order.type = OP_SELLSTOP;
    order.symbol = "CIAO";
    orderFind_.setMockedOrders(order);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize, 0)
    );

    order.symbol = Symbol();
    order.magicNumber = 999999;
    orderFind_.setMockedOrders(order);

    unitTest.assertFalse(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize, 0)
    );

    order.magicNumber = BASE_MAGIC_NUMBER + PERIOD_H1;

    Order orders[];
    ArrayResize(orders, 2);
    orders[0] = order;
    orders[1] = order;
    orders[1].stopLoss = order.openPrice + stopLossSize / 2;

    orderFind_.setMockedOrders(orders);

    unitTest.assertTrue(
        areThereBetterOrders(order.symbol, OP_SELLSTOP, stopLossSize * 0.6, 0)
    );

    orderFind_.deleteAllMockedOrders();
}

void OrderCreateTest::calculateOrderTypeFromSetupsTest() {
    UnitTest unitTest("calculateOrderTypeFromSetupsTest");

    unitTest.assertEquals(
        -1,
        calculateOrderTypeFromSetups(0)
    );

    Pattern pattern;

    const int totalAssertions = 3;
    int checkedAssertions = 0;

    bool antiPatternTested = false;
    bool patternTested = false;
    bool trendLineTested = false;

    for (int i = 1; i < 100; i++) {
        if (checkedAssertions == totalAssertions) {
            break;
        }

        if (pattern.isAntiPattern(i)) {
            if (antiPatternTested) {
                continue;
            }

            unitTest.assertEquals(
                -1,
                calculateOrderTypeFromSetups(i)
            );
            checkedAssertions++;
            antiPatternTested = true;

        } else if (!pattern.isSellPattern(i) && !pattern.isBuyPattern(i)) {
            if (patternTested) {
                continue;
            }

            unitTest.assertEquals(
                -1,
                calculateOrderTypeFromSetups(i)
            );
            checkedAssertions++;
            patternTested = true;

        } else {
            if (trendLineTested) {
                continue;
            }

            TrendLine trendLine;

            const Discriminator discriminator = (pattern.isSellPattern(i)) ? Min : Max;
            const int expectedOrder = (discriminator == Min) ? OP_SELLSTOP : OP_BUYSTOP;
            const double currentExtreme = iExtreme(discriminator, i);

            string trendLineName = trendLine.buildTrendLineName(50 + i, 20 + i, 0, discriminator);
            ObjectCreate(trendLineName, OBJ_TREND, 0, Time[50 + i], currentExtreme, Time[20 + i], currentExtreme);

            unitTest.assertEquals(
                expectedOrder,
                calculateOrderTypeFromSetups(i)
            );

            ObjectDelete(trendLineName);
            trendLineName = trendLine.buildTrendLineName(50 + i, 20 + i, 0, discriminator);
            ObjectCreate(trendLineName, OBJ_TREND, 0,
                Time[50 + i], currentExtreme + (TRENDLINE_SETUP_MAX_PIPS_DISTANCE - 1) * Pip(),
                Time[20 + i], currentExtreme + (TRENDLINE_SETUP_MAX_PIPS_DISTANCE - 1) * Pip()
            );

            unitTest.assertEquals(
                expectedOrder,
                calculateOrderTypeFromSetups(i)
            );

            ObjectDelete(trendLineName);
            trendLineName = trendLine.buildTrendLineName(50 + i, 20 + i, 0, discriminator);
            ObjectCreate(trendLineName, OBJ_TREND, 0,
                Time[50 + i], currentExtreme + (TRENDLINE_SETUP_MAX_PIPS_DISTANCE + 1) * Pip(),
                Time[20 + i], currentExtreme + (TRENDLINE_SETUP_MAX_PIPS_DISTANCE + 1) * Pip()
            );

            unitTest.assertEquals(
                -1,
                calculateOrderTypeFromSetups(i)
            );

            ObjectDelete(trendLineName);
            trendLineName = trendLine.buildTrendLineName(50 + i, 20 + i, 0, discriminator);
            ObjectCreate(trendLineName, OBJ_TREND, 0,
                Time[50 + i], currentExtreme - (TRENDLINE_SETUP_MAX_PIPS_DISTANCE + 1) * Pip(),
                Time[20 + i], currentExtreme - (TRENDLINE_SETUP_MAX_PIPS_DISTANCE + 1) * Pip()
            );

            unitTest.assertEquals(
                -1,
                calculateOrderTypeFromSetups(i)
            );

            ObjectDelete(trendLineName);
            trendLineName = trendLine.buildBadTrendLineName(50 + i, 20 + i, 0, discriminator);
            ObjectCreate(trendLineName, OBJ_TREND, 0, Time[50 + i], currentExtreme, Time[20 + i], currentExtreme);

            unitTest.assertEquals(
                -1,
                calculateOrderTypeFromSetups(i)
            );

            ObjectDelete(trendLineName);
            trendLineName = trendLine.buildTrendLineName(50 + i, i, 0, discriminator);
            ObjectCreate(trendLineName, OBJ_TREND, 0, Time[50 + i], currentExtreme, Time[i], currentExtreme);

            unitTest.assertEquals(
                -1,
                calculateOrderTypeFromSetups(i)
            );

            ObjectDelete(trendLineName);

            checkedAssertions++;
            trendLineTested = true;
        }
    }

    if (checkedAssertions < totalAssertions && IS_DEBUG) {
        Print(checkedAssertions, "/", totalAssertions, " checks run, some skipped..");
    }

    ObjectsDeleteAll();
}

void OrderCreateTest::calculateTakeProfitFactorTest() {
    UnitTest unitTest("calculateTakeProfitFactorTest");

    const double openPrice = 1.1;
    const double stopLossPips = 15;

    double level;

    unitTest.assertEquals(
        MAX_TAKE_PROFIT_FACTOR,
        calculateTakeProfitFactor(openPrice, stopLossPips, Max)
    );

    level = openPrice + 300 * Pip();
    ObjectCreate("Level_1_Max", OBJ_TREND, 0, Time[1], level, Time[0], level);
    level = openPrice + 1 * Pip();
    ObjectCreate("Level_11_Max", OBJ_TREND, 0, Time[1], level, Time[0], level);
    level = openPrice - 300 * Pip();
    ObjectCreate("Level_12_Max", OBJ_TREND, 0, Time[1], level, Time[0], level);
    level = openPrice + 35 * Pip();
    ObjectCreate("LEVELLL_1_Max", OBJ_TREND, 0, Time[1], level, Time[0], level);
    ObjectCreate("Level_1_Min", OBJ_TREND, 0, Time[1], level, Time[0], level);

    unitTest.assertEquals(
        MAX_TAKE_PROFIT_FACTOR,
        calculateTakeProfitFactor(openPrice, stopLossPips, Max)
    );

    level = openPrice + 35 * Pip();
    ObjectCreate("Level_2_Max", OBJ_TREND, 0, Time[1], level, Time[0], level);

    unitTest.assertEquals(
        2.1,
        calculateTakeProfitFactor(openPrice, stopLossPips, Max)
    );

    level = openPrice + 40 * Pip();
    ObjectCreate("Level_3_Max", OBJ_TREND, 0, Time[1], level, Time[0], level);

    unitTest.assertEquals(
        2.1,
        calculateTakeProfitFactor(openPrice, stopLossPips, Max)
    );

    level = openPrice + 30 * Pip();
    ObjectCreate("Level_4_Max", OBJ_TREND, 0, Time[1], level, Time[0], level);

    unitTest.assertEquals(
        1.8,
        calculateTakeProfitFactor(openPrice, stopLossPips, Max)
    );

    level = openPrice + 20 * Pip();
    ObjectCreate("Level_5_Max", OBJ_TREND, 0, Time[1], level, Time[0], level);

    if (SPLIT_POSITION) {
        unitTest.assertEquals(
            1.8,
            calculateTakeProfitFactor(openPrice, stopLossPips, Max)
        );
    } else {
        unitTest.assertEquals(
            1.1,
            calculateTakeProfitFactor(openPrice, stopLossPips, Max)
        );
    }

    ObjectsDeleteAll();

    level = openPrice - 1 * Pip();
    ObjectCreate("Level_1_Min", OBJ_TREND, 0, Time[1], level, Time[0], level);

    unitTest.assertEquals(
        MAX_TAKE_PROFIT_FACTOR,
        calculateTakeProfitFactor(openPrice, stopLossPips, Min)
    );

    level = openPrice - 35 * Pip();
    ObjectCreate("Level_2_Min", OBJ_TREND, 0, Time[1], level, Time[0], level);

    unitTest.assertEquals(
        2.1,
        calculateTakeProfitFactor(openPrice, stopLossPips, Min)
    );

    level = openPrice - 30 * Pip();
    ObjectCreate("Level_3_Min", OBJ_TREND, 0, Time[1], level, Time[0], level);

    unitTest.assertEquals(
        1.8,
        calculateTakeProfitFactor(openPrice, stopLossPips, Min)
    );

    ObjectsDeleteAll();
}

void OrderCreateTest::calculateSizeFactorTest() {
    UnitTest unitTest("calculateSizeFactorTest");

    const double price = GetAsk();
    const string symbol = Symbol();

    unitTest.assertEquals(
        0.0,
        calculateSizeFactor(OP_SELL, price, symbol)
    );

    unitTest.assertEquals(
        0.0,
        calculateSizeFactor(OP_BUYSTOP, -price, symbol)
    );

    unitTest.assertEquals(
        0.0,
        calculateSizeFactor(OP_SELLSTOP, price, "CIAO")
    );

    Pivot pivot;
    if ((price > pivot.getPivotRS(symbol, D1, R2) ||
        price < pivot.getPivotRS(symbol, D1, S2)) &&
        Period() != PERIOD_H4) {
        // red configuration
        unitTest.assertEquals(
            0.0,
            calculateSizeFactor(OP_BUYSTOP, price, symbol)
        );
    } else {
        unitTest.assertTrue(
            calculateSizeFactor(OP_BUYSTOP, price, symbol) > 0
        );
        unitTest.assertTrue(
            calculateSizeFactor(OP_BUYSTOP, price, symbol) < 2
        );
    }
}

void OrderCreateTest::calculateOrderLotsTest() {
    UnitTest unitTest("calculateOrderLotsTest");

    const int stopLossPips = 10;
    const string symbol = Symbol();

    unitTest.assertEquals(
        0.0,
        calculateOrderLots(stopLossPips, 0, symbol)
    );

    unitTest.assertEquals(
        NormalizeDouble(calculateOrderLots(stopLossPips, 1, symbol) / 2, 2),
        calculateOrderLots(stopLossPips, 1, symbol) / 2
    );

    unitTest.assertEquals(
        0.02,
        calculateOrderLots(stopLossPips, 0.0001, symbol)
    );

    unitTest.assertTrue(
        calculateOrderLots(stopLossPips, 1.5, symbol) > calculateOrderLots(stopLossPips, 1, symbol)
    );

    unitTest.assertTrue(
        calculateOrderLots(stopLossPips, 1, symbol) > 0
    );

    unitTest.assertTrue(
        calculateOrderLots(stopLossPips, 1, symbol) < 30 // max lots allowed per operation
    );
}

void OrderCreateTest::getPercentRiskTest() {
    UnitTest unitTest("getPercentRiskTest");

    if (AccountNumber() == 2100183900) {
        unitTest.assertEquals(
            0.015,
            getPercentRisk()
        );
    } else {
        unitTest.assertEquals(
            PERCENT_RISK / 100,
            getPercentRisk()
        );
    }
}

void OrderCreateTest::buildOrderCommentTest() {
    UnitTest unitTest("buildOrderCommentTest");

    // OrderTrail relies on this comment structure for splitPosition

    unitTest.assertEquals(
        "A P60 M1 R3 S10",
        buildOrderComment(PERIOD_H1, 1, 3, 10)
    );

    unitTest.assertEquals(
        "A P240 M1.2 R2.8 S12",
        buildOrderComment(PERIOD_H4, 1.2, 2.8, 12)
    );

    // It truncates a long comment
    unitTest.assertEquals(
        "A P30 M1.3 R2.5 S123",
        buildOrderComment(PERIOD_M30, 1.3, 2.5, 123456789)
    );
}

void OrderCreateTest::getSizeFactorFromCommentTest() {
    UnitTest unitTest("getSizeFactorFromCommentTest");

    string comment = "A P30 M1.3 R3 S10";

    unitTest.assertEquals(
        1.3,
        getSizeFactorFromComment(comment)
    );

    comment = "A P30 M1 R3 S10";

    unitTest.assertEquals(
        1.0,
        getSizeFactorFromComment(comment)
    );

    comment = "M0.8";

    unitTest.assertEquals(
        0.8,
        getSizeFactorFromComment(comment)
    );

    comment = "A P30 W1 R3 S10";

    unitTest.assertEquals(
        -1.0,
        getSizeFactorFromComment(comment)
    );

    comment = "W1";

    unitTest.assertEquals(
        -1.0,
        getSizeFactorFromComment(comment)
    );

    comment = "asdasdM123asdasd";

    unitTest.assertEquals(
        123.0,
        getSizeFactorFromComment(comment)
    );
}
