# FMS Range Visualizer - Changelog

## Version 2.0 - Time-Bounded Lines (Current)

### Major Changes

**Replaced infinite horizontal lines with time-bounded trend lines**

Previously, the indicator used `OBJ_HLINE` objects that extended infinitely across the entire chart. This made it unclear which trading period each range applied to, especially when viewing historical data or multiple days on the same chart.

Now, the indicator uses `OBJ_TREND` objects with defined start and end times, creating horizontal trend lines that:
- Start at the reference candle's opening time
- End exactly 24 hours later at the next reference candle's expected opening time
- Clearly show which trading period each range is active for

### Technical Implementation

#### Before (Version 1.0)
```mql5
// Old implementation - infinite horizontal line
ObjectCreate(0, objectName, OBJ_HLINE, 0, 0, price);
// Line extended infinitely across the chart
```

#### After (Version 2.0)
```mql5
// New implementation - time-bounded trend line
datetime startTime = g_last4HCandleTime;  // Reference candle opening time
datetime endTime = startTime + 86400;     // 24 hours later
ObjectCreate(0, objectName, OBJ_TREND, 0, startTime, price, endTime, price);
ObjectSetInteger(0, objectName, OBJPROP_RAY_RIGHT, false);  // Don't extend
ObjectSetInteger(0, objectName, OBJPROP_RAY_LEFT, false);   // Don't extend
```

### Specific Changes

#### 4H Range Lines
- **Start Time**: 04:00 UTC (when 4H reference candle opens)
- **End Time**: Next day's 04:00 UTC (24 hours later)
- **Duration**: Exactly 24 hours
- **Visual**: Blue (high) and Red (low) solid lines with defined endpoints

#### 15M Range Lines
- **Start Time**: 04:30 UTC (when 15M reference candle opens)
- **End Time**: Next day's 04:30 UTC (24 hours later)
- **Duration**: Exactly 24 hours
- **Visual**: Green (high) and Orange (low) dotted lines with defined endpoints

#### Text Labels
- **Position**: Now placed at the END of each trend line (endTime)
- **Before**: Labels were positioned at current chart time
- **After**: Labels are positioned at the end of the 24-hour range period

### Benefits

1. **Clarity**: Immediately see which trading period each range applies to
2. **Historical View**: When scrolling back, old ranges don't clutter the current view
3. **Multi-Day Analysis**: Easy to distinguish between different days' ranges
4. **Professional Appearance**: Clean, time-bounded lines look more professional
5. **Accurate Representation**: Matches the actual 24-hour validity period of each range

### Visual Comparison

#### Before (Infinite Lines)
```
Price
1.08450 ═══════════════════════════════════════════════════════════
        ↑                                                         ↑
        Old range                                          Current time
        (extends forever)
```

#### After (Time-Bounded Lines)
```
Price
1.08450 ═════════════════════════════════════════════════════════
        ↑                                                       ↑
        04:00 UTC                                    Next 04:00 UTC
        (24-hour duration)
```

### Code Changes Summary

**Modified Functions:**
1. `CreateHorizontalLine()` - Lines 259-309
   - Changed from `OBJ_HLINE` to `OBJ_TREND`
   - Added start/end time calculation
   - Set `RAY_RIGHT` and `RAY_LEFT` to false

2. `CreateLabel()` - Lines 311-354
   - Updated label positioning to use end time
   - Labels now appear at the end of trend lines

**No Changes Required:**
- `Initialize4HCandle()` - Still finds reference candle correctly
- `Initialize15MCandle()` - Still finds reference candle correctly
- `CheckNew4HCandle()` - Still detects new candles correctly
- `CheckNew15MCandle()` - Still detects new candles correctly
- `UpdateRangeLines()` - Still calls CreateHorizontalLine() the same way
- Input parameters - All remain the same
- Global variables - All remain the same

### Backward Compatibility

**Breaking Changes**: None
- All input parameters remain the same
- All functionality remains the same
- Only visual representation changed

**Migration**: Simply recompile and reattach
- No configuration changes needed
- No settings need to be adjusted
- Existing customizations (colors, widths, styles) still work

### Documentation Updates

All documentation files updated to reflect time-bounded lines:
- ✅ `FMS_RangeVisualizer.mq5` - Code updated
- ✅ `README.md` - Overview updated
- ✅ `QUICK_START.md` - Duration information added
- ✅ `VISUAL_GUIDE.md` - Diagrams updated with time bounds
- ✅ `FMS_RangeVisualizer_README.md` - Technical details updated
- ✅ `TECHNICAL_SPEC.md` - Implementation details updated
- ✅ `CHANGELOG.md` - This file created

### Testing Checklist

Before using in production, verify:
- [ ] Indicator compiles without errors
- [ ] 4H lines start at 04:00 UTC and end 24 hours later
- [ ] 15M lines start at 04:30 UTC and end 24 hours later
- [ ] Lines don't extend beyond their 24-hour period
- [ ] Labels appear at the end of lines
- [ ] Info panel shows correct information
- [ ] Lines update correctly when new reference candles form
- [ ] Old lines disappear when new ones are created
- [ ] Works correctly on multiple symbols
- [ ] Customization options (colors, widths, styles) still work

---

## Version 1.0 - Initial Release

### Features
- Display 4H range from 04:00 UTC candle
- Display 15M range from 04:30 UTC candle
- Customizable colors, widths, and styles
- Info panel with price levels and timestamps
- Auto-initialization with historical candles
- Real-time updates when new reference candles form

### Implementation
- Used `OBJ_HLINE` for infinite horizontal lines
- Used `OBJ_TEXT` for price level labels
- Used `OBJ_LABEL` for info panel
- Matched Python bot's `MultiRangeCandleProcessor` logic

---

**Current Version**: 2.0 (Time-Bounded Lines)  
**Last Updated**: 2025-01-06  
**Compatibility**: MT5 Build 3802+

