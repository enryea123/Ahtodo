#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"


class MarketTime {
    public:
        MarketTime();
        ~MarketTime();

        bool getDaylightSavingCorrectionGMT(datetime);
        bool isMarketOpened(datetime);
        int getDaylightSavingCorrection();
        int marketOpenHour();
        int marketCloseHour();
        int marketOpenHour();
        int marketOpenHour();
};

MarketTime::MarketTime() {}

MarketTime::~MarketTime() {}


// verifica come testare metodi protetti, non va bene dare la possibilita pubblica di usare parametri nel metodi dove non si dovrebbe. quindi va cambiato. ha senso testare ereditando?


/**
 * This method returns true if the daylight saving time correction is on.
 *
 * @param {datetime=} date The date for which to check DST
 * @return boolean
 */
int MarketTime::getDaylightSavingCorrectionGMT(datetime date = NULL) {
    if (!date) {
        date = TimeGMT();
    }

    const int day = TimeDay(date);
    const int month = TimeMonth(date);
    const int year = TimeYear(date);
    const int dayOfWeek = TimeDayOfWeek(date);

    const datetime lastSundayOfMarch = getLastSundayOfMonth(year, 3);
    const datetime lastSundayOfOctober = getLastSundayOfMonth(year, 10);

    if (date > lastSundayOfMarch && date < lastSundayOfOctober) {
        return 1;
    }

    return 0;
}

datetime MarketTime::getLastSundayOfMonth(int year, int month) {
    if (month != 3 && month != 10) {
        return ThrowException(-1, StringConcatenate("Cannot calculate last Sunday of month: ", month));
    }

    for (int day = 25; day < 32; day++) {
        const datetime date = StringToTime(StringConcatenate(year, ".", month, ".", day, " 01:00:00"));

        if (TimeDayOfWeek(date) == 0) {
            return date;
        }
    }
}

datetime MarketTime::timeItaly() {
    return TimeGMT() + 3600 * (1 + getDaylightSavingCorrectionGMT());
}

int MarketTime::marketOpenHour() {
    const int baseMarketOpenHour = CURRENT_PERIOD != PERIOD_H4 ? MARKET_OPEN_HOUR : MARKET_OPEN_HOUR_H4;

    return baseMarketOpenHour + getDaylightSavingCorrectionGMT();
}

int MarketTime::marketCloseHour() {
    const int baseMarketCloseHour = CURRENT_PERIOD != PERIOD_H4 ? MARKET_CLOSE_HOUR : MARKET_CLOSE_HOUR_H4;

    return baseMarketCloseHour + getDaylightSavingCorrectionGMT();
}

bool MarketTime::isMarketOpened(datetime date = NULL) {
    if (!date) {
        date = timeItaly();
    }

    const int hour = TimeHour(date);
    const int dayOfWeek = TimeDayOfWeek(date);

    if (hour >= marketOpenHour() && hour < marketCloseHour() &&
        dayOfWeek >= MARKET_OPEN_DAY && dayOfWeek < MARKET_CLOSE_DAY) {
        return true;
    }

    return false;
}

// https://www.timeanddate.com/time/zone/uk/london
// Bisogna testare questa classe, eri arrivato qui

//0	08:49:18.467	Ahtodo AUDUSD,H1: TimeCurrent(): 2020.10.27 10:49
//0	08:49:18.467	Ahtodo AUDUSD,H1: TimeLocal(): 2020.10.27 08:49
//0	08:49:18.467	Ahtodo AUDUSD,H1: TimeGMT(): 2020.10.27 07:49
//0	08:49:18.467	Ahtodo AUDUSD,H1: Hour(): 10


// nuova funzione isMarketOpenedFirstBar? (che cancola direttamente se si possono fare ordini a -6)


/*
    if (DayOfWeek() >= MARKET_CLOSE_DAY || DayOfWeek() < MARKET_OPEN_DAY) {
        SetChartMarketClosedColors();
    }

bool Market::isMarketOpened(day, hour, minute?) {
    if (year < 2022) {
        return true; // exception? fatal exception? Incorporate in other method. already isAllowedExecutionDate in Market. ThrowFatalException gia li
    }
}
*/
