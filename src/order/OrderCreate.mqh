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

        bool areThereRecentOrders(datetime);
        bool areThereBetterOrders(string, int, double, double);

        int calculateOrderTypeFromSetups(int);
        int morningLookBackCandles(int);
        double calculateSizeFactor(int, double, string);
        double calculateOrderLots(double, double);

        string buildOrderComment(int, double, double, int);
        double getSizeFactorFromComment(string);

    protected:
        OrderFind orderFind_;

        static const int maxCommentCharacters_;
        static const string periodCommentIdentifier_;
        static const string sizeFactorCommentIdentifier_;

        void createNewOrder(int);
        void sendOrder(Order &);

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

const int OrderCreate::maxCommentCharacters_ = 20;
const string OrderCreate::periodCommentIdentifier_ = "P";
const string OrderCreate::sizeFactorCommentIdentifier_ = "M";

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
    if (areThereRecentOrders()) {
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

    Order order;
    order.symbol = Symbol();
    order.magicNumber = BotMagicNumber();
    order.type = calculateOrderTypeFromSetups(startIndexForOrder);

    if (order.type != OP_BUYSTOP && order.type != OP_SELLSTOP) {
        return;
    }

    const bool isBuy = (order.type == OP_BUYSTOP);

    const Discriminator discriminator = isBuy ? Max : Min;
    const Discriminator antiDiscriminator = !isBuy ? Max : Min;

    const double spread = GetMarketSpread();
    const double spreadAsk = isBuy ? spread : 0;
    const double spreadBid = !isBuy ? spread : 0;

    order.openPrice = iExtreme(discriminator, startIndexForOrder) + discriminator * (1 + spreadAsk) * Pips();
    order.stopLoss = iExtreme(antiDiscriminator, startIndexForOrder) - discriminator * (1 + spreadBid) * Pips();

    const double takeProfitFactor = takeProfitFactor_;

    order.takeProfit = order.openPrice + discriminator * takeProfitFactor * order.getStopLossPips() / Pips();

    const double sizeFactor = calculateSizeFactor(order.type, order.openPrice, order.symbol);
    order.lots = calculateOrderLots(order.getStopLossPips(), sizeFactor);

    if (sizeFactor == 0) {
        return;
    }
    if (areThereBetterOrders(order.symbol, order.type, order.openPrice, order.stopLoss)) {
        return;
    }

    order.expiration = Time[0] + (orderCandlesDuration_ + 1 - startIndexForOrder) * order.getPeriod() * 60;
    order.comment = buildOrderComment(order.getPeriod(), sizeFactor, takeProfitFactor, order.getStopLossPips());

    sendOrder(order);
}

/**
 * Creates a new pending order.
 */
void OrderCreate::sendOrder(Order & order) {
    ResetLastError();

    order.ticket = OrderSend(
        order.symbol,
        order.type,
        order.lots,
        NormalizeDouble(order.openPrice, Digits),
        3,
        NormalizeDouble(order.stopLoss, Digits),
        NormalizeDouble(order.takeProfit, Digits),
        order.comment,
        order.magicNumber,
        order.expiration,
        Blue
    );

    const int lastError = GetLastError();
    if (lastError != 0) {
        ThrowException(__FUNCTION__, StringConcatenate(
            "OrderSend error: ", lastError, " for order ticket: ", order.ticket));
    }

    if (order.ticket > 0) {
        const int previouslySelectedOrder = OrderTicket();
        const int selectedOrder = OrderSelect(order.ticket, SELECT_BY_TICKET);

        Print("New order created with ticket: ", order.ticket);
        OrderPrint();

        if (order.type != OrderType() || order.lots != OrderLots() || order.comment != OrderComment() ||
            order.magicNumber != OrderMagicNumber() || order.expiration != OrderExpiration()) {
            Print(order.toString());
            ThrowException(__FUNCTION__, StringConcatenate(
                "Mismatching information in newly created order with ticket: ", order.ticket));
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
 * Checks if there have been any recent correlated open orders, so that it can be waited before placing new ones.
 */
bool OrderCreate::areThereRecentOrders(datetime date = NULL) {
    if (date == NULL) {
        date = (datetime) (TimeCurrent() - 60 * Period() * MathRound(orderCandlesDuration_ / PeriodFactor()));
    }

    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily());
    orderFilter.type.add(OP_BUY, OP_SELL);

    orderFilter.closeTime.setFilterType(Greater);
    orderFilter.closeTime.add(date);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter, MODE_HISTORY);

    if (ArraySize(orders) > 0) {
        return true;
    }

    return false;
}

/**
 * Checks if there are other pending orders. In case they are with worst setups it deletes them.
 */
bool OrderCreate::areThereBetterOrders(string symbol, int type, double openPrice, double stopLoss) {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(ALLOWED_MAGIC_NUMBERS);
    orderFilter.symbolFamily.add(SymbolFamily());
    orderFilter.type.add(type, OP_BUY, OP_SELL);

    Order orders[];
    orderFind_.getFilteredOrdersList(orders, orderFilter);

    Order newOrder;
    newOrder.symbol = symbol;
    newOrder.type = type;
    newOrder.openPrice = openPrice;
    newOrder.stopLoss = stopLoss;

    OrderManage orderManage;

    for (int order = 0; order < ArraySize(orders); order++) {
        if (orderManage.findBestOrder(orders[order], newOrder)) {
            return true;
        }
    }

    return false;
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
double OrderCreate::calculateOrderLots(double stopLossPips, double sizeFactor) {
    if (sizeFactor == 0) {
        return 0;
    }

    const double absoluteRisk = (PERCENT_RISK / 100) * AccountEquity() / MarketInfo(Symbol(), MODE_TICKVALUE);
    const double stopLossTicks = stopLossPips / 10;
    const double rawOrderLots = absoluteRisk / stopLossTicks;

    double orderLots = 2 * NormalizeDouble(rawOrderLots * sizeFactor / 2, 2);

    orderLots = MathMax(orderLots, 0.02);

    return NormalizeDouble(orderLots, 2);
}

/**
 * Creates the comment for a new pending order, and makes sure it doesn't exceed the maximum length.
 */
string OrderCreate::buildOrderComment(int period, double sizeFactor, double takeProfitFactor, int stopLossPips) {
    const string strategyPrefix = "A";

    const string comment = StringConcatenate(
        strategyPrefix,
        " ", periodCommentIdentifier_, period,
        " ", sizeFactorCommentIdentifier_, NormalizeDouble(sizeFactor, 1),
        " R", NormalizeDouble(takeProfitFactor, 1),
        " S", stopLossPips
    );

    if (StringLen(comment) > maxCommentCharacters_) {
        return ThrowException(StringSubstr(comment, 0, maxCommentCharacters_), __FUNCTION__, "Order comment too long");
    }

    return comment;
}

/**
 * Estrapolates the sizeFactor of a pending order from a well formatted order comment.
 */
double OrderCreate::getSizeFactorFromComment(string comment) {
    string splittedComment[];
    StringSplit(comment, StringGetCharacter(" ", 0), splittedComment);

    for (int i = 0; i < ArraySize(splittedComment); i++) {
        if (StringContains(splittedComment[i], sizeFactorCommentIdentifier_)) {
            StringSplit(splittedComment[i], StringGetCharacter(sizeFactorCommentIdentifier_, 0), splittedComment);
            break;
        }
    }

    if (ArraySize(splittedComment) == 2) {
        return (double) splittedComment[1];
    }

    return ThrowException(-1, __FUNCTION__, "Could not get sizeFactor from comment");
}
