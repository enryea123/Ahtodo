#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "../market/Holiday.mqh"
#include "../market/MarketTime.mqh"
#include "../pattern/PatternsDraw.mqh"
#include "../pivot/PivotsDraw.mqh"
#include "../trendline/TrendLinesDraw.mqh"


class Drawer {
    public:
        void drawEverything();
        void setChartDefaultColors();
        void setChartMarketOpenedColors();
        void setChartMarketClosedColors();

    private:
        static const int drawOpenMarketLinesMaxDays_;
        static const int openMarketLinesPipsShift_;
        static const string lastDrawingTimePrefix_;
        static const string openMarketLinePrefix_;

        bool areDrawingsUpdated();
        string getLastDrawingTimeSignalName();
        color getLastDrawingTimeSignalColor();
        void drawLastDrawingTimeSignal();
        void drawOpenMarketLines();
};

const int Drawer::drawOpenMarketLinesMaxDays_ = 40;
const int Drawer::openMarketLinesPipsShift_ = 10;
const string Drawer::lastDrawingTimePrefix_ = "LastDrawingTime";
const string Drawer::openMarketLinePrefix_ = "OpenMarketLine";

void Drawer::drawEverything() {
    if (areDrawingsUpdated()) {
        return;
    }

    ObjectsDeleteAll();

    TrendLinesDraw trendLinesDraw;
    trendLinesDraw.drawTrendLines();

    PatternsDraw patternsDraw;
    patternsDraw.drawAllPatterns();

    PivotsDraw pivotsDraw;
    pivotsDraw.drawAllPivots();

    drawLastDrawingTimeSignal();

    if (IS_DEBUG) {
        drawOpenMarketLines();
        Print("Updated drawings at Time: ", TimeToStr(TimeLocal()));
    }
}

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

void Drawer::setChartMarketOpenedColors() {
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrWhite);
    ChartSetInteger(0, CHART_COLOR_GRID, clrSilver);
}

void Drawer::setChartMarketClosedColors() {
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrSilver);
    ChartSetInteger(0, CHART_COLOR_GRID, clrWhite);
}

bool Drawer::areDrawingsUpdated() {
    return (ObjectFind(getLastDrawingTimeSignalName()) >= 0) ? true : false;
}

void Drawer::drawLastDrawingTimeSignal() {
    const string lastDrawingTimeSignal = getLastDrawingTimeSignalName();

    ObjectCreate(
        lastDrawingTimeSignal,
        OBJ_ARROW_UP,
        0,
        Time[1],
        iExtreme(1, Min) * 0.999
    );

    const color lastDrawingTimeSignalColor = getLastDrawingTimeSignalColor();

    ObjectSet(lastDrawingTimeSignal, OBJPROP_COLOR, lastDrawingTimeSignalColor);
    ObjectSet(lastDrawingTimeSignal, OBJPROP_ARROWCODE, 233);
    ObjectSet(lastDrawingTimeSignal, OBJPROP_WIDTH, 4);
}

string Drawer::getLastDrawingTimeSignalName() {
    return StringConcatenate(lastDrawingTimePrefix_, NAME_SEPARATOR, Time[1]);
}

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

void Drawer::drawOpenMarketLines() {
    MarketTime marketTime;

    const datetime today = marketTime.timeAtMidnight(marketTime.timeItaly());
    const int brokerHoursShift = marketTime.timeShiftInHours(marketTime.timeBroker(), marketTime.timeItaly());

    for (int day = 0; day < drawOpenMarketLinesMaxDays_; day++) {
        const datetime thisDayStart = StringToTime(StringConcatenate(today, " ",
            marketTime.marketOpenHour() + brokerHoursShift, ":00")) - 86400 * day;

        const datetime thisDayEnd = StringToTime(StringConcatenate(today, " ",
            marketTime.marketCloseHour() + brokerHoursShift, ":00")) - 86400 * day;

        if (TimeDayOfWeek(thisDayStart) >= (marketTime.marketCloseDay()) ||
            TimeDayOfWeek(thisDayStart) < marketTime.marketOpenDay()) {
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
