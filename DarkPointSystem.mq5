#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
CTrade trade;
input double lotsize=0.01; //Lot Size
input int     TpLevel=2;//  Tp Level
input int     SlLevel=1;//  Sl Level

int handleDarkPoint;

int totalBars;

int OnInit()
  {
   
   totalBars=iBars(_Symbol,PERIOD_CURRENT); 
   handleDarkPoint=iCustom(_Symbol,PERIOD_CURRENT,"Market/Dark Point MT5.ex5"); 
   if(handleDarkPoint==INVALID_HANDLE)
     {
      Print("Failed to Load the Indciator");
     }else{
      Print("Indicator Loaded successfully");
     }
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   
  }

void OnTick()
  {
   int bars=iBars(_Symbol,PERIOD_CURRENT);
   if(totalBars!=bars)
     {
      totalBars=bars;
       double dpBuy[],dpSell[],dpBuyStar[],dpSellStar[];
       CopyBuffer(handleDarkPoint,0,1,1,dpBuy);
       CopyBuffer(handleDarkPoint,1,1,1,dpSell);
       CopyBuffer(handleDarkPoint,2,1,1,dpBuyStar);
       CopyBuffer(handleDarkPoint,3,1,1,dpSellStar);
       if(dpBuy[0]>0 || dpBuyStar[0]>0)
         {
            Print("new Buy Signal: ",dpBuy[0]);
            double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            ask=NormalizeDouble(ask,_Digits);
            
            double tp=ObjectGetDouble(0,"DP_TP_Line_"+IntegerToString(TpLevel)+IntegerToString(iTime(_Symbol,PERIOD_CURRENT,1)),OBJPROP_PRICE);
            tp=NormalizeDouble(tp,_Digits);
            double sl=ObjectGetDouble(0,"DP_SL_Line_"+IntegerToString(SlLevel)+IntegerToString(iTime(_Symbol,PERIOD_CURRENT,1)),OBJPROP_PRICE);
            sl=NormalizeDouble(sl,_Digits);
            
            if(tp>0 && sl>0 && ask >0)
              {
               trade.Buy(lotsize,_Symbol,ask,sl,tp,"Dark Point Buy");
              }
            Print("Tp: ",tp," Sl: ",sl);
         }
       if(dpSell[0]>0 || dpSellStar[0]>0)
         {
            Print("new Sell Signal: ",dpSell[0]);
            double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
            bid=NormalizeDouble(bid,_Digits);
            
            double tp=ObjectGetDouble(0,"DP_TP_Line_"+IntegerToString(TpLevel)+IntegerToString(iTime(_Symbol,PERIOD_CURRENT,1)),OBJPROP_PRICE);
            tp=NormalizeDouble(tp,_Digits);
            double sl=ObjectGetDouble(0,"DP_SL_Line_"+IntegerToString(SlLevel)+IntegerToString(iTime(_Symbol,PERIOD_CURRENT,1)),OBJPROP_PRICE);
            sl=NormalizeDouble(sl,_Digits);
            
            if(tp>0 && sl>0 && bid >0)
              {
               trade.Sell(lotsize,_Symbol,bid,sl,tp,"Dark Point Buy");
              }
            Print("Tp: ",tp," Sl: ",sl);
         }
     }
   
   
  }
