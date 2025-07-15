//+------------------------------------------------------------------+
//|                                            FindingHighandLow.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

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
    
    double higestHigh=0;
    for(int i=0;i<200;i++)
      {
        double high=iHigh(_Symbol,PERIOD_CURRENT,i);
        Print("First high: ",high);
        Print("current high: ",higestHigh,"i value= ",i," start of the Highest= ",i-4," highest: ",iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,11,i-4)," Highest Price: ",iHigh(_Symbol,PERIOD_CURRENT,iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,11,i-4)));
        if(i>4 && iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,11,i-4)==i)
          {
             Print("High foundequal: ",iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,11,i-4));
             if(high>higestHigh)
               {
                 Print("Finally high: ",high);
               }
               
               higestHigh=MathMax(high,higestHigh);
               Print("The High is here: ",higestHigh);
               
          }
      }
      
    double lowestLow=DBL_MAX;
    for(int i=0;i<200;i++)
      {
        double low=iLow(_Symbol,PERIOD_CURRENT,i);
        Print("First Low: ",low);
        Print("current low: ",lowestLow,"i value= ",i," start of the Lowest= ",i-4," lowest: ",iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,11,i-4)," low Price: ",iLow(_Symbol,PERIOD_CURRENT,iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,11,i-4)));
        if(i>4 && iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,11,i-4)==i)
          {
             Print("Low foundequal: ",iLowest(_Symbol,PERIOD_CURRENT,MODE_LOW,11,i-4));
             if(low>lowestLow)
               {
                 Print("Finally low: ",low);
               }
               lowestLow=low;
               
               lowestLow=MathMin(low,lowestLow);
               Print("The Low is here: ",lowestLow);
               
          }
      }
      Print("----------------------------------------------------------------------");
      ExpertRemove();
      
      
      
    
   
  }

