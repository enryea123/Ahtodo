#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "../market/Market.mqh"

enum PivotPeriod {
    D1 = PERIOD_D1,
    W1 = PERIOD_W1,
    MN1 = PERIOD_MN1,
};

enum PivotRS {
    R1,
    R2,
    R3,
    S1,
    S2,
    S3,
};


class Pivot {
    public:
        double getPivot(string, PivotPeriod, int);
        double getPivotRS(string, PivotPeriod, PivotRS);

    private:
        Market market_;
};

double Pivot::getPivot(string symbol, PivotPeriod pivotPeriod, int timeIndex) {
    if (!market_.isAllowedSymbol(symbol)) {
        return ThrowException(-1, __FUNCTION__, "getPivot, unauthorized symbol");
    }
    if (timeIndex < 0) {
        return ThrowException(-1, __FUNCTION__, "getPivot, timeIndex < 0");
    }

    const double pivot = (iCandle(I_high, symbol, pivotPeriod, timeIndex + 1)
       + iCandle(I_low, symbol, pivotPeriod, timeIndex + 1)
       + iCandle(I_close, symbol, pivotPeriod, timeIndex + 1)) / 3;

    if (pivot == 0) {
        return ThrowException(0, __FUNCTION__, "getPivot == 0");
    }

    return pivot;
}

double Pivot::getPivotRS(string symbol, PivotPeriod pivotPeriod, PivotRS pivotRS) {
    if (!market_.isAllowedSymbol(symbol)) {
        return ThrowException(-1, __FUNCTION__, "getPivotRS, unauthorized symbol");
    }

    const int timeIndex = 0;

    if (pivotRS == R1) {
        return (2 * getPivot(symbol, pivotPeriod, timeIndex)
            - iCandle(I_low, symbol, pivotPeriod, timeIndex + 1));
    }

    if (pivotRS == R2) {
        return (getPivot(symbol, pivotPeriod, timeIndex)
            + iCandle(I_high, symbol, pivotPeriod, timeIndex + 1)
            - iCandle(I_low, symbol, pivotPeriod, timeIndex + 1));
    }

    if (pivotRS == R3) {
        return (2 * getPivot(symbol, pivotPeriod, timeIndex)
            + iCandle(I_high, symbol, pivotPeriod, timeIndex + 1)
            - 2 * iCandle(I_low, symbol, pivotPeriod, timeIndex + 1));
    }

    if (pivotRS == S1) {
        return (2 * getPivot(symbol, pivotPeriod, timeIndex)
            - iCandle(I_high, symbol, pivotPeriod, timeIndex + 1));
    }

    if (pivotRS == S2) {
        return (getPivot(symbol, pivotPeriod, timeIndex)
            - iCandle(I_high, symbol, pivotPeriod, timeIndex + 1)
            + iCandle(I_low, symbol, pivotPeriod, timeIndex + 1));
    }

    if (pivotRS == S3) {
        return (2 * getPivot(symbol, pivotPeriod, timeIndex)
            + iCandle(I_low, symbol, pivotPeriod, timeIndex + 1)
            - 2 * iCandle(I_high, symbol, pivotPeriod, timeIndex + 1));
    }

    return ThrowException(-1, __FUNCTION__, "getPivotRS: could not get value");
}
