#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|include                                                           |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//|inputs                                                            |
//+------------------------------------------------------------------+
static input long     InpMagicnumber      =5887474; //Magic Number
input  int            InpPeriod           =21;      //Period
input  double         InpDeviation        =2.0;     // Deviation
input  bool           InpStopLossTrailing =false;    // Trailing stop loss ?
input  int            InpStopLoss         =100;     // Stop Loss in points  (0=off)
input  int            InpTakeProfit       =200;     // Take Profit in points (0=off)

//---------Lot configuration
enum LOT_MODE_ENUM {
   LOT_MODE_FIXED,                                //Fixed lot mode
   LOT_MODE_MONEY,                                //lots based on money
   LOT_MODE_PCT_ACCOUNT                           //lots based on % of account
};
static input LOT_MODE_ENUM    InpLotMode       = LOT_MODE_FIXED; // lot mode
static input double    InpLotSize       =0.01;    // lots/money/ percent
//---------End Lot Configuration

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
int handle;
double upperBuffer[];
double baseBuffer[];
double lowerBuffer[];
MqlTick currentTick;
CTrade trade;
datetime openTimeBuy=0;
datetime openTimeSell=0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
     if(InpMagicnumber <=0)
       {
        Alert("Magicnumber <=0");
        return INIT_PARAMETERS_INCORRECT;
       }
     if(InpLotMode==LOT_MODE_FIXED && (InpLotSize <=0 || InpLotSize > 1))
       {
        Alert("Lot Size <=0 or > 1 ");
        return INIT_PARAMETERS_INCORRECT;
       }
      if(InpLotMode==LOT_MODE_MONEY && (InpLotSize <=0 || InpLotSize > 20))
       {
        Alert("Lot Size <=0 or > 20 ");
        return INIT_PARAMETERS_INCORRECT;
       }
       if(InpLotMode==LOT_MODE_PCT_ACCOUNT && (InpLotSize <=0 || InpLotSize > 5))
       {
        Alert("Lot Size <=0 or > 5 ");
        return INIT_PARAMETERS_INCORRECT;
       }
       if((InpLotMode==LOT_MODE_MONEY || InpLotMode==LOT_MODE_PCT_ACCOUNT) && InpStopLoss==0)
       {
          Alert("selected lot mode need a stop loss");
         return INIT_PARAMETERS_INCORRECT;
       } 
      if(InpPeriod <=1)
       {
        Alert("Period <=1");
        return INIT_PARAMETERS_INCORRECT;
       }
       if(InpDeviation <=0)
       {
        Alert("Deviation <=0");
        return INIT_PARAMETERS_INCORRECT;
       } 
       if(InpStopLoss <=0)
       {
        Alert("Stop Loss <=0");
        return INIT_PARAMETERS_INCORRECT;
       }
       if(InpTakeProfit <0)
       {
        Alert("Take Profit <0");
        return INIT_PARAMETERS_INCORRECT;
       }
      //set Magic Number
      trade.SetExpertMagicNumber(InpMagicnumber);  
      
      handle=iBands(_Symbol,PERIOD_CURRENT,InpPeriod,1,InpDeviation,PRICE_CLOSE); 
      if(handle==INVALID_HANDLE)
        {
         Alert("Failed to create indicator handle");
        } 
        
        ArraySetAsSeries(upperBuffer,true); 
        ArraySetAsSeries(lowerBuffer,true); 
        ArraySetAsSeries(baseBuffer,true);
    return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
    
    //check if the current tick is a bar open tick
    if(!isNewBar()){return;}
    //Get current tick
    if(!SymbolInfoTick(_Symbol,currentTick)){Print("Failed to get tick"); return;}
    //get Indicator values
    int values=CopyBuffer(handle,0,0,1,baseBuffer)+CopyBuffer(handle,1,0,1,upperBuffer)+CopyBuffer(handle,2,0,1,lowerBuffer);
    if(values!=3)
      {
       Print("Failed to get indicator values");
       return;
      }
      Comment("up[0]",upperBuffer[0],
               "base[0]",baseBuffer[0],
               "lower[0]",lowerBuffer[0]
             );
             
    //count open Positions
    int cntBuy, cntSell;
    if(!CountOpenPositions(cntBuy,cntSell)){return;}  
    
    //check for lower band cross to open a buy position
    if(cntBuy==0 && currentTick.ask <=lowerBuffer[0] && openTimeBuy!=iTime(_Symbol,PERIOD_CURRENT,0))
      {
       openTimeBuy=iTime(_Symbol,PERIOD_CURRENT,0);
       double sl=currentTick.bid-InpStopLoss*_Point;
       double tp=InpTakeProfit==0 ? 0: currentTick.bid+InpTakeProfit*_Point;
       if(!NormalizePrice(sl,sl)){ return;}
       if(!NormalizePrice(tp,tp)){ return;}
       
       //calculate lots
       double lots;
       if(!CalculateLots(currentTick.bid-sl,lots)){return;}
       trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,lots,currentTick.ask,sl,tp,"Bollinger Bands EA");
      } 
      //check for uppper band cross to open a Sell position
    if(cntSell==0 && currentTick.bid >=upperBuffer[0] && openTimeSell!=iTime(_Symbol,PERIOD_CURRENT,0))
      {
       openTimeSell=iTime(_Symbol,PERIOD_CURRENT,0);
       double sl=currentTick.ask+InpStopLoss*_Point;
       double tp=InpTakeProfit==0 ? 0: currentTick.ask-InpTakeProfit*_Point;
       if(!NormalizePrice(sl,sl)){ return;}
       if(!NormalizePrice(tp,tp)){ return;}
       //calculate lots
       double lots;
       if(!CalculateLots(sl-currentTick.ask,lots)){return;}       
       trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,lots,currentTick.bid,sl,tp,"Bollinger Bands EA");
      } 
      
      //check for close at the cross with base band
      if(!CountOpenPositions(cntBuy,cntSell)) {return;}   
      //if(cntBuy>0 && currentTick.bid>=baseBuffer[0]){  CloseOpenPositions(1);} 
      //if(cntSell>0 && currentTick.ask <= baseBuffer[0]){CloseOpenPositions(2);}
      
      //double tslsl=InpStopLoss*_Point;
      //UpdateStopLoss(tslsl);
  }

