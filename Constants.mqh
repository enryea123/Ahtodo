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

// mettere TUTTE le costanti qui

const int PATTERN_MINIMUM_SIZE_PIPS = 7;
const int PATTERN_MAXIMUM_SIZE_PIPS = 22;

const int TRENDLINE_MIN_EXTREMES_DISTANCE = 3;
const double TRENDLINE_NEGATIVE_SLOPE_VOLATILITY = 0.0038;
const double TRENDLINE_POSITIVE_SLOPE_VOLATILITY = 0.0024;


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

enum BotPeriod{
    M30 = PERIOD_M30,
    H1 = PERIOD_H1,
    H4 = PERIOD_H4,
};


enum Discriminator{
   Max = 1,
   Min = -1,
};

bool IsAllowedSymbol(string symbol){
    if(symbol == NULL
    || symbol == EnumToString(EURJPY)
    || symbol == EnumToString(EURUSD)
    || symbol == EnumToString(GBPCHF)
    || symbol == EnumToString(GBPJPY)
    || symbol == EnumToString(GBPUSD))
        return true;

    if(IsDemo() && IsAllowedTestSymbol(symbol))
        return true;

    return false;
}

bool IsAllowedTestSymbol(string symbol){
    // New cross being tested
    if(symbol == EnumToString(AUDUSD)
    || symbol == EnumToString(EURGBP)
    || symbol == EnumToString(EURNZD)
    || symbol == EnumToString(NZDUSD)
    || symbol == EnumToString(USDCAD)
    || symbol == EnumToString(USDCHF)
    || symbol == EnumToString(USDJPY))
        return true;

    return false;
}

enum AllowedSymbol{
    EURJPY,
    EURUSD,
    GBPCHF,
    GBPJPY,
    GBPUSD,
};

enum AllowedTestSymbol{
    AUDUSD,
    EURGBP,
    EURNZD,
    NZDUSD,
    USDCAD,
    USDCHF,
    USDJPY,
};

double iExtreme(int InputTime, Discriminator discriminator){
    if(discriminator == Min)
        return iLow(NULL, Period(), InputTime);
    else if(discriminator == Max)
        return iHigh(NULL, Period(), InputTime);
    else
        return NULL;
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

double Pips(){
    return Pips(Symbol());
}

double Pips(string OrderSymbol){
    return 10 * MarketInfo(OrderSymbol, MODE_TICKSIZE);
}

double ErrorPips(){
    return 2 * PeriodMultiplicationFactor() * Pips();
}

int PeriodMultiplicationFactor(){
    if(Period() == PERIOD_H4)
        return 2;
    return 1;
}

double GetMarketVolatility(){
    int CandlesForVolatility = 465;
    double MarketMax = -10000, MarketMin = 10000;

    for(int i = 0; i < CandlesForVolatility; i++){
        MarketMax = MathMax(MarketMax, iHigh(NULL, Period(), i));
        MarketMin = MathMin(MarketMin, iLow(NULL, Period(), i));
    }

    double Volatility = MathAbs(MarketMax - MarketMin);
    return Volatility;
}

double CandleMidPoint(int TimeIndex){
    return MathAbs(iHigh(NULL, Period(), TimeIndex) + iLow(NULL, Period(), TimeIndex)) / 2;
}

bool ThrowException(bool returnValue, string message){
    Print("ThrowException invoked with message: ", message);
    return returnValue;
}

int ThrowException(int returnValue, string message){
    Print("ThrowException invoked with message: ", message);
    return returnValue;
}

int ThrowFatalException(string message){
    Print("ThrowFatalException invoked with message: ", message);
    ExpertRemove();

    return -1;
}


datetime CandleStartTime(string orderSymbol, int period, int timeIndex){
    if(timeIndex < 0)
        return TimeCurrent();

    return iTime(orderSymbol, period, timeIndex);
}


int MarketOpenHour(){
    if(Period() == PERIOD_H4)
        return MARKET_OPEN_HOUR_H4;

    return MARKET_OPEN_HOUR;
}

int MarketCloseHour(){
    if(Period() == PERIOD_H4)
        return MARKET_CLOSE_HOUR_H4;

    return MARKET_CLOSE_HOUR;
}

/*
datetime CandleStartTime(string orderSymbol, PivotPeriod pivotPeriod, int timeIndex){
    if(timeIndex < 0)
        return TimeCurrent();

    return iTime(orderSymbol, pivotPeriod, timeIndex);
}

datetime CandleStartTime(string orderSymbol, BotPeriod botPeriod, int timeIndex){
    if(timeIndex < 0)
        return TimeCurrent();

    return iTime(orderSymbol, botPeriod, timeIndex);
}
*/