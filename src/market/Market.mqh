#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../util/Exception.mqh"
#include "../util/Util.mqh"
#include "Holiday.mqh"
#include "MarketTime.mqh"


/**
 * This class allows to run validations on the market conditions, to determine the openness status,
 * and to run other checks to decide whether the bot should be removed.
 */
class Market {
    public:
        Market();
        ~Market();

        bool isMarketOpened(datetime);
        bool isMarketOpenLookBackTimeWindow();
        bool isMarketCloseNoPendingTimeWindow();
        void marketConditionsValidation();

    protected:
        bool isAllowedAccountNumber(int);
        bool isAllowedExecutionDate(datetime);
        bool isAllowedPeriod(int);
        bool isAllowedBroker(string);
        bool isAllowedSymbol(string);
        bool isAllowedSymbolPeriodCombo(string, int);
        bool isDemoTrading(int);

        void accountTypeOverride();
        void accountTypeOverrideReset();

    private:
        static const int incorrectClockErrorSeconds_;

        static bool isHoliday_;
        static datetime spreadTimeStamp_;
        static datetime wrongClockTimeStamp_;

        MarketTime marketTime_;

        bool forceIsLiveAccountForTesting_;
};

Market::Market():
    forceIsLiveAccountForTesting_(false) {
}

Market::~Market() {
    isHoliday_ = false;
    spreadTimeStamp_ = -1;
    wrongClockTimeStamp_ = -1;
}

const int Market::incorrectClockErrorSeconds_ = 60;

bool Market::isHoliday_ = false;
datetime Market::spreadTimeStamp_ = -1;
datetime Market::wrongClockTimeStamp_ = -1;

/**
 * Checks if the market is opened in the default timezone.
 * It also closes the market in case the spread is too high.
 */
bool Market::isMarketOpened(datetime date = NULL) {
    if (date == NULL) {
        date = marketTime_.timeItaly();
    }

    const int hour = TimeHour(date);
    const int dayOfWeek = TimeDayOfWeek(date);

    if (hour < marketTime_.marketOpenHour() || hour >= marketTime_.marketCloseHour() ||
        dayOfWeek < marketTime_.marketOpenDay() || dayOfWeek >= marketTime_.marketCloseDay()) {
        return false;
    }

    if (marketTime_.hasDateChanged(date)) {
        Holiday holiday;
        isHoliday_ = holiday.isMajorBankHoliday(date);
    }
    if (isHoliday_) {
        return false;
    }

    const double spread = GetSpread();
    if (spread > SPREAD_PIPS_CLOSE_MARKET) {
        spreadTimeStamp_ = AlertTimer(spreadTimeStamp_, StringConcatenate("Market closed for spread: ", spread));
        return false;
    }

    return true;
}

/**
 * Checks if the market has been just recently opened, and it's hence possible
 * to try to put pending orders on older candles.
 */
bool Market::isMarketOpenLookBackTimeWindow() {
    return (TimeHour(marketTime_.timeItaly()) == marketTime_.marketOpenHour() &&
        TimeMinute(marketTime_.timeItaly()) < OPEN_MARKET_LOOKBACK_MINUTES);
}

/**
 * Checks if it's the time window when the market is not closed yet, but no more pending orders are allowed.
 */
bool Market::isMarketCloseNoPendingTimeWindow() {
    return (TimeHour(marketTime_.timeItaly()) >= marketTime_.marketCloseHourPending());
}

/**
 * Checks all the market conditions such as AccountNumber, Date, Period,
 * and if there is internet connection it removes the bot.
 */
void Market::marketConditionsValidation() {
    if (isAllowedAccountNumber() && isAllowedExecutionDate() && isAllowedPeriod() &&
        isAllowedBroker() && isAllowedSymbol() && isAllowedSymbolPeriodCombo()) {

        // This doesn't catch an incorrect clock, only a different timezone
        if (MathAbs(marketTime_.timeItaly() - TimeLocal()) > incorrectClockErrorSeconds_) {
            wrongClockTimeStamp_ = AlertTimer(wrongClockTimeStamp_,
                "The computer clock is not on the CET timezone, untested scenario");
        }

        return;
    }

    if (IsConnected()) {
        ThrowFatalException(__FUNCTION__, "Market conditions validation failed");
    }
}

