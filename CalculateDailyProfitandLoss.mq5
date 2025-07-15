#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;


input double DailyProfitTarget=40; //Daily Profit Target in %
input double DailyLossStop=20; //Daily Stop in %


double profitClosed;

int totalbars;

int OnInit(){
   
   profitClosed=CalculateDailyProfitClosed();
   
   totalbars=iBars(_Symbol,PERIOD_CURRENT);
   
   return(INIT_SUCCEEDED);
  }
  
  
void OnDeinit(const int reason){

   
  }
void OnTick(){
  
     double accountBalance=AccountInfoDouble(ACCOUNT_BALANCE);
     double accountEquity=AccountInfoDouble(ACCOUNT_EQUITY);
     double profitOpen=accountEquity-accountBalance;
     double profitDay=profitOpen+profitClosed;
     
     
     
     
     
     Comment(" Profit Open: ",DoubleToString(profitOpen,2),
             " Profit Closed: ",DoubleToString(profitClosed,2),
             " Profit for the  Day: ",DoubleToString(profitDay,2),
             " Target Profit: ",DoubleToString((DailyProfitTarget*0.01*AccountInfoDouble(ACCOUNT_BALANCE)),2),
             " Stop Loss : ",DoubleToString((DailyLossStop*0.01*AccountInfoDouble(ACCOUNT_BALANCE)),2));
             
    if(profitDay >(DailyProfitTarget*0.01*AccountInfoDouble(ACCOUNT_BALANCE)) || profitDay <(DailyLossStop*0.01*AccountInfoDouble(ACCOUNT_BALANCE)))
      {
        for(int i=PositionsTotal()-1;i>=0;i--)
          {
            ulong posTicket=PositionGetTicket(i);
            trade.PositionClose(posTicket);
          }
      } 
      
      
      
      
      int bars=iBars(_Symbol,PERIOD_CURRENT);
      if(totalbars!=bars)
        {
         totalbars=bars;
         
           if(profitDay >DailyProfitTarget || profitDay <DailyLossStop)
            {
                Print("Cannot perform any trade Bro");
                Alert("Cannot perform any trade Bro");
            }else
               {
                trade.Buy(0.01);
               }
         
        }        
   
  }

void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
     if(trans.type==TRADE_TRANSACTION_DEAL_ADD)
       {
         profitClosed=CalculateDailyProfitClosed();
       }
   
  }  
  
  
double CalculateDailyProfitClosed()
{
   double profit=0;
   MqlDateTime dt;
   TimeTradeServer(dt);
   dt.hour=0;
   dt.min=0;
   dt.sec=0;
   
   datetime timeDaystart=StructToTime(dt);
   datetime timeNow = TimeTradeServer();
   
   HistorySelect(timeDaystart,timeNow+100);
   for(int i=HistoryDealsTotal()-1;i>=0;i--)
     {
        ulong dealTicket = HistoryDealGetTicket(i);
        //double dealProfit=HistoryDealGetDouble(dealTicket,DEAL_PROFIT);
        
        int dealType = (int)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
        if (dealType==DEAL_ENTRY_OUT)
         {
            
         
        
        //Print("Deal Ticket: ", dealTicket," profit: ",dealProfit);
        
       
         string symbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
         double volume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
         double price = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
         double mydealprofit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
         int type = (int)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
         ulong order = HistoryDealGetInteger(dealTicket, DEAL_ORDER);
         double commission= HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
         
         //Print("DealTicket: ", dealTicket,", Order: ", order,", Symbol: ", symbol,", Profit: ", profit,", commission ",commission);
               
            //calculate profit
              profit+=mydealprofit+commission; 
             //Print("Profit: ",DoubleToString(profit+=mydealprofit,2));  
               
            }   
            
         }
   return profit;
}  

