#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

input double PERCENT_RISK = 1.0; // getPercentRisk: if !PercentRisk -> get from list of account owners
input bool ALERT_ALLOWED = true;
input bool IS_DEBUG = false;

datetime STARTUP_TIME = NULL;

const int MY_SCRIPT_ID = 2044000;
const int MY_SCRIPT_ID_030 = 2044030;
const int MY_SCRIPT_ID_060 = 2044060;
const int MY_SCRIPT_ID_240 = 2044240;

const datetime BOT_EXPIRATION_DATE = (datetime) "2021-06-30";
const datetime BOT_TESTS_EXPIRATION_DATE = (datetime) "2025-01-01";

const int STARTUP_EXCEPTIONS_BUFFER_SECONDS = 10;

const int CANDLES_VISIBLE_IN_GRAPH_2X = 940;
const int PATTERN_MINIMUM_SIZE_PIPS = 7;
const int PATTERN_MAXIMUM_SIZE_PIPS = 22;
const string NAME_SEPARATOR = "_";

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


/*
const bool SelectedOrder;
const int PreviousOrderTicket;
const int OrderCandlesDuration = 6;
const bool PositionSplit = true;
const double BaseTakeProfitFactor = 3.0;
*/


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

    return ThrowException(false, __FUNCTION__, StringConcatenate("SymbolExists, uknown symbol: ", symbol));
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


double iExtreme(int timeIndex, Discriminator discriminator) {
    if (discriminator == Max) {
        return iCandle(I_high, timeIndex);
    }

    if (discriminator == Min) {
        return iCandle(I_low, timeIndex);
    }

    return ThrowException(-1, __FUNCTION__, "iExtreme: could not get value");
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

double iCandle(CandleSeriesType candleSeriesType, string symbol, int period, int timeIndex) { // servono unit tests su iCandle
    if (!SymbolExists(symbol)) {
        return ThrowException(-1, __FUNCTION__, "iCandle: unknown symbol");
    }

    if (timeIndex < 0) {
        if (candleSeriesType == I_time) {
            return TimeCurrent();
        }
        return ThrowException(-1, __FUNCTION__, "iCandle: timeIndex < 0");
    }

    const int maxAttempts = 20;

    for (int i = 0; i < maxAttempts; i++) {
        ResetLastError();
        RefreshRates();

        double value = 0;

        if (candleSeriesType == I_high) {
            value = iHigh(symbol, period, timeIndex);
        }
        if (candleSeriesType == I_low) {
            value = iLow(symbol, period, timeIndex);
        }
        if (candleSeriesType == I_open) {
            value = iOpen(symbol, period, timeIndex);
        }
        if (candleSeriesType == I_close) {
            value = iClose(symbol, period, timeIndex);
        }
        if (candleSeriesType == I_time) {
            value = iTime(symbol, period, timeIndex);
        }

        int lastError = GetLastError();

        if (lastError == 0 && value != 0) {
            return value;
        }

        if (IS_DEBUG || lastError != 4066) {
            Print("iCandle: candleSeriesType == ", EnumToString(candleSeriesType),
            ", lastError == ", lastError, ", value == ", value);
        }

        Sleep(500);
    }

    return ThrowException(-1, __FUNCTION__, "iCandle: could not get market data");
}

/*
int MathSign(double inputValue) {
    if (inputValue > 0) {
        return 1;
    } else if (inputValue < 0) {
        return -1;
    } else {
        return 0;
    }
}

string AntiDiscriminator(string Discriminator) {
    return Discriminator == "Min" ? "Max" : "Min";
}

string GetDiscriminatorFromSign(double inputValue) {
    if (inputValue >= 0) {
        return "Max";
    } else {
        return "Min";
    }
}
*/

double Pips(string symbol = NULL) {
    return 10 * MarketInfo(symbol, MODE_TICKSIZE); // serve unittest, non è pensabile altrimenti. ad esempio cambio broker a diverse digit (oppure niente classe ma comunque test)
}

double ErrorPips() {
    return 2 * PeriodMultiplicationFactor() * Pips();
}

int PeriodMultiplicationFactor() {
    if (Period() == PERIOD_H4) {
        return 2;
    }

    return 1;
}

double GetMarketSpread() {
    RefreshRates();
    return NormalizeDouble(MathAbs(Ask - Bid), Digits);
}

double GetMarketVolatility() {
    int CandlesForVolatility = 465;
    double MarketMax = -10000, MarketMin = 10000;

    for (int i = 0; i < CandlesForVolatility; i++) {
        MarketMax = MathMax(MarketMax, iCandle(I_high, i));
        MarketMin = MathMin(MarketMin, iCandle(I_low, i));
    }

    double Volatility = MathAbs(MarketMax - MarketMin);
    return Volatility;
}

bool IsLossLimiterEnabled() {
    // Dummy function for now
    return false;
}

bool ThrowException(bool returnValue, string function, string message) {
    ThrowException(function, message);
    return returnValue;
}

int ThrowException(int returnValue, string function, string message) {
    ThrowException(function, message);
    return returnValue;
}

datetime ThrowException(datetime returnValue, string function, string message) {
    ThrowException(function, message);
    return returnValue;
}

void ThrowException(string function, string message) {
    const string errorMessage = StringConcatenate(function, " | ThrowException invoked with message: ", message);
    if (TimeLocal() < STARTUP_TIME + STARTUP_EXCEPTIONS_BUFFER_SECONDS) {
        Print(errorMessage);
    } else {
        OptionalAlert(errorMessage);
    }
}

void ThrowFatalException(string function, string message) {
    const string errorMessage = StringConcatenate(function, " | ThrowFatalException invoked with message: ", message);
    OptionalAlert(errorMessage);
    ExpertRemove();
}

void OptionalAlert(string message, bool limitOutput = false) {
    static datetime alertTimeStamp;

    if (ALERT_ALLOWED && (alertTimeStamp != Time[0] || limitOutput)) {
        Alert(message);
        alertTimeStamp = Time[0];
    } else {
        Print(message);
    }
}
