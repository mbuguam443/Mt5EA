//+------------------------------------------------------------------+
//| Expert advisor: TenDollarBot.mq5                                 |
//| Strategy: RSI + EMA                                              |
//+------------------------------------------------------------------+
#property strict

input int    rsiPeriod      = 14;
input double emaPeriod      = 50;
input double rsiBuyLevel    = 55;
input double rsiSellLevel   = 45;
input double lotSize        = 0.01;
input double slPips         = 30;
input double tpPips         = 60;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
  input int emaPeriod = 50;
double ema = 0;
int OnInit()
  {
   Print("TenDollarBot initialized.");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("TenDollarBot stopped.");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Check if a position is already open
   if (PositionsTotal() > 0)
      return;



   // Get the EMA handle
   int emaHandle = iMA(_Symbol, _Period, emaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   int rsiHandle = iRSI(_Symbol, _Period, rsiPeriod, PRICE_CLOSE);
   double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl = slPips * _Point;
   double tp = tpPips * _Point;

   // Buy conditions
   if (price > ema && rsi > rsiBuyLevel)
     {
      tradeOrder(ORDER_TYPE_BUY, lotSize, price, sl, tp);
     }
   // Sell conditions
   else if (price < ema && rsi < rsiSellLevel)
     {
      tradeOrder(ORDER_TYPE_SELL, lotSize, price, sl, tp);
     }
  }

//+------------------------------------------------------------------+
//| Order execution helper                                           |
//+------------------------------------------------------------------+
void tradeOrder(ENUM_ORDER_TYPE type, double lot, double price, double sl, double tp)
  {
   MqlTradeRequest request;
   MqlTradeResult  result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action   = TRADE_ACTION_DEAL;
   request.symbol   = _Symbol;
   request.volume   = lot;
   request.type     = type;
   request.price    = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.sl       = (type == ORDER_TYPE_BUY) ? request.price - sl : request.price + sl;
   request.tp       = (type == ORDER_TYPE_BUY) ? request.price + tp : request.price - tp;
   request.deviation= 10;
   request.magic    = 20250719;
   request.type_filling = ORDER_FILLING_IOC;

   if (!OrderSend(request, result))
     {
      Print("Trade failed: ", result.retcode);
     }
   else
     {
      Print("Trade success: ", result.order);
     }
  }
