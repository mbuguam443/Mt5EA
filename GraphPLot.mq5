//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    // Create a panel for the line graph
    CreatePanel("LineGraphPanel", 0, 0, 600, 400);

    // Example data points for the line graph (y-values)
    double data[] = {10, 20, 15, 30, 25, 35, 45};

    // Draw lines connecting the data points
    for (int i = 1; i < ArraySize(data); i++)
    {
        int x1 = (i - 1) * 80;         // X-position for the first point (scaled by 80)
        int y1 = 400 - data[i - 1] * 3;  // Y-position (inverted Y, scaled by 3)
        int x2 = i * 80;               // X-position for the second point
        int y2 = 400 - data[i] * 3;    // Y-position for the second point

        DrawLine("Line_" + IntegerToString(i), x1, y1, x2, y2, 2, clrRed);  // Width = 2, color = red
    }

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Create a panel                                                   |
//+------------------------------------------------------------------+
void CreatePanel(string name, int x, int y, int width, int height)
{
    ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlack);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

//+------------------------------------------------------------------+
//| Draw a line between two points                                   |
//+------------------------------------------------------------------+
void DrawLine(string name, int x1, int y1, int x2, int y2, int width, color clr)
{
    ObjectCreate(0, name, OBJ_TREND, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_RAY, false);  // No extension

    // Set the coordinates for the line
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE1, x1);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE1, y1);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE2, x2);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE2, y2);
}

//+------------------------------------------------------------------+
//| Indicator deinitialization function                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0);  // Clean up all objects
}
