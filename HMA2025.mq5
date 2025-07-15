//+------------------------------------------------------------------+
//|                                                      HMA2025.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <RobotLibrary.mqh>
#include <Trade/Trade.mqh>
CTrade trade;

input int InpTpPoints=600; //Tp in points
input int InpSlPoints=200; //Tp in points
input ulong InpMagicNo=445654;
input int  RiskPercent=1;//% risk

input group "Slow Setting"
input int SlowPeriod=150;
input ENUM_MA_METHOD SlowMethod=MODE_LWMA;
input ENUM_APPLIED_PRICE SlowPrice=PRICE_CLOSE;

int handleHUllma;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNo);
   handleHUllma=iCustom(_Symbol,PERIOD_CURRENT,"Market/HMA Color with Alerts MT5.ex5","",SlowPeriod,SlowMethod,SlowPrice,"",false,false,false,false,"","",false);
   
   if(handleHUllma==INVALID_HANDLE){
     Print("Fast Indicator Failed");
    return INIT_FAILED;
   }
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
      //check for new Bar
      if(!IsNewBar()){return;}    
      
      double hullBuffer[];
      
      CopyBuffer(handleHUllma,0,1,4,hullBuffer);
      
      if(hullBuffer[2]<hullBuffer[1] && hullBuffer[1]>hullBuffer[0])
        {
         Print("Sell Now");
         double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         double sl=InpSlPoints==0?hullBuffer[2]: entry+InpSlPoints*_Point;
         sl=NormalizePrice(hullBuffer[2]);
         double tp=InpTpPoints==0?0:entry-InpTpPoints*_Point;
         tp=NormalizePrice(tp);
         entry=NormalizePrice(entry);
         double lots=CalculateLotSize(RiskPercent,sl-entry,0);
   
         if(trade.Sell(lots,_Symbol,entry,hullBuffer[3],tp))
           {
             Print("Buy Excuted successfully");
           }
    
        }
      if(hullBuffer[2]>hullBuffer[1] && hullBuffer[1]<hullBuffer[0])
        {
         Print("Buy Now");
         double entry =SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         double sl=InpSlPoints==0?entry-200*_Point: entry-InpSlPoints*_Point;
         sl=NormalizePrice(hullBuffer[2]);
         double tp=InpTpPoints==0?0:entry+InpTpPoints*_Point;
         tp=NormalizePrice(tp);
         entry=NormalizePrice(entry);
         
         double lots=CalculateLotSize(RiskPercent,entry-sl,0);
         if(trade.Buy(lots,_Symbol,entry,hullBuffer[3],tp))
           {
             Print("Buy Success");
           }
        }  
  }

