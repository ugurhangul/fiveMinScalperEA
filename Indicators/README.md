# FMS Range Visualizer - Complete Documentation

## 📋 Quick Links

- **[Quick Start Guide](QUICK_START.md)** - Get up and running in 3 steps
- **[Visual Guide](VISUAL_GUIDE.md)** - See what the indicator displays
- **[Full Documentation](FMS_RangeVisualizer_README.md)** - Complete feature reference
- **[Technical Specification](TECHNICAL_SPEC.md)** - For developers and advanced users

## 🎯 What Is This?

The **FMS Range Visualizer** is a custom MT5 indicator that displays the exact price ranges your Python trading bot monitors for breakout signals. It shows:

- **4H Range**: High/Low from the 4H candle at 04:00 UTC (blue/red solid lines, 24-hour duration)
- **15M Range**: High/Low from the 15M candle at 04:30 UTC (green/orange dotted lines, 24-hour duration)

These ranges match **exactly** what the Python bot uses in its multi-range breakout strategy. All lines are **time-bounded** to clearly show which trading period each range applies to.

## ✨ Key Features

✅ **Perfect Alignment**: Matches Python bot's `MultiRangeCandleProcessor` logic
✅ **Real-Time Updates**: Automatically updates when new reference candles form
✅ **Time-Bounded Lines**: 24-hour duration clearly shows active trading periods
✅ **Visual Clarity**: Color-coded lines with customizable styles
✅ **Info Panel**: Shows exact price levels and timestamps
✅ **Multi-Symbol**: Works on any chart, any symbol
✅ **Zero Configuration**: Works out-of-the-box with sensible defaults

## 🚀 Installation (3 Steps)

### 1. Compile
```
MetaEditor → Open FMS_RangeVisualizer.mq5 → Press F7 (Compile)
```

### 2. Attach
```
MT5 → Insert → Indicators → Custom → FMS_RangeVisualizer
```

### 3. Trade
```
Watch the ranges, monitor breakouts, profit! 📈
```

**Full instructions**: [QUICK_START.md](QUICK_START.md)

## 📊 What You'll See

```
┌─────────────────────────────────┐
│ FMS Range Visualizer            │
│ ━━━━━━━━━━━━━━━━━━━━━━          │
│ 4H Range (04:00 UTC):           │
│   High: 1.08450  ← SELL level   │
│   Low:  1.08200  ← BUY level    │
│                                 │
│ 15M Range (04:30 UTC):          │
│   High: 1.08380  ← SELL level   │
│   Low:  1.08290  ← BUY level    │
└─────────────────────────────────┘

Price Chart (Time-Bounded Lines):
1.08450 ═════════════════════  ← 4H High (Blue, 04:00→04:00+24h)
1.08380 ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄  ← 15M High (Green, 04:30→04:30+24h)
        [Current Price Action]
1.08290 ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄  ← 15M Low (Orange, 04:30→04:30+24h)
1.08200 ═════════════════════  ← 4H Low (Red, 04:00→04:00+24h)
```

**Visual examples**: [VISUAL_GUIDE.md](VISUAL_GUIDE.md)

## 🎨 Customization

All colors, line widths, and styles are configurable via input parameters:

| Setting | Default | Options |
|---------|---------|---------|
| 4H High Color | Dodger Blue | Any MT5 color |
| 4H Low Color | Crimson | Any MT5 color |
| 15M High Color | Lime Green | Any MT5 color |
| 15M Low Color | Orange | Any MT5 color |
| Line Width | 2 (4H), 1 (15M) | 1-5 |
| Line Style | Solid (4H), Dotted (15M) | Solid, Dash, Dot, etc. |
| Show Labels | Yes | Yes/No |

## 🔄 How It Works

### Initialization (On Startup)
1. Searches backwards for most recent 04:00 UTC 4H candle
2. Searches backwards for most recent 04:30 UTC 15M candle
3. Draws ranges immediately if found

### Real-Time Operation
1. Monitors for new 4H candle at 04:00 UTC → Updates 4H range
2. Monitors for new 15M candle at 04:30 UTC → Updates 15M range
3. Redraws lines automatically when ranges change

### Python Bot Synchronization
The indicator uses the **exact same logic** as the Python bot:
- Same reference times (04:00 UTC for 4H, 04:30 UTC for 15M)
- Same candle selection (last closed candle at specific time)
- Same high/low extraction (iHigh/iLow functions)

**Technical details**: [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md)

