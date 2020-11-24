#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/pattern/Pattern.mqh"


class PatternTest {
    public:
        void isPatternTest();

    private:
        Pattern pattern_;
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

        const double thisCandleSize = MathAbs(iExtreme(i, Max) - iExtreme(i, Min));

        if (!isUpPinbarTested && pattern_.upPinbar(i) &&
            thisCandleSize < PATTERN_MAXIMUM_SIZE_PIPS * PeriodMultiplicationFactor() * Pips() &&
            thisCandleSize > PATTERN_MINIMUM_SIZE_PIPS * PeriodMultiplicationFactor() * Pips()) {
            unitTest.assertTrue(
                pattern_.isBuyPattern(i),
                "isUpPinbarTested"
            );
            checkedAssertions++;
            isUpPinbarTested = true;
        }

        if (!isDownPinbarTested && pattern_.downPinbar(i) &&
            thisCandleSize < PATTERN_MAXIMUM_SIZE_PIPS * PeriodMultiplicationFactor() * Pips() &&
            thisCandleSize > PATTERN_MINIMUM_SIZE_PIPS * PeriodMultiplicationFactor() * Pips()) {
            unitTest.assertTrue(
                pattern_.isSellPattern(i),
                "isDownPinbarTested"
            );
            checkedAssertions++;
            isDownPinbarTested = true;
        }

        if (!isNotUpPinbarTested && pattern_.upPinbar(i) &&
            (thisCandleSize > PATTERN_MAXIMUM_SIZE_PIPS * PeriodMultiplicationFactor() * Pips() ||
            thisCandleSize < PATTERN_MINIMUM_SIZE_PIPS * PeriodMultiplicationFactor() * Pips())) {
            unitTest.assertFalse(
                pattern_.isBuyPattern(i),
                "isNotUpPinbarTested"
            );
            checkedAssertions++;
            isNotUpPinbarTested = true;
        }

        if (!isNotDownPinbarTested && pattern_.downPinbar(i) &&
            (thisCandleSize > PATTERN_MAXIMUM_SIZE_PIPS * PeriodMultiplicationFactor() * Pips() ||
            thisCandleSize < PATTERN_MINIMUM_SIZE_PIPS * PeriodMultiplicationFactor() * Pips())) {
            unitTest.assertFalse(
                pattern_.isSellPattern(i),
                "isNotDownPinbarTested"
            );
            checkedAssertions++;
            isNotDownPinbarTested = true;
        }

        if (i == maxIndex - 1 && checkedAssertions < totalAssertions) {
            Print("isBuyPatternTest: ", checkedAssertions, " out of ",
                totalAssertions, " assertions checked, some skipped..");
        }
    }
}
