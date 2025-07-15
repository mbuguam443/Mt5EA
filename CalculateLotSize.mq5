#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  
    long AuthuserAccount=10419166;
    
    long availableAccount=AccountInfoInteger(ACCOUNT_LOGIN);
    // Authorized: 10419166
   

    Print("Login ",availableAccount," Authorized: ",AuthuserAccount);
    
    //if(availableAccount==AuthuserAccount)
      if(true)
      {
        Print("License is Valid");
      }else{
        Print("License is invalid");
        ExpertRemove();
        return INIT_FAILED;
      }
      
      
    //if(TimeCurrent() < StringToTime("2025.02.10"))
     if(true)
      {
        Print("Robot is Valid");
      }else{
        Print("Robot Expired");
        ExpertRemove();
        return INIT_FAILED;
      }  
  
    double entry= SymbolInfoDouble(_Symbol,SYMBOL_ASK);
    entry=NormalizeDouble(entry,_Digits);
    double sl=entry - 1000 * _Point;
    sl=NormalizeDouble(sl,_Digits);
    Print("Distance Size: ", (entry-sl));
    CalculateLotSize(3,(entry-sl));
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {

   
  }

void OnTick()
  {

   
  }

double CalculateLotSize(int Percent,double slDistance)
{
   double tickSize= SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue= SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double ticklotStep=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double ticklotMin=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double ticklotMax=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   
   Print("tickSize: ",tickSize," tickValue: ",tickValue," tickLotStep: ",ticklotStep," tickMin: ",ticklotMin," tickmax: ",ticklotMax);
   
   if(tickSize==0 || tickValue==0 || ticklotStep==0 )
     {
       return 0;
     }
     
   double riskMoney= AccountInfoDouble(ACCOUNT_EQUITY)*Percent/100;
   
   double moneyPerSmallestLotsize= (slDistance/tickSize)*tickValue*ticklotStep;
   Print("slDistance: ",slDistance,"riskMoney: ",riskMoney," smallest you can riskMoney: ",moneyPerSmallestLotsize);
   if(moneyPerSmallestLotsize==0)
     {
      return 0;
     }
   double lotsFactor= (riskMoney/moneyPerSmallestLotsize);  
   double lots= MathFloor(riskMoney/moneyPerSmallestLotsize)* ticklotStep;
   if(moneyPerSmallestLotsize >riskMoney)
     {
      lots=ticklotMin;
     }
   if(lots > ticklotMax)
     {
      lots=ticklotMax;
     }  
   Print("The Lot Factor between the two is: ",lotsFactor);
   Print("The Lots size to be used: ",lots);
   return lots; 
    
}