//+------------------------------------------------------------------+
//| custom function                                                  |
//+------------------------------------------------------------------+
bool isNewBar()
{
   static datetime previousTime=0;
   datetime currentTime=iTime(_Symbol,PERIOD_CURRENT,0);
   if(previousTime!=currentTime)
     {
      previousTime=currentTime;
      return true;
     }
   
   return false;
}

//count open positions
bool CountOpenPositions(int &countBuy,int &countSell)
{
  countBuy=0;
  countSell=0;
  
  int total=PositionsTotal();
  for(int i=total-1;i>=0;i--)
    {
       ulong positionTicket=PositionGetTicket(i);
       if(positionTicket<=0){Print("Failed to get Ticket"); return false;}
       if(!PositionSelectByTicket(positionTicket)){Print("Failed to select position"); return false;}
       long magic;
       if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get magic "); return false;}
       
       if(magic==InpMagicnumber)
         {
           long type;
           if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get type"); return false;}
           if(type== POSITION_TYPE_BUY){countBuy++;}
           if(type== POSITION_TYPE_SELL){countSell++;}
         }
    }
    return true;
}
//count open positions
bool CloseOpenPositions(int all_buy_sell)
{
   
  int total=PositionsTotal();
  for(int i=total-1;i>=0;i--)
    {
       ulong positionTicket=PositionGetTicket(i);
       if(positionTicket<=0){Print("Failed to get Ticket"); return false;}
       if(!PositionSelectByTicket(positionTicket)){Print("Failed to select position"); return false;}
       long magic;
       if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get magic "); return false;}
       
       if(magic==InpMagicnumber)
         {
           long type;
           if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get type"); return false;}
           if(all_buy_sell==1 && type== POSITION_TYPE_SELL){continue;}
           if(all_buy_sell==2 && type== POSITION_TYPE_BUY){continue;}
           trade.PositionClose(positionTicket);
           if(trade.ResultRetcode()!=TRADE_RETCODE_DONE)
             {
                  Print("Failed to close position ticket:",
                        (string)positionTicket," result: ",
                        (string)trade.ResultRetcodeDescription());
               return false;
             }
         }
    }
    return true;
}

