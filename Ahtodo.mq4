#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property description "Enrico Albano's automated bot for Ahtodo"
#property strict

#include "src/drawer/Drawer.mqh"
#include "src/market/Market.mqh"
#include "src/order/OrderCreate.mqh"
#include "src/order/OrderManage.mqh"
#include "src/order/OrderTrail.mqh"
#include "tst/UnitTestsRunner.mqh"


void OnInit() {
    while (!IsConnected()) {
        Sleep(2000);
    }

    const datetime startTime = TimeLocal();

    if (!DownloadHistory()) {
        ThrowFatalException(__FUNCTION__, "Could not download history data, retry or download it manually");
        return;
    }
    Sleep(2000);

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

    Print("Initialization completed in ", TimeLocal() - startTime, " seconds");
    INITIALIZATION_COMPLETED = true;
}

void OnTick() {
    DownloadHistory();
    Sleep(500);

    Drawer drawer;
    Market market;
    OrderManage orderManage;

    orderManage.emergencySwitchOff();
    market.marketConditionsValidation();
    drawer.drawEverything();

    if (market.isMarketOpened()) {
        drawer.setChartMarketOpenedColors();

        if (!orderManage.areThereOpenOrders()) { /// could be split better between classes? Some preconditions here, some there..
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
    INITIALIZATION_COMPLETED = false;
}
