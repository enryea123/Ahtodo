#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../market/Holiday.mqh"
#include "../order/Order.mqh"
#include "../order/OrderFilter.mqh"
#include "../order/OrderFind.mqh"
#include "../order/OrderManage.mqh"
#include "../pivot/Pivot.mqh"


/**
 * This class allows to modify and trail an already existing opened order.
 */
class OrderTrail {
    public:
        void manageOpenOrders();

    protected:
        OrderFind orderFind_;

        void manageOpenOrder(Order &);
        void updateOrder(Order &, double, double);

        bool splitPosition(Order &);
        bool closeDrawningOrder(Order &, double);
        double calculateBreakEvenStopLoss(Order &);
        double calculateSufferingStopLoss(Order &);
        double calculateTrailingStopLoss(Order &);
        double getPreviousExtreme(Discriminator, int);
        void orderBelowZeroAlert(Order &);
};

/**
 * Gets the list of opened orders that need to be managed.
 */
void OrderTrail::manageOpenOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(MagicNumber());
    orderFilter.symbol.add(Symbol());
    orderFilter.type.add(OP_BUY, OP_SELL);

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter);

    for (int order = 0; order < ArraySize(orders); order++) {
        manageOpenOrder(orders[order]);
    }
}

/**
 * Manages a single opened order, calculates its new stoploss, and updates it.
 */
void OrderTrail::manageOpenOrder(Order & order) {
    const double breakEvenStopLoss = calculateBreakEvenStopLoss(order);
    const double trailingStopLoss = calculateTrailingStopLoss(order);

    double newStopLoss;

    if (order.getDiscriminator() == Max) {
        newStopLoss = MathMax(breakEvenStopLoss, trailingStopLoss);
    } else {
        newStopLoss = MathMin(breakEvenStopLoss, trailingStopLoss);
    }

    if (closeDrawningOrder(order, newStopLoss)) {
        return;
    }

    orderBelowZeroAlert(order);

    updateOrder(order, newStopLoss);
    splitPosition(order);
}

/**
 * Send the update request for an already existing order, if its stopLoss or takeProfit have changed.
 */
void OrderTrail::updateOrder(Order & order, double newStopLoss, double newTakeProfit = NULL) {
    if (!UNIT_TESTS_COMPLETED || !order.isOpen()) {
        return;
    }

    if (newTakeProfit == NULL) {
        newTakeProfit = order.takeProfit;
    }

    const string symbol = order.symbol;

    if (MathRound(MathAbs(newTakeProfit - order.takeProfit) / Pip(symbol)) > 0 ||
        MathRound(MathAbs(newStopLoss - order.stopLoss) / Pip(symbol)) > 0) {

        ORDER_MODIFIED_TIMESTAMP = PrintTimer(ORDER_MODIFIED_TIMESTAMP, StringConcatenate(
            "Modifying the existing order: ", order.ticket));

        ResetLastError();

        const bool orderModified = OrderModify(
            order.ticket,
            NormalizeDouble(order.openPrice, Digits),
            NormalizeDouble(newStopLoss, Digits),
            NormalizeDouble(newTakeProfit, Digits),
            0
        );

        const int lastError = GetLastError();
        const datetime thisTime = Time[0];

        static int cachedLastError;
        static datetime timeStamp;

        if ((lastError != 0 || !orderModified) && (cachedLastError != lastError || timeStamp != thisTime)) {
            ThrowException(__FUNCTION__, StringConcatenate(
                "Error ", lastError, " when modifying order: ", order.toString(), ", newStopLoss: ", newStopLoss));
        }

        cachedLastError = lastError;
        timeStamp = thisTime;
    }
}

/**
 * Splits an order by closing half position, if the stopLoss is beyond the breakEven point.
 */
bool OrderTrail::splitPosition(Order & order) {
    if (!SPLIT_POSITION) {
        return false;
    }

    if (!order.isOpen()) {
        return ThrowException(false, __FUNCTION__, "Cannot split pending position");
    }

    const Discriminator discriminator = order.getDiscriminator();
    const double currentExtreme = iExtreme(discriminator, 0);
    const double breakEvenPoint = order.openPrice + discriminator *
        PeriodFactor(order.getPeriod()) * Pip(order.symbol) * BREAKEVEN_STEPS_SPLIT.getKeys(0);

    if ((discriminator == Max && currentExtreme < breakEvenPoint) ||
        (discriminator == Min && currentExtreme > breakEvenPoint)) {
        return false;
    }

    if (!order.isBreakEvenByComment()) {
        if (UNIT_TESTS_COMPLETED) {
            const bool splitOrder = OrderClose(order.ticket, order.lots / 2, order.closePrice, 3);

            if (!splitOrder) {
                ThrowException(__FUNCTION__, StringConcatenate("Failed to split order: ", order.ticket));
            }
        }

        return true;
    }

    return false;
}

/*
 * Closes orders that haven't reached the breakEven yet, in case
 * the new stopLoss is below (or above) the market value.
 */
bool OrderTrail::closeDrawningOrder(Order & order, double newStopLoss) {
    if (order.isBreakEven() || !order.isOpen()) {
        return false;
    }

    if ((GetPrice() < newStopLoss - Pip(order.symbol) && order.type == OP_BUY) ||
        (GetPrice() > newStopLoss + Pip(order.symbol) && order.type == OP_SELL)) {

        if (UNIT_TESTS_COMPLETED) {
            Print("Closing order: ", order.ticket, " for new stopLoss below (or above) the market value");
            OrderManage orderManage;
            orderManage.deleteSingleOrder(order);
        }

        return true;
    }

    return false;
}

/**
 * Calculates the new stopLoss for an already existing order that might need to be updated.
 */
