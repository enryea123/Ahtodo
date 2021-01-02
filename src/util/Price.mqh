#property copyright "2020 Enrico Albano"
#property link "https://www.linkedin.com/in/enryea123"
#property strict

#include "../../Constants.mqh"
#include "Exception.mqh"
#include "Util.mqh"


enum CandleSeriesType {
    I_high,
    I_low,
    I_open,
    I_close,
    I_time
};

/**
 * Used to get iHigh and iLow from iCandle.
 */
double iExtreme(Discriminator discriminator, int timeIndex) {
    if (discriminator == Max) {
        return iCandle(I_high, timeIndex);
    }

    if (discriminator == Min) {
        return iCandle(I_low, timeIndex);
    }

    return ThrowException(-1, __FUNCTION__, "Could not get value");
}

/**
 * Used to get market information from candle series for this symbol and period.
 */
double iCandle(CandleSeriesType candleSeriesType, int timeIndex) {
    return iCandle(candleSeriesType, Symbol(), Period(), timeIndex);
}

/**
 * Used to get market information from candle series. Assumes DownloadHistory has been executed before.
 */
double iCandle(CandleSeriesType candleSeriesType, string symbol, int period, int timeIndex) {
    if (!SymbolExists(symbol)) {
        return ThrowException(-1, __FUNCTION__, "Unknown symbol");
    }

    if (timeIndex < 0) {
        if (candleSeriesType == I_time) {
            return (double) TimeCurrent();
        }
        return ThrowException(-1, __FUNCTION__, "timeIndex < 0");
    }

    ResetLastError();
    double value = 0;

    if (candleSeriesType == I_high) {
        value = iHigh(symbol, period, timeIndex);
    } else if (candleSeriesType == I_low) {
        value = iLow(symbol, period, timeIndex);
    } else if (candleSeriesType == I_open) {
        value = iOpen(symbol, period, timeIndex);
    } else if (candleSeriesType == I_close) {
        value = iClose(symbol, period, timeIndex);
    } else if (candleSeriesType == I_time) {
        value = (double) iTime(symbol, period, timeIndex);
    } else {
        return ThrowException(-1, __FUNCTION__, StringConcatenate("Unsupported candleSeriesType: ", candleSeriesType));
    }

    int lastError = GetLastError();

    if (lastError == 0 && value != 0) {
        return value;
    }

    return ThrowException(value, __FUNCTION__, StringConcatenate("candleSeriesType == ",
        EnumToString(candleSeriesType), ", lastError == ", lastError, ", value == ", value));;
}

/**
 * Downloads history data for all the periods enabled on the bot.
 * It retries a few times if needed, and waits between attempts.
 */
bool DownloadHistory(string symbol = NULL) {
    if (symbol == NULL) {
        symbol = Symbol();
    }

    const int maxAttempts = 20;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
        int totalError = 0;
        ResetLastError();

        for (int i = 0; i < ArraySize(HISTORY_DOWNLOAD_PERIODS); i++) {
            int lastError = 0;
            int period = HISTORY_DOWNLOAD_PERIODS[i];

            iTime(symbol, period, 1);
            lastError = GetLastError();

            if (lastError != 0) {
                totalError += lastError;
            }
        }

        if (totalError == 0) {
            return true;
        } else if (attempt != maxAttempts - 1) {
            Print("Downloading missing history data, attempt: ", attempt + 1);
            Sleep(500);
        }
    }

    return ThrowException(false, __FUNCTION__, "Could not download history data");
}
