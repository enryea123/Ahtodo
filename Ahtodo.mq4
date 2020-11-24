#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property description "Enrico Albano's automated bot for Ahtodo"

#include "src/drawer/Drawer.mqh"
#include "src/market/Market.mqh"
#include "tst/UnitTestsRunner.mqh"

input double PercentRisk = NULL; // getPercentRisk: if !PercentRisk -> get from list of account owners


void OnInit() {
    RefreshRates();
    Sleep(1000);

    UnitTestsRunner unitTestsRunner;
    unitTestsRunner.runAllUnitTests();

    // Market opening stuff, check Ahtodo_mono for info

    Market market;
    market.startUpMarketValidation();

    Drawer drawer;
    drawer.setChartDefaultColors();
    drawer.drawEverything();

}

void OnTick() {
    Sleep(1000);

    Drawer drawer;
    drawer.drawEverything();

    Print("Ciao");
}

void OnDeinit(const int reason) {
    Drawer drawer;
    drawer.setChartMarketOpenColors();

    ObjectsDeleteAll();
}
