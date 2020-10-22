#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"


class TrendLine{
    public:
        TrendLine();
        ~TrendLine();

        bool areTrendLineSetupsGood(int, int, Discriminator);
        bool isExistingTrendLineBad(string, Discriminator);
        bool isBadTrendLineFromName(string);
        bool isTrendLineGoodForPendingOrder(string, int);
        int getTrendLineMaxIndex(string);
        int getTrendLineMinIndex(string);
        string buildTrendLineName(int, int, int, Discriminator);
        string buildBadTrendLineName(int, int, int, Discriminator);

    private:
        const int trendLineMinCandlesLength_;
        const int trendLineMinExtremesDistance_;
        const int trendLineNameFirstIndexPosition_;
        const int trendLineNameSecondIndexPosition_;

        const double negativeSlopeVolatility_;
        const double pipsFromPriceTrendLineThreshold_;
        const double positiveSlopeVolatility_;
        const double trendLineBalanceRatioThreshold_;

        const string trendLineNamePrefix_;
        const string badTrendLineNameSuffix_;

        const string trendLineNameBeamIdentifier_;
        const string trendLineNameFirstIndexIdentifier_;
        const string trendLineNameSecondIndexIdentifier_;
        const string trendLineNameSeparator_;

        int getTrendLineIndex(string, string);
        double getMaxTrendLineSlope(double);
};

TrendLine::TrendLine():
    trendLineMinCandlesLength_(10),
    trendLineMinExtremesDistance_(TRENDLINE_MIN_EXTREMES_DISTANCE),
    trendLineNameFirstIndexPosition_(1),
    trendLineNameSecondIndexPosition_(2),

    negativeSlopeVolatility_(TRENDLINE_NEGATIVE_SLOPE_VOLATILITY),
    positiveSlopeVolatility_(TRENDLINE_POSITIVE_SLOPE_VOLATILITY),
    pipsFromPriceTrendLineThreshold_(PATTERN_MINIMUM_SIZE_PIPS + PATTERN_MAXIMUM_SIZE_PIPS),
    trendLineBalanceRatioThreshold_(0.92),

    trendLineNamePrefix_("TrendLine"),
    badTrendLineNameSuffix_("Bad"),

    trendLineNameBeamIdentifier_("b"),
    trendLineNameFirstIndexIdentifier_("i"),
    trendLineNameSecondIndexIdentifier_("j"),
    trendLineNameSeparator_("_"){
}

TrendLine::~TrendLine(){}

bool TrendLine::areTrendLineSetupsGood(int indexI, int indexJ, Discriminator discriminator){
    if(indexI < indexJ)
        return ThrowException(false, "areTrendLineSetupsGood: indexI < indexJ");

    if(indexI < 1 || indexJ < 1)
        return ThrowException(false, "areTrendLineSetupsGood: indexI < 1 || indexJ < 1");

    if(indexI < trendLineMinCandlesLength_ && indexJ < trendLineMinCandlesLength_)
        return false;

    if(MathAbs(indexI - indexJ) < trendLineMinExtremesDistance_)
        return false;

    const double trendLineBalanceRatio = MathAbs(indexI - indexJ) / (double) indexI;

    if(trendLineBalanceRatio > trendLineBalanceRatioThreshold_
    || trendLineBalanceRatio < 1 - trendLineBalanceRatioThreshold_)
        return false;

    if((iExtreme(indexI, discriminator) > iExtreme(indexJ, discriminator) && discriminator == Min)
    || (iExtreme(indexI, discriminator) < iExtreme(indexJ, discriminator) && discriminator == Max))
        return false;

    const double trendLineSlope = (iExtreme(indexJ, discriminator)
        - iExtreme(indexI, discriminator)) / (indexI - indexJ);

    if(MathAbs(trendLineSlope) > getMaxTrendLineSlope(trendLineSlope))
        return false;

    return true;
}

