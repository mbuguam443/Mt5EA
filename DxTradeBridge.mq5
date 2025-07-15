//+------------------------------------------------------------------+
//|                                                DxTradeBridge.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


#define BASE_URL "https://dxtrade.ftmo.com/api/auth/"
#define ACCOUNT_FTMO "1210119720"
#define PASSWORD_FTMO "8*57*8Eauj2"
int OnInit()
  {
   login();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   
  }

void OnTick()
  {

   
  }

int login()
{
   string url=BASE_URL+"login";
   char post[],result[];
   string headers="Content-Type:application/json\r\nAccept:application/json\r\n";
   string resultHeader;
   
   string json="{\"username\":\"1210118996\", \"ftmo\":\"default\", \"password\": \"8B32e28!c?b?P\"}";
   StringToCharArray(json,post,0,StringLen(json));
   ResetLastError();
   
   int res=WebRequest("POST",url,headers,5000,post,result,resultHeader);
   
   if(res==-1)
   {
      Print("Web Request Failed");
   }else if(res!=200)
   {
     Print("Server says: ",res);
   
   }else
   {
      string message=CharArrayToString(result);
      Print("Finally: ",message);
   
   }
   
   return 0;

}
