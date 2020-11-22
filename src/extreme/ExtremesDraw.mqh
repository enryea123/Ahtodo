#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "ArrowStyle.mqh"

class ExtremesDraw {
    public:
        ExtremesDraw();
        ~ExtremesDraw();

        void drawExtremes(int & [], Discriminator);

    private:
        ArrowStyle arrowStyle_;
        const int minimumCandlesBetweenExtremes_;
        const int smallestAllowedExtremeIndex_;
        const int totalCandles_;

        void calculateAllExtremes(int & [], Discriminator);
        void calculateValidExtremes(int & [], Discriminator);
};

ExtremesDraw::ExtremesDraw():
    arrowStyle_(),
    minimumCandlesBetweenExtremes_(1),
    smallestAllowedExtremeIndex_(4),
    totalCandles_(CANDLES_VISIBLE_IN_GRAPH_2X) {
}

ExtremesDraw::~ExtremesDraw() {}

void ExtremesDraw::calculateAllExtremes(int & allExtremes[], Discriminator discriminator) {
    int numberOfExtremes = 0;
    ArrayResize(allExtremes, totalCandles_);

    for (int i = smallestAllowedExtremeIndex_; i < totalCandles_; i++) {
        bool isBeatingNeighbours = true;

        for (int j = -minimumCandlesBetweenExtremes_; j < minimumCandlesBetweenExtremes_ + 1; j++) {
            if ((iExtreme(i, discriminator) > iExtreme(i + j, discriminator) + Pips() && discriminator == Min) ||
                (iExtreme(i, discriminator) < iExtreme(i + j, discriminator) - Pips() && discriminator == Max)) {
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
    ArrayResize(validExtremes, MathRound(totalCandles_ / (minimumCandlesBetweenExtremes_ + 1)));

    for (int i = ArraySize(allExtremes) - 1; i >= 0; i--) {
        bool isValidExtreme = true;
        const int indexI = allExtremes[i];

        for (int j = i - 1; j >= 0; j--) {
            const int indexJ = allExtremes[j];

            if ((iExtreme(indexI, discriminator) > iExtreme(indexJ, discriminator) && discriminator == Min) ||
                (iExtreme(indexI, discriminator) < iExtreme(indexJ, discriminator) && discriminator == Max)) {
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

void ExtremesDraw::drawExtremes(int & extremes[], Discriminator discriminator) {
    calculateValidExtremes(extremes, discriminator);
}
