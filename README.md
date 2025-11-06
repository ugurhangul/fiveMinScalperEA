# Five Minute Scalper EA (FiveMinScalper)

## 📊 Overview

The **Five Minute Scalper EA** is an advanced MetaTrader 5 Expert Advisor that implements a sophisticated false breakout reversal strategy based on 4-hour candle ranges. The EA monitors 5-minute price action for false breakouts of key 4H levels, then enters trades when price reverses back into the range.

### Core Strategy

The EA uses a **false breakout reversal** approach:
1. **Reference Setup**: Identifies the 4H candle at 04:00 UTC (second candle of the day)
2. **Breakout Detection**: Waits for 5-minute candle to close outside the 4H range (weak breakout)
3. **Reversal Entry**: Enters trade when price reverses back inside the 4H range (strong reversal)
4. **Risk Management**: Uses calculated stop-loss and take-profit based on risk/reward ratio

**BUY Signal**: 5M candle closes BELOW 4H low → Next 5M candle closes ABOVE 4H low  
**SELL Signal**: 5M candle closes ABOVE 4H high → Next 5M candle closes BELOW 4H high

## ✨ Key Features

### Trading Strategy
- ✅ **False Breakout Detection**: Identifies weak breakouts with low volume
- ✅ **Reversal Confirmation**: Validates strong reversals with high volume
- ✅ **Divergence Analysis**: RSI and MACD divergence confirmation (optional)
- ✅ **Symbol-Specific Optimization**: Auto-adjusts parameters based on asset class
- ✅ **Adaptive Filter System**: Dynamically enables/disables filters based on performance

### Risk Management
- ✅ **Position Sizing**: Automatic lot calculation based on account risk percentage
- ✅ **Stop-Loss Protection**: Configurable offset from 4H high/low
- ✅ **Take-Profit Targets**: Risk/reward ratio-based profit targets
- ✅ **Breakeven Management**: Moves SL to breakeven at configurable R:R ratio
- ✅ **Trailing Stop**: Optional trailing stop after reaching profit threshold

### Advanced Features
- ✅ **Symbol-Level Adaptation**: Disables underperforming symbols automatically
- ✅ **Multi-Symbol Support**: Works on forex, metals, indices, and crypto
- ✅ **Trading Hours Filter**: Restrict trading to specific hours
- ✅ **Visual Indicators**: Draws key levels on chart for monitoring
- ✅ **Comprehensive Logging**: Detailed logs for analysis and debugging

## 📥 Installation

### Requirements
- MetaTrader 5 platform (build 3661 or higher)
- Minimum account balance: $100 (recommended: $500+)
- VPS recommended for 24/7 operation

### Installation Steps

1. **Download Files**
   ```
   Clone or download this repository to your local machine
   ```

2. **Copy to MT5 Directory**
   ```
   Copy all files to: C:\Users\[YourName]\AppData\Roaming\MetaQuotes\Terminal\[InstanceID]\MQL5\Experts\
   
   Directory structure:
   Experts/
   ├── fiveminscalper.mq5
   ├── Include/
   │   ├── FMS_Config.mqh
   │   ├── FMS_GlobalVars.mqh
   │   ├── FMS_Utilities.mqh
   │   ├── FMS_Indicators.mqh
   │   ├── FMS_TradeManagement.mqh
   │   ├── FMS_TradeExecution.mqh
   │   ├── FMS_SymbolOptimization.mqh
   │   ├── FMS_ChartVisual.mqh
   │   ├── FMS_CandleProcessing.mqh
   │   └── FMS_Strategy.mqh
   └── Indicators/
       └── FMS_RangeVisualizer.mq5
   ```

3. **Compile the EA**
   ```
   - Open MetaEditor (F4 in MT5)
   - Open fiveminscalper.mq5
   - Press F7 to compile
   - Ensure no errors in compilation
   ```

4. **Attach to Chart**
   ```
   - Open a 5-minute chart of your desired symbol
   - Drag fiveminscalper from Navigator → Expert Advisors
   - Enable "Allow Algo Trading" button in MT5 toolbar
   - Configure parameters (see Configuration section)
   ```

