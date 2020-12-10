#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"

#include "../../Constants.mqh"
#include "../holiday/Holiday.mqh"
#include "../order/Order.mqh"
#include "../order/OrderFind.mqh"
#include "../pivot/Pivot.mqh"


class OrderTrail {
    public:
        void manageOpenOrders();

    protected: // or public ?
        static const bool positionSplit_;
        static const int breakEvenPips_;
        static const int commissionPips_;
        static const int pointPips_[];
        static const int stopLossPips_[];
};

const bool OrderTrail::positionSplit_ = true;
const int OrderTrail::breakEvenPips_ = 6;
const int OrderTrail::commissionPips_ = 2;
const int OrderTrail::pointPips_[] = {breakEvenPips_, 25} * PeriodMultiplicationFactor();
const int OrderTrail::stopLossPips_[] = {breakEvenPips_, 0} * PeriodMultiplicationFactor();

// put in unit tests
//if (ArraySize(pointPips_) != ArraySize(stopLossPips_)) {
//    return ThrowException(0, __FUNCTION__, "Incorrect break even steps");
//}

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

void OrderTrail::manageOpenedOrder(Order order) {
    double newStopLoss = breakEvenStopLoss(order.orderType, order.openPrice, order.stopLoss);

    updateOrder(order, newStopLoss);
    splitPosition(order, newStopLoss);
}

void OrderTrail::updateOrder(Order order, double newStopLoss, double newTakeProfit = NULL) {
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

double OrderTrail::splitPosition(Order order, double newStopLoss) { // testable because I can build on Order object with custom values (use ordercomment builder)
    const int newStopLossPips = MathRound(MathAbs(order.openPrice - newStopLoss) / Pips());

    if (positionSplit_ && StringContains(order.comment, StringConcatenate("P", Period())) && // test to make sure comment is not changed
        newStopLossPips == breakEvenPips_ - commissionPips_) {

        const bool splitOrder = OrderClose(order.ticket, order.lots / 2, order.closePrice, 3);

        if (!splitOrder) {
            ThrowException(__FUNCTION__, StringConcatenate("Failed to split order: ", order.ticket));
        }
    }
}

double OrderTrail::breakEvenStopLoss(int orderType, double openPrice, double stopLoss) {
    const Discriminator discriminator = (orderType == OP_BUY) ? Max : Min;
    const double currentExtreme = iExtreme(discriminator, 0);

    for (int i = 0; i < ArraySize(pointPips_); i++) {
        double breakEvenPoint = openPrice + discriminator * pointPips_[i] * Pips();
        double breakEvenStopLoss = openPrice - discriminator * (stopLossPips_[i] - commissionPips_) * Pips();

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
    double TrailerInitialDistance = 2.0;
    double TrailerPercent = 0.0;

    double Trailer = TrailerInitialDistance - TrailerPercent
        * CurrentExtremeToOpenDistance / profitToOpenDistance;

    double InitialStopLossDistance = profitToOpenDistance / GetTakeProfitFactor();
    double TrailerStopLoss = CurrentExtreme - InitialStopLossDistance * Trailer;

    // Trailing StopLoss
    if(OrderSign > 0){
        StopLoss = MathMax(StopLoss, TrailerStopLoss);
    }else{
        StopLoss = MathMin(StopLoss, TrailerStopLoss);
    }

    /*
    // Update TakeProfit
    if((CurrentToOpenDistance > 0.95 * ProfitToOpenDistance && ProfitToOpenDistance > 0)
    || (CurrentToOpenDistance < 0.95 * ProfitToOpenDistance && ProfitToOpenDistance < 0)){
        TakeProfit += ProfitToOpenDistance * 0.05;
    }
    */

}
