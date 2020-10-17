#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../src/Constants.mqh"
#include "extremes/ArrowStyleTest.mqh"
#include "patterns/PatternsTest.mqh"
#include "pivot/PivotTest.mqh"
#include "pivot/PivotStyleTest.mqh"
#include "trendlines/TrendLinesTest.mqh"


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

    TrendLinesTest trendLinesTest;
    trendLinesTest.isTrendLineGoodForPendingOrderTest();
    trendLinesTest.getTrendLineIndexesTest();
    trendLinesTest.trendLineNameTest();
    trendLinesTest.trendLineSetupsTest();

    PatternsTest patternsTest;
    patternsTest.isPatternTest();

    int endTime = TimeLocal() - startTime;
    Print("All unit tests run in ", endTime, " seconds. StartTime: ", TimeToStr(startTime));
}
