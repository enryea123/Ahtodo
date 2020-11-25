#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property description "Enrico Albano's automated bot for Ahtodo"

#include "src/drawer/Drawer.mqh"
#include "src/market/Market.mqh"
#include "tst/UnitTestsRunner.mqh"

// make these 2 (and MarketTime and Holiday) static singletons? Then cleanup in DeInit.
// Cosi potrebbero essere inizializzate in OnInit con nomi normali (no default)
// https://www.mql5.com/en/forum/160423 (static & SINGLETON)
// https://www.mql5.com/en/forum/159069 (DISALLOW_COPY_AND_ASSIGN)
Drawer defaultDrawer;
Market defaultMarket;


void OnInit() {
    STARTUP_TIME = TimeLocal();

    RefreshRates();
    Sleep(1000);

    UnitTestsRunner unitTestsRunner;
    unitTestsRunner.runAllUnitTests();

    defaultDrawer.setChartDefaultColors();

    if (!defaultMarket.isMarketOpened()) {
        defaultDrawer.setChartMarketClosedColors();
    }

    defaultMarket.marketConditionsValidation();
    defaultDrawer.drawEverything();
}

void OnTick() {
    RefreshRates();
    Sleep(1000);

    defaultMarket.marketConditionsValidation();
    defaultDrawer.drawEverything();

    if (defaultMarket.isMarketOpened()) {
        defaultDrawer.setChartMarketOpenedColors();

        if (!IsTradeAllowed()) {
            return;
        }

//        if (!AreThereOpenOrders()) {
//            if (Hour() >= MARKET_CLOSE_HOUR_PENDING) {
//                DeletePendingOrdersThisSymbolThisPeriod();
//                return;
//            }
//
//            PutPendingOrder(); // order.putNewOrder();
//        } else {
//            OrderTrailing(); // order.manageOpenedOrders();
//        }
    } else {
        defaultDrawer.setChartMarketClosedColors();
        // CloseAllPositions(); // order.closeAllOrders();
    }
}

void OnDeinit(const int reason) {
    defaultDrawer.setChartDefaultColors();
    ObjectsDeleteAll();
}
