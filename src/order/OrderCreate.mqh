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


/**
 * This class allows to place new orders.
 */
class OrderCreate {
    public:
        void newOrder();

        bool areThereRecentOrders(datetime);
        bool areThereBetterOrders(string, int, double, double);

        int calculateOrderTypeFromSetups(int);
        double calculateSizeFactor(int, double, string);
        double calculateOrderLots(int, double);
        double getPercentRisk();

        string buildOrderComment(int, double, double, int);
        double getSizeFactorFromComment(string);

    protected:
        OrderFind orderFind_;

        static const string periodCommentIdentifier_;
        static const string sizeFactorCommentIdentifier_;

        void createNewOrder(int);
        void sendOrder(Order &);
};

const string OrderCreate::periodCommentIdentifier_ = "P";
const string OrderCreate::sizeFactorCommentIdentifier_ = "M";

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
    if (Minute() == 0 || Minute() == 59 || Minute() == 30 || Minute() == 29) {
        return;
    }
    if (areThereRecentOrders()) {
        return;
    }

    createNewOrder(1);

    // At the opening of the market, search for patterns in the past
    if (market.isMarketOpenLookBackTimeWindow()) {
        for(int time = 2; time < MORNING_LOOKBACK_CANDLES.get(Period()) + 2; time++){
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
    order.magicNumber = MagicNumber();
    order.type = calculateOrderTypeFromSetups(startIndexForOrder);

    if (order.type != OP_BUYSTOP && order.type != OP_SELLSTOP) {
        return;
    }

    const bool isBuy = order.isBuy();

    const Discriminator discriminator = isBuy ? Max : Min;
    const Discriminator antiDiscriminator = !isBuy ? Max : Min;

    const double spread = GetSpread();
    const double spreadAsk = isBuy ? spread : 0;
    const double spreadBid = !isBuy ? spread : 0;

    order.openPrice = iExtreme(discriminator, startIndexForOrder) + discriminator * (1 + spreadAsk) * Pip();
    order.stopLoss = iExtreme(antiDiscriminator, startIndexForOrder) - discriminator * (1 + spreadBid) * Pip();

    const double takeProfitFactor = BASE_TAKE_PROFIT_FACTOR;

    order.takeProfit = order.openPrice + discriminator * takeProfitFactor * order.getStopLossPips() / Pip();

    const double sizeFactor = calculateSizeFactor(order.type, order.openPrice, order.symbol);
    order.lots = calculateOrderLots(order.getStopLossPips(), sizeFactor);

    if (sizeFactor == 0) {
        return;
    }
    if (areThereBetterOrders(order.symbol, order.type, order.openPrice, order.stopLoss)) {
        return;
    }

    order.expiration = Time[0] + (ORDER_CANDLES_DURATION + 1 - startIndexForOrder) * order.getPeriod() * 60;
    order.comment = buildOrderComment(order.getPeriod(), sizeFactor, takeProfitFactor, order.getStopLossPips());

    sendOrder(order);
}

/**
 * Creates a new pending order.
 */
void OrderCreate::sendOrder(Order & order) {
    if (!UNIT_TESTS_COMPLETED) {
        return;
    }

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

    if (pattern.isAntiPattern(timeIndex)) {
        ANTIPATTERN_TIMESTAMP = PrintTimer(ANTIPATTERN_TIMESTAMP, StringConcatenate(
            "AntiPattern found at time: ", TimeToStr(Time[timeIndex])));
        return -1;
    }

    if (!pattern.isSellPattern(timeIndex) && !pattern.isBuyPattern(timeIndex)) {
        FOUND_PATTERN_TIMESTAMP = PrintTimer(FOUND_PATTERN_TIMESTAMP, StringConcatenate(
            "No patterns found at time: ", TimeToStr(Time[timeIndex])));
        return -1;
    }

    TrendLine trendLine;

    for (int i = ObjectsTotal() - 1; i >= 0; i--) {
        if (!trendLine.isGoodTrendLineFromName(ObjectName(i), timeIndex)) {
            continue;
        }

        const double trendLineSetupValue = ObjectGetValueByShift(ObjectName(i), timeIndex);
        const double trendLineDistanceFromMin = MathAbs(iExtreme(Min, timeIndex) - trendLineSetupValue);
        const double trendLineDistanceFromMax = MathAbs(iExtreme(Max, timeIndex) - trendLineSetupValue);

        if (pattern.isSellPattern(timeIndex) && trendLineDistanceFromMin < TRENDLINE_SETUP_MAX_PIPS_DISTANCE * Pip()) {
            SELL_SETUP_TIMESTAMP = PrintTimer(SELL_SETUP_TIMESTAMP, StringConcatenate(
                "Found OP_SELLSTOP setup at Time: ", TimeToStr(Time[timeIndex]), " for TrendLine: ", ObjectName(i)));
            return OP_SELLSTOP;
        }

        if (pattern.isBuyPattern(timeIndex) && trendLineDistanceFromMax < TRENDLINE_SETUP_MAX_PIPS_DISTANCE * Pip()) {
            BUY_SETUP_TIMESTAMP = PrintTimer(BUY_SETUP_TIMESTAMP, StringConcatenate(
                "Found OP_BUYSTOP setup at Time: ", TimeToStr(Time[timeIndex]), " for TrendLine: ", ObjectName(i)));
            return OP_BUYSTOP;
        }
    }

    NO_SETUP_TIMESTAMP = PrintTimer(NO_SETUP_TIMESTAMP, StringConcatenate(
        "No setups found at Time: ", TimeToStr(Time[timeIndex])));
    return -1;
}

/**
 * Checks if there have been any recent correlated open orders, so that it can be waited before placing new ones.
 */
bool OrderCreate::areThereRecentOrders(datetime date = NULL) {
    if (date == NULL) {
        date = (datetime) (TimeCurrent() - 60 * Period() * MathRound(ORDER_CANDLES_DURATION / PeriodFactor()));
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
 * Calculates the size for a new order, and makes sure that it's divisible by 2,
 * so that the position can be later split.
 */
double OrderCreate::calculateOrderLots(int stopLossPips, double sizeFactor) {
    if (sizeFactor == 0) {
        return 0;
    }

    const string symbol = Symbol();

    const double absoluteRisk = getPercentRisk() * AccountEquity() / MarketInfo(symbol, MODE_TICKVALUE);
    const int stopLossTicks = stopLossPips * 10;
    const double rawOrderLots = absoluteRisk / stopLossTicks;

    double orderLots = 2 * NormalizeDouble(rawOrderLots * sizeFactor / 2, 2);

    orderLots = MathMax(orderLots, 0.02);

    return NormalizeDouble(orderLots, 2);
}

/**
 * Returns the percent risk for a position, depending on the account.
 */
double OrderCreate::getPercentRisk() {
    const double exceptionPercentRisk = PERCENT_RISK_ACCOUNT_EXCEPTIONS.get(AccountNumber());
    const double percentRisk = (exceptionPercentRisk != NULL) ? exceptionPercentRisk : PERCENT_RISK;

    return percentRisk / 100;
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

    if (StringLen(comment) > MAX_ORDER_COMMENT_CHARACTERS) {
        const string truncatedComment = StringSubstr(comment, 0, MAX_ORDER_COMMENT_CHARACTERS);
        return ThrowException(truncatedComment, __FUNCTION__, "Order comment too long");
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
