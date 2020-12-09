
int GetBreakEvenPips() {
    if (Period() == PERIOD_H4) {
        return 15;
    }

    return 6;
}

bool AreSymbolsCorrelated(string SymbolOne, string SymbolTwo) { // replace with SymbolFamily
    if ((StringContains(SymbolOne, "GBP") && StringContains(SymbolTwo, "GBP")) ||
        (StringContains(SymbolOne, "EUR") && StringContains(SymbolTwo, "EUR"))) {
        return true;
    }

    // missing improvement from last ahtodo, check all comments

    return false;
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



void OrderTrailing() {
    PreviousOrderTicket = OrderTicket();
    for (int order = OrdersTotal() - 1; order >= 0; order--) { // quello dentro il for puo essere una funzione separata dentro manageOrder
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
            OrderCloseTime() < GetDate() - (Days + 1) * 86400 ||
            OrderSymbol() != Symbol() || IsUnknownMagicNumber(OrderMagicNumber())) {
            continue;
        }

        TotalGains += OrderProfit();
    }
    SelectedOrder = OrderSelect(PreviousOrderTicket, SELECT_BY_TICKET);

    // Print("TotalGains of the last ", Days, " days: ", TotalGains);
    return TotalGains;
}
