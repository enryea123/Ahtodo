#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "../pattern/PatternsDraw.mqh"
#include "../pivot/PivotsDraw.mqh"
#include "../trendline/TrendLinesDraw.mqh"


class Drawer {
    public:
        Drawer();
        ~Drawer();

        void drawEverything();
        void setChartDefaultColors();
        void setChartMarketOpenColors();
        void setChartMarketClosedColors();

    private:
        bool drawLastDrawingTimeSignal();
        void drawOpenMarketLines();
};

Drawer::Drawer() {}

Drawer::~Drawer() {}

bool Drawer::drawLastDrawingTimeSignal() {
    const string LastDrawingTimeSignal = StringConcatenate("LastDrawingTime_", Time[1]);

    if (ObjectFind(LastDrawingTimeSignal) >= 0) {
        return false;
    }

    ObjectsDeleteAll();

    ObjectCreate(
        LastDrawingTimeSignal,
        OBJ_ARROW_UP,
        0,
        Time[1],
        iExtreme(1, Min) * 0.999
    );

    ObjectSet(LastDrawingTimeSignal, OBJPROP_COLOR, clrForestGreen);
    ObjectSet(LastDrawingTimeSignal, OBJPROP_ARROWCODE, 233);
    ObjectSet(LastDrawingTimeSignal, OBJPROP_WIDTH, 4);

    return true;
}

void Drawer::drawOpenMarketLines() {
    const int maxDays = 40;

    for (int day = 0; day < maxDays; day++) {
        const datetime ThisDayStart = StrToTime(StringConcatenate(Year(), ".", Month(), ".", Day(),
            " ", MarketOpenHour(), ":00")) - 86400 * day;

        const datetime ThisDayEnd = StrToTime(StringConcatenate(Year(), ".", Month(), ".", Day(),
            " ", MarketCloseHour() - 1, ":30")) - 86400 * day;

        if (TimeDayOfWeek(ThisDayStart) >= (MARKET_CLOSE_DAY) ||
            TimeDayOfWeek(ThisDayStart) < MARKET_OPEN_DAY) {
            continue;
        }

        const string MarketOpenLineName = StringConcatenate("MarketOpenLine-", day);

        ObjectCreate(
            MarketOpenLineName,
            OBJ_TREND,
            0,
            ThisDayStart,
            MathMin(iCandle(I_low, CURRENT_SYMBOL, PERIOD_MN1, 0),
                iCandle(I_low, CURRENT_SYMBOL, PERIOD_MN1, 1)) - 10 * Pips(),
            ThisDayEnd,
            MathMin(iCandle(I_low, CURRENT_SYMBOL, PERIOD_MN1, 0),
                iCandle(I_low, CURRENT_SYMBOL, PERIOD_MN1, 1)) - 10 * Pips()
        );

        ObjectSet(MarketOpenLineName, OBJPROP_RAY_RIGHT, false);
        ObjectSet(MarketOpenLineName, OBJPROP_COLOR, clrMediumSeaGreen);
        ObjectSet(MarketOpenLineName, OBJPROP_WIDTH, 4);
        ObjectSet(MarketOpenLineName, OBJPROP_BACK, true);
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
