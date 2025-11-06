//+------------------------------------------------------------------+
//|                                             FMS_Indicators.mqh |
//|                   Indicator and Signal Detection for FMS EA      |
//+------------------------------------------------------------------+
#property copyright "FiveMinScalper"
#property link      ""
#property version   "1.00"
#property strict

#include "FMS_Config.mqh"
#include "FMS_GlobalVars.mqh"
#include "FMS_Utilities.mqh"

//+------------------------------------------------------------------+
//| Calculate average volume over a specified period                 |
//+------------------------------------------------------------------+
double CalculateAverageVolume(int period)
{
   if(period <= 0)
   {
      LogMessage("ERROR: Invalid period for volume calculation: " + IntegerToString(period));
      return 0;
   }

   // Get volume data for the specified period
   // We use index 1 to start from the last closed candle
   long volumes[];
   int copied = CopyTickVolume(_Symbol, PERIOD_M5, 1, period, volumes);

   if(copied <= 0)
   {
      LogMessage("ERROR: Failed to copy volume data. Error: " + IntegerToString(GetLastError()));
      return 0;
   }

   // Calculate average
   long totalVolume = 0;
   for(int i = 0; i < copied; i++)
   {
      totalVolume += volumes[i];
   }

   double avgVolume = (double)totalVolume / copied;

   if(EnableDetailedLogging)
   {
      LogMessage("Volume Analysis:");
      LogMessage("  Period: " + IntegerToString(period) + " candles");
      LogMessage("  Candles copied: " + IntegerToString(copied));
      LogMessage("  Total volume: " + IntegerToString(totalVolume));
      LogMessage("  Average volume: " + DoubleToString(avgVolume, 0));
   }

   return avgVolume;
}

//+------------------------------------------------------------------+
//| Get volume for a specific candle by index                        |
//+------------------------------------------------------------------+
long GetCandleVolume(int candleIndex)
{
   long volume = iVolume(_Symbol, PERIOD_M5, candleIndex);

   if(volume < 0)
   {
      LogMessage("ERROR: Failed to get volume for candle index " + IntegerToString(candleIndex));
      return 0;
   }

   return volume;
}

//+------------------------------------------------------------------+
//| Check if breakout volume is LOW (weak breakout = good for false breakout strategy) |
//+------------------------------------------------------------------+
bool IsBreakoutVolumeLow(long breakoutVolume, double averageVolume, double maxThreshold)
{
   if(averageVolume <= 0)
   {
      LogMessage("WARNING: Average volume is zero or negative - cannot confirm volume");
      return false;
   }

   double volumeRatio = (double)breakoutVolume / averageVolume;
   bool isLow = volumeRatio <= maxThreshold;

   LogMessage("=== Breakout Volume Check (Want LOW Volume) ===");
   LogMessage("Breakout Volume: " + IntegerToString(breakoutVolume));
   LogMessage("Average Volume: " + DoubleToString(averageVolume, 0));
   LogMessage("Volume Ratio: " + DoubleToString(volumeRatio, 2) + "x");
   LogMessage("Max Threshold: " + DoubleToString(maxThreshold, 2) + "x");
   LogMessage("Volume is LOW: " + (isLow ? "YES" : "NO"));

   if(!isLow)
   {
      LogMessage(">>> VOLUME TOO HIGH - Strong breakout, likely to continue <<<");
      LogMessage(">>> Not ideal for false breakout strategy - skipping <<<");
   }
   else
   {
      LogMessage(">>> VOLUME IS LOW - Weak breakout, likely to reverse <<<");
      LogMessage(">>> Good candidate for false breakout - proceeding <<<");
   }

   return isLow;
}

