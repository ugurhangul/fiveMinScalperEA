//+------------------------------------------------------------------+
//|                                                   FMS_Config.mqh |
//|                          Configuration and Settings for FMS EA   |
//+------------------------------------------------------------------+
#property copyright "FiveMinScalper"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+

//--- Strategy Settings
input group "=== Strategy Settings ==="
input double   EntryOffsetPercent = 0.01;      // Entry offset from 4H high/low (%)
input double   StopLossOffsetPercent = 0.02;   // Stop-loss offset from 4H high/low (%)
input double   RiskRewardRatio = 2.0;          // Risk to Reward Ratio (1:X)

//--- Risk Management
input group "=== Risk Management ==="
input double   RiskPercentPerTrade = 1.0;      // Risk per trade (% of balance)
input double   MaxLotSize = 10.0;              // Maximum lot size
input double   MinLotSize = 0.01;              // Minimum lot size

//--- Trailing Stop
input group "=== Trailing Stop ==="
input bool     UseTrailingStop = false;        // Enable trailing stop
input double   TrailingStopTriggerRR = 1.5;    // Activate trailing at R:R ratio
input double   TrailingStopDistance = 50.0;    // Trailing stop distance (points)

//--- Trading Hours
input group "=== Trading Hours ==="
input bool     UseTradingHours = false;        // Enable trading hours filter
input int      StartHour = 0;                  // Trading start hour
input int      EndHour = 23;                   // Trading end hour

//--- Advanced Settings
input group "=== Advanced Settings ==="
input bool     UseBreakeven = true;            // Move SL to breakeven
input double   BreakevenTriggerRR = 1.0;       // Trigger breakeven at RR ratio
input bool     UseOnly00UTCCandle = true;      // Use only first 4H candle of day (chart shows 04:00)
input int      MagicNumber = 123456;           // Magic number for orders
input string   TradeComment = "5MinScalper";   // Trade comment

//--- Logging Settings
input group "=== Logging Settings ==="
input bool     EnableDetailedLogging = true;   // Enable detailed logging
input bool     LogToFile = true;               // Write logs to file
input bool     LogToConsole = true;            // Print logs to console
input bool     ExportCandleData = false;       // Export candle data to CSV for verification

//--- Debug Settings
input group "=== Debug Settings ==="
input bool     LogActiveTradesEvery5Min = true; // Log all active trades every 5-min candle

//--- Symbol-Specific Optimization
input group "=== Symbol-Specific Optimization ==="
input bool     UseSymbolSpecificSettings = true; // Auto-adjust parameters based on symbol
input string   ManualSymbolCategory = "AUTO";    // Manual override: AUTO, MAJOR_FOREX, MINOR_FOREX, METALS, INDICES, CRYPTO

//--- Adaptive Filter System
input group "=== Adaptive Filter System ==="
input bool     UseAdaptiveFilters = true;       // Enable adaptive filter system
input int      AdaptiveLossTrigger = 3;         // Consecutive losses to activate filters (auto-adjusted per symbol)
input int      AdaptiveWinRecovery = 2;         // Consecutive wins to deactivate filters (auto-adjusted per symbol)
input bool     StartWithFiltersEnabled = false; // Start with filters enabled (true) or disabled (false)

//--- Symbol-Level Adaptation
input group "=== Symbol-Level Adaptation ==="
input bool     UseSymbolAdaptation = true;      // Enable symbol-level adaptive system
input int      SymbolMinTrades = 10;            // Min trades before evaluation
input double   SymbolMinWinRate = 30.0;         // Min win rate % to stay enabled
input double   SymbolMaxLoss = -100.0;          // Max loss $ before disabling symbol
input int      SymbolMaxConsecutiveLosses = 5;  // Max consecutive losses per symbol
input int      SymbolCoolingPeriodDays = 7;     // Days before auto re-enable

//--- Volume Confirmation
input group "=== Volume Confirmation ==="
input double   BreakoutVolumeMaxMultiplier = 1.0; // Max volume for initial breakout (weak breakout = good)
input double   ReversalVolumeMinMultiplier = 1.5; // Min volume for reversal (strong reversal = good)
input int      VolumeAveragePeriod = 20;        // Period for volume moving average

