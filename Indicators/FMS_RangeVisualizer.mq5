//+------------------------------------------------------------------+
//|                                        FMS_RangeVisualizer.mq5   |
//|                   Multi-Range Breakout Strategy Visualizer       |
//|                   Displays 4H and 15M ranges from Python bot     |
//+------------------------------------------------------------------+
#property copyright "FiveMinScalper"
#property link      ""
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

//--- Input parameters
input group "=== 4H Range Settings ==="
input bool     Show4HRange = true;                    // Show 4H Range
input color    Color4HHigh = clrDodgerBlue;           // 4H High Line Color
input color    Color4HLow = clrCrimson;               // 4H Low Line Color
input int      Width4H = 2;                           // 4H Line Width
input ENUM_LINE_STYLE Style4H = STYLE_SOLID;          // 4H Line Style

input group "=== 15M Range Settings ==="
input bool     Show15MRange = true;                   // Show 15M Range
input color    Color15MHigh = clrLimeGreen;           // 15M High Line Color
input color    Color15MLow = clrOrange;               // 15M Low Line Color
input int      Width15M = 1;                          // 15M Line Width
input ENUM_LINE_STYLE Style15M = STYLE_DOT;           // 15M Line Style

input group "=== Display Settings ==="
input bool     ShowLabels = true;                     // Show Text Labels
input int      FontSize = 10;                         // Label Font Size
input color    LabelColor = clrWhite;                 // Label Text Color

//--- Global variables
datetime g_last4HCandleTime = 0;      // Last processed 4H candle (04:00 UTC)
datetime g_last15MCandleTime = 0;     // Last processed 15M candle (04:30 UTC)
double   g_4HHigh = 0;                // 4H candle high
double   g_4HLow = 0;                 // 4H candle low
double   g_15MHigh = 0;               // 15M candle high
double   g_15MLow = 0;                // 15M candle low

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize with existing candles
   Initialize4HCandle();
   Initialize15MCandle();
   
   // Draw initial ranges
   UpdateRangeLines();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Delete all chart objects created by this indicator
   DeleteAllObjects();
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // Check for new 4H candle (04:00 UTC)
   CheckNew4HCandle();
   
   // Check for new 15M candle (04:30 UTC)
   CheckNew15MCandle();
   
   // Update range lines on chart
   UpdateRangeLines();
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Initialize with most recent 4H candle at 04:00 UTC              |
//+------------------------------------------------------------------+
void Initialize4HCandle()
{
   // Search backwards for the most recent 4H candle at 04:00 UTC
   for(int i = 1; i <= 10; i++)
   {
      datetime candleTime = iTime(_Symbol, PERIOD_H4, i);
      
      // Check if this is the second 4H candle (opens at 04:00 UTC)
      MqlDateTime dt;
      TimeToStruct(candleTime, dt);
      
      if(dt.hour == 4 && dt.min == 0)
      {
         g_last4HCandleTime = candleTime;
         g_4HHigh = iHigh(_Symbol, PERIOD_H4, i);
         g_4HLow = iLow(_Symbol, PERIOD_H4, i);
         
         Print("Initialized with 4H candle at ", TimeToString(candleTime), 
               " | High: ", DoubleToString(g_4HHigh, _Digits),
               " | Low: ", DoubleToString(g_4HLow, _Digits));
         return;
      }
   }
   
   Print("No 4H candle at 04:00 UTC found in recent history");
}

//+------------------------------------------------------------------+
//| Initialize with most recent 15M candle at 04:30 UTC             |
//+------------------------------------------------------------------+
void Initialize15MCandle()
{
   // Search backwards for the most recent 15M candle at 04:30 UTC
   for(int i = 1; i <= 100; i++)
   {
      datetime candleTime = iTime(_Symbol, PERIOD_M15, i);
      
      // Check if this is a 15M candle at 04:30 UTC
      MqlDateTime dt;
      TimeToStruct(candleTime, dt);
      
      if(dt.hour == 4 && dt.min == 30)
      {
         g_last15MCandleTime = candleTime;
         g_15MHigh = iHigh(_Symbol, PERIOD_M15, i);
         g_15MLow = iLow(_Symbol, PERIOD_M15, i);
         
         Print("Initialized with 15M candle at ", TimeToString(candleTime),
               " | High: ", DoubleToString(g_15MHigh, _Digits),
               " | Low: ", DoubleToString(g_15MLow, _Digits));
         return;
      }
   }
   
   Print("No 15M candle at 04:30 UTC found in recent history");
}

