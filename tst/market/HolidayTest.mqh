#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../UnitTest.mqh"
#include "../../src/market/Holiday.mqh"


class HolidayTest {
    public:
        void isMajorBankHolidayTest();
        void isMinorBankHolidayTest();

    private:
        Holiday holiday_;
};

void HolidayTest::isMajorBankHolidayTest() {
    UnitTest unitTest("isMajorBankHolidayTest");

    if (unitTest.hasDateDependentTestExpired()) {
        return;
    }

    unitTest.assertTrue(
        holiday_.isMajorBankHoliday((datetime) "2020-01-03")
    );

    unitTest.assertFalse(
        holiday_.isMajorBankHoliday((datetime) "2020-03-01 07.18.01")
    );

    // Pasquetta
    unitTest.assertTrue(
        holiday_.isMajorBankHoliday((datetime) "2020-04-13")
    );

    // Not Pasquetta
    unitTest.assertFalse(
        holiday_.isMajorBankHoliday((datetime) "2021-04-13")
    );

    // Not Pasquetta
    unitTest.assertFalse(
        holiday_.isMajorBankHoliday((datetime) "2020-04-05")
    );

    // Pasquetta
    unitTest.assertTrue(
        holiday_.isMajorBankHoliday((datetime) "2021-04-05")
    );

    // Ascension
    unitTest.assertTrue(
        holiday_.isMajorBankHoliday((datetime) "2021-05-13")
    );

    // Ascension
    unitTest.assertTrue(
        holiday_.isMajorBankHoliday((datetime) "2025-05-29")
    );

    // Pentecoste
    unitTest.assertTrue(
        holiday_.isMajorBankHoliday((datetime) "2023-05-28")
    );

    // Pentecoste
    unitTest.assertTrue(
        holiday_.isMajorBankHoliday((datetime) "2024-05-19")
    );

    // Columbus day
    unitTest.assertTrue(
        holiday_.isMajorBankHoliday((datetime) "2022-10-10")
    );

    unitTest.assertTrue(
        holiday_.isMajorBankHoliday((datetime) "2022-12-23 18:00")
    );

    unitTest.assertFalse(
        holiday_.isMajorBankHoliday((datetime) "9999-01-01")
    );
}

void HolidayTest::isMinorBankHolidayTest() {
    UnitTest unitTest("isMinorBankHolidayTest");

    if (unitTest.hasDateDependentTestExpired()) {
        return;
    }

    unitTest.assertFalse(
        holiday_.isMinorBankHoliday((datetime) "2021-01-10")
    );

    unitTest.assertTrue(
        holiday_.isMinorBankHoliday((datetime) "2024-06-02 08:08:00")
    );

    unitTest.assertTrue(
        holiday_.isMinorBankHoliday((datetime) "2022-08-29")
    );
}
