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

        bool splitPosition(Order &, double);
        bool closeSufferingOrder(Order &, double);
        double calculateSufferingFactor(Order &, double);
        double breakEvenStopLoss(Order &);
        double trailer(double, double, double);
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
    double newStopLoss = breakEvenStopLoss(order);

    newStopLoss *= calculateSufferingFactor(order, newStopLoss);

    if (closeSufferingOrder(order, newStopLoss)) {
        return;
    }

    updateOrder(order, newStopLoss);
    splitPosition(order, newStopLoss);
}

/**
 * Send the update request for an already existing order, if its stopLoss or takeProfit have changed.
 */
void OrderTrail::updateOrder(Order & order, double newStopLoss, double newTakeProfit = NULL) {
    if (!UNIT_TESTS_COMPLETED) {
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
        if (lastError != 0 || !orderModified) {
            ThrowException(__FUNCTION__, StringConcatenate(
                "Error ", lastError, " when modifying order: ", order.ticket));
        }
    }
}

/**
 * Splits an order by closing half position, if the stopLoss lies exactly at the breakEven point.
 */
bool OrderTrail::splitPosition(Order & order, double newStopLoss) {
    if (!SPLIT_POSITION) {
        return false;
    }

    if (!order.isOpen()) {
        return ThrowException(false, __FUNCTION__, "Cannot split pending position");
    }

    const int period = order.getPeriod();
    const double newStopLossPips = MathRound(MathAbs(order.openPrice - newStopLoss) / Pip(order.symbol));

    if ((order.type == OP_BUY && newStopLoss > order.openPrice) ||
        (order.type == OP_SELL && newStopLoss < order.openPrice)) {
        /**
         * Avoid splitting two times if there is a trailing,
         * since the sign of newStopLossPips is not checked.
         */
        return false;
    }

    if (!order.isBreakEven() && newStopLossPips == PeriodFactor(period) * BREAKEVEN_STEPS.getValues(0)) {
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
 * the new stopLoss is too close or below (above) the market value.
 */
bool OrderTrail::closeSufferingOrder(Order & order, double newStopLoss) {
    if (order.isBreakEven()) {
        return false;
    }

    if ((GetPrice() < newStopLoss + Pip(order.symbol) && order.type == OP_BUY) ||
        (GetPrice() > newStopLoss - Pip(order.symbol) && order.type == OP_SELL)) {

        if (UNIT_TESTS_COMPLETED) {
            Print("Closing order: ", order.ticket, " for new stopLoss too close or below (above) the market value");
            OrderManage orderManage;
            orderManage.deleteSingleOrder(order);
        }

        return true;
    }

    return false;
}

/**
 * Reduces the suffering for orders that delay to reach the breakEven point.
 * The suffering factor can be different from 1 only if:
 *  1. The order is not already at breakEven
 *  2. The newStopLoss is not going to update the order
 */
double OrderTrail::calculateSufferingFactor(Order & order, double newStopLoss) {
    if (order.isBreakEven()) {
        return 1;
    }

    if (MathRound(MathAbs(newStopLoss - order.stopLoss) / Pip(order.symbol)) == 0) {
        // Going in reverse order to make sure to not return
        // too early, as the conditions slowly become all true.
        for (int i = BREAKEVEN_SUFFERING_INTERVALS.size() - 1; i >= 0; i--) {
           const int orderAgeSeconds = (int) MathAbs(TimeCurrent() - order.openTime);

            if (orderAgeSeconds > 60 * BREAKEVEN_SUFFERING_INTERVALS.getKeys(i)) {
                return BREAKEVEN_SUFFERING_INTERVALS.getValues(i);
            }
        }
    }

    return 1;
}

/**
 * Calculates the new stopLoss for an already existing order that might need to be updated.
 */
double OrderTrail::breakEvenStopLoss(Order & order) {
    const int period = order.getPeriod();
    const double openPrice = order.openPrice;
    const string symbol = order.symbol;

    const Discriminator discriminator = order.getDiscriminator();
    const double currentExtreme = iExtreme(discriminator, 0);

    double stopLoss = order.stopLoss;

    for (int i = 0; i < BREAKEVEN_STEPS.size(); i++) {
        double breakEvenPoint = openPrice + discriminator *
            PeriodFactor(period) * Pip(symbol) * BREAKEVEN_STEPS.getKeys(i);
        double breakEvenStopLoss = openPrice - discriminator *
            PeriodFactor(period) * Pip(symbol) * BREAKEVEN_STEPS.getValues(i);

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
 * Trails the stopLoss and the takeProfit for and already existing order.
 */
double OrderTrail::trailer(double openPrice, double stopLoss, double takeProfit) {
    const Discriminator discriminator = (takeProfit > openPrice) ? Max : Min;
    const double currentExtreme = iExtreme(discriminator, 0);
    const double currentExtremeToOpenDistance = currentExtreme - openPrice;
    const double profitToOpenDistance = takeProfit - openPrice;

    const double trailerBaseDistance = 2.0;
    const double trailerPercent = 0.0;

    const double trailer = trailerBaseDistance - trailerPercent * currentExtremeToOpenDistance / profitToOpenDistance;

    // This trailing assumes a constant takeProfit factor
    double initialStopLossDistance = profitToOpenDistance / MAX_TAKEPROFIT_FACTOR;
    double trailerStopLoss = currentExtreme - initialStopLossDistance * trailer;

    // Trailing StopLoss
    if (discriminator > 0) {
        stopLoss = MathMax(stopLoss, trailerStopLoss);
    } else {
        stopLoss = MathMin(stopLoss, trailerStopLoss);
    }

    return stopLoss;

    // In the future, implement a stopLoss trailing below the previous minimum

    /*
    // Trailing TakeProfit
    const double takeProfitPercentUpdate = 0.95;

    if ((discriminator > 0 && currentExtremeToOpenDistance > takeProfitPercentUpdate * profitToOpenDistance) ||
        (discriminator < 0 && currentExtremeToOpenDistance < takeProfitPercentUpdate * profitToOpenDistance)) {
        takeProfit += profitToOpenDistance * (1 - takeProfitPercentUpdate);
    }
    return takeProfit;
    */
}
