

//------------------------------------------------------------------------------------------------//
// Operational functions
//------------------------------------------------------------------------------------------------//

double Pips() {
    return Pips(Symbol());
}

double Pips(string OrderSymbol) {
    return 10 * MarketInfo(OrderSymbol, MODE_TICKSIZE);
}

double ErrorPips() {
    return 2 * PeriodMultiplicationFactor() * Pips();
}

double GetCurrentMarketValue() {
    RefreshRates();
    return NormalizeDouble((Ask + Bid) / 2, Digits);
}




int GetBreakEvenPips() {
    if (Period() == PERIOD_H4) {
        return 15;
    }

    return 6;
}



bool StringContains(string InputString, string InputSubString) {
    if (StringFind(InputString, InputSubString) != -1) {
        return true;
    }

    return false;
}

int BotMagicNumber() {
    return (MY_SCRIPT_ID + Period());
}

bool IsUnknownMagicNumber(int MagicNumber) {
    if (MagicNumber != MY_SCRIPT_ID_030 && MagicNumber != MY_SCRIPT_ID_060 && MagicNumber != MY_SCRIPT_ID_240) {
        return true;
    }

    return false;
}



datetime GetTimeAtMidnight() {
    return (TimeCurrent() - (TimeCurrent() % (PERIOD_D1 * 60)));
}

//------------------------------------------------------------------------------------------------//
// Order placing
//------------------------------------------------------------------------------------------------//