bool TrendLine::isExistingTrendLineBad(string trendLineName, Discriminator discriminator){
    // Broken TrendLine
    for(int k = 0; k < getTrendLineMaxIndex(trendLineName); k++){
        if(discriminator == Min && ObjectGetValueByShift(trendLineName, k)
        > iExtreme(k, discriminator) + ErrorPips())
            return true;
        if(discriminator == Max && ObjectGetValueByShift(trendLineName, k)
        < iExtreme(k, discriminator) - ErrorPips())
            return true;
    }

    const double trendLineSlope = ObjectGetValueByShift(trendLineName, 1) - ObjectGetValueByShift(trendLineName, 2);

    // TrendLine with opposite or excessive inclination
    if(discriminator == Min && trendLineSlope < 0)
        return true;
    if(discriminator == Max && trendLineSlope > 0)
        return true;
    if(MathAbs(trendLineSlope) > getMaxTrendLineSlope(trendLineSlope) && !isBadTrendLineFromName(trendLineName))
        return true;

    // TrendLine far from current price
    if(!IS_DEBUG && MathAbs(ObjectGetValueByShift(trendLineName, 1) - iCandle(I_close, 1))
    > pipsFromPriceTrendLineThreshold_ * PeriodMultiplicationFactor() * Pips())
        return true;

    return false;
}

bool TrendLine::isBadTrendLineFromName(string trendLineName){
    if(StringContains(trendLineName, trendLineNamePrefix_)
    && StringContains(trendLineName, badTrendLineNameSuffix_))
        return true;
    return false;
}

bool TrendLine::isTrendLineGoodForPendingOrder(string trendLineName, int timeIndex){
    if(!StringContains(trendLineName, trendLineNamePrefix_)
    || StringContains(trendLineName, badTrendLineNameSuffix_))
        return false;

    // Needed for orders set in the past
    if(getTrendLineMinIndex(trendLineName) < timeIndex + trendLineMinExtremesDistance_)
        return false;

    return true;
}

int TrendLine::getTrendLineIndex(string trendLineName, string indexDisambiguator){
    if(!StringContains(trendLineName, trendLineNamePrefix_))
        return -1;

    if(indexDisambiguator != trendLineNameFirstIndexIdentifier_
    && indexDisambiguator != trendLineNameSecondIndexIdentifier_)
        return -1;

    const int positionInName = indexDisambiguator == trendLineNameFirstIndexIdentifier_ ?
        trendLineNameFirstIndexPosition_ : trendLineNameSecondIndexPosition_;

    string splittedTrendLineName[];
    StringSplit(trendLineName, StringGetCharacter(trendLineNameSeparator_, 0), splittedTrendLineName);

    if(ArraySize(splittedTrendLineName) <= positionInName)
        return -1;

    StringSplit(splittedTrendLineName[positionInName], StringGetCharacter(indexDisambiguator, 0),
        splittedTrendLineName);

    if(ArraySize(splittedTrendLineName) < 2)
        return -1;

    return StrToInteger(splittedTrendLineName[1]);
}

int TrendLine::getTrendLineMaxIndex(string trendLineName){
    return getTrendLineIndex(trendLineName, trendLineNameFirstIndexIdentifier_);
}

int TrendLine::getTrendLineMinIndex(string trendLineName){
    return getTrendLineIndex(trendLineName, trendLineNameSecondIndexIdentifier_);
}

double TrendLine::getMaxTrendLineSlope(double trendLineSlope){
    const double maxVolatilityPercentage = trendLineSlope > 0 ? positiveSlopeVolatility_ : negativeSlopeVolatility_;
    return MathAbs(maxVolatilityPercentage * GetMarketVolatility());
}

string TrendLine::buildTrendLineName(int indexI, int indexJ, int beam, Discriminator discriminator){
    return StringConcatenate(trendLineNamePrefix_,
        trendLineNameSeparator_, trendLineNameFirstIndexIdentifier_, indexI,
        trendLineNameSeparator_, trendLineNameSecondIndexIdentifier_, indexJ,
        trendLineNameSeparator_, trendLineNameBeamIdentifier_, beam,
        trendLineNameSeparator_, EnumToString(discriminator));
}

string TrendLine::buildBadTrendLineName(int indexI, int indexJ, int beam, Discriminator discriminator){
    return StringConcatenate(buildTrendLineName(indexI, indexJ, beam, discriminator),
        trendLineNameSeparator_, badTrendLineNameSuffix_);
}
