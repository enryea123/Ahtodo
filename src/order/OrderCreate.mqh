#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "../market/Holiday.mqh"
#include "../market/Market.mqh"
#include "../order/Order.mqh"
#include "../order/OrderFilter.mqh"
#include "../order/OrderFind.mqh"
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
        bool areThereBetterOrders(int, double, double);
        bool areThereRecentOrders();
        int calculateOrderTypeFromSetups(int);
        int morningLookBackCandles(int);
        double calculateSizeFactor(int, double, string);
        double calculateOrderLots(double, double, double);
        string buildOrderComment(double, double, double);

    private:
        static const int betterSetupBufferPips_;
        static const int maxCommentLength_;
        static const int orderCandlesDuration_;
        static const double takeProfitFactor_;
        static const double trandLineSetupMaxDistance_;

        static datetime antiPatternTimeStamp_;
        static datetime foundPatternTimeStamp_;
        static datetime sellSetupTimeStamp_;
        static datetime buySetupTimeStamp_;
        static datetime noSetupsTimeStamp_;
};

const int OrderCreate::betterSetupBufferPips_ = 2;
const int OrderCreate::maxCommentLength_ = 20;
const int OrderCreate::orderCandlesDuration_ = 6;
const double OrderCreate::takeProfitFactor_ = 3;
const double OrderCreate::trandLineSetupMaxDistance_ = 3 * Pips();

datetime OrderCreate::antiPatternTimeStamp_ = -1;
datetime OrderCreate::foundPatternTimeStamp_ = -1;
datetime OrderCreate::sellSetupTimeStamp_ = -1;
datetime OrderCreate::buySetupTimeStamp_ = -1;
datetime OrderCreate::noSetupsTimeStamp_ = -1;

OrderCreate::~OrderCreate() {
    antiPatternTimeStamp_ = -1;
    foundPatternTimeStamp_ = -1;
    sellSetupTimeStamp_ = -1;
    buySetupTimeStamp_ = -1;
    noSetupsTimeStamp_ = -1;
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
    if (areThereRecentOrders()) {
        return;
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
    if (!areThereBetterOrders(orderType, stopLossSize, sizeFactor)) {
        return;
    }

    const int magicNumber = BotMagicNumber();
    const datetime expirationTime = Time[0] + (orderCandlesDuration_ + 1 - startIndexForOrder) * Period() * 60;
    const string orderComment = buildOrderComment(sizeFactor, takeProfitFactor, stopLossSize);

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
            ThrowException(__FUNCTION__, "Could not select back previous order: ", previouslySelectedOrder);
        }
    }
}

/**
 * Creates the comment for a new pending order, and makes sure it doesn't exceed the maximum length.
 */
string OrderCreate::buildOrderComment(double sizeFactor, double takeProfitFactor, double stopLossSize) {
    const string comment = StringConcatenate(
         "P", Period(),
        " M", NormalizeDouble(sizeFactor, 1),
        " R", NormalizeDouble(takeProfitFactor, 1),
        " S", MathRound(stopLossSize / Pips())
    );

    if (StringLen(comment) > maxCommentLength_) {
        return ThrowException(StringSubstr(comment, 0, maxCommentLength_), __FUNCTION__,
            StringConcatenate("Order comment longer than: ", maxCommentLength_));
    }

    return comment;
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
            antiPatternTimeStamp_ = PrintTimer(antiPatternTimeStamp_,
                "AntiPattern found at time: ", TimeToStr(Time[t]));
            return -1;
        }
    }

    if (!pattern.isSellPattern(timeIndex) && !pattern.isBuyPattern(timeIndex)) {
        foundPatternTimeStamp_ = PrintTimer(foundPatternTimeStamp_,
            "No patterns found at time: ", TimeToStr(Time[timeIndex]));
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
            sellSetupTimeStamp_ = PrintTimer(sellSetupTimeStamp_,
                "Found OP_SELLSTOP setup at Time: ", TimeToStr(Time[timeIndex]), " for TrendLine: ", ObjectName(i));
            return OP_SELLSTOP;
        }

        if (pattern.isBuyPattern(timeIndex) && trandLineDistanceFromMax < trandLineSetupMaxDistance_) {
            buySetupTimeStamp_ = PrintTimer(buySetupTimeStamp_,
                "Found OP_BUYSTOP setup at Time: ", TimeToStr(Time[timeIndex]), " for TrendLine: ", ObjectName(i));
            return OP_BUYSTOP;
        }
    }

    noSetupsTimeStamp_ = PrintTimer(noSetupsTimeStamp_, "No setups found at Time: ", TimeToStr(Time[timeIndex]));
    return -1;
}

/**
 * Checks if there have been any recent correlated open orders, so that it can be waited before placing new ones.
 */
bool OrderCreate::areThereRecentOrders() { /// qui o OrderManage? Meglio #2? o orderHandle?
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily());
    orderFilter.type.add(OP_BUY, OP_SELL);

    orderFilter.closeTime.setFilterType(Greater);
    orderFilter.closeTime.add(TimeCurrent() - 60 * Period() *
        MathRound(orderCandlesDuration_ / PeriodMultiplicationFactor()));

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter, MODE_HISTORY);

    if (ArraySize(orders) > 0) {
        return true;
    }

    return false;
}

/**
 * Checks if there are other pending orders. In case they are with worst setups it deletes them.
 */
bool OrderCreate::areThereBetterOrders(int orderType, double stopLossSize, double sizeFactor) {
    if (!IsFirstRankSymbolFamily()) {
        Sleep(500);
    }
    if (Period() == PERIOD_H1) { /// necessario? abbastanza tempo??
        Sleep(500);
    }
    if (Period() == PERIOD_H4) {
        Sleep(1000);
    }

    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily());
    orderFilter.type.add(orderType);

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter);

    if (ArraySize(orders) > 0) {
        OrderManage orderManage;

        for (int order = 0; order < ArraySize(orders); order++) {
            if (Period() == PERIOD_H4 && orders[order].period != PERIOD_H4) {
                // Shorter timeframes are prioritized over H4
                continue;
            }

            const double openPrice = orders[order].openPrice;
            const double stopLoss = orders[order].stopLoss;
            const string symbol = orders[order].symbol;

            const double oldSizeFactor = calculateSizeFactor(orderType, openPrice, symbol);
            const int newStopLossPips = MathRound(stopLossSize / Pips());
            const int oldStopLossPips = MathRound(MathAbs(openPrice - stopLoss) / Pips(symbol));

            // Not accounting for PeriodMultiplicationFactor()
            const bool isOldStopLossBigger = (oldStopLossPips - newStopLossPips > betterSetupBufferPips_);

            if (oldSizeFactor < sizeFactor || (oldSizeFactor == sizeFactor && isOldStopLossBigger)) {
                orderManage.deleteSingleOrder(orders[order]);
            }
        }
    }

    orderFilter.type.add(OP_BUY, OP_SELL);
    ArrayFree(orders);
    orderFind.getFilteredOrdersList(orders, orderFilter);

    if (ArraySize(orders) > 0) {
        return false;
    }

    return true;
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

            if (MarketInfo(orderSymbol, MODE_ASK) < pivot.getPivot(orderSymbol, D1, 0)) {
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
