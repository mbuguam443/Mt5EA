#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
CTrade trade;

static long InpMagicNumber=495994;
input  double  step=0.02;
input  double  maximum=0.2;
input  int     TpPoints=600;
input  int     SlPoints=200;
input  int     RiskPercentage=2;


int handleSAR;
int totalBars;

int OnInit()
  {

   totalBars=iBars(_Symbol,PERIOD_CURRENT);
   handleSAR=iSAR(_Symbol,PERIOD_CURRENT,step,maximum);
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
        double SARBuffer[];
        
        CopyBuffer(handleSAR,0,1,2,SARBuffer);
        double high1=iHigh(_Symbol,PERIOD_CURRENT,1);
        double low1=iLow(_Symbol,PERIOD_CURRENT,1);
        
        double high2=iHigh(_Symbol,PERIOD_CURRENT,2);
        double low2=iLow(_Symbol,PERIOD_CURRENT,2);
        
        if(SARBuffer[0]>high2 && SARBuffer[1]<low1)
          {
            Print("Buy Now");
            double entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            double sl=SlPoints==0?SARBuffer[1]:entry-SlPoints*_Point;
            double tp=TpPoints==0?0:entry+TpPoints*_Point;
           
           tp=NormalizeDouble(tp,_Digits);
           sl=NormalizeDouble(sl,_Digits);
           
           double lots=CalculateLotSize(RiskPercentage,entry-sl);
           trade.Buy(lots,_Symbol,entry,sl,tp,"Buy PAR robo");
          }
          if(SARBuffer[0]<low2 && SARBuffer[1]>high1)
          {
            Print("Sell Now");
            double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
            double sl=SlPoints==0?SARBuffer[1]:entry+SlPoints*_Point;
            double tp=TpPoints==0?0:entry-TpPoints*_Point;
            double lots=CalculateLotSize(RiskPercentage,sl-entry);
            trade.Sell(lots,_Symbol,entry,sl,tp,"Sell PAR robo");
          }
          
        TrailingtheDot();  
       }
  }


void TrailingtheDot()
{
   int total=PositionsTotal();
   for(int i=total-1;i>=0;i--)
     {
        ulong ticket=PositionGetTicket(i);
        ulong magicno=PositionGetInteger(POSITION_MAGIC);
        double currentTp=PositionGetDouble(POSITION_TP);
        
        if(PositionSelectByTicket(ticket))
          {
            if(magicno==InpMagicNumber)
              {
                 double SARBuffer[];
                 CopyBuffer(handleSAR,0,0,2,SARBuffer);
                 if(!trade.PositionModify(_Symbol,SARBuffer[1],currentTp))
                   {
                    Print("Error Modifying the Position: ticket :",ticket);
                   }
                 
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
