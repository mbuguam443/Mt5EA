// Define indicator handle and parameters
int handle;

// Indicator parameters from your screenshot
string mode = "T3";     // Mode: T3
int price = PRICE_CLOSE; // Price: Close
int period = 14;         // Period: 14
int phase = 15;          // O1 Phase: 15
int step = 1;            // O1 Step: 1
int shift = 0;           // Shift: 0
bool paintArrow = true;  // PaintArrow: true
int modePaintProfit = 3; // ModePaintProfit: 3

// Initialize the indicator
void OnInit()
{
    // Call iCustom with the correct parameters for UniversalMA MT5
    handle = iCustom(Symbol(), Period(), "UniversalMA MT5 1.5",
                     mode,
                     price,
                     period,
                     phase,
                     step,
                     shift,
                     paintArrow,
                     modePaintProfit);

    // Check if handle is valid
    if(handle == INVALID_HANDLE)
    {
        Print("Error creating handle for UniversalMA indicator");
    }
}

// Retrieve indicator value from a specific buffer
double GetIndicatorValue(int bufferNum, int shift)
{
    // Make sure the handle is valid
    if(handle == INVALID_HANDLE)
    {
        Print("Invalid handle for UniversalMA indicator");
        return 0.0;
    }

    // Array to store the data
    double value[];
    
    // Copy data from the specified buffer
    if(CopyBuffer(handle, bufferNum, shift, 1, value) > 0)
    {
        return value[0];
    }
    else
    {
        Print("Failed to copy data from buffer ", bufferNum);
        return 0.0;
    }
}

// Clean up the indicator handle on deinitialization
void OnDeinit(const int reason)
{
    if(handle != INVALID_HANDLE)
    {
        IndicatorRelease(handle);
    }
}
