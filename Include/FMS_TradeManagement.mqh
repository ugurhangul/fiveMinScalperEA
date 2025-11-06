//+------------------------------------------------------------------+
//|                                        FMS_TradeManagement.mqh |
//|                   Trade Management Functions for FMS EA          |
//+------------------------------------------------------------------+
#property copyright "FiveMinScalper"
#property link      ""
#property version   "1.00"
#property strict

#include "FMS_Config.mqh"
#include "FMS_GlobalVars.mqh"
#include "FMS_Utilities.mqh"

//+------------------------------------------------------------------+
//| Check if ticket is in breakeven list - OPTIMIZED                 |
//+------------------------------------------------------------------+
bool IsTicketInBreakevenList(ulong ticket)
{
   int size = ArraySize(g_breakevenSetTickets);
   for(int i = 0; i < size; i++)
   {
      if(g_breakevenSetTickets[i] == ticket)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Add ticket to breakeven list - OPTIMIZED                         |
//+------------------------------------------------------------------+
void AddTicketToBreakevenList(ulong ticket)
{
   // Check if already exists to avoid duplicates
   if(IsTicketInBreakevenList(ticket))
      return;

   int size = ArraySize(g_breakevenSetTickets);
   ArrayResize(g_breakevenSetTickets, size + 1);
   g_breakevenSetTickets[size] = ticket;

   if(EnableDetailedLogging)
      LogMessage("Position #" + IntegerToString(ticket) + " added to breakeven tracking list");
}

//+------------------------------------------------------------------+
//| Remove ticket from breakeven list - OPTIMIZED (swap and pop)     |
//+------------------------------------------------------------------+
void RemoveTicketFromBreakevenList(ulong ticket)
{
   int size = ArraySize(g_breakevenSetTickets);

   for(int i = 0; i < size; i++)
   {
      if(g_breakevenSetTickets[i] == ticket)
      {
         // Swap with last element and reduce size (faster than shifting)
         g_breakevenSetTickets[i] = g_breakevenSetTickets[size - 1];
         ArrayResize(g_breakevenSetTickets, size - 1);

         if(EnableDetailedLogging)
            LogMessage("Position #" + IntegerToString(ticket) + " removed from breakeven tracking list");

         return;
      }
   }
}

//+------------------------------------------------------------------+
//| Clear breakeven tracking list                                    |
//+------------------------------------------------------------------+
void ClearBreakevenList()
{
   ArrayResize(g_breakevenSetTickets, 0);
   LogMessage("Breakeven tracking list cleared");
}

//+------------------------------------------------------------------+
//| Check if ticket has trailing stop activated - OPTIMIZED          |
//+------------------------------------------------------------------+
bool IsTrailingStopActive(ulong ticket)
{
   int size = ArraySize(g_trailingStopActiveTickets);
   for(int i = 0; i < size; i++)
   {
      if(g_trailingStopActiveTickets[i] == ticket)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Add ticket to trailing stop active list - OPTIMIZED              |
//+------------------------------------------------------------------+
void ActivateTrailingStop(ulong ticket)
{
   // Check if already exists to avoid duplicates
   if(IsTrailingStopActive(ticket))
      return;

   int size = ArraySize(g_trailingStopActiveTickets);
   ArrayResize(g_trailingStopActiveTickets, size + 1);
   g_trailingStopActiveTickets[size] = ticket;

   LogMessage("Trailing stop ACTIVATED for position #" + IntegerToString(ticket));
}

//+------------------------------------------------------------------+
//| Remove ticket from trailing stop list - OPTIMIZED (swap and pop) |
//+------------------------------------------------------------------+
void DeactivateTrailingStop(ulong ticket)
{
   int size = ArraySize(g_trailingStopActiveTickets);

   for(int i = 0; i < size; i++)
   {
      if(g_trailingStopActiveTickets[i] == ticket)
      {
         // Swap with last element and reduce size (faster than shifting)
         g_trailingStopActiveTickets[i] = g_trailingStopActiveTickets[size - 1];
         ArrayResize(g_trailingStopActiveTickets, size - 1);

         if(EnableDetailedLogging)
            LogMessage("Position #" + IntegerToString(ticket) + " removed from trailing stop tracking");

         return;
      }
   }
}

//+------------------------------------------------------------------+
//| Clear trailing stop tracking list                                |
//+------------------------------------------------------------------+
void ClearTrailingStopList()
{
   ArrayResize(g_trailingStopActiveTickets, 0);
   LogMessage("Trailing stop tracking list cleared");
}

//+------------------------------------------------------------------+
//| Clean up closed positions from tracking lists                    |
//+------------------------------------------------------------------+
void CleanupClosedPositions()
{
   // Clean up breakeven tracking
   int beSize = ArraySize(g_breakevenSetTickets);
   for(int i = beSize - 1; i >= 0; i--)
   {
      ulong ticket = g_breakevenSetTickets[i];

      // Try to select the position
      if(!PositionSelectByTicket(ticket))
      {
         // Position no longer exists - remove from list
         RemoveTicketFromBreakevenList(ticket);
         LogMessage("Position #" + IntegerToString(ticket) + " closed - removed from breakeven tracking");
      }
   }

   // Clean up trailing stop tracking
   int tsSize = ArraySize(g_trailingStopActiveTickets);
   for(int i = tsSize - 1; i >= 0; i--)
   {
      ulong ticket = g_trailingStopActiveTickets[i];

      // Try to select the position
      if(!PositionSelectByTicket(ticket))
      {
         // Position no longer exists - remove from list
         DeactivateTrailingStop(ticket);
         LogMessage("Position #" + IntegerToString(ticket) + " closed - removed from trailing stop tracking");
      }
   }
}

//+------------------------------------------------------------------+
//| Move stop-loss to breakeven - OPTIMIZED with PositionInfo        |
//+------------------------------------------------------------------+
void MoveToBreakevenOptimized(PositionInfo &posInfo)
{
   string posTypeStr = (posInfo.type == POSITION_TYPE_BUY) ? "BUY" : "SELL";

   if(EnableDetailedLogging)
   {
      LogMessage("Checking breakeven for ticket " + IntegerToString(posInfo.ticket) + " (" + posTypeStr + ")");
      LogMessage("  Open: " + DoubleToString(posInfo.openPrice, _Digits) + " | Current: " + DoubleToString(posInfo.currentPrice, _Digits));
      LogMessage("  Current SL: " + DoubleToString(posInfo.sl, _Digits) + " | TP: " + DoubleToString(posInfo.tp, _Digits));
      LogMessage("  Risk: " + DoubleToString(posInfo.risk, _Digits) + " | Profit: " + DoubleToString(posInfo.currentPnL, _Digits));
      LogMessage("  Profit R:R: " + DoubleToString(posInfo.currentRR, 2) + " | Trigger: " + DoubleToString(BreakevenTriggerRR, 2));
   }

   // Check if profit has reached the breakeven trigger threshold
   if(posInfo.currentPnL >= posInfo.risk * BreakevenTriggerRR)
   {
      // Check if SL is not already at breakeven
      bool needsUpdate = false;

      if(posInfo.type == POSITION_TYPE_BUY && posInfo.sl < posInfo.openPrice)
         needsUpdate = true;
      else if(posInfo.type == POSITION_TYPE_SELL && posInfo.sl > posInfo.openPrice)
         needsUpdate = true;

      if(needsUpdate)
      {
         LogMessage("*** MOVING STOP-LOSS TO BREAKEVEN ***");
         LogMessage("Ticket: " + IntegerToString(posInfo.ticket) + " | Type: " + posTypeStr);

         MqlTradeRequest request = {};
         MqlTradeResult result = {};

         request.action = TRADE_ACTION_SLTP;
         request.position = posInfo.ticket;
         request.symbol = _Symbol;
         request.sl = NormalizePrice(posInfo.openPrice);
         request.tp = posInfo.tp;

         LogMessage("Modifying SL from " + DoubleToString(posInfo.sl, _Digits) + " to " + DoubleToString(posInfo.openPrice, _Digits));

         if(OrderSend(request, result))
         {
            if(result.retcode == TRADE_RETCODE_DONE)
            {
               LogMessage("SUCCESS: SL moved to breakeven for ticket " + IntegerToString(posInfo.ticket));

               // Add ticket to breakeven tracking list to prevent redundant checks
               AddTicketToBreakevenList(posInfo.ticket);
               LogMessage("Position #" + IntegerToString(posInfo.ticket) + " will not be checked for breakeven again");
            }
            else
            {
               LogMessage("WARNING: Modify result code: " + IntegerToString(result.retcode) + " | " + result.comment);
            }
         }
         else
         {
            LogMessage("ERROR: Failed to move SL to breakeven. Error: " + IntegerToString(GetLastError()));
            LogMessage("Result: " + IntegerToString(result.retcode) + " | " + result.comment);
         }
      }
      else if(EnableDetailedLogging)
      {
         LogMessage("SL already at or beyond breakeven - no update needed");
      }
   }
}

//+------------------------------------------------------------------+
//| Apply trailing stop - OPTIMIZED with PositionInfo                |
//+------------------------------------------------------------------+
void ApplyTrailingStopOptimized(PositionInfo &posInfo)
{
   string posTypeStr = (posInfo.type == POSITION_TYPE_BUY) ? "BUY" : "SELL";

   // Check if profit has reached the trailing stop trigger threshold
   if(posInfo.currentRR >= TrailingStopTriggerRR)
   {
      // Check if trailing stop is not yet activated for this position
      bool isFirstActivation = false;
      if(!IsTrailingStopActive(posInfo.ticket))
      {
         ActivateTrailingStop(posInfo.ticket);
         isFirstActivation = true;
      }

      // Calculate new trailing stop level
      double newSL = 0;
      bool needsUpdate = false;

      if(posInfo.type == POSITION_TYPE_BUY)
      {
         // For BUY: Trail below current price
         newSL = posInfo.currentPrice - TrailingStopDistance * g_symbolPoint;

         // Only update if new SL is higher than current SL
         if(newSL > posInfo.sl)
            needsUpdate = true;
      }
      else  // SELL
      {
         // For SELL: Trail above current price
         newSL = posInfo.currentPrice + TrailingStopDistance * g_symbolPoint;

         // Only update if new SL is lower than current SL
         if(newSL < posInfo.sl || posInfo.sl == 0)
            needsUpdate = true;
      }

      if(needsUpdate)
      {
         LogMessage("*** UPDATING TRAILING STOP ***");
         LogMessage("Ticket: " + IntegerToString(posInfo.ticket) + " | Type: " + posTypeStr);
         LogMessage("Current Price: " + DoubleToString(posInfo.currentPrice, _Digits));
         LogMessage("Current SL: " + DoubleToString(posInfo.sl, _Digits));
         LogMessage("New SL: " + DoubleToString(newSL, _Digits));
         LogMessage("Trailing Distance: " + DoubleToString(TrailingStopDistance, 0) + " points");

         if(isFirstActivation)
         {
            LogMessage("Take-Profit removed - position will be managed by trailing stop only");
         }

         MqlTradeRequest request = {};
         MqlTradeResult result = {};

         request.action = TRADE_ACTION_SLTP;
         request.position = posInfo.ticket;
         request.symbol = _Symbol;
         request.sl = NormalizePrice(newSL);
         request.tp = 0;  // Remove TP when trailing stop is active

         if(OrderSend(request, result))
         {
            if(result.retcode == TRADE_RETCODE_DONE)
            {
               LogMessage("SUCCESS: Trailing stop updated for ticket " + IntegerToString(posInfo.ticket));
            }
            else
            {
               LogMessage("WARNING: Modify result code: " + IntegerToString(result.retcode) + " | " + result.comment);
            }
         }
         else
         {
            LogMessage("ERROR: Failed to update trailing stop. Error: " + IntegerToString(GetLastError()));
            LogMessage("Result: " + IntegerToString(result.retcode) + " | " + result.comment);
         }
      }
      else if(EnableDetailedLogging)
      {
         LogMessage("Trailing stop for #" + IntegerToString(posInfo.ticket) + " - no update needed (SL: " +
                   DoubleToString(posInfo.sl, _Digits) + ")");
      }
   }
}

//+------------------------------------------------------------------+
//| Apply trailing stop (legacy function for compatibility)          |
//+------------------------------------------------------------------+
void ApplyTrailingStop(ulong ticket)
{
   if(!PositionSelectByTicket(ticket))
   {
      LogMessage("ApplyTrailingStop: Failed to select position " + IntegerToString(ticket));
      return;
   }

   // Create PositionInfo and call optimized version
   PositionInfo posInfo;
   posInfo.ticket = ticket;
   posInfo.type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   posInfo.openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   posInfo.sl = PositionGetDouble(POSITION_SL);
   posInfo.tp = PositionGetDouble(POSITION_TP);
   posInfo.currentPrice = (posInfo.type == POSITION_TYPE_BUY) ?
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   posInfo.risk = MathAbs(posInfo.openPrice - posInfo.sl);
   posInfo.currentPnL = (posInfo.type == POSITION_TYPE_BUY) ?
                        (posInfo.currentPrice - posInfo.openPrice) :
                        (posInfo.openPrice - posInfo.currentPrice);
   posInfo.currentRR = (posInfo.risk > 0) ? (posInfo.currentPnL / posInfo.risk) : 0;

   ApplyTrailingStopOptimized(posInfo);
}

//+------------------------------------------------------------------+
//| Manage open positions (breakeven, trailing, etc.) - OPTIMIZED    |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   // Note: This function is called when (UseBreakeven OR UseTrailingStop) AND PositionsTotal()>0

   int totalPositions = PositionsTotal();

   if(EnableDetailedLogging)
      LogMessage("ManageOpenPositions: Checking " + IntegerToString(totalPositions) + " position(s)");

   for(int i = totalPositions - 1; i >= 0; i--)
   {
      PositionInfo posInfo;

      // Get all position info at once (optimized - single query)
      if(!GetPositionInfo(i, posInfo))
         continue;

      // Move stop-loss to breakeven if enabled and not already done
      if(UseBreakeven)
      {
         // Check if this position already has breakeven set
         if(!IsTicketInBreakevenList(posInfo.ticket))
         {
            // Move stop-loss to breakeven
            MoveToBreakevenOptimized(posInfo);
         }
         else if(EnableDetailedLogging)
         {
            LogMessage("Position #" + IntegerToString(posInfo.ticket) + " already at breakeven - skipping breakeven check");
         }
      }

      // Apply trailing stop if enabled (runs AFTER breakeven check)
      if(UseTrailingStop)
      {
         ApplyTrailingStopOptimized(posInfo);
      }
   }
}

//+------------------------------------------------------------------+
