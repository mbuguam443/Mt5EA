//+------------------------------------------------------------------+
//|                                                       Apollo.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
CTrade trade;

bool tradeisopen;

input double lotsize=0.01;
input int  takeprofit=150;
input int  stoploss=2000;
input int  numberoftrade=2;


int OnInit()
  {
  
   tradeisopen=false;
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   double close=iClose(_Symbol,PERIOD_CURRENT,0);
   double open=iOpen(_Symbol,PERIOD_CURRENT,0);
   Print("Print There");
   
   if(close>open)
   {
     //trade.PositionClose(_Symbol);
     if(PositionsTotal()<numberoftrade)
       {
         tradeisopen=true;
         double entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        double tp=entry+takeprofit*_Point;
        double sl=stoploss==0?0:entry-stoploss*_Point;
        trade.Buy(lotsize,_Symbol,entry,sl,tp,"buy now");
       Print("going up");
       }
     
   }
   if(open>close)
   {
     
     if(PositionsTotal()<numberoftrade)
       {
         tradeisopen=true;
         double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
        double tp=entry-takeprofit*_Point;
        double sl=stoploss==0?0:entry+stoploss*_Point;
        trade.Sell(lotsize,_Symbol,entry,sl,tp,"sell now");
       Print("going up");
       }
    Print("going down");
   }
  }
//+------------------------------------------------------------------+



void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
  {
   if (id==CHARTEVENT_KEYDOWN)
   {
    Print ("key code ", lparam);
    if(lparam==79)
      {
       int total=PositionsTotal();
        Print ("total: ",total);
        for(int i=total-1;i>=0;i--)
          {
            ulong ticket=PositionGetTicket(i);
            if (PositionSelectByTicket(ticket))
            {
              trade.PositionClose(ticket);
              Print("postion closed successfully");
            }
          }
      }
      if(lparam==80)
      {
        ExpertRemove();
        Print("out me");
      }
   }
  }