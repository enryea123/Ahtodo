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
        bool isMarketOpened();
        int marketOpenHour();   // public o protected?
        int marketCloseHour();
        int marketCloseHourPending();

        datetime timeItaly();
        datetime timeBroker();
        datetime timeAtMidnight(datetime);
        int timeShiftInHours(datetime, datetime);

    protected:
        bool isMarketOpened(datetime);
        datetime findDayOfWeekOccurrenceInMonth(int, int, int, int);
        int getDaylightSavingCorrectionCET(datetime);
        int getDaylightSavingCorrectionUSA(datetime);

    private:
        static const string knownTimeZoneBrokers_;

        int getDaysInMonth(int, int);
        bool isLeapYear(int);
};

const string MarketTime::knownTimeZoneBrokers_ = "KEY TO MARKETS";

bool MarketTime::isMarketOpened() {
    return isMarketOpened(timeItaly());
}

bool MarketTime::isMarketOpened(datetime date) {
    const int hour = TimeHour(date);
    const int dayOfWeek = TimeDayOfWeek(date);

    if (hour >= marketOpenHour() && hour < marketCloseHour() &&
        dayOfWeek >= MARKET_OPEN_DAY && dayOfWeek < MARKET_CLOSE_DAY) {
        return true;
    }

    return false;
}

int MarketTime::marketOpenHour() {
    return (Period() != PERIOD_H4) ? MARKET_OPEN_HOUR : MARKET_OPEN_HOUR_H4;
}

int MarketTime::marketCloseHour() {
    return (Period() != PERIOD_H4) ? MARKET_CLOSE_HOUR : MARKET_CLOSE_HOUR_H4;
}

int MarketTime::marketCloseHourPending() {
    return MARKET_CLOSE_HOUR_PENDING;
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

    if (daysInMonth < 0 || occurrence == 0 || MathAbs(TimeYear(TimeGMT()) - year) > 5) {
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

    return ThrowException(-1, __FUNCTION__, StringConcatenate(
        "Could not calculate date"));
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
