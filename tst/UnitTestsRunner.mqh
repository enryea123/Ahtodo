#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../Constants.mqh"
#include "extreme/ArrowStyleTest.mqh"
#include "market/HolidayTest.mqh"
#include "market/MarketTest.mqh"
#include "market/MarketTimeTest.mqh"
#include "order/OrderFindTest.mqh"
#include "pattern/PatternTest.mqh"
#include "pivot/PivotTest.mqh"
#include "pivot/PivotStyleTest.mqh"
#include "trendline/TrendLineTest.mqh"


class UnitTestsRunner {
    public:
        void runAllUnitTests();
};

void UnitTestsRunner::runAllUnitTests() {
    const int startTime = TimeLocal();

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

    OrderFindTest orderFindTest;
    orderFindTest.getOrdersListTest();
    orderFindTest.getFilteredOrdersListTest();

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

    const int endTime = TimeLocal() - startTime;
    Print("All unit tests run in ", endTime, " seconds");
}
