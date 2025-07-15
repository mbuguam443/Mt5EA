//+------------------------------------------------------------------+
//|                                                 ATRindicator.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int handleATR;
input double atrFactor=1.2; //ATR Factor
input int ATRPeriod=14;// ATR Period
double ATRBuffer[];

int totalBars;

int OnInit()
  {
   totalBars=iBars(_Symbol,PERIOD_CURRENT);
   
   handleATR=iATR(_Symbol,PERIOD_CURRENT,ATRPeriod);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int bars=iBars(_Symbol,PERIOD_CURRENT);
   //Print("Total Bars: ",totalBars," Bars: ",bars);
   if(totalBars!=bars)
     {
      totalBars=bars;
      CopyBuffer(handleATR,0,1,1,ATRBuffer);
      double open=iOpen(_Symbol,PERIOD_CURRENT,1);
      double close=iClose(_Symbol,PERIOD_CURRENT,1);
      if(open < close && close-open > ATRBuffer[0]*atrFactor)
        {
         Print("Buy Now");
         sendMessage("Buy NOw ATR "+_Symbol);
        }
      if(open > close && open-close > ATRBuffer[0]*atrFactor)
        {
         Print("Sell Now");
         sendMessage("Sell NOw ATR "+_Symbol);
        }  
     }
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