#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

input double PERCENT_RISK = 1.0; /// getPercentRisk: if !PercentRisk -> get from list of account owners

const bool IS_DEBUG = false;

bool INITIALIZATION_COMPLETED = false; // oppure dovrebbe chiamarsi UNIT_TESTS_FINISHED

const int BOT_MAGIC_NUMBER = 2044000; // then pass a different bot base number to each strategy Order's thing

const datetime BOT_EXPIRATION_DATE = (datetime) "2021-06-30";
const datetime BOT_TESTS_EXPIRATION_DATE = (datetime) "2025-01-01";

const int CANDLES_VISIBLE_IN_GRAPH_2X = 940; /// questa non dovrebbe essere un config pero
const int PATTERN_MINIMUM_SIZE_PIPS = 7;
const int PATTERN_MAXIMUM_SIZE_PIPS = 22;
const string NAME_SEPARATOR = "_";

/// credo che le variabili qui mi piacciano, devo spostarne di piu allora

const int ALLOWED_DEMO_ACCOUNT_NUMBERS [] = {
    2100219063, // Enrico
    2100220672, // Enrico
    2100225710, // Eugenio
    2100222405 // Tanya
};

const int ALLOWED_LIVE_ACCOUNT_NUMBERS [] = {
    2100183900, // Enrico
    2100175255, // Eugenio
    2100186686 // Tanya
};

const int ALLOWED_PERIODS [] = {
    PERIOD_M30,
    PERIOD_H1,
    PERIOD_H4
};

const int ALLOWED_MAGIC_NUMBERS [] = { // shouldn't be here, should be inside the code used by each strategy
    2044030,
    2044060,
    2044240
};

const string ALLOWED_BROKERS [] = {
    "KEY TO MARKETS NZ Limited",
    "KEY TO MARKETS NZ LIMITED"
};

const string ALLOWED_SYMBOLS [] = {
    "EURJPY",
    "EURUSD",
    "GBPCHF",
    "GBPJPY",
    "GBPUSD",
};

const string RESTRICTED_SYMBOL_FAMILIES_H4 [] = {
    "JPY"
};

// Sotto ci sono funzioni da migrare in classi o in file util

bool StringContains(string inputString, string inputSubString) {
    if (StringFind(inputString, inputSubString) != -1) {
        return true;
    }

    return false;
}

// questo potrebbe andare in Market dopo, cosi come iCandle e iExtreme (o magari quest'ultimo va in extremes o trendlines)
bool SymbolExists(string symbol) {
    ResetLastError();
    MarketInfo(symbol, MODE_TICKSIZE);

    if (GetLastError() != 4106) { // Unknown symbol error
        return true;
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate("Unexistent symbol: ", symbol));
}

/*
enum BotPeriod {
    M30 = PERIOD_M30,
    H1 = PERIOD_H1,
    H4 = PERIOD_H4,
};
*/

enum Discriminator {
   Max = 1,
   Min = -1,
};


double iExtreme(Discriminator discriminator, int timeIndex) {
    if (discriminator == Max) {
        return iCandle(I_high, timeIndex);
    }

    if (discriminator == Min) {
        return iCandle(I_low, timeIndex);
    }

    return ThrowException(-1, __FUNCTION__, "Could not get value");
}

enum CandleSeriesType {
    I_high,
    I_low,
    I_open,
    I_close,
    I_time
};

double iCandle(CandleSeriesType candleSeriesType, int timeIndex) {
    return iCandle(candleSeriesType, Symbol(), Period(), timeIndex);
}

// Assumes DownloadHistory() has been executed before
double iCandle(CandleSeriesType candleSeriesType, string symbol, int period, int timeIndex) { // servono unit tests su iCandle
    if (!SymbolExists(symbol)) {
        return ThrowException(-1, __FUNCTION__, "Unknown symbol");
    }

    if (timeIndex < 0) {
        if (candleSeriesType == I_time) {
            return TimeCurrent();
        }
        return ThrowException(-1, __FUNCTION__, "timeIndex < 0");
    }

    ResetLastError();
    double value = 0;

    if (candleSeriesType == I_high) {
        value = iHigh(symbol, period, timeIndex);
    } else if (candleSeriesType == I_low) {
        value = iLow(symbol, period, timeIndex);
    } else if (candleSeriesType == I_open) {
        value = iOpen(symbol, period, timeIndex);
    } else if (candleSeriesType == I_close) {
        value = iClose(symbol, period, timeIndex);
    } else if (candleSeriesType == I_time) {
        value = iTime(symbol, period, timeIndex);
    } else {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Unsupported candleSeriesType: ", candleSeriesType));
    }

    int lastError = GetLastError();

    if (lastError == 0 && value != 0) {
        return value;
    }

    return ThrowException(value, __FUNCTION__, StringConcatenate("candleSeriesType == ",
        EnumToString(candleSeriesType), ", lastError == ", lastError, ", value == ", value));;
}

