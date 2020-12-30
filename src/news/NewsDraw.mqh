#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../util/Exception.mqh"
#include "../util/Util.mqh"
#include "../util/Price.mqh"
#include "News.mqh"
#include "NewsFormat.mqh"


/**
 * This class handles the drawings of the news on the chart.
 */
class NewsDraw {
    public:
        void drawNewsLines();
        bool isNewsTimeWindow();

    private:
        static const int newsLabelFontSize_;
        static const int newsLabelPipsShift_;
        static const string newsLineNamePrefix_;
        static const string newsLabelNamePrefix_;

        void drawSingleNewsLine(News &);
        color getNewsColorFromImpact(string);
        int getNewsLineWidthFromImpact(string);
};

const int NewsDraw::newsLabelFontSize_ = 10;
const int NewsDraw::newsLabelPipsShift_ = 20;
const string NewsDraw::newsLineNamePrefix_ = "NewsLine";
const string NewsDraw::newsLabelNamePrefix_ = "NewsLabel";

/**
 * Draws all the news lines.
 */
void NewsDraw::drawNewsLines() {
    News news[];

    NewsFormat newsFormat;
    newsFormat.readNewsFromCalendar(news);

    for (int i = 0; i < ArraySize(news); i++) {
        drawSingleNewsLine(news[i]);
    }
}

/**
 * Draws a single news vertical line and sets its properties.
 * It only draws news relevant to the current symbol, and filters out holidays.
 */
void NewsDraw::drawSingleNewsLine(News & news) {
    const string symbol = Symbol();

    if (!StringContains(symbol, news.country) || news.impact == "Holiday") {
        return;
    }

    const string newsNameIdentified = StringConcatenate(news.title, " ", news.country);
    const string lineName = StringConcatenate(newsLineNamePrefix_, " ", newsNameIdentified);
    const string labelName = StringConcatenate(newsLabelNamePrefix_, " ", newsNameIdentified);

    ObjectCreate(0, lineName, OBJ_VLINE, 0, news.date, 0);

    ObjectSet(lineName, OBJPROP_RAY_RIGHT, false);
    ObjectSet(lineName, OBJPROP_COLOR, getNewsColorFromImpact(news.impact));
    ObjectSet(lineName, OBJPROP_BACK, true);
    ObjectSet(lineName, OBJPROP_WIDTH, getNewsLineWidthFromImpact(news.impact));

    ObjectCreate(labelName, OBJ_TEXT, 0, news.date,
        iCandle(I_low, symbol, PERIOD_D1, 1) - newsLabelPipsShift_ * Pip(symbol));

    ObjectSetString(0, labelName, OBJPROP_TEXT, newsNameIdentified);
    ObjectSet(labelName, OBJPROP_COLOR, getNewsColorFromImpact(news.impact));
    ObjectSet(labelName, OBJPROP_FONTSIZE, newsLabelFontSize_);
    ObjectSet(labelName, OBJPROP_ANGLE, 90);
}

/**
 * Returns true if there is a high impact news for the current symbol within the current time window.
 */
bool NewsDraw::isNewsTimeWindow() {
    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        const int timeDistanceFromBrokerTime = (int) MathAbs(TimeCurrent() - ObjectGet(ObjectName(i), OBJPROP_TIME1));

        if (StringContains(ObjectName(i), newsLineNamePrefix_) &&
            timeDistanceFromBrokerTime < 60 * NEWS_TIME_WINDOW_MINUTES &&
            ObjectGet(ObjectName(i), OBJPROP_COLOR) == getNewsColorFromImpact("High")) {
            return true;
        }
    }

    return false;
}

/**
 * Returns the color associated with each news type, which is then used to color the line and label.
 */
color NewsDraw::getNewsColorFromImpact(string impact) {
    if (impact == "High") {
        return clrCrimson;
    } else if (impact == "Medium") {
        return clrDarkOrange;
    } else if (impact == "Low") {
        return clrGold;
    } else if (impact == "Holiday") {
        return clrPurple;
    }

    return clrBlack;
}

/**
 * Returns the line width associated with each news type.
 */
int NewsDraw::getNewsLineWidthFromImpact(string impact) {
    if (impact == "High") {
        return 2;
    } else if (impact == "Medium") {
        return 1;
    } else if (impact == "Low") {
        return 1;
    } else if (impact == "Holiday") {
        return 1;
    }

    return 1;
}
