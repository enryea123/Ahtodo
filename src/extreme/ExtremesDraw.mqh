#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "ArrowStyle.mqh"


class ExtremesDraw {
    public:
        void drawExtremes(int & [], Discriminator);

    private:
        ArrowStyle arrowStyle_;
        static const int minimumCandlesBetweenExtremes_;
        static const int smallestAllowedExtremeIndex_;

        void calculateAllExtremes(int & [], Discriminator);
        void calculateValidExtremes(int & [], Discriminator);
};

const int ExtremesDraw::minimumCandlesBetweenExtremes_ = 1;
const int ExtremesDraw::smallestAllowedExtremeIndex_ = 4;

void ExtremesDraw::drawExtremes(int & extremes[], Discriminator discriminator) {
    calculateValidExtremes(extremes, discriminator);
}

void ExtremesDraw::calculateAllExtremes(int & allExtremes[], Discriminator discriminator) {
    int numberOfExtremes = 0;
    ArrayResize(allExtremes, CANDLES_VISIBLE_IN_GRAPH_2X);

    for (int i = smallestAllowedExtremeIndex_; i < CANDLES_VISIBLE_IN_GRAPH_2X; i++) {
        bool isBeatingNeighbours = true;

        for (int j = -minimumCandlesBetweenExtremes_; j < minimumCandlesBetweenExtremes_ + 1; j++) {
            if ((iExtreme(discriminator, i) > iExtreme(discriminator, i + j) + Pips() && discriminator == Min) ||
                (iExtreme(discriminator, i) < iExtreme(discriminator, i + j) - Pips() && discriminator == Max)) {
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
            i += minimumCandlesBetweenExtremes_;
        }
    }

    ArrayResize(allExtremes, numberOfExtremes);
}

void ExtremesDraw::calculateValidExtremes(int & validExtremes[], Discriminator discriminator) {
    int allExtremes[];
    calculateAllExtremes(allExtremes, discriminator);

    int numberOfValidExtremes = 0;
    ArrayResize(validExtremes, MathRound(CANDLES_VISIBLE_IN_GRAPH_2X / (minimumCandlesBetweenExtremes_ + 1)));

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
