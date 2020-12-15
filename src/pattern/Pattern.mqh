#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "Candle.mqh"


class Pattern: public Candle {
    public:
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
        static const int antiPatternMinSizeSumPips_;

        bool pattern1(int, Discriminator);
        bool pattern3(int, Discriminator);
};

const int Pattern::antiPatternMinSizeSumPips_ = 50;

bool Pattern::isBuyPattern(int timeIndex) {
    if (isPatternSizeGood(timeIndex)) {
        if (buyPattern1(timeIndex) || buyPattern2(timeIndex) ||
            buyPattern3(timeIndex) || sellBuyPattern4(timeIndex)) {
            return true;
        }
    }

    return false;
}

bool Pattern::isSellPattern(int timeIndex) {
    if (isPatternSizeGood(timeIndex)) {
        if (sellPattern1(timeIndex) || sellPattern2(timeIndex) ||
            sellPattern3(timeIndex) || sellBuyPattern4(timeIndex)) {
            return true;
        }
    }

    return false;
}

bool Pattern::isAntiPattern(int timeIndex) {
    if (antiPattern1(timeIndex) || antiPattern1(timeIndex + 1) || antiPattern1(timeIndex + 2)) {
        return true;
    }

    return false;
}

/**
 * Low doji followed by big bull bar
 */
bool Pattern::sellPattern1(int timeIndex) {
    return pattern1(timeIndex, Min);
}

/**
 * High doji followed by big bear bar
 */
bool Pattern::buyPattern1(int timeIndex) {
    return pattern1(timeIndex, Max);
}

/**
 * Down pinbar
 */
bool Pattern::sellPattern2(int timeIndex) {
    return downPinbar(timeIndex);
}

/**
 * Up pinbar
 */
bool Pattern::buyPattern2(int timeIndex) {
    return upPinbar(timeIndex);
}

/**
 * High doji followed by big bear bar and then big bull bar
 */
bool Pattern::sellPattern3(int timeIndex) {
    return pattern3(timeIndex, Min);
}

/**
 * Low doji followed by big bull bar and then big bear bar
 */
bool Pattern::buyPattern3(int timeIndex) {
    return pattern3(timeIndex, Max);
}

/**
 * slimDoji, only for H4
 */
bool Pattern::sellBuyPattern4(int timeIndex) {
    return (slimDoji(timeIndex) && Period() == PERIOD_H4);
}

/**
 * 3 dojis or discording pinbars in a row
 */
bool Pattern::antiPattern1(int timeIndex) {
    if ((doji(timeIndex) && doji(timeIndex + 1) && doji(timeIndex + 2)) ||
        (doji(timeIndex) && doji(timeIndex + 1) && downPinbar(timeIndex + 2)) ||
        (doji(timeIndex) && doji(timeIndex + 1) && upPinbar(timeIndex + 2)) ||
        (doji(timeIndex) && upPinbar(timeIndex + 1) && doji(timeIndex + 2)) ||
        (doji(timeIndex) && downPinbar(timeIndex + 1) && doji(timeIndex + 2)) ||
        (upPinbar(timeIndex) && doji(timeIndex + 1) && doji(timeIndex + 2)) ||
        (downPinbar(timeIndex) && doji(timeIndex + 1) && doji(timeIndex + 2)) ||
        (doji(timeIndex) && upPinbar(timeIndex + 1) && downPinbar(timeIndex + 2)) ||
        (doji(timeIndex) && downPinbar(timeIndex + 1) && upPinbar(timeIndex + 2)) ||
        (upPinbar(timeIndex) && doji(timeIndex + 1) && downPinbar(timeIndex + 2)) ||
        (downPinbar(timeIndex) && doji(timeIndex + 1) && upPinbar(timeIndex + 2)) ||
        (downPinbar(timeIndex) && upPinbar(timeIndex + 1) && doji(timeIndex + 2)) ||
        (upPinbar(timeIndex) && downPinbar(timeIndex + 1) && doji(timeIndex + 2))) {

        if (candleSize(timeIndex) + candleSize(timeIndex + 1) + candleSize(timeIndex + 2) >
            antiPatternMinSizeSumPips_ * PeriodFactor() * Pips()) {
            return true;
        }
    }

    return false;
}

