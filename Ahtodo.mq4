#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property description "Enrico Albano's automated bot for Ahtodo"

#include "src/candles/PatternsDraw.mqh"
#include "src/extremes/ExtremesDraw.mqh"
#include "src/trendlines/TrendLinesDraw.mqh"
#include "tst/UnitTestsRunner.mqh"

void DoEverythingTestFunction(){

    UnitTestsRunner unitTestsRunner;
    unitTestsRunner.runAllUnitTests();


    TrendLinesDraw trendLinesDraw;
    trendLinesDraw.drawTrendLines();

    PatternsDraw patternsDraw;
    patternsDraw.drawAllPatterns();
}

void OnInit(){
    DoEverythingTestFunction(); // forse non serve
}

void OnTick(){
    Print("Ciao");
}

// manca fare PatternTest e CandleTest ora
// è ora di fare il setup di git
