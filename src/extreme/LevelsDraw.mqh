#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../util/Price.mqh"
#include "Extreme.mqh"


/**
 * This class handles the drawings of the horizontal levels on the chart.
 */
class LevelsDraw {
    public:
        void drawAllLevels();
        void drawValidLevels();

    private:
        void drawDiscriminatedAllLevels(Discriminator);
        void drawDiscriminatedValidLevels(Discriminator);

        void drawSingleLevelLine(int, Discriminator);
        string buildLevelLineName(int, Discriminator);
};

/**
 * Draws all the horizontal levels on the graph.
 */
void LevelsDraw::drawAllLevels() {
    drawDiscriminatedAllLevels(Max);
    drawDiscriminatedAllLevels(Min);
}

/**
 * Draws all the discriminated horizontal levels on the graph.
 */
void LevelsDraw::drawDiscriminatedAllLevels(Discriminator discriminator) {
    Extreme extreme;
    int allLevels[];

    extreme.calculateAllExtremes(allLevels, discriminator,LEVELS_MIN_DISTANCE);

    for (int i = 0; i < ArraySize(allLevels); i++) {
        drawSingleLevelLine(allLevels[i], discriminator);
    }
}

/**
 * Draws the valid horizontal levels on the graph.
 */
void LevelsDraw::drawValidLevels() {
    drawDiscriminatedValidLevels(Max);
    drawDiscriminatedValidLevels(Min);
}

/**
 * Draws the discriminated valid horizontal levels on the graph.
 */
void LevelsDraw::drawDiscriminatedValidLevels(Discriminator discriminator) {
    Extreme extreme;
    int validLevels[];

    extreme.calculateValidExtremes(validLevels, discriminator, LEVELS_MIN_DISTANCE);

    for (int i = 0; i < ArraySize(validLevels); i++) {
        drawSingleLevelLine(validLevels[i], discriminator);
    }
}

/**
 * Draws a single horizontal level on the graph.
 */
void LevelsDraw::drawSingleLevelLine(int index, Discriminator discriminator) {
    const string levelLineName = buildLevelLineName(index, discriminator);

    ObjectCreate(
        levelLineName,
        OBJ_TREND,
        0,
        Time[index],
        iExtreme(discriminator, index),
        Time[0],
        iExtreme(discriminator, index)
    );

    ObjectSet(levelLineName, OBJPROP_COLOR, clrDimGray);
    ObjectSet(levelLineName, OBJPROP_BACK, true);
}

/**
 * Builds the name of the Level line.
 */
string LevelsDraw::buildLevelLineName(int index, Discriminator discriminator) {
    return StringConcatenate(LEVEL_NAME_PREFIX, NAME_SEPARATOR, index, NAME_SEPARATOR, EnumToString(discriminator));
}
