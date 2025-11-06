//+------------------------------------------------------------------+
//|                                   FMS_CandleProcessing.mqh       |
//|              4H Candle Processing Functions for FMS EA           |
//+------------------------------------------------------------------+
#property copyright "FiveMinScalper"
#property link      ""
#property version   "1.00"
#property strict

#include "FMS_Config.mqh"
#include "FMS_GlobalVars.mqh"
#include "FMS_Utilities.mqh"
#include "FMS_ChartVisual.mqh"

//+------------------------------------------------------------------+
//| Find the most recent second 4H candle of day                     |
//| NOTE: Both iTime() and chart display opening time (04:00 UTC)    |
//| Second 4H candle: opens 04:00 UTC, closes 08:00 UTC             |
//+------------------------------------------------------------------+
datetime Find00UTCCandle()
{
   // Search backwards up to 24 hours (6 x 4H candles)
   for(int i = 1; i <= 6; i++)
   {
      datetime candleTime = iTime(_Symbol, PERIOD_H4, i);  // Returns opening time
      MqlDateTime timeStruct;
      TimeToStruct(candleTime, timeStruct);

      if(timeStruct.hour == 4)  // Second candle opens at 04:00 UTC
      {
         return candleTime;  // Returns opening time (04:00 UTC)
      }
   }

   return 0;
}

//+------------------------------------------------------------------+
//| Find the index of the most recent second 4H candle of day        |
//| NOTE: Both iTime() and chart display opening time (04:00 UTC)    |
//| Second 4H candle: opens 04:00 UTC, closes 08:00 UTC             |
//+------------------------------------------------------------------+
int Find00UTCCandleIndex()
{
   // Search backwards up to 24 hours (6 x 4H candles)
   for(int i = 1; i <= 6; i++)
   {
      datetime candleTime = iTime(_Symbol, PERIOD_H4, i);  // Returns opening time
      MqlDateTime timeStruct;
      TimeToStruct(candleTime, timeStruct);

      if(timeStruct.hour == 4)  // Second candle opens at 04:00 UTC
      {
         return i;
      }
   }

   return 0;
}

//+------------------------------------------------------------------+
//| Update 4H data from specific candle index                        |
//+------------------------------------------------------------------+
void Update4HData(int candleIndex)
{
   g_4HHigh = iHigh(_Symbol, PERIOD_H4, candleIndex);
   g_4HLow = iLow(_Symbol, PERIOD_H4, candleIndex);
   double open = iOpen(_Symbol, PERIOD_H4, candleIndex);
   double close = iClose(_Symbol, PERIOD_H4, candleIndex);
   long volume4H = iVolume(_Symbol, PERIOD_H4, candleIndex);
   datetime closedCandleTime = iTime(_Symbol, PERIOD_H4, candleIndex);

   // Store opening time of first 4H candle (iTime returns opening time)
   if(UseOnly00UTCCandle)
   {
      g_processed04CandleTime = closedCandleTime;  // Stores opening time (00:00)
   }

   double range = g_4HHigh - g_4HLow;
   string candleType = (close > open) ? "Bullish" : (close < open) ? "Bearish" : "Doji";

   LogMessage("========================================");
   LogMessage("=== 4H DATA UPDATED ===");
   LogMessage("Candle Index: " + IntegerToString(candleIndex));
   LogMessage("Closed at: " + TimeToString(closedCandleTime, TIME_DATE|TIME_MINUTES) + " UTC");
   LogMessage("Candle Type: " + candleType);
   LogMessage("High: " + DoubleToString(g_4HHigh, _Digits));
   LogMessage("Low: " + DoubleToString(g_4HLow, _Digits));
   LogMessage("Range: " + DoubleToString(range, _Digits) + " (" + DoubleToString(range / g_4HLow * 100, 2) + "%)");
   LogMessage("Volume: " + IntegerToString(volume4H));

   // Reset tracking
   g_buyOrderPlaced = false;
   g_sellOrderPlaced = false;
   g_buyBreakoutConfirmed = false;
   g_buyReversalConfirmed = false;
   g_buyBreakoutCandleTime = 0;
   g_sellBreakoutConfirmed = false;
   g_sellReversalConfirmed = false;
   g_sellBreakoutCandleTime = 0;

   // Reset volume tracking
   g_buyBreakoutVolume = 0;
   g_buyReversalVolume = 0;
   g_sellBreakoutVolume = 0;
   g_sellReversalVolume = 0;
   g_averageVolume = 0;
   g_buyBreakoutVolumeOK = false;
   g_buyReversalVolumeOK = false;
   g_sellBreakoutVolumeOK = false;
   g_sellReversalVolumeOK = false;
   g_buyDivergenceOK = false;
   g_sellDivergenceOK = false;

   // Enable trading after updating 4H data
   g_tradingAllowedToday = true;
   LogMessage("TRADING ENABLED - 4H data updated");

   // Redraw chart
   if(ShowLevelsOnChart)
   {
      DrawLevelsOnChart();
   }

   LogMessage("========================================");
}

