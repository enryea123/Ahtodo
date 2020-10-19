#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "Candle.mqh"
#include "Pattern.mqh"


class PatternsDraw{
    public:
        PatternsDraw();
        ~PatternsDraw();

        void drawAllPatterns();

    private:
        Pattern pattern_;
        const int numberOfCandlesForPatternsDraw_;

        void drawAllColoredDots(int);
        void drawCandleColoredDot(int, string, color, double);
        void drawPatternRectangle(int, int, color);
};

PatternsDraw::PatternsDraw():
    pattern_(),
    numberOfCandlesForPatternsDraw_(200){
}

PatternsDraw::~PatternsDraw(){}

void PatternsDraw::drawCandleColoredDot(int timeIndex, string namePrefix, color inputColor, double shift){
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
    if(!pattern_.isPatternSizeGood(timeIndex)){
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

void PatternsDraw::drawAllColoredDots(int maxCandles){
    Candle candle;

    // Draw a dot for each candle type
    for(int i = 1; i < maxCandles; i++){
        if(candle.doji(i))
            drawCandleColoredDot(i, "doji", clrIndianRed, 0.99967);
        if(candle.slimDoji(i))
            drawCandleColoredDot(i, "slimDoji", clrPeru, 0.99970);
        if(candle.bigBar(i))
            drawCandleColoredDot(i, "bigBar", clrForestGreen, 0.99973);
        if(candle.upPinbar(i))
            drawCandleColoredDot(i, "upPinbar", clrPlum, 0.99976);
        if(candle.downPinbar(i))
            drawCandleColoredDot(i, "downPinbar", clrOrange, 0.99980);
    }
}

void PatternsDraw::drawAllPatterns(){
    const int maxCandles = IS_DEBUG ? CANDLES_VISIBLE_IN_GRAPH_2X : numberOfCandlesForPatternsDraw_;

    // Draw a rectangle for each pattern
    for(int i = 1; i < maxCandles; i++){
        if(pattern_.buyPattern1(i))
            drawPatternRectangle(i, 2, clrLightSteelBlue);
        if(pattern_.buyPattern2(i))
            drawPatternRectangle(i, 1, clrThistle);
        if(pattern_.buyPattern3(i))
            drawPatternRectangle(i, 3, clrDarkSeaGreen);

        if(pattern_.sellPattern1(i))
            drawPatternRectangle(i, 2, clrPaleGreen);
        if(pattern_.sellPattern2(i))
            drawPatternRectangle(i, 1, clrKhaki);
        if(pattern_.sellPattern3(i))
            drawPatternRectangle(i, 3, clrSandyBrown);

        if(pattern_.sellBuyPattern4(i))
            drawPatternRectangle(i, 1, clrRosyBrown);

        if(pattern_.antiPattern1(i))
            drawPatternRectangle(i, 3, clrDarkGray);
    }

    if(IS_DEBUG)
        drawAllColoredDots(maxCandles);
}