datetime GetDate() { // MarketTime::timeAtMidnight(datetime)
    return CalculateDateByTimePeriod(PERIOD_D1);
}

datetime CalculateDateByTimePeriod(int period) {
    datetime now = TimeCurrent(); // could change with marketTime.timeBroker()

    if (period <= PERIOD_D1) {
        return now - now % (PERIOD_D1 * 60);
    }

    if (period == PERIOD_W1) {
        datetime time = now - now % (PERIOD_D1 * 60);

        while (TimeDayOfWeek(time) != SUNDAY) {
            time -= PERIOD_D1 * 60;
        }
        return time;
    }

    if (period == PERIOD_MN1) {
        int year = TimeYear(now);
        int month = TimeMonth(now);

        return StringToTime(StringConcatenate(year, ".", month, ".01"));
    }

    return ThrowException(-1, __FUNCTION__, StringConcatenate("Unsupported period: ", period));
}

bool DownloadHistory(string symbol = NULL) {
    if (symbol == NULL) {
        symbol = Symbol();
    }

    static const int HISTORY_DOWNLOAD_PERIODS [] = { /// estrarre
        PERIOD_M30,
        PERIOD_H1,
        PERIOD_H4,
        PERIOD_D1,
        PERIOD_W1,
        PERIOD_MN1
    };
    static const int attemptSleepTime = 200;
    static const int maxAttempts = 20;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
        int totalError = 0;
        ResetLastError();

        for (int i = 0; i < ArraySize(HISTORY_DOWNLOAD_PERIODS); i++) {
            int lastError = 0;
            int period = HISTORY_DOWNLOAD_PERIODS[i];

            iTime(symbol, period, 1);
            lastError = GetLastError();

            if (lastError != 0) {
                totalError += lastError;
            }
        }

        if (totalError == 0) {
            return true;
        } else if (attempt != maxAttempts - 1) {
            Print("Downloading missing history data, attempt: ", attempt);
            Sleep(attemptSleepTime);
        }
    }

    return ThrowException(false, __FUNCTION__, "Could not download history data");
}

double Pips(string symbol = NULL) { /// rename pip?
    return 10 * MarketInfo(symbol, MODE_TICKSIZE); /// serve unittest, non è pensabile altrimenti. ad esempio cambio broker a diverse digit (oppure niente classe ma comunque test)
}

double ErrorPips() {
    return 2 * PeriodFactor() * Pips();
}

int PeriodFactor(int period = NULL) {
    if (period == NULL) {
        period = Period();
    }

    if (period == PERIOD_H4) {
        return 2;
    }

    return 1;
}

double GetMarketSpread(string symbol = NULL) { /// rename GetSpread
    return MarketInfo(symbol, MODE_SPREAD) / 10;
}

double GetAsk(string symbol = NULL) { /// to be used for pips setups
    return MarketInfo(symbol, MODE_ASK); /// check where used and replace
}

int BotMagicNumber() {
    return (BOT_MAGIC_NUMBER + Period());
}

bool IsUnknownMagicNumber(int magicNumber) {
    for (int i = 0; i < ArraySize(ALLOWED_MAGIC_NUMBERS); i++) {
        if (magicNumber == ALLOWED_MAGIC_NUMBERS[i]) {
            return true;
        }
    }

    return false;
}

