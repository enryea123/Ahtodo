#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#property description "Enrico Albano's automated bot for Ahtodo"
#property version "2.0"

#include "src/drawer/Drawer.mqh"
#include "src/market/Market.mqh"
#include "src/order/OrderCreate.mqh"
#include "src/order/OrderManage.mqh"
#include "src/order/OrderTrail.mqh"
#include "src/util/Price.mqh"
#include "tst/UnitTestsRunner.mqh"

/**
 * This is the main file of the program. OnInit is executed only once at the program start.
 * OnTick is executed every time there is a new price update (tick) in the market.
 * OnDeInit is executed at the end of the program, and cleans up some variables.
 */


void OnInit() {
    const datetime startTime = TimeLocal();
    InitializeMaps();

    while (!IsConnected() || AccountNumber() == 0) {
        Sleep(500);
    }

    if (!DownloadHistory()) {
        ThrowFatalException(__FUNCTION__, "Could not download history data, retry or download it manually");
        return;
    }

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
}

void OnTick() {
    DownloadHistory();
    Sleep(200);

    Drawer drawer;
    Market market;
    OrderManage orderManage;

    orderManage.emergencySwitchOff();
    market.marketConditionsValidation();
    drawer.drawEverything();

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
    UNIT_TESTS_COMPLETED = false;
}
