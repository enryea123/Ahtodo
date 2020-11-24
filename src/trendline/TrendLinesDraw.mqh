#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "../extreme/ExtremesDraw.mqh"
#include "TrendLine.mqh"


class TrendLinesDraw {
    public:
        void drawTrendLines();

    private:
        TrendLine trendLine_;
        static const color trendLineColor_;
        static const color badTrendLineColor_;
        static const int numberOfBeams_;
        static const int trendLineWidth_;
        static const int badTrendLineWidth_;

        void drawSingleTrendLine(string, int, int, int, Discriminator);
        void drawDiscriminatedTrendLines(int & [], Discriminator);
};

const color TrendLinesDraw::trendLineColor_ = clrYellow;
const color TrendLinesDraw::badTrendLineColor_ = clrMistyRose;
const int TrendLinesDraw::numberOfBeams_ = 2;
const int TrendLinesDraw::trendLineWidth_ = 5;
const int TrendLinesDraw::badTrendLineWidth_ = 1;

void TrendLinesDraw::drawTrendLines() {
    int maximums[], minimums[];

    ExtremesDraw extremesDraw;
    extremesDraw.drawExtremes(maximums, Max);
    extremesDraw.drawExtremes(minimums, Min);

    drawDiscriminatedTrendLines(maximums, Max);
    drawDiscriminatedTrendLines(minimums, Min);
}

void TrendLinesDraw::drawDiscriminatedTrendLines(int & indexes[], Discriminator discriminator) {
    for (int i = 0; i < ArraySize(indexes) - 1; i++) {
        for (int j = i + 1; j < ArraySize(indexes); j++) {
            for (int beam = -numberOfBeams_; beam <= numberOfBeams_; beam++) {

                if (trendLine_.areTrendLineSetupsGood(indexes[i], indexes[j], discriminator)) {
                    const string trendLineName = trendLine_.buildTrendLineName(
                        indexes[i], indexes[j], beam, discriminator);

                    drawSingleTrendLine(trendLineName, indexes[i], indexes[j], beam, discriminator);
                }

                if (IS_DEBUG && !trendLine_.areTrendLineSetupsGood(indexes[i], indexes[j], discriminator)) {
                    const string badTrendLineName = trendLine_.buildBadTrendLineName(
                        indexes[i], indexes[j], beam, discriminator);

                    drawSingleTrendLine(badTrendLineName, indexes[i], indexes[j], beam, discriminator);
                }
            }
        }
    }
}

void TrendLinesDraw::drawSingleTrendLine(string trendLineName, int indexI, int indexJ,
                                         int beam, Discriminator discriminator) {
    ObjectCreate(
        trendLineName,
        OBJ_TREND,
        0,
        Time[indexI],
        iExtreme(indexI, discriminator) + Pips() * beam / numberOfBeams_,
        Time[indexJ],
        iExtreme(indexJ, discriminator) - Pips() * beam / numberOfBeams_
    );

    if (trendLine_.isExistingTrendLineBad(trendLineName, discriminator)) {
        ObjectDelete(trendLineName);
        return;
    }

    const int trendLineWidth = !trendLine_.isBadTrendLineFromName(trendLineName) ?
        trendLineWidth_ : badTrendLineWidth_;
    const color trendLineColor = !trendLine_.isBadTrendLineFromName(trendLineName) ?
        trendLineColor_ : badTrendLineColor_;

    ObjectSet(trendLineName, OBJPROP_WIDTH, trendLineWidth);
    ObjectSet(trendLineName, OBJPROP_COLOR, trendLineColor);
    ObjectSet(trendLineName, OBJPROP_BACK, true);
}
