#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict


class Order {
    public:
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

        string toString();

        bool operator == (const Order &);
        bool operator != (const Order &);
};

string Order::toString() {
    return StringConcatenate("OrderInfo | ",
        "magicNumber: ", magicNumber, ", "
        "ticket: ", ticket, ", "
        "type: ", type, ", "
        "closePrice: ", closePrice, ", "
        "openPrice: ", openPrice, ", "
        "lots: ", lots, ", "
        "profit: ", profit, ", "
        "stopLoss: ", stopLoss, ", "
        "takeProfit: ", takeProfit, ", "
        "comment: ", comment, ", "
        "symbol: ", symbol, ", "
        "symbolFamily: ", symbolFamily, ", "
        "closeTime: ", closeTime
    );
}

bool Order::operator == (const Order & v) {
    return (
        this.magicNumber == v.magicNumber &&
        this.ticket == v.ticket &&
        this.type == v.type &&
        this.closePrice == v.closePrice &&
        this.openPrice == v.openPrice &&
        this.lots == v.lots &&
        this.profit == v.profit &&
        this.stopLoss == v.stopLoss &&
        this.takeProfit == v.takeProfit &&
        this.comment == v.comment &&
        this.symbol == v.symbol &&
        this.symbolFamily == v.symbolFamily &&
        this.closeTime == v.closeTime
    );
}

bool Order::operator != (const Order & v) {
    return !(this == v);
}
