#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;
input group "Trade Setting"
static input ulong InpMagicNumber=3763342;
input double LowestRiskAmount=3.0;

input double RiskPercentage=2.0;
input int SlPoints=200;
input int TpPoint=600;
input double exit=-20.0;


input group "Fast Setting"
input int FastPeriod=21;
input ENUM_MA_METHOD FastMethod=MODE_LWMA;
input ENUM_APPLIED_PRICE FastPrice=PRICE_CLOSE;

input group "Slow Setting"
input int SlowPeriod=150;
input ENUM_MA_METHOD SlowMethod=MODE_LWMA;
input ENUM_APPLIED_PRICE SlowPrice=PRICE_CLOSE;

int handleFastHMA;
int handleSlowHMA;
int totalBars;

int OnInit()
  {
   totalBars=iBars(_Symbol,PERIOD_CURRENT);
   handleFastHMA=iCustom(_Symbol,PERIOD_CURRENT,"Market/HMA Color with Alerts MT5.ex5","",FastPeriod,FastMethod,FastPrice,"",false,false,false,false,"","",false);
   handleSlowHMA=iCustom(_Symbol,PERIOD_CURRENT,"Market/HMA Color with Alerts MT5.ex5","",SlowPeriod,SlowMethod,SlowPrice,"",false,false,false,false,"","",false);
   
   if(handleFastHMA==INVALID_HANDLE){
     Print("Fast Indicator Failed");
    return INIT_FAILED;
   }else{
    Print("Fast ",FastPeriod," loaded successfully");
   }
   if(handleSlowHMA==INVALID_HANDLE){
     Print("Slow Indicator Failed");
    return INIT_FAILED;
   }else{
    Print("Slow ",SlowPeriod," loaded successfully");
   }
   trade.SetExpertMagicNumber(InpMagicNumber);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   
  }
void BlockBlow()
{
  if(AccountInfoDouble(ACCOUNT_EQUITY) <5)
    {
      int total=PositionsTotal()-1;
    
    for(int i=total;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         
         if(PositionSelectByTicket(ticket))
           {
              trade.PositionClose(ticket);
           }
      }
    }
}
void OnTick()
  {
    //BlockBlow();
    double Eq=AccountInfoDouble(ACCOUNT_EQUITY);
    
    if(Eq<=exit)
      {
       ClosePosition(true);
       ClosePosition(false);
       ExpertRemove();
      }
   int bars=iBars(_Symbol,PERIOD_CURRENT);
   if(totalBars!=bars)
     {
      totalBars=bars;
      
      
      int cntBuy=0,cntSell=0;
      Countpositions(cntBuy,cntSell);
      
      if(cntBuy>0 )
          {
            //trailing(true);
            UpdateStopLoss(SlPoints);
          }
        if(cntSell>0)
          {
           //trailing(false);
           UpdateStopLoss(SlPoints);
          }
      
      double fastBuffer[],slowBuffer[];
      
      CopyBuffer(handleFastHMA,0,1,3,fastBuffer);
      CopyBuffer(handleSlowHMA,0,1,2,slowBuffer);
      
      
      
      if(slowBuffer[1] > slowBuffer[0])
        {
          Print("Up Trend");
          if(cntSell>0)
           {
                 ClosePosition(false);
           }
           //Detecting Buy
          if(fastBuffer[2]>fastBuffer[1] && fastBuffer[1] <fastBuffer[0])
            {
              Print("We Buy Now ");
            
              double entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
              double tp=TpPoint==0?0: entry +TpPoint*_Point;
              double sl=entry-SlPoints*_Point;
              entry=NormalizeDouble(entry,_Digits);
              sl=NormalizeDouble(sl,_Digits);
              tp=NormalizeDouble(tp,_Digits);
              
              double lots=CalculateLotSize(RiskPercentage,entry-sl);
              trade.Buy(lots,_Symbol,entry,sl,tp," HMAFastSlow Buy");
            }
            if(fastBuffer[2]<fastBuffer[1] && fastBuffer[1] >fastBuffer[0])
            {
              if(cntBuy >0)
                  {
                    if(TpPoint==0)
                      {
                        ClosePosition(true);
                      }
                   
                  }
            }
            
            
             
        }
        if(slowBuffer[1] < slowBuffer[0])
        {
          Print("Down Trend");
          if(cntBuy>0 )
          {
            ClosePosition(true);
          }
          //Detect Sell
          if(fastBuffer[2]<fastBuffer[1] && fastBuffer[1] >fastBuffer[0])
            {
              Print("We Sell Now ");
              double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
              
              double tp=TpPoint==0?0:entry-TpPoint*_Point;
              double sl=entry+SlPoints*_Point;
              
              entry=NormalizeDouble(entry,_Digits);
              tp=NormalizeDouble(tp,_Digits);
              sl=NormalizeDouble(sl,_Digits);
              double lots=CalculateLotSize(RiskPercentage,sl-entry);
              trade.Sell(lots,_Symbol,entry,sl,tp," HMAFastSlow Sell");
            }
            if(fastBuffer[2]>fastBuffer[1] && fastBuffer[1] <fastBuffer[0])
            {
                if(cntSell >0)
                  {
                      if(TpPoint==0)
                        {
                          ClosePosition(false);
                        }
                   
                  }
            }
          
         
            
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
void trailing(int buy_sell)
{
    double trailingbuffer[];
    CopyBuffer(handleFastHMA,0,1,4,trailingbuffer);
       
    int total=PositionsTotal()-1;
    
    for(int i=total;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         ulong MagicNo=PositionGetInteger(POSITION_MAGIC);
         double currentSl=PositionGetDouble(POSITION_SL);
         
         if(PositionSelectByTicket(ticket))
           {
              if(MagicNo==InpMagicNumber)
                {
                  if(buy_sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
                       if(currentSl<trailingbuffer[1])
                         {
                          trade.PositionModify(ticket,trailingbuffer[0],0);
                         }
                   }
                  if(!buy_sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){ 
                      if(currentSl>trailingbuffer[1])
                         {
                          trade.PositionModify(ticket,trailingbuffer[0],0);
                         }
                  }
                }
           }
      }
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
      if(magicnumber==InpMagicNumber)
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
//5080@Kim
//Normalize Price Function
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