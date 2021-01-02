#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "Pivot.mqh"
#include "PivotStyle.mqh"


/**
 * This class allows to draw the pivot lines.
 */
class PivotsDraw {
    public:
        void drawAllPivots();

    private:
        Pivot pivot_;

        int getMaxTimeIndex(int);
        void drawPivotLabel(string, string, color, double);
        void drawPivotLine(string, color, double, double, double, double);

        void drawPivot(PivotPeriod);
        void drawPivotRS(PivotRS);
        void drawPivotRS(PivotPeriod, PivotRS);
};

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

/**
 * Draws the pivot lines.
 */
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

/**
 * Draws the intraday pivot RS lines for D1.
 */
void PivotsDraw::drawPivotRS(PivotRS pivotRS) {
    drawPivotRS(D1, pivotRS);
}

/**
 * Draws the pivot RS lines.
 */
void PivotsDraw::drawPivotRS(PivotPeriod pivotPeriod, PivotRS pivotRS) {
    PivotStyle pivotStyle(pivotPeriod);

    drawPivotLabel(
        pivotStyle.pivotRSLabelName(pivotRS),
        EnumToString(pivotRS),
        pivotStyle.pivotRSLabelColor(pivotRS),
        pivot_.getPivotRS(Symbol(), pivotPeriod, pivotRS)
    );

    const int pivotRSLineLength = 6;

    drawPivotLine(
        pivotStyle.pivotRSLineName(pivotRS),
        pivotStyle.pivotRSLabelColor(pivotRS),
        iCandle(I_time, Symbol(), pivotPeriod, -1),
        Time[pivotRSLineLength],
        pivot_.getPivotRS(Symbol(), pivotPeriod, pivotRS),
        pivot_.getPivotRS(Symbol(), pivotPeriod, pivotRS)
    );
}

/**
 * Returns the max index to use to draw pivot lines.
 */
int PivotsDraw::getMaxTimeIndex(int pivotPeriodFactor) {
    const int maxCandles = IS_DEBUG ? CANDLES_VISIBLE_IN_GRAPH_2X : PIVOT_LINES_DRAW_MAX_CANDLES;
    return (int) MathRound(1 + maxCandles * Period() / PERIOD_D1 / pivotPeriodFactor) + 1;
}

/**
 * Draws a single pivot label.
 */
void PivotsDraw::drawPivotLabel(string pivotLabelName, string pivotLabelText, color pivotColor, double x) {
    ObjectCreate(pivotLabelName, OBJ_TEXT, 0, Time[0], x);

    ObjectSetString(0, pivotLabelName, OBJPROP_TEXT, pivotLabelText);
    ObjectSet(pivotLabelName, OBJPROP_COLOR, pivotColor);
    ObjectSet(pivotLabelName, OBJPROP_FONTSIZE, 8);
}

/**
 * Draws a single pivot line.
 */
void PivotsDraw::drawPivotLine(string lineName, color lineColor, double t1, double t2, double x1, double x2) {
    ObjectCreate(lineName, OBJ_TREND, 0, (datetime) t1, x1, (datetime) t2, x2);

    ObjectSet(lineName, OBJPROP_RAY_RIGHT, false);
    ObjectSet(lineName, OBJPROP_COLOR, lineColor);
    ObjectSet(lineName, OBJPROP_BACK, true);
}