5. **Install Range Visualizer (Optional)**
   ```
   - Compile Indicators/FMS_RangeVisualizer.mq5
   - Attach to chart: Insert → Indicators → Custom → FMS_RangeVisualizer
   - See Indicators/README.md for detailed instructions
   ```

## ⚙️ Configuration Parameters

### Strategy Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EntryOffsetPercent` | 0.01 | Entry offset from 4H high/low (1% = 0.01) |
| `StopLossOffsetPercent` | 0.02 | Stop-loss offset from 4H high/low (2% = 0.02) |
| `RiskRewardRatio` | 2.0 | Risk to reward ratio (1:2 means 2x profit target) |

### Risk Management
| Parameter | Default | Description |
|-----------|---------|-------------|
| `RiskPercentPerTrade` | 1.0 | Risk per trade as % of account balance |
| `MaxLotSize` | 10.0 | Maximum position size in lots |
| `MinLotSize` | 0.01 | Minimum position size in lots |

### Trailing Stop
| Parameter | Default | Description |
|-----------|---------|-------------|
| `UseTrailingStop` | false | Enable/disable trailing stop |
| `TrailingStopTriggerRR` | 1.5 | Activate trailing at this R:R ratio |
| `TrailingStopDistance` | 50.0 | Trailing stop distance in points |

### Trading Hours
| Parameter | Default | Description |
|-----------|---------|-------------|
| `UseTradingHours` | false | Enable trading hours filter |
| `StartHour` | 0 | Trading start hour (UTC) |
| `EndHour` | 23 | Trading end hour (UTC) |

### Advanced Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| `UseBreakeven` | true | Move SL to breakeven when profitable |
| `BreakevenTriggerRR` | 1.0 | Trigger breakeven at this R:R ratio |
| `UseOnly00UTCCandle` | true | Use only 04:00 UTC 4H candle (recommended) |
| `MagicNumber` | 123456 | Unique identifier for EA's trades |
| `TradeComment` | "5MinScalper" | Comment added to all trades |

### Symbol-Specific Optimization
| Parameter | Default | Description |
|-----------|---------|-------------|
| `UseSymbolSpecificSettings` | true | Auto-adjust parameters by asset class |
| `ManualSymbolCategory` | "AUTO" | Override: AUTO, MAJOR_FOREX, MINOR_FOREX, METALS, INDICES, CRYPTO |

### Adaptive Filter System
| Parameter | Default | Description |
|-----------|---------|-------------|
| `UseAdaptiveFilters` | true | Enable adaptive filter system |
| `AdaptiveLossTrigger` | 3 | Consecutive losses to activate filters |
| `AdaptiveWinRecovery` | 2 | Consecutive wins to deactivate filters |
| `StartWithFiltersEnabled` | false | Initial filter state |

### Symbol-Level Adaptation
| Parameter | Default | Description |
|-----------|---------|-------------|
| `UseSymbolAdaptation` | true | Enable symbol-level performance tracking |
| `SymbolMinTrades` | 10 | Minimum trades before evaluation |
| `SymbolMinWinRate` | 30.0 | Minimum win rate % to stay enabled |
| `SymbolMaxLoss` | -100.0 | Maximum loss $ before disabling symbol |
| `SymbolMaxConsecutiveLosses` | 5 | Max consecutive losses before disabling |
| `SymbolCoolingPeriodDays` | 7 | Days before auto re-enable |

### Volume Confirmation
| Parameter | Default | Description |
|-----------|---------|-------------|
| `BreakoutVolumeMaxMultiplier` | 1.0 | Max volume for breakout (weak = good) |
| `ReversalVolumeMinMultiplier` | 1.5 | Min volume for reversal (strong = good) |
| `VolumeAveragePeriod` | 20 | Period for volume moving average |

### Divergence Confirmation
| Parameter | Default | Description |
|-----------|---------|-------------|
| `RequireBothIndicators` | false | Require both RSI and MACD divergence |
| `RSI_Period` | 14 | RSI indicator period |
| `MACD_Fast` | 12 | MACD fast EMA period |
| `MACD_Slow` | 26 | MACD slow EMA period |
| `MACD_Signal` | 9 | MACD signal line period |
| `DivergenceLookback` | 20 | Candles to look back for divergence |

