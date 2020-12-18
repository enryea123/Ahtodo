#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"


class TrendLine {
    public:
        bool areTrendLineSetupsGood(int, int, Discriminator);
        bool isExistingTrendLineBad(string, Discriminator);
        bool isBadTrendLineFromName(string);
        bool isGoodTrendLineFromName(string, int);
        int getTrendLineMaxIndex(string);
        int getTrendLineMinIndex(string);
        string buildTrendLineName(int, int, int, Discriminator);
        string buildBadTrendLineName(int, int, int, Discriminator);

        static const int trendLineMinExtremesDistance_;
        static const double trendLineNegativeSlopeVolatility_;
        static const double trendLinePositiveSlopeVolatility_;

    private:
        static const int trendLineMinCandlesLength_;
        static const int trendLineNameFirstIndexPosition_;
        static const int trendLineNameSecondIndexPosition_;
        static const double trendLinePipsFromPriceThreshold_;
        static const double trendLineBalanceRatioThreshold_;
        static const string trendLineNamePrefix_;
        static const string trendLineBadNameSuffix_;
        static const string trendLineNameBeamIdentifier_;
        static const string trendLineNameFirstIndexIdentifier_;
        static const string trendLineNameSecondIndexIdentifier_;
        static const string trendLineNameSeparator_;

        int getTrendLineIndex(string, string);
        double getMaxTrendLineSlope(double);
};

const int TrendLine::trendLineMinCandlesLength_ = 10;
const int TrendLine::trendLineMinExtremesDistance_ = 3;
const int TrendLine::trendLineNameFirstIndexPosition_ = 1;
const int TrendLine::trendLineNameSecondIndexPosition_ = 2;
const double TrendLine::trendLineNegativeSlopeVolatility_ = 0.0038;
const double TrendLine::trendLinePositiveSlopeVolatility_ = 0.0024;
const double TrendLine::trendLinePipsFromPriceThreshold_ = PATTERN_MINIMUM_SIZE_PIPS + PATTERN_MAXIMUM_SIZE_PIPS;
const double TrendLine::trendLineBalanceRatioThreshold_ = 0.92;
const string TrendLine::trendLineNamePrefix_ = "TrendLine";
const string TrendLine::trendLineBadNameSuffix_ = "Bad";
const string TrendLine::trendLineNameBeamIdentifier_ = "b";
const string TrendLine::trendLineNameFirstIndexIdentifier_ = "i";
const string TrendLine::trendLineNameSecondIndexIdentifier_ = "j";
const string TrendLine::trendLineNameSeparator_ = NAME_SEPARATOR;

bool TrendLine::areTrendLineSetupsGood(int indexI, int indexJ, Discriminator discriminator) {
    if (indexI < indexJ) {
        return ThrowException(false, __FUNCTION__, "indexI < indexJ");
    }

    if (indexI < 1 || indexJ < 1) {
        return ThrowException(false, __FUNCTION__, "indexI < 1 || indexJ < 1");
    }

    if (indexI < trendLineMinCandlesLength_ && indexJ < trendLineMinCandlesLength_) {
        return false;
    }

    if (MathAbs(indexI - indexJ) < trendLineMinExtremesDistance_) {
        return false;
    }

    const double trendLineBalanceRatio = MathAbs(indexI - indexJ) / (double) indexI;

    if (trendLineBalanceRatio > trendLineBalanceRatioThreshold_ ||
        trendLineBalanceRatio < 1 - trendLineBalanceRatioThreshold_) {
        return false;
    }

    if ((iExtreme(discriminator, indexI) > iExtreme(discriminator, indexJ) && discriminator == Min) ||
        (iExtreme(discriminator, indexI) < iExtreme(discriminator, indexJ) && discriminator == Max)) {
        return false;
    }

    const double trendLineSlope = (iExtreme(discriminator, indexJ)
        - iExtreme(discriminator, indexI)) / (indexI - indexJ);

    if (MathAbs(trendLineSlope) > getMaxTrendLineSlope(trendLineSlope)) {
        return false;
    }

    return true;
}

/**
 * Checks if an already existing trendLine had bad setups.
 * The validations are in the order that gives optimal performance.
 */
