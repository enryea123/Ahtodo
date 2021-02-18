#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "src/util/Map.mqh"


/**
 * This file acts like a config, it contains all the variables needed by the program.
 * The Maps defined here need to be initialized in OnInit.
 */

input double PERCENT_RISK = 1.0;

bool UNIT_TESTS_COMPLETED = false;

enum Discriminator {
   Max = 1,
   Min = -1,
};

// Constants start here

const bool IS_DEBUG = false;
const bool SPLIT_POSITION = true;
const bool SUFFERING_STOPLOSS = false;

const datetime BOT_EXPIRATION_DATE = (datetime) "2021-06-30";

// TimeZone Milano
const int MARKET_OPEN_HOUR = 8;
const int MARKET_OPEN_HOUR_H4 = 8;
const int MARKET_CLOSE_HOUR = 17;
const int MARKET_CLOSE_HOUR_H4 = 20;
const int MARKET_CLOSE_HOUR_PENDING = 16;
const int MARKET_OPEN_DAY = 1;
const int MARKET_CLOSE_DAY = 5;

const int BASE_MAGIC_NUMBER = 2044000;

const int ALLOWED_MAGIC_NUMBERS [] = {
    2044030,
    2044060,
    2044240
};

const int ALLOWED_DEMO_ACCOUNT_NUMBERS [] = {
    2100219063, // Enrico
    2100220671, // Enrico
    2100220672, // Enrico
    2100222172, // Enrico
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

const int HISTORY_DOWNLOAD_PERIODS [] = {
    PERIOD_M1,
    PERIOD_M5,
    PERIOD_M15,
    PERIOD_M30,
    PERIOD_H1,
    PERIOD_H4,
    PERIOD_D1,
    PERIOD_W1,
    PERIOD_MN1
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

const string BROKER_BREAKEVEN_COMMENT_PREFIX [] = {
    "from #",
    "to #"
};

const string NAME_SEPARATOR = "_";
const string COMMENT_SEPARATOR = " ";
const string FILTER_SEPARATOR = "|";
const string MESSAGE_SEPARATOR = " | ";

const double MAX_TAKEPROFIT_FACTOR = 3;
const double MIN_TAKEPROFIT_FACTOR = 1;
const int TAKEPROFIT_OBSTACLE_BUFFER_PIPS = 4;

const int CANDLES_VISIBLE_IN_GRAPH_3X = 465;
const int CANDLES_VISIBLE_IN_GRAPH_2X = 940;

const int PATTERN_MINIMUM_SIZE_PIPS = 8;
const int PATTERN_MAXIMUM_SIZE_PIPS = 22;

const int ANTIPATTERN_MIN_SIZE_SUM_PIPS = 50;
const int PATTERN_DRAW_MAX_CANDLES = 200;
const int PIVOT_LINES_DRAW_MAX_CANDLES = 100;
const string PATTERN_NAME_PREFIX = "Pattern";

const string ARROW_NAME_PREFIX = "Arrow";
const string VALID_ARROW_NAME_SUFFIX = "Valid";
const string LEVEL_NAME_PREFIX = "Level";

const double EMERGENCY_SWITCHOFF_OPENPRICE = 42;
const double EMERGENCY_SWITCHOFF_STOPLOSS = 41;
const double EMERGENCY_SWITCHOFF_TAKEPROFIT = 43;

const int LOSS_LIMITER_HOURS = 8;
const int LOSS_LIMITER_MAX_ALLOWED_LOSSES_PERCENT = 10;

const int FIND_DAY_MAX_YEARS_RANGE = 5;

const int EXTREMES_MIN_DISTANCE = 2;
const int LEVELS_MIN_DISTANCE = 4;

const int INCORRECT_CLOCK_ERROR_SECONDS = 60;

const int OPEN_MARKET_LOOKBACK_MINUTES = 15;
const int SPREAD_PIPS_CLOSE_MARKET = 6;

const int MAX_ORDER_COMMENT_CHARACTERS = 20;
const int ORDER_CANDLES_DURATION = 6;
const int TRENDLINE_SETUP_MAX_PIPS_DISTANCE = 3;

const string STRATEGY_PREFIX = "A";
const string PERIOD_COMMENT_IDENTIFIER = "P";
const string SIZE_FACTOR_COMMENT_IDENTIFIER = "M";
const string TAKEPROFIT_FACTOR_COMMENT_IDENTIFIER = "R";
const string STOPLOSS_PIPS_COMMENT_IDENTIFIER = "S";

const int SMALLER_STOPLOSS_BUFFER_PIPS = 1;

const int DRAW_OPEN_MARKET_LINES_MAX_DAYS = 40;
const int OPEN_MARKET_LINES_PIPS_SHIFT = 10;
const string LAST_DRAWING_TIME_PREFIX = "LastDrawingTime";
const string OPEN_MARKET_LINE_PREFIX = "OpenMarketLine";

const int TRENDLINE_BEAMS = 2;
const int TRENDLINE_WIDTH = 5;
const int BAD_TRENDLINE_WIDTH = 1;
const color TRENDLINE_COLOR = clrYellow;
const color BAD_TRENDLINE_COLOR = clrMistyRose;
const string TRENDLINE_NAME_PREFIX = "TrendLine";
const string TRENDLINE_BAD_NAME_SUFFIX = "Bad";
const string TRENDLINE_NAME_BEAM_IDENTIFIER = "b";
const string TRENDLINE_NAME_FIRST_INDEX_IDENTIFIER = "i";
const string TRENDLINE_NAME_SECOND_INDEX_IDENTIFIER = "j";

const int TRENDLINE_MIN_CANDLES_LENGTH = 12;
const int TRENDLINE_MIN_EXTREMES_DISTANCE = 3;
const int TRENDLINE_TOLERANCE_PIPS = 2;
const double TRENDLINE_NEGATIVE_SLOPE_VOLATILITY = 0.0038;
const double TRENDLINE_POSITIVE_SLOPE_VOLATILITY = 0.0024;
const double TRENDLINE_BALANCE_RATIO_THRESHOLD = 0.92;

const string CALENDAR_FILE = "ff_calendar_thisweek.csv";
const string CALENDAR_HEADER = "Title,Country,Date,Time,Impact,Forecast,Previous";

const int NEWS_TIME_WINDOW_MINUTES = 60;
const int NEWS_LABEL_FONT_SIZE = 10;
const int NEWS_LABEL_PIPS_SHIFT = 20;
const string NEWS_LINE_NAME_PREFIX = "NewsLine";
const string NEWS_LABEL_NAME_PREFIX = "NewsLabel";

// Associative Maps
Map<int, int> BREAKEVEN_STEPS;
Map<int, int> SUFFERING_STEPS;
Map<int, double> PERCENT_RISK_ACCOUNT_EXCEPTIONS;
Map<int, int> MORNING_LOOKBACK_CANDLES;
Map<string, int> RESTRICTED_SYMBOLS;

// Maps need to be initialized by OnInit
void InitializeMaps() {
    BREAKEVEN_STEPS.put(6, 4);
    BREAKEVEN_STEPS.put(25, 0);
    BREAKEVEN_STEPS.lock();

    SUFFERING_STEPS.put(15, 15);
    SUFFERING_STEPS.put(30, 10);
    SUFFERING_STEPS.put(45, 5);
    SUFFERING_STEPS.put(60, 0);
    SUFFERING_STEPS.lock();

    PERCENT_RISK_ACCOUNT_EXCEPTIONS.put(2100183900, 2.0);
    PERCENT_RISK_ACCOUNT_EXCEPTIONS.lock();

    MORNING_LOOKBACK_CANDLES.put(PERIOD_M30, 2);
    MORNING_LOOKBACK_CANDLES.put(PERIOD_H1, 1);
    MORNING_LOOKBACK_CANDLES.put(PERIOD_H4, 1);
    MORNING_LOOKBACK_CANDLES.lock();

    RESTRICTED_SYMBOLS.put("EURJPY", PERIOD_H4);
    RESTRICTED_SYMBOLS.put("GBPJPY", PERIOD_H4);
    RESTRICTED_SYMBOLS.lock();
}

// TimeStamps for filtered AlertTimer and PrintTimer
datetime NEWS_TIMESTAMP = -1;
datetime SPREAD_TIMESTAMP = -1;
datetime WRONG_CLOCK_TIMESTAMP = -1;

datetime ANTIPATTERN_TIMESTAMP = -1;
datetime FOUND_PATTERN_TIMESTAMP = -1;
datetime SELL_SETUP_TIMESTAMP = -1;
datetime BUY_SETUP_TIMESTAMP = -1;
datetime NO_SETUP_TIMESTAMP = -1;

datetime VOLATILITY_TIMESTAMP = -1;
datetime ORDER_MODIFIED_TIMESTAMP = -1;
