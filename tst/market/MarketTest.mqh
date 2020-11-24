#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/market/Market.mqh"


/**
 * This class exposes the protected variable of Market for testing
 */
class MarketExposed: public Market {
    public:
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
        marketExaposed_.isAllowedAccountNumber(2100219063)
    );

    unitTest.assertFalse(
        marketExaposed_.isAllowedAccountNumber(123)
    );
}

void MarketTest::isAllowedExecutionDateTest() {
    UnitTest unitTest("isAllowedExecutionDateTest");

    unitTest.assertTrue(
        marketExaposed_.isAllowedExecutionDate((datetime) "2020-03-12")
    );

    unitTest.assertFalse(
        marketExaposed_.isAllowedExecutionDate((datetime) "2021-07-12")
    );
}

void MarketTest::isAllowedPeriodTest() {
    UnitTest unitTest("isAllowedPeriodTest");

    unitTest.assertTrue(
        marketExaposed_.isAllowedPeriod()
    );

    unitTest.assertTrue(
        marketExaposed_.isAllowedPeriod(PERIOD_M30)
    );

    unitTest.assertFalse(
        marketExaposed_.isAllowedPeriod(PERIOD_D1)
    );
}

void MarketTest::isAllowedSymbolTest() {
    UnitTest unitTest("isAllowedSymbolTest");

    unitTest.assertTrue(
        marketExaposed_.isAllowedSymbol()
    );

    unitTest.assertTrue(
        marketExaposed_.isAllowedSymbol("GBPUSD")
    );

    if (marketExaposed_.isDemoTrading()) {
        unitTest.assertTrue(
            marketExaposed_.isAllowedSymbol("EURNOK")
        );
    }

    marketExaposed_.accountTypeOverride();

    unitTest.assertFalse(
        marketExaposed_.isAllowedSymbol("EURNOK")
    );

    marketExaposed_.accountTypeOverrideReset();

    unitTest.assertFalse(
        marketExaposed_.isAllowedSymbol("CIAO")
    );
}

void MarketTest::isAllowedBrokerTest() {
    UnitTest unitTest("isAllowedBrokerTest");

    const string randomBrokerName = "RandomBrokerName";

    unitTest.assertTrue(
        marketExaposed_.isAllowedBroker(AccountCompany())
    );

    if (marketExaposed_.isDemoTrading()) {
        unitTest.assertTrue(
            marketExaposed_.isAllowedBroker(randomBrokerName)
        );
    } else {
        unitTest.assertFalse(
            marketExaposed_.isAllowedBroker(randomBrokerName)
        );
    }

    marketExaposed_.accountTypeOverride();

    unitTest.assertFalse(
        marketExaposed_.isAllowedBroker(randomBrokerName)
    );

    marketExaposed_.accountTypeOverrideReset();
}

void MarketTest::isAllowedSymbolPeriodComboTest() {
    UnitTest unitTest("isAllowedSymbolPeriodComboTest");

    marketExaposed_.accountTypeOverride();

    unitTest.assertFalse(
        marketExaposed_.isAllowedSymbolPeriodCombo("GBPJPY", PERIOD_M30)
    );

    unitTest.assertFalse(
        marketExaposed_.isAllowedSymbolPeriodCombo("EURJPY", PERIOD_M30)
    );

    unitTest.assertTrue(
        marketExaposed_.isAllowedSymbolPeriodCombo("GBPJPY", PERIOD_H4)
    );

    unitTest.assertTrue(
        marketExaposed_.isAllowedSymbolPeriodCombo("EURUSD", PERIOD_M30)
    );

    marketExaposed_.accountTypeOverrideReset();
}

void MarketTest::isDemoTradingTest() {
    UnitTest unitTest("isDemoTradingTest");

    unitTest.assertTrue(
        marketExaposed_.isDemoTrading(2100219063)
    );

    marketExaposed_.accountTypeOverride();

    unitTest.assertFalse(
        marketExaposed_.isDemoTrading(2100219063)
    );

    marketExaposed_.accountTypeOverrideReset();

    unitTest.assertFalse(
        marketExaposed_.isDemoTrading(2100175255)
    );

    unitTest.assertFalse(
        marketExaposed_.isDemoTrading(123)
    );
}
