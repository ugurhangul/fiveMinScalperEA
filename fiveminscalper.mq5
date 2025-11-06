//+------------------------------------------------------------------+
//|                                              FiveMinScalper.mq5 |
//|                                  5-Minute Scalping Strategy EA |
//|                                Based on 4-Hour Candle Breakouts |
//+------------------------------------------------------------------+
#property copyright "FiveMinScalper"
#property link      ""
#property version   "1.00"
#property strict

// Include all modular files
#include "Include/FMS_Config.mqh"
#include "Include/FMS_GlobalVars.mqh"
#include "Include/FMS_Utilities.mqh"
#include "Include/FMS_Indicators.mqh"
#include "Include/FMS_TradeManagement.mqh"
#include "Include/FMS_TradeExecution.mqh"
#include "Include/FMS_SymbolOptimization.mqh"
#include "Include/FMS_ChartVisual.mqh"
#include "Include/FMS_CandleProcessing.mqh"
#include "Include/FMS_Strategy.mqh"

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   LogMessage("=== FiveMinScalper EA Initialized ===");
   LogMessage("Symbol: " + _Symbol);
   LogMessage("Timeframe: " + EnumToString(PERIOD_CURRENT));
   LogMessage("Entry Offset: " + DoubleToString(EntryOffsetPercent, 2) + "%");
   LogMessage("Stop-Loss Offset: " + DoubleToString(StopLossOffsetPercent, 2) + "%");
   LogMessage("Risk/Reward Ratio: 1:" + DoubleToString(RiskRewardRatio, 2));
   LogMessage("Risk Per Trade: " + DoubleToString(RiskPercentPerTrade, 2) + "%");
   LogMessage("Use Breakeven: " + (UseBreakeven ? "Yes" : "No"));
   if(UseBreakeven)
      LogMessage("Breakeven Trigger: " + DoubleToString(BreakevenTriggerRR, 2) + " R:R");
   LogMessage("Use Trailing Stop: " + (UseTrailingStop ? "Yes" : "No"));
   if(UseTrailingStop)
   {
      LogMessage("Trailing Stop Trigger: " + DoubleToString(TrailingStopTriggerRR, 2) + " R:R");
      LogMessage("Trailing Stop Distance: " + DoubleToString(TrailingStopDistance, 0) + " points");
   }
   LogMessage("Use Only Second 4H Candle: " + (UseOnly00UTCCandle ? "Yes (chart shows 04:00, opens 04:00-closes 08:00 UTC)" : "No"));
   LogMessage("Trading Hours Filter: " + (UseTradingHours ? "Enabled" : "Disabled"));
   if(UseTradingHours)
   {
      LogMessage("Trading Hours: " + IntegerToString(StartHour) + ":00 - " + IntegerToString(EndHour) + ":00");
   }
   LogMessage("Magic Number: " + IntegerToString(MagicNumber));
   LogMessage("Account Balance: " + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
   LogMessage("Account Currency: " + AccountInfoString(ACCOUNT_CURRENCY));

   // Validate inputs
   if(RiskPercentPerTrade <= 0 || RiskPercentPerTrade > 100)
   {
      LogMessage("ERROR: Risk percent must be between 0 and 100");
      return(INIT_PARAMETERS_INCORRECT);
   }

   if(RiskRewardRatio <= 0)
   {
      LogMessage("ERROR: Risk/Reward ratio must be positive");
      return(INIT_PARAMETERS_INCORRECT);
   }

   // Cache symbol properties for performance optimization
   g_symbolPoint = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   g_symbolDigits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_symbolTickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   g_symbolMinLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   g_symbolMaxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   g_symbolLotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   LogMessage("Symbol properties cached:");
   LogMessage("  Point: " + DoubleToString(g_symbolPoint, _Digits));
   LogMessage("  Digits: " + IntegerToString(g_symbolDigits));
   LogMessage("  Tick Value: " + DoubleToString(g_symbolTickValue, 2));
   LogMessage("  Min Lot: " + DoubleToString(g_symbolMinLot, 2));
   LogMessage("  Max Lot: " + DoubleToString(g_symbolMaxLot, 2));
   LogMessage("  Lot Step: " + DoubleToString(g_symbolLotStep, 2));

   // Store default parameters from inputs
   g_defaultParams.breakoutVolumeMax = BreakoutVolumeMaxMultiplier;
   g_defaultParams.reversalVolumeMin = ReversalVolumeMinMultiplier;
   g_defaultParams.volumeAveragePeriod = VolumeAveragePeriod;
   g_defaultParams.rsiPeriod = RSI_Period;
   g_defaultParams.macdFast = MACD_Fast;
   g_defaultParams.macdSlow = MACD_Slow;
   g_defaultParams.macdSignal = MACD_Signal;
   g_defaultParams.divergenceLookback = DivergenceLookback;
   g_defaultParams.adaptiveLossTrigger = AdaptiveLossTrigger;
   g_defaultParams.adaptiveWinRecovery = AdaptiveWinRecovery;

   // Apply symbol-specific parameters (or use defaults if disabled)
   ApplySymbolParameters();

   // Use symbol-specific parameters if enabled, otherwise use defaults
   if(UseSymbolSpecificSettings)
   {
      // Symbol-specific parameters are now active in g_symbolParams
      LogMessage("Using symbol-specific optimized parameters");
   }
   else
   {
      // Copy default parameters to symbol parameters
      g_symbolParams = g_defaultParams;
      LogMessage("Using default input parameters (symbol-specific optimization disabled)");
   }

   // Initialize RSI and MACD indicators (always needed for adaptive system)
   // Use symbol-specific parameters for indicator initialization
   LogMessage("Initializing divergence indicators with symbol-specific parameters...");

   // Create RSI indicator on 5-minute timeframe using symbol-specific period
   g_rsiHandle = iRSI(_Symbol, PERIOD_M5, g_symbolParams.rsiPeriod, PRICE_CLOSE);
   if(g_rsiHandle == INVALID_HANDLE)
   {
      LogMessage("ERROR: Failed to create RSI indicator");
      return(INIT_FAILED);
   }

   // Create MACD indicator on 5-minute timeframe using symbol-specific parameters
   g_macdHandle = iMACD(_Symbol, PERIOD_M5, g_symbolParams.macdFast, g_symbolParams.macdSlow, g_symbolParams.macdSignal, PRICE_CLOSE);
   if(g_macdHandle == INVALID_HANDLE)
   {
      LogMessage("ERROR: Failed to create MACD indicator");
      return(INIT_FAILED);
   }

   LogMessage("Divergence indicators initialized successfully");
   LogMessage("  RSI Period: " + IntegerToString(g_symbolParams.rsiPeriod));
   LogMessage("  MACD: " + IntegerToString(g_symbolParams.macdFast) + ", " + IntegerToString(g_symbolParams.macdSlow) + ", " + IntegerToString(g_symbolParams.macdSignal));
   LogMessage("  Divergence Lookback: " + IntegerToString(g_symbolParams.divergenceLookback) + " candles");
   LogMessage("  Require Both Indicators: " + (RequireBothIndicators ? "Yes" : "No"));

   // Initialize filter settings for adaptive system
   // Store the starting state as the "original" state to restore to
   g_originalVolumeConfirmation = StartWithFiltersEnabled;
   g_originalDivergenceConfirmation = StartWithFiltersEnabled;
   g_activeVolumeConfirmation = StartWithFiltersEnabled;
   g_activeDivergenceConfirmation = StartWithFiltersEnabled;

   if(UseAdaptiveFilters)
   {
      LogMessage("Adaptive Filter System: ENABLED");
      LogMessage("  Loss Trigger: " + IntegerToString(g_symbolParams.adaptiveLossTrigger) + " consecutive losses (symbol-optimized)");
      LogMessage("  Win Recovery: " + IntegerToString(g_symbolParams.adaptiveWinRecovery) + " consecutive wins (symbol-optimized)");
      LogMessage("  Starting State: Filters " + (StartWithFiltersEnabled ? "ENABLED" : "DISABLED"));
      LogMessage("  When filters activate: Volume AND Divergence confirmation required");
      LogMessage("  When filters deactivate: Return to starting state (" + (StartWithFiltersEnabled ? "Enabled" : "Disabled") + ")");
   }
   else
   {
      LogMessage("Adaptive Filter System: DISABLED");
      LogMessage("  Filters permanently: " + (StartWithFiltersEnabled ? "ENABLED" : "DISABLED"));
   }

   // Initialize symbol-level adaptive system
   InitializeSymbolStats();

   if(UseSymbolAdaptation)
   {
      LogMessage("Symbol-Level Adaptation: ENABLED");
      LogMessage("  Min Trades for Evaluation: " + IntegerToString(SymbolMinTrades));
      LogMessage("  Min Win Rate: " + DoubleToString(SymbolMinWinRate, 1) + "%");
      LogMessage("  Max Loss Threshold: $" + DoubleToString(SymbolMaxLoss, 2));
      LogMessage("  Max Consecutive Losses: " + IntegerToString(SymbolMaxConsecutiveLosses));
      LogMessage("  Cooling Period: " + IntegerToString(SymbolCoolingPeriodDays) + " days");
   }
   else
   {
      LogMessage("Symbol-Level Adaptation: DISABLED");
   }

   LogMessage("Initialization successful - EA is ready to trade");

   // Initialize with current 4H candle on startup
   datetime current4HTime = iTime(_Symbol, PERIOD_H4, 0);
   if(current4HTime > 0)
   {
      int candleIndex = 1; // Start with last closed candle
      bool foundValidCandle = false;

      // If second 4H candle filter is enabled, search for it
      // NOTE: Both iTime() and chart display opening time (04:00 UTC)
      // Second 4H candle: opens 04:00 UTC, closes 08:00 UTC
      if(UseOnly00UTCCandle)
      {
         LogMessage("Searching for second 4H candle of day (opens 04:00 UTC, closes 08:00 UTC)...");

         // Search backwards up to 24 hours (6 x 4H candles)
         for(int i = 1; i <= 6; i++)
         {
            datetime candleTime = iTime(_Symbol, PERIOD_H4, i);  // Returns opening time
            MqlDateTime timeStruct;
            TimeToStruct(candleTime, timeStruct);

            if(timeStruct.hour == 4)  // Second candle opens at 04:00 UTC (chart shows 04:00)
            {
               candleIndex = i;
               foundValidCandle = true;
               LogMessage("Found second 4H candle at index " + IntegerToString(i));
               LogMessage("Opening time: " + TimeToString(candleTime, TIME_DATE|TIME_MINUTES) + " UTC (shown on chart)");
               LogMessage("Closing time: 08:00 UTC");
               break;
            }
         }

         if(!foundValidCandle)
         {
            LogMessage("No second 4H candle found in last 24 hours - waiting for next one");
            LogMessage("EA will not trade until a valid 4H candle is processed");
         }
      }
      else
      {
         // No filter - use the last closed candle
         foundValidCandle = true;
         LogMessage("Processing last closed 4H candle (no time filter)...");
      }

      if(foundValidCandle)
      {
         // Initialize both tracking variables
         g_last4HCandleTime = current4HTime;
         g_lastSeen4HCandleTime = current4HTime;

         // Process the found candle
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

         MqlDateTime timeStruct;
         TimeToStruct(closedCandleTime, timeStruct);

         double range = g_4HHigh - g_4HLow;
         string candleType = (close > open) ? "Bullish" : (close < open) ? "Bearish" : "Doji";

         LogMessage("========================================");
         LogMessage("=== 4H CANDLE ANALYSIS (STARTUP) ===");
         LogMessage("Closed at: " + TimeToString(closedCandleTime, TIME_DATE|TIME_MINUTES) + " UTC");
         LogMessage("Candle Type: " + candleType);
         LogMessage("Open: " + DoubleToString(open, _Digits));
         LogMessage("High: " + DoubleToString(g_4HHigh, _Digits));
         LogMessage("Low: " + DoubleToString(g_4HLow, _Digits));
         LogMessage("Close: " + DoubleToString(close, _Digits));
         LogMessage("Range: " + DoubleToString(range, _Digits) + " (" + DoubleToString(range / g_4HLow * 100, 2) + "%)");
         LogMessage("Volume: " + IntegerToString(volume4H));

         LogMessage("--- False Breakout Strategy ---");
         LogMessage("NOW USING 4H CANDLE: " + TimeToString(closedCandleTime, TIME_DATE|TIME_MINUTES) + " UTC");
         LogMessage("BUY Signal: Wait for 5min close BELOW " + DoubleToString(g_4HLow, _Digits) + ", then close ABOVE it");
         LogMessage("SELL Signal: Wait for 5min close ABOVE " + DoubleToString(g_4HHigh, _Digits) + ", then close BELOW it");

         // Reset order flags and breakout tracking
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

         // Check if we're in the restricted trading period (04:00-08:00 UTC)
         if(IsInCandleFormationPeriod())
         {
            g_tradingAllowedToday = false;
            LogMessage("TRADING SUSPENDED - EA started during restricted period (04:00-08:00 UTC)");
            LogMessage("Trading will begin at 08:00 UTC after the second 4H candle has closed");
         }
         else
         {
            // Enable trading after processing new 4H candle
            g_tradingAllowedToday = true;
            LogMessage("TRADING ENABLED - New 4H candle processed on startup");
         }

         LogMessage("Order flags and breakout tracking reset - Ready to monitor for false breakout signals");

         // Draw levels on chart
         if(ShowLevelsOnChart)
         {
            DrawLevelsOnChart();
         }

         LogMessage("========================================");
      }
   }
   else
   {
      LogMessage("Waiting for 4H candle data...");
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   LogMessage("=== FiveMinScalper EA Stopped ===");
   LogMessage("Reason Code: " + IntegerToString(reason));

   string reasonText = "";
   switch(reason)
   {
      case REASON_PROGRAM: reasonText = "EA was stopped by user"; break;
      case REASON_REMOVE: reasonText = "EA was removed from chart"; break;
      case REASON_RECOMPILE: reasonText = "EA was recompiled"; break;
      case REASON_CHARTCHANGE: reasonText = "Chart symbol or period changed"; break;
      case REASON_CHARTCLOSE: reasonText = "Chart was closed"; break;
      case REASON_PARAMETERS: reasonText = "Input parameters changed"; break;
      case REASON_ACCOUNT: reasonText = "Account changed"; break;
      case REASON_TEMPLATE: reasonText = "Template changed"; break;
      case REASON_INITFAILED: reasonText = "Initialization failed"; break;
      case REASON_CLOSE: reasonText = "Terminal closing"; break;
      default: reasonText = "Unknown reason";
   }

   LogMessage("Reason: " + reasonText);
   LogMessage("Total open positions: " + IntegerToString(PositionsTotal()));

   // Release indicator handles
   if(g_rsiHandle != INVALID_HANDLE)
   {
      IndicatorRelease(g_rsiHandle);
      g_rsiHandle = INVALID_HANDLE;
   }

   if(g_macdHandle != INVALID_HANDLE)
   {
      IndicatorRelease(g_macdHandle);
      g_macdHandle = INVALID_HANDLE;
   }

   // Remove all chart objects created by this EA
   DeleteAllChartObjects();

   // Close log file if open
   if(g_logFileHandle != INVALID_HANDLE)
   {
      FileClose(g_logFileHandle);
      g_logFileHandle = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Only run main logic when a new 5-minute candle has closed
   if(IsNew5MinCandle())
   {
      LogMessage("=== NEW 5-MIN CANDLE CLOSED ===");

      // Check if we've crossed midnight (00:00 UTC) - disable trading until new 4H candle
      MqlDateTime currentTime;
      TimeToStruct(TimeCurrent(), currentTime);

      static int lastDay = -1;

      // If it's a new day and we haven't processed a 4H candle yet today
      if(lastDay != -1 && currentTime.day != lastDay && g_tradingAllowedToday)
      {
         g_tradingAllowedToday = false;
         LogMessage("========================================");
         LogMessage("*** MIDNIGHT CROSSED - TRADING SUSPENDED ***");
         LogMessage("Current time: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES) + " UTC");
         LogMessage("Trading will resume after new 4H candle is processed");
         LogMessage("========================================");
      }

      lastDay = currentTime.day;

      // Check if new 4H candle has formed (only once per 5-min candle)
      if(IsNew4HCandle())
      {
         Process4HCandle();
      }

      // Verify we have valid 4H data (safety check - only when filter is enabled)
      if(UseOnly00UTCCandle && g_4HHigh > 0 && g_4HLow > 0 && g_processed04CandleTime > 0)
      {
         // Find the most recent 00:00 UTC candle
         datetime latest00Candle = Find00UTCCandle();

         // Only update if we found a newer 00:00 candle than what we're currently using
         if(latest00Candle > g_processed04CandleTime && latest00Candle > 0)
         {
            LogMessage("========================================");
            LogMessage("*** NEW 00:00 UTC CANDLE AVAILABLE ***");
            LogMessage("Currently using: " + TimeToString(g_processed04CandleTime, TIME_DATE|TIME_MINUTES) + " UTC");
            LogMessage("Latest available: " + TimeToString(latest00Candle, TIME_DATE|TIME_MINUTES) + " UTC");
            LogMessage("Updating to latest 00:00 UTC candle (closes at 04:00)...");

            // Find and update with the latest 00:00 candle
            int candleIndex = Find00UTCCandleIndex();
            if(candleIndex > 0)
            {
               g_last4HCandleTime = iTime(_Symbol, PERIOD_H4, 0);
               g_processed04CandleTime = latest00Candle;
               Update4HData(candleIndex);
            }
         }
      }

      // Check for entry signals
      MonitorEntries();

      // Clean up closed positions from breakeven tracking list
      CleanupClosedPositions();

      // Check for closed positions and update adaptive filter system
      CheckForClosedPositions();
   }

   // Manage open positions (only if breakeven or trailing stop is enabled and there are positions)
   // This runs on every tick for precise adjustments
   if((UseBreakeven || UseTrailingStop) && PositionsTotal() > 0)
   {
      ManageOpenPositions();
   }
}
//+------------------------------------------------------------------+

