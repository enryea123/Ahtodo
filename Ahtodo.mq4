#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property description "Enrico Albano's automated bot for Ahtodo"

#include "src/drawer/Drawer.mqh"
#include "tst/UnitTestsRunner.mqh"


void OnInit() {
    STARTUP_TIME = TimeLocal();

    RefreshRates();
    Sleep(1000);

    UnitTestsRunner unitTestsRunner;
    unitTestsRunner.runAllUnitTests();

    // Market opening stuff, check Ahtodo_mono for info

    Drawer drawer;
    drawer.setChartDefaultColors();
    drawer.drawEverything();

}

void OnTick() {
    RefreshRates();
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