## 📚 Documentation Structure

```
Indicators/
├── FMS_RangeVisualizer.mq5          ← The indicator code
├── README.md                         ← This file (overview)
├── QUICK_START.md                    ← 3-step installation guide
├── VISUAL_GUIDE.md                   ← Visual examples and diagrams
├── FMS_RangeVisualizer_README.md     ← Complete feature documentation
└── TECHNICAL_SPEC.md                 ← Developer reference
```

**Start here**: [QUICK_START.md](QUICK_START.md)

## 🎓 Learning Path

### Beginner
1. Read [QUICK_START.md](QUICK_START.md)
2. Install and attach to a chart
3. Watch the ranges update

### Intermediate
1. Read [VISUAL_GUIDE.md](VISUAL_GUIDE.md)
2. Understand breakout scenarios
3. Customize colors and styles

### Advanced
1. Read [FMS_RangeVisualizer_README.md](FMS_RangeVisualizer_README.md)
2. Read [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md)
3. Modify code for custom ranges

## 🔧 Troubleshooting

| Problem | Solution | Reference |
|---------|----------|-----------|
| Lines not showing | Wait for 04:00/04:30 UTC | [QUICK_START.md](QUICK_START.md) |
| Wrong candle tracked | Check broker time vs UTC | [FMS_RangeVisualizer_README.md](FMS_RangeVisualizer_README.md) |
| Compilation errors | Ensure MT5 (not MT4) | [QUICK_START.md](QUICK_START.md) |
| Want to add ranges | See extension guide | [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md) |

## 🤝 Integration with Python Bot

### What the Indicator Shows
- **4H Range**: The reference range for the "4H_5M" strategy
- **15M Range**: The reference range for the "15M_1M" strategy

### What the Python Bot Does
- **4H_5M**: Monitors 5M candles for breakouts of the 4H range
- **15M_1M**: Monitors 1M candles for breakouts of the 15M range

### Perfect Together
1. **Indicator**: Shows WHERE to look for breakouts
2. **Python Bot**: Detects WHEN breakouts happen and executes trades
3. **You**: Monitor both to understand the strategy in action

## 📈 Use Cases

### 1. Strategy Visualization
- See exactly what ranges the bot is monitoring
- Understand why trades are triggered
- Verify bot logic is working correctly

### 2. Manual Trading
- Use the ranges for manual breakout trading
- Combine with your own analysis
- Set alerts at range boundaries

### 3. Multi-Symbol Monitoring
- Attach to multiple charts
- See all ranges at a glance
- Identify best breakout opportunities

### 4. Backtesting Validation
- Review historical ranges
- Verify strategy logic
- Understand past performance

## 🎯 Best Practices

1. **Use Appropriate Timeframes**:
   - 5M chart for 4H range monitoring
   - 1M chart for 15M range monitoring

2. **Enable Info Panel**:
   - Shows exact price levels
   - Displays range timestamps
   - Confirms ranges are current

3. **Customize Colors**:
   - Match your chart theme
   - Ensure high visibility
   - Distinguish between ranges

4. **Monitor Multiple Symbols**:
   - Attach to all traded pairs
   - Use consistent settings
   - Compare range sizes

## 📞 Support

For questions or issues:
1. Check the documentation files in this folder
2. Review Python bot logs: `python_trader/logs/`
3. Compare with bot config: `python_trader/src/config/config.py`
4. Verify broker time alignment with UTC

## 🔮 Future Enhancements

Potential additions (not yet implemented):
- [ ] Configurable reference times (not hardcoded to 04:00/04:30)
- [ ] Historical range display (show previous days)
- [ ] Price proximity alerts
- [ ] Range statistics (average size, breakout frequency)
- [ ] Broker time offset auto-detection
- [ ] Mobile push notifications

## 📄 License

Part of the FiveMinScalper trading system.

## 🙏 Credits

- Matches logic from `python_trader/src/strategy/multi_range_candle_processor.py`
- Aligns with config in `python_trader/src/config/config.py`
- Complements the FiveMinScalper EA

---

**Ready to get started?** → [QUICK_START.md](QUICK_START.md)

**Want to see examples?** → [VISUAL_GUIDE.md](VISUAL_GUIDE.md)

**Need full details?** → [FMS_RangeVisualizer_README.md](FMS_RangeVisualizer_README.md)

**Developer?** → [TECHNICAL_SPEC.md](TECHNICAL_SPEC.md)

---

**Happy Trading! 📈**

