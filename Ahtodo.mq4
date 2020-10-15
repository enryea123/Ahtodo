#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property description "Enrico Albano's automated bot for Ahtodo"

#include "src/patterns/PatternsDraw.mqh"
#include "src/trendlines/TrendLinesDraw.mqh"
#include "tst/UnitTestsRunner.mqh"


void OnInit(){
    UnitTestsRunner unitTestsRunner;
    unitTestsRunner.runAllUnitTests();


    TrendLinesDraw trendLinesDraw;
    trendLinesDraw.drawTrendLines();

    PatternsDraw patternsDraw;
    patternsDraw.drawAllPatterns();
}

void OnTick(){
    Print("Ciao");
}
