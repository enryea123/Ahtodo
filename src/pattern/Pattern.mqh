#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "Candle.mqh"


class Pattern: public Candle{
    public:
        Pattern();
        ~Pattern();

        bool isBuyPattern(int);
        bool isSellPattern(int);
        bool isAntiPattern(int);

        bool buyPattern1(int);
        bool buyPattern2(int);
        bool buyPattern3(int);
        bool sellPattern1(int);
        bool sellPattern2(int);
        bool sellPattern3(int);
        bool sellBuyPattern4(int);
        bool antiPattern1(int);

        bool isPatternSizeGood(int);

    private:
        const int antiPatternMinSizeSumPips_;
};

Pattern::Pattern():
    antiPatternMinSizeSumPips_(50){
}

Pattern::~Pattern(){}

bool Pattern::sellPattern1(int timeIndex){
    // Low doji followed by big bull bar

    if(!bigBar(timeIndex))
        return false;

    if(!isCandleBull(timeIndex))
        return false;

    if(!isSupportCandle(timeIndex + 1))
        return false;

    if(candleBody(timeIndex + 1) > candleBody(timeIndex) / 2)
        return false;

    if(candleSize(timeIndex + 1) > candleSize(timeIndex))
        return false;

    if(candleBodyMidPoint(timeIndex + 1) < candleBodyMin(timeIndex) - candleBody(timeIndex) / 2)
        return false;

    if(candleBodyMidPoint(timeIndex + 1) > candleBodyMin(timeIndex) + candleBody(timeIndex) / 2)
        return false;

    if(MathAbs(iExtreme(timeIndex + 1, Min) - iExtreme(timeIndex, Min)) > 3 * ErrorPips())
        return false;

    return true;
}


bool Pattern::buyPattern1(int timeIndex){
    // High doji followed by big bear bar

    if(!bigBar(timeIndex))
        return false;

    if(isCandleBull(timeIndex))
        return false;

    if(!isSupportCandle(timeIndex + 1))
        return false;

    if(candleBody(timeIndex + 1) > candleBody(timeIndex) / 2)
        return false;

    if(candleSize(timeIndex + 1) > candleSize(timeIndex))
        return false;

    if(candleBodyMidPoint(timeIndex + 1) > candleBodyMax(timeIndex) + candleBody(timeIndex) / 2)
        return false;

    if(candleBodyMidPoint(timeIndex + 1) < candleBodyMax(timeIndex) - candleBody(timeIndex) / 2)
        return false;

    if(MathAbs(iExtreme(timeIndex + 1, Max) - iExtreme(timeIndex, Max)) > 3 * ErrorPips())
        return false;

    return true;
}

bool Pattern::sellPattern2(int timeIndex){
    // Down pinbar

    if(!downPinbar(timeIndex))
        return false;

    return true;
}

bool Pattern::buyPattern2(int timeIndex){
    // Up pinbar

    if(!upPinbar(timeIndex))
        return false;

    return true;
}

bool Pattern::sellPattern3(int timeIndex){
    // High doji followed by big bear bar and then big bull bar

    if(!bigBar(timeIndex + 1))
        return false;

    if(!bigBar(timeIndex))
        return false;

    if(isCandleBull(timeIndex + 1))
        return false;

    if(!isCandleBull(timeIndex))
        return false;

    if(!isSupportCandle(timeIndex + 2))
        return false;

    if(candleBody(timeIndex + 2) > candleBody(timeIndex + 1) / 2)
        return false;

    if(candleBody(timeIndex + 1) > candleBody(timeIndex) * 7 / 4)
        return false;

    if(candleBodyMidPoint(timeIndex + 2) > candleBodyMax(timeIndex + 1)
    + candleBody(timeIndex + 1) / 2)
        return false;

    if(candleBodyMidPoint(timeIndex + 2) < candleBodyMax(timeIndex + 1)
    - candleBody(timeIndex + 1) / 2)
        return false;

    if(candleSize(timeIndex + 2) > candleSize(timeIndex + 1))
        return false;

    if(candleSize(timeIndex + 1) < candleSize(timeIndex) * 3 / 4)
        return false;

    if(candleBody(timeIndex + 1) < candleBody(timeIndex) * 3 / 4)
        return false;

    if(iExtreme(timeIndex + 1, Max) < candleBodyMax(timeIndex) - ErrorPips())
        return false;

    if(iExtreme(timeIndex + 1, Min) > candleBodyMin(timeIndex) + ErrorPips())
        return false;

    if(MathAbs(iExtreme(timeIndex + 1, Min) - iExtreme(timeIndex, Min)) > 3 * ErrorPips())
        return false;

    return true;
}

