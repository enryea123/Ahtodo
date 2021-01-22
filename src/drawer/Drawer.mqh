#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../extreme/ExtremesDraw.mqh"
#include "../extreme/LevelsDraw.mqh"
#include "../market/Holiday.mqh"
#include "../market/MarketTime.mqh"
#include "../news/NewsDraw.mqh"
#include "../pattern/PatternsDraw.mqh"
#include "../pivot/PivotsDraw.mqh"
#include "../trendline/TrendLinesDraw.mqh"


/**
 * This class handles the drawings on the chart. Makes sure that the colors are set properly,
 * and that patterns, trendLines, and pivots are refreshed only once per candle.
 */
class Drawer {
    public:
        void drawEverything();
        void setChartDefaultColors();
        void setChartMarketOpenedColors();
        void setChartMarketClosedColors();

    private:
        bool areDrawingsUpdated();
        string getLastDrawingTimeSignalName();
        int getLastDrawingTimeSignalObject();
        color getLastDrawingTimeSignalColor();
        void drawLastDrawingTimeSignal();
        void drawOpenMarketLines();
};

/**
 * Updates the drawings when a new candle appears.
 */
void Drawer::drawEverything() {
    if (areDrawingsUpdated()) {
        return;
    }

    ObjectsDeleteAll();

    int maximums[], minimums[];

    ExtremesDraw extremesDraw;
    extremesDraw.drawExtremes(maximums, minimums);

    TrendLinesDraw trendLinesDraw;
    trendLinesDraw.drawTrendLines(maximums, minimums);

    LevelsDraw levelsDraw;
    levelsDraw.drawValidLevels();

    PatternsDraw patternsDraw;
    patternsDraw.drawAllPatterns();

    PivotsDraw pivotsDraw;
    pivotsDraw.drawAllPivots();

    NewsDraw newsDraw;
    newsDraw.drawNewsLines();

    drawLastDrawingTimeSignal();

    if (IS_DEBUG) {
        drawOpenMarketLines();
        Print("Updated drawings at Time: ", TimeToStr(TimeLocal()));
    }
}

/**
 * Sets the colors of the chart when starting the bot.
 */
void Drawer::setChartDefaultColors() {
    ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrBlack);
    ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
    ChartSetInteger(0, CHART_SCALE, 5);
    ChartSetInteger(0, CHART_COLOR_CHART_UP, clrBlack);
    ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrBlack);
    ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrWhite);
    ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrBlack);
    ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrBlack);

    setChartMarketOpenedColors();
}

/**
 * Sets some colors of the chart to show that the market is opened.
 */
void Drawer::setChartMarketOpenedColors() {
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrWhite);
    ChartSetInteger(0, CHART_COLOR_GRID, clrSilver);
}

/**
 * Sets some colors of the chart to show that the market is closed.
 */
void Drawer::setChartMarketClosedColors() {
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrSilver);
    ChartSetInteger(0, CHART_COLOR_GRID, clrWhite);
}

/**
 * Checks if the drawings need to be updated.
 */
bool Drawer::areDrawingsUpdated() {
    return (ObjectFind(getLastDrawingTimeSignalName()) >= 0);
}

/**
 * Draws the arrow that signals the drawings update time, which is then used to determine if drawings are updated.
 */
void Drawer::drawLastDrawingTimeSignal() {
    const string lastDrawingTimeSignal = getLastDrawingTimeSignalName();

    ObjectCreate(
        lastDrawingTimeSignal,
        OBJ_ARROW_UP,
        0,
        Time[1],
        iExtreme(Min, 1) - 20 * Pip()
    );

    ObjectSet(lastDrawingTimeSignal, OBJPROP_COLOR, getLastDrawingTimeSignalColor());
    ObjectSet(lastDrawingTimeSignal, OBJPROP_ARROWCODE, getLastDrawingTimeSignalObject());
    ObjectSet(lastDrawingTimeSignal, OBJPROP_WIDTH, 4);
}

/**
 * The drawings update arrow name.
 */
string Drawer::getLastDrawingTimeSignalName() {
    return StringConcatenate(LAST_DRAWING_TIME_PREFIX, NAME_SEPARATOR, Time[1]);
}

/**
 * The drawings update arrow object type.
 */
int Drawer::getLastDrawingTimeSignalObject() {
    if (FileIsExist(CALENDAR_FILE)) {
        return 233;
    }
    return 225;
}

/**
 * Returns the color of the drawings update arrow, depending on the holiday situation.
 */
color Drawer::getLastDrawingTimeSignalColor() {
    Holiday holiday;

    if (holiday.isMajorBankHoliday()) {
        return clrCrimson;
    }
    if (holiday.isMinorBankHoliday()) {
        return clrGold;
    }
    return clrForestGreen;
}

/**
 * Draws some lines to show when the market was opened in the last days/weeks. Used only in debug mode.
 */
void Drawer::drawOpenMarketLines() {
    MarketTime marketTime;

    const datetime today = marketTime.timeAtMidnight(marketTime.timeItaly());
    const int brokerHoursShift = marketTime.timeShiftInHours(marketTime.timeBroker(), marketTime.timeItaly());

    for (int day = 0; day < DRAW_OPEN_MARKET_LINES_MAX_DAYS; day++) {
        const datetime thisDayStart = StringToTime(StringConcatenate(today, " ",
            marketTime.marketOpenHour() + brokerHoursShift, ":00")) - 86400 * day;

        const datetime thisDayEnd = StringToTime(StringConcatenate(today, " ",
            marketTime.marketCloseHour() + brokerHoursShift, ":00")) - 86400 * day;

        if (TimeDayOfWeek(thisDayStart) >= (marketTime.marketCloseDay()) ||
            TimeDayOfWeek(thisDayStart) < marketTime.marketOpenDay()) {
            continue;
        }

        const string openMarketLineName = StringConcatenate(OPEN_MARKET_LINE_PREFIX, NAME_SEPARATOR, day);

        ObjectCreate(
            openMarketLineName,
            OBJ_TREND,
            0,
            thisDayStart,
            MathMin(iCandle(I_low, Symbol(), PERIOD_MN1, 0),
                iCandle(I_low, Symbol(), PERIOD_MN1, 1)) - OPEN_MARKET_LINES_PIPS_SHIFT * Pip(),
            thisDayEnd,
            MathMin(iCandle(I_low, Symbol(), PERIOD_MN1, 0),
                iCandle(I_low, Symbol(), PERIOD_MN1, 1)) - OPEN_MARKET_LINES_PIPS_SHIFT * Pip()
        );

        ObjectSet(openMarketLineName, OBJPROP_RAY_RIGHT, false);
        ObjectSet(openMarketLineName, OBJPROP_COLOR, clrMediumSeaGreen);
        ObjectSet(openMarketLineName, OBJPROP_WIDTH, 4);
        ObjectSet(openMarketLineName, OBJPROP_BACK, true);
    }
}
