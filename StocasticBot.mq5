
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <testSkeleton.mqh>

#include <Trade/Trade.mqh>
CTrade trade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

input int HMAPeriod=100;
input ENUM_MA_METHOD HMAMethod=MODE_LWMA;
input ENUM_APPLIED_PRICE HMAPrice=PRICE_CLOSE;

int totalBars;

int handleStoch;
int handleHMA;

int OnInit()
  {
    handleStoch=iStochastic(_Symbol,PERIOD_CURRENT,5,3,3,MODE_SMA,STO_LOWHIGH);
    handleHMA=iCustom(_Symbol,PERIOD_CURRENT,"Market/HMA Color with Alerts MT5.ex5","",HMAPeriod,HMAMethod,HMAPrice,"",false,false,false,false,"","",false);
    totalBars=iBars(_Symbol,PERIOD_CURRENT);
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
      double hullbuffer[];
      CopyBuffer(handleHMA,0,1,2,hullbuffer);
      
      double main[];
          
      CopyBuffer(handleStoch,0,1,2,main);
      
        if(hullbuffer[0]<hullbuffer[1])
          {
            Print("Buy Now");
            if(main[1]>20 && main[0]<20)
            {
               ClosePosition(false);
               double entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
               double sl=entry-200*_Point;
               double tp=entry+400*_Point;
               sl=NormalizeDouble(sl,_Digits);
               tp=NormalizeDouble(tp,_Digits);
               entry=NormalizeDouble(entry,_Digits);
               double lots=CalculateLotSize(2,entry-sl);
               trade.Buy(lots,_Symbol,entry,sl,tp,"HMAStock Buy");
            }
          }
          if(hullbuffer[0]>hullbuffer[1])
          {
            Print("Sell Now");
            if(main[1]<80 && main[0]>80)
            {
               ClosePosition(true);
               double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
               double sl=entry+200*_Point;
               double tp=entry-400*_Point;
               sl=NormalizeDouble(sl,_Digits);
               tp=NormalizeDouble(tp,_Digits);
               entry=NormalizeDouble(entry,_Digits);
             
               trade.Sell(0.01,_Symbol,entry,sl,tp,"HMAStock Sell");
            }
          }
     }
  }
//+------------------------------------------------------------------+
void ClosePosition(int buy_sell)
{
       
    int total=PositionsTotal()-1;
    
    for(int i=total;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         ulong MagicNo=PositionGetInteger(POSITION_MAGIC);
         if(PositionSelectByTicket(ticket))
           {
              //if(MagicNo==InpMagicnumber)
                {
                  if(!buy_sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){ continue;}
                  if(buy_sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){ continue;}
                  trade.PositionClose(ticket);
                }
           }
      }
}