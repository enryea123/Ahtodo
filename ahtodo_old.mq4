#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property description "Enrico Albano's automated bot for ahtodo"

#define MY_SCRIPT_ID 2044000
#define MY_SCRIPT_ID_030 2044030
#define MY_SCRIPT_ID_060 2044060
#define MY_SCRIPT_ID_240 2044240

#define MARKET_OPEN_HOUR 10
#define MARKET_CLOSE_HOUR 18
#define MARKET_OPEN_HOUR_H4 2
#define MARKET_CLOSE_HOUR_H4 22
#define MARKET_CLOSE_HOUR_PENDING 17
#define MARKET_OPEN_DAY 1
#define MARKET_CLOSE_DAY 5

bool SelectedOrder;
int PreviousOrderTicket;

int OrderCandlesDuration = 6;
int SmallestAllowedExtremeIndex = 4;
int TotalCandles = 940;

bool IsDebug = false;
bool PositionSplit = true;

input double PercentRisk = 1.0;
double BaseTakeProfitFactor = 3.0;



//------------------------------------------------------------------------------------------------//
// Patterns
//------------------------------------------------------------------------------------------------//




double iExtreme(int InputTime, string Discriminator){
    if(Discriminator == "Min")
        return iLow(NULL, Period(), InputTime);
    else if(Discriminator == "Max")
        return iHigh(NULL, Period(), InputTime);
    else
        return NULL;
}

int MathSign(double InputValue){
    if(InputValue > 0)
        return 1;
    else if(InputValue < 0)
        return -1;
    else
        return 0;
}

string AntiDiscriminator(string Discriminator){
    return Discriminator == "Min" ? "Max" : "Min";
}

string GetDiscriminatorFromSign(double InputValue){
    if(InputValue >= 0)
        return "Max";
    else
        return "Min";
}



//------------------------------------------------------------------------------------------------//
// Drawing functions
//------------------------------------------------------------------------------------------------//



void DrawOpenMarketLines(){
    for(int day = 0; day < 40; day++){

        datetime ThisDayStart = StrToTime(StringConcatenate(Year(), ".", Month(), ".", Day(),
            " ", MarketOpenHour(), ":00")) - 86400 * day;

        datetime ThisDayEnd = StrToTime(StringConcatenate(Year(), ".", Month(), ".", Day(),
            " ", MarketCloseHour() - 1, ":30")) - 86400 * day;

        if(TimeDayOfWeek(ThisDayStart) >= (MARKET_CLOSE_DAY)
        || TimeDayOfWeek(ThisDayStart) < MARKET_OPEN_DAY)
            continue;

        string MarketOpenLineName = StringConcatenate("MarketOpenLine-", day);

        ObjectCreate(
            MarketOpenLineName,
            OBJ_TREND,
            0,
            ThisDayStart,
            MathMin(iLow(NULL, PERIOD_MN1, 0), iLow(NULL, PERIOD_MN1, 1)) - 10 * Pips(),
            ThisDayEnd,
            MathMin(iLow(NULL, PERIOD_MN1, 0), iLow(NULL, PERIOD_MN1, 1)) - 10 * Pips());

        ObjectSet(MarketOpenLineName, OBJPROP_RAY_RIGHT, false);
        ObjectSet(MarketOpenLineName, OBJPROP_COLOR, clrMediumSeaGreen);
        ObjectSet(MarketOpenLineName, OBJPROP_WIDTH, 4);
        ObjectSet(MarketOpenLineName, OBJPROP_BACK, true);
    }
}

void DrawEverything(){
    string LastDrawingTimeSignal = StringConcatenate("LastDrawingTime-", Time[1]);

    if(ObjectFind(LastDrawingTimeSignal) >= 0){
        return;
    }

    for(int i = ObjectsTotal() - 1; i >= 0; i--){
        ObjectDelete(ObjectName(i));
    }

    ObjectCreate(
        LastDrawingTimeSignal,
        OBJ_ARROW_UP,
        0,
        Time[1],
        iExtreme(1, "Min") * 0.999);

    ObjectSet(LastDrawingTimeSignal, OBJPROP_COLOR, clrForestGreen);
    ObjectSet(LastDrawingTimeSignal, OBJPROP_ARROWCODE, 233);
    ObjectSet(LastDrawingTimeSignal, OBJPROP_WIDTH, 4);

    int ValidMinimumsIndexes[];
    int ValidMaximumsIndexes[];

    FindExtremes(ValidMinimumsIndexes, "Min");
    FindExtremes(ValidMaximumsIndexes, "Max");

    DrawTrendLines(ValidMinimumsIndexes, "Min");
    DrawTrendLines(ValidMaximumsIndexes, "Max");

    DrawAllMicropatterns();

    DrawAllPivots();

    if(IsDebug)
        DrawOpenMarketLines();

    Print("Updated drawings at Time: ", TimeToStr(TimeCurrent()));
}


//------------------------------------------------------------------------------------------------//
// Operational functions
//------------------------------------------------------------------------------------------------//

double Pips(){
    return Pips(Symbol());
}

double Pips(string OrderSymbol){
    return 10 * MarketInfo(OrderSymbol, MODE_TICKSIZE);
}

double ErrorPips(){
    return 2 * PeriodMultiplicationFactor() * Pips();
}

double GetCurrentMarketValue(){
    RefreshRates();
    return NormalizeDouble((Ask + Bid) / 2, Digits);
}

