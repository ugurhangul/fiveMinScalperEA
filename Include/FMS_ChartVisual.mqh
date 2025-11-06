//+------------------------------------------------------------------+
//|                                        FMS_ChartVisual.mqh       |
//|                Chart Drawing and Visual Functions for FMS EA     |
//+------------------------------------------------------------------+
#property copyright "FiveMinScalper"
#property link      ""
#property version   "1.00"
#property strict

#include "FMS_Config.mqh"
#include "FMS_GlobalVars.mqh"
#include "FMS_Utilities.mqh"

//+------------------------------------------------------------------+
//| Draw all levels on chart                                         |
//+------------------------------------------------------------------+
void DrawLevelsOnChart()
{
   LogMessage("Drawing levels on chart...");
   LogMessage("ShowLevelsOnChart = " + (ShowLevelsOnChart ? "true" : "false"));
   LogMessage("Values: 4HHigh=" + DoubleToString(g_4HHigh, _Digits) + ", 4HLow=" + DoubleToString(g_4HLow, _Digits));

   // Validate data before drawing
   if(g_4HHigh == 0 || g_4HLow == 0)
   {
      LogMessage("ERROR: Cannot draw lines - 4H candle data is zero");
      return;
   }

   // Delete old lines first
   DeleteAllChartObjects();
   LogMessage("Old chart objects deleted");

   // Draw 4H High line (SELL breakout level)
   CreateHorizontalLine("4H_High", g_4HHigh, Color4HHigh, LineWidth, LineStyle, "4H High (SELL Breakout): " + DoubleToString(g_4HHigh, _Digits));

   // Draw 4H Low line (BUY breakout level)
   CreateHorizontalLine("4H_Low", g_4HLow, Color4HLow, LineWidth, LineStyle, "4H Low (BUY Breakout): " + DoubleToString(g_4HLow, _Digits));

   LogMessage("All horizontal lines created");

   // Add info text
   CreateInfoText();
   LogMessage("Info text created");

   ChartRedraw();
   LogMessage("Chart redrawn - levels should now be visible");
}

//+------------------------------------------------------------------+
//| Create horizontal line - OPTIMIZED with tracking                 |
//+------------------------------------------------------------------+
void CreateHorizontalLine(string name, double price, color lineColor, int width, ENUM_LINE_STYLE style, string description)
{
   string objectName = "FMS_" + name;

   if(ObjectFind(0, objectName) >= 0)
   {
      ObjectDelete(0, objectName);
   }

   bool created = ObjectCreate(0, objectName, OBJ_HLINE, 0, 0, price);

   if(created)
   {
      // Batch property settings for better performance
      ObjectSetInteger(0, objectName, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, objectName, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, objectName, OBJPROP_STYLE, style);
      ObjectSetInteger(0, objectName, OBJPROP_BACK, false);
      ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, objectName, OBJPROP_SELECTED, false);
      ObjectSetString(0, objectName, OBJPROP_TEXT, description);
      ObjectSetString(0, objectName, OBJPROP_TOOLTIP, description);

      // Track the object for efficient deletion later
      TrackChartObject(objectName);

      LogMessage("Created line: " + objectName + " at price " + DoubleToString(price, _Digits));
   }
   else
   {
      int error = GetLastError();
      LogMessage("ERROR: Failed to create line " + objectName + " at price " + DoubleToString(price, _Digits) + ". Error: " + IntegerToString(error));
   }
}

//+------------------------------------------------------------------+
//| Create info text on chart                                        |
//+------------------------------------------------------------------+
void CreateInfoText()
{
   string objectName = "FMS_Info";

   // Delete existing object if it exists
   if(ObjectFind(0, objectName) >= 0)
   {
      LogMessage("Deleting existing info label...");
      if(!ObjectDelete(0, objectName))
      {
         LogMessage("WARNING: Failed to delete existing info label. Error: " + IntegerToString(GetLastError()));
      }
   }

   // Create label
   bool created = ObjectCreate(0, objectName, OBJ_LABEL, 0, 0, 0);

   if(!created)
   {
      int error = GetLastError();
      LogMessage("ERROR: Failed to create info label. Error: " + IntegerToString(error));
      return;
   }

   // Build info text
   string infoText = "FMS EA | 4H: " + DoubleToString(g_4HHigh, _Digits) + " / " + DoubleToString(g_4HLow, _Digits);

   // Set label properties
   ObjectSetInteger(0, objectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objectName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, objectName, OBJPROP_YDISTANCE, 20);
   ObjectSetInteger(0, objectName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, objectName, OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, objectName, OBJPROP_FONT, "Arial Bold");
   ObjectSetString(0, objectName, OBJPROP_TEXT, infoText);
   ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objectName, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, objectName, OBJPROP_BACK, false);

   // Track the object
   TrackChartObject(objectName);

   LogMessage("Info label created with text: " + infoText);
}

//+------------------------------------------------------------------+
//| Delete all chart objects - OPTIMIZED with tracking               |
//+------------------------------------------------------------------+
void DeleteAllChartObjects()
{
   // Use tracked objects for faster deletion
   int size = ArraySize(g_chartObjects);

   for(int i = 0; i < size; i++)
   {
      ObjectDelete(0, g_chartObjects[i]);
   }

   // Clear the tracking array
   ArrayResize(g_chartObjects, 0);
}

//+------------------------------------------------------------------+
//| Track created chart object                                       |
//+------------------------------------------------------------------+
void TrackChartObject(string objectName)
{
   int size = ArraySize(g_chartObjects);
   ArrayResize(g_chartObjects, size + 1);
   g_chartObjects[size] = objectName;
}
//+------------------------------------------------------------------+

