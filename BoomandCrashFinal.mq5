#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade/Trade.mqh>
CTrade trade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

static input ulong InputMagNo=983833;
input int ATRPeriod=14;
input int TrailingIndex=20;
input bool AllowTrailing=true;

int handleBoomandCrash;
int totalBars;

int OnInit()
  {
   
   totalBars=iBars(_Symbol,PERIOD_CURRENT);
   handleBoomandCrash=iCustom(_Symbol,PERIOD_CURRENT,"Market\\Boom and crash smasher.ex5",ATRPeriod,1,false,0,false,false);
   if(handleBoomandCrash==INVALID_HANDLE)
     {
       Print("Boom Indicator Failed to load");
     }else{
       Print("Boom Indicator loaded successfully");
     }
     trade.SetExpertMagicNumber(InputMagNo);
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
        
        int cntBuy=0,cntSell=0;
        
        CountPosition(cntBuy,cntSell);
        
        
        double smashSell[],smashBuy[];
        
        CopyBuffer(handleBoomandCrash,0,1,1,smashSell);
        CopyBuffer(handleBoomandCrash,1,1,1,smashBuy);
        
        if(smashSell[0] >0)
          {
              Print("Time to Sell");
              if(cntBuy>0)
                {
                 ClosePosition(true);
                }
              double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
              
              trade.Sell(0.01,_Symbol,entry,smashSell[0],0," Boom Sell");
          }
        if(smashBuy[0]>0)
          {
            Print("Time to Buy");
            if(cntSell>0)
              {
               ClosePosition(false);
              }
            double entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            trade.Buy(0.01,_Symbol,entry,smashBuy[0],0," Boom Buy");
          } 
          
          if(AllowTrailing)
            {
              if(cntBuy >0)
               {
                UpdateStopLoss(200);
               } 
              if(cntSell >0)
               {
                UpdateStopLoss(200);
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
           if(magicNo==InputMagNo)
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
           if(magicNo==InputMagNo)
             {
                if(!buy_Sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){continue;}
                if(buy_Sell && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){continue;}
                trade.PositionClose(ticket);
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
      if(magicnumber==InputMagNo)
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