//+------------------------------------------------------------------+
//|                                          FMS_Strategy.mqh        |
//|                Core Strategy Logic Functions for FMS EA          |
//+------------------------------------------------------------------+
#property copyright "FiveMinScalper"
#property link      ""
#property version   "1.00"
#property strict

#include "FMS_Config.mqh"
#include "FMS_GlobalVars.mqh"
#include "FMS_Utilities.mqh"
#include "FMS_Indicators.mqh"
#include "FMS_TradeExecution.mqh"
#include "FMS_CandleProcessing.mqh"
#include "FMS_ChartVisual.mqh"

//+------------------------------------------------------------------+
//| Process new 4-hour candle                                        |
//+------------------------------------------------------------------+
void Process4HCandle()
{
   // Get the closed 4H candle (index 1)
   g_4HHigh = iHigh(_Symbol, PERIOD_H4, 1);
   g_4HLow = iLow(_Symbol, PERIOD_H4, 1);
   double open = iOpen(_Symbol, PERIOD_H4, 1);
   double close = iClose(_Symbol, PERIOD_H4, 1);
   long volume4H = iVolume(_Symbol, PERIOD_H4, 1);
   g_last4HCandleTime = iTime(_Symbol, PERIOD_H4, 0);

   // Store the opening time of the first 4H candle we're using
   datetime closedCandleTime = iTime(_Symbol, PERIOD_H4, 1);
   if(UseOnly00UTCCandle)
   {
      g_processed04CandleTime = closedCandleTime;
   }

   MqlDateTime timeStruct;
   TimeToStruct(closedCandleTime, timeStruct);

   double range = g_4HHigh - g_4HLow;
   string candleType = (close > open) ? "Bullish" : (close < open) ? "Bearish" : "Doji";

   LogMessage("========================================");
   LogMessage("=== 4H CANDLE ANALYSIS ===");
   LogMessage("Closed at: " + TimeToString(closedCandleTime, TIME_DATE|TIME_MINUTES) + " UTC");
   LogMessage("Candle Type: " + candleType);
   LogMessage("Open: " + DoubleToString(open, _Digits));
   LogMessage("High: " + DoubleToString(g_4HHigh, _Digits));
   LogMessage("Low: " + DoubleToString(g_4HLow, _Digits));
   LogMessage("Close: " + DoubleToString(close, _Digits));
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
//| Check for closed positions and update adaptive filters           |
//+------------------------------------------------------------------+
void CheckForClosedPositions()
{
   if(!UseAdaptiveFilters)
      return;

   // Request history for the last day
   datetime from = TimeCurrent() - 86400;
   datetime to = TimeCurrent();

   if(!HistorySelect(from, to))
   {
      if(EnableDetailedLogging)
         LogMessage("Failed to select history for adaptive filter check");
      return;
   }

   int totalDeals = HistoryDealsTotal();

   // Check the most recent deals for position closures
   for(int i = totalDeals - 1; i >= MathMax(0, totalDeals - 10); i--)
   {
      ulong ticket = HistoryDealGetTicket(i);

      if(ticket == 0)
         continue;

      // Only process deals from this EA
      long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
      if(magic != MagicNumber)
         continue;

      // Only process OUT deals (position closures)
      long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT)
         continue;

      // Get position ID
      ulong positionId = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);

      // Process this closed trade
      ProcessClosedTrade(positionId);
   }
}