//+------------------------------------------------------------------+
//| Find the lowest low among BULLISH candles - OPTIMIZED            |
//| Analyzes up to 10 latest candles within breakout-to-reversal range|
//+------------------------------------------------------------------+
double FindLowestLowInRange(datetime startTime, datetime endTime)
{
   double lowestLow = DBL_MAX;
   int candlesAnalyzed = 0;
   int bullishCandles = 0;

   LogMessage("--- Finding Lowest Low in Latest Candles (Max 10) ---");
   LogMessage("Start Time: " + TimeToString(startTime, TIME_DATE|TIME_MINUTES));
   LogMessage("End Time (Reversal): " + TimeToString(endTime, TIME_DATE|TIME_MINUTES));
   LogMessage("Priority: BULLISH candles that closed below 4H Low");
   LogMessage("Fallback: ANY candles that closed below 4H Low if no bullish found");

   // Calculate how many candles to fetch based on time range
   int timeRangeSeconds = (int)(endTime - startTime);
   int candlesToFetch = MathMin(100, MathMax(5, (timeRangeSeconds / 300) + 5));

   LogMessage("Time range: " + IntegerToString(timeRangeSeconds) + " seconds (" +
             IntegerToString(timeRangeSeconds / 60) + " minutes)");
   LogMessage("Fetching " + IntegerToString(candlesToFetch) + " candles for analysis");

   // Use CopyRates for bulk data retrieval
   MqlRates rates[];
   int copied = CopyRates(_Symbol, PERIOD_M5, 1, candlesToFetch, rates);

   if(copied <= 0)
   {
      LogMessage("ERROR: Failed to copy rates. Error: " + IntegerToString(GetLastError()));
      return DBL_MAX;
   }

   LogMessage("Successfully copied " + IntegerToString(copied) + " candles");

   // FIRST PASS: Look for BULLISH candles that closed below 4H Low
   for(int i = 0; i < copied; i++)
   {
      datetime candleTime = rates[i].time;

      if(candleTime >= startTime && candleTime <= endTime)
      {
         double candleOpen = rates[i].open;
         double candleClose = rates[i].close;
         double candleLow = rates[i].low;

         candlesAnalyzed++;

         if(candleClose < g_4HLow)
         {
            if(candleClose > candleOpen)
            {
               bullishCandles++;

               if(candleLow < lowestLow)
               {
                  lowestLow = candleLow;
                  if(EnableDetailedLogging)
                     LogMessage("  Bullish candle at " + TimeToString(candleTime, TIME_MINUTES) +
                               " Low: " + DoubleToString(candleLow, _Digits) +
                               " (O:" + DoubleToString(candleOpen, _Digits) +
                               " C:" + DoubleToString(candleClose, _Digits) + ") - new lowest");
               }
               else if(EnableDetailedLogging)
               {
                  LogMessage("  Bullish candle at " + TimeToString(candleTime, TIME_MINUTES) +
                            " Low: " + DoubleToString(candleLow, _Digits));
               }
            }
         }
      }
   }

   // SECOND PASS: If no bullish candles found, use ANY candles
   if(lowestLow == DBL_MAX)
   {
      LogMessage("No bullish candles found - using fallback: ANY candles that closed below 4H Low");

      for(int i = 0; i < copied; i++)
      {
         datetime candleTime = rates[i].time;

         if(candleTime >= startTime && candleTime <= endTime)
         {
            double candleOpen = rates[i].open;
            double candleClose = rates[i].close;
            double candleLow = rates[i].low;

            if(candleClose < g_4HLow)
            {
               if(candleLow < lowestLow)
               {
                  lowestLow = candleLow;
                  bool isBullish = (candleClose > candleOpen);
                  if(EnableDetailedLogging)
                     LogMessage("  " + (isBullish ? "Bullish" : "Bearish") + " candle at " + TimeToString(candleTime, TIME_MINUTES) +
                               " Low: " + DoubleToString(candleLow, _Digits) +
                               " (O:" + DoubleToString(candleOpen, _Digits) +
                               " C:" + DoubleToString(candleClose, _Digits) + ") - new lowest");
               }
            }
         }
      }
   }

   LogMessage("Analyzed " + IntegerToString(candlesAnalyzed) + " total candles in time range");
   LogMessage("Found " + IntegerToString(bullishCandles) + " bullish candles that closed below 4H Low");
   LogMessage("4H Low reference: " + DoubleToString(g_4HLow, _Digits));

   if(lowestLow != DBL_MAX)
   {
      if(bullishCandles > 0)
         LogMessage("Lowest Low from bullish candles: " + DoubleToString(lowestLow, _Digits));
      else
         LogMessage("Lowest Low from fallback (any candles): " + DoubleToString(lowestLow, _Digits));
   }
   else
   {
      LogMessage("WARNING: No candles found that closed below 4H Low");
      LogMessage("Pattern does not meet criteria for BUY signal");
   }

   return lowestLow;
}

