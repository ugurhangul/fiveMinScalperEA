# FMS Range Visualizer - Visual Guide

## Chart Display Example

```
┌─────────────────────────────────────────────────────────────────┐
│ FMS Range Visualizer                                            │
│ ━━━━━━━━━━━━━━━━━━━━━━                                          │
│ 4H Range (04:00 UTC):                                           │
│   High: 1.08450                                                 │
│   Low:  1.08200                                                 │
│   Range: 0.00250                                                │
│   Time: 2025-01-15 04:00                                        │
│                                                                  │
│ 15M Range (04:30 UTC):                                          │
│   High: 1.08380                                                 │
│   Low:  1.08290                                                 │
│   Range: 0.00090                                                │
│   Time: 2025-01-15 04:30                                        │
└─────────────────────────────────────────────────────────────────┘

Price                                                    TIME-BOUNDED LINES
1.08500 ─────────────────────────────────────────────────────────

1.08450 ═════════════════════════════════════════════════════════  ← 4H High (Blue)
        ↑                                                       ↑     SELL Breakout Level
        04:00 UTC                                    Next 04:00 UTC  (24-hour duration)

1.08400 ─────────────────────────────────────────────────────────

1.08380 ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄  ← 15M High (Green)
        ↑                                                       ↑     SELL Breakout Level
        04:30 UTC                                    Next 04:30 UTC  (24-hour duration)

1.08350 ─────────────────────────────────────────────────────────
        │                                                         │
        │         Current Price Action                            │
        │                                                         │
1.08300 ─────────────────────────────────────────────────────────

1.08290 ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄  ← 15M Low (Orange)
        ↑                                                       ↑     BUY Breakout Level
        04:30 UTC                                    Next 04:30 UTC  (24-hour duration)

1.08250 ─────────────────────────────────────────────────────────

1.08200 ═════════════════════════════════════════════════════════  ← 4H Low (Red)
        ↑                                                       ↑     BUY Breakout Level
        04:00 UTC                                    Next 04:00 UTC  (24-hour duration)

1.08150 ─────────────────────────────────────────────────────────

        00:00   04:00   08:00   12:00   16:00   20:00   00:00   04:00
                  ↑       ↑                                       ↑
                  │       └─ 4H candle closes (range established) │
                  └───────── 4H range starts ──────────────────────┘
                             (lines extend for 24 hours)
```

## Line Legend

| Line Type | Color | Style | Meaning | Duration | Updates |
|-----------|-------|-------|---------|----------|---------|
| ═════════ | Blue | Solid, Thick | 4H High (SELL breakout) | 04:00 UTC → Next 04:00 UTC | Daily at 04:00 UTC |
| ═════════ | Red | Solid, Thick | 4H Low (BUY breakout) | 04:00 UTC → Next 04:00 UTC | Daily at 04:00 UTC |
| ┄┄┄┄┄┄┄┄┄ | Green | Dotted, Thin | 15M High (SELL breakout) | 04:30 UTC → Next 04:30 UTC | Daily at 04:30 UTC |
| ┄┄┄┄┄┄┄┄┄ | Orange | Dotted, Thin | 15M Low (BUY breakout) | 04:30 UTC → Next 04:30 UTC | Daily at 04:30 UTC |

**Note**: All lines are time-bounded (24-hour duration) and clearly show which trading period each range applies to.

## Breakout Scenarios

### Scenario 1: SELL Signal from 4H Range
```
Price Movement:
1.08500 ─────────────────────────────────────────
                                    ↗ Breakout!
1.08450 ═════════════════════════════════════════  ← 4H High
                              ↗ Close above
1.08400 ─────────────────────────────────────────
              ↗ Price rises
1.08350 ─────────────────────────────────────────
        ↗ Starting inside range
1.08300 ─────────────────────────────────────────

✓ Valid SELL Signal:
  - 5M candle opens INSIDE 4H range
  - 5M candle closes ABOVE 4H high
  - Python bot generates SELL signal
```

### Scenario 2: BUY Signal from 4H Range
```
Price Movement:
1.08300 ─────────────────────────────────────────
        ↘ Starting inside range
1.08250 ─────────────────────────────────────────
              ↘ Price falls
1.08200 ═════════════════════════════════════════  ← 4H Low
                              ↘ Close below
1.08150 ─────────────────────────────────────────
                                    ↘ Breakout!
1.08100 ─────────────────────────────────────────

✓ Valid BUY Signal:
  - 5M candle opens INSIDE 4H range
  - 5M candle closes BELOW 4H low
  - Python bot generates BUY signal
```

### Scenario 3: SELL Signal from 15M Range
```
Price Movement:
1.08400 ─────────────────────────────────────────
                              ↗ Breakout!
1.08380 ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄  ← 15M High
                        ↗ Close above
1.08350 ─────────────────────────────────────────
              ↗ Price rises
1.08320 ─────────────────────────────────────────
        ↗ Starting inside range
1.08290 ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄  ← 15M Low

✓ Valid SELL Signal:
  - 1M candle opens INSIDE 15M range
  - 1M candle closes ABOVE 15M high
  - Python bot generates SELL signal
```

