#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/market/Market.mqh"


/**
 * This class exposes the protected variable of Market for testing
 */
class MarketExposed: public Market {
    public:
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
        void isAllowedAccountNumberTest();
        void isAllowedExecutionDateTest();
        void isAllowedPeriodTest();
        void isAllowedBrokerTest();
        void isAllowedSymbolTest();
        void isAllowedSymbolPeriodComboTest();
        void isDemoTradingTest();

    private:
        MarketExposed marketExaposed_;
};

void MarketTest::isAllowedAccountNumberTest() {
    UnitTest unitTest("isAllowedAccountNumberTest");

    unitTest.assertTrue(
        marketExaposed_._isAllowedAccountNumber(2100219063)
    );

    unitTest.assertFalse(
        marketExaposed_._isAllowedAccountNumber(123)
    );
}

void MarketTest::isAllowedExecutionDateTest() {
    UnitTest unitTest("isAllowedExecutionDateTest");

    unitTest.assertTrue(
        marketExaposed_._isAllowedExecutionDate((datetime) "2020-03-12")
    );

    unitTest.assertFalse(
        marketExaposed_._isAllowedExecutionDate((datetime) "2021-07-12")
    );
}

void MarketTest::isAllowedPeriodTest() {
    UnitTest unitTest("isAllowedPeriodTest");

    unitTest.assertTrue(
        marketExaposed_._isAllowedPeriod()
    );

    unitTest.assertTrue(
        marketExaposed_._isAllowedPeriod(PERIOD_M30)
    );

    unitTest.assertFalse(
        marketExaposed_._isAllowedPeriod(PERIOD_D1)
    );
}

void MarketTest::isAllowedSymbolTest() {
    UnitTest unitTest("isAllowedSymbolTest");

    unitTest.assertTrue(
        marketExaposed_._isAllowedSymbol()
    );

    unitTest.assertTrue(
        marketExaposed_._isAllowedSymbol("GBPUSD")
    );

    if (marketExaposed_._isDemoTrading()) {
        unitTest.assertTrue(
            marketExaposed_._isAllowedSymbol("EURNOK")
        );
    }

    marketExaposed_.accountTypeOverride();

    unitTest.assertFalse(
        marketExaposed_._isAllowedSymbol("EURNOK")
    );

    marketExaposed_.accountTypeOverrideReset();

    unitTest.assertFalse(
        marketExaposed_._isAllowedSymbol("CIAO")
    );
}

void MarketTest::isAllowedBrokerTest() {
    UnitTest unitTest("isAllowedBrokerTest");

    const string randomBrokerName = "RandomBrokerName";

    unitTest.assertTrue(
        marketExaposed_._isAllowedBroker(AccountCompany())
    );

    if (marketExaposed_._isDemoTrading()) {
        unitTest.assertTrue(
            marketExaposed_._isAllowedBroker(randomBrokerName)
        );
    } else {
        unitTest.assertFalse(
            marketExaposed_._isAllowedBroker(randomBrokerName)
        );
    }

    marketExaposed_.accountTypeOverride();

    unitTest.assertFalse(
        marketExaposed_._isAllowedBroker(randomBrokerName)
    );

    marketExaposed_.accountTypeOverrideReset();
}

void MarketTest::isAllowedSymbolPeriodComboTest() {
    UnitTest unitTest("isAllowedSymbolPeriodComboTest");

    marketExaposed_.accountTypeOverride();

    unitTest.assertFalse(
        marketExaposed_._isAllowedSymbolPeriodCombo("GBPJPY", PERIOD_M30)
    );

    unitTest.assertFalse(
        marketExaposed_._isAllowedSymbolPeriodCombo("EURJPY", PERIOD_M30)
    );

    unitTest.assertTrue(
        marketExaposed_._isAllowedSymbolPeriodCombo("GBPJPY", PERIOD_H4)
    );

    unitTest.assertTrue(
        marketExaposed_._isAllowedSymbolPeriodCombo("EURUSD", PERIOD_M30)
    );

    marketExaposed_.accountTypeOverrideReset();
}

void MarketTest::isDemoTradingTest() {
    UnitTest unitTest("isDemoTradingTest");

    unitTest.assertTrue(
        marketExaposed_._isDemoTrading(2100219063)
    );

    marketExaposed_.accountTypeOverride();

    unitTest.assertFalse(
        marketExaposed_._isDemoTrading(2100219063)
    );

    marketExaposed_.accountTypeOverrideReset();

    unitTest.assertFalse(
        marketExaposed_._isDemoTrading(2100175255)
    );

    unitTest.assertFalse(
        marketExaposed_._isDemoTrading(123)
    );
}
