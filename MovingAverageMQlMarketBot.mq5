#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade/Trade.mqh>
CTrade trade;

static input ulong InpMagNo=98653;
input int FastMA=20;
input int SlowMA=50;
input int TpPoints=600;
input int SlPoints=200;

int handleMovingAverage;
int totalBars;


int OnInit()
  {

    totalBars=iBars(_Symbol,PERIOD_CURRENT);
    handleMovingAverage=iCustom(_Symbol,PERIOD_CURRENT,"Market\\Moving Average Signal Alert.ex5",FastMA,SlowMA,false,false,false);
    if(handleMovingAverage==INVALID_HANDLE)
      {
        Print("Moving Average Indactor loading Failed");
      }else{
        Print("Indicator Loaded successfully");
      }
      trade.SetExpertMagicNumber(InpMagNo);
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
       double BuySignal[],SellSignal[];
     
        CopyBuffer(handleMovingAverage,0,1,1,BuySignal);
        CopyBuffer(handleMovingAverage,1,1,1,SellSignal);
        
        int cntBuy=0,cntSell=0;
        CountPosition(cntBuy,cntSell);
        
        
        if(BuySignal[0]!=EMPTY_VALUE)
          {
            Print("We have a Buy Signal");
            double entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            double tp=TpPoints==0?0:entry+TpPoints*_Point;
            double sl=SlPoints==0?BuySignal[0]:entry-SlPoints*_Point;
            tp=NormalizeDouble(tp,_Digits);
            sl=NormalizeDouble(sl,_Digits);
            entry=NormalizeDouble(entry,_Digits);
            if(cntSell>0)
              {
               ClosePosition(false);
              }
            trade.Buy(0.01,_Symbol,entry,sl,tp,"Moving Average Buy");
          }
        if(SellSignal[0]!=EMPTY_VALUE)
          {
           Print("we have a Sell Signal");
           double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
           double tp=TpPoints==0?0:entry-TpPoints*_Point;
           double sl=SlPoints==0?SellSignal[0]:entry+SlPoints*_Point;
            tp=NormalizeDouble(tp,_Digits);
            sl=NormalizeDouble(sl,_Digits);
            entry=NormalizeDouble(entry,_Digits);
           if(cntBuy>0)
             {
              ClosePosition(true);
             }
           trade.Sell(0.01,_Symbol,entry,sl,tp,"Moving Average Sell");
          }  
      }
     
     
  }

void CountPosition(int &cntBuy,int &cntSell)
{
  cntBuy=0;
  cntSell=0;
   
  int total=PositionsTotal()-1;
  for(int i=total;i>=0;i--)
    {
       ulong ticket=PositionGetTicket(i);
       long magicNo=PositionGetInteger(POSITION_MAGIC);
       if(PositionSelectByTicket(ticket))
         {
           if(magicNo==InpMagNo)
             {
                if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){cntBuy++;}
                if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){cntSell++;}
             }
         }
    }
  
 
}


void ClosePosition(bool buy_Sell)
{
    
  int total=PositionsTotal()-1;
  for(int i=total;i>=0;i--)
    {
       ulong ticket=PositionGetTicket(i);
       long magicNo=PositionGetInteger(POSITION_MAGIC);
       if(PositionSelectByTicket(ticket))
         {
           if(magicNo==InpMagNo)
             {
                if(!buy_Sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){continue;}
                if(buy_Sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){continue;}
                trade.PositionClose(ticket);
             }
         }
    }
  
 
}