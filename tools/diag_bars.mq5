//+------------------------------------------------------------------+
//| Diagnostic Script to inspect 2026.06.16 08:15 bars                |
//+------------------------------------------------------------------+
void OnStart() {
   datetime t = D'2026.06.16 08:20';
   int shift = iBarShift(_Symbol, PERIOD_M5, t, false);
   PrintFormat('Shift for %s is %d', TimeToString(t), shift);
   for(int i = shift + 15; i >= shift - 5; i--) {
      PrintFormat('Bar %d [%s] O:%.2f H:%.2f L:%.2f C:%.2f',
                  i, TimeToString(iTime(_Symbol, PERIOD_M5, i)),
                  iOpen(_Symbol, PERIOD_M5, i), iHigh(_Symbol, PERIOD_M5, i),
                  iLow(_Symbol, PERIOD_M5, i), iClose(_Symbol, PERIOD_M5, i));
   }
}
