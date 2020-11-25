#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../UnitTest.mqh"
#include "../../src/market/MarketTime.mqh"


/**
 * This class exposes the protected methods of MarketTime for testing
 */
class MarketTimeExposed: public MarketTime {
    public:
        bool _isMarketOpened(datetime date) {return isMarketOpened(date);}
        datetime _findDayOfWeekOccurrenceInMonth(int year, int month, int dayOfWeek, int occurrence) {
            return findDayOfWeekOccurrenceInMonth(year, month, dayOfWeek, occurrence);}
        int _getDaylightSavingCorrectionCET(datetime date) {return getDaylightSavingCorrectionCET(date);}
        int _getDaylightSavingCorrectionUSA(datetime date) {return getDaylightSavingCorrectionUSA(date);}
};


class MarketTimeTest {
    public:
        void isMarketOpenedTest();
        void findDayOfWeekOccurrenceInMonthTest();
        void getDaylightSavingCorrectionsTest();
        void timeAtMidnightTest();
        void timeShiftInHoursTest();

    private:
        MarketTimeExposed marketTimeExposed_;
};

void MarketTimeTest::isMarketOpenedTest() {
    UnitTest unitTest("isMarketOpenedTest");

    if (unitTest.hasDateDependentTestExpired()) {
        return;
    }

    if (Period() != PERIOD_H4) {
        unitTest.assertFalse(
            marketTimeExposed_._isMarketOpened((datetime) "2020-04-06 08:58")
        );

        unitTest.assertTrue(
            marketTimeExposed_._isMarketOpened((datetime) "2020-04-06 09:02")
        );

        unitTest.assertTrue(
            marketTimeExposed_._isMarketOpened((datetime) "2021-06-30 16:58")
        );

        unitTest.assertFalse(
            marketTimeExposed_._isMarketOpened((datetime) "2021-06-30 17:02")
        );
    }

    if (Period() == PERIOD_H4) {
        unitTest.assertFalse(
            marketTimeExposed_._isMarketOpened((datetime) "2021-06-30 07:58")
        );
        unitTest.assertTrue(
            marketTimeExposed_._isMarketOpened((datetime) "2021-06-30 08:02")
        );
        unitTest.assertTrue(
            marketTimeExposed_._isMarketOpened((datetime) "2021-06-30 19:30")
        );
        unitTest.assertFalse(
            marketTimeExposed_._isMarketOpened((datetime) "2021-06-30 20:02")
        );
    }

    unitTest.assertFalse(
        marketTimeExposed_._isMarketOpened((datetime) "2020-04-03 12:00") // Friday
    );

    unitTest.assertFalse(
        marketTimeExposed_._isMarketOpened((datetime) "2020-04-05 12:00") // Sunday
    );
}

void MarketTimeTest::findDayOfWeekOccurrenceInMonthTest() {
    UnitTest unitTest("findDayOfWeekOccurrenceInMonthTest");

    if (unitTest.hasDateDependentTestExpired()) {
        return;
    }

    unitTest.assertEquals(
        (datetime) "2020-04-05",
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(2020, APRIL, SUNDAY, 1)
    );

    unitTest.assertEquals(
        (datetime) "2019-06-04",
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(2019, JUNE, TUESDAY, 1)
    );

    unitTest.assertEquals(
        (datetime) "2019-06-04",
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(2019, JUNE, TUESDAY, -4)
    );

    unitTest.assertEquals(
        (datetime) "2019-06-04",
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(2019, JUNE, TUESDAY, -16)
    );

    unitTest.assertEquals(
        (datetime) "2021-03-29",
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(2021, MARCH, MONDAY, -1)
    );

    unitTest.assertEquals(
        (datetime) "2020-02-29", // testing leap year
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(2020, FEBRUARY, SATURDAY, -1)
    );

    unitTest.assertEquals(
        (datetime) "2022-02-15", // testing non leap year
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(2022, FEBRUARY, TUESDAY, -2)
    );

    unitTest.assertEquals(
        (datetime) -1,
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(2020, 27, MONDAY, 1)
    );

    unitTest.assertEquals(
        (datetime) -1,
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(2020, 0, MONDAY, 1)
    );

    unitTest.assertEquals(
        (datetime) -1,
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(2021, MAY, MONDAY, 0)
    );

    unitTest.assertEquals(
        (datetime) -1,
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(2021, MAY, 19, 1)
    );

    unitTest.assertEquals(
        (datetime) -1,
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(1, MAY, WEDNESDAY, 2)
    );

    unitTest.assertEquals(
        (datetime) -1,
        marketTimeExposed_._findDayOfWeekOccurrenceInMonth(3000, MAY, WEDNESDAY, 2)
    );
}

