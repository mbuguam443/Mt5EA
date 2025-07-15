
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

input string url="https://greatjourns.com/ForexRobot.php";

int OnInit()
  {
    
    InternetAuth();
    
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

  }

void OnTick()
  {

   
  }


int InternetAuth()
{
   if(!MQLInfoInteger(MQL_TESTER) )
      {
         char post[];
       int accountNumber=9876; //AccountInfoInteger(ACCOUNT_LOGIN);
       
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
                Alert("Sorry you are not allowed to use this Bot Bro!");
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
