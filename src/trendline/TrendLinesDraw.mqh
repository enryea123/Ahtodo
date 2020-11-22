#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "../extreme/ExtremesDraw.mqh"
#include "TrendLine.mqh"


class TrendLinesDraw {
    public:
        TrendLinesDraw();
        ~TrendLinesDraw();

        void drawTrendLines();

    private:
        TrendLine trendLine_;
        const color trendLineColor_;
        const color badTrendLineColor_;
        const int numberOfBeams_;
        const int trendLineWidth_;
        const int badTrendLineWidth_;
        const double beamSize_;

        void drawSingleTrendLine(string, int, int, int, Discriminator);
        void drawDiscriminatedTrendLines(int & [], Discriminator);
};

TrendLinesDraw::TrendLinesDraw():
    trendLine_(),
    trendLineColor_(clrYellow),
    badTrendLineColor_(clrMistyRose),
    numberOfBeams_(2),
    trendLineWidth_(5),
    badTrendLineWidth_(1),
    beamSize_(Pips()) {
}

TrendLinesDraw::~TrendLinesDraw() {}

void TrendLinesDraw::drawSingleTrendLine(string trendLineName,
                                         int indexI,
                                         int indexJ,
                                         int beam,
                                         Discriminator discriminator) {
    ObjectCreate(
        trendLineName,
        OBJ_TREND,
        0,
        Time[indexI],
        iExtreme(indexI, discriminator) + beamSize_ * beam / numberOfBeams_,
        Time[indexJ],
        iExtreme(indexJ, discriminator) - beamSize_ * beam / numberOfBeams_
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

void TrendLinesDraw::drawTrendLines() {
    int maximums[], minimums[];

    ExtremesDraw extremesDraw;
    extremesDraw.drawExtremes(maximums, Max);
    extremesDraw.drawExtremes(minimums, Min);

    drawDiscriminatedTrendLines(maximums, Max);
    drawDiscriminatedTrendLines(minimums, Min);
}