//+------------------------------------------------------------------+
//| Check for new 4H candle at 04:00 UTC                            |
//+------------------------------------------------------------------+
void CheckNew4HCandle()
{
   // Get the last closed 4H candle (index 1)
   datetime candleTime = iTime(_Symbol, PERIOD_H4, 1);

   // Check if this is a new candle
   if(candleTime > g_last4HCandleTime)
   {
      // Check if this is the second 4H candle (opens at 04:00 UTC)
      MqlDateTime dt;
      TimeToStruct(candleTime, dt);

      if(dt.hour == 4 && dt.min == 0)
      {
         g_last4HCandleTime = candleTime;
         g_4HHigh = iHigh(_Symbol, PERIOD_H4, 1);
         g_4HLow = iLow(_Symbol, PERIOD_H4, 1);

         Print("NEW 4H CANDLE DETECTED at ", TimeToString(candleTime),
               " | High: ", DoubleToString(g_4HHigh, _Digits),
               " | Low: ", DoubleToString(g_4HLow, _Digits),
               " | Range: ", DoubleToString(g_4HHigh - g_4HLow, _Digits));

         // Delete old lines to redraw
         DeleteAllObjects();
      }
   }
}

//+------------------------------------------------------------------+
//| Check for new 15M candle at 04:30 UTC                           |
//+------------------------------------------------------------------+
void CheckNew15MCandle()
{
   // Get the last closed 15M candle (index 1)
   datetime candleTime = iTime(_Symbol, PERIOD_M15, 1);

   // Check if this is a new candle
   if(candleTime > g_last15MCandleTime)
   {
      // Check if this is a 15M candle at 04:30 UTC
      MqlDateTime dt;
      TimeToStruct(candleTime, dt);

      if(dt.hour == 4 && dt.min == 30)
      {
         g_last15MCandleTime = candleTime;
         g_15MHigh = iHigh(_Symbol, PERIOD_M15, 1);
         g_15MLow = iLow(_Symbol, PERIOD_M15, 1);

         Print("NEW 15M CANDLE DETECTED at ", TimeToString(candleTime),
               " | High: ", DoubleToString(g_15MHigh, _Digits),
               " | Low: ", DoubleToString(g_15MLow, _Digits),
               " | Range: ", DoubleToString(g_15MHigh - g_15MLow, _Digits));

         // Delete old lines to redraw
         DeleteAllObjects();
      }
   }
}

