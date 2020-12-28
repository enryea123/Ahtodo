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

const bool IS_DEBUG = false;
const bool SPLIT_POSITION = true;

const datetime BOT_EXPIRATION_DATE = (datetime) "2021-06-30";
const datetime BOT_TESTS_EXPIRATION_DATE = (datetime) "2025-01-01";

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

const string NAME_SEPARATOR = "_";
const string MESSAGE_SEPARATOR = " | ";

const double BASE_TAKE_PROFIT_FACTOR = 3;

const int CANDLES_VISIBLE_IN_GRAPH_3X = 465;
const int CANDLES_VISIBLE_IN_GRAPH_2X = 940;

const int PATTERN_MINIMUM_SIZE_PIPS = 8;
const int PATTERN_MAXIMUM_SIZE_PIPS = 22;

const int ANTIPATTERN_MIN_SIZE_SUM_PIPS = 50;
const int PATTERN_DRAW_MAX_CANDLES = 200;
const int PIVOT_LINES_DRAW_MAX_CANDLES = 100;

const int LOSS_LIMITER_HOURS = 8;
const int LOSS_LIMITER_MAX_ALLOWED_LOSSES_PERCENT = 10;

const int MINIMUM_CANDLES_BETWEEN_EXTREMES = 1;
const int SMALLEST_ALLOWED_EXTREME_INDEX = 4;

const int OPEN_MARKET_LOOKBACK_MINUTES = 15;
const int SPREAD_PIPS_CLOSE_MARKET = 5;

const int MAX_ORDER_COMMENT_CHARACTERS = 20;
const int ORDER_CANDLES_DURATION = 6;
const int TRENDLINE_SETUP_MAX_PIPS_DISTANCE = 3;

const int TRENDLINE_BEAMS = 2;
const int TRENDLINE_WIDTH = 5;
const int BAD_TRENDLINE_WIDTH = 1;
const color TRENDLINE_COLOR = clrYellow;
const color BAD_TRENDLINE_COLOR = clrMistyRose;

const int TRENDLINE_MIN_CANDLES_LENGTH = 10;
const int TRENDLINE_MIN_EXTREMES_DISTANCE = 3;
const int TRENDLINE_TOLERANCE_PIPS = 2;
const double TRENDLINE_NEGATIVE_SLOPE_VOLATILITY = 0.0038;
const double TRENDLINE_POSITIVE_SLOPE_VOLATILITY = 0.0024;
const double TRENDLINE_BALANCE_RATIO_THRESHOLD = 0.92;

Map<int, int> BREAKEVEN_STEPS;
Map<int, double> PERCENT_RISK_ACCOUNT_EXCEPTIONS;
Map<int, int> MORNING_LOOKBACK_CANDLES;
Map<string, int> RESTRICTED_SYMBOLS;

void InitializeMaps() {
    BREAKEVEN_STEPS.put(6, 4);
    BREAKEVEN_STEPS.put(25, 0);
    BREAKEVEN_STEPS.lock();

    PERCENT_RISK_ACCOUNT_EXCEPTIONS.put(2100183900, 1.5);
    PERCENT_RISK_ACCOUNT_EXCEPTIONS.lock();

    MORNING_LOOKBACK_CANDLES.put(PERIOD_M30, 2);
    MORNING_LOOKBACK_CANDLES.put(PERIOD_H1, 1);
    MORNING_LOOKBACK_CANDLES.put(PERIOD_H4, 1);
    MORNING_LOOKBACK_CANDLES.lock();

    RESTRICTED_SYMBOLS.put("EURJPY", PERIOD_H4);
    RESTRICTED_SYMBOLS.put("GBPJPY", PERIOD_H4);
    RESTRICTED_SYMBOLS.lock();
}
