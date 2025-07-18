#include <Trade\Trade.mqh>

input double Lots = 0.01;

CTrade trade;

void OnTick()
{
   string symbol = _Symbol;

   // Step 1: Wait for valid price
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   if (ask == 0.0)
   {
      Print("Waiting for price data...");
      return;
   }

   // Step 2: Ensure no duplicate trades
   if (PositionSelect(symbol))
   {
      Print("Position already exists for ", symbol);
      return;
   }

   // Step 3: Try placing buy order (no SL/TP)
   bool result = trade.Buy(Lots, symbol, ask, 0.0, 0.0, "BTC Buy");

   if (result)
      Print("✅ Buy executed at: ", ask);
   else
      Print("❌ Failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
}
