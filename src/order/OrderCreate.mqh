#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../market/Holiday.mqh"
#include "../market/Market.mqh"
#include "../order/OrderManage.mqh"
#include "../pattern/Pattern.mqh"
#include "../pivot/Pivot.mqh"
#include "../trendline/TrendLine.mqh"


class OrderCreate {
    public:
        ~OrderCreate();
        void newOrder();

    protected:
        void createNewOrder(int);

        int calculateOrderTypeFromSetups(int);
        int morningLookBackCandles(int);
        double calculateSizeFactor(int, double, string);
        double calculateOrderLots(double, double, double);

    private:
        static const int orderCandlesDuration_;
        static const double takeProfitFactor_;
        static const double trandLineSetupMaxDistance_;

        static datetime antiPatternTimeStamp_;
        static datetime foundPatternTimeStamp_;
        static datetime sellSetupTimeStamp_;
        static datetime buySetupTimeStamp_;
        static datetime noSetupTimeStamp_;
};

const int OrderCreate::orderCandlesDuration_ = 6;
const double OrderCreate::takeProfitFactor_ = 3;
const double OrderCreate::trandLineSetupMaxDistance_ = 3 * Pips();

datetime OrderCreate::antiPatternTimeStamp_ = -1;
datetime OrderCreate::foundPatternTimeStamp_ = -1;
datetime OrderCreate::sellSetupTimeStamp_ = -1;
datetime OrderCreate::buySetupTimeStamp_ = -1;
datetime OrderCreate::noSetupTimeStamp_ = -1;

OrderCreate::~OrderCreate() {
    antiPatternTimeStamp_ = -1;
    foundPatternTimeStamp_ = -1;
    sellSetupTimeStamp_ = -1;
    buySetupTimeStamp_ = -1;
    noSetupTimeStamp_ = -1;
}

/**
 * Checks if some preconditions are met, and then tries to create new orders.
 */
void OrderCreate::newOrder() {
    Market market;

    if (market.isMarketCloseNoPendingTimeWindow()) {
        return;
    }
    if (!IsTradeAllowed()) {
        return;
    }
    if (Minute() == 0 || Minute() == 59 || Minute() == 30 || Minute() == 29) { /// extract in new class?
        return;
    }
    OrderManage orderManage;
    if (orderManage.areThereRecentOrders((datetime) (TimeCurrent() - 60 * Period() * /// comunque non mi piace cosi passare sto parametro lunghissimo
        MathRound(orderCandlesDuration_ / PeriodFactor())))) { /// maybe not here, refactor preconditions in handler
        return;
    }

    if (!IsFirstRankSymbolFamily()) {
        Sleep(300);
    }
    if (Period() == PERIOD_H1) { /// necessario? abbastanza tempo?? non qui ma ANCORA prima
        Sleep(300);
    }
    if (Period() == PERIOD_H4) {
        Sleep(500);
    }

    createNewOrder(1);

    // At the opening of the market, search for patterns in the past
    if (market.isMarketOpenLookBackTimeWindow()) {
        for(int time = 2; time < morningLookBackCandles() + 2; time++){
            createNewOrder(time);
        }
    }
}

/**
 * Creates a new pending order.
 */
