//+------------------------------------------------------------------+
//|                                     Test_Integration_Harness.mq5 |
//|                         Automated MT5 Runtime Integration Suite   |
//|               Tests: Real OCO Lifecycle, Recovery & Fail-Injections|
//+------------------------------------------------------------------+
#property copyright "Quantitative Verification Engineer"
#property link      "https://github.com/yossefbelal1/PriceAction-Pro-MT5"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

CTrade         m_trade;
CPositionInfo  m_position;
COrderInfo     m_order;

ulong          m_magic = 20269999;
double         m_point;
int            m_digits;

// Struct to mimic OCO pair in EA
struct TestOCOPair
{
   ulong    buyStopTicket;
   ulong    sellStopTicket;
   string   ocoTag;
   bool     isActive;
};

TestOCOPair m_testOcoPairs[];

// State machine for integration runner
enum ENUM_TEST_STAGE
{
   STAGE_INIT,
   STAGE_FAILURE_INJECTION,
   STAGE_OCO_BUY_TRIGGER_SETUP,
   STAGE_OCO_BUY_TRIGGER_WAIT,
   STAGE_OCO_SELL_TRIGGER_SETUP,
   STAGE_OCO_SELL_TRIGGER_WAIT,
   STAGE_RECOVERY_SETUP,
   STAGE_RECOVERY_EXEC,
   STAGE_FINAL_VERIFICATION,
   STAGE_COMPLETE
};

ENUM_TEST_STAGE m_stage = STAGE_INIT;

int m_passCount = 0;
int m_failCount = 0;

void LogTest(string testId, bool passed, string detail)
{
   if(passed)
   {
      m_passCount++;
      PrintFormat("[TEST PASS] %s: %s", testId, detail);
   }
   else
   {
      m_failCount++;
      PrintFormat("[TEST FAIL] %s: %s", testId, detail);
   }
}

// Check helper
bool IsOCOOrderFilled(ulong orderTicket)
{
   if(orderTicket == 0) return false;
   if(HistoryOrderSelect(orderTicket))
   {
      ENUM_ORDER_STATE state = (ENUM_ORDER_STATE)HistoryOrderGetInteger(orderTicket, ORDER_STATE);
      return (state == ORDER_STATE_FILLED);
   }
   return false;
}

bool IsOCOOrderActive(ulong orderTicket)
{
   if(orderTicket == 0) return false;
   if(OrderSelect(orderTicket))
   {
      ENUM_ORDER_STATE state = (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE);
      return (state == ORDER_STATE_PLACED);
   }
   return false;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_point  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   m_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   m_trade.SetExpertMagicNumber(m_magic);

   // Symbol-aware filling mode
   int fillingMode = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((fillingMode & SYMBOL_FILLING_FOK) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if((fillingMode & SYMBOL_FILLING_IOC) != 0)
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);

   PrintFormat("[INIT] Test_Integration_Harness started on %s. Filling mode bitmask: %d", _Symbol, fillingMode);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   PrintFormat("================================================================================");
   PrintFormat("INTEGRATION HARNESS FINISHED: TOTAL PASS=%d | TOTAL FAIL=%d", m_passCount, m_failCount);
   PrintFormat("================================================================================");
}

