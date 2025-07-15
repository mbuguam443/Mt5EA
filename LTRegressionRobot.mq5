//+------------------------------------------------------------------+
//|                                            LTRegressionRobot.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade/Trade.mqh>
CTrade trade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int handleLTRegression;

int totalBars;
int OnInit()
  {
   
   totalBars=iBars(_Symbol,PERIOD_CURRENT);
   
   handleLTRegression=iCustom(_Symbol,PERIOD_CURRENT,"Market/LT Regression Chanel MT5.ex5");
   if(handleLTRegression==INVALID_HANDLE)
     {
      Print("Failed to load indicator");
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
    if(totalBars!=bars)
      {
       totalBars=bars;
       
       double mainBuffer[];
       CopyBuffer(handleLTRegression,0,1,1,mainBuffer);
       //Print("Main Buffer: ",mainBuffer[0]);
       
       //Upper Zone
       double Buffer1[];
       CopyBuffer(handleLTRegression,1,1,1,Buffer1);
       //Print("Buffer1: ",Buffer1[0]);
       
       double Buffer2[];
       CopyBuffer(handleLTRegression,2,1,1,Buffer2);
       //Print("Buffer2: ",Buffer2[0]);
       
       double Buffer3[];
       CopyBuffer(handleLTRegression,3,1,1,Buffer3);
       //Print("Buffer3: ",Buffer3[0]);
       
       //Lower Zone
       double Buffer4[];
       CopyBuffer(handleLTRegression,4,1,1,Buffer4);
       //Print("Buffer4: ",Buffer4[0]);
       
       double Buffer5[];
       CopyBuffer(handleLTRegression,5,1,1,Buffer5);
       //Print("Buffer5: ",Buffer5[0]);
       
       double Buffer6[];
       CopyBuffer(handleLTRegression,6,1,1,Buffer6);
       //Print("Buffer6: ",Buffer6[0]);
       
       //last Candle Close and High
       
      double askPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double bidPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      
      if(askPrice <=Buffer5[0])
        {
          Print("Buy Now");
          trade.Buy(0.01,_Symbol,askPrice,Buffer6[0],Buffer1[0],"LTR Buy");
        }
        
      if(bidPrice >=Buffer2[0])
        {
          Print("Sell Now");
          trade.Sell(0.01,_Symbol,bidPrice,Buffer3[0],Buffer4[0],"LTR Sell");
        }  
       
       
       
       
      }
  }
//+------------------------------------------------------------------+
