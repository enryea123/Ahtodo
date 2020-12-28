#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../util/Exception.mqh"
#include "../util/Price.mqh"
#include "../util/Util.mqh"


/**
 * This class allows to determine the properties of a trendLine.
 */
class TrendLine {
    public:
        ~TrendLine();

        bool areTrendLineSetupsGood(int, int, Discriminator);
        bool isExistingTrendLineBad(string, Discriminator);
        bool isBadTrendLineFromName(string);
        bool isGoodTrendLineFromName(string, int);
        int getTrendLineMaxIndex(string);
        int getTrendLineMinIndex(string);
        double getVolatility();
        string buildTrendLineName(int, int, int, Discriminator);
        string buildBadTrendLineName(int, int, int, Discriminator);

    private:
        static const string trendLineNamePrefix_;
        static const string trendLineBadNameSuffix_;
        static const string trendLineNameBeamIdentifier_;
        static const string trendLineNameFirstIndexIdentifier_;
        static const string trendLineNameSecondIndexIdentifier_;

        static double volatility_;
        static datetime volatilityTimeStamp_;

        int getTrendLineIndex(string, string);
        double getMaxTrendLineSlope(double);
};

const string TrendLine::trendLineNamePrefix_ = "TrendLine";
const string TrendLine::trendLineBadNameSuffix_ = "Bad";
const string TrendLine::trendLineNameBeamIdentifier_ = "b";
const string TrendLine::trendLineNameFirstIndexIdentifier_ = "i";
const string TrendLine::trendLineNameSecondIndexIdentifier_ = "j";

datetime TrendLine::volatilityTimeStamp_ = -1;
double TrendLine::volatility_ = -1;

TrendLine::~TrendLine() {
    volatilityTimeStamp_ = -1;
    volatility_ = -1;
}

/**
 * Checks if the setups of a trendLine are good, before it has been created.
 * It checks the indexes, length, balance, slope, steepness.
 */
bool TrendLine::areTrendLineSetupsGood(int indexI, int indexJ, Discriminator discriminator) {
    if (indexI < indexJ) {
        return ThrowException(false, __FUNCTION__, "indexI < indexJ");
    }

    if (indexI < 1 || indexJ < 1) {
        return ThrowException(false, __FUNCTION__, "indexI < 1 || indexJ < 1");
    }

    if (indexI < TRENDLINE_MIN_CANDLES_LENGTH && indexJ < TRENDLINE_MIN_CANDLES_LENGTH) {
        return false;
    }

    if (MathAbs(indexI - indexJ) < TRENDLINE_MIN_EXTREMES_DISTANCE) {
        return false;
    }

    const double trendLineBalanceRatio = MathAbs(indexI - indexJ) / (double) indexI;

    if (trendLineBalanceRatio > TRENDLINE_BALANCE_RATIO_THRESHOLD ||
        trendLineBalanceRatio < 1 - TRENDLINE_BALANCE_RATIO_THRESHOLD) {
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
        (PATTERN_MINIMUM_SIZE_PIPS + PATTERN_MAXIMUM_SIZE_PIPS) * PeriodFactor() * Pip()) {
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
        if (ObjectGetValueByShift(trendLineName, k) - iExtreme(discriminator, k) >
            TRENDLINE_TOLERANCE_PIPS * PeriodFactor() * Pip() && discriminator == Min) {
            return true;
        }
        if (ObjectGetValueByShift(trendLineName, k) - iExtreme(discriminator, k) <
            -TRENDLINE_TOLERANCE_PIPS * PeriodFactor() * Pip() && discriminator == Max) {
            return true;
        }
    }

    return false;
}

/**
 * Returns true if the given name identifies a bad trendLine.
 */
bool TrendLine::isBadTrendLineFromName(string trendLineName) {
    if (StringContains(trendLineName, trendLineNamePrefix_) &&
        StringContains(trendLineName, trendLineBadNameSuffix_)) {
        return true;
    }

    return false;
}

