#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/trendline/TrendLine.mqh"


class TrendLineTest {
    public:
        void isTrendLineGoodForPendingOrderTest();
        void getTrendLineIndexesTest();
        void trendLineNameTest();
        void trendLineSetupsTest();

    private:
        TrendLine trendLine_;
};

void TrendLineTest::isTrendLineGoodForPendingOrderTest() {
    UnitTest unitTest("isTrendLineGoodForPendingOrderTest");

    unitTest.assertTrue(
        trendLine_.isTrendLineGoodForPendingOrder(trendLine_.buildTrendLineName(50, 30, 0, Max), 1)
    );

    unitTest.assertFalse(
        trendLine_.isTrendLineGoodForPendingOrder(trendLine_.buildBadTrendLineName(50, 30, 0, Max), 1)
    );

    unitTest.assertFalse(
        trendLine_.isTrendLineGoodForPendingOrder("randomString", 1)
    );

    const int timeIndex = 1;
    const int bigTimeIndex = trendLine_.trendLineMinExtremesDistance_ - timeIndex;

    unitTest.assertTrue(
        trendLine_.isTrendLineGoodForPendingOrder(trendLine_.buildTrendLineName(
            20, trendLine_.trendLineMinExtremesDistance_ + timeIndex, 0, Max), timeIndex)
    );

    unitTest.assertFalse(
        trendLine_.isTrendLineGoodForPendingOrder(trendLine_.buildTrendLineName(
            20, trendLine_.trendLineMinExtremesDistance_ + timeIndex, 0, Max), bigTimeIndex)
    );
}

void TrendLineTest::getTrendLineIndexesTest() {
    UnitTest unitTest("getTrendLineIndexesTest");

    unitTest.assertEquals(
        50,
        trendLine_.getTrendLineMaxIndex("TrendLine_i50_j9_b-2_Max"),
        "TrendLine_i50_j9_b-2_Max"
    );

    unitTest.assertEquals(
        130,
        trendLine_.getTrendLineMaxIndex("TrendLine_i130_j9_b1_Min"),
        "TrendLine_i130_j9_b1_Min"
    );

    unitTest.assertEquals(
        20,
        trendLine_.getTrendLineMinIndex("TrendLine_i130_j20_b0_Max"),
        "TrendLine_i130_j20_b0_Max"
    );

    unitTest.assertEquals(
        5,
        trendLine_.getTrendLineMinIndex("TrendLine_i30_j5_b1_Max"),
        "TrendLine_i30_j5_b1_Max"
    );

    unitTest.assertEquals(
        -1,
        trendLine_.getTrendLineMaxIndex("RandomString"),
        "RandomString"
    );

    unitTest.assertEquals(
        -1,
        trendLine_.getTrendLineMaxIndex("TrendLine_WrongNameSent"),
        "TrendLine_WrongNameSent"
    );

    unitTest.assertEquals(
        -1,
        trendLine_.getTrendLineMaxIndex("TrendLine_Wrong_Name_Sent_To_Test"),
        "TrendLine_Wrong_Name_Sent_To_Test"
    );
}

void TrendLineTest::trendLineNameTest() {
    UnitTest unitTest("trendLineNameTest");

    unitTest.assertEquals(
        "TrendLine_i50_j9_b-2_Max",
        trendLine_.buildTrendLineName(50, 9, -2, Max)
    );

    unitTest.assertEquals(
        "TrendLine_i130_j20_b0_Min_Bad",
        trendLine_.buildBadTrendLineName(130, 20, 0, Min)
    );

    unitTest.assertTrue(
        trendLine_.isBadTrendLineFromName("TrendLine_i130_j20_b0_Min_Bad")
    );

    unitTest.assertFalse(
        trendLine_.isBadTrendLineFromName("TrendLine_i50_j20_b0_Max")
    );
}

void TrendLineTest::trendLineSetupsTest() {
    UnitTest unitTest("trendLineSetupsTest");

    unitTest.assertFalse(
        trendLine_.areTrendLineSetupsGood(10, 30, Max)
    );

    unitTest.assertFalse(
        trendLine_.areTrendLineSetupsGood(20, -1, Max)
    );

    unitTest.assertFalse(
        trendLine_.areTrendLineSetupsGood(9, 5, Max)
    );

    unitTest.assertFalse(
        trendLine_.areTrendLineSetupsGood(10, 9, Max)
    );

    unitTest.assertFalse(
        trendLine_.areTrendLineSetupsGood(100, 98, Max)
    );

    if (iExtreme(50, Min) > iExtreme(20, Min)) {
        unitTest.assertFalse(
            trendLine_.areTrendLineSetupsGood(50, 20, Min),
            "Incorrect slope test - Min"
        );
    }else if (iExtreme(50, Max) < iExtreme(20, Max)) {
        unitTest.assertFalse(
            trendLine_.areTrendLineSetupsGood(50, 20, Max),
            "Incorrect slope test - Max"
        );
    } else {
        Print("trendLineSetupsTest(): incorrect slope test skipped..");
    }

    const double slopeMin = (iExtreme(20, Min) - iExtreme(50, Min)) / (50 - 20);
    const double slopeMax = (iExtreme(20, Max) - iExtreme(50, Max)) / (50 - 20);

    if (slopeMin > 0 && MathAbs(slopeMin) >
        trendLine_.trendLinePositiveSlopeVolatility_ * GetMarketVolatility()) {
        unitTest.assertFalse(
            trendLine_.areTrendLineSetupsGood(50, 20, Min),
            "TrendLine positive slope volatility"
        );
    }else if (slopeMax < 0 && MathAbs(slopeMax) >
        trendLine_.trendLineNegativeSlopeVolatility_ * GetMarketVolatility()) {
        unitTest.assertFalse(
            trendLine_.areTrendLineSetupsGood(50, 20, Max),
            "TrendLine negative slope volatility"
        );
    } else {
        Print("trendLineSetupsTest(): excessive slope test skipped..");
    }
}