### Visual Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| `ShowLevelsOnChart` | true | Draw 4H high/low levels on chart |
| `Color4HHigh` | Dodger Blue | Color for 4H high line |
| `Color4HLow` | Dodger Blue | Color for 4H low line |
| `ColorBuyEntry` | Lime | Color for buy entry line |
| `ColorSellEntry` | Red | Color for sell entry line |

### Logging Settings
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EnableDetailedLogging` | true | Enable detailed log messages |
| `LogToFile` | true | Write logs to file |
| `LogToConsole` | true | Print logs to Experts tab |
| `LogActiveTradesEvery5Min` | true | Log all active trades every 5 minutes |

## 📖 Usage Guidelines

### Getting Started

1. **Start with Demo Account**
   - Test the EA on a demo account first
   - Run for at least 2 weeks to understand behavior
   - Monitor logs and performance metrics

2. **Choose Appropriate Symbols**
   - Recommended: Major forex pairs (EUR/USD, GBP/USD, USD/JPY)
   - Works on: Metals (XAU/USD), Indices, Crypto
   - Avoid: Exotic pairs with wide spreads

3. **Set Conservative Risk**
   - Start with 0.5-1% risk per trade
   - Increase only after consistent profitability
   - Never risk more than 2% per trade

4. **Monitor Performance**
   - Check logs daily in MT5 Experts tab
   - Review closed trades in Account History
   - Adjust parameters based on results

### Best Practices

#### Symbol Selection
- **Major Forex Pairs**: EUR/USD, GBP/USD, USD/JPY, AUD/USD, USD/CAD
- **Metals**: XAU/USD (Gold), XAG/USD (Silver)
- **Indices**: US30, NAS100, SPX500
- **Avoid**: Pairs with spreads > 3 pips, low liquidity symbols

#### Timeframe
- **Chart Timeframe**: 5-minute (M5) - Required for proper operation
- **Reference Timeframe**: 4-hour (H4) - Used internally by EA
- Do not change chart timeframe while EA is running

#### Risk Management
- **Account Size**: Minimum $100, recommended $500+
- **Risk Per Trade**: 0.5-1% for conservative, 1-2% for aggressive
- **Max Positions**: 1 position per symbol (enforced by EA)
- **Diversification**: Run on 3-5 different symbols maximum

#### Trading Hours
- **Best Performance**: London/New York session overlap (12:00-16:00 UTC)
- **Avoid**: Low liquidity hours (22:00-02:00 UTC)
- **Weekend**: EA automatically stops trading before weekend

#### VPS Recommendations
- **Latency**: < 10ms to broker server
- **Uptime**: 99.9% guaranteed
- **Location**: Same region as broker
- **Specs**: 1GB RAM minimum, Windows Server

### Understanding the Strategy

#### Entry Logic
1. EA identifies 4H candle at 04:00 UTC
2. Monitors 5M candles for breakout (close outside 4H range)
3. Waits for reversal (close back inside 4H range)
4. Validates with volume and divergence filters (if enabled)
5. Enters trade with calculated lot size

#### Exit Logic
- **Take Profit**: Automatically set at risk/reward ratio (default 1:2)
- **Stop Loss**: Set at offset from 4H high/low (default 2%)
- **Breakeven**: Moves SL to entry when profit reaches 1:1 R:R
- **Trailing Stop**: Optional, activates at 1.5:1 R:R

#### Adaptive Behavior
- **Filter Activation**: After 3 consecutive losses, enables volume/divergence filters
- **Filter Deactivation**: After 2 consecutive wins, disables filters for more opportunities
- **Symbol Disabling**: Automatically stops trading symbols with poor performance
- **Auto Recovery**: Re-enables symbols after cooling period (7 days default)

### Monitoring and Maintenance

#### Daily Checks
- ✅ Verify EA is running (check for smiley face icon)
- ✅ Review new trades in Terminal tab
- ✅ Check logs for errors or warnings
- ✅ Monitor account balance and equity

#### Weekly Reviews
- ✅ Analyze win rate and profit factor
- ✅ Review which symbols are performing best
- ✅ Check if any symbols were auto-disabled
- ✅ Adjust risk parameters if needed

#### Monthly Optimization
- ✅ Run strategy tester on recent data
- ✅ Compare live results vs backtest
- ✅ Fine-tune parameters for current market conditions
- ✅ Update EA to latest version if available

### Troubleshooting

| Issue | Solution |
|-------|----------|
| EA not trading | Check "Allow Algo Trading" is enabled, verify 5M chart |
| No positions opening | Wait for 04:00 UTC 4H candle, check logs for entry conditions |
| Positions closing early | Check if breakeven is enabled, review trailing stop settings |
| High loss rate | Enable adaptive filters, reduce risk per trade, check symbol selection |
| Compilation errors | Ensure all .mqh files are in Include folder, use MT5 (not MT4) |

## ⚠️ Risk Disclaimer

**IMPORTANT: Please read carefully before using this Expert Advisor**

### Trading Risks
- **Forex trading involves substantial risk of loss** and is not suitable for all investors
- **Past performance is not indicative of future results**
- **You could lose some or all of your invested capital**
- Only trade with money you can afford to lose
- Leverage can work against you as well as for you

### EA-Specific Risks
- This EA is provided "as-is" without any guarantees of profitability
- Automated trading systems can malfunction due to technical issues
- Market conditions can change, making the strategy ineffective
- Slippage and spread widening can impact results
- VPS or internet connection failures can cause missed trades

### User Responsibilities
- **Test thoroughly on demo account** before live trading
- **Monitor the EA regularly** - do not leave it completely unattended
- **Understand the strategy** before risking real money
- **Start with small position sizes** and scale up gradually
- **Keep MT5 and EA updated** to latest versions

### No Guarantees
- The developers make no claims about profitability
- Results will vary based on broker, market conditions, and settings
- No refunds or compensation for trading losses
- Use at your own risk

**By using this EA, you acknowledge that you understand and accept these risks.**

## 📄 License

This project is provided for educational and personal use.

**Terms:**
- ✅ Free to use for personal trading
- ✅ Modify for your own needs
- ❌ Do not sell or redistribute without permission
- ❌ No commercial use without license

## 📞 Support & Contact

### Documentation
- **Main README**: This file
- **Indicator Guide**: `Indicators/README.md`
- **Quick Start**: `Indicators/QUICK_START.md`
- **Visual Guide**: `Indicators/VISUAL_GUIDE.md`

### Getting Help
1. **Check Logs**: Review MT5 Experts tab and log files
2. **Read Documentation**: Most questions answered in docs
3. **Test Settings**: Use Strategy Tester to validate parameters
4. **Community**: Share experiences with other users

### Reporting Issues
When reporting issues, please include:
- MT5 build number
- EA version (1.00)
- Symbol and timeframe
- Input parameters used
- Log file excerpt showing the issue
- Steps to reproduce

### Version History
- **v1.00** (Current) - Initial release
  - False breakout reversal strategy
  - Adaptive filter system
  - Symbol-level adaptation
  - Multi-symbol support
  - Comprehensive risk management

---

## 🎯 Quick Reference Card

### Minimum Setup (Conservative)
```
RiskPercentPerTrade = 0.5
UseBreakeven = true
UseAdaptiveFilters = true
UseSymbolAdaptation = true
StartWithFiltersEnabled = false
```

### Aggressive Setup
```
RiskPercentPerTrade = 2.0
UseBreakeven = true
UseTrailingStop = true
UseAdaptiveFilters = false
UseSymbolAdaptation = true
```

### Recommended Symbols
- EUR/USD, GBP/USD, USD/JPY (Major Forex)
- XAU/USD (Gold)
- US30, NAS100 (Indices)

### Key Times (UTC)
- **04:00** - 4H reference candle forms
- **04:00-08:00** - Trading suspended (candle formation period)
- **08:00-04:00** - Active trading period

---

**Happy Trading! 📈**

*Remember: The best trader is a disciplined trader. Stick to your risk management rules!*