/**
 * Check if the current account number is allowed to run the bot.
 */
bool Market::isAllowedAccountNumber(int accountNumber = NULL) {
    if (!accountNumber) {
        accountNumber = AccountNumber();
    }

    for (int i = 0; i < ArraySize(ALLOWED_DEMO_ACCOUNT_NUMBERS); i++) {
        if (accountNumber == ALLOWED_DEMO_ACCOUNT_NUMBERS[i]) {
            return true;
        }
    }

    for (int j = 0; j < ArraySize(ALLOWED_LIVE_ACCOUNT_NUMBERS); j++) {
        if (accountNumber == ALLOWED_LIVE_ACCOUNT_NUMBERS[j]) {
            return true;
        }
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized accountNumber: ", accountNumber));
}

/**
 * Check if the bot has expired and it's no more allowed to run.
 */
bool Market::isAllowedExecutionDate(datetime date = NULL) {
    if (!date) {
        date = TimeGMT();
    }

    if (date > BOT_TESTS_EXPIRATION_DATE) {
        ThrowException(__FUNCTION__, StringConcatenate("Date dependent tests have expired on: ",
            BOT_TESTS_EXPIRATION_DATE));
    }

    if (date < BOT_EXPIRATION_DATE) {
        return true;
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized execution date: ", date));
}

/**
 * Check if the current period is supported to run the bot.
 */
bool Market::isAllowedPeriod(int period = NULL) {
    if (!period) {
        period = Period();
    }

    for (int i = 0; i < ArraySize(ALLOWED_PERIODS); i++) {
        if (period == ALLOWED_PERIODS[i]) {
            return true;
        }
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized period: ", period));
}

/**
 * Check if the current symbol is supported to run the bot.
 */
bool Market::isAllowedSymbol(string symbol = "") {
    if (symbol == "") {
        symbol = Symbol();
    }

    if (isDemoTrading() && SymbolExists(symbol)) {
        return true;
    }

    for (int i = 0; i < ArraySize(ALLOWED_SYMBOLS); i++) {
        if (symbol == ALLOWED_SYMBOLS[i]) {
            return true;
        }
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized symbol: ", symbol));
}

/**
 * Check if the current broker is supported to run the bot. This is because
 * different brokers with different digits and options haven't been tested yet.
 */
bool Market::isAllowedBroker(string broker = "") {
    if (broker == "") {
        broker = AccountCompany();
    }

    if (isDemoTrading()) {
        return true;
    }

    for (int i = 0; i < ArraySize(ALLOWED_BROKERS); i++) {
        if (broker == ALLOWED_BROKERS[i]) {
            return true;
        }
    }

    return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized broker: ", broker));
}

/**
 * Check if the current period/symbol combo is supported to run the bot.
 */
bool Market::isAllowedSymbolPeriodCombo(string symbol = "", int period = NULL) {
    if (symbol == "") {
        symbol = Symbol();
    }
    if (!period) {
        period = Period();
    }

    if (isDemoTrading()) {
        return true;
    }

    for (int i = 0; i < RESTRICTED_SYMBOLS.size(); i++) {
        if (RESTRICTED_SYMBOLS.getKeys(i) == symbol && RESTRICTED_SYMBOLS.getValues(i) != period) {
            return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized symbol ",
                symbol, " and period ", period, " combination"));
        }
    }

    return true;
}

/**
 * Check if the current account is demo or live. It allows to override the real value for unit tests.
 */
bool Market::isDemoTrading(int accountNumber = NULL) {
    if (!accountNumber) {
        accountNumber = AccountNumber();
    }

    if (forceIsLiveAccountForTesting_) {
        return false;
    }

    for (int i = 0; i < ArraySize(ALLOWED_DEMO_ACCOUNT_NUMBERS); i++) {
        if (accountNumber == ALLOWED_DEMO_ACCOUNT_NUMBERS[i]) {
            return true;
        }
    }

    return false;
}

/**
 * Positively overrides the account type to live for unit tests.
 */
void Market::accountTypeOverride() {
    forceIsLiveAccountForTesting_ = true;
}

/**
 * Resets the account type override for unit tests.
 */
void Market::accountTypeOverrideReset() {
    forceIsLiveAccountForTesting_ = false;
}
