#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"


class Order {
    public:
        int magicNumber;
        int ticket;
        int type;
        double openPrice;
        double profit;
        string commment;
        string symbol;
        datetime closeTime;
};

#define SETTER(T, V, V_) public: void V(T V) {V_ = (V_ == NULL) ? V : StringConcatenate(V_, "|", V);}
#define SETTER_OL2(T, V) public: void V(T V1, T V2) {V(V1); V(V2);}
#define SETTER_OL3(T, V) public: void V(T V1, T V2, T V3) {V(V1); V(V2); V(V3);}
#define SETTER_OL4(T, V) public: void V(T V1, T V2, T V3, T V4) {V(V1); V(V2); V(V3); V(V4);}
#define SETTER_OL5(T, V) public: void V(T V1, T V2, T V3, T V4, T V5) {V(V1); V(V2); V(V3); V(V4); V(V5);}
#define SETTER_OVERLOADS(T, V) SETTER_OL2(T, V) SETTER_OL3(T, V) SETTER_OL4(T, V) SETTER_OL5(T, V)

#define GETTER(N, T, V, V_) public: bool N(T V) {return (V_ == NULL || StringContains(V_, V)) ? false : true;}
#define FILTER(N, T, V, V_) SETTER(T, V, V_) SETTER_OVERLOADS(T, V) GETTER(N, T, V, V_) private: string V_;

class OrderFilter {
    FILTER(byMagicNumber, int, magicNumber, magicNumber_);
    FILTER(byTicket, int, ticket, ticket_);
    FILTER(byType, int, type, type_);
    FILTER(byOpenPrice, double, openPrice, openPrice_);
    FILTER(byProfit, double, profit, profit_);
    FILTER(byCommment, string, commment, commment_);
    FILTER(bySymbol, string, symbol, symbol_);
    FILTER(byCloseTime, datetime, closeTime, closeTime_);
};

#undef SETTER
#undef SETTER_OL2
#undef SETTER_OL3
#undef SETTER_OL4
#undef SETTER_OL5
#undef SETTER_OVERLOADS
#undef GETTER
#undef FILTER
