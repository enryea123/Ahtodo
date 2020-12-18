#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "Holiday.mqh"
#include "MarketTime.mqh"


class Market {
    public:
        Market();
        ~Market();

        bool isMarketOpened(datetime);
        bool isMarketOpenLookBackTimeWindow();
        bool isMarketCloseNoPendingTimeWindow();
        void marketConditionsValidation();

    protected:
        static const int spreadPipsCloseMarket_;
        bool forceIsLiveAccountForTesting_;

        bool isAllowedAccountNumber(int);
        bool isAllowedExecutionDate(datetime);
        bool isAllowedPeriod(int);
        bool isAllowedBroker(string);
        bool isAllowedSymbol(string);
        bool isAllowedSymbolPeriodCombo(string, int);
        bool isDemoTrading(int);

    private:
        static const int incorrectClockErrorSeconds_;
        static const int openMarketLookBackMinutes_;

        static bool isHoliday_;
        static datetime spreadTimeStamp_;

        MarketTime marketTime_;
};

Market::Market():
    forceIsLiveAccountForTesting_(false) {
}

Market::~Market() {
    isHoliday_ = false;
    spreadTimeStamp_ = -1;
}

const int Market::spreadPipsCloseMarket_ = 5;

const int Market::incorrectClockErrorSeconds_ = 60;
const int Market::openMarketLookBackMinutes_ = 15;

bool Market::isHoliday_ = false;
datetime Market::spreadTimeStamp_ = -1;

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

    const double spread = GetMarketSpread();
    if (spread > spreadPipsCloseMarket_) {
        spreadTimeStamp_ = AlertTimer(spreadTimeStamp_, StringConcatenate("Market closed for spread: ", spread));
        return false;
    }

    return true;
}

bool Market::isMarketOpenLookBackTimeWindow() {
    return (TimeHour(marketTime_.timeItaly()) == marketTime_.marketOpenHour() &&
        TimeMinute(marketTime_.timeItaly()) < openMarketLookBackMinutes_);
}

bool Market::isMarketCloseNoPendingTimeWindow() {
    return (TimeHour(marketTime_.timeItaly()) >= marketTime_.marketCloseHourPending());
}

void Market::marketConditionsValidation() {
    if (isAllowedAccountNumber() && isAllowedExecutionDate() && isAllowedPeriod() &&
        isAllowedBroker() && isAllowedSymbol() && isAllowedSymbolPeriodCombo()) {

        // This doesn't catch an incorrect clock, only a different timezone
        if (MathAbs(marketTime_.timeItaly() - TimeLocal()) > incorrectClockErrorSeconds_) {
            ThrowException(__FUNCTION__, "The computer clock is not on the CET timezone, untested scenario");
        }

        return;
    }

    if (IsConnected()) {
        ThrowFatalException(__FUNCTION__, "Market conditions validation failed");
    }
}

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

    for (int i = 0; i < ArraySize(RESTRICTED_SYMBOL_FAMILIES_H4); i++) {
        if (StringContains(symbol, RESTRICTED_SYMBOL_FAMILIES_H4[i]) && period != PERIOD_H4) {
            return ThrowException(false, __FUNCTION__, StringConcatenate("Unauthorized symbol ",
                symbol, " and period ", period, " combination"));
        }
    }

    return true;
}

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
