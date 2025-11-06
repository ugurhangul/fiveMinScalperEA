# FMS Range Visualizer - Technical Specification

## Architecture Overview

### Indicator Type
- **Type**: Custom Chart Window Indicator
- **Plots**: 0 (uses graphical objects instead of indicator buffers)
- **Calculation Mode**: On every tick (but only redraws when necessary)
- **Object Management**: Manual creation/deletion of chart objects

### Core Components

```
FMS_RangeVisualizer.mq5
├── Input Parameters (User Configuration)
├── Global Variables (State Management)
├── OnInit() - Initialization
├── OnDeinit() - Cleanup
├── OnCalculate() - Main Loop
├── Initialize4HCandle() - 4H Range Setup
├── Initialize15MCandle() - 15M Range Setup
├── CheckNew4HCandle() - 4H Range Updates
├── CheckNew15MCandle() - 15M Range Updates
├── UpdateRangeLines() - Visual Rendering
├── CreateHorizontalLine() - Line Drawing
├── CreateLabel() - Text Label Creation
├── CreateInfoPanel() - Info Panel Rendering
└── DeleteAllObjects() - Cleanup Utility
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         OnInit()                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ 1. Initialize4HCandle()                                  │   │
│  │    - Search backwards for 04:00 UTC candle              │   │
│  │    - Store g_4HHigh, g_4HLow, g_last4HCandleTime       │   │
│  │                                                          │   │
│  │ 2. Initialize15MCandle()                                │   │
│  │    - Search backwards for 04:30 UTC candle             │   │
│  │    - Store g_15MHigh, g_15MLow, g_last15MCandleTime    │   │
│  │                                                          │   │
│  │ 3. UpdateRangeLines()                                   │   │
│  │    - Draw initial lines and labels                      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      OnCalculate()                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Called on every tick                                     │   │
│  │                                                          │   │
│  │ 1. CheckNew4HCandle()                                   │   │
│  │    - Get latest 4H candle (index 1)                     │   │
│  │    - If new AND hour==4 AND min==0:                     │   │
│  │      * Update g_4HHigh, g_4HLow                         │   │
│  │      * Delete old objects                               │   │
│  │                                                          │   │
│  │ 2. CheckNew15MCandle()                                  │   │
│  │    - Get latest 15M candle (index 1)                    │   │
│  │    - If new AND hour==4 AND min==30:                    │   │
│  │      * Update g_15MHigh, g_15MLow                       │   │
│  │      * Delete old objects                               │   │
│  │                                                          │   │
│  │ 3. UpdateRangeLines()                                   │   │
│  │    - Redraw all lines and labels                        │   │
│  │    - Update info panel                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                       OnDeinit()                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ DeleteAllObjects()                                       │   │
│  │  - Remove all FMS_RV_* objects from chart               │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Global Variables

| Variable | Type | Purpose | Initial Value |
|----------|------|---------|---------------|
| `g_last4HCandleTime` | datetime | Timestamp of last processed 4H candle | 0 |
| `g_last15MCandleTime` | datetime | Timestamp of last processed 15M candle | 0 |
| `g_4HHigh` | double | 4H candle high price | 0 |
| `g_4HLow` | double | 4H candle low price | 0 |
| `g_15MHigh` | double | 15M candle high price | 0 |
| `g_15MLow` | double | 15M candle low price | 0 |

## Chart Objects

### Object Naming Convention
All objects created by this indicator use the prefix `FMS_RV_` to:
- Avoid conflicts with other indicators/EAs
- Enable easy identification and cleanup
- Support multiple instances on different charts

### Object List

| Object Name | Type | Purpose | Properties | Time Bounds |
|-------------|------|---------|------------|-------------|
| `FMS_RV_4H_High` | OBJ_TREND | 4H high trend line (horizontal) | Color, Width, Style, Tooltip, RAY_RIGHT=false | 04:00 UTC → Next 04:00 UTC |
| `FMS_RV_4H_Low` | OBJ_TREND | 4H low trend line (horizontal) | Color, Width, Style, Tooltip, RAY_RIGHT=false | 04:00 UTC → Next 04:00 UTC |
| `FMS_RV_15M_High` | OBJ_TREND | 15M high trend line (horizontal) | Color, Width, Style, Tooltip, RAY_RIGHT=false | 04:30 UTC → Next 04:30 UTC |
| `FMS_RV_15M_Low` | OBJ_TREND | 15M low trend line (horizontal) | Color, Width, Style, Tooltip, RAY_RIGHT=false | 04:30 UTC → Next 04:30 UTC |
| `FMS_RV_4H_High_Label` | OBJ_TEXT | Text label for 4H high | Text, Color, Font, Position | Positioned at end of 4H line |
| `FMS_RV_4H_Low_Label` | OBJ_TEXT | Text label for 4H low | Text, Color, Font, Position | Positioned at end of 4H line |
| `FMS_RV_15M_High_Label` | OBJ_TEXT | Text label for 15M high | Text, Color, Font, Position | Positioned at end of 15M line |
| `FMS_RV_15M_Low_Label` | OBJ_TEXT | Text label for 15M low | Text, Color, Font, Position | Positioned at end of 15M line |
| `FMS_RV_InfoPanel` | OBJ_LABEL | Info panel (top-left corner) | Multi-line text, Font, Position | N/A |

## Function Specifications

### Initialize4HCandle()
```cpp
Purpose: Find and load the most recent 4H candle at 04:00 UTC
Algorithm:
  1. Loop backwards through 4H candles (i = 1 to 10)
  2. For each candle:
     - Get candle time using iTime(_Symbol, PERIOD_H4, i)
     - Convert to MqlDateTime structure
     - Check if hour == 4 AND minute == 0
     - If match found:
       * Store candle time in g_last4HCandleTime
       * Store high in g_4HHigh using iHigh()
       * Store low in g_4HLow using iLow()
       * Print initialization message
       * Return
  3. If no match found, print warning message