void OrderCreate::createNewOrder(int startIndexForOrder) {
    if (startIndexForOrder < 1) {
        ThrowException(__FUNCTION__, StringConcatenate("Unprocessable startIndexForOrder: ", startIndexForOrder));
        return;
    }

    const int orderType = calculateOrderTypeFromSetups(startIndexForOrder);

    if (orderType != OP_BUYSTOP && orderType != OP_SELLSTOP) {
        return;
    }

    const bool isBuy = (orderType == OP_BUYSTOP);

    const Discriminator discriminator = isBuy ? Max : Min;
    const Discriminator antiDiscriminator = !isBuy ? Max : Min;

    const double spread = GetMarketSpread();
    const double spreadAsk = isBuy ? spread : 0;
    const double spreadBid = !isBuy ? spread : 0;

    const double openPrice = iExtreme(discriminator, startIndexForOrder) + discriminator * (1 + spreadAsk) * Pips();
    const double stopLoss = iExtreme(antiDiscriminator, startIndexForOrder) - discriminator * (1 + spreadBid) * Pips();

    const double stopLossSize = MathAbs(openPrice - stopLoss);
    const double takeProfitFactor = takeProfitFactor_;
    const double takeProfit = openPrice + discriminator * stopLossSize * takeProfitFactor;

    const double sizeFactor = calculateSizeFactor(orderType, openPrice, Symbol());
    const double orderLots = calculateOrderLots(openPrice, stopLoss, sizeFactor);

    if (sizeFactor == 0) {
        return;
    }
    OrderManage orderManage;
    if (orderManage.areThereBetterOrders(orderType, stopLossSize, sizeFactor)) {
        return;
    }

    const int magicNumber = BotMagicNumber();
    const datetime expirationTime = Time[0] + (orderCandlesDuration_ + 1 - startIndexForOrder) * Period() * 60;
    const string orderComment = orderManage.buildOrderComment(sizeFactor, takeProfitFactor, stopLossSize / Pips()); /// change later /Pips()? also tests betterOrders..

    ResetLastError();

    const int orderTicket = OrderSend(
        Symbol(),
        orderType,
        orderLots,
        NormalizeDouble(openPrice, Digits),
        3,
        NormalizeDouble(stopLoss, Digits),
        NormalizeDouble(takeProfit, Digits),
        orderComment,
        magicNumber,
        expirationTime,
        Blue
    );

    const int lastError = GetLastError();
    if (lastError != 0) {
        ThrowException(__FUNCTION__, StringConcatenate(
            "OrderSend error: ", lastError, " for orderTicket: ", orderTicket));
    }

    if (orderTicket > 0) {
        const int previouslySelectedOrder = OrderTicket();
        const int selectedOrder = OrderSelect(orderTicket, SELECT_BY_TICKET);

        Print("New order created: ", orderTicket);
        OrderPrint();

        if (orderType != OrderType() ||
            orderLots != OrderLots() ||
            orderComment != OrderComment() ||
            magicNumber != OrderMagicNumber() ||
            expirationTime != OrderExpiration()) {

            Print("orderType: ", orderType);
            Print("orderLots: ", orderLots);
            Print("orderComment: ", orderComment);
            Print("magicNumber: ", magicNumber);
            Print("expirationTime: ", TimeToStr(expirationTime));
            ThrowException(__FUNCTION__, StringConcatenate(
                "Mismatching information in newly created order: ", orderTicket));
        }

        if (previouslySelectedOrder != 0 && !OrderSelect(previouslySelectedOrder, SELECT_BY_TICKET)) {
            ThrowException(__FUNCTION__, StringConcatenate(
                "Could not select back previous order: ", previouslySelectedOrder));
        }
    }
}

/**
 * Checks if there are any valid setups, and in that case returns the orderType.
 */
int OrderCreate::calculateOrderTypeFromSetups(int timeIndex) {
    if (timeIndex < 1) {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Unprocessable timeIndex: ", timeIndex));
    }

    Pattern pattern;
    for (int t = 1; t < timeIndex + 1; t++) {
        if (pattern.isAntiPattern(t)) {
            antiPatternTimeStamp_ = PrintTimer(antiPatternTimeStamp_, StringConcatenate(
                "AntiPattern found at time: ", TimeToStr(Time[t])));
            return -1;
        }
    }

    if (!pattern.isSellPattern(timeIndex) && !pattern.isBuyPattern(timeIndex)) {
        foundPatternTimeStamp_ = PrintTimer(foundPatternTimeStamp_, StringConcatenate(
            "No patterns found at time: ", TimeToStr(Time[timeIndex])));
        return -1;
    }

    TrendLine trendLine;

    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        if (!trendLine.isGoodTrendLineFromName(ObjectName(i), timeIndex)) {
            continue;
        }

        const double trendLineSetupValue = ObjectGetValueByShift(ObjectName(i), timeIndex);
        const double trandLineDistanceFromMin = MathAbs(iExtreme(Min, timeIndex) - trendLineSetupValue);
        const double trandLineDistanceFromMax = MathAbs(iExtreme(Max, timeIndex) - trendLineSetupValue);

        if (pattern.isSellPattern(timeIndex) && trandLineDistanceFromMin < trandLineSetupMaxDistance_) {
            sellSetupTimeStamp_ = PrintTimer(sellSetupTimeStamp_, StringConcatenate(
                "Found OP_SELLSTOP setup at Time: ", TimeToStr(Time[timeIndex]), " for TrendLine: ", ObjectName(i)));
            return OP_SELLSTOP;
        }

        if (pattern.isBuyPattern(timeIndex) && trandLineDistanceFromMax < trandLineSetupMaxDistance_) {
            buySetupTimeStamp_ = PrintTimer(buySetupTimeStamp_, StringConcatenate(
                "Found OP_BUYSTOP setup at Time: ", TimeToStr(Time[timeIndex]), " for TrendLine: ", ObjectName(i)));
            return OP_BUYSTOP;
        }
    }

    noSetupTimeStamp_ = PrintTimer(noSetupTimeStamp_, StringConcatenate(
        "No setups found at Time: ", TimeToStr(Time[timeIndex])));
    return -1;
}