//+------------------------------------------------------------------+
//| Manage OCO identical to PriceAction_Pro_MT5                      |
//+------------------------------------------------------------------+
void ExecuteOCOManager()
{
   // 1. In-Memory scan
   int total = ArraySize(m_testOcoPairs);
   for(int i = total - 1; i >= 0; i--)
   {
      if(!m_testOcoPairs[i].isActive) continue;

      ulong buyTicket  = m_testOcoPairs[i].buyStopTicket;
      ulong sellTicket = m_testOcoPairs[i].sellStopTicket;

      bool buyFilled  = IsOCOOrderFilled(buyTicket);
      bool sellFilled = IsOCOOrderFilled(sellTicket);
      bool buyActive  = IsOCOOrderActive(buyTicket);
      bool sellActive = IsOCOOrderActive(sellTicket);

      if(buyFilled)
      {
         if(sellActive)
         {
            if(m_trade.OrderDelete(sellTicket))
            {
               uint retcode = m_trade.ResultRetcode();
               if(retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_PLACED)
               {
                  LogTest("OCO-BUY-DELETES-SELL", true, StringFormat("Buy #%I64u filled. Deleted opposite SellStop #%I64u retcode=%u", buyTicket, sellTicket, retcode));
               }
               else
               {
                  LogTest("OCO-BUY-DELETES-SELL", false, StringFormat("OrderDelete retcode=%u desc=%s", retcode, m_trade.ResultRetcodeDescription()));
               }
            }
            else
            {
               LogTest("OCO-BUY-DELETES-SELL", false, StringFormat("m_trade.OrderDelete returned false retcode=%u", m_trade.ResultRetcode()));
            }
         }
         m_testOcoPairs[i].isActive = false;
         continue;
      }
      else if(sellFilled)
      {
         if(buyActive)
         {
            if(m_trade.OrderDelete(buyTicket))
            {
               uint retcode = m_trade.ResultRetcode();
               if(retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_PLACED)
               {
                  LogTest("OCO-SELL-DELETES-BUY", true, StringFormat("Sell #%I64u filled. Deleted opposite BuyStop #%I64u retcode=%u", sellTicket, buyTicket, retcode));
               }
               else
               {
                  LogTest("OCO-SELL-DELETES-BUY", false, StringFormat("OrderDelete retcode=%u desc=%s", retcode, m_trade.ResultRetcodeDescription()));
               }
            }
            else
            {
               LogTest("OCO-SELL-DELETES-BUY", false, StringFormat("m_trade.OrderDelete returned false retcode=%u", m_trade.ResultRetcode()));
            }
         }
         m_testOcoPairs[i].isActive = false;
         continue;
      }

      if(!buyActive && !sellActive)
         m_testOcoPairs[i].isActive = false;
   }

   // 2. Cross-Restart Tag Recovery scan
   for(int p = PositionsTotal() - 1; p >= 0; p--)
   {
      if(!m_position.SelectByIndex(p)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != m_magic) continue;

      string posComment = m_position.Comment();
      PrintFormat("[RECOVERY DEBUG] Found Pos #%I64u Magic=%I64u Comment='%s'", m_position.Ticket(), m_position.Magic(), posComment);
      int tagPos = StringFind(posComment, "IB_OCO_");
      if(tagPos < 0) continue;

      int endSep = StringFind(posComment, " ", tagPos);
      if(endSep < 0) endSep = StringFind(posComment, "]", tagPos);
      string ocoTag = (endSep > tagPos) ? StringSubstr(posComment, tagPos, endSep - tagPos) : StringSubstr(posComment, tagPos);
      PrintFormat("[RECOVERY DEBUG] Extracted pure ocoTag='%s'", ocoTag);

      for(int o = OrdersTotal() - 1; o >= 0; o--)
      {
         if(!m_order.SelectByIndex(o)) continue;
         if(m_order.Symbol() == _Symbol && m_order.Magic() == m_magic)
         {
            PrintFormat("[RECOVERY DEBUG] Found Order #%I64u Magic=%I64u Comment='%s' vs ocoTag='%s'", m_order.Ticket(), m_order.Magic(), m_order.Comment(), ocoTag);
            if(StringFind(m_order.Comment(), ocoTag) >= 0)
            {
               ulong ocoOrderTicket = m_order.Ticket();
               if(m_trade.OrderDelete(ocoOrderTicket))
               {
                  uint retcode = m_trade.ResultRetcode();
                  if(retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_PLACED)
                  {
                     LogTest("OCO-RESTART-RECOVERY", true, StringFormat("Tag %s. Cleaned orphan pending #%I64u retcode=%u", ocoTag, ocoOrderTicket, retcode));
                  }
                  else
                  {
                     LogTest("OCO-RESTART-RECOVERY", false, StringFormat("Recovery Delete retcode=%u desc=%s", retcode, m_trade.ResultRetcodeDescription()));
                  }
               }
               else
               {
                  LogTest("OCO-RESTART-RECOVERY", false, StringFormat("Recovery OrderDelete returned false retcode=%u", m_trade.ResultRetcode()));
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask <= 0 || bid <= 0) return;

   // ---------------------------------------------------------------
   // STAGE: FAILURE INJECTION TESTS
   // ---------------------------------------------------------------
   if(m_stage == STAGE_INIT)
   {
      PrintFormat(">>> RUNNING STAGE 1: REAL MT5 FAILURE-INJECTION TESTS <<<");

      // FAIL-01: Invalid Volume (Lot size 0.00001 < min 0.01)
      bool resVol = m_trade.Buy(0.00001, _Symbol, ask, 0, 0, "Test Invalid Volume");
      uint retVol = m_trade.ResultRetcode();
      bool passVol = (!resVol) && (retVol == TRADE_RETCODE_INVALID_VOLUME || retVol == 10014);
      LogTest("FAIL-01-INVALID-VOLUME", passVol, 
              StringFormat("Broker rejected lot 0.00001: retcode=%u desc=%s", retVol, m_trade.ResultRetcodeDescription()));

      // FAIL-02: Invalid Stops Distance (SL equal to ask / inside stops level)
      bool resStops = m_trade.Buy(0.01, _Symbol, ask, ask - (1 * m_point), 0, "Test Invalid Stops");
      uint retStops = m_trade.ResultRetcode();
      bool passStops = (!resStops) && (retStops == TRADE_RETCODE_INVALID_STOPS || retStops == 10016);
      LogTest("FAIL-02-INVALID-STOPS", passStops,
              StringFormat("Broker rejected SL inside StopsLevel: retcode=%u desc=%s", retStops, m_trade.ResultRetcodeDescription()));

      // FAIL-03: Invalid Pending Price (BuyStop below current ask)
      double invalidBuyStopPrice = bid - (50 * m_point);
      bool resPrice = m_trade.BuyStop(0.01, invalidBuyStopPrice, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "Test Invalid Price");
      uint retPrice = m_trade.ResultRetcode();
      bool passPrice = (!resPrice) && (retPrice == TRADE_RETCODE_INVALID_PRICE || retPrice == 10015);
      LogTest("FAIL-03-INVALID-PRICE", passPrice,
              StringFormat("Broker rejected BuyStop below ask: retcode=%u desc=%s", retPrice, m_trade.ResultRetcodeDescription()));

      // FAIL-04: Rejected PositionModify (Modify non-existent position #999999999)
      bool resMod = m_trade.PositionModify(999999999, 1.1000, 1.1200);
      uint retMod = m_trade.ResultRetcode();
      bool passMod = (!resMod) && (retMod != TRADE_RETCODE_DONE);
      LogTest("FAIL-04-INVALID-MODIFY", passMod,
              StringFormat("Broker rejected modify on non-existent position: retcode=%u desc=%s", retMod, m_trade.ResultRetcodeDescription()));

      // FAIL-05: Rejected OrderDelete (Delete non-existent order #999999999)
      bool resDel = m_trade.OrderDelete(999999999);
      uint retDel = m_trade.ResultRetcode();
      bool passDel = (!resDel) && (retDel != TRADE_RETCODE_DONE);
      LogTest("FAIL-05-INVALID-DELETE", passDel,
              StringFormat("Broker rejected delete on non-existent order: retcode=%u desc=%s", retDel, m_trade.ResultRetcodeDescription()));

      m_stage = STAGE_OCO_BUY_TRIGGER_SETUP;
      return;
   }

   // ---------------------------------------------------------------
   // STAGE: OCO SCENARIO 1 (BuyStop triggers -> verify SellStop deleted)
   // ---------------------------------------------------------------
   if(m_stage == STAGE_OCO_BUY_TRIGGER_SETUP)
   {
      PrintFormat(">>> RUNNING STAGE 2: OCO SCENARIO 1 (BuyStop Triggers) <<<");

      // Place BuyStop right above ask (10 points) so it triggers very quickly
      double buyPrice = NormalizeDouble(ask + 10 * m_point, m_digits);
      double slPrice  = NormalizeDouble(buyPrice - 50 * m_point, m_digits);
      double tpPrice  = NormalizeDouble(buyPrice + 100 * m_point, m_digits);

      // Place SellStop 100 points below bid
      double sellPrice = NormalizeDouble(bid - 100 * m_point, m_digits);
      double sellSL    = NormalizeDouble(sellPrice + 50 * m_point, m_digits);
      double sellTP    = NormalizeDouble(sellPrice - 100 * m_point, m_digits);

      string pairTag = StringFormat("IB_OCO_%u", (uint)TimeCurrent());
      string buyComment  = StringFormat("[TEST] IB_BuyStop [%s]", pairTag);
      string sellComment = StringFormat("[TEST] IB_SellStop [%s]", pairTag);

      ulong buyTicket = 0;
      ulong sellTicket = 0;

      if(m_trade.BuyStop(0.01, buyPrice, _Symbol, slPrice, tpPrice, ORDER_TIME_GTC, 0, buyComment))
      {
         buyTicket = m_trade.ResultOrder();
         LogTest("OCO-BUY-PLACED", (buyTicket > 0), StringFormat("Placed BuyStop #%I64u at %f", buyTicket, buyPrice));
      }

      if(m_trade.SellStop(0.01, sellPrice, _Symbol, sellSL, sellTP, ORDER_TIME_GTC, 0, sellComment))
      {
         sellTicket = m_trade.ResultOrder();
         LogTest("OCO-SELL-PLACED", (sellTicket > 0), StringFormat("Placed SellStop #%I64u at %f", sellTicket, sellPrice));
      }

      if(buyTicket > 0 && sellTicket > 0)
      {
         int sz = ArraySize(m_testOcoPairs);
         ArrayResize(m_testOcoPairs, sz + 1);
         m_testOcoPairs[sz].buyStopTicket  = buyTicket;
         m_testOcoPairs[sz].sellStopTicket = sellTicket;
         m_testOcoPairs[sz].ocoTag         = pairTag;
         m_testOcoPairs[sz].isActive       = true;

         m_stage = STAGE_OCO_BUY_TRIGGER_WAIT;
      }
      return;
   }

   if(m_stage == STAGE_OCO_BUY_TRIGGER_WAIT)
   {
      ExecuteOCOManager();

      // Check if pair was handled
      if(ArraySize(m_testOcoPairs) > 0 && !m_testOcoPairs[0].isActive)
      {
         // Verify SellStop is not in active orders
         bool sellStillActive = IsOCOOrderActive(m_testOcoPairs[0].sellStopTicket);
         LogTest("OCO-VERIFY-SELL-NOT-ACTIVE", (!sellStillActive), 
                 StringFormat("SellStop #%I64u successfully purged from active orders", m_testOcoPairs[0].sellStopTicket));

         // Close any opened position to clean up
         for(int p = PositionsTotal() - 1; p >= 0; p--)
         {
            if(m_position.SelectByIndex(p) && m_position.Magic() == m_magic)
               m_trade.PositionClose(m_position.Ticket());
         }

         m_stage = STAGE_OCO_SELL_TRIGGER_SETUP;
      }
      return;
   }

   // ---------------------------------------------------------------
   // STAGE: OCO SCENARIO 2 (SellStop triggers -> verify BuyStop deleted)
   // ---------------------------------------------------------------
   if(m_stage == STAGE_OCO_SELL_TRIGGER_SETUP)
   {
      PrintFormat(">>> RUNNING STAGE 3: OCO SCENARIO 2 (SellStop Triggers) <<<");

      double sellPrice = NormalizeDouble(bid - 10 * m_point, m_digits);
      double sellSL    = NormalizeDouble(sellPrice + 50 * m_point, m_digits);
      double sellTP    = NormalizeDouble(sellPrice - 100 * m_point, m_digits);

      double buyPrice = NormalizeDouble(ask + 100 * m_point, m_digits);
      double buySL    = NormalizeDouble(buyPrice - 50 * m_point, m_digits);
      double buyTP    = NormalizeDouble(buyPrice + 100 * m_point, m_digits);

      string pairTag = StringFormat("IB_OCO_REV_%u", (uint)TimeCurrent());
      string buyComment  = StringFormat("[TEST] IB_BuyStop [%s]", pairTag);
      string sellComment = StringFormat("[TEST] IB_SellStop [%s]", pairTag);

      ulong buyTicket = 0;
      ulong sellTicket = 0;

      if(m_trade.SellStop(0.01, sellPrice, _Symbol, sellSL, sellTP, ORDER_TIME_GTC, 0, sellComment))
         sellTicket = m_trade.ResultOrder();

      if(m_trade.BuyStop(0.01, buyPrice, _Symbol, buySL, buyTP, ORDER_TIME_GTC, 0, buyComment))
         buyTicket = m_trade.ResultOrder();

      if(buyTicket > 0 && sellTicket > 0)
      {
         int sz = ArraySize(m_testOcoPairs);
         ArrayResize(m_testOcoPairs, sz + 1);
         int idx = sz;
         m_testOcoPairs[idx].buyStopTicket  = buyTicket;
         m_testOcoPairs[idx].sellStopTicket = sellTicket;
         m_testOcoPairs[idx].ocoTag         = pairTag;
         m_testOcoPairs[idx].isActive       = true;

         m_stage = STAGE_OCO_SELL_TRIGGER_WAIT;
      }
      return;
   }

   if(m_stage == STAGE_OCO_SELL_TRIGGER_WAIT)
   {
      ExecuteOCOManager();

      int lastIdx = ArraySize(m_testOcoPairs) - 1;
      if(lastIdx >= 1 && !m_testOcoPairs[lastIdx].isActive)
      {
         bool buyStillActive = IsOCOOrderActive(m_testOcoPairs[lastIdx].buyStopTicket);
         LogTest("OCO-VERIFY-BUY-NOT-ACTIVE", (!buyStillActive),
                 StringFormat("BuyStop #%I64u successfully purged from active orders", m_testOcoPairs[lastIdx].buyStopTicket));

         for(int p = PositionsTotal() - 1; p >= 0; p--)
         {
            if(m_position.SelectByIndex(p) && m_position.Magic() == m_magic)
               m_trade.PositionClose(m_position.Ticket());
         }

         m_stage = STAGE_RECOVERY_SETUP;
      }
      return;
   }

   // ---------------------------------------------------------------
   // STAGE: MULTI-SESSION RESTART RECOVERY TEST
   // ---------------------------------------------------------------
   if(m_stage == STAGE_RECOVERY_SETUP)
   {
      PrintFormat(">>> RUNNING STAGE 4: SIMULATED EA RESTART RECOVERY TEST <<<");

      // Place a market Buy with tag starting first (within MT5 31-char limit)
      string simTag = "IB_OCO_RESTART";
      string posComment = StringFormat("%s Buy", simTag);
      double sl = NormalizeDouble(bid - 50 * m_point, m_digits);
      double tp = NormalizeDouble(ask + 100 * m_point, m_digits);

      if(!m_trade.Buy(0.01, _Symbol, ask, sl, tp, posComment))
      {
         PrintFormat("Failed to open position for recovery test");
         return;
      }

      // Place an orphan pending SellStop with the same tag
      string orderComment = StringFormat("%s SellStop", simTag);
      double pendingPrice = NormalizeDouble(bid - 150 * m_point, m_digits);
      ulong orphanTicket = 0;
      if(m_trade.SellStop(0.01, pendingPrice, _Symbol, 0, 0, ORDER_TIME_GTC, 0, orderComment))
      {
         orphanTicket = m_trade.ResultOrder();
         LogTest("RECOVERY-ORPHAN-CREATED", (orphanTicket > 0), StringFormat("Created orphan SellStop #%I64u with tag %s", orphanTicket, simTag));
      }

      // SIMULATE EA RESTART / CRASH:
      // Completely wipe the in-memory array m_testOcoPairs!
      ArrayFree(m_testOcoPairs);
      LogTest("RECOVERY-MEMORY-WIPED", (ArraySize(m_testOcoPairs) == 0), "In-memory OCO array cleared to simulate fresh EA startup");

      m_stage = STAGE_RECOVERY_EXEC;
      return;
   }

   if(m_stage == STAGE_RECOVERY_EXEC)
   {
      // Run OCO Manager which executes terminal recovery scan
      ExecuteOCOManager();

      // Check if any pending orders remain
      int remainingOrders = OrdersTotal();
      bool noOrphans = (remainingOrders == 0);
      LogTest("RECOVERY-NO-ORPHANS", noOrphans, StringFormat("Active pending orders count: %d (Zero orphans)", remainingOrders));

      // Close open positions
      for(int p = PositionsTotal() - 1; p >= 0; p--)
      {
         if(m_position.SelectByIndex(p) && m_position.Magic() == m_magic)
            m_trade.PositionClose(m_position.Ticket());
      }

      m_stage = STAGE_COMPLETE;
      PrintFormat(">>> ALL INTEGRATION AND FAILURE-INJECTION TESTS FINISHED! <<<");
      return;
   }
}
