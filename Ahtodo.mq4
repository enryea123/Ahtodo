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


// News: https://www.mql5.com/en/articles/1502
// Livelli orizzontali per takeProfit
// StopLoss trailing sotto al minimo precedente
// Log quando ordine già a breakeven va sotto 0 (filtra commenti con "#from 123891")
// Salvare dettagli ordine su un log separato, sia per dropbox che per dimezzare
// Chiudere la sofferenza e se un trade è in negativo o senza breakeven dopo 30 min
// Dopo che la pending hour è passata, metti il grafico grigio se non ci sono ordini aperti
// Unire bots di diversi timeframe in uno solo, così non si toglierebbe da D1
// Sostituisci tutti gli int period con ENUM_TIMEFRAMES. Farlo anche con Symbol? https://www.mql5.com/en/forum/216344
// DownloadHistory, serve variable array se lo scarico per tutti?


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
