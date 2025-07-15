//+------------------------------------------------------------------+
//|                                                   TelegramEA.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int handleStocatic;

double signalBuffer[],mainBuffer[];
input int upperLevel=85;
input int lowerLeveL=15;

int totalBars;
int OnInit()
  {
    handleStocatic=iStochastic(_Symbol,PERIOD_CURRENT,5,3,3,MODE_SMA,STO_LOWHIGH);
    totalBars=iBars(_Symbol,PERIOD_CURRENT);
    
    //sendMessage("hello there ");   
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
     int bars=iBars(_Symbol,PERIOD_CURRENT);
     if(totalBars!=bars)
       {
         totalBars=bars;
         
         CopyBuffer(handleStocatic,0,1,2,mainBuffer);         
         if(mainBuffer[0] <lowerLeveL && mainBuffer[1] >lowerLeveL)
           {
              Print("Buy now");
              sendMessage("Buy Now Stocatic signal "+_Symbol);
           }
           
           if(mainBuffer[0] >upperLevel && mainBuffer[1] <upperLevel)
           {
              Print("Sell now");
              sendMessage("Sell Now Stocatic signal "+_Symbol);
           }
         
       }   
  }
//+------------------------------------------------------------------+


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