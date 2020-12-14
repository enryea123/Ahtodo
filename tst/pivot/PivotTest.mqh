#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/pivot/Pivot.mqh"


class PivotTest {
    public:
        void getPivotHappyPathTest();
        void getPivotNegativeTimeIndexTest();
        void getPivotUnexistestSymbolTest();
        void getPivotRSHappyPathTest();
        void getPivotRSUnexistestSymbolTest();

    private:
        Pivot pivot_;
};

void PivotTest::getPivotHappyPathTest() {
    UnitTest unitTest("getPivotHappyPathTest");

    unitTest.assertTrue(
        pivot_.getPivot(Symbol(), D1, 0) > 0
    );

    unitTest.assertTrue(
        pivot_.getPivot(Symbol(), D1, 0) < 2 * iCandle(I_high, Symbol(), D1, 0)
    );

    unitTest.assertTrue(
        pivot_.getPivot(Symbol(), W1, 0) > 0
    );

    unitTest.assertTrue(
        pivot_.getPivot(Symbol(), W1, 0) < 2 * iCandle(I_high, Symbol(), W1, 0)
    );
}

void PivotTest::getPivotNegativeTimeIndexTest() {
    UnitTest unitTest("getPivotNegativeTimeIndexTest");

    unitTest.assertEquals(
        -1.0,
        pivot_.getPivot(Symbol(), D1, -5)
    );
}

void PivotTest::getPivotUnexistestSymbolTest() {
    UnitTest unitTest("getPivotUnexistestSymbolTest");

    unitTest.assertEquals(
        -1.0,
        pivot_.getPivot("CIAO", D1, 0)
    );
}

void PivotTest::getPivotRSHappyPathTest() {
    UnitTest unitTest("getPivotRSHappyPathTest");

    unitTest.assertTrue(
        pivot_.getPivotRS(Symbol(), D1, R1) > 0
    );

    unitTest.assertTrue(
        pivot_.getPivotRS(Symbol(), D1, R1) < 2 * iCandle(I_high, Symbol(), D1, 0)
    );

    unitTest.assertNotEquals(
        -1.0,
        pivot_.getPivotRS(Symbol(), D1, R1)
    );
}

void PivotTest::getPivotRSUnexistestSymbolTest() {
    UnitTest unitTest("getPivotRSUnexistestSymbolTest");

    unitTest.assertEquals(
        -1.0,
        pivot_.getPivotRS("CIAO", D1, R1)
    );
}
