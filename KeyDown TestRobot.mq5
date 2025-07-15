//+------------------------------------------------------------------+
//|                                             Button TestRobot.mq5 |
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
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {

   
  }

void OnTick()
  {

   
  }

void  OnChartEvent( 
   const int       id,       // event ID  
   const long&     lparam,   // long type event parameter 
   const double&   dparam,   // double type event parameter 
   const string&   sparam    // string type event parameter 
   )
   {
      if(id==CHARTEVENT_KEYDOWN)
        {
          Print("Key code ",lparam);
          if(lparam==79)
            {
             int total=PositionsTotal();
             Print("Total: ",total);
              for(int i=PositionsTotal()-1;i>=0;i--)
                {
                  ulong ticket=PositionGetTicket(i);
                  Print("ticket: ",ticket);
                  ulong magicNo=PositionGetInteger(POSITION_MAGIC);
                   if(PositionSelectByTicket(ticket))
                     {
                       trade.PositionClose(ticket);
                       Print("Position Closed successfully");
                     }
                }
            }
        }
   }