//+------------------------------------------------------------------+
//| Check if reversal volume is HIGH (strong reversal = good confirmation) |
//+------------------------------------------------------------------+
bool IsReversalVolumeHigh(long reversalVolume, double averageVolume, double minThreshold)
{
   if(averageVolume <= 0)
   {
      LogMessage("WARNING: Average volume is zero or negative - cannot confirm volume");
      return false;
   }

   double volumeRatio = (double)reversalVolume / averageVolume;
   bool isHigh = volumeRatio >= minThreshold;

   LogMessage("=== Reversal Volume Check (Want HIGH Volume) ===");
   LogMessage("Reversal Volume: " + IntegerToString(reversalVolume));
   LogMessage("Average Volume: " + DoubleToString(averageVolume, 0));
   LogMessage("Volume Ratio: " + DoubleToString(volumeRatio, 2) + "x");
   LogMessage("Min Threshold: " + DoubleToString(minThreshold, 2) + "x");
   LogMessage("Volume is HIGH: " + (isHigh ? "YES" : "NO"));

   if(!isHigh)
   {
      LogMessage(">>> VOLUME TOO LOW - Weak reversal, lacks conviction <<<");
      LogMessage(">>> May not be a strong false breakout - skipping <<<");
   }
   else
   {
      LogMessage(">>> VOLUME IS HIGH - Strong reversal confirmation <<<");
      LogMessage(">>> Excellent false breakout signal - proceeding <<<");
   }

   return isHigh;
}

//+------------------------------------------------------------------+
//| Detect bullish RSI divergence (for BUY setup)                    |
//+------------------------------------------------------------------+
bool DetectBullishRSIDivergence()
{
   if(g_rsiHandle == INVALID_HANDLE)
      return false;

   // Get RSI values for lookback period
   double rsiValues[];
   ArraySetAsSeries(rsiValues, true);

   int copied = CopyBuffer(g_rsiHandle, 0, 0, g_symbolParams.divergenceLookback + 1, rsiValues);
   if(copied <= 0)
   {
      LogMessage("ERROR: Failed to copy RSI data. Error: " + IntegerToString(GetLastError()));
      return false;
   }

   // Get price lows for lookback period
   double lows[];
   ArraySetAsSeries(lows, true);

   copied = CopyLow(_Symbol, PERIOD_M5, 0, g_symbolParams.divergenceLookback + 1, lows);
   if(copied <= 0)
   {
      LogMessage("ERROR: Failed to copy price lows. Error: " + IntegerToString(GetLastError()));
      return false;
   }

   // Find the most recent swing low (excluding current candle at index 0)
   int recentLowIndex = -1;
   for(int i = 2; i < g_symbolParams.divergenceLookback - 1; i++)
   {
      if(lows[i] < lows[i-1] && lows[i] < lows[i+1])
      {
         recentLowIndex = i;
         break;
      }
   }

   if(recentLowIndex == -1)
   {
      if(EnableDetailedLogging)
         LogMessage("No swing low found in lookback period");
      return false;
   }

   // Current price low (index 1 = last closed candle)
   double currentLow = lows[1];
   double previousLow = lows[recentLowIndex];

   // Current RSI and previous RSI at swing low
   double currentRSI = rsiValues[1];
   double previousRSI = rsiValues[recentLowIndex];

   // Bullish divergence: Price makes lower low, RSI makes higher low
   bool priceLowerLow = (currentLow < previousLow);
   bool rsiHigherLow = (currentRSI > previousRSI);

   if(priceLowerLow && rsiHigherLow)
   {
      LogMessage("*** BULLISH RSI DIVERGENCE DETECTED ***");
      LogMessage("Price: " + DoubleToString(previousLow, _Digits) + " -> " + DoubleToString(currentLow, _Digits) + " (Lower Low)");
      LogMessage("RSI: " + DoubleToString(previousRSI, 2) + " -> " + DoubleToString(currentRSI, 2) + " (Higher Low)");
      LogMessage("Swing low found at index " + IntegerToString(recentLowIndex) + " (" + IntegerToString(recentLowIndex * 5) + " minutes ago)");
      return true;
   }

   if(EnableDetailedLogging)
   {
      LogMessage("No bullish RSI divergence:");
      LogMessage("  Price Lower Low: " + (priceLowerLow ? "YES" : "NO"));
      LogMessage("  RSI Higher Low: " + (rsiHigherLow ? "YES" : "NO"));
   }

   return false;
}

