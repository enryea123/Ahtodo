#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../Constants.mqh"
#include "extreme/ArrowStyleTest.mqh"
#include "market/HolidayTest.mqh"
#include "market/MarketTest.mqh"
#include "market/MarketTimeTest.mqh"
#include "order/OrderFindTest.mqh"
#include "order/OrderCreateTest.mqh"
#include "order/OrderManageTest.mqh"
#include "order/OrderTrailTest.mqh"
#include "pattern/PatternTest.mqh"
#include "pivot/PivotTest.mqh"
#include "pivot/PivotStyleTest.mqh"
#include "trendline/TrendLineTest.mqh"


class UnitTestsRunner {
    public:
        void runAllUnitTests();
};

void UnitTestsRunner::runAllUnitTests() {
    const datetime startTime = TimeLocal();

    ArrowStyleTest arrowStyleTest;
    arrowStyleTest.drawExtremeArrowTest();

    HolidayTest holidayTest;
    holidayTest.isMajorBankHolidayTest();
    holidayTest.isMinorBankHolidayTest();

    MarketTest marketTest;
    marketTest.isMarketOpenedTest();
    marketTest.isAllowedAccountNumberTest();
    marketTest.isAllowedExecutionDateTest();
    marketTest.isAllowedPeriodTest();
    marketTest.isAllowedBrokerTest();
    marketTest.isAllowedSymbolTest();
    marketTest.isAllowedSymbolPeriodComboTest();
    marketTest.isDemoTradingTest();

    MarketTimeTest marketTimeTest;
    marketTimeTest.hasDateChangedTest();
    marketTimeTest.findDayOfWeekOccurrenceInMonthTest();
    marketTimeTest.getDaylightSavingCorrectionsTest();
    marketTimeTest.timeAtMidnightTest();
    marketTimeTest.timeShiftInHoursTest();

    OrderCreateTest orderCreateTest;
    orderCreateTest.areThereRecentOrdersTest();
    orderCreateTest.areThereBetterOrdersTest();
    orderCreateTest.calculateOrderTypeFromSetupsTest();
    orderCreateTest.calculateSizeFactorTest();
    orderCreateTest.calculateOrderLotsTest();
    orderCreateTest.buildOrderCommentTest();
    orderCreateTest.getSizeFactorFromCommentTest();

    OrderFindTest orderFindTest;
    orderFindTest.getOrdersListTest();
    orderFindTest.getFilteredOrdersListTest();

    OrderManageTest orderManageTest;
    orderManageTest.areThereOpenOrdersTest();
    orderManageTest.findBestOrderTest();
    orderManageTest.deduplicateOrdersTest();
    orderManageTest.emergencySwitchOffTest();
    orderManageTest.lossLimiterTest();
    orderManageTest.deleteAllOrdersTest();
    orderManageTest.deletePendingOrdersTest();

    OrderTrailTest orderTrailTest;
    orderTrailTest.splitPositionTest();
    orderTrailTest.breakEvenStopLossTest();

    PatternTest patternTest;
    patternTest.isPatternTest();

    PivotTest pivotTest;
    pivotTest.getPivotHappyPathTest();
    pivotTest.getPivotNegativeTimeIndexTest();
    pivotTest.getPivotUnexistestSymbolTest();
    pivotTest.getPivotRSHappyPathTest();
    pivotTest.getPivotRSUnexistestSymbolTest();

    PivotStyleTest pivotStyleTest;
    pivotStyleTest.pivotStyleBaseTest();
    pivotStyleTest.pivotRSLabelColorTest();
    pivotStyleTest.pivotRSLabelNameTest();

    TrendLineTest trendLineTest;
    trendLineTest.isGoodTrendLineFromNameTest();
    trendLineTest.getTrendLineIndexesTest();
    trendLineTest.trendLineNameTest();
    trendLineTest.trendLineSetupsTest();

    UNIT_TESTS_COMPLETED = true;
    Print("All unit tests run in ", TimeLocal() - startTime, " seconds");
}
