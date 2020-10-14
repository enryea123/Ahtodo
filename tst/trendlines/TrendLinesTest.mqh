#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/trendlines/TrendLines.mqh"


class TrendLinesTest{
    public:
        TrendLinesTest();
        ~TrendLinesTest();

        void isTrendLineGoodForPendingOrderTest();
        void getTrendLineIndexesTest();
        void trendLineNameTest();
        void trendLineSetupsTest();

    private:
        TrendLines trendLines_;
};

TrendLinesTest::TrendLinesTest():
    trendLines_(){
}

TrendLinesTest::~TrendLinesTest(){}

void TrendLinesTest::isTrendLineGoodForPendingOrderTest(){
    UnitTest unitTest("isTrendLineGoodForPendingOrderTest");

    unitTest.assertTrue(
        trendLines_.isTrendLineGoodForPendingOrder(trendLines_.buildTrendLineName(50, 30, 0, Max), 1)
    );

    unitTest.assertFalse(
        trendLines_.isTrendLineGoodForPendingOrder(trendLines_.buildBadTrendLineName(50, 30, 0, Max), 1)
    );

    unitTest.assertFalse(
        trendLines_.isTrendLineGoodForPendingOrder("randomString", 1)
    );

    const int timeIndex = 1;
    const int bigTimeIndex = TRENDLINES_MIN_EXTREMES_DISTANCE - timeIndex;

    unitTest.assertTrue(
        trendLines_.isTrendLineGoodForPendingOrder(trendLines_.buildTrendLineName(
            20, TRENDLINES_MIN_EXTREMES_DISTANCE + timeIndex, 0, Max), timeIndex)
    );

    unitTest.assertFalse(
        trendLines_.isTrendLineGoodForPendingOrder(trendLines_.buildTrendLineName(
            20, TRENDLINES_MIN_EXTREMES_DISTANCE + timeIndex, 0, Max), bigTimeIndex)
    );
}

void TrendLinesTest::getTrendLineIndexesTest(){
    UnitTest unitTest("getTrendLineIndexesTest");

    unitTest.assertEquals(
        50,
        trendLines_.getTrendLineMaxIndex("TrendLine_i50_j9_b-2_Max"),
        "TrendLine_i50_j9_b-2_Max"
    );

    unitTest.assertEquals(
        130,
        trendLines_.getTrendLineMaxIndex("TrendLine_i130_j9_b1_Min"),
        "TrendLine_i130_j9_b1_Min"
    );

    unitTest.assertEquals(
        20,
        trendLines_.getTrendLineMinIndex("TrendLine_i130_j20_b0_Max"),
        "TrendLine_i130_j20_b0_Max"
    );

    unitTest.assertEquals(
        5,
        trendLines_.getTrendLineMinIndex("TrendLine_i30_j5_b1_Max"),
        "TrendLine_i30_j5_b1_Max"
    );

    unitTest.assertEquals(
        -1,
        trendLines_.getTrendLineMaxIndex("RandomString"),
        "RandomString"
    );

    unitTest.assertEquals(
        -1,
        trendLines_.getTrendLineMaxIndex("TrendLine_WrongNameSent"),
        "TrendLine_WrongNameSent"
    );

    unitTest.assertEquals(
        -1,
        trendLines_.getTrendLineMaxIndex("TrendLine_Wrong_Name_Sent_To_Test"),
        "TrendLine_Wrong_Name_Sent_To_Test"
    );
}

void TrendLinesTest::trendLineNameTest(){
    UnitTest unitTest("trendLineNameTest");

    unitTest.assertEquals(
        "TrendLine_i50_j9_b-2_Max",
        trendLines_.buildTrendLineName(50, 9, -2, Max)
    );

    unitTest.assertEquals(
        "TrendLine_i130_j20_b0_Min_Bad",
        trendLines_.buildBadTrendLineName(130, 20, 0, Min)
    );

    unitTest.assertTrue(
        trendLines_.isBadTrendLineFromName("TrendLine_i130_j20_b0_Min_Bad")
    );

    unitTest.assertFalse(
        trendLines_.isBadTrendLineFromName("TrendLine_i50_j20_b0_Max")
    );
}

void TrendLinesTest::trendLineSetupsTest(){
    UnitTest unitTest("trendLineSetupsTest");

    unitTest.assertFalse(
        trendLines_.areTrendLineSetupsGood(10, 30, Max)
    );

    unitTest.assertFalse(
        trendLines_.areTrendLineSetupsGood(20, -1, Max)
    );

    unitTest.assertFalse(
        trendLines_.areTrendLineSetupsGood(9, 5, Max)
    );

    unitTest.assertFalse(
        trendLines_.areTrendLineSetupsGood(10, 9, Max)
    );

    unitTest.assertFalse(
        trendLines_.areTrendLineSetupsGood(100, 98, Max)
    );

    if(iExtreme(50, Min) > iExtreme(20, Min)){
        unitTest.assertFalse(
            trendLines_.areTrendLineSetupsGood(50, 20, Min),
            "Incorrect slope test - Min"
        );
    }else if(iExtreme(50, Max) < iExtreme(20, Max)){
        unitTest.assertFalse(
            trendLines_.areTrendLineSetupsGood(50, 20, Max),
            "Incorrect slope test - Max"
        );
    }else{
        Print("trendLineSetupsTest(): incorrect slope test skipped..");
    }

    const double slopeMin = (iExtreme(20, Min) - iExtreme(50, Min)) / (50 - 20);
    const double slopeMax = (iExtreme(20, Max) - iExtreme(50, Max)) / (50 - 20);

    if(slopeMin > 0 && MathAbs(slopeMin) > POSITIVE_SLOPE_VOLATILITY * GetMarketVolatility()){
        unitTest.assertFalse(
            trendLines_.areTrendLineSetupsGood(50, 20, Min),
            "POSITIVE_SLOPE_VOLATILITY"
        );
    }else if(slopeMax < 0 && MathAbs(slopeMax) > NEGATIVE_SLOPE_VOLATILITY * GetMarketVolatility()){
        unitTest.assertFalse(
            trendLines_.areTrendLineSetupsGood(50, 20, Max),
            "NEGATIVE_SLOPE_VOLATILITY"
        );
    }else{
        Print("trendLineSetupsTest(): excessive slope test skipped..");
    }
}