bool Pattern::buyPattern3(int timeIndex){
    // Low doji followed by big bull bar and then big bear bar

    if(!bigBar(timeIndex + 1))
        return false;

    if(!bigBar(timeIndex))
        return false;

    if(!isCandleBull(timeIndex + 1))
        return false;

    if(isCandleBull(timeIndex))
        return false;

    if(!isSupportCandle(timeIndex + 2))
        return false;

    if(candleBody(timeIndex + 2) > candleBody(timeIndex + 1) / 2)
        return false;

    if(candleBody(timeIndex + 1) > candleBody(timeIndex) * 7 / 4)
        return false;

    if(candleBodyMidPoint(timeIndex + 2) < candleBodyMin(timeIndex + 1)
    - candleBody(timeIndex + 1) / 2)
        return false;

    if(candleBodyMidPoint(timeIndex + 2) > candleBodyMin(timeIndex + 1)
    + candleBody(timeIndex + 1) / 2)
        return false;

    if(candleSize(timeIndex + 2) > candleSize(timeIndex + 1))
        return false;

    if(candleSize(timeIndex + 1) < candleSize(timeIndex) * 3 / 4)
        return false;

    if(candleBody(timeIndex + 1) < candleBody(timeIndex) * 3 / 4)
        return false;

    if(iExtreme(timeIndex + 1, Max) < candleBodyMax(timeIndex) - ErrorPips())
        return false;

    if(iExtreme(timeIndex + 1, Min) > candleBodyMin(timeIndex) + ErrorPips())
        return false;

    if(MathAbs(iExtreme(timeIndex + 1, Max) - iExtreme(timeIndex, Max)) > 3 * ErrorPips())
        return false;

    return true;
}

bool Pattern::sellBuyPattern4(int timeIndex){
    // slimDoji, only for H4

    if(!slimDoji(timeIndex))
        return false;

    if(CURRENT_PERIOD != PERIOD_H4)
        return false;

    return true;
}

bool Pattern::antiPattern1(int timeIndex){
    // 3 dojis or discording pinbars in a row

    if((doji(timeIndex) && doji(timeIndex + 1) && doji(timeIndex + 2))
    || (doji(timeIndex) && doji(timeIndex + 1) && downPinbar(timeIndex + 2))
    || (doji(timeIndex) && doji(timeIndex + 1) && upPinbar(timeIndex + 2))
    || (doji(timeIndex) && upPinbar(timeIndex + 1) && doji(timeIndex + 2))
    || (doji(timeIndex) && downPinbar(timeIndex + 1) && doji(timeIndex + 2))
    || (upPinbar(timeIndex) && doji(timeIndex + 1) && doji(timeIndex + 2))
    || (downPinbar(timeIndex) && doji(timeIndex + 1) && doji(timeIndex + 2))
    || (doji(timeIndex) && upPinbar(timeIndex + 1) && downPinbar(timeIndex + 2))
    || (doji(timeIndex) && downPinbar(timeIndex + 1) && upPinbar(timeIndex + 2))
    || (upPinbar(timeIndex) && doji(timeIndex + 1) && downPinbar(timeIndex + 2))
    || (downPinbar(timeIndex) && doji(timeIndex + 1) && upPinbar(timeIndex + 2))
    || (downPinbar(timeIndex) && upPinbar(timeIndex + 1) && doji(timeIndex + 2))
    || (upPinbar(timeIndex) && downPinbar(timeIndex + 1) && doji(timeIndex + 2)))
        if(candleSize(timeIndex) + candleSize(timeIndex + 1) + candleSize(timeIndex + 2)
        > antiPatternMinSizeSumPips_ * PeriodMultiplicationFactor() * Pips())
            return true;
    return false;
}

bool Pattern::isBuyPattern(int timeIndex){
    if(isPatternSizeGood(timeIndex)
    && (buyPattern1(timeIndex) || buyPattern2(timeIndex)
    || buyPattern3(timeIndex) || sellBuyPattern4(timeIndex)))
        return true;

    return false;
}

bool Pattern::isSellPattern(int timeIndex){
    if(isPatternSizeGood(timeIndex)
    && (sellPattern1(timeIndex) || sellPattern2(timeIndex)
    || sellPattern3(timeIndex) || sellBuyPattern4(timeIndex)))
        return true;

    return false;
}

bool Pattern::isAntiPattern(int timeIndex){
    if(antiPattern1(timeIndex) || antiPattern1(timeIndex + 1) || antiPattern1(timeIndex + 2))
        return true;

    return false;
}

bool Pattern::isPatternSizeGood(int timeIndex){
    if(candleSize(timeIndex) >= PATTERN_MINIMUM_SIZE_PIPS * PeriodMultiplicationFactor() * Pips()
    && candleSize(timeIndex) <= PATTERN_MAXIMUM_SIZE_PIPS * PeriodMultiplicationFactor() * Pips())
        return true;
    return false;
}