//+------------------------------------------------------------------+
//| Update all range lines on chart                                 |
//+------------------------------------------------------------------+
void UpdateRangeLines()
{
   // Draw 4H range
   if(Show4HRange && g_4HHigh > 0 && g_4HLow > 0)
   {
      CreateHorizontalLine("4H_High", g_4HHigh, Color4HHigh, Width4H, Style4H,
                          "4H High (SELL Breakout): " + DoubleToString(g_4HHigh, _Digits));
      CreateHorizontalLine("4H_Low", g_4HLow, Color4HLow, Width4H, Style4H,
                          "4H Low (BUY Breakout): " + DoubleToString(g_4HLow, _Digits));

      if(ShowLabels)
      {
         CreateLabel("4H_High_Label", "4H High", g_4HHigh, Color4HHigh);
         CreateLabel("4H_Low_Label", "4H Low", g_4HLow, Color4HLow);
      }
   }

   // Draw 15M range
   if(Show15MRange && g_15MHigh > 0 && g_15MLow > 0)
   {
      CreateHorizontalLine("15M_High", g_15MHigh, Color15MHigh, Width15M, Style15M,
                          "15M High (SELL Breakout): " + DoubleToString(g_15MHigh, _Digits));
      CreateHorizontalLine("15M_Low", g_15MLow, Color15MLow, Width15M, Style15M,
                          "15M Low (BUY Breakout): " + DoubleToString(g_15MLow, _Digits));

      if(ShowLabels)
      {
         CreateLabel("15M_High_Label", "15M High", g_15MHigh, Color15MHigh);
         CreateLabel("15M_Low_Label", "15M Low", g_15MLow, Color15MLow);
      }
   }

   // Create info panel
   if(ShowLabels)
   {
      CreateInfoPanel();
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create time-bounded trend line (horizontal)                      |
//+------------------------------------------------------------------+
void CreateHorizontalLine(string name, double price, color lineColor, int width,
                         ENUM_LINE_STYLE style, string description)
{
   string objectName = "FMS_RV_" + name;

   // Delete if exists
   if(ObjectFind(0, objectName) >= 0)
   {
      ObjectDelete(0, objectName);
   }

   // Determine start and end times based on range type
   datetime startTime = 0;
   datetime endTime = 0;

   if(StringFind(name, "4H") >= 0)
   {
      // 4H range: starts at last 4H candle time, ends 24 hours later
      startTime = g_last4HCandleTime;
      endTime = startTime + 86400; // 24 hours = 86400 seconds
   }
   else if(StringFind(name, "15M") >= 0)
   {
      // 15M range: starts at last 15M candle time, ends 24 hours later
      startTime = g_last15MCandleTime;
      endTime = startTime + 86400; // 24 hours = 86400 seconds
   }

   // Validate times
   if(startTime == 0)
   {
      return; // No valid start time, skip drawing
   }

   // Create trend line (horizontal at specified price)
   if(ObjectCreate(0, objectName, OBJ_TREND, 0, startTime, price, endTime, price))
   {
      ObjectSetInteger(0, objectName, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, objectName, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, objectName, OBJPROP_STYLE, style);
      ObjectSetInteger(0, objectName, OBJPROP_BACK, false);
      ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, objectName, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, objectName, OBJPROP_RAY_RIGHT, false); // Don't extend to the right
      ObjectSetInteger(0, objectName, OBJPROP_RAY_LEFT, false);  // Don't extend to the left
      ObjectSetString(0, objectName, OBJPROP_TEXT, description);
      ObjectSetString(0, objectName, OBJPROP_TOOLTIP, description);
   }
}

//+------------------------------------------------------------------+
//| Create text label for price level                               |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, double price, color textColor)
{
   string objectName = "FMS_RV_" + name;

   // Delete if exists
   if(ObjectFind(0, objectName) >= 0)
   {
      ObjectDelete(0, objectName);
   }

   // Determine time position based on range type
   datetime timePos = 0;

   if(StringFind(name, "4H") >= 0)
   {
      // Position at the end of the 4H range line
      timePos = g_last4HCandleTime + 86400; // 24 hours later
   }
   else if(StringFind(name, "15M") >= 0)
   {
      // Position at the end of the 15M range line
      timePos = g_last15MCandleTime + 86400; // 24 hours later
   }
   else
   {
      // Fallback to current time
      timePos = iTime(_Symbol, PERIOD_CURRENT, 0);
   }

   // Create text object
   if(ObjectCreate(0, objectName, OBJ_TEXT, 0, timePos, price))
   {
      ObjectSetString(0, objectName, OBJPROP_TEXT, " " + text);
      ObjectSetInteger(0, objectName, OBJPROP_COLOR, textColor);
      ObjectSetInteger(0, objectName, OBJPROP_FONTSIZE, FontSize);
      ObjectSetString(0, objectName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, objectName, OBJPROP_ANCHOR, ANCHOR_LEFT);
      ObjectSetInteger(0, objectName, OBJPROP_BACK, false);
      ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| Create info panel showing range details                         |
//+------------------------------------------------------------------+
void CreateInfoPanel()
{
   string objectName = "FMS_RV_InfoPanel";

   // Delete if exists
   if(ObjectFind(0, objectName) >= 0)
   {
      ObjectDelete(0, objectName);
   }

   // Build info text
   string infoText = "FMS Range Visualizer\n";
   infoText += "━━━━━━━━━━━━━━━━━━━━━━\n";

   if(Show4HRange && g_4HHigh > 0 && g_4HLow > 0)
   {
      infoText += "4H Range (04:00 UTC):\n";
      infoText += "  High: " + DoubleToString(g_4HHigh, _Digits) + "\n";
      infoText += "  Low:  " + DoubleToString(g_4HLow, _Digits) + "\n";
      infoText += "  Range: " + DoubleToString(g_4HHigh - g_4HLow, _Digits) + "\n";
      infoText += "  Time: " + TimeToString(g_last4HCandleTime, TIME_DATE|TIME_MINUTES) + "\n";
   }
   else if(Show4HRange)
   {
      infoText += "4H Range: Waiting...\n";
   }

   if(Show15MRange && g_15MHigh > 0 && g_15MLow > 0)
   {
      infoText += "\n15M Range (04:30 UTC):\n";
      infoText += "  High: " + DoubleToString(g_15MHigh, _Digits) + "\n";
      infoText += "  Low:  " + DoubleToString(g_15MLow, _Digits) + "\n";
      infoText += "  Range: " + DoubleToString(g_15MHigh - g_15MLow, _Digits) + "\n";
      infoText += "  Time: " + TimeToString(g_last15MCandleTime, TIME_DATE|TIME_MINUTES) + "\n";
   }
   else if(Show15MRange)
   {
      infoText += "\n15M Range: Waiting...\n";
   }

   // Create label
   if(ObjectCreate(0, objectName, OBJ_LABEL, 0, 0, 0))
   {
      ObjectSetInteger(0, objectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, objectName, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, objectName, OBJPROP_YDISTANCE, 30);
      ObjectSetInteger(0, objectName, OBJPROP_COLOR, LabelColor);
      ObjectSetInteger(0, objectName, OBJPROP_FONTSIZE, FontSize);
      ObjectSetString(0, objectName, OBJPROP_FONT, "Courier New");
      ObjectSetString(0, objectName, OBJPROP_TEXT, infoText);
      ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objectName, OBJPROP_BACK, false);
   }
}

//+------------------------------------------------------------------+
//| Delete all objects created by this indicator                    |
//+------------------------------------------------------------------+
void DeleteAllObjects()
{
   // List of all possible object names
   string objects[] = {
      "FMS_RV_4H_High",
      "FMS_RV_4H_Low",
      "FMS_RV_15M_High",
      "FMS_RV_15M_Low",
      "FMS_RV_4H_High_Label",
      "FMS_RV_4H_Low_Label",
      "FMS_RV_15M_High_Label",
      "FMS_RV_15M_Low_Label",
      "FMS_RV_InfoPanel"
   };

   for(int i = 0; i < ArraySize(objects); i++)
   {
      if(ObjectFind(0, objects[i]) >= 0)
      {
         ObjectDelete(0, objects[i]);
      }
   }
}
//+------------------------------------------------------------------+

