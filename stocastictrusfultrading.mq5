//+------------------------------------------------------------------+
//|                                      stocastictrusfultrading.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|Includes                                                          |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
//+------------------------------------------------------------------+
//|Inputs                                                            |
//+------------------------------------------------------------------+
input group "=====General===="
static input long InpMagicnumber=98765; //magic number
static input double InpLotSize=0.01; //Lot Size

input group "====Trading====="
input int    InpStopLoss=200;       //stop loss in points (0=off)
input int    InpTakeProfit=600;       //Take Profit in points (0=off)
input bool   InpCloseSignal=true;  //Close trade by opposite signal
input group "====Stocastic====="
input int    InpKperiod=5;          // K Period
input int    InpUpperLevel=80;      // UpperLevel
input int    LowestRiskAmount=5;    //lowest to risk

//+------------------------------------------------------------------+
//|Global Variable                                                   |
//+------------------------------------------------------------------+
int handle;
double bufferMain[];
MqlTick cT;
CTrade trade;
int totalbars;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
    //get the bars
    totalbars=iBars(_Symbol,PERIOD_CURRENT);
    
    //check user inputs
    if(!CheckUserInput()){ return INIT_PARAMETERS_INCORRECT;}
    
    //set magic number
    trade.SetExpertMagicNumber(InpMagicnumber);
    
    //create indicator handle
    handle=iStochastic(_Symbol,PERIOD_CURRENT,InpKperiod,1,3,MODE_SMA,STO_LOWHIGH);
    
    if(handle==INVALID_HANDLE)
      {
       Alert("Failed to create indicator hande");
       return INIT_FAILED;
      }
      
      ArraySetAsSeries(bufferMain,true);
    
    
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
    // we release the indicator
    if(handle!=INVALID_HANDLE)
      {
       IndicatorRelease(handle);
      }   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
    //count open position
    int coutBuy,coutSell;
    Countpositions(coutBuy,coutSell);
    
    //check for open bar
    int bars=iBars(_Symbol,PERIOD_CURRENT);
    if(totalbars!=bars)
      {
       totalbars=bars;
       Comment("Open Buy Position: ",coutBuy," Sell Position: ",coutSell);
       //get current tick
       if(!SymbolInfoTick(_Symbol,cT)){Print("Failed to get Current Tick");}
       //get the current value
       if(CopyBuffer(handle,0,1,2,bufferMain)!=2)
         {
          Print("Failed to get Indicator values");
          return;
         } 
         
       //check for buy Position
       if(coutBuy==0 && bufferMain[0]>=(100-InpUpperLevel) && bufferMain[1]<=(100-InpUpperLevel))
         {
           Print("Buy Now");
           if(InpCloseSignal)
             {
                ClosePosition(false);
             }
             
           double sl=InpStopLoss==0?0:cT.bid-InpStopLoss*_Point;
           double tp=InpTakeProfit==0?0:cT.bid+InpTakeProfit*_Point;
           
           sl=NormalizeDouble(sl,_Digits);
           tp=NormalizeDouble(tp,_Digits);
           trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,InpLotSize,cT.ask,sl,tp,"stocastic EA Buy");
           
         } 
         
        //check for Sell Position
       if(coutSell==0 && bufferMain[0]<=(InpUpperLevel) && bufferMain[1]>=(InpUpperLevel))
         {
           Print("Sell Now");
           if(InpCloseSignal)
             {
                ClosePosition(true);
             }
           double sl=InpStopLoss==0?0:cT.ask+InpStopLoss*_Point;
           double tp=InpTakeProfit==0?0:cT.ask-InpTakeProfit*_Point;
           
           sl=NormalizeDouble(sl,_Digits);
           tp=NormalizeDouble(tp,_Digits);
           trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,InpLotSize,cT.ask,sl,tp,"stocastic EA Sell");  
         }   
       
      }
    ;
      
      
  }
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+

bool CheckUserInput()
{
  
   if(InpMagicnumber<=0)
     {
      Alert("wrong InpMagicnumber<=0");
      return false;
     }
   if(InpLotSize<=0 || InpLotSize>=10 )
     {
      Alert("wrong InpLotSize InpLotSize<=0 || InpLotSize>=10");
      return false;
     } 
   if(InpStopLoss<0)
     {
      Alert("wrong InpStopLoss <0");
      return false;
     }
    if(InpTakeProfit<0)
     {
      Alert("wrong InpTakeProfit <0");
      return false;
     }
    if(!InpCloseSignal && InpStopLoss==0)
     {
      Alert("wrong InpCloseSignal is false and  InpStopLoss==0");
      return false;
     }
     if(InpKperiod<=0)
     {
      Alert("wrong input  InpKperiod <=0");
      return false;
     }
     if(InpUpperLevel<=50 || InpUpperLevel>=100)
     {
      Alert("wrong input  InpUpperLevel<=50 or InpUpperLevel>=100");
      return false;
     }     
  
  return true;
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
              if(MagicNo==InpMagicnumber)
                {
                  if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){ cntBuy++;}
                  if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){ cntSell++;}
                }
           }
      }
}

void ClosePosition(bool buy_sell)
{
       
    int total=PositionsTotal()-1;
    
    for(int i=total;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         ulong MagicNo=PositionGetInteger(POSITION_MAGIC);
         if(PositionSelectByTicket(ticket))
           {
              if(MagicNo==InpMagicnumber)
                {
                  if(!buy_sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){ continue;}
                  if(buy_sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){ continue;}
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