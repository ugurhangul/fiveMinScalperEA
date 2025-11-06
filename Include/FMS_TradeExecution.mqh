//+------------------------------------------------------------------+
//|                                        FMS_TradeExecution.mqh |
//|                   Trade Execution Functions for FMS EA           |
//+------------------------------------------------------------------+
#property copyright "FiveMinScalper"
#property link      ""
#property version   "1.00"
#property strict

#include "FMS_Config.mqh"
#include "FMS_GlobalVars.mqh"
#include "FMS_Utilities.mqh"

//+------------------------------------------------------------------+
//| Calculate lot size based on risk management                      |
//+------------------------------------------------------------------+
double CalculateLotSize(double entryPrice, double stopLoss)
{
   if(EnableDetailedLogging)
      LogMessage("--- Calculating Lot Size ---");

   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * (RiskPercentPerTrade / 100.0);

   if(EnableDetailedLogging)
   {
      LogMessage("Account Balance: " + DoubleToString(accountBalance, 2));
      LogMessage("Risk Percent: " + DoubleToString(RiskPercentPerTrade, 2) + "%");
      LogMessage("Risk Amount: " + DoubleToString(riskAmount, 2));
   }

   // Use cached symbol properties for better performance
   double stopLossPoints = MathAbs(entryPrice - stopLoss) / g_symbolPoint;

   if(EnableDetailedLogging)
   {
      LogMessage("Entry Price: " + DoubleToString(entryPrice, _Digits));
      LogMessage("Stop-Loss: " + DoubleToString(stopLoss, _Digits));
      LogMessage("SL Distance: " + DoubleToString(MathAbs(entryPrice - stopLoss), _Digits));
      LogMessage("SL Points: " + DoubleToString(stopLossPoints, 0));
      LogMessage("Point Value: " + DoubleToString(g_symbolTickValue, 2));
   }

   double lotSize = riskAmount / (stopLossPoints * g_symbolTickValue);

   if(EnableDetailedLogging)
      LogMessage("Raw lot size: " + DoubleToString(lotSize, 2));

   // Normalize lot size using cached values
   lotSize = MathFloor(lotSize / g_symbolLotStep) * g_symbolLotStep;
   // Ensure both symbol AND user minimums/maximums are respected
   lotSize = MathMax(lotSize, MathMax(g_symbolMinLot, MinLotSize));
   lotSize = MathMin(lotSize, MathMin(g_symbolMaxLot, MaxLotSize));

   if(EnableDetailedLogging)
   {
      LogMessage("Symbol Min Lot: " + DoubleToString(g_symbolMinLot, 2));
      LogMessage("Symbol Max Lot: " + DoubleToString(g_symbolMaxLot, 2));
      LogMessage("Lot Step: " + DoubleToString(g_symbolLotStep, 2));
      LogMessage("Final lot size: " + DoubleToString(lotSize, 2));
   }

   return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate optimized stop-loss for BUY order                      |
//+------------------------------------------------------------------+
double CalculateOptimizedBuySL(double lowestLow, double entryPrice, datetime breakoutTime, datetime reversalTime)
{
   // Calculate SL using the lowest low with offset
   double stopLoss = lowestLow - (lowestLow * StopLossOffsetPercent / 100.0);
   double risk = entryPrice - stopLoss;

   LogMessage("=== Calculating BUY Stop-Loss ===");
   LogMessage("Entry Price: " + DoubleToString(entryPrice, _Digits));
   LogMessage("Lowest Low in pattern: " + DoubleToString(lowestLow, _Digits));
   LogMessage("Stop-Loss: " + DoubleToString(stopLoss, _Digits));
   LogMessage("Risk: " + DoubleToString(risk, _Digits));

   return stopLoss;
}

//+------------------------------------------------------------------+
//| Calculate optimized stop-loss for SELL order                     |
//+------------------------------------------------------------------+
double CalculateOptimizedSellSL(double highestHigh, double entryPrice, datetime breakoutTime, datetime reversalTime)
{
   // Calculate SL using the highest high with offset
   double stopLoss = highestHigh + (highestHigh * StopLossOffsetPercent / 100.0);
   double risk = stopLoss - entryPrice;

   LogMessage("=== Calculating SELL Stop-Loss ===");
   LogMessage("Entry Price: " + DoubleToString(entryPrice, _Digits));
   LogMessage("Highest High in pattern: " + DoubleToString(highestHigh, _Digits));
   LogMessage("Stop-Loss: " + DoubleToString(stopLoss, _Digits));
   LogMessage("Risk: " + DoubleToString(risk, _Digits));

   return stopLoss;
}

//+------------------------------------------------------------------+
//| Execute buy order                                                |
//+------------------------------------------------------------------+
bool ExecuteBuyOrder(double lowestLow, datetime breakoutTime, datetime reversalTime)
{
   LogMessage("--- Executing BUY Order ---");

   double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // Calculate optimized stop-loss
   double stopLoss = CalculateOptimizedBuySL(lowestLow, currentAsk, breakoutTime, reversalTime);
   double risk = currentAsk - stopLoss;
   double takeProfit = currentAsk + (risk * RiskRewardRatio);

   LogMessage("=== Final Order Parameters ===");
   LogMessage("Entry Price: " + DoubleToString(currentAsk, _Digits));
   LogMessage("Final SL: " + DoubleToString(stopLoss, _Digits));
   LogMessage("Final Risk: " + DoubleToString(risk, _Digits) + " points");
   LogMessage("Final TP: " + DoubleToString(takeProfit, _Digits) + " (Risk × " + DoubleToString(RiskRewardRatio, 2) + ")");

   // Validate SL/TP
   if(stopLoss <= 0 || takeProfit <= 0 || stopLoss >= currentAsk)
   {
      LogMessage("ERROR: Invalid SL/TP levels. SL=" + DoubleToString(stopLoss, _Digits) + ", TP=" + DoubleToString(takeProfit, _Digits));
      return false;
   }

   double lotSize = CalculateLotSize(currentAsk, stopLoss);
   LogMessage("Calculated lot size: " + DoubleToString(lotSize, 2));

   if(lotSize < MinLotSize)
   {
      LogMessage("ERROR: Calculated lot size (" + DoubleToString(lotSize, 2) + ") is below minimum (" + DoubleToString(MinLotSize, 2) + ")");
      return false;
   }

   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = ORDER_TYPE_BUY;
   request.price = currentAsk;
   request.sl = NormalizePrice(stopLoss);
   request.tp = NormalizePrice(takeProfit);
   request.deviation = 10;
   request.magic = MagicNumber;
   request.comment = TradeComment;
   request.type_filling = ORDER_FILLING_FOK;

   LogMessage("Order Request Details:");
   LogMessage("  Symbol: " + request.symbol);
   LogMessage("  Volume: " + DoubleToString(request.volume, 2));
   LogMessage("  Type: BUY");
   LogMessage("  Price: " + DoubleToString(request.price, _Digits));
   LogMessage("  Stop-Loss: " + DoubleToString(request.sl, _Digits));
   LogMessage("  Take-Profit: " + DoubleToString(request.tp, _Digits));
   LogMessage("  Magic: " + IntegerToString(request.magic));

   if(!OrderSend(request, result))
   {
      LogMessage("ERROR: OrderSend failed. Error code: " + IntegerToString(GetLastError()));
      LogMessage("Result code: " + IntegerToString(result.retcode) + " | " + result.comment);
      return false;
   }

   LogMessage("OrderSend result code: " + IntegerToString(result.retcode));
   LogMessage("Result comment: " + result.comment);

   if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
   {
      LogMessage("SUCCESS: Buy order executed");
      LogMessage("  Ticket: " + IntegerToString(result.order));
      LogMessage("  Execution Price: " + DoubleToString(result.price, _Digits));
      LogMessage("  Volume: " + DoubleToString(result.volume, 2));

      LogTrade("BUY", result.order, lotSize, result.price, stopLoss, takeProfit);
      return true;
   }

   LogMessage("Order not executed. Return code: " + IntegerToString(result.retcode));
   return false;
}

//+------------------------------------------------------------------+
//| Execute sell order                                               |
//+------------------------------------------------------------------+
bool ExecuteSellOrder(double highestHigh, datetime breakoutTime, datetime reversalTime)
{
   LogMessage("--- Executing SELL Order ---");

   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Calculate optimized stop-loss
   double stopLoss = CalculateOptimizedSellSL(highestHigh, currentBid, breakoutTime, reversalTime);
   double risk = stopLoss - currentBid;
   double takeProfit = currentBid - (risk * RiskRewardRatio);

   LogMessage("=== Final Order Parameters ===");
   LogMessage("Entry Price: " + DoubleToString(currentBid, _Digits));
   LogMessage("Final SL: " + DoubleToString(stopLoss, _Digits));
   LogMessage("Final Risk: " + DoubleToString(risk, _Digits) + " points");
   LogMessage("Final TP: " + DoubleToString(takeProfit, _Digits) + " (Risk × " + DoubleToString(RiskRewardRatio, 2) + ")");

   // Validate SL/TP
   if(stopLoss <= 0 || takeProfit <= 0 || stopLoss <= currentBid)
   {
      LogMessage("ERROR: Invalid SL/TP levels. SL=" + DoubleToString(stopLoss, _Digits) + ", TP=" + DoubleToString(takeProfit, _Digits));
      return false;
   }

   double lotSize = CalculateLotSize(currentBid, stopLoss);
   LogMessage("Calculated lot size: " + DoubleToString(lotSize, 2));

   if(lotSize < MinLotSize)
   {
      LogMessage("ERROR: Calculated lot size (" + DoubleToString(lotSize, 2) + ") is below minimum (" + DoubleToString(MinLotSize, 2) + ")");
      return false;
   }

   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = ORDER_TYPE_SELL;
   request.price = currentBid;
   request.sl = NormalizePrice(stopLoss);
   request.tp = NormalizePrice(takeProfit);
   request.deviation = 10;
   request.magic = MagicNumber;
   request.comment = TradeComment;
   request.type_filling = ORDER_FILLING_FOK;

   LogMessage("Order Request Details:");
   LogMessage("  Symbol: " + request.symbol);
   LogMessage("  Volume: " + DoubleToString(request.volume, 2));
   LogMessage("  Type: SELL");
   LogMessage("  Price: " + DoubleToString(request.price, _Digits));
   LogMessage("  Stop-Loss: " + DoubleToString(request.sl, _Digits));
   LogMessage("  Take-Profit: " + DoubleToString(request.tp, _Digits));
   LogMessage("  Magic: " + IntegerToString(request.magic));

   if(!OrderSend(request, result))
   {
      LogMessage("ERROR: OrderSend failed. Error code: " + IntegerToString(GetLastError()));
      LogMessage("Result code: " + IntegerToString(result.retcode) + " | " + result.comment);
      return false;
   }

   LogMessage("OrderSend result code: " + IntegerToString(result.retcode));
   LogMessage("Result comment: " + result.comment);

   if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
   {
      LogMessage("SUCCESS: Sell order executed");
      LogMessage("  Ticket: " + IntegerToString(result.order));
      LogMessage("  Execution Price: " + DoubleToString(result.price, _Digits));
      LogMessage("  Volume: " + DoubleToString(result.volume, 2));

      LogTrade("SELL", result.order, lotSize, result.price, stopLoss, takeProfit);
      return true;
   }

   LogMessage("Order not executed. Return code: " + IntegerToString(result.retcode));
   return false;
}

//+------------------------------------------------------------------+

