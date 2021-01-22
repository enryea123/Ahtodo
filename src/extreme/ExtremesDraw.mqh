#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "ArrowStyle.mqh"
#include "Extreme.mqh"


/**
 * This class handles the drawings of the extremes on the chart.
 */
class ExtremesDraw {
    public:
        void drawExtremes(int & [], int & []);

    private:
        void drawDiscriminatedExtremes(int & [], Discriminator);
};

/**
 * Draws the extremes on the graph.
 */
void ExtremesDraw::drawExtremes(int & maximums[], int & minimums[]) {
    drawDiscriminatedExtremes(maximums, Max);
    drawDiscriminatedExtremes(minimums, Min);
}

/**
 * Draws the discriminated extremes on the graph.
 */
void ExtremesDraw::drawDiscriminatedExtremes(int & validExtremes[], Discriminator discriminator) {
    ArrowStyle arrowStyle;
    Extreme extreme;

    extreme.calculateValidExtremes(validExtremes, discriminator, EXTREMES_MIN_DISTANCE);

    for (int i = 0; i < ArraySize(validExtremes); i++) {
        arrowStyle.drawExtremeArrow(validExtremes[i], discriminator, true);
    }

    if (IS_DEBUG) {
        int allExtremes[];
        extreme.calculateAllExtremes(allExtremes, discriminator, EXTREMES_MIN_DISTANCE);

        for (int i = 0; i < ArraySize(allExtremes); i++) {
            arrowStyle.drawExtremeArrow(allExtremes[i], discriminator, false);
        }
    }
}
