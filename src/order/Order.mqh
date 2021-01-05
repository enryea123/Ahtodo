#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../util/Util.mqh"


/**
 * This class is an interface for orders. It provides basic attributes
 * and a few methods that allow to get extra information on the order.
 */
class Order {
    public:
        Order();

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
        datetime closeTime;
        datetime expiration;

        bool operator == (const Order &);
        bool operator != (const Order &);

        int getPeriod();
        double getStopLossPips();
        string toString();

        bool isOpen();
        bool isBuy();
        Discriminator getDiscriminator();
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
        closeTime == v.closeTime &&
        expiration == v.expiration
    );
}

bool Order::operator != (const Order & v) {
    return !(this == v);
}

/**
 * Calculates the period of an order, starting from the magicNumber.
 * It assumes the magicNumber is set of the form: BASE + Period.
 */
int Order::getPeriod() {
    if (magicNumber == -1) {
        return ThrowException(-1, __FUNCTION__, "Order magicNumber not initialized");
    }

    for (int i = 0; i < ArraySize(ALLOWED_MAGIC_NUMBERS); i++) {
        if (magicNumber == ALLOWED_MAGIC_NUMBERS[i]) {
            return (magicNumber - BASE_MAGIC_NUMBER);
        }
    }

    return ThrowException(-1, __FUNCTION__, "Could not get period for unknown magicNumber");
}

/**
 * Calculates the number of pips of an order stopLoss.
 */
double Order::getStopLossPips() {
    if (openPrice == -1 || stopLoss == -1 || symbol == NULL) {
        return ThrowException(-1, __FUNCTION__, "Some order quantities not initialized");
    }

    return MathAbs(openPrice - stopLoss) / Pip(symbol);
}

/**
 * Returns all the order information as string, so that it can be printed.
 */
string Order::toString() {
    return StringConcatenate("OrderInfo", MESSAGE_SEPARATOR,
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
        "closeTime: ", closeTime, ", "
        "expiration: ", expiration
    );
}

/**
 * Checks the order type to determine whether it's opened.
 */
bool Order::isOpen() {
    if (type == -1) {
        return ThrowException(false, __FUNCTION__, "Order type not initialized");
    }

    return (type == OP_BUY || type == OP_SELL) ? true : false;
}

/**
 * Checks the order type to determine whether it's of buy type.
 */
bool Order::isBuy() {
    if (type == -1) {
        return ThrowException(false, __FUNCTION__, "Order type not initialized");
    }

    return (getDiscriminator() == Max) ? true : false;
}

/**
 * Calculates the discriminator of an order from its type.
 */
Discriminator Order::getDiscriminator() {
    if (type == -1) {
        return ThrowException(Min, __FUNCTION__, "Order type not initialized");
    }

    return (type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT) ? Max : Min;
}
