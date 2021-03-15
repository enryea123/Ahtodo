#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#property description "Enrico Albano's automated bot for Ahtodo"
#property version "210.315"

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
    const ulong startTime = GetTickCount();
    InitializeMaps();

    while (!IsConnected() || AccountNumber() == 0) {
        Sleep(500);
    }

    if (!DownloadHistory()) {
        ThrowFatalException(__FUNCTION__, "History data is outdated, restart the bot to download it");
        return;
    }

    Drawer drawer;
    Market market;
    OrderManage orderManage;

    if (!market.marketConditionsValidation()) {
        return;
    }

    drawer.setChartDefaultColors();

    if (!market.isMarketOpened() || (market.isMarketCloseNoPendingTimeWindow() &&
        !orderManage.areThereOrdersThisSymbolThisPeriod())) {
        drawer.setChartMarketClosedColors();
    } else {
        drawer.setChartMarketOpenedColors();
    }

    UnitTestsRunner unitTestsRunner;
    unitTestsRunner.runAllUnitTests();

    drawer.drawEverything();

    Print("Initialization completed in ", GetTickCount() - startTime, " ms");
}

void OnTick() {
    DownloadHistory();
    Sleep(500);

    Drawer drawer;
    Market market;
    OrderManage orderManage;

    if (!market.marketConditionsValidation()) {
        return;
    }

    drawer.drawEverything();

    if (!IsTradeAllowed()) {
        drawer.setChartMarketClosedColors();
        return;
    }

    orderManage.emergencySwitchOff();

    if (!market.isMarketOpened() || (market.isMarketCloseNoPendingTimeWindow() &&
        !orderManage.areThereOrdersThisSymbolThisPeriod())) {
        drawer.setChartMarketClosedColors();
    } else {
        drawer.setChartMarketOpenedColors();
    }

    if (market.isMarketOpened()) {
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
        orderManage.deleteAllOrders();
    }
}

void OnDeinit(const int reason) {
    Drawer drawer;
    drawer.setChartDefaultColors();

    ObjectsDeleteAll();
    UNIT_TESTS_COMPLETED = false;
}
