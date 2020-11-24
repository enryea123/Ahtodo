#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/extreme/ArrowStyle.mqh"


class ArrowStyleTest {
    public:
        void drawExtremeArrowTest();

    private:
        ArrowStyle arrowStyle_;
};

void ArrowStyleTest::drawExtremeArrowTest() {
    UnitTest unitTest("drawExtremeArrowTest");

    arrowStyle_.drawExtremeArrow(10, Max, true);
    arrowStyle_.drawExtremeArrow(5, Min, false);

    unitTest.assertTrue(
        ObjectFind("Arrow_10_Max_Valid") >= 0
    );

    unitTest.assertEquals(
        clrOrange,
        ObjectGet("Arrow_10_Max_Valid", OBJPROP_COLOR)
    );

    unitTest.assertTrue(
        ObjectFind("Arrow_5_Min") >= 0
    );

    unitTest.assertEquals(
        clrRed,
        ObjectGet("Arrow_5_Min", OBJPROP_COLOR)
    );

    ObjectDelete("Arrow_10_Max_Valid");
    ObjectDelete("Arrow_5_Min");
}
