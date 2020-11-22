#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"

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


class Market {
    public:
        Market();
        ~Market();

// variabili sopra da spostare nel file comune? Vedro dopo
// classe molto lunga. va splittata? decidi dopo che sarà finita, mancano varie funzioni
// alcune protected?, probabilmente posso mettere il default degli argomenti con parametri private
        bool isAllowedAccountNumber(int);
        bool isAllowedExecutionDate(datetime);
        bool isAllowedPeriod(int);
        bool isAllowedSymbol(string);
        bool isAllowedSymbolPeriodCombo(string, int);

        bool isDemoTrading();
        bool isDemoTrading(int);
        void forceIsLiveAccount();
        void resetAccountTypeOverride();

        void startUpMarketValidation();

    private:
        const int accountNumber_;
        bool forceIsLiveAccount_;
};

Market::Market():
    forceIsLiveAccount_(false),
    accountNumber_(AccountNumber()) {
}

Market::~Market() {}

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

bool Market::isDemoTrading() {
    return isDemoTrading(accountNumber_);
}

bool Market::isDemoTrading(int accountNumber) {
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

void Market::startUpMarketValidation() { // controllo ad ogni tick. variabile startUpTime_?
    if (isAllowedAccountNumber(accountNumber_) &&
        isAllowedExecutionDate(TimeCurrent()) &&
        isAllowedPeriod(CURRENT_PERIOD) &&
        isAllowedSymbol(CURRENT_SYMBOL) &&
        isAllowedSymbolPeriodCombo(CURRENT_SYMBOL, CURRENT_PERIOD)) {
        return;
    }

    ThrowFatalException("startUpMarketValidation failed");
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
