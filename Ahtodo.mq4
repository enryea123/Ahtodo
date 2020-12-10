#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property description "Enrico Albano's automated bot for Ahtodo"

#include "src/drawer/Drawer.mqh"
#include "src/market/Market.mqh"
#include "tst/UnitTestsRunner.mqh"


void OnInit() {
    if (!DownloadHistory()) {
        ThrowFatalException(__FUNCTION__, "Could not download history data, retry or download it manually");
        return;
    }
    Sleep(2000);

    STARTUP_TIME = TimeLocal();

    UnitTestsRunner unitTestsRunner;
    unitTestsRunner.runAllUnitTests();

    Drawer drawer;
    Market market;

    drawer.setChartDefaultColors();

    if (!market.isMarketOpened()) {
        drawer.setChartMarketClosedColors();
    }

    market.marketConditionsValidation();
    drawer.drawEverything();

    FinalizeInitialization();
}

void OnTick() {
    DownloadHistory();
    Sleep(500);

    Drawer drawer;
    Market market;
    OrderManage orderManage;

    market.marketConditionsValidation();
    drawer.drawEverything();
    orderManage.emergencySwitchOff();

    if (market.isMarketOpened()) {
        drawer.setChartMarketOpenedColors();

        if (!orderManage.areThereOpenOrders()) {
            OrderCreate orderCreate;
            orderCreate.newOrder();
        } else {
            OrderTrail orderTrail;
            orderTrail.manageOpenOrders();
        }

        Pattern pattern;
        if (pattern.isAntiPattern(1) || market.isMarketCloseNoPendingTimeWindow()) {
            orderManage.deletePendingOrders();
        }

        orderManage.lossLimiter();
        orderManage.deduplicateOrders();
    } else {
        drawer.setChartMarketClosedColors();
        orderManage.deleteAllOrders();
    }
}

void OnDeinit(const int reason) {
    Drawer drawer;
    drawer.setChartDefaultColors();
    ObjectsDeleteAll();
}

// FARE FUNZIONE PER? MathRound(MathAbs(order.openPrice - newStopLoss) / Pips())