bool AreThereOpenOrders() {
    bool OpenOrderFound = false;

    PreviousOrderTicket = OrderTicket();
    for (int order = OrdersTotal() - 1; order >= 0; order--) {
        if (!OrderSelect(order, SELECT_BY_POS, MODE_TRADES) || !AreSymbolsCorrelated(OrderSymbol(), Symbol())) {
            continue;
        }

        if (IsUnknownMagicNumber(OrderMagicNumber())) {
            Print("Emergency switchoff");
            CloseAllPositions();
            ExpertRemove();
        }

        if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
            OpenOrderFound = true;
        }else if (FoundAntiPattern(1) && OrderSymbol() == Symbol() && OrderMagicNumber() == BotMagicNumber()) {
            Print("Found AntiPattern, deleting pending order OrderTicket(): ", OrderTicket());
            SelectedOrder = OrderDelete(OrderTicket());
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
    return OpenOrderFound;
}

bool AreSymbolsCorrelated(string SymbolOne, string SymbolTwo) {
    if ((StringContains(SymbolOne, "GBP") && StringContains(SymbolTwo, "GBP")) ||
        (StringContains(SymbolOne, "EUR") && StringContains(SymbolTwo, "EUR"))) {
        return true;
    }

    // missing improvement from last ahtodo, check all comments

    return false;
}

bool CompareTwinOrders(int OrderType, double OpenPrice,
    double StopLoss, double OrderLotsModulationFactor) {

    PreviousOrderTicket = OrderTicket();
    for (int order = OrdersTotal() - 1; order >= 0; order--) {
        if (!OrderSelect(order, SELECT_BY_POS, MODE_TRADES) ||
            !AreSymbolsCorrelated(OrderSymbol(), Symbol()) ||
            OrderType() != OrderType) {
            continue;
        }

        if (IsUnknownMagicNumber(OrderMagicNumber())) {
            continue;
        }

        // Shorter timeframes are prioritized over H4
        if (Period() == PERIOD_H4 && OrderMagicNumber() != MY_SCRIPT_ID_240) {
            continue;
        }

        double OldOrderLotsModulationFactor = NormalizeDouble(GetOrderLotsModulationFactor(
            OrderType(), OrderOpenPrice(), OrderSymbol()), 2);
        double NewOrderLotsModulationFactor = NormalizeDouble(OrderLotsModulationFactor, 2);

        int OldOrderStopLossPips = MathRound(MathAbs(OrderOpenPrice() - OrderStopLoss())
            / Pips(OrderSymbol()));
        int NewOrderStopLossPips = MathRound(MathAbs(OpenPrice - StopLoss) / Pips());

        // Better size setups
        if ((Period() != PERIOD_H4 && OrderMagicNumber() == MY_SCRIPT_ID_240) ||
            (OldOrderLotsModulationFactor < NewOrderLotsModulationFactor) ||
            (OldOrderLotsModulationFactor == NewOrderLotsModulationFactor &&
            OldOrderStopLossPips > NewOrderStopLossPips)) {

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
    for (order = OrdersTotal() - 1; order >= 0; order--) {
        if (!OrderSelect(order, SELECT_BY_POS, MODE_TRADES) ||
            !AreSymbolsCorrelated(OrderSymbol(), Symbol())) {
            continue;
        }

        if (OrderType() == OrderType || OrderType() == OP_BUY || OrderType() == OP_SELL) {
            Print("CompareTwinOrders: found better order with OrderTicket(): ", OrderTicket());
            PutNewOrder = false;
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);

    return PutNewOrder;
}

double OrderLotsCalculator(double OpenPrice, double StopLoss, double OrderLotsModulationFactor) {
    double YenConversionFactor = MarketInfo(Symbol(), MODE_TICKSIZE) / 0.00001;

    double StopLossDistance = MathAbs(OpenPrice - StopLoss)
        * MarketInfo(Symbol(), MODE_TICKVALUE) / YenConversionFactor;

    double AbsoluteRisk = AccountEquity() * PercentRisk / 100;
    double RawOrderLots = AbsoluteRisk / StopLossDistance / 100000;

    double OrderLots = 2 * NormalizeDouble(RawOrderLots * OrderLotsModulationFactor / 2, 2);

    if (OrderLots < 0.02) {
        OrderLots = 0.02;
    }

    return NormalizeDouble(OrderLots, 2);
}

double GetDrawdownFactor() {
    double DrawdownFactor = 1.0;

    if (GetGainsLastDaysThisSymbol(14) < 0) {
        DrawdownFactor *= 0.9;

        if (GetGainsLastDaysThisSymbol(21) < 0 || GetGainsLastDaysThisSymbol(28) < 0) {
            DrawdownFactor *= 0.9;
        }

        Print("Reducing size for DrawdownFactor: ", DrawdownFactor);
    }

    return DrawdownFactor;
}

double GetOrderLotsModulationFactor(int OrderType, double OpenPrice, string OrderSymbol) {
    double OrderLotsModulationFactor = 1.0;

    OrderLotsModulationFactor *= GetDrawdownFactor();

    if (IsMinorBankHoliday()) {
        Print("IsMinorBankHoliday(): reducing size");
        OrderLotsModulationFactor *= 0.8;
    }

    if (Period() != PERIOD_H4) {
        // Intraday Pivot for M30 and H1
        if (OpenPrice > GetPivotRS(OrderSymbol, PERIOD_D1, "R2") ||
            OpenPrice < GetPivotRS(OrderSymbol, PERIOD_D1, "S2")) {
            Print("The intraday pivots configuration is red");
            OrderLotsModulationFactor *= 0.0;
        }else if ((OpenPrice > GetPivotRS(OrderSymbol, PERIOD_D1, "R1") &&
            OpenPrice < GetPivotRS(OrderSymbol, PERIOD_D1, "R2")) ||
            (OpenPrice < GetPivotRS(OrderSymbol, PERIOD_D1, "S1") &&
            OpenPrice > GetPivotRS(OrderSymbol, PERIOD_D1, "S2"))) {
            Print("The intraday pivots configuration is yellow");
            OrderLotsModulationFactor *= 0.8;
        }

        // Daily Pivot for M30 and H1
        if (!(iCandle(I_high, OrderSymbol, PERIOD_D1, 0) > GetPivot(OrderSymbol, PERIOD_D1, 0) &&
            iCandle(I_low, OrderSymbol, PERIOD_D1, 0) < GetPivot(OrderSymbol, PERIOD_D1, 0))) {
            Print("The daily pivot is not tested");

            if (GetCurrentMarketValue() < GetPivot(OrderSymbol, PERIOD_D1, 0)) {
                if (OrderType == OP_BUYSTOP) {
                    OrderLotsModulationFactor *= 1.1;
                }
                if (OrderType == OP_SELLSTOP) {
                    OrderLotsModulationFactor *= 0.9;
                }
            } else {
                if (OrderType == OP_BUYSTOP) {
                    OrderLotsModulationFactor *= 0.9;
                }
                if (OrderType == OP_SELLSTOP) {
                    OrderLotsModulationFactor *= 1.1;
                }
            }
        }
    }

    // Pivots configuration
    if (GetPivot(OrderSymbol, PERIOD_D1, 0) > GetPivot(OrderSymbol, PERIOD_W1, 0) &&
        GetPivot(OrderSymbol, PERIOD_W1, 0) > GetPivot(OrderSymbol, PERIOD_MN1, 0)) {
        Print("The daily, weekly, and monthly pivots are in a bull configuration");

        if (OrderType == OP_BUYSTOP) {
            OrderLotsModulationFactor *= 1.1;
        }
        if (OrderType == OP_SELLSTOP) {
            OrderLotsModulationFactor *= 0.9;
        }
    }

    if (GetPivot(OrderSymbol, PERIOD_D1, 0) < GetPivot(OrderSymbol, PERIOD_W1, 0) &&
        GetPivot(OrderSymbol, PERIOD_W1, 0) < GetPivot(OrderSymbol, PERIOD_MN1, 0)) {
        Print("The daily, weekly, and monthly pivots are in a bear configuration");

        if (OrderType == OP_BUYSTOP) {
            OrderLotsModulationFactor *= 0.9;
        }
        if (OrderType == OP_SELLSTOP) {
            OrderLotsModulationFactor *= 1.1;
        }
    }

    return OrderLotsModulationFactor;
}

bool VerifyGreenTimeWindow(int OrderType) {
    bool IsGreenTimeWindow = true;
    int TimeWindowCandles = MathRound(OrderCandlesDuration / PeriodMultiplicationFactor());

    PreviousOrderTicket = OrderTicket();
    for (int order = 0; order < OrdersHistoryTotal(); order++) {
        if (!OrderSelect(order, SELECT_BY_POS, MODE_HISTORY) ||
            IsUnknownMagicNumber(OrderMagicNumber()) ||
            !AreSymbolsCorrelated(OrderSymbol(), Symbol()) ||
            (OrderType() != OP_BUY && OrderType() != OP_SELL)) {
            continue;
        }

        if ((OrderCloseTime() > TimeCurrent() - 60 * Period()) ||
            ((OrderCloseTime() > TimeCurrent() - 60 * TimeWindowCandles * Period()) &&
            ((OrderType() == OP_BUY && OrderType == OP_BUYSTOP) ||
            (OrderType() == OP_SELL && OrderType == OP_SELLSTOP)))) {
            IsGreenTimeWindow = false;
            break;
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
    return IsGreenTimeWindow;
}

int GetOrderTypeFromSetups(int TimeIndex) {
    for (int t = 1; t < TimeIndex + 1; t++) {
        if (FoundAntiPattern(t)) {
            Print("AntiPattern found at Time: ", TimeToStr(Time[TimeIndex]));
            return -1;
        }
    }

    if (!IsSellPattern(TimeIndex) && !IsBuyPattern(TimeIndex)) {
        Print("No patterns found at Time: ", TimeToStr(Time[TimeIndex]));
        return -1;
    }

    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        if (!IsTrendLineGoodForPendingOrder(ObjectName(i), TimeIndex)) {
            continue;
        }

        if (IsDebug) {
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

        if (IsSellPattern(TimeIndex) && MathAbs(iExtreme(TimeIndex, "Min") -
            ObjectGetValueByShift(ObjectName(i), TimeIndex)) < 3 * Pips()) {
            Print("Setup for OP_SELLSTOP at Time: ", TimeToStr(Time[TimeIndex]),
                " for TrendLine: ", ObjectName(i));
            return OP_SELLSTOP;
        }

        if (IsBuyPattern(TimeIndex) && MathAbs(iExtreme(TimeIndex, "Max") -
            ObjectGetValueByShift(ObjectName(i), TimeIndex)) < 3 * Pips()) {
            Print("Setup for OP_BUYSTOP at Time: ", TimeToStr(Time[TimeIndex]),
                " for TrendLine: ", ObjectName(i));
            return OP_BUYSTOP;
        }
    }

    Print("No setups found at Time: ", TimeToStr(Time[TimeIndex]));
    return -1;
}

void PutPendingOrder() {
    DeleteCorrelatedPendingOrders();

    PutPendingOrder(1);

    // At the opening of the market, search for patterns in the past
    if (Hour() == MarketOpenHour() && Minute() < 30 && TimeSeconds(TimeCurrent()) > 30) {
        for (int time = 1; time < OrderCandlesDuration + 1; time++) {
            PutPendingOrder(time);
        }
    }
}

void PutPendingOrder(int StartIndexForOrder) {
    if (StartIndexForOrder < 1) {
        return;
    }

    if (TimeSeconds(TimeCurrent()) < 10) {
        return;
    }

    if (Minute() == 0 || Minute() == 59 || Minute() == 30 || Minute() == 29) {
        return;
    }

    if (Period() == PERIOD_M30) {
        HardSleep(2);
    }
    if (Period() == PERIOD_H1) {
        HardSleep(10);
    }
    if (Period() == PERIOD_H4) {
        HardSleep(18);
    }

    if (StringContains(Symbol(), "CHF") || StringContains(Symbol(), "JPY")) {
        HardSleep(2);
    }

    int OrderType = GetOrderTypeFromSetups(StartIndexForOrder);

    int OrderSign = 0;
    string Discriminator, AntiDiscriminator;

    double Spread = GetMarketSpread();
    double SpreadOpenPrice = 0, SpreadStopLoss = 0;

    if (OrderType == OP_BUYSTOP) {
        OrderSign = 1;
        Discriminator = "Max";
        AntiDiscriminator = "Min";
        SpreadOpenPrice = Spread;
    }else if (OrderType == OP_SELLSTOP) {
        OrderSign = -1;
        Discriminator = "Min";
        AntiDiscriminator = "Max";
        SpreadStopLoss = Spread;
    } else {
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

    if (OrderLotsModulationFactor == 0) {
        Print("OrderLotsModulationFactor is zero");
        return;
    }

    if (!VerifyGreenTimeWindow(OrderType)) {
        Print("VerifyGreenTimeWindow: recent order detected");
        return;
    }

    if (!CompareTwinOrders(OrderType, OpenPrice, StopLoss, OrderLotsModulationFactor)) {
        return;
    }

    Print("Putting a pending order: ", OrderType);

    int OrderTicket = 0;
    int ExpirationTime = Time[0] + (OrderCandlesDuration + 1 - StartIndexForOrder) * Period() * 60;
    string OrderComment = StringConcatenate(
         "P", Period(),
        " M", NormalizeDouble(OrderLotsModulationFactor, 2),
        " R", NormalizeDouble(TakeProfitFactor, 1),
        " S", MathRound(StopLossPips / Pips()));

    while (true) { // pericoloso
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

        if (OrderTicket > 0) {
            SelectedOrder = OrderSelect(OrderTicket, SELECT_BY_TICKET);
            OrderPrint();
            break;
        } else {
            if (GetLastError() == 132 || GetLastError() == 136) {
                Print("Got error 132 or 136 while putting pending order, "
                    "sleeping before retrying");
                Sleep(10);
            } else {
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

void OrderTrailing() {
    PreviousOrderTicket = OrderTicket();
    for (int order = OrdersTotal() - 1; order >= 0; order--) {
        if (!OrderSelect(order, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderSymbol() != Symbol() || OrderMagicNumber() != BotMagicNumber()) {
            continue;
        }

        if (OrderType() != OP_BUY && OrderType() != OP_SELL) {
            continue;
        }

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
        if (CurrentExtremeToOpenDistance > BreakEvenDistance && OrderSign > 0) {
            StopLoss = MathMax(StopLoss, BreakEvenStopLoss);
        }
        if (CurrentExtremeToOpenDistance < BreakEvenDistance && OrderSign < 0) {
            StopLoss = MathMin(StopLoss, BreakEvenStopLoss);
        }

        double TrailerInitialDistance = 2.0;
        double TrailerPercent = 0.0;

        double Trailer = TrailerInitialDistance - TrailerPercent
            * CurrentExtremeToOpenDistance / ProfitToOpenDistance;

        double InitialStopLossDistance = ProfitToOpenDistance / GetTakeProfitFactor();
        double TrailerStopLoss = CurrentExtreme - InitialStopLossDistance * Trailer;

        // Trailing StopLoss
        if (OrderSign > 0) {
            StopLoss = MathMax(StopLoss, TrailerStopLoss);
        } else {
            StopLoss = MathMin(StopLoss, TrailerStopLoss);
        }


        // Modify order if values changed
        if (MathAbs(TakeProfit - OrderTakeProfit()) > Pips() || MathAbs(StopLoss - OrderStopLoss()) > Pips()) {
            Print("OrderTrailing: modifying the existing order: ", OrderTicket());

            bool OrderModified = OrderModify(
                OrderTicket(),
                NormalizeDouble(OrderOpenPrice(), Digits),
                NormalizeDouble(StopLoss, Digits),
                NormalizeDouble(TakeProfit, Digits),
                0,
                Blue);

            if (OrderModified) {
                Print("Order modified successfully");
            } else {
                Print("OrderModify error ", GetLastError());
            }

            Print("OrderTicket(): ", OrderTicket());
            Print("OrderType(): ", OrderType());
            Print("OrderOpenPrice(): ", NormalizeDouble(OrderOpenPrice(), Digits));
            Print("CurrentMarketValue: ", GetCurrentMarketValue());
            Print("StopLoss: ", NormalizeDouble(StopLoss, Digits));
            Print("TakeProfit: ", NormalizeDouble(TakeProfit, Digits));
            Print("OrderExpiration(): ", OrderExpiration());
        } else {
            Print("OrderTrailing: existing order not modified: ", OrderTicket());
        }

        // Close half position when BreakEven has been reached
        if (PositionSplit && StringContains(OrderComment(), StringConcatenate("P", Period())) &&
            NormalizeDouble(MathAbs(OrderOpenPrice() - OrderStopLoss()), Digits) ==
            NormalizeDouble(GetBreakEvenPips() * Pips(), Digits)) { // estrarre ultima condizione in variabile
            SelectedOrder = OrderClose(OrderTicket(), OrderLots() / 2, OrderClosePrice(), 3);
        }

        DeleteCorrelatedPendingOrdersWhenOrderEntered(OrderType());
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
}

double GetTakeProfitFactor() {
    double TakeProfitFactor = BaseTakeProfitFactor;

    if (GetGainsLastDaysThisSymbol(14) < 0) {
        TakeProfitFactor -= (BaseTakeProfitFactor + 1) / 10;
    }
    if (GetGainsLastDaysThisSymbol(21) < 0) {
        TakeProfitFactor -= (BaseTakeProfitFactor + 1) / 10;
    }
    if (GetGainsLastDaysThisSymbol(28) < 0) {
        TakeProfitFactor -= (BaseTakeProfitFactor + 1) / 10;
    }

    /*
    double MinTakeProfitPips = 26 * PeriodMultiplicationFactor() * Pips();
    double MaxTakeProfitPips = 60 * PeriodMultiplicationFactor() * Pips();
    double StopLossPipsModule = MathAbs(StopLossPips);

    if (StopLossPipsModule * TakeProfitFactor < MinTakeProfitPips) {
        TakeProfitFactor = MinTakeProfitPips / StopLossPipsModule;
    }
    if (StopLossPipsModule * TakeProfitFactor > MaxTakeProfitPips) {
        TakeProfitFactor = MaxTakeProfitPips / StopLossPipsModule;
    }
    */

    if (!PositionSplit && TakeProfitFactor < 1) {
        TakeProfitFactor = 1;
    }
    if (PositionSplit && TakeProfitFactor < 2) {
        TakeProfitFactor = 2;
    }

    return NormalizeDouble(TakeProfitFactor, 1);
}

double GetGainsLastDaysThisSymbol(int Days) {
    double AbsoluteRisk = AccountEquity() * PercentRisk / 100;
    double TotalGains = AbsoluteRisk / 10;

    PreviousOrderTicket = OrderTicket();
    for (int order = 0; order < OrdersHistoryTotal(); order++) {
        if (!OrderSelect(order, SELECT_BY_POS, MODE_HISTORY) || OrderProfit() == 0 ||
            OrderCloseTime() < GetTimeAtMidnight() - (Days + 1) * 86400 ||
            OrderSymbol() != Symbol() || IsUnknownMagicNumber(OrderMagicNumber())) {
            continue;
        }

        TotalGains += OrderProfit();
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);

    // Print("TotalGains of the last ", Days, " days: ", TotalGains);
    return TotalGains;
}

bool LossLimiterEnabled() {
    bool IsLossLimiterEnabled = false;
    int Days = 5;
    double MaximumPercentLoss = 5;
    double TotalLosses = 0;

    PreviousOrderTicket = OrderTicket();
    for (int order = 0; order < OrdersHistoryTotal(); order++) {
        if (!OrderSelect(order, SELECT_BY_POS, MODE_HISTORY) || OrderProfit() == 0 ||
            OrderCloseTime() < GetTimeAtMidnight() - (Days + 1) * 86400 || IsUnknownMagicNumber(OrderMagicNumber())) {
            continue;
        }

        TotalLosses -= OrderProfit();

        if (TotalLosses >= AccountEquity() * MaximumPercentLoss / 100) {
            Print("Loss Limiter Enabled, TotalLosses: ", TotalLosses);
            CloseAllPositions();
            IsLossLimiterEnabled = true;
            break;
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);

    // aggiungere alert
    return IsLossLimiterEnabled;
}

void DeleteCorrelatedPendingOrdersWhenOrderEntered(int OrderType) {
    PreviousOrderTicket = OrderTicket();
    for (int order = OrdersTotal() - 1; order >= 0; order--) {
        if (!OrderSelect(order, SELECT_BY_POS, MODE_TRADES) || !AreSymbolsCorrelated(OrderSymbol(), Symbol())) {
            continue;
        }

        if (IsUnknownMagicNumber(OrderMagicNumber())) {
            continue;
        }

        if (OrderSymbol() == Symbol() && OrderType() != OP_BUY && OrderType() != OP_SELL) {
            SelectedOrder = OrderDelete(OrderTicket());
        }

        if (OrderSymbol() != Symbol() && ((OrderType() == OP_BUYSTOP && OrderType == OP_BUY) ||
            (OrderType() == OP_SELLSTOP && OrderType == OP_SELL))) {
            SelectedOrder = OrderDelete(OrderTicket());
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
}

void DeleteCorrelatedPendingOrders() {
    int CorrelatedBuyStop = 0, CorrelatedSellStop = 0;

    PreviousOrderTicket = OrderTicket();
    for (int order = OrdersTotal() - 1; order >= 0; order--) {
        if (!OrderSelect(order, SELECT_BY_POS, MODE_TRADES) || !AreSymbolsCorrelated(OrderSymbol(), Symbol())) {
            continue;
        }

        if (OrderType() == OP_BUYSTOP) {
            CorrelatedBuyStop++;
        }
        if (OrderType() == OP_SELLSTOP) {
            CorrelatedSellStop++;
        }

        if (CorrelatedBuyStop > 1) {
            SelectedOrder = OrderDelete(OrderTicket());
            CorrelatedBuyStop--;
        }
        if (CorrelatedSellStop > 1) {
            SelectedOrder = OrderDelete(OrderTicket());
            CorrelatedSellStop--;
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
}

void DeletePendingOrdersThisSymbolThisPeriod() {
    PreviousOrderTicket = OrderTicket();
    for (int order = OrdersTotal() - 1; order >= 0; order--) {
        if (!OrderSelect(order, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }

        if (OrderSymbol() != Symbol() || OrderMagicNumber() != BotMagicNumber()) {
            continue;
        }

        if (OrderType() != OP_BUY && OrderType() != OP_SELL) {
            SelectedOrder = OrderDelete(OrderTicket());
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
}

void CloseAllPositions() {
    Print("CloseAllPositions() invoked");

    PreviousOrderTicket = OrderTicket();
    for (int order = OrdersTotal() - 1; order >= 0; order--) {
        if (!OrderSelect(order, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }

        if (OrderSymbol() != Symbol() || OrderMagicNumber() != BotMagicNumber()) {
            continue;
        }

        if (OrderType() != OP_BUY && OrderType() != OP_SELL) {
            SelectedOrder = OrderDelete(OrderTicket());
        } else {
            SelectedOrder = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3);
        }
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);
}

// dentro OnTick, ma non serve
//    if (IsUnknownMagicNumber(BotMagicNumber())) {
//        return;
//    }
