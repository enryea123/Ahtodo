#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/patterns/Patterns.mqh"


class PatternsTest{
    public:
        PatternsTest();
        ~PatternsTest();

        void isPatternTest();

    private:
        Patterns patterns_;
};

PatternsTest::PatternsTest():
    patterns_(){
}

PatternsTest::~PatternsTest(){}

void PatternsTest::isPatternTest(){
    UnitTest unitTest("isPatternTest");

    const int maxIndex = 30;
    const int totalAssertions = 4;
    int checkedAssertions = 0;

    bool isUpPinbarTested = false;
    bool isDownPinbarTested = false;
    bool isNotUpPinbarTested = false;
    bool isNotDownPinbarTested = false;

    for(int i = 0; i < maxIndex; i++){
        if(checkedAssertions == totalAssertions)
            break;

        if(!isUpPinbarTested && patterns_.upPinbar(i)
        && patterns_.candleSize(i) < PATTERN_MAXIMUM_SIZE_PIPS
        && patterns_.candleSize(i) > PATTERN_MINIMUM_SIZE_PIPS){
            unitTest.assertTrue(
                isBuyPattern(i)
            );
            checkedAssertions++;
            isUpPinbarTested = true;
        }

        if(!isDownPinbarTested && patterns_.downPinbar(i)
        && patterns_.candleSize(i) < PATTERN_MAXIMUM_SIZE_PIPS
        && patterns_.candleSize(i) > PATTERN_MINIMUM_SIZE_PIPS){
            unitTest.assertTrue(
                isSellPattern(i)
            );
            checkedAssertions++;
            isDownPinbarTested = true;
        }

        if(!isNotUpPinbarTested && patterns_.upPinbar(i)
        && (patterns_.candleSize(i) > PATTERN_MAXIMUM_SIZE_PIPS
        || patterns_.candleSize(i) < PATTERN_MINIMUM_SIZE_PIPS)){
            unitTest.assertFalse(
                isBuyPattern(i)
            );
            checkedAssertions++;
            isNotUpPinbarTested = true;
        }

        if(!isNotDownPinbarTested && patterns_.downPinbar(i)
        && (patterns_.candleSize(i) > PATTERN_MAXIMUM_SIZE_PIPS
        || patterns_.candleSize(i) < PATTERN_MINIMUM_SIZE_PIPS)){
            unitTest.assertFalse(
                isSellPattern(i)
            );
            checkedAssertions++;
            isNotDownPinbarTested = true;
        }

        if(i == maxIndex - 1 && checkedAssertions < totalAssertions)
            Print("isBuyPatternTest: ", checkedAssertions, " out of ",
                totalAssertions, " assertions checked, some skipped..");
    }
}
