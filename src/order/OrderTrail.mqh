#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "../market/Holiday.mqh"
#include "../order/Order.mqh"
#include "../order/OrderFilter.mqh"
#include "../order/OrderFind.mqh"
#include "../pivot/Pivot.mqh"


class OrderTrail {
    public:
        void manageOpenOrders();
        void manageOpenedOrder(Order &);

        void updateOrder(Order &, double, double);
        void splitPosition(Order &, double);
        double breakEvenStopLoss(int, double, double);
        double trailer(double, double, double);

    private:
        int getBreakEvenPips(int);
        int getBreakEvenPoint(int);

    protected: /// or public ? or private?
        static const bool positionSplit_;
        static const int breakEvenSteps_;
        static const int breakEvenPips_;
        static const int commissionPips_;
        static const int takeProfitOneSaverPips_;
};

const bool OrderTrail::positionSplit_ = true;
const int OrderTrail::breakEvenSteps_ = 2;
const int OrderTrail::breakEvenPips_ = 6;
const int OrderTrail::commissionPips_ = 2;
const int OrderTrail::takeProfitOneSaverPips_ = 25;

void OrderTrail::manageOpenOrders() {
    OrderFilter orderFilter;
    orderFilter.magicNumber.add(BotMagicNumber());
    orderFilter.symbol.add(Symbol());
    orderFilter.type.add(OP_BUY, OP_SELL);

    Order orders[];
    OrderFind orderFind;
    orderFind.getFilteredOrdersList(orders, orderFilter);

    for (int order = 0; order < ArraySize(orders); order++) {
        manageOpenedOrder(orders[order]);
    }
}

void OrderTrail::manageOpenedOrder(Order & order) {
    double newStopLoss = breakEvenStopLoss(order.type, order.openPrice, order.stopLoss);

    updateOrder(order, newStopLoss);
    splitPosition(order, newStopLoss);
}

void OrderTrail::updateOrder(Order & order, double newStopLoss, double newTakeProfit = NULL) {
    if (newTakeProfit == NULL) {
        newTakeProfit = order.takeProfit;
    }

    if (MathRound(MathAbs(newTakeProfit - order.takeProfit) / Pips()) > 0 ||
        MathRound(MathAbs(newStopLoss - order.stopLoss) / Pips()) > 0) {

        Print("Modifying the existing order: ", order.ticket);

        ResetLastError();

        const bool orderModified = OrderModify(
            order.ticket,
            NormalizeDouble(order.openPrice, Digits),
            NormalizeDouble(newStopLoss, Digits),
            NormalizeDouble(newTakeProfit, Digits),
            0,
            Blue
        );

        const int lastError = GetLastError();
        if (lastError != 0 || !orderModified) {
            ThrowException(__FUNCTION__, StringConcatenate(
                "OrderModify error: ", lastError, " for orderTicket: ", order.ticket));
        }
    }
}

void OrderTrail::splitPosition(Order & order, double newStopLoss) { /// testable because I can build on Order object with custom values (use ordercomment builder)
    const int newStopLossPips = MathRound(MathAbs(order.openPrice - newStopLoss) / Pips());

    if (positionSplit_ && StringContains(order.comment, StringConcatenate("P", Period())) && /// test to make sure comment is not changed
        newStopLossPips == getBreakEvenPips(0)) {

        const bool splitOrder = OrderClose(order.ticket, order.lots / 2, order.closePrice, 3);

        if (!splitOrder) {
            ThrowException(__FUNCTION__, StringConcatenate("Failed to split order: ", order.ticket));
        }
    }
}

double OrderTrail::breakEvenStopLoss(int orderType, double openPrice, double stopLoss) {
    const Discriminator discriminator = (orderType == OP_BUY) ? Max : Min;
    const double currentExtreme = iExtreme(discriminator, 0);

    for (int i = 0; i < breakEvenSteps_; i++) {
        double breakEvenPoint = openPrice + discriminator * getBreakEvenPoint(i) * Pips();
        double breakEvenStopLoss = openPrice - discriminator * getBreakEvenPips(i) * Pips();

        if (discriminator == Max && currentExtreme > breakEvenPoint) {
            stopLoss = MathMax(stopLoss, breakEvenStopLoss);
        }
        if (discriminator == Min && currentExtreme < breakEvenPoint) {
            stopLoss = MathMin(stopLoss, breakEvenStopLoss);
        }
    }

    return stopLoss;
}

double OrderTrail::trailer(double openPrice, double stopLoss, double takeProfit) {
    const Discriminator discriminator = (takeProfit > openPrice) ? Max : Min;
    const double currentExtreme = iExtreme(discriminator, 0);
    const double currentExtremeToOpenDistance = currentExtreme - openPrice;
    const double profitToOpenDistance = takeProfit - openPrice;

    const double trailerBaseDistance = 2.0;
    const double trailerPercent = 0.0;

    const double trailer = trailerBaseDistance - trailerPercent * currentExtremeToOpenDistance / profitToOpenDistance;

    const double takeProfitFactor_ = 3; // not defined here, assumed as constant
    double initialStopLossDistance = profitToOpenDistance / takeProfitFactor_;
    double trailerStopLoss = currentExtreme - initialStopLossDistance * trailer;

    // Trailing StopLoss
    if(discriminator > 0){
        stopLoss = MathMax(stopLoss, trailerStopLoss);
    }else{
        stopLoss = MathMin(stopLoss, trailerStopLoss);
    }

    return stopLoss;

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

int OrderTrail::getBreakEvenPoint(int step) { /// test extensively. maybe implement hashmap
    if (step == 0) {
        return breakEvenPips_ * PeriodMultiplicationFactor();
    }
    if (step == 1) {
        return takeProfitOneSaverPips_ * PeriodMultiplicationFactor();
    }

    return ThrowException(-100, __FUNCTION__, StringConcatenate("Invalid break even step: ", step));
}

int OrderTrail::getBreakEvenPips(int step) {
    if (step == 0) {
        return breakEvenPips_ * PeriodMultiplicationFactor() - commissionPips_;
    }
    if (step == 1) {
        return 0;
    }

    return ThrowException(-100, __FUNCTION__, StringConcatenate("Invalid break even step: ", step));
}