double GetMarketVolatility() { // Needs testing as well (price class with iCandle and Pips?)
    static datetime getMarketVolatilityTimeStamp; // if they go in a class, static variables must be destroyed at the end. Goes in trendline
    static double volatility;

    if (getMarketVolatilityTimeStamp != Time[0]) {
        int CandlesForVolatility = 465;
        double MarketMax = -10000, MarketMin = 10000;

        for (int i = 0; i < CandlesForVolatility; i++) {
            MarketMax = MathMax(MarketMax, iExtreme(Max, i));
            MarketMin = MathMin(MarketMin, iExtreme(Min, i));
        }

        volatility = MathAbs(MarketMax - MarketMin);
        getMarketVolatilityTimeStamp = Time[0];
    }

    return volatility;
}

string SymbolFamily(string symbol = NULL) {
    if (symbol == NULL) {
        symbol = Symbol();
    }

    if (StringContains(symbol, "EUR")) {
        return "EUR";
    } else if (StringContains(symbol, "GBP")) {
        return "GBP";
    } else if (StringContains(symbol, "USD")) {
        return "USD";
    } else if (StringContains(symbol, "AUD")) {
        return "AUD";
    } else if (StringContains(symbol, "NZD")) {
        return "NZD";
    } else {
        return StringSubstr(symbol, 0, 3);
    }
}

bool IsFirstRankSymbolFamily(string symbol = NULL) {
    if (symbol == NULL) {
        symbol = Symbol();
    }

    const string family = SymbolFamily(symbol);

/// SI MA NON DISTINGUE TRA GBPUSD E GBPCHF PER ESEMPIO
    if (family == "EUR" || family == "GBP" || family == "USD") { /// fare array variabile, e mettere sta funzione in OrderQualcosa
        return true;
    }

    return false;
}

template <typename T> void ArrayCopyClass(T & destination[], T & source[]) {
    ArrayResize(destination, ArraySize(source));

    for (int i = 0; i < ArraySize(source); i++) {
        destination[i] = source[i];
    }
}

template <typename T> void ArrayRemoveOrdered(T & array[], int index) { // maybe unit test
    for(int last = ArraySize(array) - 1; index < last; index++) {
        array[index] = array[index + 1];
    }
    ArrayResize(array, last);
}

template <typename T> void ArrayRemove(T & array[], int index) {
   int last = ArraySize(array) - 1;
   array[index] = array[last];
   ArrayResize(array, last);
}

template <typename T> T ThrowException(T returnValue, string function, string message) {
    ThrowException(function, message);
    return returnValue;
}

template <typename T> T ThrowException(T returnValue, string function, string message1, string message2) {
    return ThrowException(returnValue, function, StringConcatenate(message1, message2));
}

void ThrowException(string function, string message) {
    OptionalAlert(StringConcatenate(function, " | ThrowException invoked with message: ", message));
}

template <typename T> T ThrowFatalException(T returnValue, string function, string message) {
    ThrowFatalException(function, message);
    return returnValue;
}

void ThrowFatalException(string function, string message) {
    Alert(buildAlertMessage(StringConcatenate(function, " | ThrowFatalException invoked with message: ", message)));
    ExpertRemove();
}

datetime PrintTimer(datetime timeStamp, string message) {
    if (timeStamp != Time[0]) {
        Print(message);
        timeStamp = Time[0];
    }

    return timeStamp;
}

datetime PrintTimer(datetime timeStamp, string message1, string message2) {
    return PrintTimer(timeStamp, StringConcatenate(message1, message2));
}

datetime PrintTimer(datetime timeStamp, string message1, string message2, string message3) {
    return PrintTimer(timeStamp, StringConcatenate(message1, message2, message3));
}

datetime PrintTimer(datetime timeStamp, string message1, string message2, string message3, string message4) {
    return PrintTimer(timeStamp, StringConcatenate(message1, message2, message3, message4));
}

datetime AlertTimer(datetime timeStamp, string message) {
    if (timeStamp != Time[0]) {
        OptionalAlert(message);
        timeStamp = Time[0];
    }

    return timeStamp;
}

datetime AlertTimer(datetime timeStamp, string message1, string message2) {
    return AlertTimer(timeStamp, StringConcatenate(message1, message2));
}

void OptionalAlert(string message) { // should be private if it goes in a class
    const string fullMessage = buildAlertMessage(message);

    if (INITIALIZATION_COMPLETED) {
        Alert(fullMessage);
    } else {
        Print(fullMessage);
    }
}

string buildAlertMessage(string message) {
    return StringConcatenate(Symbol(), NAME_SEPARATOR, Period(), " | ", message);
}
