#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/pivot/PivotStyle.mqh"


class PivotStyleTest: public PivotStyle {
    public:
        void pivotStyleBaseTest();
        void pivotRSLabelColorTest();
        void pivotRSLabelNameTest();
};

void PivotStyleTest::pivotStyleBaseTest() {
    UnitTest unitTest("pivotStyleBaseTest");

    unitTest.assertEquals(
        1,
        pivotPeriodFactor()
    );

    unitTest.assertEquals(
        "DP",
        pivotLabelText()
    );

    setPivotPeriod(W1);

    unitTest.assertEquals(
        5,
        pivotPeriodFactor()
    );

    unitTest.assertEquals(
        clrOrange,
        pivotColor()
    );

    setPivotPeriod(D1);
}

void PivotStyleTest::pivotRSLabelColorTest() {
    UnitTest unitTest("pivotRSLabelColorTest");

    unitTest.assertEquals(
        clrRed,
        pivotRSLabelColor(R3)
    );

    unitTest.assertEquals(
        clrGreen,
        pivotRSLabelColor(S2)
    );
}

void PivotStyleTest::pivotRSLabelNameTest() {
    UnitTest unitTest("pivotRSLabelNameTest");

    unitTest.assertEquals(
        "PivotLabelRS_S1_D1",
        pivotRSLabelName(S1)
    );
}
