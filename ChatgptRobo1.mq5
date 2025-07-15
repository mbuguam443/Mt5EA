//+------------------------------------------------------------------+
//| Scalping EA for Gold (XAUUSD) - 15M Timeframe                   |
//| Developed by ChatGPT                                            |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>

CTrade trade;

input double LotSize = 0.1;
input int TakeProfit = 50;
input int StopLoss = 30;
input int Slippage = 3;
input int MagicNumber = 12345;

input int FastMA = 5;
input int SlowMA = 20;
input int RSI_Period = 14;
input int RSI_Overbought = 70;
input int RSI_Oversold = 30;

//+------------------------------------------------------------------+
int OnInit()
{
    Print("Gold Scalping EA Initialized");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
bool CanTrade()
{
    if (PositionsTotal() > 0)
        return false;
    return true;
}

//+------------------------------------------------------------------+
void OnTick()
{
    if (!CanTrade())
    {
        Print("Cannot trade: Open positions exist.");
        return;
    }

    int fastMAHandle = iMA(_Symbol, PERIOD_M15, FastMA, 0, MODE_SMA, PRICE_CLOSE);
double fastMA[];
CopyBuffer(fastMAHandle, 0, 0, 1, fastMA);
    int slowMAHandle = iMA(_Symbol, PERIOD_M15, SlowMA, 0, MODE_SMA, PRICE_CLOSE);
double slowMA[];
CopyBuffer(slowMAHandle, 0, 0, 1, slowMA);
    int rsiHandle = iRSI(_Symbol, PERIOD_M15, RSI_Period, PRICE_CLOSE);
double rsiValues[];
CopyBuffer(rsiHandle, 0, 0, 1, rsiValues);
double rsi = rsiValues[0];
    
    double askPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
double bidPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

if (fastMA[0] > slowMA[0] && rsi < RSI_Oversold)
    {
        if (trade.Buy(LotSize, _Symbol, askPrice, StopLoss * _Point, TakeProfit * _Point, "Gold Scalping Buy")) {
        Print("Buy order placed successfully.");
    } else {
        Print("Buy order failed: ", trade.ResultRetcode());
    }
    }
    else if (fastMA[0] < slowMA[0] && rsi > RSI_Overbought)
    {
        if (trade.Sell(LotSize, _Symbol, bidPrice, StopLoss * _Point, TakeProfit * _Point, "Gold Scalping Sell")) {
        Print("Sell order placed successfully.");
    } else {
        Print("Sell order failed: ", trade.ResultRetcode());
    }
    }
}
