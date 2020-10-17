#property copyright "2020 Enrico voidAlbano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../Constants.mqh"

class ArrowStyle{
    public:
        ArrowStyle() ;
        ~ArrowStyle();

        void drawExtremeArrow(int, Discriminator, bool);

    private:
        const string arrowNamePrefix_;
        const string validArrowNameSuffix_;
        const string arrowNameSeparator_;

        color getArrowColor(bool);
        int getArrowSize(bool);
        double getArrowAnchor(Discriminator);
        string buildArrowName(int, Discriminator, bool);
        string getArrowObjectType(Discriminator);
};

ArrowStyle::ArrowStyle():
    arrowNamePrefix_("Arrow"),
    validArrowNameSuffix_("Valid"),
    arrowNameSeparator_("_"){
}

ArrowStyle::~ArrowStyle() {}

color ArrowStyle::getArrowColor(bool isValidExtreme){
    if(isValidExtreme)
        return clrOrange;

    return clrRed;
}

int ArrowStyle::getArrowSize(bool isValidExtreme){
    if(isValidExtreme)
        return 5;

    return 1;
}

double ArrowStyle::getArrowAnchor(Discriminator discriminator){
    if(discriminator == Max)
        return ANCHOR_BOTTOM;
    if(discriminator == Min)
        return ANCHOR_TOP;

    return NULL;
}

string ArrowStyle::getArrowObjectType(Discriminator discriminator){
    if(discriminator == Max)
        return OBJ_ARROW_DOWN;
    if(discriminator == Min)
        return OBJ_ARROW_UP;

    return NULL;
}

string ArrowStyle::buildArrowName(int timeIndex, Discriminator discriminator, bool isValidExtreme){
    string arrowName = StringConcatenate(arrowNamePrefix_, arrowNameSeparator_,
        timeIndex, arrowNameSeparator_, EnumToString(discriminator));

    if(isValidExtreme)
        arrowName = StringConcatenate(arrowName, arrowNameSeparator_, validArrowNameSuffix_);

    return arrowName;
}

void ArrowStyle::drawExtremeArrow(int timeIndex, Discriminator discriminator, bool isValidExtreme){
    string arrowName = buildArrowName(timeIndex, discriminator, isValidExtreme);
    
    ObjectCreate(
        arrowName,
        getArrowObjectType(discriminator),
        0,
        Time[timeIndex],
        iExtreme(timeIndex, discriminator)
    );

    ObjectSet(arrowName, OBJPROP_ANCHOR, getArrowAnchor(discriminator));
    ObjectSet(arrowName, OBJPROP_COLOR, getArrowColor(isValidExtreme));
    ObjectSet(arrowName, OBJPROP_WIDTH, getArrowSize(isValidExtreme));
}
