#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include<Trade/Trade.mqh>
CTrade trade;

input string url="https://greatjourns.com/ForexRobot.php";


input double DailyProfitTarget=100;
input double DailyLossStop=-100;


int handleStocastic;
int totalbars;
static input ulong InpMagicNo=987644;
input int TpPoints=400;
input int SlPoints=200;
//input double lotsize=0.01;
input double PercentRisk=2;
input int LowestRiskAmount=3;




double profitClosed;

int OnInit()
  {
    //InternetAuth();
   profitClosed=CalculateDailyProfitClosed();
   
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
  
  
     double accountBalance=AccountInfoDouble(ACCOUNT_BALANCE);
     double accountEquity=AccountInfoDouble(ACCOUNT_EQUITY);
     double profitOpen=accountEquity-accountBalance;
     double profitDay=profitOpen+profitClosed;
     
     
     Comment(" Profit Open: ",DoubleToString(profitOpen,2),
             " Profit Closed: ",DoubleToString(profitClosed,2),
             " Profit for the  Day: ",DoubleToString(profitDay,2),
             " Target Profit: ",DoubleToString(DailyProfitTarget,2),
             " Stop Loss : ",DoubleToString(DailyLossStop,2));
             
       if(profitDay >DailyProfitTarget || profitDay <DailyLossStop)
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


int InternetAuth()
{
   if(!MQLInfoInteger(MQL_TESTER) )
      {
         char post[];
       int accountNumber=(int)AccountInfoInteger(ACCOUNT_LOGIN);
       Print("Account Number: ",accountNumber);
       string postText="account_no="+IntegerToString(accountNumber);
       StringToCharArray(postText,post,0,WHOLE_ARRAY,CP_UTF8);
       char result[];
       string resultHeaders;
       
       int response= WebRequest("POST",url,NULL,1000,post,result,resultHeaders);
       if(response==200)
         {
            Print("Response: ",response);
            Print("Results: ",CharArrayToString(result));
            string resultText=CharArrayToString(result);
            if(resultText!="success")
              {
                Alert("Send your Account No: to the developer for Auth:");
                ExpertRemove();
                return INIT_FAILED;
              }
         }else
            {
                Alert("Server error",GetLastError());
                return INIT_FAILED;
            }
      }
      
      return INIT_SUCCEEDED;
}