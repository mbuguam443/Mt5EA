#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include<Trade/Trade.mqh>
CTrade trade;

input ulong InpMagicNumber=32456;


input double PercentRisk=0.1;
input int TpDistance=1500;
input int SlDistance=600;
input int LowestRiskAmount=8;

input ENUM_TIMEFRAMES stockTimeFrames=PERIOD_M15;
input int stockK=5;
input int stockD=3;
input int StockSlowing=3;

input double StockUpperLevel=80;
input double StockLowerLevel=20;


input ENUM_TIMEFRAMES MaTimeFrame=PERIOD_H1;
input int MaPeriod=100;
input ENUM_MA_METHOD MaMethod=MODE_SMA;

int totalBars;



int handleStoch;
int handleMA;

input double DailyProfitTarget=100;
input double DailyLossStop=-100;


double profitClosed;

int OnInit()
  {
    
   profitClosed=CalculateDailyProfitClosed(); 
    
   totalBars=iBars(_Symbol,stockTimeFrames);
   handleStoch=iStochastic(_Symbol,stockTimeFrames,stockK,stockD,StockSlowing,MODE_SMA,STO_LOWHIGH);
   handleMA=iMA(_Symbol,MaTimeFrame,MaPeriod,0,MaMethod,PRICE_CLOSE);
   trade.SetExpertMagicNumber(InpMagicNumber);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   
  }
void OnTick()
  {
  
  
     double accountBalance=AccountInfoDouble(ACCOUNT_BALANCE);
     double accountEquity=AccountInfoDouble(ACCOUNT_EQUITY);
     double profitOpen=accountEquity-accountBalance;
     double profitDay=profitOpen+profitClosed;
     
     Print("ProfitOpen: ",DoubleToString(profitOpen,2));
     
     
     
     
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
  
     
  
     int bars=iBars(_Symbol,stockTimeFrames);
     if(totalBars!=bars)
       {
        totalBars=bars;
        double stoch[];
        CopyBuffer(handleStoch,MAIN_LINE,1,2,stoch);
        ArraySetAsSeries(stoch,true);
        Print(" stoch[0]: ",stoch[0]," stock[1]: ",stoch[1]);
        
        double Ma[];
        CopyBuffer(handleMA,MAIN_LINE,1,1,Ma);
        Print("Ma: ",Ma[0]);
        
        
        double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
        double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
        
        if(stoch[1]>StockUpperLevel && stoch[0]<StockUpperLevel)
          {
             
             if(bid<Ma[0])
               {
                 //sell
                 double tp=bid-TpDistance*_Point;
                 tp=NormalizeDouble(tp,_Digits);
                 double sl=bid+SlDistance*_Point;
                 sl=NormalizeDouble(sl,_Digits);
                 
                 bid=NormalizeDouble(bid,_Digits);
                       if(profitDay >DailyProfitTarget || profitDay <DailyLossStop)
                        {
                            Print("Cannot perform any trade Bro");
                            Alert("Cannot perform any trade Bro");
                        }else
                           {
                           double lots=CalculateLotSize(PercentRisk,sl-bid);
                           trade.Sell(lots,_Symbol,bid,sl,tp,"StocasticMA Sell");
                         }
               }
          }
          
        if(stoch[1]<StockLowerLevel && stoch[0]>StockLowerLevel)
          {
             
             if(ask>Ma[0])
               {
                 //Buy
                 
                 ask=NormalizeDouble(ask,_Digits);
                 double tp=ask+TpDistance*_Point;
                 tp=NormalizeDouble(tp,_Digits);
                 double sl=ask-SlDistance*_Point;
                   
                   if(profitDay >DailyProfitTarget || profitDay <DailyLossStop)
                     {
                            Print("Cannot perform any trade Bro");
                            Alert("Cannot perform any trade Bro");
                     }else
                     {
                           double lots=CalculateLotSize(PercentRisk,ask-sl); 
                           trade.Buy(lots,_Symbol,ask,sl,tp,"StocasticMA Buy");
                     }
               }
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