double GetMarketSpread(){
    RefreshRates();
    return MathAbs(Ask - Bid);
}

int PeriodMultiplicationFactor(){
    if(Period() == PERIOD_H4)
        return 2;
    return 1;
}

int GetBreakEvenPips(){
    if(Period() == PERIOD_H4)
        return 15;
    return 6;
}



bool StringContains(string InputString, string InputSubString){
    if(StringFind(InputString, InputSubString) != -1)
        return true;
    return false;
}

double GetMarketVolatility(){
    int CandlesForVolatility = 465;
    double MarketMax = -10000, MarketMin = 10000;

    for(int i = 0; i < CandlesForVolatility; i++){
        MarketMax = MathMax(MarketMax, iHigh(NULL, Period(), i));
        MarketMin = MathMin(MarketMin, iLow(NULL, Period(), i));
    }

    double Volatility = MathAbs(MarketMax - MarketMin);
    return Volatility;
}

int BotMagicNumber(){
    return (MY_SCRIPT_ID + Period());
}

bool IsUnknownMagicNumber(int MagicNumber){
    if(MagicNumber != MY_SCRIPT_ID_030
    && MagicNumber != MY_SCRIPT_ID_060
    && MagicNumber != MY_SCRIPT_ID_240)
        return true;

    return false;
}

int MarketOpenHour(){
    if(Period() == PERIOD_H4)
        return MARKET_OPEN_HOUR_H4;

    return MARKET_OPEN_HOUR;
}

int MarketCloseHour(){
    if(Period() == PERIOD_H4)
        return MARKET_CLOSE_HOUR_H4;

    return MARKET_CLOSE_HOUR;
}

void HardSleep(int Seconds){
    datetime TimeWaiting = TimeCurrent() + Seconds;

    while(TimeCurrent() < TimeWaiting)
        continue;
}

datetime GetTimeAtMidnight(){
    return (TimeCurrent() - (TimeCurrent() % (PERIOD_D1 * 60)));
}

//------------------------------------------------------------------------------------------------//
// Order placing
//------------------------------------------------------------------------------------------------//