```

### Initialize15MCandle()
```cpp
Purpose: Find and load the most recent 15M candle at 04:30 UTC
Algorithm:
  1. Loop backwards through 15M candles (i = 1 to 100)
  2. For each candle:
     - Get candle time using iTime(_Symbol, PERIOD_M15, i)
     - Convert to MqlDateTime structure
     - Check if hour == 4 AND minute == 30
     - If match found:
       * Store candle time in g_last15MCandleTime
       * Store high in g_15MHigh using iHigh()
       * Store low in g_15MLow using iLow()
       * Print initialization message
       * Return
  3. If no match found, print warning message
```

### CheckNew4HCandle()
```cpp
Purpose: Detect new 4H candle at 04:00 UTC and update range
Algorithm:
  1. Get last closed 4H candle time (index 1)
  2. If candleTime > g_last4HCandleTime:
     - Convert time to MqlDateTime
     - If hour == 4 AND minute == 0:
       * Update g_last4HCandleTime
       * Update g_4HHigh and g_4HLow
       * Print detection message with range details
       * Call DeleteAllObjects() to clear old lines
```

### CheckNew15MCandle()
```cpp
Purpose: Detect new 15M candle at 04:30 UTC and update range
Algorithm:
  1. Get last closed 15M candle time (index 1)
  2. If candleTime > g_last15MCandleTime:
     - Convert time to MqlDateTime
     - If hour == 4 AND minute == 30:
       * Update g_last15MCandleTime
       * Update g_15MHigh and g_15MLow
       * Print detection message with range details
       * Call DeleteAllObjects() to clear old lines
```

### CreateHorizontalLine()
```cpp
Purpose: Create time-bounded horizontal trend line
Parameters:
  - name: Object identifier (e.g., "4H_High", "15M_Low")
  - price: Price level for the horizontal line
  - lineColor: Color of the line
  - width: Line width (1-5)
  - style: Line style (STYLE_SOLID, STYLE_DOT, etc.)
  - description: Tooltip text

