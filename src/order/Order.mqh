#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"


class Order {
    public:
        Order::Order();

        int magicNumber;
        int ticket;
        int type;
        double closePrice;
        double openPrice;
        double lots;
        double profit;
        double stopLoss;
        double takeProfit;
        string comment;
        string symbol;
        string symbolFamily;
        datetime closeTime;
        datetime expiration;

        bool operator == (const Order &);
        bool operator != (const Order &);

        int getPeriod();
        int getStopLossPips();
        string toString();
};

Order::Order():
    magicNumber(-1),
    ticket(-1),
    type(-1),
    closePrice(-1),
    openPrice(-1),
    lots(-1),
    profit(-1),
    stopLoss(-1),
    takeProfit(-1),
    comment(NULL),
    symbol(NULL),
    symbolFamily(NULL),
    closeTime(NULL),
    expiration(NULL) {
}

bool Order::operator == (const Order & v) {
    return (
        magicNumber == v.magicNumber &&
        ticket == v.ticket &&
        type == v.type &&
        closePrice == v.closePrice &&
        openPrice == v.openPrice &&
        lots == v.lots &&
        profit == v.profit &&
        stopLoss == v.stopLoss &&
        takeProfit == v.takeProfit &&
        comment == v.comment &&
        symbol == v.symbol &&
        symbolFamily == v.symbolFamily &&
        closeTime == v.closeTime &&
        expiration == v.expiration
    );
}

bool Order::operator != (const Order & v) {
    return !(this == v);
}

int Order::getPeriod() {
    if (magicNumber == -1) {
        return ThrowException(-1, __FUNCTION__, "MagicNumber not initialized");
    }

    return (magicNumber - BOT_MAGIC_NUMBER);
}

int Order::getStopLossPips() {
    if (openPrice == -1 || stopLoss == -1 || symbol == NULL) {
        return ThrowException(-1, __FUNCTION__, "Some quantities not initialized");
    }

    return (int) MathRound(MathAbs(openPrice - stopLoss) / Pips(symbol));
}

string Order::toString() {
    return StringConcatenate("OrderInfo | ",
        "magicNumber: ", magicNumber, ", "
        "ticket: ", ticket, ", "
        "type: ", type, ", "
        "closePrice: ", NormalizeDouble(closePrice, Digits), ", "
        "openPrice: ", NormalizeDouble(openPrice, Digits), ", "
        "lots: ", NormalizeDouble(lots, 2), ", "
        "profit: ", NormalizeDouble(profit, Digits), ", "
        "stopLoss: ", NormalizeDouble(stopLoss, Digits), ", "
        "takeProfit: ", NormalizeDouble(takeProfit, Digits), ", "
        "comment: ", comment, ", "
        "symbol: ", symbol, ", "
        "symbolFamily: ", symbolFamily, ", "
        "closeTime: ", closeTime, ", "
        "expiration: ", expiration
    );
}
