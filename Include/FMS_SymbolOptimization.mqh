//+------------------------------------------------------------------+
//|                                   FMS_SymbolOptimization.mqh |
//|              Symbol-Specific Optimization Functions for FMS EA   |
//+------------------------------------------------------------------+
#property copyright "FiveMinScalper"
#property link      ""
#property version   "1.00"
#property strict

#include "FMS_Config.mqh"
#include "FMS_GlobalVars.mqh"
#include "FMS_Utilities.mqh"

//+------------------------------------------------------------------+
//| Detect symbol category based on symbol name                      |
//+------------------------------------------------------------------+
ENUM_SYMBOL_CATEGORY DetectSymbolCategory(string symbol)
{
   // Convert to uppercase for comparison
   StringToUpper(symbol);

   // Major Forex Pairs (most liquid, tight spreads, moderate volatility)
   if(StringFind(symbol, "EURUSD") >= 0 || StringFind(symbol, "GBPUSD") >= 0 ||
      StringFind(symbol, "USDJPY") >= 0 || StringFind(symbol, "USDCHF") >= 0 ||
      StringFind(symbol, "AUDUSD") >= 0 || StringFind(symbol, "USDCAD") >= 0 ||
      StringFind(symbol, "NZDUSD") >= 0)
   {
      return SYMBOL_MAJOR_FOREX;
   }

   // Minor Forex Pairs (cross pairs, moderate liquidity)
   if(StringFind(symbol, "EURGBP") >= 0 || StringFind(symbol, "EURJPY") >= 0 ||
      StringFind(symbol, "GBPJPY") >= 0 || StringFind(symbol, "EURCHF") >= 0 ||
      StringFind(symbol, "EURAUD") >= 0 || StringFind(symbol, "EURCAD") >= 0 ||
      StringFind(symbol, "GBPCHF") >= 0 || StringFind(symbol, "GBPAUD") >= 0 ||
      StringFind(symbol, "AUDNZD") >= 0 || StringFind(symbol, "AUDCAD") >= 0 ||
      StringFind(symbol, "AUDJPY") >= 0 || StringFind(symbol, "CADJPY") >= 0 ||
      StringFind(symbol, "CHFJPY") >= 0 || StringFind(symbol, "NZDJPY") >= 0 ||
      StringFind(symbol, "EURNZD") >= 0 || StringFind(symbol, "GBPCAD") >= 0 ||
      StringFind(symbol, "GBPNZD") >= 0 || StringFind(symbol, "NZDCAD") >= 0 ||
      StringFind(symbol, "NZDCHF") >= 0)
   {
      return SYMBOL_MINOR_FOREX;
   }

   // Exotic Forex Pairs (low liquidity, high spreads, high volatility)
   if(StringFind(symbol, "TRY") >= 0 || StringFind(symbol, "ZAR") >= 0 ||
      StringFind(symbol, "MXN") >= 0 || StringFind(symbol, "BRL") >= 0 ||
      StringFind(symbol, "RUB") >= 0 || StringFind(symbol, "HKD") >= 0 ||
      StringFind(symbol, "SGD") >= 0 || StringFind(symbol, "THB") >= 0 ||
      StringFind(symbol, "NOK") >= 0 || StringFind(symbol, "SEK") >= 0 ||
      StringFind(symbol, "DKK") >= 0 || StringFind(symbol, "PLN") >= 0 ||
      StringFind(symbol, "CZK") >= 0 || StringFind(symbol, "HUF") >= 0 ||
      StringFind(symbol, "ILS") >= 0 || StringFind(symbol, "CNH") >= 0)
   {
      return SYMBOL_EXOTIC_FOREX;
   }

   // Precious Metals (Gold, Silver - high volatility, trending)
   if(StringFind(symbol, "XAUUSD") >= 0 || StringFind(symbol, "GOLD") >= 0 ||
      StringFind(symbol, "XAGUSD") >= 0 || StringFind(symbol, "SILVER") >= 0 ||
      StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "XAG") >= 0 ||
      StringFind(symbol, "XALUSD") >= 0 || StringFind(symbol, "XCUUSD") >= 0 ||
      StringFind(symbol, "XPBUSD") >= 0 || StringFind(symbol, "XPDUSD") >= 0 ||
      StringFind(symbol, "XPTUSD") >= 0 || StringFind(symbol, "XZNUSD") >= 0)
   {
      return SYMBOL_METALS;
   }

   // Stock Indices (trending, moderate to high volatility)
   if(StringFind(symbol, "SPX") >= 0 || StringFind(symbol, "SP500") >= 0 ||
      StringFind(symbol, "US500") >= 0 || StringFind(symbol, "NAS100") >= 0 ||
      StringFind(symbol, "NASDAQ") >= 0 || StringFind(symbol, "USTEC") >= 0 ||
      StringFind(symbol, "US30") >= 0 || StringFind(symbol, "DOW") >= 0 ||
      StringFind(symbol, "DAX") >= 0 || StringFind(symbol, "DE30") >= 0 ||
      StringFind(symbol, "GER") >= 0 || StringFind(symbol, "FTSE") >= 0 ||
      StringFind(symbol, "UK100") >= 0 || StringFind(symbol, "CAC") >= 0 ||
      StringFind(symbol, "FR40") >= 0 || StringFind(symbol, "FRA") >= 0 ||
      StringFind(symbol, "NIKKEI") >= 0 || StringFind(symbol, "JP225") >= 0 ||
      StringFind(symbol, "JPN") >= 0 || StringFind(symbol, "ASX") >= 0 ||
      StringFind(symbol, "AUS") >= 0 || StringFind(symbol, "HK50") >= 0 ||
      StringFind(symbol, "DXY") >= 0)
   {
      return SYMBOL_INDICES;
   }

   // Cryptocurrencies (very high volatility, 24/7 trading)
   if(StringFind(symbol, "BTC") >= 0 || StringFind(symbol, "ETH") >= 0 ||
      StringFind(symbol, "XRP") >= 0 || StringFind(symbol, "LTC") >= 0 ||
      StringFind(symbol, "BCH") >= 0 || StringFind(symbol, "ADA") >= 0 ||
      StringFind(symbol, "DOT") >= 0 || StringFind(symbol, "LINK") >= 0 ||
      StringFind(symbol, "DOGE") >= 0 || StringFind(symbol, "CRYPTO") >= 0 ||
      StringFind(symbol, "BNB") >= 0 || StringFind(symbol, "SOL") >= 0 ||
      StringFind(symbol, "UNI") >= 0 || StringFind(symbol, "FIL") >= 0 ||
      StringFind(symbol, "BAT") >= 0 || StringFind(symbol, "XTZ") >= 0)
   {
      return SYMBOL_CRYPTO;
   }

   // Commodities (Oil, Gas, etc.)
   if(StringFind(symbol, "WTI") >= 0 || StringFind(symbol, "BRENT") >= 0 ||
      StringFind(symbol, "OIL") >= 0 || StringFind(symbol, "USOIL") >= 0 ||
      StringFind(symbol, "UKOIL") >= 0 || StringFind(symbol, "NGAS") >= 0 ||
      StringFind(symbol, "GAS") >= 0 || StringFind(symbol, "XNG") >= 0)
   {
      return SYMBOL_COMMODITIES;
   }

   return SYMBOL_UNKNOWN;
}

