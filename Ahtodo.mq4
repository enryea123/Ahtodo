#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property description "Enrico Albano's automated bot for Ahtodo"

#include "src/drawer/Drawer.mqh"
#include "src/market/Market.mqh"
#include "tst/UnitTestsRunner.mqh"

Drawer drawer;
Market market;


void OnInit() {
    STARTUP_TIME = TimeLocal();

    UnitTestsRunner unitTestsRunner;
    unitTestsRunner.runAllUnitTests();

    drawer.setChartDefaultColors();

    if (!market.isMarketOpened()) {
        drawer.setChartMarketClosedColors();
    }

    market.marketConditionsValidation();
    drawer.drawEverything();

    FinalizeInitialization();
}

void OnTick() {
    market.marketConditionsValidation();
    drawer.drawEverything();

    if (market.isMarketOpened()) {
        drawer.setChartMarketOpenedColors();

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
        drawer.setChartMarketClosedColors();
        // CloseAllPositions(); // order.closeAllOrders();
    }
}

void OnDeinit(const int reason) {
    drawer.setChartDefaultColors();
    ObjectsDeleteAll();
}
