# FMS Range Visualizer Indicator

## Overview
The **FMS Range Visualizer** is a custom MT5 indicator that displays the key price ranges used by the Python trading bot's multi-range breakout strategy. It visualizes both the 4H and 15M reference candle ranges directly on your MT5 charts using time-bounded trend lines that show exactly when each range is active.

## What It Shows

### 4H Range (Blue/Red Lines)
- **4H High Line (Blue)**: The SELL breakout level from the 4H candle at 04:00 UTC
- **4H Low Line (Red)**: The BUY breakout level from the 4H candle at 04:00 UTC
- **Timeframe**: 4-Hour (H4)
- **Reference Time**: 04:00 UTC (second 4H candle of the day)
- **Duration**: Lines extend from 04:00 UTC to next day's 04:00 UTC (24 hours)
- **Updates**: Once per day when new 4H candle forms at 04:00 UTC

### 15M Range (Green/Orange Lines)
- **15M High Line (Green)**: The SELL breakout level from the 15M candle at 04:30 UTC
- **15M Low Line (Orange)**: The BUY breakout level from the 15M candle at 04:30 UTC
- **Timeframe**: 15-Minute (M15)
- **Reference Time**: 04:30 UTC
- **Duration**: Lines extend from 04:30 UTC to next day's 04:30 UTC (24 hours)
- **Updates**: Once per day when new 15M candle forms at 04:30 UTC

## Installation

1. **Copy the indicator file**:
   - Copy `FMS_RangeVisualizer.mq5` to your MT5 `Indicators` folder
   - Default location: `C:\Users\[YourName]\AppData\Roaming\MetaQuotes\Terminal\[TerminalID]\MQL5\Indicators\`

2. **Compile the indicator**:
   - Open MetaEditor (F4 in MT5)
   - Open `FMS_RangeVisualizer.mq5`
   - Click "Compile" (F7) or the compile button
   - Ensure there are no errors

3. **Attach to chart**:
   - In MT5, go to Insert → Indicators → Custom → FMS_RangeVisualizer
   - Or drag the indicator from the Navigator window onto your chart

## Input Parameters

### 4H Range Settings
- **Show4HRange**: Enable/disable 4H range display (default: true)
- **Color4HHigh**: Color for 4H high line (default: Dodger Blue)
- **Color4HLow**: Color for 4H low line (default: Crimson)
- **Width4H**: Line width for 4H lines (default: 2)
- **Style4H**: Line style for 4H lines (default: Solid)

### 15M Range Settings
- **Show15MRange**: Enable/disable 15M range display (default: true)
- **Color15MHigh**: Color for 15M high line (default: Lime Green)
- **Color15MLow**: Color for 15M low line (default: Orange)
- **Width15M**: Line width for 15M lines (default: 1)
- **Style15M**: Line style for 15M lines (default: Dotted)

### Display Settings
- **ShowLabels**: Show/hide text labels and info panel (default: true)
- **FontSize**: Font size for labels (default: 10)
- **LabelColor**: Color for label text (default: White)

## How It Works

### Matching Python Bot Logic
The indicator exactly replicates the Python bot's multi-range candle detection:

1. **4H Range (Range ID: "4H_5M")**:
   - Searches for the 4H candle that opens at 04:00 UTC
   - This is the second 4H candle of the day (00:00-04:00 is first, 04:00-08:00 is second)
   - Tracks the high and low of this specific candle
   - Updates once per day when a new 04:00 UTC candle forms

2. **15M Range (Range ID: "15M_1M")**:
   - Searches for the 15M candle that opens at 04:30 UTC
   - Tracks the high and low of this specific candle
   - Updates once per day when a new 04:30 UTC candle forms

### Initialization
On startup, the indicator:
- Searches backwards through recent history (up to 10 candles for 4H, 100 for 15M)
- Finds the most recent valid reference candle for each range
- Displays those ranges immediately

### Real-Time Updates
The indicator continuously monitors for:
- New 4H candle at 04:00 UTC → Updates 4H range
- New 15M candle at 04:30 UTC → Updates 15M range
- Automatically redraws lines when ranges change

## Info Panel
When labels are enabled, an info panel appears in the top-left corner showing:
- Current 4H range values (High, Low, Range size, Timestamp)
- Current 15M range values (High, Low, Range size, Timestamp)
- "Waiting..." status if a range hasn't been detected yet

## Usage Tips

1. **Best Timeframes**: Works on any chart timeframe, but recommended:
   - 5M chart for monitoring 4H range breakouts
   - 1M chart for monitoring 15M range breakouts

2. **Combining with EA**: Use alongside the FiveMinScalper EA to see:
   - Where the EA is looking for breakouts
   - Current price position relative to ranges
   - Visual confirmation of strategy logic

3. **Multi-Symbol Monitoring**: Attach to multiple charts to monitor ranges across different symbols

4. **Customization**: Adjust colors and styles to match your chart theme

## Troubleshooting

**Lines not appearing?**
- Check that the reference times (04:00 UTC for 4H, 04:30 UTC for 15M) have occurred
- Verify your broker's server time matches UTC (or adjust accordingly)
- Check the Experts tab in MT5 terminal for initialization messages

**Wrong candle being tracked?**
- Ensure your broker's 4H and 15M candles align with UTC time
- Some brokers may have offset server times

**Lines disappear?**
- This is normal when new reference candles form - they're redrawn automatically
- Check the info panel to see current range status

## Technical Details

- **Indicator Type**: Chart window indicator
- **Plots**: 0 (uses graphical objects instead)
- **Line Type**: OBJ_TREND (time-bounded horizontal trend lines)
- **Objects Created**:
  - 4 trend lines (4H High/Low, 15M High/Low) - each with 24-hour duration
  - 4 text labels (optional) - positioned at end of trend lines
  - 1 info panel (optional)
- **Object Prefix**: `FMS_RV_` (all objects start with this)
- **Update Frequency**: On every tick (but only redraws when new reference candles form)
- **Line Duration**:
  - 4H lines: 04:00 UTC to next day's 04:00 UTC (24 hours)
  - 15M lines: 04:30 UTC to next day's 04:30 UTC (24 hours)

## Compatibility

- **MT5 Version**: Build 3802 or higher
- **Python Bot**: Matches multi-range strategy in `python_trader/src/strategy/multi_range_candle_processor.py`
- **Configuration**: Matches default ranges in `python_trader/src/config/config.py`

## Version History

**v1.00** (Initial Release)
- 4H range visualization (04:00 UTC)
- 15M range visualization (04:30 UTC)
- Customizable colors, widths, and styles
- Info panel with range details
- Auto-initialization with recent candles