bool AreThereOpenOrders(){
    bool OpenOrderFound = false;

    PreviousOrderTicket = OrderTicket();
    for(int order = OrdersTotal() - 1; order >= 0; order--){
        if(!OrderSelect(order, SELECT_BY_POS, MODE_TRADES)
        || !AreSymbolsCorrelated(OrderSymbol(), Symbol()))
            continue;

        if(IsUnknownMagicNumber(OrderMagicNumber())){
            Print("Emergency switchoff");
            CloseAllPositions();
            ExpertRemove();
        }

        if(OrderType() == OP_BUY || OrderType() == OP_SELL){
            OpenOrderFound = true;
        }else if(FoundAntiPattern(1)
        && OrderSymbol() == Symbol()
        && OrderMagicNumber() == BotMagicNumber()){
            Print("Found AntiPattern, deleting pending order OrderTicket(): ", OrderTicket());
            SelectedOrder = OrderDelete(OrderTicket());
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
    return OpenOrderFound;
}

bool AreSymbolsCorrelated(string SymbolOne, string SymbolTwo){
    if((StringContains(SymbolOne, "GBP") && StringContains(SymbolTwo, "GBP"))
    || (StringContains(SymbolOne, "EUR") && StringContains(SymbolTwo, "EUR")))
        return true;

    return false;
}

bool CompareTwinOrders(int OrderType, double OpenPrice,
    double StopLoss, double OrderLotsModulationFactor){

    PreviousOrderTicket = OrderTicket();
    for(int order = OrdersTotal() - 1; order >= 0; order--){
        if(!OrderSelect(order, SELECT_BY_POS, MODE_TRADES)
        || !AreSymbolsCorrelated(OrderSymbol(), Symbol())
        || OrderType() != OrderType)
            continue;

        if(IsUnknownMagicNumber(OrderMagicNumber()))
            continue;

        // Shorter timeframes are prioritized over H4
        if(Period() == PERIOD_H4 && OrderMagicNumber() != MY_SCRIPT_ID_240)
            continue;

        double OldOrderLotsModulationFactor = NormalizeDouble(GetOrderLotsModulationFactor(
            OrderType(), OrderOpenPrice(), OrderSymbol()), 2);
        double NewOrderLotsModulationFactor = NormalizeDouble(OrderLotsModulationFactor, 2);

        int OldOrderStopLossPips = MathRound(MathAbs(OrderOpenPrice() - OrderStopLoss())
            / Pips(OrderSymbol()));
        int NewOrderStopLossPips = MathRound(MathAbs(OpenPrice - StopLoss) / Pips());

        // Better size setups
        if((Period() != PERIOD_H4 && OrderMagicNumber() == MY_SCRIPT_ID_240)
        || (OldOrderLotsModulationFactor < NewOrderLotsModulationFactor)
        || (OldOrderLotsModulationFactor == NewOrderLotsModulationFactor
        && OldOrderStopLossPips > NewOrderStopLossPips)){

            Print("CompareTwinOrders: deleting order with OrderTicket(): ", OrderTicket());
            Print("OldOrderLotsModulationFactor: ", OldOrderLotsModulationFactor);
            Print("NewOrderLotsModulationFactor: ", NewOrderLotsModulationFactor);
            Print("OldOrderStopLossPips: ", OldOrderStopLossPips);
            Print("NewOrderStopLossPips: ", NewOrderStopLossPips);

            SelectedOrder = OrderDelete(OrderTicket());
        }

    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);

    bool PutNewOrder = true;

    PreviousOrderTicket = OrderTicket();
    for(order = OrdersTotal() - 1; order >= 0; order--){
        if(!OrderSelect(order, SELECT_BY_POS, MODE_TRADES)
        || !AreSymbolsCorrelated(OrderSymbol(), Symbol()))
            continue;

        if(OrderType() == OrderType
        || OrderType() == OP_BUY
        || OrderType() == OP_SELL){
            Print("CompareTwinOrders: found better order with OrderTicket(): ", OrderTicket());
            PutNewOrder = false;
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);

    return PutNewOrder;
}

double OrderLotsCalculator(double OpenPrice, double StopLoss, double OrderLotsModulationFactor){
    double YenConversionFactor = MarketInfo(Symbol(), MODE_TICKSIZE) / 0.00001;

    double StopLossDistance = MathAbs(OpenPrice - StopLoss)
        * MarketInfo(Symbol(), MODE_TICKVALUE) / YenConversionFactor;

    double AbsoluteRisk = AccountEquity() * PercentRisk / 100;
    double RawOrderLots = AbsoluteRisk / StopLossDistance / 100000;

    double OrderLots = 2 * NormalizeDouble(RawOrderLots * OrderLotsModulationFactor / 2, 2);

    if(OrderLots < 0.02)
        OrderLots = 0.02;

    return NormalizeDouble(OrderLots, 2);
}

double GetDrawdownFactor(){
    double DrawdownFactor = 1.0;

    if(GetGainsLastDaysThisSymbol(14) < 0){
        DrawdownFactor *= 0.9;

        if(GetGainsLastDaysThisSymbol(21) < 0 || GetGainsLastDaysThisSymbol(28) < 0)
            DrawdownFactor *= 0.9;

        Print("Reducing size for DrawdownFactor: ", DrawdownFactor);
    }

    return DrawdownFactor;
}

double GetOrderLotsModulationFactor(int OrderType, double OpenPrice, string OrderSymbol){
    double OrderLotsModulationFactor = 1.0;

    OrderLotsModulationFactor *= GetDrawdownFactor();

    if(IsMinorBankHoliday()){
        Print("IsMinorBankHoliday(): reducing size");
        OrderLotsModulationFactor *= 0.8;
    }

    if(Period() != PERIOD_H4){
        // Intraday Pivot for M30 and H1
        if(OpenPrice > GetPivotRS(OrderSymbol, PERIOD_D1, "R2")
        || OpenPrice < GetPivotRS(OrderSymbol, PERIOD_D1, "S2")){
            Print("The intraday pivots configuration is red");
            OrderLotsModulationFactor *= 0.0;
        }else if((OpenPrice > GetPivotRS(OrderSymbol, PERIOD_D1, "R1")
        && OpenPrice < GetPivotRS(OrderSymbol, PERIOD_D1, "R2"))
        || (OpenPrice < GetPivotRS(OrderSymbol, PERIOD_D1, "S1")
        && OpenPrice > GetPivotRS(OrderSymbol, PERIOD_D1, "S2"))){
            Print("The intraday pivots configuration is yellow");
            OrderLotsModulationFactor *= 0.8;
        }

        // Daily Pivot for M30 and H1
        if(!(iHigh(OrderSymbol, PERIOD_D1, 0) > GetPivot(OrderSymbol, PERIOD_D1, 0)
        && iLow(OrderSymbol, PERIOD_D1, 0) < GetPivot(OrderSymbol, PERIOD_D1, 0))){
            Print("The daily pivot is not tested");

            if(GetCurrentMarketValue() < GetPivot(OrderSymbol, PERIOD_D1, 0)){
                if(OrderType == OP_BUYSTOP)
                    OrderLotsModulationFactor *= 1.1;
                if(OrderType == OP_SELLSTOP)
                    OrderLotsModulationFactor *= 0.9;
            }else{
                if(OrderType == OP_BUYSTOP)
                    OrderLotsModulationFactor *= 0.9;
                if(OrderType == OP_SELLSTOP)
                    OrderLotsModulationFactor *= 1.1;
            }
        }
    }

    // Pivots configuration
    if(GetPivot(OrderSymbol, PERIOD_D1, 0) > GetPivot(OrderSymbol, PERIOD_W1, 0)
    && GetPivot(OrderSymbol, PERIOD_W1, 0) > GetPivot(OrderSymbol, PERIOD_MN1, 0)){
        Print("The daily, weekly, and monthly pivots are in a bull configuration");

        if(OrderType == OP_BUYSTOP)
            OrderLotsModulationFactor *= 1.1;
        if(OrderType == OP_SELLSTOP)
            OrderLotsModulationFactor *= 0.9;
    }
    if(GetPivot(OrderSymbol, PERIOD_D1, 0) < GetPivot(OrderSymbol, PERIOD_W1, 0)
    && GetPivot(OrderSymbol, PERIOD_W1, 0) < GetPivot(OrderSymbol, PERIOD_MN1, 0)){
        Print("The daily, weekly, and monthly pivots are in a bear configuration");

        if(OrderType == OP_BUYSTOP)
            OrderLotsModulationFactor *= 0.9;
        if(OrderType == OP_SELLSTOP)
            OrderLotsModulationFactor *= 1.1;
    }

    return OrderLotsModulationFactor;
}

bool VerifyGreenTimeWindow(int OrderType){
    bool IsGreenTimeWindow = true;
    int TimeWindowCandles = MathRound(OrderCandlesDuration / PeriodMultiplicationFactor());

    PreviousOrderTicket = OrderTicket();
    for(int order = 0; order < OrdersHistoryTotal(); order++){
        if(!OrderSelect(order, SELECT_BY_POS, MODE_HISTORY)
        || IsUnknownMagicNumber(OrderMagicNumber())
        || !AreSymbolsCorrelated(OrderSymbol(), Symbol())
        || (OrderType() != OP_BUY && OrderType() != OP_SELL)){
            continue;
        }

        if((OrderCloseTime() > TimeCurrent() - 60 * Period())
        || ((OrderCloseTime() > TimeCurrent() - 60 * TimeWindowCandles * Period())
        && ((OrderType() == OP_BUY && OrderType == OP_BUYSTOP)
        || (OrderType() == OP_SELL && OrderType == OP_SELLSTOP)))){
            IsGreenTimeWindow = false;
            break;
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
    return IsGreenTimeWindow;
}

int GetOrderTypeFromSetups(int TimeIndex){
    for(int t = 1; t < TimeIndex + 1; t++){
        if(FoundAntiPattern(t)){
            Print("AntiPattern found at Time: ", TimeToStr(Time[TimeIndex]));
            return -1;
        }
    }

    if(!IsSellPattern(TimeIndex) && !IsBuyPattern(TimeIndex)){
        Print("No patterns found at Time: ", TimeToStr(Time[TimeIndex]));
        return -1;
    }

    for(int i = ObjectsTotal() - 1; i >= 0; i--){
        if(!IsTrendLineGoodForPendingOrder(ObjectName(i), TimeIndex))
            continue;

        if(IsDebug){
            Print("IsSellPattern(TimeIndex): ", IsSellPattern(TimeIndex));
            Print("IsBuyPattern(TimeIndex): ", IsBuyPattern(TimeIndex));
            Print("iExtreme(TimeIndex, Max): ", iExtreme(TimeIndex, "Max"));
            Print("iExtreme(TimeIndex, Min): ", iExtreme(TimeIndex, "Min"));
            Print("ObjectGetValueByShift(ObjectName(i), TimeIndex): ",
                ObjectGetValueByShift(ObjectName(i), TimeIndex));
            Print("TrendLineDistanceMin: ", MathAbs(iExtreme(TimeIndex, "Min")
                - ObjectGetValueByShift(ObjectName(i), TimeIndex)));
            Print("TrendLineDistanceMax: ", MathAbs(iExtreme(TimeIndex, "Max")
                - ObjectGetValueByShift(ObjectName(i), TimeIndex)));
        }

        if(IsSellPattern(TimeIndex) && MathAbs(iExtreme(TimeIndex, "Min")
        - ObjectGetValueByShift(ObjectName(i), TimeIndex)) < 3 * Pips()){
            Print("Setup for OP_SELLSTOP at Time: ", TimeToStr(Time[TimeIndex]),
                " for TrendLine: ", ObjectName(i));
            return OP_SELLSTOP;
        }

        if(IsBuyPattern(TimeIndex) && MathAbs(iExtreme(TimeIndex, "Max")
        - ObjectGetValueByShift(ObjectName(i), TimeIndex)) < 3 * Pips()){
            Print("Setup for OP_BUYSTOP at Time: ", TimeToStr(Time[TimeIndex]),
                " for TrendLine: ", ObjectName(i));
            return OP_BUYSTOP;
        }
    }

    Print("No setups found at Time: ", TimeToStr(Time[TimeIndex]));
    return -1;
}

void PutPendingOrder(){
    DeleteCorrelatedPendingOrders();

    PutPendingOrder(1);

    // At the opening of the market, search for patterns in the past
    if(Hour() == MarketOpenHour() && Minute() < 30 && TimeSeconds(TimeCurrent()) > 30)
        for(int time = 1; time < OrderCandlesDuration + 1; time++)
            PutPendingOrder(time);
}

void PutPendingOrder(int StartIndexForOrder){
    if(StartIndexForOrder < 1)
        return;

    if(TimeSeconds(TimeCurrent()) < 10)
        return;

    if(Minute() == 0 || Minute() == 59
    || Minute() == 30 || Minute() == 29)
        return;

    if(Period() == PERIOD_M30)
        HardSleep(2);
    if(Period() == PERIOD_H1)
        HardSleep(10);
    if(Period() == PERIOD_H4)
        HardSleep(18);

    if(StringContains(Symbol(), "CHF") || StringContains(Symbol(), "JPY"))
        HardSleep(2);

    int OrderType = GetOrderTypeFromSetups(StartIndexForOrder);

    int OrderSign = 0;
    string Discriminator, AntiDiscriminator;

    double Spread = GetMarketSpread();
    double SpreadOpenPrice = 0, SpreadStopLoss = 0;

    if(OrderType == OP_BUYSTOP){
        OrderSign = 1;
        Discriminator = "Max";
        AntiDiscriminator = "Min";
        SpreadOpenPrice = Spread;
    }else if(OrderType == OP_SELLSTOP){
        OrderSign = -1;
        Discriminator = "Min";
        AntiDiscriminator = "Max";
        SpreadStopLoss = Spread;
    }else{
        return;
    }

    double OpenPrice = iExtreme(StartIndexForOrder, Discriminator)
        + OrderSign * (Pips() + SpreadOpenPrice);
    double StopLoss = iExtreme(StartIndexForOrder, AntiDiscriminator)
        - OrderSign * (Pips() + SpreadStopLoss);

    double StopLossPips = MathAbs(OpenPrice - StopLoss);
    double TakeProfitFactor = GetTakeProfitFactor();
    double TakeProfit = OpenPrice + OrderSign * StopLossPips * TakeProfitFactor;

    double OrderLotsModulationFactor = GetOrderLotsModulationFactor(OrderType, OpenPrice, Symbol());
    double OrderLots = OrderLotsCalculator(OpenPrice, StopLoss, OrderLotsModulationFactor);

    if(OrderLotsModulationFactor == 0){
        Print("OrderLotsModulationFactor is zero");
        return;
    }

    if(!VerifyGreenTimeWindow(OrderType)){
        Print("VerifyGreenTimeWindow: recent order detected");
        return;
    }

    if(!CompareTwinOrders(OrderType, OpenPrice, StopLoss, OrderLotsModulationFactor))
        return;

    Print("Putting a pending order: ", OrderType);

    int OrderTicket = 0;
    int ExpirationTime = Time[0] + (OrderCandlesDuration + 1 - StartIndexForOrder) * Period() * 60;
    string OrderComment = StringConcatenate(
         "P", Period(),
        " M", NormalizeDouble(OrderLotsModulationFactor, 2),
        " R", NormalizeDouble(TakeProfitFactor, 1),
        " S", MathRound(StopLossPips / Pips()));

    while(true){
        OrderTicket = OrderSend(
            Symbol(),
            OrderType,
            OrderLots,
            NormalizeDouble(OpenPrice, Digits),
            3,
            NormalizeDouble(StopLoss, Digits),
            NormalizeDouble(TakeProfit, Digits),
            OrderComment,
            BotMagicNumber(),
            ExpirationTime,
            Blue);

        if(OrderTicket > 0){
            SelectedOrder = OrderSelect(OrderTicket, SELECT_BY_TICKET);
            OrderPrint();
            break;
        }else{
            if(GetLastError() == 132 || GetLastError() == 136){
                Print("Got error 132 or 136 while putting pending order, "
                    "sleeping before retrying");
                HardSleep(10);
            }else{
                break;
            }
        }
    }

    Print("OrderSend error ", GetLastError());
    Print("OrderType: ", OrderType);
    Print("BotMagicNumber(): ", BotMagicNumber());
    Print("StartIndexForOrder: ", StartIndexForOrder);
    Print("OrderLots: ", OrderLots);
    Print("OrderLotsModulationFactor: ", OrderLotsModulationFactor);
    Print("OpenPrice: ", NormalizeDouble(OpenPrice, Digits));
    Print("CurrentMarketValue: ", GetCurrentMarketValue());
    Print("StopLoss: ", NormalizeDouble(StopLoss, Digits));
    Print("TakeProfit: ", NormalizeDouble(TakeProfit, Digits));
    Print("TakeProfitFactor: ", TakeProfitFactor);
    Print("Spread: ", Spread);
    Print("OrderComment: ", OrderComment);
    Print("ExpirationTime: ", TimeToStr(ExpirationTime));
}

void OrderTrailing(){
    PreviousOrderTicket = OrderTicket();
    for(int order = OrdersTotal() - 1; order >= 0; order--){
        if(!OrderSelect(order, SELECT_BY_POS, MODE_TRADES))
            continue;
        if(OrderSymbol() != Symbol() || OrderMagicNumber() != BotMagicNumber())
            continue;

        if(OrderType() != OP_BUY && OrderType() != OP_SELL)
            continue;

        double StopLoss = OrderStopLoss();
        double TakeProfit = OrderTakeProfit();

        double ProfitToOpenDistance = OrderTakeProfit() - OrderOpenPrice();

        int OrderSign = MathSign(ProfitToOpenDistance);
        string Discriminator = GetDiscriminatorFromSign(ProfitToOpenDistance);

        double CurrentExtreme = iExtreme(0, Discriminator);
        double CurrentExtremeToOpenDistance = CurrentExtreme - OrderOpenPrice();

        double BreakEvenDistance = OrderSign * GetBreakEvenPips() * Pips();
        double BreakEvenStopLoss = OrderOpenPrice() - BreakEvenDistance;

        // BreakEven
        if(CurrentExtremeToOpenDistance > BreakEvenDistance && OrderSign > 0){
            StopLoss = MathMax(StopLoss, BreakEvenStopLoss);
        }
        if(CurrentExtremeToOpenDistance < BreakEvenDistance && OrderSign < 0){
            StopLoss = MathMin(StopLoss, BreakEvenStopLoss);
        }

        double TrailerInitialDistance = 2.0;
        double TrailerPercent = 0.0;

        double Trailer = TrailerInitialDistance - TrailerPercent
            * CurrentExtremeToOpenDistance / ProfitToOpenDistance;

        double InitialStopLossDistance = ProfitToOpenDistance / GetTakeProfitFactor();
        double TrailerStopLoss = CurrentExtreme - InitialStopLossDistance * Trailer;

        // Trailing StopLoss
        if(OrderSign > 0){
            StopLoss = MathMax(StopLoss, TrailerStopLoss);
        }else{
            StopLoss = MathMin(StopLoss, TrailerStopLoss);
        }


        // Modify order if values changed
        if(MathAbs(TakeProfit - OrderTakeProfit()) > Pips()
        || MathAbs(StopLoss - OrderStopLoss()) > Pips()){
            Print("OrderTrailing: modifying the existing order: ", OrderTicket());

            bool OrderModified = OrderModify(
                OrderTicket(),
                NormalizeDouble(OrderOpenPrice(), Digits),
                NormalizeDouble(StopLoss, Digits),
                NormalizeDouble(TakeProfit, Digits),
                0,
                Blue);

            if(OrderModified)
                Print("Order modified successfully");
            else{
                Print("OrderModify error ", GetLastError());
            }

            Print("OrderTicket(): ", OrderTicket());
            Print("OrderType(): ", OrderType());
            Print("OrderOpenPrice(): ", NormalizeDouble(OrderOpenPrice(), Digits));
            Print("CurrentMarketValue: ", GetCurrentMarketValue());
            Print("StopLoss: ", NormalizeDouble(StopLoss, Digits));
            Print("TakeProfit: ", NormalizeDouble(TakeProfit, Digits));
            Print("OrderExpiration(): ", OrderExpiration());
        }else{
            Print("OrderTrailing: existing order not modified: ", OrderTicket());
        }

        // Close half position when BreakEven has been reached
        if(NormalizeDouble(MathAbs(OrderOpenPrice() - OrderStopLoss()), Digits)
        == NormalizeDouble(GetBreakEvenPips() * Pips(), Digits)
        && StringContains(OrderComment(), StringConcatenate("P", Period()))
        && PositionSplit){
            SelectedOrder = OrderClose(OrderTicket(), OrderLots() / 2, OrderClosePrice(), 3);
        }

        DeleteCorrelatedPendingOrdersWhenOrderEntered(OrderType());
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
}

double GetTakeProfitFactor(){
    double TakeProfitFactor = BaseTakeProfitFactor;

    if(GetGainsLastDaysThisSymbol(14) < 0)
        TakeProfitFactor -= (BaseTakeProfitFactor + 1) / 10;
    if(GetGainsLastDaysThisSymbol(21) < 0)
        TakeProfitFactor -= (BaseTakeProfitFactor + 1) / 10;
    if(GetGainsLastDaysThisSymbol(28) < 0)
        TakeProfitFactor -= (BaseTakeProfitFactor + 1) / 10;

    /*
    double MinTakeProfitPips = 26 * PeriodMultiplicationFactor() * Pips();
    double MaxTakeProfitPips = 60 * PeriodMultiplicationFactor() * Pips();
    double StopLossPipsModule = MathAbs(StopLossPips);

    if(StopLossPipsModule * TakeProfitFactor < MinTakeProfitPips)
        TakeProfitFactor = MinTakeProfitPips / StopLossPipsModule;
    if(StopLossPipsModule * TakeProfitFactor > MaxTakeProfitPips)
        TakeProfitFactor = MaxTakeProfitPips / StopLossPipsModule;
    */

    if(!PositionSplit && TakeProfitFactor < 1)
        TakeProfitFactor = 1;
    if(PositionSplit && TakeProfitFactor < 2)
        TakeProfitFactor = 2;

    return NormalizeDouble(TakeProfitFactor, 1);
}

double GetGainsLastDaysThisSymbol(int Days){
    double AbsoluteRisk = AccountEquity() * PercentRisk / 100;
    double TotalGains = AbsoluteRisk / 10;

    PreviousOrderTicket = OrderTicket();
    for(int order = 0; order < OrdersHistoryTotal(); order++){
        if(!OrderSelect(order, SELECT_BY_POS, MODE_HISTORY)
        || OrderProfit() == 0
        || OrderCloseTime() < GetTimeAtMidnight() - (Days + 1) * 86400
        || OrderSymbol() != Symbol()
        || IsUnknownMagicNumber(OrderMagicNumber())){
            continue;
        }

        TotalGains += OrderProfit();
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);

    // Print("TotalGains of the last ", Days, " days: ", TotalGains);
    return TotalGains;
}

bool LossLimiterEnabled(){
    bool IsLossLimiterEnabled = false;
    int Days = 5;
    double MaximumPercentLoss = 5;
    double TotalLosses = 0;

    PreviousOrderTicket = OrderTicket();
    for(int order = 0; order < OrdersHistoryTotal(); order++){
        if(!OrderSelect(order, SELECT_BY_POS, MODE_HISTORY)
        || OrderProfit() == 0
        || OrderCloseTime() < GetTimeAtMidnight() - (Days + 1) * 86400
        || IsUnknownMagicNumber(OrderMagicNumber())){
            continue;
        }

        TotalLosses -= OrderProfit();

        if(TotalLosses >= AccountEquity() * MaximumPercentLoss / 100){
            Print("Loss Limiter Enabled, TotalLosses: ", TotalLosses);
            CloseAllPositions();
            IsLossLimiterEnabled = true;
            break;
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
    return IsLossLimiterEnabled;
}

void DeleteCorrelatedPendingOrdersWhenOrderEntered(int OrderType){
    PreviousOrderTicket = OrderTicket();
    for(int order = OrdersTotal() - 1; order >= 0; order--){
        if(!OrderSelect(order, SELECT_BY_POS, MODE_TRADES)
        || !AreSymbolsCorrelated(OrderSymbol(), Symbol()))
            continue;

        if(IsUnknownMagicNumber(OrderMagicNumber()))
            continue;

        if(OrderSymbol() == Symbol() && OrderType() != OP_BUY && OrderType() != OP_SELL)
            SelectedOrder = OrderDelete(OrderTicket());

        if(OrderSymbol() != Symbol()
        && ((OrderType() == OP_BUYSTOP && OrderType == OP_BUY)
        || (OrderType() == OP_SELLSTOP && OrderType == OP_SELL)))
            SelectedOrder = OrderDelete(OrderTicket());

    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
}

void DeleteCorrelatedPendingOrders(){
    int CorrelatedBuyStop = 0, CorrelatedSellStop = 0;

    PreviousOrderTicket = OrderTicket();
    for(int order = OrdersTotal() - 1; order >= 0; order--){
        if(!OrderSelect(order, SELECT_BY_POS, MODE_TRADES)
        || !AreSymbolsCorrelated(OrderSymbol(), Symbol()))
            continue;

        if(OrderType() == OP_BUYSTOP)
            CorrelatedBuyStop++;
        if(OrderType() == OP_SELLSTOP)
            CorrelatedSellStop++;

        if(CorrelatedBuyStop > 1){
            SelectedOrder = OrderDelete(OrderTicket());
            CorrelatedBuyStop--;
        }
        if(CorrelatedSellStop > 1){
            SelectedOrder = OrderDelete(OrderTicket());
            CorrelatedSellStop--;
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
}

void DeletePendingOrdersThisSymbolThisPeriod(){
    PreviousOrderTicket = OrderTicket();
    for(int order = OrdersTotal() - 1; order >= 0; order--){
        if(!OrderSelect(order, SELECT_BY_POS, MODE_TRADES))
            continue;

        if(OrderSymbol() != Symbol() || OrderMagicNumber() != BotMagicNumber())
            continue;

        if(OrderType() != OP_BUY && OrderType() != OP_SELL)
            SelectedOrder = OrderDelete(OrderTicket());
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
}

void CloseAllPositions(){
    Print("CloseAllPositions() invoked");

    PreviousOrderTicket = OrderTicket();
    for(int order = OrdersTotal() - 1; order >= 0; order--){
        if(!OrderSelect(order, SELECT_BY_POS, MODE_TRADES))
            continue;

        if(OrderSymbol() != Symbol() || OrderMagicNumber() != BotMagicNumber())
            continue;

        if(OrderType() != OP_BUY && OrderType() != OP_SELL)
            SelectedOrder = OrderDelete(OrderTicket());
        else
            SelectedOrder = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3);
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
}


//------------------------------------------------------------------------------------------------//
// Bot Execution
//------------------------------------------------------------------------------------------------//

bool AllowedSymbolsAndPeriods(){
    if(Period() != PERIOD_M30 && Period() != PERIOD_H1 && Period() != PERIOD_H4){
        Print("Timeframe not allowed for this EA");
        return false;
    }

    if(Symbol() != "GBPUSD" && Symbol() != "EURUSD"
    && Symbol() != "GBPCHF" && Symbol() != "USDCHF"
    && Symbol() != "EURJPY" && Symbol() != "GBPJPY"
    && Symbol() != "AUDUSD" && Symbol() != "USDJPY"
    && Symbol() != "USDCAD" && Symbol() != "EURGBP"
    && Symbol() != "EURNZD" && Symbol() != "NZDUSD"){
        Print("Symbol not allowed for this EA");
        return false;
    }

    if((Symbol() == "EURJPY" || Symbol() == "GBPJPY") && Period() != PERIOD_H4){
        Print("Timeframe not allowed for this Symbol");
        return false;
    }

    return true;
}

int EasterDayOfYear(int year){
    if(year == 2020)
        return 103;
    if(year == 2021)
        return 94;
    if(year == 2022)
        return 107;
    if(year == 2023)
        return 99;
    if(year == 2024)
        return 91;
    if(year == 2025)
        return 110;
    if(year == 2026)
        return 95;

    Print("Current Year's Easter day not known");
    return -1;
}

bool IsMajorBankHoliday(){
    if(Month() == 1){
        // Christmas Holidays Season
        if(Day() < 7)
            return true;

        // US: Martin Luther King Birthday (Third Monday in January)
        if(DayOfWeek() == 1 && MathCeil(Day() / 7.0) == 3)
            return true;
    }

    if(Month() == 2){
        // US: President's Day (Third Monday in February)
        if(DayOfWeek() == 1 && MathCeil(Day() / 7.0) == 3)
            return true;
    }

    if(Month() == 5){
        // IT, FR, DE, UK: Lavoro
        if(Day() == 1)
            return true;

        // US: Memorial Day (Last Monday in May)
        // UK: Spring Bank Holiday (Last Monday in May)
        if(DayOfWeek() == 1 && 31 - Day() < 7)
            return true;
    }

    if(Month() == 7){
        // US: Independence Day
        if(Day() == 4 || (Day() == 3 && DayOfWeek() == 5) || (Day() == 5 && DayOfWeek() == 1))
            return true;
    }

    if(Month() == 8){
        // Summer Holidays
        if(Day() > 7 && Day() < 24)
            return true;

        // IT: Ferragosto
        if(Day() == 15)
            return true;
    }

    if(Month() == 9){
        // US: Labor Day (First Monday in September)
        if(DayOfWeek() == 1 && MathCeil(Day() / 7.0) == 1)
            return true;
    }

    if(Month() == 10){
        // US: Columbus Day (Second Monday in October)
        if(DayOfWeek() == 1 && MathCeil(Day() / 7.0) == 2)
            return true;
    }

    if(Month() == 11){
        // US: Veterans Day
        if(Day() == 11 || (Day() == 10 && DayOfWeek() == 5) || (Day() == 12 && DayOfWeek() == 1))
            return true;

        // US: Thanksgiving Day (Fourth Thursday in November
        if(DayOfWeek() == 4 && MathCeil(Day() / 7.0) == 4)
            return true;
    }

    if(Month() == 12){
        // Christmas Holidays Season
        if(Day() > 20)
            return true;
    }

    // Easter Good Friday
    if(DayOfYear() == EasterDayOfYear(Year()) - 2)
        return true;

    // Pasquetta
    if(DayOfYear() == EasterDayOfYear(Year()) + 1)
        return true;

    // Ascension
    if(DayOfYear() == EasterDayOfYear(Year()) + 39)
        return true;

    // Pentecoste
    if(DayOfYear() == EasterDayOfYear(Year()) + 50)
        return true;

    return false;
}


bool IsMinorBankHoliday(){
    if(Month() == 4){
        // IT: Liberazione
        if(Day() == 25)
            return true;
    }

    if(Month() == 5){
        // UK: Early May Bank Holiday (First Monday in May)
        if(DayOfWeek() == 1 && MathCeil(Day() / 7.0) == 1)
            return true;

        // FR: Victory Day
        if(Day() == 8)
            return true;
    }

    if(Month() == 6){
        // IT: Festa della Repubblica
        if(Day() == 2)
            return true;
    }

    if(Month() == 7){
        // FR: Bastille
        if(Day() == 14)
            return true;
    }

    if(Month() == 8){
        // Summer Holidays
        return true;

        // CH: National Day
        if(Day() == 1)
            return true;

        // UK: Summer Bank Holiday (Last Monday in August)
        if(DayOfWeek() == 1 && 31 - Day() < 7)
            return true;
    }

    if(Month() == 10){
        // DE: German Unity
        if(Day() == 3)
            return true;
    }

    if(Month() == 11){
        // IT: Tutti i Santi
        if(Day() == 1)
            return true;

        // FR: Armistice
        if(Day() == 11)
            return true;
    }

    if(Month() == 12){
        // IT: Immacolata
        if(Day() == 8)
            return true;
    }

    return false;
}

void SetChartDefaultColors(){
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrWhite);
    ChartSetInteger(0, CHART_COLOR_GRID, clrSilver);
    ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrBlack);
    ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
    ChartSetInteger(0, CHART_SCALE, 5);
    ChartSetInteger(0, CHART_COLOR_CHART_UP, clrBlack);
    ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrBlack);
    ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrWhite);
    ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrBlack);
    ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrBlack);
}

void SetChartMarketOpenedColors(){
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrWhite);
    ChartSetInteger(0, CHART_COLOR_GRID, clrSilver);
}

void SetChartMarketClosedColors(){
    ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrSilver);
    ChartSetInteger(0, CHART_COLOR_GRID, clrWhite);
}

void OnInit(){
    SetChartDefaultColors();

    // Don't allow trading from unauthorized accounts
    if(AccountNumber() != 2100183900
    && AccountNumber() != 2100220672
    && AccountNumber() != 2100219063
    && AccountNumber() != 2100175255 // Euge
    && AccountNumber() != 2100225710){
        ExpertRemove();
        return;
    }

    if(Year() > 2021){
        ExpertRemove();
        return;
    }

    if(!AllowedSymbolsAndPeriods()){
        ExpertRemove();
        return;
    }

    DrawEverything();

    if(DayOfWeek() >= MARKET_CLOSE_DAY
    || DayOfWeek() < MARKET_OPEN_DAY)
        SetChartMarketClosedColors();
}

void OnTick(){
    //HardSleep(2);

    if(!AllowedSymbolsAndPeriods()){
        ExpertRemove();
        return;
    }

    if(IsUnknownMagicNumber(BotMagicNumber()))
        return;

    DrawEverything();

    if(DayOfWeek() >= MARKET_CLOSE_DAY
    || Hour() < MarketOpenHour()
    || Hour() >= MarketCloseHour()
    || GetMarketSpread() > 5 * Pips()
    || IsMajorBankHoliday()
    || LossLimiterEnabled()){

        Print("Market closed at time ", TimeToStr(TimeCurrent()),
            " with GetMarketSpread(): ", GetMarketSpread(),
            ", IsMajorBankHoliday(): ", IsMajorBankHoliday(),
            ", LossLimiterEnabled(): ", LossLimiterEnabled());

        SetChartMarketClosedColors();
        CloseAllPositions();
        return;
    }

    SetChartMarketOpenedColors();

    if(!IsTradeAllowed())
        return;

    if(!AreThereOpenOrders()){
        if(Hour() >= MARKET_CLOSE_HOUR_PENDING){
            DeletePendingOrdersThisSymbolThisPeriod();
            return;
        }

        PutPendingOrder();
    }else{
        OrderTrailing();
    }
}


//------------------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------//


//------------------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------//


void OnDeinit(const int reason){
    SetChartDefaultColors();

    for(int i = ObjectsTotal() - 1; i >= 0; i--){
        ObjectDelete(ObjectName(i));
    }
}


//------------------------------------------------------------------------------------------------//
//------------------------------------------------------------------------------------------------//



