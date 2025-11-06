//+------------------------------------------------------------------+
//|                                              FMS_Utilities.mqh |
//|                          Utility Functions for FMS EA            |
//+------------------------------------------------------------------+
#property copyright "FiveMinScalper"
#property link      ""
#property version   "1.00"
#property strict

#include "FMS_Config.mqh"
#include "FMS_GlobalVars.mqh"

//+------------------------------------------------------------------+
//| Helper function to get position info (reduces redundant queries) |
//+------------------------------------------------------------------+
bool GetPositionInfo(int index, PositionInfo &info)
{
   ulong ticket = PositionGetTicket(index);
   if(ticket <= 0)
      return false;

   if(PositionGetString(POSITION_SYMBOL) != _Symbol)
      return false;

   if(PositionGetInteger(POSITION_MAGIC) != MagicNumber)
      return false;

   // Fill structure with all position data in one go
   info.ticket = ticket;
   info.type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   info.volume = PositionGetDouble(POSITION_VOLUME);
   info.openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   info.sl = PositionGetDouble(POSITION_SL);
   info.tp = PositionGetDouble(POSITION_TP);
   info.profit = PositionGetDouble(POSITION_PROFIT);
   info.openTime = (datetime)PositionGetInteger(POSITION_TIME);

   // Calculate current price based on position type
   info.currentPrice = (info.type == POSITION_TYPE_BUY) ?
                       SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                       SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // Calculate risk and P&L
   info.risk = MathAbs(info.openPrice - info.sl);
   info.currentPnL = (info.type == POSITION_TYPE_BUY) ?
                     (info.currentPrice - info.openPrice) :
                     (info.openPrice - info.currentPrice);
   info.currentRR = (info.risk > 0) ? (info.currentPnL / info.risk) : 0;

   return true;
}