Algorithm:
  1. Determine start and end times based on name:
     - If name contains "4H":
       * startTime = g_last4HCandleTime
       * endTime = startTime + 86400 (24 hours)
     - If name contains "15M":
       * startTime = g_last15MCandleTime
       * endTime = startTime + 86400 (24 hours)

  2. Validate startTime != 0 (skip if no valid reference candle)

  3. Create OBJ_TREND object:
     - time1 = startTime (reference candle opening time)
     - price1 = price (horizontal level)
     - time2 = endTime (24 hours later)
     - price2 = price (same level - creates horizontal line)

  4. Set properties:
     - RAY_RIGHT = false (don't extend beyond endTime)
     - RAY_LEFT = false (don't extend before startTime)
     - Color, Width, Style, Tooltip as specified

Result: Time-bounded horizontal line that clearly shows active trading period
```

### UpdateRangeLines()
```cpp
Purpose: Draw/update all visual elements on chart
Algorithm:
  1. If Show4HRange AND valid 4H data:
     - CreateHorizontalLine("4H_High", ...)
       * Creates OBJ_TREND from g_last4HCandleTime to g_last4HCandleTime + 86400
     - CreateHorizontalLine("4H_Low", ...)
       * Creates OBJ_TREND from g_last4HCandleTime to g_last4HCandleTime + 86400
     - If ShowLabels:
       * CreateLabel("4H_High_Label", ...) - positioned at end time
       * CreateLabel("4H_Low_Label", ...) - positioned at end time

  2. If Show15MRange AND valid 15M data:
     - CreateHorizontalLine("15M_High", ...)
       * Creates OBJ_TREND from g_last15MCandleTime to g_last15MCandleTime + 86400
     - CreateHorizontalLine("15M_Low", ...)
       * Creates OBJ_TREND from g_last15MCandleTime to g_last15MCandleTime + 86400
     - If ShowLabels:
       * CreateLabel("15M_High_Label", ...) - positioned at end time
       * CreateLabel("15M_Low_Label", ...) - positioned at end time

  3. If ShowLabels:
     - CreateInfoPanel()

  4. Call ChartRedraw()
```

## Python Bot Alignment

### Matching Logic

| Python Component | Indicator Equivalent | Verification |
|------------------|---------------------|--------------|
| `MultiRangeCandleProcessor` | `Initialize4HCandle()` + `Initialize15MCandle()` | ✓ Same lookback logic |
| `RangeConfig("4H_5M")` | 4H range (04:00 UTC) | ✓ Same time check |
| `RangeConfig("15M_1M")` | 15M range (04:30 UTC) | ✓ Same time check |
| `is_new_reference_candle()` | `CheckNew4HCandle()` + `CheckNew15MCandle()` | ✓ Same detection logic |
| `ReferenceCandle.high` | `g_4HHigh` / `g_15MHigh` | ✓ Same data source |
| `ReferenceCandle.low` | `g_4HLow` / `g_15MLow` | ✓ Same data source |

### Time Synchronization
Both systems use:
- **UTC timezone** for all time checks
- **Opening time** of candles (not closing time)
- **Index 1** for last closed candle (index 0 is forming)
- **Exact time matching** (hour == 4, minute == 0 for 4H; hour == 4, minute == 30 for 15M)

## Performance Considerations

### Optimization Strategies
1. **Minimal Redraws**: Only redraw when new reference candles form
2. **Object Reuse**: Delete and recreate objects instead of updating properties
3. **Efficient Loops**: Limited lookback (10 for 4H, 100 for 15M)
4. **Conditional Rendering**: Skip drawing if Show*Range is false

### Resource Usage
- **CPU**: Negligible (only processes on new candles)
- **Memory**: ~9 chart objects maximum
- **Network**: None (uses local chart data only)

## Extension Points

### Adding New Ranges
To add a third range (e.g., 1H at 05:00 UTC):

1. Add input parameters:
```cpp
input bool Show1HRange = true;
input color Color1HHigh = clrYellow;
input color Color1HLow = clrPurple;
```

2. Add global variables:
```cpp
datetime g_last1HCandleTime = 0;
double g_1HHigh = 0;
double g_1HLow = 0;
```

3. Create initialization function:
```cpp
void Initialize1HCandle() { /* Similar to Initialize4HCandle */ }
```

4. Create check function:
```cpp
void CheckNew1HCandle() { /* Similar to CheckNew4HCandle */ }
```

5. Update OnInit(), OnCalculate(), UpdateRangeLines(), DeleteAllObjects()

### Adding Alerts
To add price alerts when approaching ranges:

```cpp
void CheckPriceProximity()
{
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double threshold = 10 * _Point; // 10 pips
   
   if(MathAbs(currentPrice - g_4HHigh) < threshold)
   {
      Alert("Price approaching 4H High!");
   }
   // ... similar for other levels
}
```

Call from OnCalculate() after UpdateRangeLines().

## Testing Checklist

- [ ] Compiles without errors or warnings
- [ ] Initializes correctly on chart attachment
- [ ] Finds historical 4H candle at 04:00 UTC
- [ ] Finds historical 15M candle at 04:30 UTC
- [ ] Draws all lines with correct colors and styles
- [ ] Shows info panel with accurate data
- [ ] Updates when new 4H candle forms at 04:00 UTC
- [ ] Updates when new 15M candle forms at 04:30 UTC
- [ ] Cleans up objects on indicator removal
- [ ] Works on multiple symbols simultaneously
- [ ] Respects Show*Range input parameters
- [ ] Respects ShowLabels input parameter
- [ ] Handles missing data gracefully (no crashes)

## Known Limitations

1. **Broker Time Dependency**: Assumes broker's server time matches UTC
2. **No Historical Ranges**: Only shows current day's ranges
3. **No Alerts**: No built-in price proximity alerts
4. **Fixed Times**: Hardcoded to 04:00 and 04:30 UTC (not configurable)
5. **No Multi-Day View**: Doesn't show previous days' ranges

## Future Enhancements

1. **Configurable Times**: Allow user to set reference times via inputs
2. **Historical Ranges**: Option to show previous days' ranges
3. **Price Alerts**: Alert when price approaches or breaks ranges
4. **Range Statistics**: Show average range size, breakout frequency
5. **Broker Time Offset**: Auto-detect and adjust for broker time differences
6. **Mobile Notifications**: Send push notifications on range updates

