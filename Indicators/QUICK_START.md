# FMS Range Visualizer - Quick Start Guide

## 3-Step Installation

### Step 1: Compile the Indicator
1. Open **MetaEditor** (press F4 in MT5)
2. Navigate to `Indicators/FMS_RangeVisualizer.mq5`
3. Click **Compile** (F7) or the compile button
4. Verify "0 error(s), 0 warning(s)" in the output

### Step 2: Attach to Chart
1. In MT5, open any chart (recommended: 5M or 1M timeframe)
2. Go to **Insert → Indicators → Custom → FMS_RangeVisualizer**
3. Or drag from **Navigator** window → **Indicators → Custom → FMS_RangeVisualizer**

### Step 3: Configure (Optional)
- Click **OK** to use default settings, or
- Customize colors, line widths, and display options
- Click **OK** to apply

## What You'll See

### Immediately After Attaching:
- **Blue solid line**: 4H High (SELL breakout level)
- **Red solid line**: 4H Low (BUY breakout level)
- **Green dotted line**: 15M High (SELL breakout level)
- **Orange dotted line**: 15M Low (BUY breakout level)
- **Info panel** (top-left): Shows exact price levels and timestamps

### If Lines Don't Appear:
- Wait for 04:00 UTC (for 4H range) or 04:30 UTC (for 15M range)
- Check the **Experts** tab for initialization messages
- Verify your broker's server time alignment

## Understanding the Lines

### 4H Range (Thick Solid Lines)
```
Blue Line (4H High)  ← SELL breakout happens when price closes ABOVE this
─────────────────────
    [Price Range]
─────────────────────
Red Line (4H Low)    ← BUY breakout happens when price closes BELOW this
```
- **Updates**: Once per day at 04:00 UTC
- **Source**: Second 4H candle of the day (04:00-08:00 UTC)
- **Duration**: Lines extend for 24 hours (04:00 UTC → next day's 04:00 UTC)

### 15M Range (Thin Dotted Lines)
```
Green Line (15M High)  ← SELL breakout happens when price closes ABOVE this
- - - - - - - - - - - -
    [Price Range]
- - - - - - - - - - - -
Orange Line (15M Low)  ← BUY breakout happens when price closes BELOW this
```
- **Updates**: Once per day at 04:30 UTC
- **Source**: 15M candle at 04:30 UTC
- **Duration**: Lines extend for 24 hours (04:30 UTC → next day's 04:30 UTC)

**Important**: All lines are **time-bounded** - they show exactly which 24-hour trading period each range applies to, making it easy to see when ranges expire and new ones begin.

## Common Scenarios

### Scenario 1: Fresh Start (No Ranges Yet)
**What you see**: Info panel shows "Waiting..."
**What to do**: Wait for 04:00 UTC (4H) or 04:30 UTC (15M)
**When it updates**: Automatically when the reference candle closes

### Scenario 2: Mid-Day Attachment
**What you see**: Lines appear immediately with today's ranges
**What happens**: Indicator finds the most recent 04:00 UTC (4H) and 04:30 UTC (15M) candles
**Info panel**: Shows the timestamp of the reference candles

### Scenario 3: New Day Begins
**What you see**: Lines disappear briefly, then redraw
**What happens**: Old ranges are cleared, new ranges are drawn when reference candles form
**Timing**: 04:00 UTC for 4H, 04:30 UTC for 15M

## Customization Examples

### Example 1: Minimal Display (Lines Only)
```
Show4HRange = true
Show15MRange = true
ShowLabels = false  ← Hides text labels and info panel
```

### Example 2: 4H Range Only
```
Show4HRange = true
Show15MRange = false  ← Hides 15M range completely
ShowLabels = true
```

### Example 3: High Contrast Colors
```
Color4HHigh = clrYellow
Color4HLow = clrMagenta
Color15MHigh = clrAqua
Color15MLow = clrHotPink
```

### Example 4: Thicker Lines for Visibility
```
Width4H = 3
Width15M = 2
Style4H = STYLE_SOLID
Style15M = STYLE_SOLID  ← Change from dotted to solid
```

## Matching Python Bot Behavior

The indicator shows **exactly** what the Python bot monitors:

| Python Bot Range | Indicator Display | Reference Time | Breakout Detection |
|------------------|-------------------|----------------|-------------------|
| 4H_5M | Blue/Red lines | 04:00 UTC | 5M candles |
| 15M_1M | Green/Orange lines | 04:30 UTC | 1M candles |

**Note**: The indicator only shows the **ranges** (high/low levels). The actual breakout detection happens in the Python bot using 5M candles (for 4H range) and 1M candles (for 15M range).

## Tips for Best Results

1. **Use Multiple Timeframes**:
   - 5M chart: Monitor 4H range breakouts
   - 1M chart: Monitor 15M range breakouts
   - H4 chart: See the actual reference candle

2. **Combine with Price Action**:
   - Watch for candles closing outside the ranges
   - Look for retests of the breakout levels
   - Monitor volume on breakout candles

3. **Multi-Symbol Setup**:
   - Attach to all symbols you're trading
   - Use consistent color scheme across charts
   - Enable info panel to quickly see range values

4. **Alerts** (Future Enhancement):
   - Currently no alerts built-in
   - Consider adding custom alerts when price approaches ranges
   - Or use MT5's built-in alert tools on the lines

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Compilation errors | Ensure you're using MT5 (not MT4) |
| Lines not visible | Check if reference times have occurred today |
| Wrong candle tracked | Verify broker's server time matches UTC |
| Lines disappear | Normal when new reference candles form |
| Info panel overlaps | Adjust position in code or disable with ShowLabels=false |

## Next Steps

1. **Test on Demo**: Verify ranges match your expectations
2. **Compare with Python Bot**: Check that ranges align with bot's log output
3. **Customize**: Adjust colors and styles to your preference
4. **Monitor**: Watch how price interacts with the ranges
5. **Backtest**: Review historical ranges to understand strategy behavior

## Support

For issues or questions:
- Check the full README: `FMS_RangeVisualizer_README.md`
- Review Python bot logs: `python_trader/logs/`
- Compare with bot config: `python_trader/src/config/config.py`

---

**Happy Trading! 📈**

