#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../Constants.mqh"


class Candles{
    public:
        Candles();
        ~Candles();

        bool doji(int);
        bool slimDoji(int);
        bool downPinbar(int);
        bool upPinbar(int);
        bool bigBar(int);

    protected:
        bool isCandleBull(int);
        bool isCandleSizeGood(int);
        bool isSupportCandle(int);

        double candleBody(int);
        double candleSize(int);
        double candleUpShadow(int);
        double candleDownShadow(int);
        double candleBodyMidPoint(int);
        double candleBodyMin(int);
        double candleBodyMax(int);
};

Candles::Candles(){}

Candles::~Candles(){}

bool Candles::doji(int timeIndex){
    if(candleBody(timeIndex) < 3 * ErrorPips()
    && candleUpShadow(timeIndex) < candleDownShadow(timeIndex) * 9 / 4
    && candleDownShadow(timeIndex) < candleUpShadow(timeIndex) * 9 / 4
    && candleDownShadow(timeIndex) + candleUpShadow(timeIndex) > candleBody(timeIndex) / 4){
        return true;
    }
    return false;
}

bool Candles::slimDoji(int timeIndex){
    if(doji(timeIndex) && candleBody(timeIndex) < 2 * ErrorPips())
        return true;
    return false;
}


bool Candles::downPinbar(int timeIndex){
    if(candleDownShadow(timeIndex) > candleBody(timeIndex) * 4 / 3
    && candleUpShadow(timeIndex) < candleDownShadow(timeIndex) * 3 / 4
    && candleDownShadow(timeIndex) > (candleBody(timeIndex) + candleUpShadow(timeIndex)) * 3 / 4){
        return true;
    }
    return false;
}

bool Candles::upPinbar(int timeIndex){
    if(candleUpShadow(timeIndex) > candleBody(timeIndex) * 4 / 3
    && candleDownShadow(timeIndex) < candleUpShadow(timeIndex) * 3 / 4
    && candleUpShadow(timeIndex) > (candleBody(timeIndex) + candleDownShadow(timeIndex)) * 3 / 4){
        return true;
    }
    return false;
}

bool Candles::bigBar(int timeIndex){
    if(candleBody(timeIndex) > 3 * ErrorPips()
    && candleDownShadow(timeIndex) < candleBody(timeIndex) * 3 / 4
    && candleUpShadow(timeIndex) < candleBody(timeIndex) * 3 / 4
    && candleDownShadow(timeIndex) + candleUpShadow(timeIndex) < candleBody(timeIndex) * 3 / 2){
        return true;
    }
    return false;
}

bool Candles::isCandleBull(int timeIndex){
    if(iClose(NULL, Period(), timeIndex) > iOpen(NULL, Period(), timeIndex))
        return true;

    return false;
}

bool Candles::isSupportCandle(int timeIndex){
    if(doji(timeIndex) || upPinbar(timeIndex) || downPinbar(timeIndex))
        return true;
    return false;
}

double Candles::candleBody(int timeIndex){
    return MathAbs(iOpen(NULL, Period(), timeIndex) - iClose(NULL, Period(), timeIndex));
}

double Candles::candleSize(int timeIndex){
    return MathAbs(iHigh(NULL, Period(), timeIndex) - iLow(NULL, Period(), timeIndex));
}

double Candles::candleUpShadow(int timeIndex){
    return MathAbs(iHigh(NULL, Period(), timeIndex) - MathMax(iOpen(NULL, Period(), timeIndex),
        iClose(NULL, Period(), timeIndex)));
}

double Candles::candleDownShadow(int timeIndex){
    return MathAbs(iLow(NULL, Period(), timeIndex) - MathMin(iOpen(NULL, Period(), timeIndex),
        iClose(NULL, Period(), timeIndex)));
}

double Candles::candleBodyMidPoint(int timeIndex){
    return MathAbs(iOpen(NULL, Period(), timeIndex) + iClose(NULL, Period(), timeIndex)) / 2;
}

double Candles::candleBodyMin(int timeIndex){
    return MathMin(iOpen(NULL, Period(), timeIndex), iClose(NULL, Period(), timeIndex));
}

double Candles::candleBodyMax(int timeIndex){
    return MathMax(iOpen(NULL, Period(), timeIndex), iClose(NULL, Period(), timeIndex));
}
