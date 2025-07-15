#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include<Trade/Trade.mqh>
CTrade trade;


int handleStocastic;
int totalbars;
static input ulong InpMagicNo=987644;

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
                  trade.Buy(0.01);
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
                    trade.Sell(0.01);
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
