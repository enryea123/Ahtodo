#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/pivot/PivotStyle.mqh"


class PivotStyleTest {
    public:
        PivotStyleTest();

        void pivotStyleBaseTest();
        void pivotRSLabelColorTest();
        void pivotRSLabelNameTest();

    private:
        PivotStyle pivotStyleD1_;
        PivotStyle pivotStyleW1_;
};

PivotStyleTest::PivotStyleTest():
    pivotStyleD1_(D1),
    pivotStyleW1_(W1) {
}

void PivotStyleTest::pivotStyleBaseTest() {
    UnitTest unitTest("pivotStyleBaseTest");

    unitTest.assertEquals(
        1,
        pivotStyleD1_.pivotPeriodFactor()
    );

    unitTest.assertEquals(
        5,
        pivotStyleW1_.pivotPeriodFactor()
    );

    unitTest.assertEquals(
        "DP",
        pivotStyleD1_.pivotLabelText()
    );

    unitTest.assertEquals(
        clrOrange,
        pivotStyleW1_.pivotColor()
    );
}

void PivotStyleTest::pivotRSLabelColorTest() {
    UnitTest unitTest("pivotRSLabelColorTest");

    unitTest.assertEquals(
        clrRed,
        pivotStyleD1_.pivotRSLabelColor(R3)
    );

    unitTest.assertEquals(
        clrGreen,
        pivotStyleD1_.pivotRSLabelColor(S2)
    );
}

void PivotStyleTest::pivotRSLabelNameTest() {
    UnitTest unitTest("pivotRSLabelNameTest");

    unitTest.assertEquals(
        "PivotLabelRS_S1_D1",
        pivotStyleD1_.pivotRSLabelName(S1)
    );
}