//+------------------------------------------------------------------+
//| Detect bearish RSI divergence (for SELL setup)                   |
//+------------------------------------------------------------------+
bool DetectBearishRSIDivergence()
{
   if(g_rsiHandle == INVALID_HANDLE)
      return false;

   // Get RSI values for lookback period
   double rsiValues[];
   ArraySetAsSeries(rsiValues, true);

   int copied = CopyBuffer(g_rsiHandle, 0, 0, g_symbolParams.divergenceLookback + 1, rsiValues);
   if(copied <= 0)
   {
      LogMessage("ERROR: Failed to copy RSI data. Error: " + IntegerToString(GetLastError()));
      return false;
   }

   // Get price highs for lookback period
   double highs[];
   ArraySetAsSeries(highs, true);

   copied = CopyHigh(_Symbol, PERIOD_M5, 0, g_symbolParams.divergenceLookback + 1, highs);
   if(copied <= 0)
   {
      LogMessage("ERROR: Failed to copy price highs. Error: " + IntegerToString(GetLastError()));
      return false;
   }

   // Find the most recent swing high (excluding current candle at index 0)
   int recentHighIndex = -1;
   for(int i = 2; i < g_symbolParams.divergenceLookback - 1; i++)
   {
      if(highs[i] > highs[i-1] && highs[i] > highs[i+1])
      {
         recentHighIndex = i;
         break;
      }
   }

   if(recentHighIndex == -1)
   {
      if(EnableDetailedLogging)
         LogMessage("No swing high found in lookback period");
      return false;
   }

   // Current price high (index 1 = last closed candle)
   double currentHigh = highs[1];
   double previousHigh = highs[recentHighIndex];

   // Current RSI and previous RSI at swing high
   double currentRSI = rsiValues[1];
   double previousRSI = rsiValues[recentHighIndex];

   // Bearish divergence: Price makes higher high, RSI makes lower high
   bool priceHigherHigh = (currentHigh > previousHigh);
   bool rsiLowerHigh = (currentRSI < previousRSI);

   if(priceHigherHigh && rsiLowerHigh)
   {
      LogMessage("*** BEARISH RSI DIVERGENCE DETECTED ***");
      LogMessage("Price: " + DoubleToString(previousHigh, _Digits) + " -> " + DoubleToString(currentHigh, _Digits) + " (Higher High)");
      LogMessage("RSI: " + DoubleToString(previousRSI, 2) + " -> " + DoubleToString(currentRSI, 2) + " (Lower High)");
      LogMessage("Swing high found at index " + IntegerToString(recentHighIndex) + " (" + IntegerToString(recentHighIndex * 5) + " minutes ago)");
      return true;
   }

   if(EnableDetailedLogging)
   {
      LogMessage("No bearish RSI divergence:");
      LogMessage("  Price Higher High: " + (priceHigherHigh ? "YES" : "NO"));
      LogMessage("  RSI Lower High: " + (rsiLowerHigh ? "YES" : "NO"));
   }

   return false;
}

//+------------------------------------------------------------------+
//| Detect bullish MACD divergence (for BUY setup)                   |
//+------------------------------------------------------------------+
bool DetectBullishMACDDivergence()
{
   if(g_macdHandle == INVALID_HANDLE)
      return false;

   // Get MACD main line values for lookback period
   double macdValues[];
   ArraySetAsSeries(macdValues, true);

   int copied = CopyBuffer(g_macdHandle, 0, 0, g_symbolParams.divergenceLookback + 1, macdValues);
   if(copied <= 0)
   {
      LogMessage("ERROR: Failed to copy MACD data. Error: " + IntegerToString(GetLastError()));
      return false;
   }

   // Get price lows for lookback period
   double lows[];
   ArraySetAsSeries(lows, true);

   copied = CopyLow(_Symbol, PERIOD_M5, 0, g_symbolParams.divergenceLookback + 1, lows);
   if(copied <= 0)
   {
      LogMessage("ERROR: Failed to copy price lows. Error: " + IntegerToString(GetLastError()));
      return false;
   }

   // Find the most recent swing low (excluding current candle at index 0)
   int recentLowIndex = -1;
   for(int i = 2; i < g_symbolParams.divergenceLookback - 1; i++)
   {
      if(lows[i] < lows[i-1] && lows[i] < lows[i+1])
      {
         recentLowIndex = i;
         break;
      }
   }

   if(recentLowIndex == -1)
   {
      if(EnableDetailedLogging)
         LogMessage("No swing low found for MACD divergence");
      return false;
   }

   // Current price low and MACD (index 1 = last closed candle)
   double currentLow = lows[1];
   double previousLow = lows[recentLowIndex];
   double currentMACD = macdValues[1];
   double previousMACD = macdValues[recentLowIndex];

   // Bullish divergence: Price makes lower low, MACD makes higher low
   bool priceLowerLow = (currentLow < previousLow);
   bool macdHigherLow = (currentMACD > previousMACD);

   if(priceLowerLow && macdHigherLow)
   {
      LogMessage("*** BULLISH MACD DIVERGENCE DETECTED ***");
      LogMessage("Price: " + DoubleToString(previousLow, _Digits) + " -> " + DoubleToString(currentLow, _Digits) + " (Lower Low)");
      LogMessage("MACD: " + DoubleToString(previousMACD, 5) + " -> " + DoubleToString(currentMACD, 5) + " (Higher Low)");
      LogMessage("Swing low found at index " + IntegerToString(recentLowIndex) + " (" + IntegerToString(recentLowIndex * 5) + " minutes ago)");
      return true;
   }

   if(EnableDetailedLogging)
   {
      LogMessage("No bullish MACD divergence:");
      LogMessage("  Price Lower Low: " + (priceLowerLow ? "YES" : "NO"));
      LogMessage("  MACD Higher Low: " + (macdHigherLow ? "YES" : "NO"));
   }

   return false;
}