bool TrendLine::isExistingTrendLineBad(string trendLineName, Discriminator discriminator) {
    // TrendLine far from current price
    if (!IS_DEBUG && MathAbs(ObjectGetValueByShift(trendLineName, 1) - iCandle(I_close, 1)) >
        trendLinePipsFromPriceThreshold_ * PeriodFactor() * Pips()) {
        return true;
    }

    const double trendLineSlope = ObjectGetValueByShift(trendLineName, 1) - ObjectGetValueByShift(trendLineName, 2);

    // TrendLine with opposite or excessive inclination
    if (discriminator == Min && trendLineSlope < 0) {
        return true;
    }
    if (discriminator == Max && trendLineSlope > 0) {
        return true;
    }
    if (MathAbs(trendLineSlope) > getMaxTrendLineSlope(trendLineSlope) && !isBadTrendLineFromName(trendLineName)) {
        return true;
    }

    // Broken TrendLine
    for (int k = 0; k < getTrendLineMaxIndex(trendLineName); k++) {
        if (ObjectGetValueByShift(trendLineName, k) > iExtreme(discriminator, k) + ErrorPips() &&
            discriminator == Min) {
            return true;
        }
        if (ObjectGetValueByShift(trendLineName, k) < iExtreme(discriminator, k) - ErrorPips() &&
            discriminator == Max) {
            return true;
        }
    }

    return false;
}

bool TrendLine::isBadTrendLineFromName(string trendLineName) {
    if (StringContains(trendLineName, trendLineNamePrefix_) &&
        StringContains(trendLineName, trendLineBadNameSuffix_)) {
        return true;
    }

    return false;
}

bool TrendLine::isGoodTrendLineFromName(string trendLineName, int timeIndex = 1) {
    if (!StringContains(trendLineName, trendLineNamePrefix_) ||
        StringContains(trendLineName, trendLineBadNameSuffix_)) {
        return false;
    }

    // Needed for orders set in the past
    if (getTrendLineMinIndex(trendLineName) < timeIndex + trendLineMinExtremesDistance_) {
        return false;
    }

    return true;
}

int TrendLine::getTrendLineIndex(string trendLineName, string indexDisambiguator) {
    if (!StringContains(trendLineName, trendLineNamePrefix_)) {
        return -1;
    }

    if (indexDisambiguator != trendLineNameFirstIndexIdentifier_ &&
        indexDisambiguator != trendLineNameSecondIndexIdentifier_) {
        return -1;
    }

    const int positionInName = indexDisambiguator == trendLineNameFirstIndexIdentifier_ ?
        trendLineNameFirstIndexPosition_ : trendLineNameSecondIndexPosition_;

    string splittedTrendLineName[];
    StringSplit(trendLineName, StringGetCharacter(trendLineNameSeparator_, 0), splittedTrendLineName);

    if (ArraySize(splittedTrendLineName) <= positionInName) {
        return -1;
    }

    StringSplit(splittedTrendLineName[positionInName], StringGetCharacter(indexDisambiguator, 0),
        splittedTrendLineName);

    if (ArraySize(splittedTrendLineName) < 2) {
        return -1;
    }

    return StrToInteger(splittedTrendLineName[1]);
}

int TrendLine::getTrendLineMaxIndex(string trendLineName) {
    return getTrendLineIndex(trendLineName, trendLineNameFirstIndexIdentifier_);
}

int TrendLine::getTrendLineMinIndex(string trendLineName) {
    return getTrendLineIndex(trendLineName, trendLineNameSecondIndexIdentifier_);
}

double TrendLine::getMaxTrendLineSlope(double trendLineSlope) {
    const double maxVolatilityPercentage = trendLineSlope > 0 ?
        trendLinePositiveSlopeVolatility_ : trendLineNegativeSlopeVolatility_;
    return MathAbs(maxVolatilityPercentage * GetMarketVolatility());
}

string TrendLine::buildTrendLineName(int indexI, int indexJ, int beam, Discriminator discriminator) {
    return StringConcatenate(trendLineNamePrefix_,
        trendLineNameSeparator_, trendLineNameFirstIndexIdentifier_, indexI,
        trendLineNameSeparator_, trendLineNameSecondIndexIdentifier_, indexJ,
        trendLineNameSeparator_, trendLineNameBeamIdentifier_, beam,
        trendLineNameSeparator_, EnumToString(discriminator));
}

string TrendLine::buildBadTrendLineName(int indexI, int indexJ, int beam, Discriminator discriminator) {
    return StringConcatenate(buildTrendLineName(indexI, indexJ, beam, discriminator),
        trendLineNameSeparator_, trendLineBadNameSuffix_);
}
