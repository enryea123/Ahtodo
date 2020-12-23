#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "../market/Holiday.mqh"
#include "../order/Order.mqh"
#include "../order/OrderFilter.mqh"
#include "../order/OrderFind.mqh"
#include "../pivot/Pivot.mqh"


class OrderTrail {
    public:
        ~OrderTrail();
        void manageOpenOrders();

    protected:
        OrderFind orderFind_;

        void manageOpenOrder(Order &);
        void updateOrder(Order &, double, double);

        bool splitPosition(Order &, double);
        double breakEvenStopLoss(Order &);
        double trailer(double, double, double);

    private:
        static const int breakEvenSteps_;
        static const int breakEvenPips_;
        static const int commissionPips_;
        static const int takeProfitOneSaverPips_;

        static datetime orderModifiedTimeStamp_;

        int getBreakEvenPips(int, int);
        int getBreakEvenPoint(int, int);
};

const int OrderTrail::breakEvenSteps_ = 2;
const int OrderTrail::breakEvenPips_ = 6;
const int OrderTrail::commissionPips_ = 2;
const int OrderTrail::takeProfitOneSaverPips_ = 25;

datetime OrderTrail::orderModifiedTimeStamp_ = -1;

OrderTrail::~OrderTrail() {
    orderModifiedTimeStamp_ = -1;
}

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

void OrderTrail::manageOpenOrder(Order & order) {
    double newStopLoss = breakEvenStopLoss(order);

    updateOrder(order, newStopLoss);
    splitPosition(order, newStopLoss);
}

void OrderTrail::updateOrder(Order & order, double newStopLoss, double newTakeProfit = NULL) {
    if (!UNIT_TESTS_COMPLETED) {
        return;
    }

    if (newTakeProfit == NULL) {
        newTakeProfit = order.takeProfit;
    }

    const string symbol = order.symbol;

    if (MathRound(MathAbs(newTakeProfit - order.takeProfit) / Pips(symbol)) > 0 ||
        MathRound(MathAbs(newStopLoss - order.stopLoss) / Pips(symbol)) > 0) {

        orderModifiedTimeStamp_ = PrintTimer(orderModifiedTimeStamp_, StringConcatenate(
            "Modifying the existing order: ", order.ticket));

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

bool OrderTrail::splitPosition(Order & order, double newStopLoss) {
    if (!SPLIT_POSITION) {
        return false;
    }

    if (order.type != OP_BUY && order.type != OP_SELL) {
        return ThrowException(false, __FUNCTION__, "Cannot split pending position");
    }

    const int period = order.getPeriod();
    const double newStopLossPips = MathRound(MathAbs(order.openPrice - newStopLoss) / Pips(order.symbol));

    if ((order.type == OP_BUY && newStopLoss > order.openPrice) ||
        (order.type == OP_SELL && newStopLoss < order.openPrice)) {
        // Avoid splitting two times if there is a trailing,
        // since the sign of newStopLossPips is not checked
        return false;
    }

    if (StringContains(order.comment, StringConcatenate("A P", period)) &&
        newStopLossPips == getBreakEvenPips(period, 0)) {

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

double OrderTrail::breakEvenStopLoss(Order & order) {
    const int period = order.getPeriod();
    const int type = order.type;
    const double openPrice = order.openPrice;
    const string symbol = order.symbol;

    const Discriminator discriminator = (type == OP_BUY || type == OP_BUYSTOP || type == OP_BUYLIMIT) ? Max : Min;
    const double currentExtreme = iExtreme(discriminator, 0);

    double stopLoss = order.stopLoss;

    for (int i = 0; i < breakEvenSteps_; i++) {
        double breakEvenPoint = openPrice + discriminator * getBreakEvenPoint(period, i) * Pips(symbol);
        double breakEvenStopLoss = openPrice - discriminator * getBreakEvenPips(period, i) * Pips(symbol);

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

int OrderTrail::getBreakEvenPoint(int period, int step) {
    if (step == 0) {
        return breakEvenPips_ * PeriodFactor(period);
    }
    if (step == 1) {
        return takeProfitOneSaverPips_ * PeriodFactor(period);
    }

    return ThrowException(-100, __FUNCTION__, StringConcatenate("Invalid break even step: ", step));
}

int OrderTrail::getBreakEvenPips(int period, int step) {
    if (step == 0) {
        return breakEvenPips_ * PeriodFactor(period) - commissionPips_;
    }
    if (step == 1) {
        return 0;
    }

    return ThrowException(-100, __FUNCTION__, StringConcatenate("Invalid break even step: ", step));
}