//+------------------------------------------------------------------+
//| Detect bearish MACD divergence (for SELL setup)                  |
//+------------------------------------------------------------------+
bool DetectBearishMACDDivergence()
{
   if(g_macdHandle == INVALID_HANDLE)
      return false;

   // Get MACD main line values for lookback period
   double macdValues[];
   ArraySetAsSeries(macdValues, true);

   int copied = CopyBuffer(g_macdHandle, 0, 0, g_symbolParams.divergenceLookback + 1, macdValues);
   if(copied <= 0)
   {
      LogMessage("ERROR: Failed to copy MACD data. Error: " + IntegerToString(GetLastError()));
      return false;
   }

   // Get price highs for lookback period
   double highs[];
   ArraySetAsSeries(highs, true);

   copied = CopyHigh(_Symbol, PERIOD_M5, 0, g_symbolParams.divergenceLookback + 1, highs);
   if(copied <= 0)
   {
      LogMessage("ERROR: Failed to copy price highs. Error: " + IntegerToString(GetLastError()));
      return false;
   }

   // Find the most recent swing high (excluding current candle at index 0)
   int recentHighIndex = -1;
   for(int i = 2; i < g_symbolParams.divergenceLookback - 1; i++)
   {
      if(highs[i] > highs[i-1] && highs[i] > highs[i+1])
      {
         recentHighIndex = i;
         break;
      }
   }

   if(recentHighIndex == -1)
   {
      if(EnableDetailedLogging)
         LogMessage("No swing high found for MACD divergence");
      return false;
   }

   // Current price high and MACD (index 1 = last closed candle)
   double currentHigh = highs[1];
   double previousHigh = highs[recentHighIndex];
   double currentMACD = macdValues[1];
   double previousMACD = macdValues[recentHighIndex];

   // Bearish divergence: Price makes higher high, MACD makes lower high
   bool priceHigherHigh = (currentHigh > previousHigh);
   bool macdLowerHigh = (currentMACD < previousMACD);

   if(priceHigherHigh && macdLowerHigh)
   {
      LogMessage("*** BEARISH MACD DIVERGENCE DETECTED ***");
      LogMessage("Price: " + DoubleToString(previousHigh, _Digits) + " -> " + DoubleToString(currentHigh, _Digits) + " (Higher High)");
      LogMessage("MACD: " + DoubleToString(previousMACD, 5) + " -> " + DoubleToString(currentMACD, 5) + " (Lower High)");
      LogMessage("Swing high found at index " + IntegerToString(recentHighIndex) + " (" + IntegerToString(recentHighIndex * 5) + " minutes ago)");
      return true;
   }

   if(EnableDetailedLogging)
   {
      LogMessage("No bearish MACD divergence:");
      LogMessage("  Price Higher High: " + (priceHigherHigh ? "YES" : "NO"));
      LogMessage("  MACD Lower High: " + (macdLowerHigh ? "YES" : "NO"));
   }

   return false;
}

//+------------------------------------------------------------------+

