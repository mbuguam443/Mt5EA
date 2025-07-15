#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;

input string url="https://greatjourns.com/ForexRobot.php";

input double DailyProfitTarget=200;
input double DailyLossStop=200;

double profitClosed;


input group "Trade Setting"
static input ulong InpMagicNumber=3763342;
input double LowestRiskAmount=3.0;

input double RiskPercentage=2.0;
input int SlPoints=200;
input int TpPoint=600;


input group "Fast Setting"
input int FastPeriod=21;
input ENUM_MA_METHOD FastMethod=MODE_LWMA;
input ENUM_APPLIED_PRICE FastPrice=PRICE_CLOSE;
input ENUM_TIMEFRAMES FastTimeFrame=PERIOD_CURRENT;

input group "Slow Setting"
input int SlowPeriod=150;
input ENUM_MA_METHOD SlowMethod=MODE_LWMA;
input ENUM_APPLIED_PRICE SlowPrice=PRICE_CLOSE;
input ENUM_TIMEFRAMES SlowTimeFrame=PERIOD_CURRENT;

int handleFastHMA;
int handleSlowHMA;
int totalBars;

int OnInit()
  {
    
    InternetAuth();
    
   profitClosed=CalculateDailyProfitClosed(); 
    
   totalBars=iBars(_Symbol,PERIOD_CURRENT);
   handleFastHMA=iCustom(_Symbol,FastTimeFrame,"Market/HMA Color with Alerts MT5.ex5","",FastPeriod,FastMethod,FastPrice,"",false,false,false,false,"","",false);
   handleSlowHMA=iCustom(_Symbol,SlowTimeFrame,"Market/HMA Color with Alerts MT5.ex5","",SlowPeriod,SlowMethod,SlowPrice,"",false,false,false,false,"","",false);
   
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
   //authorization of the Robot Expert advisor
   //Authorization();
   
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
  
  
    //BlockBlow();
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
              
              Print("get back slDistance: ",(entry-sl));
              double lots=CalculateLotSize(RiskPercentage,(entry-sl));
              if(profitDay >DailyProfitTarget || profitDay <DailyLossStop)
              {
               Print("Buy cannot Safeguard account");
              }else
                 {
                   trade.Buy(lots,_Symbol,entry,sl,tp," HMAFastSlow Buy");
                 }
             
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
              Print("get back slDistance: ",(sl-entry));
              double lots=CalculateLotSize(RiskPercentage,(sl-entry));
              
              if(profitDay >DailyProfitTarget || profitDay <DailyLossStop)
              {
                Print("Sell No  safegaurd");
              }else
              {
                  trade.Sell(lots,_Symbol,entry,sl,tp," HMAFastSlow Sell");
              }
              
              
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
   Print("SlDisatnce: ",DoubleToString(slDistance, 2),"Total tickSize for Distance: ",DoubleToString(slDistance/tickSize, 2)," riskMoney: ",DoubleToString(riskMoney, 2)," smallest you can riskMoney: ",moneyPerSmallestLotsize);
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
      ulong magicnumber=9;
      if(magicnumber!=PositionGetInteger(POSITION_MAGIC)){Print("Failed to get Position Magic Number");return;}
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

int  Authorization()
{
    long AuthuserAccount=2000903183;
    
    long availableAccount=AccountInfoInteger(ACCOUNT_LOGIN);
    // Authorized: 10419166
    Print("Login ",availableAccount," Authorized: ",AuthuserAccount);
    
    if(availableAccount==AuthuserAccount)
      {
        Print("License is valid");
      }else{
        Print("License invalid");
        ExpertRemove();
        return INIT_FAILED;
      }
      
      
    if(TimeCurrent() < StringToTime("2025.03.10"))
      {
        Print("Robot is Valid");
      }else{
        Print("Robot Expired ");
        ExpertRemove();
        return INIT_FAILED;
      }
      
      return INIT_SUCCEEDED;
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