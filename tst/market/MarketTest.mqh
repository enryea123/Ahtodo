#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/market/Market.mqh"


/**
 * This class exposes the protected methods and variables of Market for testing
 */
class MarketExposed: public Market {
    public:
        bool _isMarketOpened(datetime date) {return isMarketOpened(date);}
        bool _isAllowedAccountNumber(int account) {return isAllowedAccountNumber(account);}
        bool _isAllowedExecutionDate(datetime date) {return isAllowedExecutionDate(date);}
        bool _isAllowedPeriod() {return isAllowedPeriod();}
        bool _isAllowedPeriod(int period) {return isAllowedPeriod(period);}
        bool _isAllowedBroker(string broker) {return isAllowedBroker(broker);}
        bool _isAllowedSymbol() {return isAllowedSymbol();}
        bool _isAllowedSymbol(string symbol) {return isAllowedSymbol(symbol);}
        bool _isAllowedSymbolPeriodCombo(string symbol, int period) {return isAllowedSymbolPeriodCombo(symbol, period);}
        bool _isDemoTrading() {return isDemoTrading();}
        bool _isDemoTrading(int account) {return isDemoTrading(account);}

        void accountTypeOverride() {forceIsLiveAccountForTesting_ = true;};
        void accountTypeOverrideReset() {forceIsLiveAccountForTesting_ = false;};
};


class MarketTest {
    public:
        void isMarketOpenedTest();
        void isAllowedAccountNumberTest();
        void isAllowedExecutionDateTest();
        void isAllowedPeriodTest();
        void isAllowedBrokerTest();
        void isAllowedSymbolTest();
        void isAllowedSymbolPeriodComboTest();
        void isDemoTradingTest();

    private:
        MarketExposed marketExposed_;
};


void MarketTest::isMarketOpenedTest() {
    UnitTest unitTest("isMarketOpenedTest");

    if (unitTest.hasDateDependentTestExpired()) {
        return;
    }

    if (Period() != PERIOD_H4) {
        unitTest.assertFalse(
            marketExposed_._isMarketOpened((datetime) "2020-04-06 08:58")
        );

        unitTest.assertTrue(
            marketExposed_._isMarketOpened((datetime) "2020-04-06 09:02")
        );

        unitTest.assertTrue(
            marketExposed_._isMarketOpened((datetime) "2021-06-30 16:58")
        );

        unitTest.assertFalse(
            marketExposed_._isMarketOpened((datetime) "2021-06-30 17:02")
        );
    }

    if (Period() == PERIOD_H4) {
        unitTest.assertFalse(
            marketExposed_._isMarketOpened((datetime) "2021-06-30 07:58")
        );
        unitTest.assertTrue(
            marketExposed_._isMarketOpened((datetime) "2021-06-30 08:02")
        );
        unitTest.assertTrue(
            marketExposed_._isMarketOpened((datetime) "2021-06-30 19:30")
        );
        unitTest.assertFalse(
            marketExposed_._isMarketOpened((datetime) "2021-06-30 20:02")
        );
    }

    unitTest.assertFalse(
        marketExposed_._isMarketOpened((datetime) "2020-04-03 12:00") // Friday
    );

    unitTest.assertFalse(
        marketExposed_._isMarketOpened((datetime) "2020-04-05 12:00") // Sunday
    );

    unitTest.assertFalse(
        marketExposed_._isMarketOpened((datetime) "2020-12-25 12:00") // Christmas
    );
}

void MarketTest::isAllowedAccountNumberTest() {
    UnitTest unitTest("isAllowedAccountNumberTest");

    unitTest.assertTrue(
        marketExposed_._isAllowedAccountNumber(2100219063)
    );

    unitTest.assertFalse(
        marketExposed_._isAllowedAccountNumber(123)
    );
}

void MarketTest::isAllowedExecutionDateTest() {
    UnitTest unitTest("isAllowedExecutionDateTest");

    if (unitTest.hasDateDependentTestExpired()) {
        return;
    }

    unitTest.assertTrue(
        marketExposed_._isAllowedExecutionDate((datetime) "2020-03-12")
    );

    unitTest.assertFalse(
        marketExposed_._isAllowedExecutionDate((datetime) "2021-07-12")
    );
}

void MarketTest::isAllowedPeriodTest() {
    UnitTest unitTest("isAllowedPeriodTest");

    unitTest.assertTrue(
        marketExposed_._isAllowedPeriod()
    );

    unitTest.assertTrue(
        marketExposed_._isAllowedPeriod(PERIOD_M30)
    );

    unitTest.assertFalse(
        marketExposed_._isAllowedPeriod(PERIOD_D1)
    );
}

void MarketTest::isAllowedSymbolTest() {
    UnitTest unitTest("isAllowedSymbolTest");

    unitTest.assertTrue(
        marketExposed_._isAllowedSymbol()
    );

    unitTest.assertTrue(
        marketExposed_._isAllowedSymbol("GBPUSD")
    );

    if (marketExposed_._isDemoTrading()) {
        unitTest.assertTrue(
            marketExposed_._isAllowedSymbol("EURNOK")
        );
    }

    marketExposed_.accountTypeOverride();

    unitTest.assertFalse(
        marketExposed_._isAllowedSymbol("EURNOK")
    );

    marketExposed_.accountTypeOverrideReset();

    unitTest.assertFalse(
        marketExposed_._isAllowedSymbol("CIAO")
    );
}

void MarketTest::isAllowedBrokerTest() {
    UnitTest unitTest("isAllowedBrokerTest");

    const string randomBrokerName = "RandomBrokerName";

    unitTest.assertTrue(
        marketExposed_._isAllowedBroker(AccountCompany())
    );

    if (marketExposed_._isDemoTrading()) {
        unitTest.assertTrue(
            marketExposed_._isAllowedBroker(randomBrokerName)
        );
    } else {
        unitTest.assertFalse(
            marketExposed_._isAllowedBroker(randomBrokerName)
        );
    }

    marketExposed_.accountTypeOverride();

    unitTest.assertFalse(
        marketExposed_._isAllowedBroker(randomBrokerName)
    );

    marketExposed_.accountTypeOverrideReset();
}

void MarketTest::isAllowedSymbolPeriodComboTest() {
    UnitTest unitTest("isAllowedSymbolPeriodComboTest");

    marketExposed_.accountTypeOverride();

    unitTest.assertFalse(
        marketExposed_._isAllowedSymbolPeriodCombo("GBPJPY", PERIOD_M30)
    );

    unitTest.assertFalse(
        marketExposed_._isAllowedSymbolPeriodCombo("EURJPY", PERIOD_M30)
    );

    unitTest.assertTrue(
        marketExposed_._isAllowedSymbolPeriodCombo("GBPJPY", PERIOD_H4)
    );

    unitTest.assertTrue(
        marketExposed_._isAllowedSymbolPeriodCombo("EURUSD", PERIOD_M30)
    );

    marketExposed_.accountTypeOverrideReset();
}

void MarketTest::isDemoTradingTest() {
    UnitTest unitTest("isDemoTradingTest");

    unitTest.assertTrue(
        marketExposed_._isDemoTrading(2100219063)
    );

    marketExposed_.accountTypeOverride();

    unitTest.assertFalse(
        marketExposed_._isDemoTrading(2100219063)
    );

    marketExposed_.accountTypeOverrideReset();

    unitTest.assertFalse(
        marketExposed_._isDemoTrading(2100175255)
    );

    unitTest.assertFalse(
        marketExposed_._isDemoTrading(123)
    );
}