//--- Divergence Confirmation
input group "=== Divergence Confirmation ==="
input bool     RequireBothIndicators = false;   // Require BOTH RSI and MACD divergence (stricter)
input int      RSI_Period = 14;                 // RSI period
input int      MACD_Fast = 12;                  // MACD fast EMA period
input int      MACD_Slow = 26;                  // MACD slow EMA period
input int      MACD_Signal = 9;                 // MACD signal period
input int      DivergenceLookback = 20;         // Candles to look back for swing points

//--- Visual Settings
input group "=== Visual Settings ==="
input bool     ShowLevelsOnChart = true;       // Draw levels on chart
input color    Color4HHigh = clrDodgerBlue;    // 4H High line color
input color    Color4HLow = clrDodgerBlue;     // 4H Low line color
input color    ColorBuyEntry = clrLime;        // Buy entry line color
input color    ColorSellEntry = clrRed;        // Sell entry line color
input int      LineWidth = 2;                  // Line width
input ENUM_LINE_STYLE LineStyle = STYLE_SOLID; // Line style

//+------------------------------------------------------------------+
//| Symbol Category Enumeration                                       |
//+------------------------------------------------------------------+
enum ENUM_SYMBOL_CATEGORY
{
   SYMBOL_MAJOR_FOREX,    // Major Forex Pairs (EUR/USD, GBP/USD, USD/JPY, etc.)
   SYMBOL_MINOR_FOREX,    // Minor Forex Pairs (EUR/GBP, AUD/NZD, etc.)
   SYMBOL_EXOTIC_FOREX,   // Exotic Forex Pairs (USD/TRY, EUR/ZAR, etc.)
   SYMBOL_METALS,         // Precious Metals (Gold, Silver, etc.)
   SYMBOL_INDICES,        // Stock Indices (S&P500, NASDAQ, DAX, etc.)
   SYMBOL_CRYPTO,         // Cryptocurrencies (BTC/USD, ETH/USD, etc.)
   SYMBOL_COMMODITIES,    // Commodities (Oil, Gas, etc.)
   SYMBOL_UNKNOWN         // Unknown/Unclassified
};

//+------------------------------------------------------------------+
//| Symbol-Specific Parameter Set                                     |
//+------------------------------------------------------------------+
struct SymbolParameters
{
   // Volume parameters
   double breakoutVolumeMax;      // Max volume multiplier for breakout
   double reversalVolumeMin;      // Min volume multiplier for reversal
   int    volumeAveragePeriod;    // Volume average period

   // Divergence parameters
   int    rsiPeriod;              // RSI period
   int    macdFast;               // MACD fast EMA
   int    macdSlow;               // MACD slow EMA
   int    macdSignal;             // MACD signal
   int    divergenceLookback;     // Divergence lookback period

   // Adaptive trigger parameters
   int    adaptiveLossTrigger;    // Losses to activate filters
   int    adaptiveWinRecovery;    // Wins to deactivate filters
};

//+------------------------------------------------------------------+
//| Symbol-Level Performance Statistics                               |
//+------------------------------------------------------------------+
struct SymbolStats
{
   int      totalTrades;          // Total trades on this symbol
   int      winningTrades;        // Winning trades
   int      losingTrades;         // Losing trades
   double   totalProfit;          // Total profit
   double   totalLoss;            // Total loss
   int      consecutiveLosses;    // Current consecutive losses
   int      consecutiveWins;      // Current consecutive wins
   bool     isEnabled;            // Is symbol currently enabled?
   datetime disabledTime;         // When was it disabled?
   string   disableReason;        // Why was it disabled?
};

//+------------------------------------------------------------------+
//| Position information structure for caching                       |
//+------------------------------------------------------------------+
struct PositionInfo
{
   ulong             ticket;
   ENUM_POSITION_TYPE type;
   double            volume;
   double            openPrice;
   double            currentPrice;
   double            sl;
   double            tp;
   double            profit;
   datetime          openTime;
   double            risk;
   double            currentPnL;
   double            currentRR;
};

//+------------------------------------------------------------------+

