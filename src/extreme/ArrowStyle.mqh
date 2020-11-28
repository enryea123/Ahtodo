#property copyright "2020 Enrico voidAlbano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"


class ArrowStyle {
    public:
        void drawExtremeArrow(int, Discriminator, bool);

    private:
        static const string arrowNamePrefix_;
        static const string validArrowNameSuffix_;

        color getArrowColor(bool);
        int getArrowSize(bool);
        double getArrowAnchor(Discriminator);
        string getArrowObjectType(Discriminator);
        string buildArrowName(int, Discriminator, bool);
};

const string ArrowStyle::arrowNamePrefix_ = "Arrow";
const string ArrowStyle::validArrowNameSuffix_ = "Valid";

void ArrowStyle::drawExtremeArrow(int timeIndex, Discriminator discriminator, bool isValidExtreme) {
    string arrowName = buildArrowName(timeIndex, discriminator, isValidExtreme);

    ObjectCreate(
        arrowName,
        getArrowObjectType(discriminator),
        0,
        Time[timeIndex],
        iExtreme(discriminator, timeIndex)
    );

    ObjectSet(arrowName, OBJPROP_ANCHOR, getArrowAnchor(discriminator));
    ObjectSet(arrowName, OBJPROP_COLOR, getArrowColor(isValidExtreme));
    ObjectSet(arrowName, OBJPROP_WIDTH, getArrowSize(isValidExtreme));
}

color ArrowStyle::getArrowColor(bool isValidExtreme) {
    return isValidExtreme ? clrOrange : clrRed;
}

int ArrowStyle::getArrowSize(bool isValidExtreme) {
    return isValidExtreme ? 5 : 1;
}

double ArrowStyle::getArrowAnchor(Discriminator discriminator) {
    return (discriminator == Max) ? ANCHOR_BOTTOM : ANCHOR_TOP;
}

string ArrowStyle::getArrowObjectType(Discriminator discriminator) {
    return (discriminator == Max) ? OBJ_ARROW_DOWN : OBJ_ARROW_UP;
}

string ArrowStyle::buildArrowName(int timeIndex, Discriminator discriminator, bool isValidExtreme) {
    string arrowName = StringConcatenate(arrowNamePrefix_, NAME_SEPARATOR,
        timeIndex, NAME_SEPARATOR, EnumToString(discriminator));

    if (isValidExtreme) {
        arrowName = StringConcatenate(arrowName, NAME_SEPARATOR, validArrowNameSuffix_);
    }

    return arrowName;
}