//+------------------------------------------------------------------+
//| Process closed trade for adaptive filters                        |
//+------------------------------------------------------------------+
void ProcessClosedTrade(ulong positionId)
{
   // Skip if both adaptive systems are disabled
   if(!UseAdaptiveFilters && !UseSymbolAdaptation)
      return;

   // Avoid processing the same trade twice
   if(positionId == g_lastClosedTicket)
      return;

   g_lastClosedTicket = positionId;

   // Select the position from history
   if(!HistorySelectByPosition(positionId))
   {
      LogMessage("ERROR: Failed to select position " + IntegerToString(positionId) + " from history");
      return;
   }

   // Calculate total P&L for this position
   double totalProfit = 0;
   double totalSwap = 0;
   double totalCommission = 0;

   int totalDeals = HistoryDealsTotal();
   for(int i = 0; i < totalDeals; i++)
   {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket == 0)
         continue;

      // Only sum deals for this position
      if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == positionId)
      {
         totalProfit += HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
         totalSwap += HistoryDealGetDouble(dealTicket, DEAL_SWAP);
         totalCommission += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
      }
   }

   double netProfit = totalProfit + totalSwap + totalCommission;
   bool isWin = (netProfit > 0);

   LogMessage("╔════════════════════════════════════════════════════════════╗");
   LogMessage("║  TRADE CLOSED - ADAPTIVE FILTER UPDATE                    ║");
   LogMessage("╚════════════════════════════════════════════════════════════╝");
   LogMessage("Position ID: " + IntegerToString(positionId));
   LogMessage("Result: " + (isWin ? "WIN" : "LOSS"));
   LogMessage("Net P&L: $" + DoubleToString(netProfit, 2));

   // Update adaptive filter system
   if(UseAdaptiveFilters)
   {
      if(isWin)
      {
         g_consecutiveWins++;
         g_consecutiveLosses = 0;

         // Check if we can relax filters
         if(g_adaptiveModeActive && g_consecutiveWins >= g_symbolParams.adaptiveWinRecovery)
         {
            g_adaptiveModeActive = false;
            g_activeVolumeConfirmation = false;
            g_activeDivergenceConfirmation = false;

            LogMessage("╔════════════════════════════════════════════════════════════╗");
            LogMessage("║  ADAPTIVE MODE: DEACTIVATED                                ║");
            LogMessage("╚════════════════════════════════════════════════════════════╝");
            LogMessage("Reason: " + IntegerToString(g_consecutiveWins) + " consecutive wins");
            LogMessage("Volume Confirmation: DISABLED");
            LogMessage("Divergence Confirmation: DISABLED");
            LogMessage("════════════════════════════════════════════════════════════");
         }
      }
      else
      {
         g_consecutiveLosses++;
         g_consecutiveWins = 0;

         // Check if we need to activate filters
         if(!g_adaptiveModeActive && g_consecutiveLosses >= g_symbolParams.adaptiveLossTrigger)
         {
            g_adaptiveModeActive = true;
            g_activeVolumeConfirmation = true;
            g_activeDivergenceConfirmation = true;

            LogMessage("╔════════════════════════════════════════════════════════════╗");
            LogMessage("║  ADAPTIVE MODE: ACTIVATED                                  ║");
            LogMessage("╚════════════════════════════════════════════════════════════╝");
            LogMessage("Reason: " + IntegerToString(g_consecutiveLosses) + " consecutive losses");
            LogMessage("Volume Confirmation: ENABLED");
            LogMessage("Divergence Confirmation: ENABLED");
            LogMessage("════════════════════════════════════════════════════════════");
         }
      }

      LogMessage("Consecutive Wins: " + IntegerToString(g_consecutiveWins));
      LogMessage("Consecutive Losses: " + IntegerToString(g_consecutiveLosses));
   }

   LogMessage("════════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Monitor for entry signals (main strategy logic) - Part 1         |
//+------------------------------------------------------------------+
void MonitorEntries()
{
   // Skip if no 4H candle has been processed yet
   if(g_last4HCandleTime == 0 || g_4HHigh == 0 || g_4HLow == 0)
   {
      if(EnableDetailedLogging)
         LogMessage("MonitorEntries: Waiting for 4H candle data");
      return;
   }

   // Check if we're in the restricted trading period (04:00-08:00 UTC)
   if(IsInCandleFormationPeriod())
   {
      if(EnableDetailedLogging)
         LogMessage("MonitorEntries: Trading suspended - Restricted period (04:00-08:00 UTC)");
      return;
   }

   // Check if we've passed midnight and need a new 4H candle
   if(!g_tradingAllowedToday)
   {
      LogMessage("MonitorEntries: Trading suspended - waiting for new 4H candle after midnight");
      return;
   }

   // Check trading hours
   if(UseTradingHours && !IsWithinTradingHours())
   {
      if(EnableDetailedLogging)
         LogMessage("MonitorEntries: Outside trading hours - skipping");
      return;
   }

   // Get the CLOSED 5-minute candle (index 1)
   double candle5mClose = iClose(_Symbol, PERIOD_M5, 1);
   double candle5mHigh = iHigh(_Symbol, PERIOD_M5, 1);
   double candle5mLow = iLow(_Symbol, PERIOD_M5, 1);
   double candle5mOpen = iOpen(_Symbol, PERIOD_M5, 1);
   datetime candle5mTime = iTime(_Symbol, PERIOD_M5, 1);

   // Enhanced logging to debug candle data
   if(EnableDetailedLogging)
   {
      LogMessage("=== ANALYZING CLOSED CANDLE (Index 1) ===");
      LogMessage("Candle Time: " + TimeToString(candle5mTime, TIME_DATE|TIME_MINUTES));
      LogMessage("Open: " + DoubleToString(candle5mOpen, _Digits));
      LogMessage("High: " + DoubleToString(candle5mHigh, _Digits));
      LogMessage("Low: " + DoubleToString(candle5mLow, _Digits));
      LogMessage("Close: " + DoubleToString(candle5mClose, _Digits));
      LogMessage("4H High: " + DoubleToString(g_4HHigh, _Digits) + " | 4H Low: " + DoubleToString(g_4HLow, _Digits));

      // Show comparison
      if(candle5mClose < g_4HLow)
         LogMessage(">>> Candle closed BELOW 4H Low (Potential BUY breakout)");
      else if(candle5mClose > g_4HHigh)
         LogMessage(">>> Candle closed ABOVE 4H High (Potential SELL breakout)");
      else
         LogMessage(">>> Candle closed INSIDE 4H range");

      // Show last 3 candles for context
      LogMessage("--- Last 3 Candles for Context ---");
      for(int i = 1; i <= 3; i++)
      {
         datetime t = iTime(_Symbol, PERIOD_M5, i);
         double o = iOpen(_Symbol, PERIOD_M5, i);
         double h = iHigh(_Symbol, PERIOD_M5, i);
         double l = iLow(_Symbol, PERIOD_M5, i);
         double c = iClose(_Symbol, PERIOD_M5, i);

         string status = "";
         if(c < g_4HLow)
            status = " [BELOW 4H Low]";
         else if(c > g_4HHigh)
            status = " [ABOVE 4H High]";
         else
            status = " [INSIDE range]";

         LogMessage("Candle[" + IntegerToString(i) + "] " + TimeToString(t, TIME_DATE|TIME_MINUTES) +
                    " | O:" + DoubleToString(o, _Digits) +
                    " H:" + DoubleToString(h, _Digits) +
                    " L:" + DoubleToString(l, _Digits) +
                    " C:" + DoubleToString(c, _Digits) + status);
      }
   }

   // Export candle data to CSV for verification
   if(ExportCandleData)
   {
      ExportCandleToCSV(candle5mTime, candle5mOpen, candle5mHigh, candle5mLow, candle5mClose);
   }

   // Log active trades every 5-min candle
   if(LogActiveTradesEvery5Min)
   {
      LogActiveTrades();
   }

   // Track BUY signal (false breakout below 4H Low, then reversal above)
   bool canCheckBuySignal = !g_buyOrderPlaced && !HasOpenPosition(ORDER_TYPE_BUY);

   if(EnableDetailedLogging)
   {
      LogMessage("--- BUY Signal Check ---");
      LogMessage("g_buyOrderPlaced: " + (g_buyOrderPlaced ? "TRUE" : "FALSE"));
      LogMessage("HasOpenPosition(BUY): " + (HasOpenPosition(ORDER_TYPE_BUY) ? "TRUE" : "FALSE"));
      LogMessage("Can check BUY signal: " + (canCheckBuySignal ? "YES" : "NO"));
   }

   if(canCheckBuySignal)
   {
      // Step 1 & 2: Check if 5-min candle closed BELOW 4H Low (breakout confirmation)
      if(!g_buyBreakoutConfirmed && candle5mClose < g_4HLow)
      {
         LogMessage("*** BUY BREAKOUT DETECTED ***");
         LogMessage("5-min candle closed BELOW 4H Low");
         LogMessage("Candle Time: " + TimeToString(candle5mTime, TIME_DATE|TIME_MINUTES));
         LogMessage("Candle OHLC: O=" + DoubleToString(candle5mOpen, _Digits) +
                    " H=" + DoubleToString(candle5mHigh, _Digits) +
                    " L=" + DoubleToString(candle5mLow, _Digits) +
                    " C=" + DoubleToString(candle5mClose, _Digits));
         LogMessage("Candle Close: " + DoubleToString(candle5mClose, _Digits) + " | 4H Low: " + DoubleToString(g_4HLow, _Digits));
         LogMessage("Breakout Distance: " + DoubleToString(g_4HLow - candle5mClose, _Digits) + " points");

         // Check volume confirmation if enabled - want LOW volume on breakout
         bool volumeOK = true;
         if(g_activeVolumeConfirmation)
         {
            LogMessage("--- Checking Breakout Volume (Want LOW) ---");
            g_buyBreakoutVolume = GetCandleVolume(1);
            g_averageVolume = CalculateAverageVolume(g_symbolParams.volumeAveragePeriod);
            g_buyBreakoutVolumeOK = IsBreakoutVolumeLow(g_buyBreakoutVolume, g_averageVolume, g_symbolParams.breakoutVolumeMax);
            volumeOK = g_buyBreakoutVolumeOK;
         }
         else
         {
            LogMessage("Volume confirmation disabled - accepting breakout");
            g_buyBreakoutVolumeOK = true;
         }

         // Check divergence confirmation if volume is OK
         bool divergenceOK = true;
         if(volumeOK && g_activeDivergenceConfirmation)
         {
            LogMessage("--- Checking Divergence (Want Bullish) ---");

            bool rsiDivergence = DetectBullishRSIDivergence();
            bool macdDivergence = DetectBullishMACDDivergence();

            // Determine if divergence requirement is met
            if(RequireBothIndicators)
            {
               // Strict mode: require BOTH RSI and MACD divergence
               divergenceOK = (rsiDivergence && macdDivergence);
               g_buyDivergenceOK = divergenceOK;

               if(divergenceOK)
                  LogMessage("BOTH RSI and MACD show bullish divergence - CONFIRMED");
               else
                  LogMessage("Divergence requirement NOT met (need both RSI and MACD)");
            }
            else
            {
               // Lenient mode: require EITHER RSI or MACD divergence
               divergenceOK = (rsiDivergence || macdDivergence);
               g_buyDivergenceOK = divergenceOK;

               if(divergenceOK)
                  LogMessage("At least one indicator shows bullish divergence - CONFIRMED");
               else
                  LogMessage("No divergence detected on either RSI or MACD");
            }
         }
         else if(!g_activeDivergenceConfirmation)
         {
            LogMessage("Divergence confirmation disabled - accepting breakout");
            g_buyDivergenceOK = true;
         }

         // Only confirm breakout if BOTH volume and divergence are OK
         if(volumeOK && divergenceOK)
         {
            g_buyBreakoutConfirmed = true;
            g_buyBreakoutCandleTime = candle5mTime;
            LogMessage("*** BUY BREAKOUT CONFIRMED (Low Volume + Bullish Divergence) ***");
            LogMessage("Waiting for reversal back above 4H Low...");
         }
         else
         {
            if(!volumeOK)
            {
               LogMessage("*** BUY BREAKOUT REJECTED - Volume Too High ***");
               LogMessage("Strong breakout likely to continue - not ideal for false breakout");
            }
            if(!divergenceOK)
            {
               LogMessage("*** BUY BREAKOUT REJECTED - No Bullish Divergence ***");
               LogMessage("Strong momentum suggests true breakout - not ideal for reversal");
            }

            LogMessage("Resetting to wait for next breakout opportunity");
            // Reset flags so we can check for another breakout
            g_buyBreakoutConfirmed = false;
            g_buyBreakoutVolumeOK = false;
            g_buyDivergenceOK = false;
         }
      }
      else if(!g_buyBreakoutConfirmed && EnableDetailedLogging)
      {
         LogMessage("BUY Breakout NOT confirmed: Close (" + DoubleToString(candle5mClose, _Digits) +
                    ") >= 4H Low (" + DoubleToString(g_4HLow, _Digits) + ")");
      }

      // Step 3 & 4: Check if 5-min candle closed ABOVE 4H Low (reversal confirmation)
      if(g_buyBreakoutConfirmed && !g_buyReversalConfirmed && candle5mClose > g_4HLow)
      {
         LogMessage("*** BUY REVERSAL DETECTED ***");
         LogMessage("5-min candle closed ABOVE 4H Low after breakout");
         LogMessage("Candle Time: " + TimeToString(candle5mTime, TIME_DATE|TIME_MINUTES));
         LogMessage("Candle OHLC: O=" + DoubleToString(candle5mOpen, _Digits) +
                    " H=" + DoubleToString(candle5mHigh, _Digits) +
                    " L=" + DoubleToString(candle5mLow, _Digits) +
                    " C=" + DoubleToString(candle5mClose, _Digits));
         LogMessage("Candle Close: " + DoubleToString(candle5mClose, _Digits) + " | 4H Low: " + DoubleToString(g_4HLow, _Digits));
         LogMessage("Reversal Distance: " + DoubleToString(candle5mClose - g_4HLow, _Digits) + " points");

         // Check reversal volume confirmation if enabled - want HIGH volume on reversal
         bool reversalVolumeOK = true;
         if(g_activeVolumeConfirmation)
         {
            LogMessage("--- Checking Reversal Volume (Want HIGH) ---");

            // Get volume of the reversal candle (index 1 = last closed candle)
            g_buyReversalVolume = GetCandleVolume(1);

            // Reuse average volume if already calculated, otherwise calculate it
            if(g_averageVolume <= 0)
            {
               g_averageVolume = CalculateAverageVolume(g_symbolParams.volumeAveragePeriod);
            }

            // Check if reversal volume is HIGH (strong reversal = good confirmation)
            g_buyReversalVolumeOK = IsReversalVolumeHigh(g_buyReversalVolume, g_averageVolume, g_symbolParams.reversalVolumeMin);

            reversalVolumeOK = g_buyReversalVolumeOK;
         }
         else
         {
            LogMessage("Volume confirmation disabled - accepting reversal");
            g_buyReversalVolumeOK = true;
         }

         // Only confirm reversal if volume is HIGH (or volume check is disabled)
         if(!reversalVolumeOK)
         {
            LogMessage("*** BUY REVERSAL REJECTED - Volume Too Low ***");
            LogMessage("Weak reversal lacks conviction - not ideal for trade");
            LogMessage("Resetting to wait for next opportunity");
            // Reset flags so we can check for another breakout
            g_buyBreakoutConfirmed = false;
            g_buyReversalConfirmed = false;
            g_buyBreakoutVolumeOK = false;
            g_buyReversalVolumeOK = false;
            g_buyDivergenceOK = false;
            return;
         }

         g_buyReversalConfirmed = true;

         // Find the LOWEST low among the LATEST 10 candles within breakout-to-reversal range
         datetime startTime = MathMax(g_buyBreakoutCandleTime, candle5mTime - (10 * 5 * 60));
         double lowestLow = FindLowestLowInRange(startTime, candle5mTime);

         LogMessage("Analyzing latest 10 candles from " + TimeToString(startTime, TIME_MINUTES) +
                    " to " + TimeToString(candle5mTime, TIME_MINUTES));
         LogMessage("(Breakout occurred at: " + TimeToString(g_buyBreakoutCandleTime, TIME_MINUTES) + ")");

         // Validate lowestLow before proceeding
         if(lowestLow == DBL_MAX || lowestLow <= 0)
         {
            LogMessage("ERROR: No valid bullish candles found in breakout pattern");
            LogMessage("Cannot determine lowest low - skipping BUY order");
            LogMessage("Resetting BUY signal tracking");
            g_buyBreakoutConfirmed = false;
            g_buyReversalConfirmed = false;
            return;
         }

         LogMessage("LOWEST Low in pattern: " + DoubleToString(lowestLow, _Digits));
         LogMessage("*** BUY REVERSAL CONFIRMED (High Volume) ***");
         LogMessage("FALSE BREAKOUT PATTERN COMPLETE - Executing BUY order");

         // Check if symbol is enabled for trading
         if(!IsSymbolEnabled())
         {
            LogMessage("TRADE BLOCKED: Symbol " + _Symbol + " is currently disabled");
            LogMessage("Reason: " + g_symbolStats.disableReason);
            LogMessage("Resetting BUY signal tracking");
            g_buyBreakoutConfirmed = false;
            g_buyReversalConfirmed = false;
            return;
         }

         // Execute buy order using optimized SL calculation
         if(ExecuteBuyOrder(lowestLow, g_buyBreakoutCandleTime, candle5mTime))
         {
            g_buyOrderPlaced = true;
            LogMessage(">>> g_buyOrderPlaced set to TRUE <<<");
            // Reset tracking after successful order
            g_buyBreakoutConfirmed = false;
            g_buyReversalConfirmed = false;
            g_buyBreakoutCandleTime = 0;
            LogMessage("Buy order successfully placed and executed");
         }
         else
         {
            LogMessage("Buy order execution FAILED");
            LogMessage(">>> g_buyOrderPlaced remains FALSE - will retry on next signal <<<");
            // Reset on failure to try again
            g_buyBreakoutConfirmed = false;
            g_buyReversalConfirmed = false;
            g_buyBreakoutCandleTime = 0;
         }
      }
   }

   // Track SELL signal (false breakout above 4H High, then reversal below)
   bool canCheckSellSignal = !g_sellOrderPlaced && !HasOpenPosition(ORDER_TYPE_SELL);

   if(EnableDetailedLogging)
   {
      LogMessage("--- SELL Signal Check ---");
      LogMessage("g_sellOrderPlaced: " + (g_sellOrderPlaced ? "TRUE" : "FALSE"));
      LogMessage("HasOpenPosition(SELL): " + (HasOpenPosition(ORDER_TYPE_SELL) ? "TRUE" : "FALSE"));
      LogMessage("Can check SELL signal: " + (canCheckSellSignal ? "YES" : "NO"));
   }

   if(canCheckSellSignal)
   {
      // Step 1 & 2: Check if 5-min candle closed ABOVE 4H High (breakout confirmation)
      if(!g_sellBreakoutConfirmed && candle5mClose > g_4HHigh)
      {
         LogMessage("*** SELL BREAKOUT DETECTED ***");
         LogMessage("5-min candle closed ABOVE 4H High");
         LogMessage("Candle Time: " + TimeToString(candle5mTime, TIME_DATE|TIME_MINUTES));
         LogMessage("Candle OHLC: O=" + DoubleToString(candle5mOpen, _Digits) +
                    " H=" + DoubleToString(candle5mHigh, _Digits) +
                    " L=" + DoubleToString(candle5mLow, _Digits) +
                    " C=" + DoubleToString(candle5mClose, _Digits));
         LogMessage("Candle Close: " + DoubleToString(candle5mClose, _Digits) + " | 4H High: " + DoubleToString(g_4HHigh, _Digits));
         LogMessage("Breakout Distance: " + DoubleToString(candle5mClose - g_4HHigh, _Digits) + " points");

         // Check volume confirmation if enabled - want LOW volume on breakout
         bool volumeOK = true;
         if(g_activeVolumeConfirmation)
         {
            LogMessage("--- Checking Breakout Volume (Want LOW) ---");

            // Get volume of the breakout candle (index 1 = last closed candle)
            g_sellBreakoutVolume = GetCandleVolume(1);

            // Calculate average volume (reuse if already calculated for BUY check)
            if(g_averageVolume <= 0)
            {
               g_averageVolume = CalculateAverageVolume(g_symbolParams.volumeAveragePeriod);
            }

            // Check if breakout volume is LOW (weak breakout = good for false breakout strategy)
            g_sellBreakoutVolumeOK = IsBreakoutVolumeLow(g_sellBreakoutVolume, g_averageVolume, g_symbolParams.breakoutVolumeMax);

            volumeOK = g_sellBreakoutVolumeOK;
         }
         else
         {
            LogMessage("Volume confirmation disabled - accepting breakout");
            g_sellBreakoutVolumeOK = true;
         }

         // Check divergence confirmation if volume is OK
         bool divergenceOK = true;
         if(volumeOK && g_activeDivergenceConfirmation)
         {
            LogMessage("--- Checking Divergence (Want Bearish) ---");

            bool rsiDivergence = DetectBearishRSIDivergence();
            bool macdDivergence = DetectBearishMACDDivergence();

            // Determine if divergence requirement is met
            if(RequireBothIndicators)
            {
               // Strict mode: require BOTH RSI and MACD divergence
               divergenceOK = (rsiDivergence && macdDivergence);
               g_sellDivergenceOK = divergenceOK;

               if(divergenceOK)
                  LogMessage("BOTH RSI and MACD show bearish divergence - CONFIRMED");
               else
                  LogMessage("Divergence requirement NOT met (need both RSI and MACD)");
            }
            else
            {
               // Lenient mode: require EITHER RSI or MACD divergence
               divergenceOK = (rsiDivergence || macdDivergence);
               g_sellDivergenceOK = divergenceOK;

               if(divergenceOK)
                  LogMessage("At least one indicator shows bearish divergence - CONFIRMED");
               else
                  LogMessage("No divergence detected on either RSI or MACD");
            }
         }
         else if(!g_activeDivergenceConfirmation)
         {
            LogMessage("Divergence confirmation disabled - accepting breakout");
            g_sellDivergenceOK = true;
         }

         // Only confirm breakout if BOTH volume and divergence are OK
         if(volumeOK && divergenceOK)
         {
            g_sellBreakoutConfirmed = true;
            g_sellBreakoutCandleTime = candle5mTime;
            LogMessage("*** SELL BREAKOUT CONFIRMED (Low Volume + Bearish Divergence) ***");
            LogMessage("Waiting for reversal back below 4H High...");
         }
         else
         {
            if(!volumeOK)
            {
               LogMessage("*** SELL BREAKOUT REJECTED - Volume Too High ***");
               LogMessage("Strong breakout likely to continue - not ideal for false breakout");
            }
            if(!divergenceOK)
            {
               LogMessage("*** SELL BREAKOUT REJECTED - No Bearish Divergence ***");
               LogMessage("Strong momentum suggests true breakout - not ideal for reversal");
            }

            LogMessage("Resetting to wait for next breakout opportunity");
            // Reset flags so we can check for another breakout
            g_sellBreakoutConfirmed = false;
            g_sellBreakoutVolumeOK = false;
            g_sellDivergenceOK = false;
         }
      }
      else if(!g_sellBreakoutConfirmed && EnableDetailedLogging)
      {
         LogMessage("SELL Breakout NOT confirmed: Close (" + DoubleToString(candle5mClose, _Digits) +
                    ") <= 4H High (" + DoubleToString(g_4HHigh, _Digits) + ")");
      }

      // Step 3 & 4: Check if 5-min candle closed BELOW 4H High (reversal confirmation)
      if(g_sellBreakoutConfirmed && !g_sellReversalConfirmed && candle5mClose < g_4HHigh)
      {
         LogMessage("*** SELL REVERSAL DETECTED ***");
         LogMessage("5-min candle closed BELOW 4H High after breakout");
         LogMessage("Candle Time: " + TimeToString(candle5mTime, TIME_DATE|TIME_MINUTES));
         LogMessage("Candle OHLC: O=" + DoubleToString(candle5mOpen, _Digits) +
                    " H=" + DoubleToString(candle5mHigh, _Digits) +
                    " L=" + DoubleToString(candle5mLow, _Digits) +
                    " C=" + DoubleToString(candle5mClose, _Digits));
         LogMessage("Candle Close: " + DoubleToString(candle5mClose, _Digits) + " | 4H High: " + DoubleToString(g_4HHigh, _Digits));
         LogMessage("Reversal Distance: " + DoubleToString(g_4HHigh - candle5mClose, _Digits) + " points");

         // Check reversal volume confirmation if enabled - want HIGH volume on reversal
         bool reversalVolumeOK = true;
         if(g_activeVolumeConfirmation)
         {
            LogMessage("--- Checking Reversal Volume (Want HIGH) ---");

            // Get volume of the reversal candle (index 1 = last closed candle)
            g_sellReversalVolume = GetCandleVolume(1);

            // Reuse average volume if already calculated, otherwise calculate it
            if(g_averageVolume <= 0)
            {
               g_averageVolume = CalculateAverageVolume(g_symbolParams.volumeAveragePeriod);
            }

            // Check if reversal volume is HIGH (strong reversal = good confirmation)
            g_sellReversalVolumeOK = IsReversalVolumeHigh(g_sellReversalVolume, g_averageVolume, g_symbolParams.reversalVolumeMin);

            reversalVolumeOK = g_sellReversalVolumeOK;
         }
         else
         {
            LogMessage("Volume confirmation disabled - accepting reversal");
            g_sellReversalVolumeOK = true;
         }

         // Only confirm reversal if volume is HIGH (or volume check is disabled)
         if(!reversalVolumeOK)
         {
            LogMessage("*** SELL REVERSAL REJECTED - Volume Too Low ***");
            LogMessage("Weak reversal lacks conviction - not ideal for trade");
            LogMessage("Resetting to wait for next opportunity");
            // Reset flags so we can check for another breakout
            g_sellBreakoutConfirmed = false;
            g_sellReversalConfirmed = false;
            g_sellBreakoutVolumeOK = false;
            g_sellReversalVolumeOK = false;
            g_sellDivergenceOK = false;
            return;
         }

         g_sellReversalConfirmed = true;

         // Find the HIGHEST high among the LATEST 10 candles within breakout-to-reversal range
         datetime startTime = MathMax(g_sellBreakoutCandleTime, candle5mTime - (10 * 5 * 60));
         double highestHigh = FindHighestHighInRange(startTime, candle5mTime);

         LogMessage("Analyzing latest 10 candles from " + TimeToString(startTime, TIME_MINUTES) +
                    " to " + TimeToString(candle5mTime, TIME_MINUTES));
         LogMessage("(Breakout occurred at: " + TimeToString(g_sellBreakoutCandleTime, TIME_MINUTES) + ")");

         // Validate highestHigh before proceeding
         if(highestHigh <= 0 || highestHigh == DBL_MAX)
         {
            LogMessage("ERROR: No valid bearish candles found in breakout pattern");
            LogMessage("Cannot determine highest high - skipping SELL order");
            LogMessage("Resetting SELL signal tracking");
            g_sellBreakoutConfirmed = false;
            g_sellReversalConfirmed = false;
            return;
         }

         LogMessage("HIGHEST High in pattern: " + DoubleToString(highestHigh, _Digits));
         LogMessage("*** SELL REVERSAL CONFIRMED (High Volume) ***");
         LogMessage("FALSE BREAKOUT PATTERN COMPLETE - Executing SELL order");

         // Check if symbol is enabled for trading
         if(!IsSymbolEnabled())
         {
            LogMessage("TRADE BLOCKED: Symbol " + _Symbol + " is currently disabled");
            LogMessage("Reason: " + g_symbolStats.disableReason);
            LogMessage("Resetting SELL signal tracking");
            g_sellBreakoutConfirmed = false;
            g_sellReversalConfirmed = false;
            return;
         }

         // Execute sell order using optimized SL calculation
         if(ExecuteSellOrder(highestHigh, g_sellBreakoutCandleTime, candle5mTime))
         {
            g_sellOrderPlaced = true;
            LogMessage(">>> g_sellOrderPlaced set to TRUE <<<");
            // Reset tracking after successful order
            g_sellBreakoutConfirmed = false;
            g_sellReversalConfirmed = false;
            g_sellBreakoutCandleTime = 0;
            LogMessage("Sell order successfully placed and executed");
         }
         else
         {
            LogMessage("Sell order execution FAILED");
            LogMessage(">>> g_sellOrderPlaced remains FALSE - will retry on next signal <<<");
            // Reset on failure to try again
            g_sellBreakoutConfirmed = false;
            g_sellReversalConfirmed = false;
            g_sellBreakoutCandleTime = 0;
         }
      }
   }

   // Detailed logging of current state
   if(EnableDetailedLogging)
   {
      LogMessage("--- False Breakout Tracking ---");
      LogMessage("Using 4H Candle: " + TimeToString(g_processed04CandleTime, TIME_DATE|TIME_MINUTES) + " UTC");
      LogMessage("Last 5min Close: " + DoubleToString(candle5mClose, _Digits));
      LogMessage("4H High: " + DoubleToString(g_4HHigh, _Digits) + " | 4H Low: " + DoubleToString(g_4HLow, _Digits));
      LogMessage("BUY: Breakout=" + (g_buyBreakoutConfirmed ? "YES" : "NO") + " | Reversal=" + (g_buyReversalConfirmed ? "YES" : "NO"));
      LogMessage("SELL: Breakout=" + (g_sellBreakoutConfirmed ? "YES" : "NO") + " | Reversal=" + (g_sellReversalConfirmed ? "YES" : "NO"));
   }
}

//+------------------------------------------------------------------+
//| Export candle data to CSV file for verification                  |
//+------------------------------------------------------------------+
void ExportCandleToCSV(datetime time, double open, double high, double low, double close)
{
   static int csvHandle = INVALID_HANDLE;
   static bool headerWritten = false;

   // Create CSV filename with symbol and date
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   string filename = StringFormat("CandleData_%s_%04d%02d%02d.csv",
                                  _Symbol, dt.year, dt.mon, dt.day);

   // Open file for writing (append mode)
   if(csvHandle == INVALID_HANDLE)
   {
      csvHandle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');

      if(csvHandle == INVALID_HANDLE)
      {
         LogMessage("ERROR: Failed to create CSV file: " + filename);
         return;
      }

      LogMessage("CSV Export: Created file " + filename);
   }

   // Write header on first call
   if(!headerWritten)
   {
      FileWrite(csvHandle, "DateTime", "Open", "High", "Low", "Close", "4H_High", "4H_Low", "Status");
      headerWritten = true;
   }

   // Determine status
   string status = "INSIDE";
   if(close < g_4HLow)
      status = "BELOW_4H_LOW";
   else if(close > g_4HHigh)
      status = "ABOVE_4H_HIGH";

   // Write candle data
   FileWrite(csvHandle,
             TimeToString(time, TIME_DATE|TIME_MINUTES),
             DoubleToString(open, _Digits),
             DoubleToString(high, _Digits),
             DoubleToString(low, _Digits),
             DoubleToString(close, _Digits),
             DoubleToString(g_4HHigh, _Digits),
             DoubleToString(g_4HLow, _Digits),
             status);

   FileFlush(csvHandle);
}

//+------------------------------------------------------------------+
//| Log all active trades for this EA                                |
//+------------------------------------------------------------------+
void LogActiveTrades()
{
   int totalPositions = PositionsTotal();
   int eaPositions = 0;
   bool hasBuyPosition = false;
   bool hasSellPosition = false;

   LogMessage("=== ACTIVE TRADES CHECK ===");
   LogMessage("Total positions in account: " + IntegerToString(totalPositions));

   // First, count EA positions and check what types exist
   for(int i = 0; i < totalPositions; i++)
   {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         eaPositions++;
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

         if(type == POSITION_TYPE_BUY)
            hasBuyPosition = true;
         else if(type == POSITION_TYPE_SELL)
            hasSellPosition = true;
      }
   }

   // Auto-correct flags if no positions exist
   bool flagsCorrected = false;

   if(!hasBuyPosition && g_buyOrderPlaced)
   {
      LogMessage("*** AUTO-CORRECTION: No BUY position exists but g_buyOrderPlaced = TRUE ***");
      LogMessage("Resetting g_buyOrderPlaced to FALSE");
      g_buyOrderPlaced = false;
      flagsCorrected = true;
   }

   if(!hasSellPosition && g_sellOrderPlaced)
   {
      LogMessage("*** AUTO-CORRECTION: No SELL position exists but g_sellOrderPlaced = TRUE ***");
      LogMessage("Resetting g_sellOrderPlaced to FALSE");
      g_sellOrderPlaced = false;
      flagsCorrected = true;
   }

   if(flagsCorrected)
   {
      LogMessage("Flags have been auto-corrected - EA can now check for new signals");
   }

   if(eaPositions == 0)
   {
      LogMessage("No EA positions for this symbol");
      LogMessage("g_buyOrderPlaced: " + (g_buyOrderPlaced ? "TRUE" : "FALSE"));
      LogMessage("g_sellOrderPlaced: " + (g_sellOrderPlaced ? "TRUE" : "FALSE"));
      LogMessage("===========================");
      return;
   }

   // Now log detailed information for each EA position
   LogMessage("EA has " + IntegerToString(eaPositions) + " active position(s)");

   int positionCount = 0;
   for(int i = 0; i < totalPositions; i++)
   {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber)
      {
         positionCount++;

         ulong ticket = PositionGetInteger(POSITION_TICKET);
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentPrice = (type == POSITION_TYPE_BUY) ?
                               SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                               SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double sl = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);
         double profit = PositionGetDouble(POSITION_PROFIT);
         datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);

         string typeStr = (type == POSITION_TYPE_BUY) ? "BUY" : "SELL";

         LogMessage("--- Position #" + IntegerToString(positionCount) + " ---");
         LogMessage("Ticket: " + IntegerToString(ticket));
         LogMessage("Type: " + typeStr);
         LogMessage("Volume: " + DoubleToString(volume, 2));
         LogMessage("Open Price: " + DoubleToString(openPrice, _Digits));
         LogMessage("Current Price: " + DoubleToString(currentPrice, _Digits));
         LogMessage("Stop Loss: " + DoubleToString(sl, _Digits));
         LogMessage("Take Profit: " + (tp > 0 ? DoubleToString(tp, _Digits) : "None"));
         LogMessage("Profit: " + DoubleToString(profit, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY));
         LogMessage("Open Time: " + TimeToString(openTime, TIME_DATE|TIME_MINUTES));

         // Calculate R:R
         double risk = MathAbs(openPrice - sl);
         double currentPnL = (type == POSITION_TYPE_BUY) ?
                            (currentPrice - openPrice) :
                            (openPrice - currentPrice);
         double currentRR = (risk > 0) ? (currentPnL / risk) : 0;

         LogMessage("Current R:R: " + DoubleToString(currentRR, 2));
      }
   }

   LogMessage("EA Positions: " + IntegerToString(eaPositions) + " / " + IntegerToString(totalPositions));
   LogMessage("g_buyOrderPlaced: " + (g_buyOrderPlaced ? "TRUE" : "FALSE"));
   LogMessage("g_sellOrderPlaced: " + (g_sellOrderPlaced ? "TRUE" : "FALSE"));
   LogMessage("===========================");
}
//+------------------------------------------------------------------+
