#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "Pivot.mqh"
#include "PivotStyle.mqh"


class PivotsDraw {
    public:
        void drawAllPivots();

    private:
        Pivot pivot_;
        static const int maxCandlesPivotLinesDraw_;
        static const int pivotLabelFontSize_;
        static const int pivotRSLineLength_;

        int getMaxTimeIndex(int);
        void drawPivotLabel(string, string, color, double);
        void drawPivotLine(string, color, datetime, datetime, double, double);

        void drawPivot(PivotPeriod);
        void drawPivotRS(PivotRS);
        void drawPivotRS(PivotPeriod, PivotRS);
};

const int PivotsDraw::maxCandlesPivotLinesDraw_ = 100;
const int PivotsDraw::pivotLabelFontSize_ = 8;
const int PivotsDraw::pivotRSLineLength_ = 6;

void PivotsDraw::drawAllPivots() {
    drawPivot(D1);
    drawPivot(W1);
    drawPivot(MN1);

    drawPivotRS(R1);
    drawPivotRS(R2);
    drawPivotRS(R3);
    drawPivotRS(S1);
    drawPivotRS(S2);
    drawPivotRS(S3);

    if (IS_DEBUG) {
        Print("PivotsDraw: pivot_.getPivot(", Symbol(), ", D1, 0): ", pivot_.getPivot(Symbol(), D1, 0));
    }
}

void PivotsDraw::drawPivot(PivotPeriod pivotPeriod) {
    PivotStyle pivotStyle(pivotPeriod);

    drawPivotLabel(
        pivotStyle.pivotLabelName(),
        pivotStyle.pivotLabelText(),
        pivotStyle.pivotColor(),
        pivot_.getPivot(Symbol(), pivotPeriod, 0)
    );

    for (int timeIndex = 0; timeIndex < getMaxTimeIndex(pivotStyle.pivotPeriodFactor()); timeIndex++) {
        drawPivotLine(
            pivotStyle.horizontalPivotLineName(timeIndex),
            pivotStyle.pivotColor(),
            iCandle(I_time, Symbol(), pivotPeriod, timeIndex - 1),
            iCandle(I_time, Symbol(), pivotPeriod, timeIndex),
            pivot_.getPivot(Symbol(), pivotPeriod, timeIndex),
            pivot_.getPivot(Symbol(), pivotPeriod, timeIndex)
        );

        drawPivotLine(
            pivotStyle.verticalPivotLineName(timeIndex),
            pivotStyle.pivotColor(),
            iCandle(I_time, Symbol(), pivotPeriod, timeIndex),
            iCandle(I_time, Symbol(), pivotPeriod, timeIndex),
            pivot_.getPivot(Symbol(), pivotPeriod, timeIndex),
            pivot_.getPivot(Symbol(), pivotPeriod, timeIndex + 1)
        );
    }
}

void PivotsDraw::drawPivotRS(PivotRS pivotRS) {
    drawPivotRS(D1, pivotRS);
}

void PivotsDraw::drawPivotRS(PivotPeriod pivotPeriod, PivotRS pivotRS) {
    PivotStyle pivotStyle(pivotPeriod);

    drawPivotLabel(
        pivotStyle.pivotRSLabelName(pivotRS),
        EnumToString(pivotRS),
        pivotStyle.pivotRSLabelColor(pivotRS),
        pivot_.getPivotRS(Symbol(), pivotPeriod, pivotRS)
    );

    drawPivotLine(
        pivotStyle.pivotRSLineName(pivotRS),
        pivotStyle.pivotRSLabelColor(pivotRS),
        Time[0],
        Time[pivotRSLineLength_],
        pivot_.getPivotRS(Symbol(), pivotPeriod, pivotRS),
        pivot_.getPivotRS(Symbol(), pivotPeriod, pivotRS)
    );
}

int PivotsDraw::getMaxTimeIndex(int pivotPeriodFactor) {
    const int maxCandles = IS_DEBUG ? CANDLES_VISIBLE_IN_GRAPH_2X : maxCandlesPivotLinesDraw_;
    return MathRound(1 + maxCandles * Period() / PERIOD_D1 / pivotPeriodFactor) + 1;
}

void PivotsDraw::drawPivotLabel(string pivotLabelName, string pivotLabelText, color pivotColor, double x) {
    ObjectCreate(pivotLabelName, OBJ_TEXT, 0, Time[0], x);

    ObjectSetString(0, pivotLabelName, OBJPROP_TEXT, pivotLabelText);
    ObjectSet(pivotLabelName, OBJPROP_COLOR, pivotColor);
    ObjectSet(pivotLabelName, OBJPROP_FONTSIZE, pivotLabelFontSize_);
}

void PivotsDraw::drawPivotLine(string lineName, color lineColor, datetime t1, datetime t2, double x1, double x2) {
    ObjectCreate(lineName, OBJ_TREND, 0, t1, x1, t2, x2);

    ObjectSet(lineName, OBJPROP_RAY_RIGHT, false);
    ObjectSet(lineName, OBJPROP_COLOR, lineColor);
    ObjectSet(lineName, OBJPROP_BACK, true);
}
