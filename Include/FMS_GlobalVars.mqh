//+------------------------------------------------------------------+
//|                                              FMS_GlobalVars.mqh |
//|                          Global Variables for FMS EA             |
//+------------------------------------------------------------------+
#property copyright "FiveMinScalper"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+

// 4H Candle tracking
datetime g_last4HCandleTime = 0;               // Last processed 4H candle time (for trading)
datetime g_lastSeen4HCandleTime = 0;           // Last seen 4H candle time (including skipped ones)
datetime g_last5MinCandleTime = 0;             // Last processed 5-min candle time
datetime g_processed04CandleTime = 0;          // Opening time of first 4H candle of day (iTime returns open time, chart shows close time)
double   g_4HHigh = 0;                         // 4H candle high (SELL breakout level)
double   g_4HLow = 0;                          // 4H candle low (BUY breakout level)
bool     g_buyOrderPlaced = false;             // Buy order status
bool     g_sellOrderPlaced = false;            // Sell order status
int      g_logFileHandle = INVALID_HANDLE;     // Log file handle
datetime g_lastLogTime = 0;                    // Last log timestamp
bool     g_tradingAllowedToday = false;        // Trading allowed after new 4H candle processed

// False breakout tracking for BUY signal
bool     g_buyBreakoutConfirmed = false;       // 5min candle closed below 4H Low
bool     g_buyReversalConfirmed = false;       // 5min candle closed above 4H Low after breakout
datetime g_buyBreakoutCandleTime = 0;          // Time of the breakout candle

// False breakout tracking for SELL signal
bool     g_sellBreakoutConfirmed = false;      // 5min candle closed above 4H High
bool     g_sellReversalConfirmed = false;      // 5min candle closed below 4H High after breakout
datetime g_sellBreakoutCandleTime = 0;         // Time of the breakout candle

// Volume confirmation tracking
long     g_buyBreakoutVolume = 0;              // Volume of the BUY breakout candle (should be LOW)
long     g_buyReversalVolume = 0;              // Volume of the BUY reversal candle (should be HIGH)
long     g_sellBreakoutVolume = 0;             // Volume of the SELL breakout candle (should be LOW)
long     g_sellReversalVolume = 0;             // Volume of the SELL reversal candle (should be HIGH)
double   g_averageVolume = 0;                  // Average volume over reference period
bool     g_buyBreakoutVolumeOK = false;        // BUY breakout has LOW volume (weak = good)
bool     g_buyReversalVolumeOK = false;        // BUY reversal has HIGH volume (strong = good)
bool     g_sellBreakoutVolumeOK = false;       // SELL breakout has LOW volume (weak = good)
bool     g_sellReversalVolumeOK = false;       // SELL reversal has HIGH volume (strong = good)

// Divergence confirmation tracking
int      g_rsiHandle = INVALID_HANDLE;         // RSI indicator handle
int      g_macdHandle = INVALID_HANDLE;        // MACD indicator handle
bool     g_buyDivergenceOK = false;            // BUY breakout shows bullish divergence (weak momentum = good)
bool     g_sellDivergenceOK = false;           // SELL breakout shows bearish divergence (weak momentum = good)

// Adaptive filter system tracking
bool     g_adaptiveModeActive = false;         // Is adaptive mode currently active?
int      g_consecutiveLosses = 0;              // Current consecutive loss count
int      g_consecutiveWins = 0;                // Current consecutive win count (when adaptive mode is active)
bool     g_originalVolumeConfirmation = false; // Original/starting volume confirmation state
bool     g_originalDivergenceConfirmation = false; // Original/starting divergence confirmation state
ulong    g_lastClosedTicket = 0;               // Last closed trade ticket (to avoid double-counting)

// Working filter variables (can be modified by adaptive system)
bool     g_activeVolumeConfirmation = false;   // Current active volume confirmation setting
bool     g_activeDivergenceConfirmation = false; // Current active divergence confirmation setting

// Symbol-specific optimization
ENUM_SYMBOL_CATEGORY g_symbolCategory = SYMBOL_UNKNOWN; // Detected symbol category
SymbolParameters     g_symbolParams;           // Active symbol-specific parameters
SymbolParameters     g_defaultParams;          // Default parameters from inputs

// Symbol-level adaptive system
SymbolStats          g_symbolStats;            // Performance statistics for current symbol

// Breakeven tracking to prevent redundant checks
ulong    g_breakevenSetTickets[];              // Array of tickets that already have breakeven set

// Trailing stop tracking
ulong    g_trailingStopActiveTickets[];        // Array of tickets with trailing stop activated

// Cached symbol properties (initialized once in OnInit for performance)
double   g_symbolPoint = 0;                    // Symbol point size
int      g_symbolDigits = 0;                   // Symbol digits
double   g_symbolTickValue = 0;                // Symbol tick value
double   g_symbolMinLot = 0;                   // Minimum lot size
double   g_symbolMaxLot = 0;                   // Maximum lot size
double   g_symbolLotStep = 0;                  // Lot step size

// Chart object tracking for efficient management
string   g_chartObjects[];                     // Array of chart objects created by EA

//+------------------------------------------------------------------+

