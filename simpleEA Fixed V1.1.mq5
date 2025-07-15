//+------------------------------------------------------------------+
//|                                           AI_Model_Trader.mq5    |
//+------------------------------------------------------------------+
#property copyright "Oyeyemi Ogungbaro"
#property version   "1.04"
#property strict

#include <Zmq/Zmq.mqh>
#include <Trade/Trade.mqh>

// ZeroMQ Context
Context context("AI_Model_Context");

// Create a socket to connect to Python server
Socket socket(context, ZMQ_REQ);

// Trade object
CTrade trade;

// Input parameters
input string   InpPythonServer = "tcp://localhost:5555";  // Python server address
input double   InpLotSize      = 0.01;                    // Manual Lot Size
input int      InpMagicNumber  = 123456;                  // Magic number
input int      InpPeriod       = 15;                      // Period (15 minutes)
input int      InpRSIPeriod    = 14;                      // RSI Period
input int      InpMACDFast     = 12;                      // MACD Fast EMA Period
input int      InpMACDSlow     = 26;                      // MACD Slow EMA Period
input int      InpMACDSignal   = 9;                       // MACD Signal SMA Period
input int      InpStopLoss     = 50;                      // Stop Loss in points
input int      InpTakeProfit   = 100;                     // Take Profit in points

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("Starting OnInit...");

    // Connect to Python server
    bool connected = socket.connect(InpPythonServer);
    if (!connected)
    {
        Print("Failed to connect to ZeroMQ server at ", InpPythonServer);
        return INIT_FAILED;
    }

    Print("Connected to ZeroMQ server.");

    // Set magic number for trade operations
    trade.SetExpertMagicNumber(InpMagicNumber);

    Print("OnInit completed successfully.");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Disconnect from Python server
    socket.disconnect(InpPythonServer);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check if it's time for a new bar
    static datetime last_bar_time = 0;
    datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
    
    if (current_bar_time == last_bar_time)
        return;
    
    last_bar_time = current_bar_time;
    
    // Log current trading conditions
    Print("Symbol: ", _Symbol, ", Timeframe: ", EnumToString((ENUM_TIMEFRAMES)_Period));
    
    // Prepare data for the model
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, InpPeriod, rates);
    
    if (copied != InpPeriod)
    {
        Print("Error copying rates data. Copied: ", copied, ", Required: ", InpPeriod);
        return;
    }
    
    // Calculate indicators
    double rsi[], macd[], macd_signal[], ema_12[], ema_26[];
    ArraySetAsSeries(rsi, true);
    ArraySetAsSeries(macd, true);
    ArraySetAsSeries(macd_signal, true);
    ArraySetAsSeries(ema_12, true);
    ArraySetAsSeries(ema_26, true);
    
    // Resize arrays
    ArrayResize(rsi, InpPeriod);
    ArrayResize(macd, InpPeriod);
    ArrayResize(macd_signal, InpPeriod);
    ArrayResize(ema_12, InpPeriod);
    ArrayResize(ema_26, InpPeriod);
    
    int rsi_handle = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
    int macd_handle = iMACD(_Symbol, PERIOD_CURRENT, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
    int ema_12_handle = iMA(_Symbol, PERIOD_CURRENT, 12, 0, MODE_EMA, PRICE_CLOSE);
    int ema_26_handle = iMA(_Symbol, PERIOD_CURRENT, 26, 0, MODE_EMA, PRICE_CLOSE);

    if (rsi_handle < 0 || macd_handle < 0 || ema_12_handle < 0 || ema_26_handle < 0)
    {
        Print("Error creating indicator handles: RSI=", rsi_handle, ", MACD=", macd_handle, 
              ", EMA12=", ema_12_handle, ", EMA26=", ema_26_handle);
        return;
    }

    // Wait for indicators to calculate
    int max_wait = 50; // Maximum number of attempts
    for (int i = 0; i < max_wait; i++)
    {
        if (BarsCalculated(rsi_handle) > 0 && 
            BarsCalculated(macd_handle) > 0 && 
            BarsCalculated(ema_12_handle) > 0 && 
            BarsCalculated(ema_26_handle) > 0)
        {
            break;
        }
        Sleep(100); // Wait for 100 milliseconds
        if (i == max_wait - 1)
        {
            Print("Timeout waiting for indicators to calculate");
            return;
        }
    }

    int copied_rsi = CopyBuffer(rsi_handle, 0, 0, InpPeriod, rsi);
    int copied_macd = CopyBuffer(macd_handle, 0, 0, InpPeriod, macd);
    int copied_macd_signal = CopyBuffer(macd_handle, 1, 0, InpPeriod, macd_signal);
    int copied_ema_12 = CopyBuffer(ema_12_handle, 0, 0, InpPeriod, ema_12);
    int copied_ema_26 = CopyBuffer(ema_26_handle, 0, 0, InpPeriod, ema_26);

    if (copied_rsi != InpPeriod || copied_macd != InpPeriod || copied_macd_signal != InpPeriod || 
        copied_ema_12 != InpPeriod || copied_ema_26 != InpPeriod)
    {
        Print("Error copying indicator data: RSI=", copied_rsi, ", MACD=", copied_macd, 
              ", MACD Signal=", copied_macd_signal, ", EMA12=", copied_ema_12, ", EMA26=", copied_ema_26);
        Print("Last error: ", GetLastError());
        IndicatorRelease(rsi_handle);
        IndicatorRelease(macd_handle);
        IndicatorRelease(ema_12_handle);
        IndicatorRelease(ema_26_handle);
        return;
    }

    // Release indicator handles
    IndicatorRelease(rsi_handle);
    IndicatorRelease(macd_handle);
    IndicatorRelease(ema_12_handle);
    IndicatorRelease(ema_26_handle);
    
    // Prepare data for Python
    string json_data = "{\"symbol\":\"" + _Symbol + "\",\"data\":[";
    for (int i = InpPeriod - 1; i >= 0; i--)
    {
        json_data += "{\"RSI\":" + DoubleToString(rsi[i], 2) + ",";
        json_data += "\"MACD\":" + DoubleToString(macd[i], 5) + ",";
        json_data += "\"MACD_signal\":" + DoubleToString(macd_signal[i], 5) + ",";
        json_data += "\"MACD_diff\":" + DoubleToString(macd[i] - macd_signal[i], 5) + ",";
        json_data += "\"EMA_12\":" + DoubleToString(ema_12[i], 5) + ",";
        json_data += "\"EMA_26\":" + DoubleToString(ema_26[i], 5) + "}";
        if (i > 0) json_data += ",";
    }
    json_data += "]}";
    
    // Send data to Python server
    Print("Sending data to Python server");
    ZmqMsg request(json_data);
    if (!socket.send(request))
    {
        Print("Error sending data to Python server");
        return;
    }
    
    // Receive response from Python server
    Print("Receiving response from Python server");
    ZmqMsg reply;
    if (!socket.recv(reply))
    {
        Print("Error receiving response from Python server");
        return;
    }
    
    string reply_string = reply.getData();
    Print("Raw ZMQ response: ", reply_string);

    // Parse the response manually
    int signal = ParseSignalFromResponse(reply_string);
    Print("Parsed Signal: ", signal);
    
    // Check for existing positions
    bool has_position = false;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionSelectByTicket(PositionGetTicket(i)))
        {
            if (PositionGetInteger(POSITION_MAGIC) == InpMagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                has_position = true;
                break;
            }
        }
    }
    
    // Use the manual lot size instead of calculating it
    double position_size = InpLotSize;

    // Improved Trade Execution Logic with Manual Lot Size
    if (!has_position)
    {
        if (signal == 1)  // Buy signal
        {
            ExecuteTrade(ORDER_TYPE_BUY, position_size);
        }
        else if (signal == -1)  // Sell signal
        {
            ExecuteTrade(ORDER_TYPE_SELL, position_size);
        }
        else
        {
            Print("No action taken. Signal: ", signal);
        }
    }
    else
    {
        Print("Position already exists. No new trades.");
    }
}
//+------------------------------------------------------------------+
//| Execute trade with stop loss and take profit                     |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_ORDER_TYPE order_type, double volume)
{
    double price = (order_type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double stop_loss = (order_type == ORDER_TYPE_BUY) ? price - InpStopLoss * _Point : price + InpStopLoss * _Point;
    double take_profit = (order_type == ORDER_TYPE_BUY) ? price + InpTakeProfit * _Point : price - InpTakeProfit * _Point;

    trade.PositionOpen(_Symbol, order_type, volume, price, stop_loss, take_profit, "AI Model " + EnumToString(order_type));

    if (trade.ResultRetcode() == TRADE_RETCODE_DONE)
    {
        Print("Trade executed successfully. Type: ", EnumToString(order_type), ", Volume: ", volume,
              ", Price: ", price, ", SL: ", stop_loss, ", TP: ", take_profit);
    }
    else
    {
        Print("Trade execution failed. Error: ", GetLastError());
    }
}
//+------------------------------------------------------------------+
//| Parse signal from Python response                                |
//+------------------------------------------------------------------+
int ParseSignalFromResponse(string response)
{
    Print("Parsing response: ", response);
    
    // Remove any whitespace from the response
    response = StringTrim(response);
    
    // Check if the response is in the expected format
    if (StringGetCharacter(response, 0) != '{' || StringGetCharacter(response, StringLen(response) - 1) != '}')
    {
        Print("Error: Invalid JSON format");
        return 0;
    }
    
    // Extract the content between the curly braces
    string content = StringSubstr(response, 1, StringLen(response) - 2);
    
    // Split the content by colon
    string parts[];
    int split = StringSplit(content, ':', parts);
    
    if (split != 2)
    {
        Print("Error: Invalid key-value pair format");
        return 0;
    }
    
    // Check if the key is "signal"
    if (StringTrim(parts[0]) != "\"signal\"")
    {
        Print("Error: Expected 'signal' key, got ", parts[0]);
        return 0;
    }
    
    // Extract and convert the signal value
    string signal_str = StringTrim(parts[1]);
    
    // Remove any quotation marks if present
    if (StringGetCharacter(signal_str, 0) == '"')
        signal_str = StringSubstr(signal_str, 1, StringLen(signal_str) - 2);
    
    int signal = (int)StringToInteger(signal_str);
    
    Print("Parsed signal value: ", signal);
    
    if (signal == 1 || signal == -1 || signal == 0)
        return signal;
    
    Print("Error: Invalid signal value: ", signal_str);
    return 0;
}

//+------------------------------------------------------------------+
//| Custom string trim function                                      |
//+------------------------------------------------------------------+
string StringTrim(string str)
{
    // Trim leading whitespace
    while(StringLen(str) > 0 && StringGetCharacter(str, 0) <= 32)
        str = StringSubstr(str, 1);
    
    // Trim trailing whitespace
    while(StringLen(str) > 0 && StringGetCharacter(str, StringLen(str) - 1) <= 32)
        str = StringSubstr(str, 0, StringLen(str) - 1);
    
    return str;
}