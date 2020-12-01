#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"


class Order {
    public:
        int magicNumber;
        int ticket;
        int type;
        double closePrice;
        double openPrice;
        double lots;
        double profit;
        string commment;
        string symbol;
        datetime closeTime;
};

#define SET(T, V, V_) void V(T V) {V_ = (V_ == NULL) ? V : StringConcatenate(V_, "|", V);}
#define SET_OL2(T, V) void V(T V1, T V2) {V(V1); V(V2);}
#define SET_OL3(T, V) void V(T V1, T V2, T V3) {V(V1); V(V2); V(V3);}
#define SET_OL4(T, V) void V(T V1, T V2, T V3, T V4) {V(V1); V(V2); V(V3); V(V4);}
#define SET_OL5(T, V) void V(T V1, T V2, T V3, T V4, T V5) {V(V1); V(V2); V(V3); V(V4); V(V5);}
#define SET_OVERLOADS(T, V) SET_OL2(T, V) SET_OL3(T, V) SET_OL4(T, V) SET_OL5(T, V)
#define GET(N, T, V, V_) T V() {return V_;} bool N(T V) {return (V_ == NULL || StringContains(V_, V)) ? false : true;}
#define FILTER(N, T, V, V_) private: string V_; public: SET(T, V, V_) SET_OVERLOADS(T, V) GET(N, T, V, V_)

class OrderFilter {
    FILTER(byMagicNumber, int, magicNumber, magicNumber_);
    FILTER(byTicket, int, ticket, ticket_);
    FILTER(byType, int, type, type_);
    FILTER(byOpenPrice, double, openPrice, openPrice_);
    FILTER(byProfit, double, profit, profit_);
    FILTER(byCommment, string, commment, commment_);
    FILTER(bySymbol, string, symbol, symbol_);
    FILTER(bySymbolFamily, string, symbolFamily, symbolFamily_);
    FILTER(byCloseTime, datetime, closeTime, closeTime_);
};

#undef SET
#undef SET_OL2
#undef SET_OL3
#undef SET_OL4
#undef SET_OL5
#undef SET_OVERLOADS
#undef GET
#undef FILTER
