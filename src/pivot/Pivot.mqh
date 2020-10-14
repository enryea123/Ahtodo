#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../Constants.mqh"

enum PivotPeriod{
    D1 = PERIOD_D1,
    W1 = PERIOD_W1,
    MN1 = PERIOD_MN1,
};

enum PivotRS{
    R1,
    R2,
    R3,
    S1,
    S2,
    S3,
};

class Pivot{
    public:
        Pivot();
        ~Pivot();

        double getPivot(string, PivotPeriod, int);
        double getPivotRS(string, PivotPeriod, PivotRS);
};

Pivot::Pivot(){}

Pivot::~Pivot(){}

double Pivot::getPivot(string orderSymbol, PivotPeriod pivotPeriod, int timeIndex){
    if(!IsAllowedSymbol(orderSymbol))
        return ThrowException(-1, "getPivot, unallowed symbol");
    if(timeIndex < 0)
        return ThrowException(-1, "getPivot, timeIndex < 0");

    double pivot = (iHigh(orderSymbol, pivotPeriod, timeIndex + 1)
       + iLow(orderSymbol, pivotPeriod, timeIndex + 1)
       + iClose(orderSymbol, pivotPeriod, timeIndex + 1)) / 3;

    return pivot;
}

double Pivot::getPivotRS(string orderSymbol, PivotPeriod pivotPeriod, PivotRS pivotRS){
    if(!IsAllowedSymbol(orderSymbol))
        return ThrowException(-1, "getPivotRS, unallowed symbol");

    const int timeIndex = 0;

    if(pivotRS == R1)
        return (2 * getPivot(orderSymbol, pivotPeriod, timeIndex)
            - iLow(orderSymbol, pivotPeriod, timeIndex + 1));

    if(pivotRS == R2)
        return (getPivot(orderSymbol, pivotPeriod, timeIndex)
            + iHigh(orderSymbol, pivotPeriod, timeIndex + 1)
            - iLow(orderSymbol, pivotPeriod, timeIndex + 1));

    if(pivotRS == R3)
        return (2 * getPivot(orderSymbol, pivotPeriod, timeIndex)
            + iHigh(orderSymbol, pivotPeriod, timeIndex + 1)
            - 2 * iLow(orderSymbol, pivotPeriod, timeIndex + 1));

    if(pivotRS == S1)
        return (2 * getPivot(orderSymbol, pivotPeriod, timeIndex)
            - iHigh(orderSymbol, pivotPeriod, timeIndex + 1));

    if(pivotRS == S2)
        return (getPivot(orderSymbol, pivotPeriod, timeIndex)
            - iHigh(orderSymbol, pivotPeriod, timeIndex + 1)
            + iLow(orderSymbol, pivotPeriod, timeIndex + 1));

    if(pivotRS == S3)
        return (2 * getPivot(orderSymbol, pivotPeriod, timeIndex)
            + iLow(orderSymbol, pivotPeriod, timeIndex + 1)
            - 2 * iHigh(orderSymbol, pivotPeriod, timeIndex + 1));

    return NULL;
}