/**
 * Returns true if the given name identifies a good trendLine. In order to be good,
 * the minimum index of the trendLine needs to be far enough from the input timeIndex.
 */
bool TrendLine::isGoodTrendLineFromName(string trendLineName, int timeIndex = 1) {
    if (!StringContains(trendLineName, trendLineNamePrefix_) ||
        StringContains(trendLineName, trendLineBadNameSuffix_)) {
        return false;
    }

    // Needed for orders set in the past
    if (getTrendLineMinIndex(trendLineName) < timeIndex + TRENDLINE_MIN_EXTREMES_DISTANCE) {
        return false;
    }

    return true;
}

/**
 * Returns the value of the trendLine given inxed.
 */
int TrendLine::getTrendLineIndex(string trendLineName, string indexDisambiguator) {
    if (!StringContains(trendLineName, trendLineNamePrefix_)) {
        return -1;
    }

    if (indexDisambiguator != trendLineNameFirstIndexIdentifier_ &&
        indexDisambiguator != trendLineNameSecondIndexIdentifier_) {
        return -1;
    }

    const int positionInName = (indexDisambiguator == trendLineNameFirstIndexIdentifier_) ? 1 : 2;

    string splittedTrendLineName[];
    StringSplit(trendLineName, StringGetCharacter(NAME_SEPARATOR, 0), splittedTrendLineName);

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

/**
 * Returns the value of the first index of the trendLine.
 */
int TrendLine::getTrendLineMaxIndex(string trendLineName) {
    return getTrendLineIndex(trendLineName, trendLineNameFirstIndexIdentifier_);
}

/**
 * Returns the value of the second index of the trendLine.
 */
int TrendLine::getTrendLineMinIndex(string trendLineName) {
    return getTrendLineIndex(trendLineName, trendLineNameSecondIndexIdentifier_);
}

/**
 * Returns the maximum accepted slope for a trendLine to be good.
 */
double TrendLine::getMaxTrendLineSlope(double trendLineSlope) {
    const double maxVolatilityPercentage = trendLineSlope > 0 ?
        TRENDLINE_POSITIVE_SLOPE_VOLATILITY : TRENDLINE_NEGATIVE_SLOPE_VOLATILITY;
    return MathAbs(maxVolatilityPercentage * getVolatility());
}

/**
 * Calculates the market volatility at the trendLines zoom.
 */
double TrendLine::getVolatility() {
    if (volatilityTimeStamp_ != Time[0]) {
        double marketMax = -10000, marketMin = 10000;

        for (int i = 0; i < CANDLES_VISIBLE_IN_GRAPH_3X; i++) {
            marketMax = MathMax(marketMax, iExtreme(Max, i));
            marketMin = MathMin(marketMin, iExtreme(Min, i));
        }

        volatility_ = MathAbs(marketMax - marketMin);
        volatilityTimeStamp_ = Time[0];
    }

    return volatility_;
}

/**
 * Builds the trendLine name.
 */
string TrendLine::buildTrendLineName(int indexI, int indexJ, int beam, Discriminator discriminator) {
    return StringConcatenate(trendLineNamePrefix_,
        NAME_SEPARATOR, trendLineNameFirstIndexIdentifier_, indexI,
        NAME_SEPARATOR, trendLineNameSecondIndexIdentifier_, indexJ,
        NAME_SEPARATOR, trendLineNameBeamIdentifier_, beam,
        NAME_SEPARATOR, EnumToString(discriminator));
}

/**
 * Builds the bad trendLine name.
 */
string TrendLine::buildBadTrendLineName(int indexI, int indexJ, int beam, Discriminator discriminator) {
    return StringConcatenate(buildTrendLineName(indexI, indexJ, beam, discriminator),
        NAME_SEPARATOR, trendLineBadNameSuffix_);
}
