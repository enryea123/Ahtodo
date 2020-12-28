#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "Pivot.mqh"


/**
 * This class contains styling informaiton for pivots.
 */
class PivotStyle {
    public:
        PivotStyle();
        PivotStyle(PivotPeriod);

        color pivotColor();
        color pivotRSLabelColor(PivotRS);
        int pivotPeriodFactor();
        string pivotLabelText();

        string pivotLabelName();
        string horizontalPivotLineName(int);
        string verticalPivotLineName(int);
        string pivotRSLabelName(PivotRS);
        string pivotRSLineName(PivotRS);

        void setPivotPeriod(PivotPeriod pivotPeriod);

    private:
        PivotPeriod pivotPeriod_;
};

PivotStyle::PivotStyle():
    pivotPeriod_(D1) {
}

PivotStyle::PivotStyle(PivotPeriod pivotPeriod):
    pivotPeriod_(pivotPeriod) {
}

void PivotStyle::setPivotPeriod(PivotPeriod pivotPeriod) {
    pivotPeriod_ = pivotPeriod;
}

/**
 * Returns the color for the pivot lines depending on the type.
 */
color PivotStyle::pivotColor() {
    if (pivotPeriod_ == (PivotPeriod) PERIOD_D1) {
        return clrMagenta;
    }
    if (pivotPeriod_ == (PivotPeriod) PERIOD_W1) {
        return clrOrange;
    }
    if (pivotPeriod_ == (PivotPeriod) PERIOD_MN1) {
        return clrDeepSkyBlue;
    }

    return NULL;
}

/**
 * Returns the color for the pivot RS lines depending on the type.
 */
color PivotStyle::pivotRSLabelColor(PivotRS pivotRS) {
    return StringContains(EnumToString(pivotRS), "R") ? clrRed : clrGreen;
}

/**
 * Returns the pivot factor depending on the type, which is used to determine for how many candles to draw the lines.
 */
int PivotStyle::pivotPeriodFactor() {
    if (pivotPeriod_ == (PivotPeriod) PERIOD_D1) {
        return 1;
    }
    if (pivotPeriod_ == (PivotPeriod) PERIOD_W1) {
        return 5;
    }
    if (pivotPeriod_ == (PivotPeriod) PERIOD_MN1) {
        return 20;
    }

    return NULL;
}

/**
 * Returns the pivot labels text.
 */
string PivotStyle::pivotLabelText() {
    if (pivotPeriod_ == (PivotPeriod) PERIOD_D1) {
        return "DP";
    }
    if (pivotPeriod_ == (PivotPeriod) PERIOD_W1) {
        return "WP";
    }
    if (pivotPeriod_ == (PivotPeriod) PERIOD_MN1) {
        return "MP";
    }

    return NULL;
}

/**
 * Returns the pivot label name.
 */
string PivotStyle::pivotLabelName() {
    return StringConcatenate("PivotLabel", NAME_SEPARATOR, EnumToString(pivotPeriod_));
}

/**
 * Returns the horizontal pivot line object name.
 */
string PivotStyle::horizontalPivotLineName(int timeIndex) {
    return StringConcatenate("PivotLineHorizontal", NAME_SEPARATOR,
        EnumToString(pivotPeriod_), NAME_SEPARATOR, timeIndex);
}

/**
 * Returns the vertical pivot line object name.
 */
string PivotStyle::verticalPivotLineName(int timeIndex) {
    return StringConcatenate("PivotLineVertical", NAME_SEPARATOR,
        EnumToString(pivotPeriod_), NAME_SEPARATOR, timeIndex);
}

/**
 * Returns the pivot RS label name.
 */
string PivotStyle::pivotRSLabelName(PivotRS pivotRS) {
    return StringConcatenate("PivotLabelRS", NAME_SEPARATOR, EnumToString(pivotRS),
        NAME_SEPARATOR, EnumToString(pivotPeriod_));
}

/**
 * Returns the pivot RS line object name.
 */
string PivotStyle::pivotRSLineName(PivotRS pivotRS) {
    return StringConcatenate("PivotLineRS", NAME_SEPARATOR, EnumToString(pivotRS),
        NAME_SEPARATOR, EnumToString(pivotPeriod_));
}
