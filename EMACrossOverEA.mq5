#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include<Trade/Trade.mqh>
CTrade trade;

input int FastPeriod=10;
input int SlowPeriod=23;

input int TpPoints=600;
input int SlPoints=200;

input ulong InpMagicNumber=34938445;

input int Risk=2;


int handleFastEMA;
int handleSlowEMA;

int totalBars;

int OnInit()
  {
   
   handleFastEMA=iMA(_Symbol,PERIOD_CURRENT,FastPeriod,0,MODE_EMA,PRICE_MEDIAN);
   handleSlowEMA=iMA(_Symbol,PERIOD_CURRENT,SlowPeriod,0,MODE_EMA,PRICE_MEDIAN);
   totalBars=iBars(_Symbol,PERIOD_CURRENT);
   trade.SetExpertMagicNumber(InpMagicNumber);
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
    int bars=iBars(_Symbol,PERIOD_CURRENT);
    if(totalBars!=bars)
      {
       totalBars=bars;
       
       int cntBuy=0,cntSell=0;
       Countpositions(cntBuy,cntSell);
       
       double FastBuffer[],SlowBuffer[];
       CopyBuffer(handleFastEMA,0,1,2,FastBuffer);
       CopyBuffer(handleSlowEMA,0,1,2,SlowBuffer);
       
       if(SlowBuffer[0]>FastBuffer[0] && SlowBuffer[1]<FastBuffer[1])
         {
           Print("Buy Signal");
           ClosePosition(false);
           
           double entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
           
           double tp=entry+TpPoints*_Point;
           double sl=entry-SlPoints*_Point;
           
           tp=NormalizeDouble(tp,_Digits);
           sl=NormalizeDouble(sl,_Digits);
           
           double lots=CalculateLotSize(Risk,entry-sl);
           trade.Buy(lots,_Symbol,entry,sl,tp,"EMA CrossOver Buy");
           
         }
        if(SlowBuffer[0]<FastBuffer[0] && SlowBuffer[1]>FastBuffer[1] && cntSell==0)
         {
           Print("Sell Signal");
           ClosePosition(true);
           
           double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
           
           double tp=entry-TpPoints*_Point;
           double sl=entry+SlPoints*_Point;
           
           tp=NormalizeDouble(tp,_Digits);
           sl=NormalizeDouble(sl,_Digits);
           double lots=CalculateLotSize(Risk,sl-entry);
           trade.Sell(0.01,_Symbol,entry,sl,tp,"EMA CrossOver Sell");
         } 
       
      }
   
  }
  
void Countpositions(int &cntBuy,int &cntSell)
{
    cntBuy=0;
    cntSell=0;
    
    int total=PositionsTotal()-1;
    
    for(int i=total;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         ulong MagicNo=PositionGetInteger(POSITION_MAGIC);
         if(PositionSelectByTicket(ticket))
           {
              if(MagicNo==InpMagicNumber)
                {
                  if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){ cntBuy++;}
                  if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){ cntSell++;}
                }
           }
      }
}

void ClosePosition(int buy_sell)
{
       
    int total=PositionsTotal()-1;
    
    for(int i=total;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         ulong MagicNo=PositionGetInteger(POSITION_MAGIC);
         if(PositionSelectByTicket(ticket))
           {
              if(MagicNo==InpMagicNumber)
                {
                  if(!buy_sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){ continue;}
                  if(buy_sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){ continue;}
                  trade.PositionClose(ticket);
                }
           }
      }
}  

double CalculateLotSize(int Percent,double slDistance)
{
   double tickSize= SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue= SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double ticklotStep=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double ticklotMin=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double ticklotMax=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   
   Print("tickSize: ",tickSize," tickValue: ",tickValue," tickLotStep: ",ticklotStep," tickMin: ",ticklotMin," tickmax: ",ticklotMax);
   
   if(tickSize==0 || tickValue==0 || ticklotStep==0 )
     {
       return 0;
     }
     
   double riskMoney= AccountInfoDouble(ACCOUNT_EQUITY)*Percent/100;
   
   double moneyPerSmallestLotsize= (slDistance/tickSize)*tickValue*ticklotStep;
   Print("riskMoney: ",riskMoney," smallest you can riskMoney: ",moneyPerSmallestLotsize);
   if(moneyPerSmallestLotsize==0)
     {
      return 0;
     }
   double lotsFactor= (riskMoney/moneyPerSmallestLotsize);  
   double lots= MathFloor(riskMoney/moneyPerSmallestLotsize)* ticklotStep;
   if(moneyPerSmallestLotsize >riskMoney)
     {
      lots=ticklotMin;
     }
   if(lots > ticklotMax)
     {
      lots=ticklotMax;
     }  
   Print("The Lot Factor between the two is: ",lotsFactor);
   Print("The Lots size to be used: ",lots);
   return lots; 
    
}