//+------------------------------------------------------------------+
//| Find the highest high among BEARISH candles - OPTIMIZED          |
//| Analyzes up to 10 latest candles within breakout-to-reversal range|
//+------------------------------------------------------------------+
double FindHighestHighInRange(datetime startTime, datetime endTime)
{
   double highestHigh = 0;
   int candlesAnalyzed = 0;
   int bearishCandles = 0;

   LogMessage("--- Finding Highest High in Latest Candles (Max 10) ---");
   LogMessage("Start Time: " + TimeToString(startTime, TIME_DATE|TIME_MINUTES));
   LogMessage("End Time (Reversal): " + TimeToString(endTime, TIME_DATE|TIME_MINUTES));
   LogMessage("Priority: BEARISH candles that closed above 4H High");
   LogMessage("Fallback: ANY candles that closed above 4H High if no bearish found");

   // Calculate how many candles to fetch based on time range
   int timeRangeSeconds = (int)(endTime - startTime);
   int candlesToFetch = MathMin(100, MathMax(5, (timeRangeSeconds / 300) + 5));

   LogMessage("Time range: " + IntegerToString(timeRangeSeconds) + " seconds (" +
             IntegerToString(timeRangeSeconds / 60) + " minutes)");
   LogMessage("Fetching " + IntegerToString(candlesToFetch) + " candles for analysis");

   // Use CopyRates for bulk data retrieval
   MqlRates rates[];
   int copied = CopyRates(_Symbol, PERIOD_M5, 1, candlesToFetch, rates);

   if(copied <= 0)
   {
      LogMessage("ERROR: Failed to copy rates. Error: " + IntegerToString(GetLastError()));
      return 0;
   }

   LogMessage("Successfully copied " + IntegerToString(copied) + " candles");

   // FIRST PASS: Look for BEARISH candles that closed above 4H High
   for(int i = 0; i < copied; i++)
   {
      datetime candleTime = rates[i].time;

      if(candleTime >= startTime && candleTime <= endTime)
      {
         double candleOpen = rates[i].open;
         double candleClose = rates[i].close;
         double candleHigh = rates[i].high;

         candlesAnalyzed++;

         if(candleClose > g_4HHigh)
         {
            if(candleClose < candleOpen)
            {
               bearishCandles++;

               if(candleHigh > highestHigh)
               {
                  highestHigh = candleHigh;
                  if(EnableDetailedLogging)
                     LogMessage("  Bearish candle at " + TimeToString(candleTime, TIME_MINUTES) +
                               " High: " + DoubleToString(candleHigh, _Digits) +
                               " (O:" + DoubleToString(candleOpen, _Digits) +
                               " C:" + DoubleToString(candleClose, _Digits) + ") - new highest");
               }
               else if(EnableDetailedLogging)
               {
                  LogMessage("  Bearish candle at " + TimeToString(candleTime, TIME_MINUTES) +
                            " High: " + DoubleToString(candleHigh, _Digits));
               }
            }
         }
      }
   }

   // SECOND PASS: If no bearish candles found, use ANY candles
   if(highestHigh == 0)
   {
      LogMessage("No bearish candles found - using fallback: ANY candles that closed above 4H High");

      for(int i = 0; i < copied; i++)
      {
         datetime candleTime = rates[i].time;

         if(candleTime >= startTime && candleTime <= endTime)
         {
            double candleOpen = rates[i].open;
            double candleClose = rates[i].close;
            double candleHigh = rates[i].high;

            if(candleClose > g_4HHigh)
            {
               if(candleHigh > highestHigh)
               {
                  highestHigh = candleHigh;
                  bool isBearish = (candleClose < candleOpen);
                  if(EnableDetailedLogging)
                     LogMessage("  " + (isBearish ? "Bearish" : "Bullish") + " candle at " + TimeToString(candleTime, TIME_MINUTES) +
                               " High: " + DoubleToString(candleHigh, _Digits) +
                               " (O:" + DoubleToString(candleOpen, _Digits) +
                               " C:" + DoubleToString(candleClose, _Digits) + ") - new highest");
               }
            }
         }
      }
   }

   LogMessage("Analyzed " + IntegerToString(candlesAnalyzed) + " total candles in time range");
   LogMessage("Found " + IntegerToString(bearishCandles) + " bearish candles that closed above 4H High");
   LogMessage("4H High reference: " + DoubleToString(g_4HHigh, _Digits));

   if(highestHigh > 0)
   {
      if(bearishCandles > 0)
         LogMessage("Highest High from bearish candles: " + DoubleToString(highestHigh, _Digits));
      else
         LogMessage("Highest High from fallback (any candles): " + DoubleToString(highestHigh, _Digits));
   }
   else
   {
      LogMessage("WARNING: No candles found that closed above 4H High");
      LogMessage("Pattern does not meet criteria for SELL signal");
   }

   return highestHigh;
}
//+------------------------------------------------------------------+
