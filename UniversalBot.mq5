//+------------------------------------------------------------------+
//|                                                 UniversalBot.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include<Trade/Trade.mqh>
CTrade trade;

int handleUniversalMT5;
int totalbars;

input double lotSize=0.01;

input int  TpPoint=600; //Take Profit in point
input int SlPoint=200; //Stop Loss in point
input int TrailingIndex=10;// Trailing index
input bool TrailingStopallowed=false;// Trailing Stop
input double PercentRisk=2;// % Risk percentage
input double LowestRiskAmount=10;

static input long InpMagicumber=976537;


int OnInit()
  {
   
   totalbars=iBars(_Symbol,PERIOD_CURRENT);
   handleUniversalMT5=iCustom(_Symbol,PERIOD_CURRENT,"Market/UniversalMA MT5.ex5");
   trade.SetExpertMagicNumber(InpMagicumber);
   if(handleUniversalMT5==INVALID_HANDLE)
     {
       Print("Indicated load Failed");
     }else
        {
         Print("Indicator Loaded successfully");
        }
   
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
        
        
        
        double signalUp[],signalDown[],Trend[];
        CopyBuffer(handleUniversalMT5,2,1,1,Trend);
        CopyBuffer(handleUniversalMT5,4,1,1,signalUp);
        CopyBuffer(handleUniversalMT5,5,1,1,signalDown);
        Print("Trend ",Trend[0],"Signal Up ",signalUp[0],"Signal Down", signalDown[0]);
        int cntBuy=0,cntSell=0;
        CountPosition(cntBuy,cntSell);
        Print("cntBuy: ",cntBuy," cntSell: ",cntSell);
        
        if(Trend[0] >0 && cntSell >0)
          {
           ClosePosition(false);
          }
          if(Trend[0] <0 && cntBuy >0)
          {
           ClosePosition(true);
          }
        if(signalUp[0]>0 && cntBuy==0)
          {
            Print("Buy Now ",signalUp[0]);
            double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            ask=NormalizeDouble(ask,_Digits);
            
            double tp=TpPoint==0?0:ask+TpPoint*_Point;
            tp=NormalizeDouble(tp,_Digits);
            double sl=SlPoint==0?signalUp[0]:ask-SlPoint*_Point;//;
            sl=NormalizeDouble(sl,_Digits);
          
            double lots=CalculateLotSize(PercentRisk,ask-sl);
            trade.Buy(lots,_Symbol,ask,sl,tp,"Universal Buy");
             
            
          }
          if(signalDown[0]>0 && cntSell==0)
          {
            Print("Sell Now", signalDown[0]);
            
            double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
            bid=NormalizeDouble(bid,_Digits);
            
            double tp=TpPoint==0?0:bid-TpPoint*_Point;
            tp=NormalizeDouble(tp,_Digits);
            double sl=SlPoint==0?signalDown[0]:bid+SlPoint*_Point;//
            sl=NormalizeDouble(sl,_Digits);
            double lots=CalculateLotSize(PercentRisk,sl-bid);
            trade.Sell(lots,_Symbol,bid,sl,tp,"Universal Sell");
             
            
          }
          if(TrailingStopallowed)
            {
               //TrailingStop();
               Print("countSell: ",cntSell," CountBuy: ",cntSell);
               if(cntBuy>0 )
                {
                  UpdateStopLoss(20);
                }
               if(cntSell>0)
                {
                 UpdateStopLoss(20);
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
           if(magicNo==InpMagicumber)
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
           if(magicNo==InpMagicumber)
             {
                if(!buy_Sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){continue;}
                if(buy_Sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){continue;}
                trade.PositionClose(ticket);
             }
         }
    }
  
 
}

