#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../Constants.mqh"
#include "Candles.mqh"
#include "Patterns.mqh"


class PatternsDraw: public Patterns{
    public:
        PatternsDraw();
        ~PatternsDraw();

        void drawAllPatterns();

    private:
        const int numberOfCandlesForPatternsDraw_;

        void drawCandleColouredDot(int, string, color, double);
        void drawPatternRectangle(int, int, color);
};

PatternsDraw::PatternsDraw():
    numberOfCandlesForPatternsDraw_(200){
}

PatternsDraw::~PatternsDraw(){}

void PatternsDraw::drawCandleColouredDot(int timeIndex, string namePrefix, color inputColor, double shift){
    const string colouredDotName = StringConcatenate(namePrefix, "_", timeIndex);

    ObjectCreate(
        colouredDotName,
        OBJ_ARROW_UP,
        0,
        Time[timeIndex],
        iExtreme(timeIndex, Min) * shift);

    ObjectSet(colouredDotName, OBJPROP_COLOR, inputColor);
    ObjectSet(colouredDotName, OBJPROP_ARROWCODE, 167);
    ObjectSet(colouredDotName, OBJPROP_WIDTH, 1);
}

void PatternsDraw::drawPatternRectangle(int timeIndex, int patternLength, color patternColor){
    if(!isPatternSizeGood(timeIndex)){
        if(IS_DEBUG)
            patternColor = clrPink;
        else
            return;
    }

    const string patternName = StringConcatenate("Pattern_", timeIndex, "_", patternLength, "_", patternColor);

    ObjectCreate(
        patternName,
        OBJ_RECTANGLE,
        0,
        Time[timeIndex + patternLength],
        iLow(NULL, Period(), timeIndex),
        Time[timeIndex],
        iHigh(NULL, Period(), timeIndex)
    );

    ObjectSet(patternName, OBJPROP_COLOR, patternColor);
}

void PatternsDraw::drawAllPatterns(){
    const int MaxCandles = IS_DEBUG ? CANDLES_VISIBLE_IN_GRAPH_2X : numberOfCandlesForPatternsDraw_;

    for(int i = 1; i < MaxCandles; i++){
        if(IS_DEBUG){
            if(doji(i))
                drawCandleColouredDot(i, "doji", clrIndianRed, 0.99967);
            if(slimDoji(i))
                drawCandleColouredDot(i, "slimDoji", clrPeru, 0.99970);
            if(bigBar(i))
                drawCandleColouredDot(i, "bigBar", clrForestGreen, 0.99973);
            if(upPinbar(i))
                drawCandleColouredDot(i, "upPinbar", clrPlum, 0.99976);
            if(downPinbar(i))
                drawCandleColouredDot(i, "downPinbar", clrOrange, 0.99980);
        }

        // Draw a rectangle for each pattern
        if(sellPattern1(i))
            drawPatternRectangle(i, 2, clrPaleGreen);
        if(buyPattern1(i))
            drawPatternRectangle(i, 2, clrLightSteelBlue);
        if(sellPattern2(i))
            drawPatternRectangle(i, 1, clrKhaki);
        if(buyPattern2(i))
            drawPatternRectangle(i, 1, clrThistle);
        if(sellPattern3(i))
            drawPatternRectangle(i, 3, clrSandyBrown);
        if(buyPattern3(i))
            drawPatternRectangle(i, 3, clrDarkSeaGreen);
        if(sellBuyPattern4(i))
            drawPatternRectangle(i, 1, clrRosyBrown);
        if(antiPattern(i))
            drawPatternRectangle(i, 3, clrDarkGray);
    }
}
