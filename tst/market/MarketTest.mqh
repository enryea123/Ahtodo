#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/market/Market.mqh"


class MarketTest {
    public:
        MarketTest();
        ~MarketTest();

        void isAllowedAccountNumberTest();
        void isAllowedExecutionDateTest();
        void isAllowedPeriodTest();
        void isAllowedSymbolTest();
        void isAllowedSymbolPeriodComboTest();
        void isDemoTradingTest();

    private:
        Market market_;
};

MarketTest::MarketTest():
    market_() {
}

MarketTest::~MarketTest() {}

void MarketTest::isAllowedAccountNumberTest() {
    UnitTest unitTest("isAllowedAccountNumberTest");

    unitTest.assertTrue(
        market_.isAllowedAccountNumber(2100219063)
    );

    unitTest.assertFalse(
        market_.isAllowedAccountNumber(123)
    );
}

void MarketTest::isAllowedExecutionDateTest() {
    UnitTest unitTest("isAllowedExecutionDateTest");

    unitTest.assertTrue(
        market_.isAllowedExecutionDate((datetime) "2020-03-12")
    );

    unitTest.assertFalse(
        market_.isAllowedExecutionDate((datetime) "2021-07-12")
    );
}

void MarketTest::isAllowedPeriodTest() {
    UnitTest unitTest("isAllowedPeriodTest");

    unitTest.assertTrue(
        market_.isAllowedPeriod(CURRENT_PERIOD)
    );

    unitTest.assertTrue(
        market_.isAllowedPeriod(PERIOD_M30)
    );

    unitTest.assertFalse(
        market_.isAllowedPeriod(PERIOD_D1)
    );
}

void MarketTest::isAllowedSymbolTest() {
    UnitTest unitTest("isAllowedSymbolTest");

    unitTest.assertTrue(
        market_.isAllowedSymbol(CURRENT_SYMBOL)
    );

    unitTest.assertTrue(
        market_.isAllowedSymbol("GBPUSD")
    );

    if (market_.isDemoTrading()) {
        unitTest.assertTrue(
            market_.isAllowedSymbol("EURNOK")
        );
    }

    market_.forceIsLiveAccount();

    unitTest.assertFalse(
        market_.isAllowedSymbol("EURNOK")
    );

    market_.resetAccountTypeOverride();

    unitTest.assertFalse(
        market_.isAllowedSymbol("CIAO")
    );
}

void MarketTest::isAllowedSymbolPeriodComboTest() {
    UnitTest unitTest("isAllowedSymbolPeriodComboTest");

    market_.forceIsLiveAccount();

    unitTest.assertFalse(
        market_.isAllowedSymbolPeriodCombo("GBPJPY", PERIOD_M30)
    );

    unitTest.assertFalse(
        market_.isAllowedSymbolPeriodCombo("EURJPY", PERIOD_M30)
    );

    unitTest.assertTrue(
        market_.isAllowedSymbolPeriodCombo("GBPJPY", PERIOD_H4)
    );

    unitTest.assertTrue(
        market_.isAllowedSymbolPeriodCombo("EURUSD", PERIOD_M30)
    );

    market_.resetAccountTypeOverride();
}

void MarketTest::isDemoTradingTest() {
    UnitTest unitTest("isDemoTradingTest");

    unitTest.assertTrue(
        market_.isDemoTrading(2100219063)
    );

    market_.forceIsLiveAccount();

    unitTest.assertFalse(
        market_.isDemoTrading(2100219063)
    );

    market_.resetAccountTypeOverride();

    unitTest.assertFalse(
        market_.isDemoTrading(2100175255)
    );

    unitTest.assertFalse(
        market_.isDemoTrading(123)
    );
}