void TrailingStop()
{
    
  int total=PositionsTotal()-1;
  for(int i=total;i>=0;i--)
    {
       ulong ticket=PositionGetTicket(i);
       long magicNo=PositionGetInteger(POSITION_MAGIC);
       double currlSl=PositionGetDouble(POSITION_SL);
       double currlTp=PositionGetDouble(POSITION_TP);
       double highestHigh=iHigh(_Symbol,PERIOD_CURRENT,iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,TrailingIndex,0));
       double lowestLow=iLow(_Symbol,PERIOD_CURRENT,iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,TrailingIndex,0));
       if(PositionSelectByTicket(ticket))
         {
           if(magicNo==InpMagicumber)
             {
                if(currlSl<lowestLow && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
                  lowestLow=NormalizeDouble(lowestLow,_Digits);
                  if(trade.PositionModify(ticket,lowestLow,currlTp))
                  {
                     Print("Buy Trade Modified");
                  }else{
                    Print("Sell Trade Modified Failed !!!");
                  }
                }
                if(currlSl > highestHigh && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
                  highestHigh=NormalizeDouble(highestHigh,_Digits);
                  if(trade.PositionModify(ticket,highestHigh,currlTp))
                  {
                    Print("Sell Trade Modified");
                  }else{
                    Print("Sell Trade Modified Failed !!!");
                  }
                }
             }
         }
    }
  
 
}
void trailing(int buy_sell)
{
    double trailingbuffer[];
    CopyBuffer(handleUniversalMT5,0,1,3,trailingbuffer);
       
    int total=PositionsTotal()-1;
    
    for(int i=total;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         ulong MagicNo=PositionGetInteger(POSITION_MAGIC);
         double currentSl=PositionGetDouble(POSITION_SL);
         
         if(PositionSelectByTicket(ticket))
           {
              if(MagicNo==MagicNo)
                {
                  if(buy_sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
                       if(currentSl<trailingbuffer[1])
                         {
                          trade.PositionModify(ticket,trailingbuffer[1],0);
                         }
                   }
                  if(!buy_sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){ 
                      if(currentSl>trailingbuffer[1])
                         {
                          trade.PositionModify(ticket,trailingbuffer[1],0);
                         }
                  }
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
     
   double riskMoney= AccountInfoDouble(ACCOUNT_EQUITY)*Percent*0.01;
   
   double moneyPerSmallestLotsize= (slDistance/tickSize)*tickValue*ticklotStep;
   Print("riskMoney: ",riskMoney," smallest you can riskMoney: ",moneyPerSmallestLotsize);
   if(moneyPerSmallestLotsize==0)
     {
      return 0;
     }
   double lotsFactor= (riskMoney/moneyPerSmallestLotsize);  
   double lots= MathFloor(riskMoney/moneyPerSmallestLotsize)* ticklotStep;
   Print("MathFloor: ",NormalizeDouble(riskMoney/moneyPerSmallestLotsize,2)," Without MathFloor: ",riskMoney/moneyPerSmallestLotsize);
   
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

void UpdateStopLoss(int slDistance)
{
   int total=PositionsTotal();
   for(int i=total-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket<=0){Print("Failed to get Position Ticket"); return;}
      if(!PositionSelectByTicket(ticket)){Print("Failed to select the ticket");return;}
      ulong magicnumber;
      if(!PositionGetInteger(POSITION_MAGIC,magicnumber)){Print("Failed to get Position Magic Number");return;}
      if(magicnumber==InpMagicumber)
        {
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get Position Type");return;}
         
         double currentSL,currentTP;
         if(!PositionGetDouble(POSITION_SL,currentSL)){Print("Failed to get current Position Stop Loss");return;}
         if(!PositionGetDouble(POSITION_TP,currentTP)){Print("Failed to get current Position Take Profit");return;}
         
         
         double currentPrice=type==POSITION_TYPE_BUY?SymbolInfoDouble(_Symbol,SYMBOL_BID) :SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         int n = type==POSITION_TYPE_BUY?1:-1;
         double newSL=currentPrice-slDistance*n*_Point;
         if(!NormalizePrice(newSL)){return;}
         
         if((newSL*n)<(currentSL*n) || NormalizeDouble(MathAbs(newSL-currentSL),_Digits)<_Point)
           {
             continue;
           }
         long level=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
         if(level!=0 && MathAbs(currentPrice-newSL)<=level*_Point)
           {
            Print("New Stop Loss inside Stop  Level");
            continue;
           } 
         if(!trade.PositionModify(ticket,newSL,currentTP))
           {
             Print("Failed to Modify new Sl ",ticket);
             return;
           }   
        }
     }

}

bool NormalizePrice(double &price)
{
  double tickSize=0;
  if(!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,tickSize))
    {
     Print("Failed to get Tick Size");
     return false;
    }
    price=NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
    return true;
}