//+------------------------------------------------------------------+
//| Check if a new 5-minute candle has formed                       |
//+------------------------------------------------------------------+
bool IsNew5MinCandle()
{
   datetime current5MinTime = iTime(_Symbol, PERIOD_M5, 0);

   if(current5MinTime != g_last5MinCandleTime)
   {
      if(g_last5MinCandleTime != 0)  // Skip the first call on initialization
      {
         if(EnableDetailedLogging)
         {
            LogMessage("New 5-min candle closed at: " + TimeToString(current5MinTime, TIME_DATE|TIME_MINUTES));
         }

         g_last5MinCandleTime = current5MinTime;
         return true;
      }
      else
      {
         // First initialization - just set the time
         g_last5MinCandleTime = current5MinTime;
         return false;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if a new 4-hour candle has formed                         |
//+------------------------------------------------------------------+
bool IsNew4HCandle()
{
   datetime current4HTime = iTime(_Symbol, PERIOD_H4, 0);

   // Check if we've seen a new 4H candle (different from last seen)
   if(current4HTime != g_lastSeen4HCandleTime && g_lastSeen4HCandleTime != 0)
   {
      datetime closedCandleTime = iTime(_Symbol, PERIOD_H4, 1);
      MqlDateTime timeStruct;
      TimeToStruct(closedCandleTime, timeStruct);

      LogMessage("=== NEW 4H CANDLE DETECTED ===");
      LogMessage("Closed candle time: " + TimeToString(closedCandleTime, TIME_DATE|TIME_MINUTES) + " UTC (Hour: " + IntegerToString(timeStruct.hour) + ")");
      LogMessage("Current candle time: " + TimeToString(current4HTime, TIME_DATE|TIME_MINUTES) + " UTC");
      LogMessage("Last seen time: " + TimeToString(g_lastSeen4HCandleTime, TIME_DATE|TIME_MINUTES) + " UTC");
      LogMessage("Last processed time: " + TimeToString(g_last4HCandleTime, TIME_DATE|TIME_MINUTES) + " UTC");

      // Update last seen time (even if we skip this candle)
      g_lastSeen4HCandleTime = current4HTime;

      // If filter is enabled, only process second 4H candle of day
      // NOTE: Both iTime() and chart display opening time (04:00 UTC)
      // Second 4H candle: opens 04:00 UTC, closes 08:00 UTC
      if(UseOnly00UTCCandle)
      {
         // Check if the closed candle opened at 04:00 UTC (second 4H candle)
         if(timeStruct.hour != 4)
         {
            LogMessage("SKIPPING: Candle opening hour is " + IntegerToString(timeStruct.hour) + ":00 UTC");
            LogMessage("Only processing second 4H candle (opens 04:00 UTC, chart shows 04:00 UTC)");
            LogMessage("Updated g_lastSeen4HCandleTime but NOT g_last4HCandleTime");
            return false;
         }
         else
         {
            LogMessage("PROCESSING: Second 4H candle of day detected");
            LogMessage("Opening time: 04:00 UTC (shown on chart), Closing time: 08:00 UTC");
         }
      }
      else
      {
         LogMessage("PROCESSING: No time filter - This candle will be processed");
      }

      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if there's an open position of specified type              |
//+------------------------------------------------------------------+
bool HasOpenPosition(ENUM_ORDER_TYPE orderType)
{
   ENUM_POSITION_TYPE posType = (orderType == ORDER_TYPE_BUY) ?
                                 POSITION_TYPE_BUY :
                                 POSITION_TYPE_SELL;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
         PositionGetInteger(POSITION_TYPE) == posType)
      {
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if in restricted trading period (04:00-08:00 UTC)          |
//| Trading is suspended only while the second 4H candle is forming  |
//+------------------------------------------------------------------+
bool IsInCandleFormationPeriod()
{
   MqlDateTime currentTime;
   TimeToStruct(TimeCurrent(), currentTime);
   return (currentTime.hour >= 4 && currentTime.hour < 8);
}

//+------------------------------------------------------------------+
//| Check if current time is within trading hours                    |
//+------------------------------------------------------------------+
bool IsWithinTradingHours()
{
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);

   int currentHour = timeStruct.hour;

   if(StartHour <= EndHour)
   {
      return (currentHour >= StartHour && currentHour <= EndHour);
   }
   else
   {
      // Handle overnight trading hours (e.g., 22:00 to 02:00)
      return (currentHour >= StartHour || currentHour <= EndHour);
   }
}

//+------------------------------------------------------------------+
//| Normalize price to symbol's digit precision                      |
//+------------------------------------------------------------------+
double NormalizePrice(double price)
{
   // Use cached symbol digits for better performance
   return NormalizeDouble(price, g_symbolDigits);
}

//+------------------------------------------------------------------+
//| Centralized logging function (optimized with persistent handle)  |
//+------------------------------------------------------------------+
void LogMessage(string message)
{
   string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   string fullMessage = "[" + timestamp + "] " + message;

   // Print to console
   if(LogToConsole)
   {
      Print(fullMessage);
   }

   // Write to file using persistent handle (much faster than open/close each time)
   if(LogToFile)
   {
      // Open file handle if not already open
      if(g_logFileHandle == INVALID_HANDLE)
      {
         g_logFileHandle = FileOpen("FiveMinScalper_Log.txt", FILE_WRITE|FILE_READ|FILE_TXT|FILE_ANSI);
         if(g_logFileHandle != INVALID_HANDLE)
         {
            FileSeek(g_logFileHandle, 0, SEEK_END);
         }
         else
         {
            Print("ERROR: Failed to open log file. Error: ", GetLastError());
            return;
         }
      }

      // Write to file
      FileWriteString(g_logFileHandle, fullMessage + "\n");

      // Flush every 10 messages or every 5 seconds for safety
      static int messageCount = 0;
      static datetime lastFlush = 0;
      messageCount++;

      if(messageCount >= 10 || TimeCurrent() - lastFlush >= 5)
      {
         FileFlush(g_logFileHandle);
         messageCount = 0;
         lastFlush = TimeCurrent();
      }
   }
}

//+------------------------------------------------------------------+
//| Log trade to journal - OPTIMIZED with StringFormat               |
//+------------------------------------------------------------------+
void LogTrade(string direction, ulong ticket, double lotSize, double entryPrice, double sl, double tp)
{
   // Use StringFormat for better performance than string concatenation
   string logMessage = StringFormat(
      "========================================\n"
      "=== TRADE EXECUTED ===\n"
      "Time: %s\n"
      "Direction: %s\n"
      "Ticket: %I64u\n"
      "Symbol: %s\n"
      "Lot Size: %.2f\n"
      "Entry Price: %.*f\n"
      "Stop-Loss: %.*f\n"
      "Take-Profit: %.*f\n"
      "Risk: %.*f\n"
      "Potential Reward: %.*f\n"
      "R:R Ratio: 1:%.2f\n"
      "4H Candle High: %.*f\n"
      "4H Candle Low: %.*f\n"
      "Account Balance: %.2f\n"
      "========================================",
      TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
      direction,
      ticket,
      _Symbol,
      lotSize,
      _Digits, entryPrice,
      _Digits, sl,
      _Digits, tp,
      _Digits, MathAbs(entryPrice - sl),
      _Digits, MathAbs(tp - entryPrice),
      RiskRewardRatio,
      _Digits, g_4HHigh,
      _Digits, g_4HLow,
      AccountInfoDouble(ACCOUNT_BALANCE)
   );

   LogMessage(logMessage);
}

//+------------------------------------------------------------------+

