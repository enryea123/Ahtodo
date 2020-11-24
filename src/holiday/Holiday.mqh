#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "../market/MarketTime.mqh"


class Holiday {
    public:
        bool isMajorBankHoliday();
        bool isMinorBankHoliday();

    protected:
        bool isMajorBankHoliday(datetime);
        bool isMinorBankHoliday(datetime);

    private:
        int easterDayOfYear(int);
};

bool Holiday::isMajorBankHoliday() {
    return isMajorBankHoliday(TimeGMT()); // timeMilan
}

bool Holiday::isMinorBankHoliday() {
    return isMinorBankHoliday(TimeGMT());
}

bool Holiday::isMajorBankHoliday(datetime inputDate) {
    if (!inputDate) {
        inputDate = TimeGMT();
    }

    const int day = TimeDay(inputDate);
    const int month = TimeMonth(inputDate);
    const int year = TimeYear(inputDate);
    const int dayOfWeek = TimeDayOfWeek(inputDate);
    const int dayOfYear = TimeDayOfYear(inputDate);

    if (easterDayOfYear(year) < 0) {
        return ThrowException(false, __FUNCTION__, StringConcatenate("Easter day of year ", year, " not known"));
    }

    if (month == JANUARY) {
        // Christmas Holidays Season
        if (day < 7) {
            return true;
        }

        // US: Martin Luther King Birthday (Third Monday in January)
        if (dayOfWeek == MONDAY && MathCeil(day / 7.0) == 3) {
            return true;
        }
    }

    if (month == FEBRUARY) {
        // US: President's Day (Third Monday in February)
        if (dayOfWeek == MONDAY && MathCeil(day / 7.0) == 3) {
            return true;
        }
    }

    if (month == MAY) {
        // IT, FR, DE, UK: Lavoro
        if (day == 1) {
            return true;
        }

        // US: Memorial Day (Last Monday in May)
        // UK: Spring Bank Holiday (Last Monday in May)
        if (dayOfWeek == MONDAY && 31 - day < 7) {
            return true;
        }
    }

    if (month == JULY) {
        // US: Independence Day
        if (day == 4 || (day == 3 && dayOfWeek == FRIDAY) || (day == 5 && dayOfWeek == MONDAY)) {
            return true;
        }
    }

    if (month == AUGUST) {
        // Summer Holidays
        if (day > 7 && day < 24) {
            return true;
        }

        // IT: Ferragosto
        if (day == 15) {
            return true;
        }
    }

    if (month == SEPTEMBER) {
        // US: Labor Day (First Monday in September)
        if (dayOfWeek == MONDAY && MathCeil(day / 7.0) == 1) {
            return true;
        }
    }

    if (month == OCTOBER) {
        // US: Columbus Day (Second Monday in October)
        if (dayOfWeek == MONDAY && MathCeil(day / 7.0) == 2) {
            return true;
        }
    }

    if (month == NOVEMBER) {
        // US: Veterans Day
        if (day == 11 || (day == 10 && dayOfWeek == FRIDAY) || (day == 12 && dayOfWeek == MONDAY)) {
            return true;
        }

        // US: Thanksgiving Day (Fourth Thursday in November
        if (dayOfWeek == THURSDAY && MathCeil(day / 7.0) == 4) {
            return true;
        }
    }

    if (month == DECEMBER) {
        // Christmas Holidays Season
        if (day > 20) {
            return true;
        }
    }

    // Easter Good Friday
    if (dayOfYear == easterDayOfYear(year) - 2) {
        return true;
    }

    // Pasquetta
    if (dayOfYear == easterDayOfYear(year) + 1) {
        return true;
    }

    // Ascension
    if (dayOfYear == easterDayOfYear(year) + 39) {
        return true;
    }

    // Pentecoste
    if (dayOfYear == easterDayOfYear(year) + 49) {
        return true;
    }

    return false;
}

bool Holiday::isMinorBankHoliday(datetime inputDate) {
    if (!inputDate) {
        inputDate = TimeGMT();
    }

    const int day = TimeDay(inputDate);
    const int month = TimeMonth(inputDate);
    const int dayOfWeek = TimeDayOfWeek(inputDate);

    if (month == APRIL) {
        // IT: Liberazione
        if (day == 25) {
            return true;
        }
    }

    if (month == MAY) {
        // UK: Early May Bank Holiday (First Monday in May)
        if (dayOfWeek == MONDAY && MathCeil(day / 7.0) == 1) {
            return true;
        }

        // FR: Victory Day
        if (day == 8) {
            return true;
        }
    }

    if (month == JUNE) {
        // IT: Festa della Repubblica
        if (day == 2) {
            return true;
        }
    }

    if (month == JULY) {
        // FR: Bastille
        if (day == 14) {
            return true;
        }
    }

    if (month == AUGUST) {
        // Summer Holidays
        return true;

        // CH: National Day
        if (day == 1) {
            return true;
        }

        // UK: Summer Bank Holiday (Last Monday in August)
        if (dayOfWeek == MONDAY && 31 - day < 7) {
            return true;
        }
    }

    if (month == OCTOBER) {
        // DE: German Unity
        if (day == 3) {
            return true;
        }
    }

    if (month == NOVEMBER) {
        // IT: Tutti i Santi
        if (day == 1) {
            return true;
        }

        // FR: Armistice
        if (day == 11) {
            return true;
        }
    }

    if (month == DECEMBER) {
        // IT: Immacolata
        if (day == 8) {
            return true;
        }
    }

    return false;
}

int Holiday::easterDayOfYear(int year) {
    if (year == 2020) {
        return 103;
    }
    if (year == 2021) {
        return 94;
    }
    if (year == 2022) {
        return 107;
    }
    if (year == 2023) {
        return 99;
    }
    if (year == 2024) {
        return 91;
    }
    if (year == 2025) {
        return 110;
    }
    if (year == 2026) {
        return 95;
    }

    return -1;
}
