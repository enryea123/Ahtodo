#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/pattern/Pattern.mqh"


class PatternTest: public Pattern {
    public:
        void isPatternTest();
};

void PatternTest::isPatternTest() {
    UnitTest unitTest("isPatternTest");

    const int maxIndex = 100;
    const int totalAssertions = 4;
    int checkedAssertions = 0;

    bool isUpPinbarTested = false;
    bool isDownPinbarTested = false;
    bool isNotUpPinbarTested = false;
    bool isNotDownPinbarTested = false;

    for (int i = 0; i < maxIndex; i++) {
        if (checkedAssertions == totalAssertions) {
            break;
        }

        const double thisCandleSize = MathAbs(iExtreme(Max, i) - iExtreme(Min, i));

        if (!isUpPinbarTested && upPinbar(i) &&
            thisCandleSize < PATTERN_MAXIMUM_SIZE_PIPS * PeriodFactor() * Pip() &&
            thisCandleSize > PATTERN_MINIMUM_SIZE_PIPS * PeriodFactor() * Pip()) {
            unitTest.assertTrue(
                isBuyPattern(i),
                "isUpPinbarTested"
            );
            checkedAssertions++;
            isUpPinbarTested = true;
        }

        if (!isDownPinbarTested && downPinbar(i) &&
            thisCandleSize < PATTERN_MAXIMUM_SIZE_PIPS * PeriodFactor() * Pip() &&
            thisCandleSize > PATTERN_MINIMUM_SIZE_PIPS * PeriodFactor() * Pip()) {
            unitTest.assertTrue(
                isSellPattern(i),
                "isDownPinbarTested"
            );
            checkedAssertions++;
            isDownPinbarTested = true;
        }

        if (!isNotUpPinbarTested && upPinbar(i) &&
            (thisCandleSize > PATTERN_MAXIMUM_SIZE_PIPS * PeriodFactor() * Pip() ||
            thisCandleSize < PATTERN_MINIMUM_SIZE_PIPS * PeriodFactor() * Pip())) {
            unitTest.assertFalse(
                isBuyPattern(i),
                "isNotUpPinbarTested"
            );
            checkedAssertions++;
            isNotUpPinbarTested = true;
        }

        if (!isNotDownPinbarTested && downPinbar(i) &&
            (thisCandleSize > PATTERN_MAXIMUM_SIZE_PIPS * PeriodFactor() * Pip() ||
            thisCandleSize < PATTERN_MINIMUM_SIZE_PIPS * PeriodFactor() * Pip())) {
            unitTest.assertFalse(
                isSellPattern(i),
                "isNotDownPinbarTested"
            );
            checkedAssertions++;
            isNotDownPinbarTested = true;
        }
    }

    if (checkedAssertions < totalAssertions) {
        Print(checkedAssertions, "/", totalAssertions, " checks run, some skipped..");
    }
}