double OrderTrail::calculateBreakEvenStopLoss(Order & order) {
    const int period = order.getPeriod();
    const double openPrice = order.openPrice;
    const string symbol = order.symbol;

    const Discriminator discriminator = order.getDiscriminator();
    const double currentExtreme = iExtreme(discriminator, 0);

    double stopLoss = order.stopLoss;

    const int breakEvenSteps = SPLIT_POSITION ? BREAKEVEN_STEPS_SPLIT.size() : BREAKEVEN_STEPS.size();

    for (int i = 0; i < breakEvenSteps; i++) {
        const int breakEvenStepKey = SPLIT_POSITION ? BREAKEVEN_STEPS_SPLIT.getKeys(i) : BREAKEVEN_STEPS.getKeys(i);
        const int breakEvenStepVal = SPLIT_POSITION ? BREAKEVEN_STEPS_SPLIT.getValues(i) : BREAKEVEN_STEPS.getValues(i);

        const double breakEvenPoint = openPrice + discriminator *
            PeriodFactor(period) * Pip(symbol) * breakEvenStepKey;
        const double breakEvenStopLoss = openPrice + discriminator *
            PeriodFactor(period) * Pip(symbol) * breakEvenStepVal;

        if (discriminator == Max && currentExtreme > breakEvenPoint) {
            stopLoss = MathMax(stopLoss, breakEvenStopLoss);
        }
        if (discriminator == Min && currentExtreme < breakEvenPoint) {
            stopLoss = MathMin(stopLoss, breakEvenStopLoss);
        }
    }

    return stopLoss;
}

/**
 * Reduces the suffering for orders that delay to reach the breakEven point, by slowly decreasing the stopLoss.
 */
double OrderTrail::calculateSufferingStopLoss(Order & order) {
    if (!SUFFERING_STOPLOSS || order.isBreakEven() || !order.isOpen()) {
        return order.stopLoss;
    }

    const int period = order.getPeriod();
    const double openPrice = order.openPrice;
    const string symbol = order.symbol;
    const Discriminator discriminator = order.getDiscriminator();

    double stopLoss = order.stopLoss;

    for (int i = 0; i < SUFFERING_STEPS.size(); i++) {
       const int orderAgeSeconds = (int) MathAbs(TimeCurrent() - order.openTime);

        if (orderAgeSeconds > 60 * SUFFERING_STEPS.getKeys(i)) {
            double sufferingStopLoss = openPrice - discriminator *
                PeriodFactor(period) * Pip(symbol) * SUFFERING_STEPS.getValues(i);

            if (discriminator == Max) {
                stopLoss = MathMax(stopLoss, sufferingStopLoss);
            } else {
                stopLoss = MathMin(stopLoss, sufferingStopLoss);
            }
        }
    }

    return stopLoss;
}

/**
 * Trails the stopLoss and the takeProfit for and already existing order.
 */
double OrderTrail::calculateTrailingStopLoss(Order & order) {
    if (order.symbol != Symbol()) {
        return ThrowException(0, __FUNCTION__, "Order trailing not supported for non current symbol");
    }

    const Discriminator discriminator = order.getDiscriminator();
    const Discriminator antiDiscriminator = (discriminator > 0) ? Min : Max;

    const int stopLossPips = SPLIT_POSITION ? (int) AverageTrueRange() : order.getStopLossPipsFromComment();

    const double currentGain = MathAbs(GetPrice() - order.openPrice) / Pip() / stopLossPips;

    if (!order.isBreakEven()) {
        return order.stopLoss;
    }

    double stopLoss = order.stopLoss;

    const int trailingSteps = TRAILING_STEPS.size();

    for (int i = 0; i < trailingSteps; i++) {
        if (i < trailingSteps - 1) {
            if (currentGain > TRAILING_STEPS.getKeys(i) && currentGain < TRAILING_STEPS.getKeys(i + 1)) {
                stopLoss = getPreviousExtreme(antiDiscriminator, TRAILING_STEPS.getValues(i));
            }
        } else {
            if (currentGain > TRAILING_STEPS.getKeys(i)) {
                stopLoss = getPreviousExtreme(antiDiscriminator, TRAILING_STEPS.getValues(i));
            }
        }
    }

    stopLoss -= discriminator * TRAILING_BUFFER_PIPS * Pip();

    if (discriminator > 0) {
        stopLoss = MathMax(stopLoss, order.stopLoss);
    } else {
        stopLoss = MathMin(stopLoss, order.stopLoss);
    }

    return stopLoss;
}

/**
 * Calculates the previous extreme out of numberOfCandles.
 */
double OrderTrail::getPreviousExtreme(Discriminator discriminator, int numberOfCandles) {
    if (numberOfCandles < 0) {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Unprocessable numberOfCandles: ", numberOfCandles));
    }

    double previousExtreme = (discriminator > 0) ? -10000 : 10000;

    for (int i = 0; i < numberOfCandles + 1; i++) {
        if (discriminator > 0) {
            previousExtreme = MathMax(previousExtreme, iExtreme(discriminator, i));
        } else {
            previousExtreme = MathMin(previousExtreme, iExtreme(discriminator, i));
        }
    }

    return previousExtreme;
}

/**
 * Produces an alert if an order already at breakeven goes below zero.
 */
void OrderTrail::orderBelowZeroAlert(Order & order) {
    if (order.isBreakEven()) {
        if ((order.getDiscriminator() == Max && GetPrice() < order.openPrice) ||
            (order.getDiscriminator() == Min && GetPrice() > order.openPrice)) {
            ORDER_BELOW_ZERO_TIMESTAMP = PrintTimer(ORDER_BELOW_ZERO_TIMESTAMP,
                StringConcatenate("Order ", order.ticket, " went below zero after breakEven"));
        }
    }
}
