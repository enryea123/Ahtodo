#property copyright "2020 Enrico voidAlbano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../Constants.mqh"
#include "Pivot.mqh"


class PivotStyle{
    public:
        PivotStyle(PivotPeriod);
        ~PivotStyle();

        color pivotColor();
        color pivotRSLabelColor(PivotRS);
        int pivotPeriodFactor();
        string pivotLabelText();

        string pivotLabelName();
        string horizontalPivotLineName(int);
        string verticalPivotLineName(int);
        string pivotRSLabelName(PivotRS);
        string pivotRSLineName(PivotRS);

    private:
        PivotPeriod pivotPeriod_;
};

PivotStyle::PivotStyle(PivotPeriod pivotPeriod):
    pivotPeriod_(pivotPeriod){
}

PivotStyle::~PivotStyle() {}

color PivotStyle::pivotColor(){
    if(pivotPeriod_ == (PivotPeriod) PERIOD_D1)
        return clrMagenta;
    if(pivotPeriod_ == (PivotPeriod) PERIOD_W1)
        return clrOrange;
    if(pivotPeriod_ == (PivotPeriod) PERIOD_MN1)
        return clrDeepSkyBlue;
    return NULL;
}

color PivotStyle::pivotRSLabelColor(PivotRS pivotRS){
    return StringContains(EnumToString(pivotRS), "R") ? clrRed : clrGreen;
}

int PivotStyle::pivotPeriodFactor(){
    if(pivotPeriod_ == (PivotPeriod) PERIOD_D1)
        return 1;
    if(pivotPeriod_ == (PivotPeriod) PERIOD_W1)
        return 5;
    if(pivotPeriod_ == (PivotPeriod) PERIOD_MN1)
        return 20;
    return NULL;
}

string PivotStyle::pivotLabelText(){
    if(pivotPeriod_ == (PivotPeriod) PERIOD_D1)
        return "DP";
    if(pivotPeriod_ == (PivotPeriod) PERIOD_W1)
        return "WP";
    if(pivotPeriod_ == (PivotPeriod) PERIOD_MN1)
        return "MP";
    return NULL;
}

string PivotStyle::pivotLabelName(){
    return StringConcatenate("PivotLabel-", EnumToString(pivotPeriod_));
}

string PivotStyle::horizontalPivotLineName(int timeIndex){
    return StringConcatenate("HorizontalPivotLine-", EnumToString(pivotPeriod_), "-", timeIndex);
}

string PivotStyle::verticalPivotLineName(int timeIndex){
    return StringConcatenate("VerticalPivotLine-", EnumToString(pivotPeriod_), "-", timeIndex);
}

string PivotStyle::pivotRSLabelName(PivotRS pivotRS){
    return StringConcatenate(EnumToString(pivotRS), "-PivotLabel-", EnumToString(pivotPeriod_));
}

string PivotStyle::pivotRSLineName(PivotRS pivotRS){
    return StringConcatenate(EnumToString(pivotRS), "-PivotLine-", EnumToString(pivotPeriod_));
}
