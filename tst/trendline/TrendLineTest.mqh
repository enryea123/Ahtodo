#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/trendline/TrendLine.mqh"


class TrendLineTest: public TrendLine {
    public:
        void isGoodTrendLineFromNameTest();
        void getTrendLineIndexesTest();
        void trendLineNameTest();
        void trendLineSetupsTest();
};

void TrendLineTest::isGoodTrendLineFromNameTest() {
    UnitTest unitTest("isGoodTrendLineFromNameTest");

    unitTest.assertTrue(
        isGoodTrendLineFromName(buildTrendLineName(50, 30, 0, Max))
    );

    unitTest.assertFalse(
        isGoodTrendLineFromName(buildBadTrendLineName(50, 30, 0, Max), 1)
    );

    unitTest.assertFalse(
        isGoodTrendLineFromName("randomString", 1)
    );

    const int timeIndex = 1;
    const int bigTimeIndex = TRENDLINE_MIN_EXTREMES_DISTANCE - timeIndex;

    unitTest.assertTrue(
        isGoodTrendLineFromName(buildTrendLineName(
            20, TRENDLINE_MIN_EXTREMES_DISTANCE + timeIndex, 0, Max), timeIndex)
    );

    unitTest.assertFalse(
        isGoodTrendLineFromName(buildTrendLineName(
            20, TRENDLINE_MIN_EXTREMES_DISTANCE + timeIndex, 0, Max), bigTimeIndex)
    );
}

void TrendLineTest::getTrendLineIndexesTest() {
    UnitTest unitTest("getTrendLineIndexesTest");

    unitTest.assertEquals(
        50,
        getTrendLineMaxIndex("TrendLine_i50_j9_b-2_Max"),
        "TrendLine_i50_j9_b-2_Max"
    );

    unitTest.assertEquals(
        130,
        getTrendLineMaxIndex("TrendLine_i130_j9_b1_Min"),
        "TrendLine_i130_j9_b1_Min"
    );

    unitTest.assertEquals(
        20,
        getTrendLineMinIndex("TrendLine_i130_j20_b0_Max"),
        "TrendLine_i130_j20_b0_Max"
    );

    unitTest.assertEquals(
        5,
        getTrendLineMinIndex("TrendLine_i30_j5_b1_Max"),
        "TrendLine_i30_j5_b1_Max"
    );

    unitTest.assertEquals(
        -1,
        getTrendLineMaxIndex("RandomString"),
        "RandomString"
    );

    unitTest.assertEquals(
        -1,
        getTrendLineMaxIndex("TrendLine_WrongNameSent"),
        "TrendLine_WrongNameSent"
    );

    unitTest.assertEquals(
        -1,
        getTrendLineMaxIndex("TrendLine_Wrong_Name_Sent_To_Test"),
        "TrendLine_Wrong_Name_Sent_To_Test"
    );
}

void TrendLineTest::trendLineNameTest() {
    UnitTest unitTest("trendLineNameTest");

    unitTest.assertEquals(
        "TrendLine_i50_j9_b-2_Max",
        buildTrendLineName(50, 9, -2, Max)
    );

    unitTest.assertEquals(
        "TrendLine_i130_j20_b0_Min_Bad",
        buildBadTrendLineName(130, 20, 0, Min)
    );

    unitTest.assertTrue(
        isBadTrendLineFromName("TrendLine_i130_j20_b0_Min_Bad")
    );

    unitTest.assertFalse(
        isBadTrendLineFromName("TrendLine_i50_j20_b0_Max")
    );
}

void TrendLineTest::trendLineSetupsTest() {
    UnitTest unitTest("trendLineSetupsTest");

    unitTest.assertFalse(
        areTrendLineSetupsGood(10, 30, Max)
    );

    unitTest.assertFalse(
        areTrendLineSetupsGood(20, -1, Max)
    );

    unitTest.assertFalse(
        areTrendLineSetupsGood(9, 5, Max)
    );

    unitTest.assertFalse(
        areTrendLineSetupsGood(10, 9, Max)
    );

    unitTest.assertFalse(
        areTrendLineSetupsGood(100, 98, Max)
    );

    if (iExtreme(Min, 50) > iExtreme(Min, 20)) {
        unitTest.assertFalse(
            areTrendLineSetupsGood(50, 20, Min),
            "Incorrect slope test - Min"
        );
    } else if (iExtreme(Max, 50) < iExtreme(Max, 20)) {
        unitTest.assertFalse(
            areTrendLineSetupsGood(50, 20, Max),
            "Incorrect slope test - Max"
        );
    } else if (IS_DEBUG) {
        Print("trendLineSetupsTest: incorrect slope test skipped..");
    }

    const double slopeMin = (iExtreme(Min, 20) - iExtreme(Min, 50)) / (50 - 20);
    const double slopeMax = (iExtreme(Max, 20) - iExtreme(Max, 50)) / (50 - 20);

    if (slopeMin > 0 && MathAbs(slopeMin) >
        TRENDLINE_POSITIVE_SLOPE_VOLATILITY * GetMarketVolatility()) {
        unitTest.assertFalse(
            areTrendLineSetupsGood(50, 20, Min),
            "TrendLine positive slope volatility"
        );
    } else if (slopeMax < 0 && MathAbs(slopeMax) >
        TRENDLINE_NEGATIVE_SLOPE_VOLATILITY * GetMarketVolatility()) {
        unitTest.assertFalse(
            areTrendLineSetupsGood(50, 20, Max),
            "TrendLine negative slope volatility"
        );
    } else if (IS_DEBUG) {
        Print("trendLineSetupsTest: excessive slope test skipped..");
    }
}
