#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#define MY_SCRIPT_ID 2044000
#define MY_SCRIPT_ID_030 2044030
#define MY_SCRIPT_ID_060 2044060
#define MY_SCRIPT_ID_240 2044240

#define MARKET_OPEN_HOUR 10 // a queste non serve essere define
#define MARKET_CLOSE_HOUR 18
#define MARKET_OPEN_HOUR_H4 2
#define MARKET_CLOSE_HOUR_H4 22
#define MARKET_CLOSE_HOUR_PENDING 17
#define MARKET_OPEN_DAY 1
#define MARKET_CLOSE_DAY 5

bool SelectedOrder;
int PreviousOrderTicket;

int OrderCandlesDuration = 6;

const int CURRENT_PERIOD = Period();
const string CURRENT_SYMBOL = Symbol();

// mettere TUTTE le costanti qui
// forse rinominare il file a Config.mqh o Variables.Mqh

const int PATTERN_MINIMUM_SIZE_PIPS = 7;
const int PATTERN_MAXIMUM_SIZE_PIPS = 22;

const int TRENDLINE_MIN_EXTREMES_DISTANCE = 3;
const double TRENDLINE_NEGATIVE_SLOPE_VOLATILITY = 0.0038;
const double TRENDLINE_POSITIVE_SLOPE_VOLATILITY = 0.0024;

const datetime BOT_EXPIRATION_DATE = (datetime) "2021-06-30";

const int CANDLES_VISIBLE_IN_GRAPH_2X = 940;
const bool IS_DEBUG = false;

bool PositionSplit = true;

input double PercentRisk = 1.0;
double BaseTakeProfitFactor = 3.0;

bool IsPeriodAllowed(int i){
    return true;
}

bool StringContains(string inputString, string inputSubString){
    if(StringFind(inputString, inputSubString) != -1)
        return true;
    return false;
}

// questo potrebbe andare in Market dopo, cosi come iCandle e iExtreme (o magari quest'ultimo va in extremes o trendlines)
bool SymbolExists(string symbol){
    ResetLastError();
    MarketInfo(symbol, MODE_TICKSIZE);

    if(GetLastError() != 4106) // Unknown symbol error
        return true;

    return ThrowException(false, StringConcatenate("SymbolExists, uknown symbol: ", symbol));
}

/*
enum BotPeriod{
    M30 = PERIOD_M30,
    H1 = PERIOD_H1,
    H4 = PERIOD_H4,
};
*/

enum Discriminator{
   Max = 1,
   Min = -1,
};


double iExtreme(int timeIndex, Discriminator discriminator){
    if(discriminator == Max)
        return iCandle(I_high, timeIndex);
    if(discriminator == Min)
        return iCandle(I_low, timeIndex);

    return ThrowException(-1, "iExtreme: could not get value");
}

enum CandleSeriesType{
    I_high,
    I_low,
    I_open,
    I_close,
    I_time
};

double iCandle(CandleSeriesType candleSeriesType, int timeIndex){
    return iCandle(candleSeriesType, CURRENT_SYMBOL, CURRENT_PERIOD, timeIndex);
}

double iCandle(CandleSeriesType candleSeriesType, string symbol, int period, int timeIndex){ // servono unit tests su iCandle
    if(!SymbolExists(symbol))
        return ThrowException(-1, "iCandle: unknown symbol");

    if(timeIndex < 0){
        if(candleSeriesType == I_time)
            return TimeCurrent();

        return ThrowException(-1, "iCandle: timeIndex < 0");
    }

    const int maxAttempts = 20;

    for(int i = 0; i < maxAttempts; i++){
        ResetLastError();
        RefreshRates();

        double value = 0;

        if(candleSeriesType == I_high)
            value = iHigh(symbol, period, timeIndex);
        if(candleSeriesType == I_low)
            value = iLow(symbol, period, timeIndex);
        if(candleSeriesType == I_open)
            value = iOpen(symbol, period, timeIndex);
        if(candleSeriesType == I_close)
            value = iClose(symbol, period, timeIndex);
        if(candleSeriesType == I_time)
            value = iTime(symbol, period, timeIndex);

        int lastError = GetLastError();

        if(lastError == 0 && value != 0)
            return value;

        if(IS_DEBUG || lastError != 4066)
            Print("iCandle: candleSeriesType == ", EnumToString(candleSeriesType),
            ", lastError == ", lastError, ", value == ", value);

        Sleep(500);
    }

    return ThrowException(-1, "iCandle: could not get market data");
}

/*
int MathSign(double inputValue){
    if(inputValue > 0)
        return 1;
    else if(inputValue < 0)
        return -1;
    else
        return 0;
}

string AntiDiscriminator(string Discriminator){
    return Discriminator == "Min" ? "Max" : "Min";
}

string GetDiscriminatorFromSign(double inputValue){
    if(inputValue >= 0)
        return "Max";
    else
        return "Min";
}
*/

double Pips(string symbol = NULL){
    return 10 * MarketInfo(symbol, MODE_TICKSIZE); // serve unittest, non è pensabile altrimenti. ad esempio cambio broker a diverse digit (oppure niente classe ma comunque test)
}

double ErrorPips(){
    return 2 * PeriodMultiplicationFactor() * Pips();
}

int PeriodMultiplicationFactor(){
    if(CURRENT_PERIOD == PERIOD_H4)
        return 2;
    return 1;
}

double GetMarketVolatility(){
    int CandlesForVolatility = 465;
    double MarketMax = -10000, MarketMin = 10000;

    for(int i = 0; i < CandlesForVolatility; i++){
        MarketMax = MathMax(MarketMax, iCandle(I_high, i));
        MarketMin = MathMin(MarketMin, iCandle(I_low, i));
    }

    double Volatility = MathAbs(MarketMax - MarketMin);
    return Volatility;
}

bool ThrowException(bool returnValue, string message){
    Print("ThrowException invoked with message: ", message);
    return returnValue;
}

int ThrowException(int returnValue, string message){
    Print("ThrowException invoked with message: ", message);
    return returnValue;
}

void ThrowException(string message){
    Print("ThrowException invoked with message: ", message);
}

int ThrowFatalException(string message){
    Alert("ThrowFatalException invoked with message: ", message);

    ExpertRemove();
    return -1;
}

int MarketOpenHour(){
    if(CURRENT_PERIOD == PERIOD_H4)
        return MARKET_OPEN_HOUR_H4;

    return MARKET_OPEN_HOUR;
}

int MarketCloseHour(){
    if(CURRENT_PERIOD == PERIOD_H4)
        return MARKET_CLOSE_HOUR_H4;

    return MARKET_CLOSE_HOUR;
}