bool Pattern::isPatternSizeGood(int timeIndex) {
    if (candleSize(timeIndex) >= PATTERN_MINIMUM_SIZE_PIPS * PeriodFactor() * Pips() &&
        candleSize(timeIndex) <= PATTERN_MAXIMUM_SIZE_PIPS * PeriodFactor() * Pips()) {
        return true;
    }

    return false;
}

bool Pattern::pattern1(int timeIndex, Discriminator discriminator) {
    bool isBuyPattern = (discriminator == Max);

    if (!bigBar(timeIndex) || !isSupportCandle(timeIndex + 1)) {
        return false;
    }

    if ((isBuyPattern && isCandleBull(timeIndex)) ||
        (!isBuyPattern && !isCandleBull(timeIndex))) {
        return false;
    }

    if (candleBody(timeIndex + 1) > candleBody(timeIndex) / 2 ||
        candleSize(timeIndex + 1) > candleSize(timeIndex)) {
        return false;
    }

    double candleBodySide = isBuyPattern ? candleBodyMax(timeIndex) : candleBodyMin(timeIndex);

    if (candleBodyMidPoint(timeIndex + 1) > candleBodySide + candleBody(timeIndex) / 2 ||
        candleBodyMidPoint(timeIndex + 1) < candleBodySide - candleBody(timeIndex) / 2) {
        return false;
    }

    if (MathAbs(iExtreme(discriminator, timeIndex + 1) - iExtreme(discriminator, timeIndex)) > 3 * ErrorPips()) {
        return false;
    }

    return true;
}

bool Pattern::pattern3(int timeIndex, Discriminator discriminator) {
    bool isBuyPattern = (discriminator == Max);

    if (!bigBar(timeIndex) || !bigBar(timeIndex + 1) || !isSupportCandle(timeIndex + 2)) {
        return false;
    }

    if ((isBuyPattern && isCandleBull(timeIndex)) ||
        (isBuyPattern && !isCandleBull(timeIndex + 1)) ||
        (!isBuyPattern && !isCandleBull(timeIndex)) ||
        (!isBuyPattern && isCandleBull(timeIndex + 1))) {
        return false;
    }


    if (candleBody(timeIndex + 1) > candleBody(timeIndex) * 7 / 4 ||
        candleBody(timeIndex + 1) < candleBody(timeIndex) * 3 / 4 ||
        candleSize(timeIndex + 1) < candleSize(timeIndex) * 3 / 4 ||
        candleBody(timeIndex + 2) > candleBody(timeIndex + 1) / 2 ||
        candleSize(timeIndex + 2) > candleSize(timeIndex + 1)) {
        return false;
    }

    double candleBodySide = isBuyPattern ? candleBodyMin(timeIndex + 1) : candleBodyMax(timeIndex + 1);

    if (candleBodyMidPoint(timeIndex + 2) > candleBodySide + candleBody(timeIndex + 1) / 2 ||
        candleBodyMidPoint(timeIndex + 2) < candleBodySide - candleBody(timeIndex + 1) / 2) {
        return false;
    }

    if (iExtreme(Min, timeIndex + 1) > candleBodyMin(timeIndex) + 2 * ErrorPips() ||
        iExtreme(Max, timeIndex + 1) < candleBodyMax(timeIndex) - 2 * ErrorPips()) {
        return false;
    }

    if (MathAbs(iExtreme(discriminator, timeIndex + 1) - iExtreme(discriminator, timeIndex)) > 3 * ErrorPips()) {
        return false;
    }

    return true;
}