/**
 * Calculates the size modulation factor from pivot and holiday setups.
 */
double OrderCreate::calculateSizeFactor(int orderType, double openPrice, string orderSymbol) {
    if (orderType != OP_BUYSTOP && orderType != OP_SELLSTOP) {
        return ThrowException(0, __FUNCTION__, StringConcatenate("Unsupported orderType:", orderType));
    }
    if (openPrice <= 0) {
        return ThrowException(0, __FUNCTION__, StringConcatenate("Wrong openPrice:", openPrice));
    }
    if (!SymbolExists(orderSymbol)) {
        return ThrowException(0, __FUNCTION__, "Unknown symbol");
    }

    double sizeFactor = 1.0;

    Holiday holiday;
    Pivot pivot;

    if (holiday.isMinorBankHoliday()) {
        sizeFactor *= 0.8;
    }

    if (Period() != PERIOD_H4) {
        // Intraday Pivot for M30 and H1
        if (openPrice > pivot.getPivotRS(orderSymbol, D1, R2) ||
            openPrice < pivot.getPivotRS(orderSymbol, D1, S2)) {
            sizeFactor *= 0.0; // red configuration
        }
        if ((openPrice > pivot.getPivotRS(orderSymbol, D1, R1) &&
            openPrice < pivot.getPivotRS(orderSymbol, D1, R2)) ||
            (openPrice < pivot.getPivotRS(orderSymbol, D1, S1) &&
            openPrice > pivot.getPivotRS(orderSymbol, D1, S2))) {
            sizeFactor *= 0.8; // yellow configuration
        }

        // Daily Pivot for M30 and H1
        if (iCandle(I_high, orderSymbol, D1, 0) < pivot.getPivot(orderSymbol, D1, 0) ||
            iCandle(I_low, orderSymbol, D1, 0) > pivot.getPivot(orderSymbol, D1, 0)) {

            if (GetAsk(orderSymbol) < pivot.getPivot(orderSymbol, D1, 0)) {
                if (orderType == OP_BUYSTOP) {
                    sizeFactor *= 1.1;
                }
                if (orderType == OP_SELLSTOP) {
                    sizeFactor *= 0.9;
                }
            } else {
                if (orderType == OP_BUYSTOP) {
                    sizeFactor *= 0.9;
                }
                if (orderType == OP_SELLSTOP) {
                    sizeFactor *= 1.1;
                }
            }
        }
    }

    // Pivots configurations
    if (pivot.getPivot(orderSymbol, D1, 0) > pivot.getPivot(orderSymbol, W1, 0) &&
        pivot.getPivot(orderSymbol, W1, 0) > pivot.getPivot(orderSymbol, MN1, 0)) {
        if (orderType == OP_BUYSTOP) {
            sizeFactor *= 1.1;
        }
        if (orderType == OP_SELLSTOP) {
            sizeFactor *= 0.9;
        }
    }
    if (pivot.getPivot(orderSymbol, D1, 0) < pivot.getPivot(orderSymbol, W1, 0) &&
        pivot.getPivot(orderSymbol, W1, 0) < pivot.getPivot(orderSymbol, MN1, 0)) {
        if (orderType == OP_BUYSTOP) {
            sizeFactor *= 0.9;
        }
        if (orderType == OP_SELLSTOP) {
            sizeFactor *= 1.1;
        }
    }

    return NormalizeDouble(sizeFactor, 1);
}

/**
 * Returns the numbers of candles to look back for in the morning.
 */
int OrderCreate::morningLookBackCandles(int period = NULL) {
    if (period == NULL) {
        period = Period();
    }

    if (period == PERIOD_H4) {
        return 1;
    } else if (period == PERIOD_H1) {
        return 1;
    } else if (period == PERIOD_M30) {
        return 2;
    } else {
        return 0;
    }
}

/**
 * Calculates the size for a new order, and makes sure that it's divisible by 2,
 * so that the position can be later split.
 */
double OrderCreate::calculateOrderLots(double openPrice, double stopLoss, double sizeFactor) {
    if (sizeFactor == 0) {
        return 0;
    }

    const double absoluteRisk = (PERCENT_RISK / 100) * AccountEquity() / MarketInfo(Symbol(), MODE_TICKVALUE);
    const double stopLossTicks = MathAbs(openPrice - stopLoss) / MarketInfo(Symbol(), MODE_TICKSIZE);
    const double rawOrderLots = absoluteRisk / stopLossTicks;

    double orderLots = 2 * NormalizeDouble(rawOrderLots * sizeFactor / 2, 2);

    orderLots = MathMax(orderLots, 0.02);

    return NormalizeDouble(orderLots, 2);
}
