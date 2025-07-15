//+------------------------------------------------------------------+
//|                                      BrianKamauMovingAverage.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
CTrade trade;


input int Fast_MA=20;
input int Slow_MA=50;
input bool CloseOppositeSignal=true;

input int TakeProfitPoints=600;
input int StopLossPoints=200;
input double LotSize=0.01;



int handleMA;
int totalbars;

int OnInit()
  {
    
    totalbars=iBars(_Symbol,PERIOD_CURRENT);
    
    handleMA=iCustom(_Symbol,PERIOD_CURRENT,"Market/Moving Average Signal Alert.ex5",Fast_MA,Slow_MA,false,false,false);
    if(handleMA==INVALID_HANDLE)
      {
       Print("i was unable to get the indicator");
      }else
         {
          Print("Indicator loaded successfully with id: ",handleMA);
         }
      
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
    
    int bars=iBars(_Symbol,PERIOD_CURRENT);
    if(totalbars!=bars)
      {
       totalbars=bars;
       
       double buyBuffer[];
       
       CopyBuffer(handleMA,0,1,1,buyBuffer);
       
       
       double sellBuffer[];
       
       CopyBuffer(handleMA,1,1,1,sellBuffer);
       
       if(buyBuffer[0]!=EMPTY_VALUE)
         {
           Print("Buy Now");
           
           if(CloseOppositeSignal)
             {
              trade.PositionClose(_Symbol);
             }
           
           double entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
           double tp=TakeProfitPoints==0?0:entry+TakeProfitPoints*_Point;
           double sl=entry-StopLossPoints*_Point;
           
           tp=NormalizeDouble(tp,_Digits);
           sl=NormalizeDouble(sl,_Digits);
           
           trade.Buy(0.01,_Symbol,entry,sl,tp,"Buy Moving Average CrossOver");
           
         }
          if(sellBuffer[0]!=EMPTY_VALUE)
         {
          Print("Sell now");
          
          if(CloseOppositeSignal)
             {
              trade.PositionClose(_Symbol);
             }
          
           double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
           double tp=TakeProfitPoints==0?0:entry-TakeProfitPoints*_Point;
           double sl=entry+StopLossPoints*_Point;
           
           tp=NormalizeDouble(tp,_Digits);
           sl=NormalizeDouble(sl,_Digits);
           
           trade.Sell(0.01,_Symbol,entry,sl,tp,"Sell Moving Average CrossOver");
         }
       
      }
   
  }
//+------------------------------------------------------------------+
