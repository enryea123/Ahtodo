#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "../market/MarketTime.mqh"
#include "../pattern/PatternsDraw.mqh"
#include "../pivot/PivotsDraw.mqh"
#include "../trendline/TrendLinesDraw.mqh"


class Drawer {
    public:
        void drawEverything();
        void setChartDefaultColors();
        void setChartMarketOpenColors();
        void setChartMarketClosedColors();

    private:
        static const int drawOpenMarketLinesMaxDays_;
        static const int openMarketLinesPipsShift_;
        static const string lastDrawingTimePrefix_;
        static const string openMarketLinePrefix_;

        bool drawLastDrawingTimeSignal();
        void drawOpenMarketLines();
};

const int Drawer::drawOpenMarketLinesMaxDays_ = 40;
const int Drawer::openMarketLinesPipsShift_ = 10;
const string Drawer::lastDrawingTimePrefix_ = "LastDrawingTime";
const string Drawer::openMarketLinePrefix_ = "OpenMarketLine";

bool Drawer::drawLastDrawingTimeSignal() {
    const string lastDrawingTimeSignal = StringConcatenate(lastDrawingTimePrefix_, NAME_SEPARATOR, Time[1]);

    if (ObjectFind(lastDrawingTimeSignal) >= 0) {
        return false;
    }

    ObjectsDeleteAll();

    ObjectCreate(
        lastDrawingTimeSignal,
        OBJ_ARROW_UP,
        0,
        Time[1],
        iExtreme(1, Min) * 0.999
    );

    ObjectSet(lastDrawingTimeSignal, OBJPROP_COLOR, clrForestGreen);
    ObjectSet(lastDrawingTimeSignal, OBJPROP_ARROWCODE, 233);
    ObjectSet(lastDrawingTimeSignal, OBJPROP_WIDTH, 4);

    return true;
}

void Drawer::drawOpenMarketLines() {
    MarketTime marketTime_;

    const datetime today = marketTime_.timeAtMidnight(marketTime_.timeItaly());

    // devo creare una funzione che calcola lo shift
    const int mt4HourShift = 1;

    for (int day = 0; day < drawOpenMarketLinesMaxDays_; day++) {
        const datetime thisDayStart = StringToTime(StringConcatenate(today, " ",
            marketTime_.marketOpenHour() + mt4HourShift, ":00")) - 86400 * day;

        const datetime thisDayEnd = StringToTime(StringConcatenate(today, " ",
            marketTime_.marketCloseHour() + mt4HourShift, ":00")) - 86400 * day;

        if (TimeDayOfWeek(thisDayStart) >= (MARKET_CLOSE_DAY) ||
            TimeDayOfWeek(thisDayStart) < MARKET_OPEN_DAY) {
            continue;
        }

        const string openMarketLineName = StringConcatenate(openMarketLinePrefix_, NAME_SEPARATOR, day);

        ObjectCreate(
            openMarketLineName,
            OBJ_TREND,
            0,
            thisDayStart,
            MathMin(iCandle(I_low, Symbol(), PERIOD_MN1, 0),
                iCandle(I_low, Symbol(), PERIOD_MN1, 1)) - openMarketLinesPipsShift_ * Pips(),
            thisDayEnd,
            MathMin(iCandle(I_low, Symbol(), PERIOD_MN1, 0),
                iCandle(I_low, Symbol(), PERIOD_MN1, 1)) - openMarketLinesPipsShift_ * Pips()
        );

        ObjectSet(openMarketLineName, OBJPROP_RAY_RIGHT, false);
        ObjectSet(openMarketLineName, OBJPROP_COLOR, clrMediumSeaGreen);
        ObjectSet(openMarketLineName, OBJPROP_WIDTH, 4);
        ObjectSet(openMarketLineName, OBJPROP_BACK, true);
    }
}

void Drawer::drawEverything() {
    if (!drawLastDrawingTimeSignal()) {
        return;
    }

    TrendLinesDraw trendLinesDraw;
    trendLinesDraw.drawTrendLines();

    PatternsDraw patternsDraw;
    patternsDraw.drawAllPatterns();

    PivotsDraw pivotsDraw;
    pivotsDraw.drawAllPivots();

    if (IS_DEBUG) {
        drawOpenMarketLines();
        Print("Updated drawings at Time: ", TimeToStr(TimeCurrent()));
    }
}

void Drawer::setChartDefaultColors() {
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrWhite);
    ChartSetInteger(0, CHART_COLOR_GRID, clrSilver);
    ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrBlack);
    ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
    ChartSetInteger(0, CHART_SCALE, 5);
    ChartSetInteger(0, CHART_COLOR_CHART_UP, clrBlack);
    ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrBlack);
    ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrWhite);
    ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrBlack);
    ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrBlack);
}

void Drawer::setChartMarketOpenColors() {
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrWhite);
    ChartSetInteger(0, CHART_COLOR_GRID, clrSilver);
}

void Drawer::setChartMarketClosedColors() {
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrSilver);
    ChartSetInteger(0, CHART_COLOR_GRID, clrWhite);
}