## Daily Timeline

```
UTC Time:  00:00   04:00   04:30   08:00   12:00   16:00   20:00   00:00
           │       │       │       │       │       │       │       │
           │       │       │       │       │       │       │       │
4H Candle: ├───────┼───────┼───────┼───────┼───────┼───────┼───────┤
           │  1st  │  2nd  │       │  3rd  │       │  4th  │       │
           │       │       │       │       │       │       │       │
           │       ↑       │       │       │       │       │       │
           │       │       │       │       │       │       │       │
           │    4H Range   │       │       │       │       │       │
           │   Established │       │       │       │       │       │
           │               │       │       │       │       │       │
15M Candle:├─┬─┬─┬─┼─┬─┬─┬─┼─┬─┬─┬─┼─┬─┬─┬─┼─┬─┬─┬─┼─┬─┬─┬─┼─┬─┬─┬─┤
           │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
           │ │ │ │ │ │ │ │ ↑ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
           │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
           │ │ │ │ │ │ │ │ 15M Range │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
           │ │ │ │ │ │ │ │ Established│ │ │ │ │ │ │ │ │ │ │ │ │ │ │
           │ │ │ │ │ │ │ │ (04:30)    │ │ │ │ │ │ │ │ │ │ │ │ │ │ │

Trading:   │       │       │       │       │       │       │       │
           │       │       │       │       │       │       │       │
           │       │ WAIT  │ ← Trading allowed after 08:00 UTC →  │
           │       │ 04:00-│       │       │       │       │       │
           │       │ 08:00 │       │       │       │       │       │
```

## Info Panel Breakdown

```
┌─────────────────────────────────────┐
│ FMS Range Visualizer                │  ← Indicator name
│ ━━━━━━━━━━━━━━━━━━━━━━              │  ← Separator
│ 4H Range (04:00 UTC):               │  ← Range identifier
│   High: 1.08450                     │  ← SELL breakout level
│   Low:  1.08200                     │  ← BUY breakout level
│   Range: 0.00250                    │  ← Distance between high/low
│   Time: 2025-01-15 04:00            │  ← When this candle formed
│                                     │
│ 15M Range (04:30 UTC):              │  ← Range identifier
│   High: 1.08380                     │  ← SELL breakout level
│   Low:  1.08290                     │  ← BUY breakout level
│   Range: 0.00090                    │  ← Distance between high/low
│   Time: 2025-01-15 04:30            │  ← When this candle formed
└─────────────────────────────────────┘
```

## Multi-Symbol Setup Example

```
Chart 1: EURUSD (5M)          Chart 2: GBPUSD (5M)          Chart 3: USDJPY (5M)
┌──────────────────────┐      ┌──────────────────────┐      ┌──────────────────────┐
│ 4H: 1.08450/1.08200  │      │ 4H: 1.26800/1.26500  │      │ 4H: 148.50/147.80    │
│ 15M: 1.08380/1.08290 │      │ 15M: 1.26720/1.26610 │      │ 15M: 148.30/148.05   │
│                      │      │                      │      │                      │
│ ═════════ 4H High    │      │ ═════════ 4H High    │      │ ═════════ 4H High    │
│ ┄┄┄┄┄┄┄┄┄ 15M High   │      │ ┄┄┄┄┄┄┄┄┄ 15M High   │      │ ┄┄┄┄┄┄┄┄┄ 15M High   │
│                      │      │                      │      │                      │
│   [Price Action]     │      │   [Price Action]     │      │   [Price Action]     │
│                      │      │                      │      │                      │
│ ┄┄┄┄┄┄┄┄┄ 15M Low    │      │ ┄┄┄┄┄┄┄┄┄ 15M Low    │      │ ┄┄┄┄┄┄┄┄┄ 15M Low    │
│ ═════════ 4H Low     │      │ ═════════ 4H Low     │      │ ═════════ 4H Low     │
└──────────────────────┘      └──────────────────────┘      └──────────────────────┘
```

## Color Customization Examples

### Default Theme (Dark Background)
- 4H High: Dodger Blue (bright, stands out)
- 4H Low: Crimson (red, danger zone)
- 15M High: Lime Green (fresh, secondary)
- 15M Low: Orange (warm, secondary)

### Light Background Theme
- 4H High: Dark Blue
- 4H Low: Dark Red
- 15M High: Dark Green
- 15M Low: Dark Orange

### Monochrome Theme
- 4H High: White (thick solid)
- 4H Low: White (thick solid)
- 15M High: Gray (thin dotted)
- 15M Low: Gray (thin dotted)

### High Contrast Theme
- 4H High: Yellow (maximum visibility)
- 4H Low: Magenta (maximum visibility)
- 15M High: Cyan (bright secondary)
- 15M Low: Hot Pink (bright secondary)

---

**Tip**: Experiment with different color schemes to find what works best for your eyes and trading style!