bool NormalizePrice(double price, double &normalizedprice)
{
     double tickSize=0;
    if(!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,tickSize)){Print("Failed to get Tick Size"); return false;}
    
     normalizedprice=NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
    
     return true;
}

//calculate lots
bool CalculateLots(double slDistance, double &lots)
{
   lots=0.0;
   if(InpLotSize==LOT_MODE_FIXED)
     {
       lots=InpLotSize;
     }else{
       double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
       double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
       double volumeStep=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
       
       double riskMoney = InpLotMode==LOT_MODE_MONEY ? InpLotSize : AccountInfoDouble(ACCOUNT_EQUITY)*InpLotSize*0.01;
       
       double moneyVolumeStep=(slDistance/tickSize)*tickValue*volumeStep;
       
       lots=MathFloor(riskMoney/moneyVolumeStep)* volumeStep;
     }
     //check calcalcuted Lots
     if(!CheckLots(lots)){ return false;}
   return true;
}

//check lots for min, max and step
bool CheckLots(double &lots)
{
   double min = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double max = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   
   if(lots< min)
     {
       Print("Lots size Set to minimum allowable volume");
       lots=min;
       return true;
     }
   if(lots > max)
     {
       Print("Lots size Set to maximum allowable volume");
       lots=max;
       return false;
     }
     
     lots=(int)MathFloor(lots/step)*step;
     
   
   return true;
}
// update stop loss
void UpdateStopLoss(double slDistance)
{
   //return if no stop loss or fixed stop loss
   if(InpStopLoss==0 || !InpStopLossTrailing){return;}
    
   int total=PositionsTotal();
   for(int i=total-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket<=0){Print("Failed to get Position Ticket"); return;}
      if(!PositionSelectByTicket(ticket)){Print("Failed to select position by ticket"); return;}
      ulong magicnumber=PositionGetInteger(POSITION_MAGIC);
      if(magicnumber!=InpMagicnumber){Print("Failed to get the magic number"); return;}
      if(InpMagicnumber==magicnumber)
        {
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position type"); return;}
         
         double currSL,currTP;
         if(!PositionGetDouble(POSITION_SL,currSL)){Print("Failed to get position current Stop Loss"); return;}
         if(!PositionGetDouble(POSITION_TP,currTP)){Print("Failed to get position current Take Profit"); return;}
         
         double currPrice=type==POSITION_TYPE_BUY? currentTick.bid:currentTick.ask;
         
         int n =type==POSITION_TYPE_BUY?1:-1;
         double newSL=currPrice-slDistance*n;
         
         if(!NormalizePrice(newSL,newSL)){return;}
         
         if(newSL * n< currSL*n ||NormalizeDouble(MathAbs(newSL-currSL),_Digits) <_Point)
           {
            continue;
           }
           
         long level=SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
         if(level!=0 && MathAbs((currPrice-newSL)<level*_Point))
           {
             Print("New Stop loss inside stop level");
             continue;
           }
         if(!trade.PositionModify(ticket,newSL,currTP))
           {
              Print("Failed to Modify position: ticket",(string)ticket,"CurrentSL",(string)currSL,
               "newSL:",(string)newSL, " CurrentTP: ",(string)currTP);
               return;
           }
           
        }
     } 
    
}