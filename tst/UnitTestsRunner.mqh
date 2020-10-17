#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../Constants.mqh"
#include "extreme/ArrowStyleTest.mqh"
#include "pattern/PatternTest.mqh"
#include "pivot/PivotTest.mqh"
#include "pivot/PivotStyleTest.mqh"
#include "trendline/TrendLineTest.mqh"


class UnitTestsRunner{
    public:
        UnitTestsRunner();
        ~UnitTestsRunner();

        void runAllUnitTests();
};

UnitTestsRunner::UnitTestsRunner(){}

UnitTestsRunner::~UnitTestsRunner(){}

void UnitTestsRunner::runAllUnitTests(){
    int startTime = TimeLocal(); // TimeCurrent is the Broker's time

    ArrowStyleTest arrowStyleTest;
    arrowStyleTest.drawExtremeArrowTest();

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
    trendLineTest.isTrendLineGoodForPendingOrderTest();
    trendLineTest.getTrendLineIndexesTest();
    trendLineTest.trendLineNameTest();
    trendLineTest.trendLineSetupsTest();

    PatternTest patternTest;
    patternTest.isPatternTest();

    int endTime = TimeLocal() - startTime;
    Print("All unit tests run in ", endTime, " seconds. StartTime: ", TimeToStr(startTime));
}