void MarketTimeTest::getDaylightSavingCorrectionsTest() {
    UnitTest unitTest("getDaylightSavingCorrectionsTest");

    if (unitTest.hasDateDependentTestExpired()) {
        return;
    }

    unitTest.assertEquals(
        0,
        marketTimeExposed_._getDaylightSavingCorrectionCET((datetime) "2020-03-28")
    );

    unitTest.assertEquals(
        1,
        marketTimeExposed_._getDaylightSavingCorrectionCET((datetime) "2020-03-30")
    );

    unitTest.assertEquals(
        1,
        marketTimeExposed_._getDaylightSavingCorrectionCET((datetime) "2020-10-24")
    );

    unitTest.assertEquals(
        0,
        marketTimeExposed_._getDaylightSavingCorrectionCET((datetime) "2020-10-26")
    );

    unitTest.assertEquals(
        0,
        marketTimeExposed_._getDaylightSavingCorrectionUSA((datetime) "2021-03-13")
    );

    unitTest.assertEquals(
        1,
        marketTimeExposed_._getDaylightSavingCorrectionUSA((datetime) "2021-03-15")
    );

    unitTest.assertEquals(
        1,
        marketTimeExposed_._getDaylightSavingCorrectionUSA((datetime) "2021-11-6")
    );

    unitTest.assertEquals(
        0,
        marketTimeExposed_._getDaylightSavingCorrectionUSA((datetime) "2021-11-8")
    );

    unitTest.assertEquals(
        1,
        marketTimeExposed_._getDaylightSavingCorrectionCET((datetime) "2018-06-30")
    );

    unitTest.assertEquals(
        0,
        marketTimeExposed_._getDaylightSavingCorrectionUSA((datetime) "2022-12-30")
    );
}

void MarketTimeTest::timeAtMidnightTest() {
    UnitTest unitTest("timeAtMidnightTest");

    if (unitTest.hasDateDependentTestExpired()) {
        return;
    }

    unitTest.assertEquals(
        (datetime) "2021-06-30",
        marketTimeExposed_.timeAtMidnight((datetime) "2021-06-30 18:45:01")
    );
}
void MarketTimeTest::timeShiftInHoursTest() {
    UnitTest unitTest("timeShiftInHoursTest");

    if (unitTest.hasDateDependentTestExpired()) {
        return;
    }

    unitTest.assertEquals(
        0,
        marketTimeExposed_.timeShiftInHours((datetime) "2018-06-30 12:00", (datetime) "2018-06-30 12:02:01")
    );

    unitTest.assertEquals(
        2,
        marketTimeExposed_.timeShiftInHours((datetime) "2018-06-30 12:02", (datetime) "2018-06-30 10:00:14")
    );

    unitTest.assertEquals(
        -3,
        marketTimeExposed_.timeShiftInHours((datetime) "2018-06-30 14:02", (datetime) "2018-06-30 16:56:14")
    );

    unitTest.assertEquals(
        24,
        marketTimeExposed_.timeShiftInHours((datetime) "2018-06-30 09:00", (datetime) "2018-06-29 09:00")
    );
}
