#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../extreme/ExtremesDraw.mqh"
#include "TrendLine.mqh"


/**
 * This class contains drawing informaiton for the trendLines.
 */
class TrendLinesDraw {
    public:
        void drawTrendLines();

    private:
        TrendLine trendLine_;

        void drawSingleTrendLine(string, int, int, int, Discriminator);
        void drawDiscriminatedTrendLines(int & [], Discriminator);
};

/**
 * Draws all the trendLines and extremes creating them.
 */
void TrendLinesDraw::drawTrendLines() {
    int maximums[], minimums[];

    ExtremesDraw extremesDraw;
    extremesDraw.drawExtremes(maximums, Max);
    extremesDraw.drawExtremes(minimums, Min);

    drawDiscriminatedTrendLines(maximums, Max);
    drawDiscriminatedTrendLines(minimums, Min);
}

/**
 * Draws all the trendLines, discriminated by sign.
 */
void TrendLinesDraw::drawDiscriminatedTrendLines(int & indexes[], Discriminator discriminator) {
    for (int i = 0; i < ArraySize(indexes) - 1; i++) {
        for (int j = i + 1; j < ArraySize(indexes); j++) {
            for (int beam = -TRENDLINE_BEAMS; beam <= TRENDLINE_BEAMS; beam++) {

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

/**
 * Draws a single trendLine and sets its properties.
 */
void TrendLinesDraw::drawSingleTrendLine(string trendLineName, int indexI, int indexJ,
                                         int beam, Discriminator discriminator) {
    ObjectCreate(
        trendLineName,
        OBJ_TREND,
        0,
        Time[indexI],
        iExtreme(discriminator, indexI) + Pip() * beam / TRENDLINE_BEAMS,
        Time[indexJ],
        iExtreme(discriminator, indexJ) - Pip() * beam / TRENDLINE_BEAMS
    );

    if (trendLine_.isExistingTrendLineBad(trendLineName, discriminator)) {
        ObjectDelete(trendLineName);
        return;
    }

    const int trendLineWidth = !trendLine_.isBadTrendLineFromName(trendLineName) ?
        TRENDLINE_WIDTH : BAD_TRENDLINE_WIDTH;
    const color trendLineColor = !trendLine_.isBadTrendLineFromName(trendLineName) ?
        TRENDLINE_COLOR : BAD_TRENDLINE_COLOR;

    ObjectSet(trendLineName, OBJPROP_WIDTH, trendLineWidth);
    ObjectSet(trendLineName, OBJPROP_COLOR, trendLineColor);
    ObjectSet(trendLineName, OBJPROP_BACK, true);
}
