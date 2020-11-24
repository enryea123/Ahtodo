#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "MarketTime.mqh"


class Market {
    public:
        Market();

        void startUpMarketValidation();
// classe molto lunga. va splittata? decidi dopo che sarà finita, mancano varie funzioni
// alcune protected?, probabilmente posso mettere il default degli argomenti con parametri private
        bool isAllowedAccountNumber(int);
        bool isAllowedExecutionDate(datetime);
        bool isAllowedPeriod(int);
        bool isAllowedSymbol(string);
        bool isAllowedSymbolPeriodCombo(string, int);

        bool isDemoTrading(int);
        void forceIsLiveAccount();
        void resetAccountTypeOverride();

    private:
        bool forceIsLiveAccount_;
};

Market::Market():
    forceIsLiveAccount_(false) {
}

void Market::startUpMarketValidation() { // controllo ad ogni tick. variabile startUpTime_?
    MarketTime marketTime_;

    if (isAllowedAccountNumber(AccountNumber()) &&
        isAllowedExecutionDate(marketTime_.timeItaly()) &&
        isAllowedPeriod(Period()) && // argomenti non tutti necessari, fare revisione completa di dove servono e dove si puo fare l'overloaded protected ecc
        isAllowedSymbol(Symbol()) &&
        isAllowedSymbolPeriodCombo(Symbol(), Period())) {
        return;
    }

    ThrowFatalException("startUpMarketValidation failed");
}

bool Market::isAllowedAccountNumber(int accountNumber) {
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

    return ThrowException(false, StringConcatenate("isAllowedAccountNumber, ",
        "unauthorized accountNumber: ", accountNumber));
}

bool Market::isAllowedExecutionDate(datetime executionDate) {
    if (executionDate < BOT_EXPIRATION_DATE) {
        return true;
    }

    return ThrowException(false, StringConcatenate("isAllowedExecutionDate, "
        "unauthorized executionDate: ", executionDate));
}

bool Market::isAllowedPeriod(int period) {
    for (int i = 0; i < ArraySize(ALLOWED_PERIODS); i++) {
        if (period == ALLOWED_PERIODS[i]) {
            return true;
        }
    }

    return ThrowException(false, StringConcatenate("isAllowedPeriod, unauthorized period: ", period));
}

bool Market::isAllowedSymbol(string symbol) {
    if (isDemoTrading() && SymbolExists(symbol)) {
        return true;
    }

    for (int i = 0; i < ArraySize(ALLOWED_SYMBOLS); i++) {
        if (symbol == ALLOWED_SYMBOLS[i]) {
            return true;
        }
    }

    return ThrowException(false, StringConcatenate("isAllowedSymbol, unauthorized symbol: ", symbol));
}

bool Market::isAllowedSymbolPeriodCombo(string symbol, int period) {
    if (isDemoTrading()) {
        return true;
    }

    for (int i = 0; i < ArraySize(RESTRICTED_SYMBOL_FAMILIES_H4); i++) {
        if (StringContains(symbol, RESTRICTED_SYMBOL_FAMILIES_H4[i]) && period != PERIOD_H4) {
            return ThrowException(false, StringConcatenate("isAllowedSymbolPeriodCombo, unauthorized symbol ",
                symbol, " and period ", period, " combination"));
        }
    }

    return true;
}

bool Market::isDemoTrading(int accountNumber = NULL) {
    if (!accountNumber) {
        accountNumber = AccountNumber();
    }

    if (forceIsLiveAccount_) {
        return false;
    }

    for (int i = 0; i < ArraySize(ALLOWED_DEMO_ACCOUNT_NUMBERS); i++) {
        if (accountNumber == ALLOWED_DEMO_ACCOUNT_NUMBERS[i]) {
            return true;
        }
    }

    return false;
}

void Market::forceIsLiveAccount() {
    forceIsLiveAccount_ = true;
}

void Market::resetAccountTypeOverride() {
    forceIsLiveAccount_ = false;
}


/**

// Print("isDemoTrading() && SymbolExists(symbol): ", isDemoTrading(), " && ", SymbolExists(symbol));


void Market::tickMarketValidation() { // ci sono vari livelli di questo, ma non deve fare fatal exception probabilmente
    if (???) {
        return;
    }

// isAllowedExecutionDate serve

    ThrowFatalException("startUpMarketValidation failed");
}

// nuova funzione isMarketOpened, e poi isMarketOpenedFirstBar (che cancola direttamente se si possono fare ordini a -6)

// sicuramente nuova classe markettime (magari poi ereditata da questa? o magari no perche frutta -/-> fragola).

// magari usare timelocal per apertura mercato, che non dipende dalla timezone. Ah pero pericoloso in caso di cambi del computer.
// meglio timecurrent allora (no perche è l'orario di metatrader, non del broker). o timelocal in altra timezone
    if (DayOfWeek() >= MARKET_CLOSE_DAY || DayOfWeek() < MARKET_OPEN_DAY) {
        SetChartMarketClosedColors();
    }

bool Market::isMarketOpened(day, hour, minute?) {
    if (year < 2022) {
        return true;
    }
}

*/
