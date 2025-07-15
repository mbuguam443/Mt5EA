
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
CTrade trade;
CPositionInfo posinfo;
COrderInfo  orderinfo;
CHistoryOrderInfo hisinfo;
CDealInfo dealinfo;

enum enumLotType{Fixed_Lots=0,Pct_of_Balance=1,Pct_of_Equity=2,Pct_of_Free_Margin=3};

input group "Group Settings";
input int InpMagic=12345;
input int Slippage=1;

input group "Time Settings";
input int StartHour=16;
input int EndHour=17;
input int Secs=60;

input group "Money Management";
input enumLotType LotType=0;
input double FixedLot=0.01;
input double RiskPercent=0.5;


input group "Trading Setting in points";
input double Delta=0.5;
input double MaxDistance=0.01;
input double Stop=10;
input double MaxTrailing=4;
input int  MaxSpread=5555;



int OnInit()
  {

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

   
  }

