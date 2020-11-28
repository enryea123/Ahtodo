#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"

enum MonthNumber {
    JANUARY = 1,
    FEBRUARY = 2,
    MARCH = 3,
    APRIL = 4,
    MAY = 5,
    JUNE = 6,
    JULY = 7,
    AUGUST = 8,
    SEPTEMBER = 9,
    OCTOBER = 10,
    NOVEMBER = 11,
    DECEMBER = 12,
};


class MarketTime {
    public:
        ~MarketTime();

        int marketOpenHour();
        int marketCloseHour();
        int marketCloseHourPending();
        int marketOpenDay();
        int marketCloseDay();

        datetime timeItaly();
        datetime timeBroker();

        bool hasDateChanged(datetime);
        datetime timeAtMidnight(datetime);
        int timeShiftInHours(datetime, datetime);

    protected:
        datetime findDayOfWeekOccurrenceInMonth(int, int, int, int);
        int getDaylightSavingCorrectionCET(datetime);
        int getDaylightSavingCorrectionUSA(datetime);

    private:
        static const int marketOpenHour_;
        static const int marketOpenHourH4_;
        static const int marketCloseHour_;
        static const int marketCloseHourH4_;
        static const int marketCloseHourPending_;
        static const int marketOpenDay_;
        static const int marketCloseDay_;

        static const int findDayMaxYearsRange_;
        static const string knownTimeZoneBrokers_;

        static datetime today_;

        int getDaysInMonth(int, int);
        bool isLeapYear(int);
};

// TimeZone Milano
const int MarketTime::marketOpenHour_ = 9;
const int MarketTime::marketOpenHourH4_ = 8;
const int MarketTime::marketCloseHour_ = 17;
const int MarketTime::marketCloseHourH4_ = 20;
const int MarketTime::marketCloseHourPending_ = 16;
const int MarketTime::marketOpenDay_ = 1;
const int MarketTime::marketCloseDay_ = 5;

const int MarketTime::findDayMaxYearsRange_ = 5;
const string MarketTime::knownTimeZoneBrokers_ = "KEY TO MARKETS";

datetime MarketTime::today_ = -1;

MarketTime::~MarketTime() {
    today_ = -1;
}

int MarketTime::marketOpenHour() {
    return (Period() != PERIOD_H4) ? marketOpenHour_ : marketOpenHourH4_;
}

int MarketTime::marketCloseHour() {
    return (Period() != PERIOD_H4) ? marketCloseHour_ : marketCloseHourH4_;
}

int MarketTime::marketCloseHourPending() {
    return marketCloseHourPending_;
}

int MarketTime::marketOpenDay() {
    return marketOpenDay_;
}

int MarketTime::marketCloseDay() {
    return marketCloseDay_;
}

datetime MarketTime::timeItaly() {
    return TimeGMT() + 3600 * (1 + getDaylightSavingCorrectionCET());
}

datetime MarketTime::timeBroker() {
    const string broker = AccountCompany();

    if (StringContains(broker, knownTimeZoneBrokers_)) {
        return TimeGMT() + 3600 * (2 + getDaylightSavingCorrectionUSA());
    }

    return ThrowException(-1, __FUNCTION__, StringConcatenate("timeBroker, error for broker:", broker));
}

bool MarketTime::hasDateChanged(datetime date) {
    const datetime newToday = timeAtMidnight(date);

    if (today_ != newToday) {
        today_ = newToday;
        return true;
    }

    return false;
}

datetime MarketTime::timeAtMidnight(datetime date) {
    return date - (date % (PERIOD_D1 * 60));
}

// Can also be negative
int MarketTime::timeShiftInHours(datetime date1, datetime date2) {
    return MathRound((date1 - date2) / (double) 3600);
}

/**
 * This method returns true if the daylight saving time correction is on.
 *
 * @param {datetime=} date The date for which to check DST
 * @return boolean
 */
int MarketTime::getDaylightSavingCorrectionCET(datetime date = NULL) {
    if (!date) {
        date = TimeGMT();
    }

    const int year = TimeYear(date);

    // Changes at Midnight GMT rather than 01:00, but it doesn't matter
    const datetime lastSundayOfMarch = findDayOfWeekOccurrenceInMonth(year, MARCH, SUNDAY, -1);
    const datetime lastSundayOfOctober = findDayOfWeekOccurrenceInMonth(year, OCTOBER, SUNDAY, -1);

    if (date > lastSundayOfMarch && date < lastSundayOfOctober) {
        return 1;
    }

    return 0;
}

int MarketTime::getDaylightSavingCorrectionUSA(datetime date = NULL) {
    if (!date) {
        date = TimeGMT();
    }

    const int year = TimeYear(date);

    // Changes at Midnight GMT rather than 01:00, but it doesn't matter
    const datetime secondSundayOfMarch = findDayOfWeekOccurrenceInMonth(year, MARCH, SUNDAY, 2);
    const datetime firstSundayOfNovember = findDayOfWeekOccurrenceInMonth(year, NOVEMBER, SUNDAY, 1);

    if (date > secondSundayOfMarch && date < firstSundayOfNovember) {
        return 1;
    }

    return 0;
}

/**
 * Considerata la possibilita di usare anche -1 e -2 bisogna spiegare bene e mettere constraints su occurrence
 */
datetime MarketTime::findDayOfWeekOccurrenceInMonth(int year, int month, int dayOfWeek, int occurrence) {
    const int daysInMonth = getDaysInMonth(year, month);

    if (daysInMonth < 0 || occurrence == 0 || MathAbs(TimeYear(TimeGMT()) - year) > findDayMaxYearsRange_) {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Could not get days in month: ",
            month, " with occurrence: ", occurrence));
    }

    int startDay, endDay;

    if (occurrence > 0) {
        startDay = MathMin(1 + 7 * (occurrence - 1), daysInMonth - 7);
        endDay = MathMin(7 * occurrence, daysInMonth);
    } else if(occurrence < 0) {
        startDay = MathMax(1 + daysInMonth + 7 * occurrence, 1);
        endDay = MathMax(daysInMonth + 7 * (occurrence + 1), 7);
    }

    for (int day = startDay; day <= endDay; day++) {
        const datetime date = StringToTime(StringConcatenate(year, ".", month, ".", day));

        if (TimeDayOfWeek(date) == dayOfWeek) {
            return date;
        }
    }

    return ThrowException(-1, __FUNCTION__, "Could not calculate date");
}

int MarketTime::getDaysInMonth(int year, int month) {
    if (month == JANUARY) {
        return 31;
    }
    if (month == FEBRUARY) {
        return isLeapYear(year) ? 29 : 28;
    }
    if (month == MARCH) {
        return 31;
    }
    if (month == APRIL) {
        return 30;
    }
    if (month == MAY) {
        return 31;
    }
    if (month == JUNE) {
        return 30;
    }
    if (month == JULY) {
        return 31;
    }
    if (month == AUGUST) {
        return 31;
    }
    if (month == SEPTEMBER) {
        return 30;
    }
    if (month == OCTOBER) {
        return 31;
    }
    if (month == NOVEMBER) {
        return 30;
    }
    if (month == DECEMBER) {
        return 31;
    }

    return ThrowException(-1, __FUNCTION__, StringConcatenate("Could not calculate days in month: ", month));
}

bool MarketTime::isLeapYear(int year) {
    bool leapYearCondition = (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
    return leapYearCondition ? true : false;
}
