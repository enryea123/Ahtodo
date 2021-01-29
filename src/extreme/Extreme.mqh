#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../util/Price.mqh"


/**
 * This class calculates all the extremes.
 */
class Extreme {
    public:
        void calculateAllExtremes(int & [], Discriminator, int);
        void calculateValidExtremes(int & [], Discriminator, int);
};

/**
 * Calculates all the extremes on the graph.
 */
void Extreme::calculateAllExtremes(int & allExtremes[], Discriminator discriminator, int extremesMinDistance) {
    ArrayFree(allExtremes);
    ArrayResize(allExtremes, CANDLES_VISIBLE_IN_GRAPH_2X);

    int numberOfExtremes = 0;

    for (int i = extremesMinDistance + 1; i < CANDLES_VISIBLE_IN_GRAPH_2X; i++) {
        bool isBeatingNeighbours = true;

        for (int j = -extremesMinDistance; j < extremesMinDistance + 1; j++) {
            if ((iExtreme(discriminator, i) > iExtreme(discriminator, i + j) && discriminator == Min) ||
                (iExtreme(discriminator, i) < iExtreme(discriminator, i + j) && discriminator == Max)) {
                isBeatingNeighbours = false;
                break;
            }
        }

        if (isBeatingNeighbours) {
            allExtremes[numberOfExtremes] = i;
            numberOfExtremes++;
            i += extremesMinDistance;
        }
    }

    ArrayResize(allExtremes, numberOfExtremes);
}

/**
 * Calculates the valid extremes on the graph.
 */
void Extreme::calculateValidExtremes(int & validExtremes[], Discriminator discriminator, int extremesMinDistance) {
    ArrayFree(validExtremes);
    ArrayResize(validExtremes, CANDLES_VISIBLE_IN_GRAPH_2X);

    int allExtremes[];
    calculateAllExtremes(allExtremes, discriminator, extremesMinDistance);

    int numberOfValidExtremes = 0;
    int lastFoundValidExtremeIndex = 0;

    for (int i = 0; i < ArraySize(allExtremes); i++) {
        bool isValidExtreme = true;
        const int indexI = allExtremes[i];

        for (int j = lastFoundValidExtremeIndex; j < indexI; j++) {
            if ((iExtreme(discriminator, indexI) > iExtreme(discriminator, j) && discriminator == Min) ||
                (iExtreme(discriminator, indexI) < iExtreme(discriminator, j) && discriminator == Max)) {
                isValidExtreme = false;
                break;
            }
        }

        if (isValidExtreme) {
            validExtremes[numberOfValidExtremes] = indexI;
            lastFoundValidExtremeIndex = indexI;
            numberOfValidExtremes++;
        }
    }

    ArrayResize(validExtremes, numberOfValidExtremes);
}