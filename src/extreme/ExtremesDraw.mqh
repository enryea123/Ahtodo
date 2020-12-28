#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "ArrowStyle.mqh"


/**
 * This class calculates all the extremes and draws the arrows representing them.
 */
class ExtremesDraw {
    public:
        void drawExtremes(int & [], Discriminator);

    private:
        ArrowStyle arrowStyle_;

        void calculateAllExtremes(int & [], Discriminator);
        void calculateValidExtremes(int & [], Discriminator);
};

/**
 * Draws the extremes on the graph.
 */
void ExtremesDraw::drawExtremes(int & extremes[], Discriminator discriminator) {
    calculateValidExtremes(extremes, discriminator);
}

/**
 * Calculates all the extremes on the graph.
 */
void ExtremesDraw::calculateAllExtremes(int & allExtremes[], Discriminator discriminator) {
    int numberOfExtremes = 0;
    ArrayResize(allExtremes, CANDLES_VISIBLE_IN_GRAPH_2X);

    for (int i = SMALLEST_ALLOWED_EXTREME_INDEX; i < CANDLES_VISIBLE_IN_GRAPH_2X; i++) {
        bool isBeatingNeighbours = true;

        for (int j = -MINIMUM_CANDLES_BETWEEN_EXTREMES; j < MINIMUM_CANDLES_BETWEEN_EXTREMES + 1; j++) {
            if ((iExtreme(discriminator, i) > iExtreme(discriminator, i + j) + Pip() && discriminator == Min) ||
                (iExtreme(discriminator, i) < iExtreme(discriminator, i + j) - Pip() && discriminator == Max)) {
                isBeatingNeighbours = false;
                break;
            }
        }

        if (isBeatingNeighbours) {
            if (IS_DEBUG) {
                arrowStyle_.drawExtremeArrow(i, discriminator, false);
            }

            allExtremes[numberOfExtremes] = i;
            numberOfExtremes++;
            i += MINIMUM_CANDLES_BETWEEN_EXTREMES;
        }
    }

    ArrayResize(allExtremes, numberOfExtremes);
}

/**
 * Filters out all the valid extremes out of all the extremes found on the graph.
 */
void ExtremesDraw::calculateValidExtremes(int & validExtremes[], Discriminator discriminator) {
    int allExtremes[];
    calculateAllExtremes(allExtremes, discriminator);

    int numberOfValidExtremes = 0;
    ArrayResize(validExtremes, (int) MathRound(CANDLES_VISIBLE_IN_GRAPH_2X / (MINIMUM_CANDLES_BETWEEN_EXTREMES + 1)));

    for (int i = ArraySize(allExtremes) - 1; i >= 0; i--) {
        bool isValidExtreme = true;
        const int indexI = allExtremes[i];

        for (int j = i - 1; j >= 0; j--) {
            const int indexJ = allExtremes[j];

            if ((iExtreme(discriminator, indexI) > iExtreme(discriminator, indexJ) && discriminator == Min) ||
                (iExtreme(discriminator, indexI) < iExtreme(discriminator, indexJ) && discriminator == Max)) {
                isValidExtreme = false;
                break;
            }
        }

        if (isValidExtreme) {
            arrowStyle_.drawExtremeArrow(indexI, discriminator, isValidExtreme);

            validExtremes[numberOfValidExtremes] = indexI;
            numberOfValidExtremes++;
        }
    }

    ArrayResize(validExtremes, numberOfValidExtremes);
}
