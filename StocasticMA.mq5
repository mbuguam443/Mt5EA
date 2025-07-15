#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include<Trade/Trade.mqh>
CTrade trade;

input ulong InpMagicNumber=32456;

input bool InpMaFilter=false;

input double Lotsize=0.01;
input int TpDistance=5000;
input int SlDistance=600;

input ENUM_TIMEFRAMES stockTimeFrames=PERIOD_M15;
input int stockK=5;
input int stockD=3;
input int StockSlowing=3;

input double StockUpperLevel=80;
input double StockLowerLevel=20;


input ENUM_TIMEFRAMES MaTimeFrame=PERIOD_H1;
input int MaPeriod=100;
input ENUM_MA_METHOD MaMethod=MODE_SMA;

int totalBars;



int handleStoch;
int handleMA;

int OnInit()
  {
  
   totalBars=iBars(_Symbol,stockTimeFrames);
   handleStoch=iStochastic(_Symbol,stockTimeFrames,stockK,stockD,StockSlowing,MODE_SMA,STO_LOWHIGH);
   handleMA=iMA(_Symbol,MaTimeFrame,MaPeriod,0,MaMethod,PRICE_CLOSE);
   trade.SetExpertMagicNumber(InpMagicNumber);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   
  }
void OnTick()
  {
     int bars=iBars(_Symbol,stockTimeFrames);
     if(totalBars!=bars)
       {
        totalBars=bars;
        double stoch[];
        CopyBuffer(handleStoch,MAIN_LINE,1,2,stoch);
        ArraySetAsSeries(stoch,true);
        Print(" stoch[0]: ",stoch[0]," stock[1]: ",stoch[1]);
        
        double Ma[];
        CopyBuffer(handleMA,MAIN_LINE,1,1,Ma);
        Print("Ma: ",Ma[0]);
        
        
        double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
        double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        
        if(stoch[1]>StockUpperLevel && stoch[0]<StockUpperLevel)
          {
             
             if(!InpMaFilter || bid<Ma[0])
               {
                 //sell
                 double tp=bid-TpDistance*_Point;
                 tp=NormalizeDouble(tp,_Digits);
                 double sl=bid+SlDistance*_Point;
                 sl=NormalizeDouble(sl,_Digits);
                 
                 bid=NormalizeDouble(bid,_Digits);
                 Print("sl: ",sl," tp: ",tp);
                 
                 trade.Sell(Lotsize,_Symbol,bid,sl,tp,"StocasticMA Sell");
               }
          }
          
        if(stoch[1]<StockLowerLevel && stoch[0]>StockLowerLevel)
          {
             
             if(!InpMaFilter || ask>Ma[0])
               {
                 //Buy
                 
                 ask=NormalizeDouble(ask,_Digits);
                 double tp=ask+TpDistance*_Point;
                 tp=NormalizeDouble(tp,_Digits);
                 double sl=ask-SlDistance*_Point;
                 
                 Print("sl: ",sl," tp: ",tp);
                 trade.Buy(Lotsize,_Symbol,ask,sl,tp,"Stocastic Buy");
               }
          }
        
       }
     
   
  }

