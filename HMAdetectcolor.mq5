//+------------------------------------------------------------------+
//|                                               HMAdetectcolor.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
CTrade trade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int handleHMA;
double HMABuffer[];

int totalBars;

int OnInit()
  {
    
   totalBars=iBars(_Symbol,PERIOD_CURRENT); 
    
   handleHMA=iCustom(_Symbol,PERIOD_CURRENT,"Market/HMA Color with Alerts MT5.ex5");
   if(handleHMA==INVALID_HANDLE)
     {
       return INIT_FAILED;
     }else
        {
         Print("Indicator loaded successfully");
        }
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
   if(totalBars!=bars)
     {
      totalBars!=bars;
      CopyBuffer(handleHMA,0,1,3,HMABuffer);
      if(HMABuffer[0] < HMABuffer[1] && HMABuffer[1] >HMABuffer[2])
        {
          Print("Sell Now");
          //sendMessage("HMA color red sell now "+_Symbol);
        }
      if(HMABuffer[0] > HMABuffer[1] && HMABuffer[1] <HMABuffer[2])
        {
          Print("Buy Now");
          //sendMessage("HMA color blue buy now "+_Symbol);
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