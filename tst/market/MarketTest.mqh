#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/market/Market.mqh"


class MarketTest: public Market {
    public:
        void isMarketOpenedTest();
        void isAllowedAccountNumberTest();
        void isAllowedExecutionDateTest();
        void isAllowedPeriodTest();
        void isAllowedBrokerTest();
        void isAllowedSymbolTest();
        void isAllowedSymbolPeriodComboTest();
        void isDemoTradingTest();
};

void MarketTest::isMarketOpenedTest() {
    UnitTest unitTest("isMarketOpenedTest");

    if (unitTest.hasDateDependentTestExpired()) {
        return;
    }

    if (GetSpread() > SPREAD_PIPS_CLOSE_MARKET - 1) {
        Print("isMarketOpenedTest skipped for high spread..");
        return;
    }

    if (Period() != PERIOD_H4) {
        unitTest.assertFalse(
            isMarketOpened((datetime) "2020-04-06 07:58")
        );

        unitTest.assertTrue(
            isMarketOpened((datetime) "2020-04-06 08:02")
        );

        unitTest.assertTrue(
            isMarketOpened((datetime) "2021-06-30 16:58")
        );

        unitTest.assertFalse(
            isMarketOpened((datetime) "2021-06-30 17:02")
        );
    }

    if (Period() == PERIOD_H4) {
        unitTest.assertFalse(
            isMarketOpened((datetime) "2021-06-30 07:58")
        );
        unitTest.assertTrue(
            isMarketOpened((datetime) "2021-06-30 08:02")
        );
        unitTest.assertTrue(
            isMarketOpened((datetime) "2021-06-30 19:30")
        );
        unitTest.assertFalse(
            isMarketOpened((datetime) "2021-06-30 20:02")
        );
    }

    unitTest.assertFalse(
        isMarketOpened((datetime) "2020-04-03 12:00") // Friday
    );

    unitTest.assertFalse(
        isMarketOpened((datetime) "2020-04-05 12:00") // Sunday
    );

    unitTest.assertFalse(
        isMarketOpened((datetime) "2020-12-24 12:00") // Vacation
    );
}

void MarketTest::isAllowedAccountNumberTest() {
    UnitTest unitTest("isAllowedAccountNumberTest");

    unitTest.assertTrue(
        isAllowedAccountNumber(2100219063)
    );

    unitTest.assertFalse(
        isAllowedAccountNumber(123)
    );
}

void MarketTest::isAllowedExecutionDateTest() {
    UnitTest unitTest("isAllowedExecutionDateTest");

    if (unitTest.hasDateDependentTestExpired()) {
        return;
    }

    unitTest.assertTrue(
        isAllowedExecutionDate((datetime) "2020-03-12")
    );

    unitTest.assertFalse(
        isAllowedExecutionDate((datetime) "2021-07-12")
    );
}

void MarketTest::isAllowedPeriodTest() {
    UnitTest unitTest("isAllowedPeriodTest");

    unitTest.assertTrue(
        isAllowedPeriod()
    );

    unitTest.assertTrue(
        isAllowedPeriod(PERIOD_M30)
    );

    unitTest.assertFalse(
        isAllowedPeriod(PERIOD_D1)
    );
}

void MarketTest::isAllowedSymbolTest() {
    UnitTest unitTest("isAllowedSymbolTest");

    unitTest.assertTrue(
        isAllowedSymbol()
    );

    unitTest.assertTrue(
        isAllowedSymbol("GBPUSD")
    );

    if (isDemoTrading()) {
        unitTest.assertTrue(
            isAllowedSymbol("EURNOK")
        );
    }

    accountTypeOverride();

    unitTest.assertFalse(
        isAllowedSymbol("EURNOK")
    );

    accountTypeOverrideReset();

    unitTest.assertFalse(
        isAllowedSymbol("CIAO")
    );
}

void MarketTest::isAllowedBrokerTest() {
    UnitTest unitTest("isAllowedBrokerTest");

    const string randomBrokerName = "RandomBrokerName";

    unitTest.assertTrue(
        isAllowedBroker(AccountCompany())
    );

    if (isDemoTrading()) {
        unitTest.assertTrue(
            isAllowedBroker(randomBrokerName)
        );
    } else {
        unitTest.assertFalse(
            isAllowedBroker(randomBrokerName)
        );
    }

    accountTypeOverride();

    unitTest.assertFalse(
        isAllowedBroker(randomBrokerName)
    );

    accountTypeOverrideReset();
}

void MarketTest::isAllowedSymbolPeriodComboTest() {
    UnitTest unitTest("isAllowedSymbolPeriodComboTest");

    accountTypeOverride();

    unitTest.assertFalse(
        isAllowedSymbolPeriodCombo("GBPJPY", PERIOD_M30)
    );

    unitTest.assertFalse(
        isAllowedSymbolPeriodCombo("EURJPY", PERIOD_M30)
    );

    unitTest.assertTrue(
        isAllowedSymbolPeriodCombo("GBPJPY", PERIOD_H4)
    );

    unitTest.assertTrue(
        isAllowedSymbolPeriodCombo("EURUSD", PERIOD_M30)
    );

    accountTypeOverrideReset();
}

void MarketTest::isDemoTradingTest() {
    UnitTest unitTest("isDemoTradingTest");

    unitTest.assertTrue(
        isDemoTrading(2100219063)
    );

    accountTypeOverride();

    unitTest.assertFalse(
        isDemoTrading(2100219063)
    );

    accountTypeOverrideReset();

    unitTest.assertFalse(
        isDemoTrading(2100175255)
    );

    unitTest.assertFalse(
        isDemoTrading(123)
    );
}