//+------------------------------------------------------------------+
//| Get category name as string                                      |
//+------------------------------------------------------------------+
string GetSymbolCategoryName(ENUM_SYMBOL_CATEGORY category)
{
   switch(category)
   {
      case SYMBOL_MAJOR_FOREX:   return "Major Forex";
      case SYMBOL_MINOR_FOREX:   return "Minor Forex";
      case SYMBOL_EXOTIC_FOREX:  return "Exotic Forex";
      case SYMBOL_METALS:        return "Precious Metals";
      case SYMBOL_INDICES:       return "Stock Indices";
      case SYMBOL_CRYPTO:        return "Cryptocurrencies";
      case SYMBOL_COMMODITIES:   return "Commodities";
      default:                   return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Get optimized parameters for symbol category                     |
//+------------------------------------------------------------------+
SymbolParameters GetSymbolParameters(ENUM_SYMBOL_CATEGORY category)
{
   SymbolParameters params;

   switch(category)
   {
      case SYMBOL_MAJOR_FOREX:
         // Major pairs: Moderate volatility, high liquidity
         params.breakoutVolumeMax = 0.8;
         params.reversalVolumeMin = 1.8;
         params.volumeAveragePeriod = 20;
         params.rsiPeriod = 14;
         params.macdFast = 12;
         params.macdSlow = 26;
         params.macdSignal = 9;
         params.divergenceLookback = 20;
         params.adaptiveLossTrigger = 3;
         params.adaptiveWinRecovery = 2;
         break;

      case SYMBOL_MINOR_FOREX:
         // Minor pairs: Higher volatility, moderate liquidity
         params.breakoutVolumeMax = 0.7;
         params.reversalVolumeMin = 2.0;
         params.volumeAveragePeriod = 25;
         params.rsiPeriod = 14;
         params.macdFast = 12;
         params.macdSlow = 26;
         params.macdSignal = 9;
         params.divergenceLookback = 25;
         params.adaptiveLossTrigger = 2;
         params.adaptiveWinRecovery = 3;
         break;

      case SYMBOL_EXOTIC_FOREX:
         // Exotic pairs: Very high volatility, low liquidity
         params.breakoutVolumeMax = 0.6;
         params.reversalVolumeMin = 2.5;
         params.volumeAveragePeriod = 30;
         params.rsiPeriod = 21;
         params.macdFast = 16;
         params.macdSlow = 32;
         params.macdSignal = 12;
         params.divergenceLookback = 30;
         params.adaptiveLossTrigger = 2;
         params.adaptiveWinRecovery = 4;
         break;

      case SYMBOL_METALS:
         // Metals (Gold/Silver): High volatility, trending
         params.breakoutVolumeMax = 0.7;
         params.reversalVolumeMin = 2.2;
         params.volumeAveragePeriod = 25;
         params.rsiPeriod = 14;
         params.macdFast = 12;
         params.macdSlow = 26;
         params.macdSignal = 9;
         params.divergenceLookback = 25;
         params.adaptiveLossTrigger = 2;
         params.adaptiveWinRecovery = 3;
         break;

      case SYMBOL_INDICES:
         // Indices: Trending, moderate volatility
         params.breakoutVolumeMax = 0.8;
         params.reversalVolumeMin = 1.8;
         params.volumeAveragePeriod = 20;
         params.rsiPeriod = 14;
         params.macdFast = 12;
         params.macdSlow = 26;
         params.macdSignal = 9;
         params.divergenceLookback = 20;
         params.adaptiveLossTrigger = 3;
         params.adaptiveWinRecovery = 2;
         break;

      case SYMBOL_CRYPTO:
         // Crypto: Extremely high volatility, 24/7
         params.breakoutVolumeMax = 0.5;
         params.reversalVolumeMin = 3.0;
         params.volumeAveragePeriod = 40;
         params.rsiPeriod = 21;
         params.macdFast = 16;
         params.macdSlow = 32;
         params.macdSignal = 12;
         params.divergenceLookback = 40;
         params.adaptiveLossTrigger = 1;
         params.adaptiveWinRecovery = 5;
         break;

      case SYMBOL_COMMODITIES:
         // Commodities (Oil, Gas): High volatility, news-driven
         params.breakoutVolumeMax = 0.7;
         params.reversalVolumeMin = 2.0;
         params.volumeAveragePeriod = 25;
         params.rsiPeriod = 14;
         params.macdFast = 12;
         params.macdSlow = 26;
         params.macdSignal = 9;
         params.divergenceLookback = 25;
         params.adaptiveLossTrigger = 2;
         params.adaptiveWinRecovery = 3;
         break;

      default: // SYMBOL_UNKNOWN
         // Use default input parameters
         params.breakoutVolumeMax = BreakoutVolumeMaxMultiplier;
         params.reversalVolumeMin = ReversalVolumeMinMultiplier;
         params.volumeAveragePeriod = VolumeAveragePeriod;
         params.rsiPeriod = RSI_Period;
         params.macdFast = MACD_Fast;
         params.macdSlow = MACD_Slow;
         params.macdSignal = MACD_Signal;
         params.divergenceLookback = DivergenceLookback;
         params.adaptiveLossTrigger = AdaptiveLossTrigger;
         params.adaptiveWinRecovery = AdaptiveWinRecovery;
         break;
   }

   return params;
}

//+------------------------------------------------------------------+
//| Apply symbol-specific parameters                                 |
//+------------------------------------------------------------------+
void ApplySymbolParameters()
{
   if(!UseSymbolSpecificSettings)
   {
      LogMessage("Symbol-specific optimization: DISABLED");
      LogMessage("Using default input parameters for all symbols");
      return;
   }

   // Detect symbol category (or use manual override)
   if(ManualSymbolCategory == "AUTO")
   {
      g_symbolCategory = DetectSymbolCategory(_Symbol);
      LogMessage("Symbol category: AUTO-DETECTED as " + GetSymbolCategoryName(g_symbolCategory));
   }
   else if(ManualSymbolCategory == "MAJOR_FOREX")
   {
      g_symbolCategory = SYMBOL_MAJOR_FOREX;
      LogMessage("Symbol category: MANUALLY SET to Major Forex");
   }
   else if(ManualSymbolCategory == "MINOR_FOREX")
   {
      g_symbolCategory = SYMBOL_MINOR_FOREX;
      LogMessage("Symbol category: MANUALLY SET to Minor Forex");
   }
   else if(ManualSymbolCategory == "EXOTIC_FOREX")
   {
      g_symbolCategory = SYMBOL_EXOTIC_FOREX;
      LogMessage("Symbol category: MANUALLY SET to Exotic Forex");
   }
   else if(ManualSymbolCategory == "METALS")
   {
      g_symbolCategory = SYMBOL_METALS;
      LogMessage("Symbol category: MANUALLY SET to Precious Metals");
   }
   else if(ManualSymbolCategory == "INDICES")
   {
      g_symbolCategory = SYMBOL_INDICES;
      LogMessage("Symbol category: MANUALLY SET to Stock Indices");
   }
   else if(ManualSymbolCategory == "CRYPTO")
   {
      g_symbolCategory = SYMBOL_CRYPTO;
      LogMessage("Symbol category: MANUALLY SET to Cryptocurrencies");
   }
   else if(ManualSymbolCategory == "COMMODITIES")
   {
      g_symbolCategory = SYMBOL_COMMODITIES;
      LogMessage("Symbol category: MANUALLY SET to Commodities");
   }
   else
   {
      g_symbolCategory = DetectSymbolCategory(_Symbol);
      LogMessage("Symbol category: Invalid manual setting, AUTO-DETECTED as " + GetSymbolCategoryName(g_symbolCategory));
   }

   // Get optimized parameters for this category
   g_symbolParams = GetSymbolParameters(g_symbolCategory);

   // Log parameter comparison
   LogMessage("╔════════════════════════════════════════════════════════════╗");
   LogMessage("║  SYMBOL-SPECIFIC PARAMETERS APPLIED                        ║");
   LogMessage("╚════════════════════════════════════════════════════════════╝");
   LogMessage("Symbol: " + _Symbol);
   LogMessage("Category: " + GetSymbolCategoryName(g_symbolCategory));
   LogMessage("");
   LogMessage("Volume Parameters:");
   LogMessage("  Breakout Max:     " + DoubleToString(g_symbolParams.breakoutVolumeMax, 2) +
              " (default: " + DoubleToString(g_defaultParams.breakoutVolumeMax, 2) + ")");
   LogMessage("  Reversal Min:     " + DoubleToString(g_symbolParams.reversalVolumeMin, 2) +
              " (default: " + DoubleToString(g_defaultParams.reversalVolumeMin, 2) + ")");
   LogMessage("  Average Period:   " + IntegerToString(g_symbolParams.volumeAveragePeriod) +
              " (default: " + IntegerToString(g_defaultParams.volumeAveragePeriod) + ")");
   LogMessage("");
   LogMessage("Divergence Parameters:");
   LogMessage("  RSI Period:       " + IntegerToString(g_symbolParams.rsiPeriod) +
              " (default: " + IntegerToString(g_defaultParams.rsiPeriod) + ")");
   LogMessage("  MACD Fast:        " + IntegerToString(g_symbolParams.macdFast) +
              " (default: " + IntegerToString(g_defaultParams.macdFast) + ")");
   LogMessage("  MACD Slow:        " + IntegerToString(g_symbolParams.macdSlow) +
              " (default: " + IntegerToString(g_defaultParams.macdSlow) + ")");
   LogMessage("  MACD Signal:      " + IntegerToString(g_symbolParams.macdSignal) +
              " (default: " + IntegerToString(g_defaultParams.macdSignal) + ")");
   LogMessage("  Lookback Period:  " + IntegerToString(g_symbolParams.divergenceLookback) +
              " (default: " + IntegerToString(g_defaultParams.divergenceLookback) + ")");
   LogMessage("");
   LogMessage("Adaptive Triggers:");
   LogMessage("  Loss Trigger:     " + IntegerToString(g_symbolParams.adaptiveLossTrigger) +
              " (default: " + IntegerToString(g_defaultParams.adaptiveLossTrigger) + ")");
   LogMessage("  Win Recovery:     " + IntegerToString(g_symbolParams.adaptiveWinRecovery) +
              " (default: " + IntegerToString(g_defaultParams.adaptiveWinRecovery) + ")");
   LogMessage("════════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Initialize Symbol Statistics                                      |
//+------------------------------------------------------------------+
void InitializeSymbolStats()
{
   g_symbolStats.totalTrades = 0;
   g_symbolStats.winningTrades = 0;
   g_symbolStats.losingTrades = 0;
   g_symbolStats.totalProfit = 0.0;
   g_symbolStats.totalLoss = 0.0;
   g_symbolStats.consecutiveLosses = 0;
   g_symbolStats.consecutiveWins = 0;
   g_symbolStats.isEnabled = true;  // Start enabled
   g_symbolStats.disabledTime = 0;
   g_symbolStats.disableReason = "";

   LogMessage("Symbol statistics initialized for " + _Symbol);
}

//+------------------------------------------------------------------+
//| Update Symbol Statistics After Trade                              |
//+------------------------------------------------------------------+
void UpdateSymbolStats(bool isWin, double profit)
{
   if(!UseSymbolAdaptation)
      return;

   g_symbolStats.totalTrades++;

   if(isWin)
   {
      g_symbolStats.winningTrades++;
      g_symbolStats.totalProfit += profit;
      g_symbolStats.consecutiveLosses = 0;
      g_symbolStats.consecutiveWins++;
   }
   else
   {
      g_symbolStats.losingTrades++;
      g_symbolStats.totalLoss += MathAbs(profit);
      g_symbolStats.consecutiveWins = 0;
      g_symbolStats.consecutiveLosses++;
   }

   // Log updated statistics
   double winRate = (g_symbolStats.totalTrades > 0) ?
                    (g_symbolStats.winningTrades * 100.0 / g_symbolStats.totalTrades) : 0.0;
   double netProfit = g_symbolStats.totalProfit - g_symbolStats.totalLoss;

   LogMessage("Symbol Stats Updated (" + _Symbol + "):");
   LogMessage("  Total Trades: " + IntegerToString(g_symbolStats.totalTrades));
   LogMessage("  Win Rate: " + DoubleToString(winRate, 1) + "% (" +
              IntegerToString(g_symbolStats.winningTrades) + "W / " +
              IntegerToString(g_symbolStats.losingTrades) + "L)");
   LogMessage("  Net P&L: $" + DoubleToString(netProfit, 2));
   LogMessage("  Consecutive: " + (isWin ?
              IntegerToString(g_symbolStats.consecutiveWins) + " wins" :
              IntegerToString(g_symbolStats.consecutiveLosses) + " losses"));
}

//+------------------------------------------------------------------+
//| Evaluate Symbol Performance and Disable if Needed                 |
//+------------------------------------------------------------------+
void EvaluateSymbolPerformance()
{
   if(!UseSymbolAdaptation || !g_symbolStats.isEnabled)
      return;

   // Need minimum trades before evaluation
   if(g_symbolStats.totalTrades < SymbolMinTrades)
      return;

   bool shouldDisable = false;
   string reason = "";

   // Check 1: Win rate too low
   double winRate = (g_symbolStats.winningTrades * 100.0 / g_symbolStats.totalTrades);
   if(winRate < SymbolMinWinRate)
   {
      shouldDisable = true;
      reason = "Win rate " + DoubleToString(winRate, 1) + "% below " +
               DoubleToString(SymbolMinWinRate, 1) + "% threshold";
   }

   // Check 2: Total loss exceeds threshold
   double netProfit = g_symbolStats.totalProfit - g_symbolStats.totalLoss;
   if(netProfit < SymbolMaxLoss)
   {
      shouldDisable = true;
      reason = "Total loss $" + DoubleToString(netProfit, 2) + " exceeds $" +
               DoubleToString(SymbolMaxLoss, 2) + " threshold";
   }

   // Check 3: Too many consecutive losses
   if(g_symbolStats.consecutiveLosses >= SymbolMaxConsecutiveLosses)
   {
      shouldDisable = true;
      reason = IntegerToString(g_symbolStats.consecutiveLosses) + " consecutive losses (threshold: " +
               IntegerToString(SymbolMaxConsecutiveLosses) + ")";
   }

   if(shouldDisable)
   {
      DisableSymbol(reason);
   }
}

//+------------------------------------------------------------------+
//| Disable Symbol Trading                                            |
//+------------------------------------------------------------------+
void DisableSymbol(string reason)
{
   g_symbolStats.isEnabled = false;
   g_symbolStats.disabledTime = TimeCurrent();
   g_symbolStats.disableReason = reason;

   double winRate = (g_symbolStats.totalTrades > 0) ?
                    (g_symbolStats.winningTrades * 100.0 / g_symbolStats.totalTrades) : 0.0;
   double netProfit = g_symbolStats.totalProfit - g_symbolStats.totalLoss;

   datetime reEnableDate = g_symbolStats.disabledTime + (SymbolCoolingPeriodDays * 86400);

   // Create padding string
   string padding = "";
   int paddingLength = 42 - StringLen(_Symbol);
   for(int i = 0; i < paddingLength; i++)
      padding += " ";

   LogMessage("╔════════════════════════════════════════════════════════════╗");
   LogMessage("║  SYMBOL DISABLED: " + _Symbol + padding + "║");
   LogMessage("╚════════════════════════════════════════════════════════════╝");
   LogMessage("Reason: " + reason);
   LogMessage("");
   LogMessage("Statistics:");
   LogMessage("  Total Trades: " + IntegerToString(g_symbolStats.totalTrades));
   LogMessage("  Wins: " + IntegerToString(g_symbolStats.winningTrades) + " (" + DoubleToString(winRate, 1) + "%)");
   LogMessage("  Losses: " + IntegerToString(g_symbolStats.losingTrades) + " (" + DoubleToString(100.0 - winRate, 1) + "%)");
   LogMessage("  Total P&L: $" + DoubleToString(netProfit, 2));
   LogMessage("  Consecutive Losses: " + IntegerToString(g_symbolStats.consecutiveLosses));
   LogMessage("");
   LogMessage("Cooling Period: " + IntegerToString(SymbolCoolingPeriodDays) + " days");
   LogMessage("Re-enable Date: " + TimeToString(reEnableDate, TIME_DATE));
   LogMessage("════════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Check if Symbol is Enabled for Trading                            |
//+------------------------------------------------------------------+
bool IsSymbolEnabled()
{
   if(!UseSymbolAdaptation)
      return true;  // If system disabled, always allow trading

   // Check if symbol is currently disabled
   if(!g_symbolStats.isEnabled)
   {
      // Check if cooling period has expired
      CheckSymbolCoolingPeriod();

      // Return current status
      return g_symbolStats.isEnabled;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check Cooling Period and Re-enable if Expired                     |
//+------------------------------------------------------------------+
void CheckSymbolCoolingPeriod()
{
   if(!UseSymbolAdaptation || g_symbolStats.isEnabled)
      return;

   datetime currentTime = TimeCurrent();
   datetime coolingEndTime = g_symbolStats.disabledTime + (SymbolCoolingPeriodDays * 86400);

   if(currentTime >= coolingEndTime)
   {
      // Re-enable symbol
      g_symbolStats.isEnabled = true;

      // Reset statistics for fresh start
      int oldTotalTrades = g_symbolStats.totalTrades;
      double oldNetProfit = g_symbolStats.totalProfit - g_symbolStats.totalLoss;

      g_symbolStats.totalTrades = 0;
      g_symbolStats.winningTrades = 0;
      g_symbolStats.losingTrades = 0;
      g_symbolStats.totalProfit = 0.0;
      g_symbolStats.totalLoss = 0.0;
      g_symbolStats.consecutiveLosses = 0;
      g_symbolStats.consecutiveWins = 0;

      // Create padding string
      string padding2 = "";
      int paddingLength2 = 39 - StringLen(_Symbol);
      for(int i = 0; i < paddingLength2; i++)
         padding2 += " ";

      LogMessage("╔════════════════════════════════════════════════════════════╗");
      LogMessage("║  SYMBOL RE-ENABLED: " + _Symbol + padding2 + "║");
      LogMessage("╚════════════════════════════════════════════════════════════╝");
      LogMessage("Reason: Cooling period expired (" + IntegerToString(SymbolCoolingPeriodDays) + " days)");
      LogMessage("");
      LogMessage("Previous Performance:");
      LogMessage("  Total Trades: " + IntegerToString(oldTotalTrades));
      LogMessage("  Net P&L: $" + DoubleToString(oldNetProfit, 2));
      LogMessage("  Disable Reason: " + g_symbolStats.disableReason);
      LogMessage("");
      LogMessage("Statistics: RESET");
      LogMessage("Status: Ready to trade");
      LogMessage("════════════════════════════════════════════════════════════");

      g_symbolStats.disableReason = "";
   }
}
//+------------------------------------------------------------------+
