#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include<Trade/Trade.mqh>
CTrade trade;


int handleStocastic;
int totalbars;
static input ulong InpMagicNo=987644;
input int TpPoints=400;
input int SlPoints=200;
input double lotsize=0.01;
input double PercentRisk=2;
input int LowestRiskAmount=3;

int OnInit()
  {
   totalbars=iBars(_Symbol,PERIOD_CURRENT);
   handleStocastic=iStochastic(_Symbol,PERIOD_CURRENT,5,3,3,MODE_SMA,STO_LOWHIGH);
   trade.SetExpertMagicNumber(InpMagicNo);
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   
  }
void OnTick()
  {
       int bars=iBars(_Symbol,PERIOD_CURRENT);
       if(totalbars!=bars)
         {
          totalbars=bars;
          
          double signal[],main[];
          
          CopyBuffer(handleStocastic,0,1,2,main);
          CopyBuffer(handleStocastic,1,1,2,signal);
          
          int cntBuy=0,cntSell=0;
          
          CountPosition(cntBuy,cntSell);
          
          
          
          if(main[1]>20 && main[0]<20)
            {
             Print("Buy Now");
             if(cntSell>0)
               {
                ClosePosition(false); 
               }
               if(cntBuy==0)
                 {
                  double entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
                  double tp=entry+TpPoints*_Point;
                  double sl=entry-SlPoints*_Point;
                  
                  tp=NormalizeDouble(tp,_Digits);
                  sl=NormalizeDouble(sl,_Digits);
                  entry=NormalizeDouble(entry,_Digits);
                  double lots=CalculateLotSize(PercentRisk,entry-sl);
                  trade.Buy(lots,_Symbol,entry,sl,tp,"Stocastic Buy");
                 }else{
                 ClosePosition(true);
                 }
               
             
            }
            if(main[1]<80 && main[0]>80)
            {
             Print("Sell Now");
             if(cntBuy>0)
               {
                ClosePosition(true);
               }
               if(cntSell==0)
                 {
                     double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
                     double tp=entry-TpPoints*_Point;
                     double sl=entry+SlPoints*_Point;
                     
                     tp=NormalizeDouble(tp,_Digits);
                     sl=NormalizeDouble(sl,_Digits);
                     entry=NormalizeDouble(entry,_Digits);
                     double lots=CalculateLotSize(PercentRisk,sl-entry);
                     trade.Sell(lots,_Symbol,entry,sl,tp,"Stocastic Sell");
                 }else
                    {
                     ClosePosition(false);
                    }
              
             
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
           if(magicNo==InpMagicNo)
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
           if(magicNo==InpMagicNo)
             {
                if(!buy_Sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){continue;}
                if(buy_Sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){continue;}
                trade.PositionClose(ticket);
             }
         }
    }
  
 
}
double CalculateLotSize(double Percent,double slDistance)
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
      if(moneyPerSmallestLotsize > LowestRiskAmount)
        {
          return 0;
        }else
           {
             lots=ticklotMin;
           }
     
      
     }
   if(lots > ticklotMax)
     {
      lots=ticklotMax;
     }  
   Print("The Lot Factor between the two is: ",lotsFactor);
   Print("The Lots size to be used: ",lots);
   return lots; 
    
}