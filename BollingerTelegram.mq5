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
             
   
    
    //check for lower band cross to open a buy position
    if(currentTick.ask <=lowerBuffer[0] && openTimeBuy!=iTime(_Symbol,PERIOD_CURRENT,0))
      {
       sendMessage(_Symbol+" Buy Now Bollinger "+(string)_Period+" timeframe");
      } 
      //check for uppper band cross to open a Sell position
    if(currentTick.bid >=upperBuffer[0] && openTimeSell!=iTime(_Symbol,PERIOD_CURRENT,0))
      {
        sendMessage(_Symbol+" Sell Now Bollinger "+(string)_Period+" timeframe");
      } 
      
      
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

void sendMessage(string messagehere)
{
    //https://api.telegram.org/bot5332685145:AAFYYnyeioeyY_5Bpw_5DeDliR82T4ZpYio/sendMessage?chat_id=-1002194068259&text=Hello%20from%20my%20Telegram%20bot%21
   string baseurl="https://api.telegram.org/bot";
   string token="5332685145:AAFYYnyeioeyY_5Bpw_5DeDliR82T4ZpYio";
   string chatid="-1002194068259";
   string message=messagehere;//"Hello from telegram bot";
   char result[];
   char Data[];
   string headers;
   string cookies;
   string referr;
   string finalurl=baseurl+token+"/sendMessage?chat_id="+chatid+"&text="+message;
   Print(finalurl);
    
    // Specify the request method (GET)
    int timeout = 2000; // Timeout in milliseconds
    ResetLastError(); // Reset error state

    // Send the request
    int responseCode =WebRequest("GET",finalurl,cookies,referr,timeout,Data,0,result,headers);

    // Check the response
    if (responseCode == -1)
    {
        Print("Error in WebRequest: ", GetLastError());
    }
    else
    {
        Print("Response Code: ", responseCode);
        Print("Response: ", result[0]);
    }
}




