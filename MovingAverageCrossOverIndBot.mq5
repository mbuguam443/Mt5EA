//+------------------------------------------------------------------+
//|                                 MovingAverageCrossOverIndBot.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

static input ulong InpMagicNumber=99742;
input int FastMA=20;
input int SlowMA=50;

input int SlPoints=0;
input int TpPoints=0; //TpPoint 0=off



int handleMovingCross;
int totalBars;

int OnInit()
  {
   totalBars=iBars(_Symbol,PERIOD_CURRENT);
   handleMovingCross=iCustom(_Symbol,PERIOD_CURRENT,"Market//Moving Average Signal Alert.ex5",FastMA,SlowMA,false,false,false);
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
       double fastBuffer[],slowBuffer[];
       CopyBuffer(handleMovingCross,2,1,2,fastBuffer);
       CopyBuffer(handleMovingCross,4,1,2,slowBuffer);
       //Print("FastBuffer[1]:",fastBuffer[1],"SlowBuffer[1]:",slowBuffer[1],"|||FastBuffer[0]:",fastBuffer[0],"SlowBuffer[0]:",slowBuffer[0]);
       int cntBuy=0,cntSell=0;
       Countpositions(cntBuy,cntSell);
       if(fastBuffer[0]>fastBuffer[1])
         {
          ClosePosition(false);
         }
       if(fastBuffer[0]<fastBuffer[1])
         {
          ClosePosition(true);
         }  
         
       if(fastBuffer[0] >slowBuffer[0] && fastBuffer[1] <slowBuffer[1])
         {
           Print("Sell Now");
           if(cntBuy>0)
             {
              ClosePosition(true);
             }
           double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
           double sl=SlPoints==0?fastBuffer[0] : entry+SlPoints*_Point;
           double tp=TpPoints==0?0:entry-TpPoints*_Point;
           
           tp=NormalizeDouble(tp,_Digits);
           sl=NormalizeDouble(sl,_Digits);
           
           //trade.Sell(0.01,_Symbol,entry,sl,tp,"MQL5 movingaverageCrossover Sell");
           trade.Sell(0.01);
         }
       if(fastBuffer[0] <slowBuffer[0] && fastBuffer[1] >slowBuffer[1])
         {
           Print("Buy Now");
           if(cntSell>0)
             {
              ClosePosition(false);
             }
           double entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
           double sl=SlPoints==0?fastBuffer[0]: entry-SlPoints*_Point;
           double tp=TpPoints==0?0:entry+TpPoints*_Point;
           
           tp=NormalizeDouble(tp,_Digits);
           sl=NormalizeDouble(sl,_Digits);
           
           //trade.Buy(0.01,_Symbol,entry,sl,tp,"MQL5 movingaverageCrossover Buy");
           trade.Buy(0.01);
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