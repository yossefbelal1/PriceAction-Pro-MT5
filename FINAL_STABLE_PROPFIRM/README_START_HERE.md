# 🚀 الدليل الرسمي الشامل لحزمة التداول المؤسسي (Final Stable PropFirm Package)

أهلاً بك في الحزمة الرسمية المعتمدة لحسابات التمويل والتداول الحي على منصتي **MetaTrader 5** و **MetaTrader 4**.
تم تدقيق واختبار كافة مكونات هذه الحزمة على **100% تيكات حقيقية من سيرفر البروكر (102.9 مليون تيك حقيقي - Model 4)** لضمان الصمود الكامل والاجتياز السلس لاختبارات كبرى شركات التمويل العالمية (FTMO, FundedNext, FundingPips, The5ers).

---

## 📁 خريطة المستودع وهيكل المجلدات (Repository Tree)

```text
FINAL_STABLE_PROPFIRM/
│
├── 01_EXPERTS_MT5/                                [إكسبيرتات الميتاتريدر 5 المعتمدة]
│   ├── Aurum_Imperium_Apex_v8.0.ex5              [⭐ بطل الذهب المعتمد - أعلى استقرار على التيكات الحقيقية]
│   ├── Aurum_Imperium_Apex_v8.0.mq5              [السورس كود المفتوح للنسخة v8.0]
│   ├── Aurum_Imperium_Apex_v9.0_MTF.ex5          [النسخة المتقدمة بالفريمات المتعددة والدعم والمقاومة]
│   ├── Aurum_Imperium_Apex_v9.0_MTF.mq5          [السورس كود المفتوح للنسخة v9.0]
│   ├── Ultimate_ICT_Gold_Scalper_v3.1.ex5        [إكسبيرت السيولة السريعة للذهب والناسداك]
│   └── PropFirm_Titan_v1.0.ex5                   [إكسبيرت الداوجونز US30]
│
├── 01_EXPERTS_MT4/                                [نسخ الميتاتريدر 4]
│   ├── Ultimate_ICT_Scalper_v3.1.ex4             [للذهب والناسداك على MT4]
│   ├── Ultimate_ICT_Scalper_v3.1.mq4             [السورس كود المفتوح]
│   ├── PropFirm_Titan_v1.0.ex4                   [للداوجونز US30 على MT4]
│   └── PropFirm_Titan_v1.0.mq4                   [السورس كود المفتوح]
│
├── 02_PRESETS_CHAMPIONS/                          [الإعدادات القياسية المعتمدة]
│   ├── Aurum_Imperium_Apex_v8.0_HighPayoff_MaxProfit_Risk095.set  [🏆 إعداد الذهب المعتمد: ربح +33.6% وتراجع 3.42%]
│   ├── Aurum_Imperium_Apex_v8.0_FastRecovery_Unchoked_Sharpe30.set [🚀 إعداد التعافي السريع: ربح +36.4% وSharpe 30.84]
│   ├── 01_GOLD_XAUUSD_Champion_41K_DualSession.set                 [إعداد الذهب الكلاسيكي: جلستي لندن ونيويورك]
│   ├── 02_NASDAQ_USTEC_Champion_23K_SilverBullet.set               [إعداد الناسداك USTEC]
│   └── 03_DOWJONES_US30_Champion_19K_Rocket_RF40.set               [إعداد الداوجونز US30]
│
├── 03_OFFICIAL_REPORTS_AND_CHARTS/                [تقارير الباكتيست الرسمية وشارتات السيولة]
│   ├── Gold_ApexV8_FullYear_100PctRealTicks_Lock120_Risk095.htm   [تقرير الذهب السنوي 102.9 مليون تيك حقيقي]
│   ├── Gold_ApexV8_FullYear_100PctRealTicks_Lock120_Risk095.png   [شارت المنحنى الصاعد للذهب 100% Real Ticks]
│   ├── Gold_ApexV8_FastRecovery_Sharpe30_100PctRealTicks.htm      [تقرير التعافي فائق السرعة Sharpe 30.84]
│   ├── Gold_ApexV8_FastRecovery_Sharpe30_100PctRealTicks.png      [شارت التعافي فائق السرعة]
│   ├── Payoff5_TightLossSL080_TP45_USTEC_20251001_20261001.htm    [تقرير الناسداك الرسمي]
│   └── US30_Titan_T1_Standard_1Year_US30_20251001_20261001.htm    [تقرير الداوجونز الرسمي]
│
├── MASTER_PROPFIRM_MANUAL.md                      [الدليل المؤسسي الشامل والشرح التقني]
├── MASTER_PROP_FIRM_TRINITY_AUDIT.md              [التدقيق الثلاثي للأصول: الذهب، الناسداك، الداوجونز]
└── README_START_HERE.md                           [هذا الفهرس]
```

---

## ⚡ خطوات الاستخدام الفوري على MetaTrader 5 (MT5)

1. افتح منصة **MetaTrader 5**.
2. تأكد من تفعيل زر **Algo Trading** بالأعلى.
3. افتح شارت الذهب **`XAUUSD`** على فريم **5 دقائق (M5)**.
4. من نافذة **Navigator** (المستكشف على اليسار)، اسحب الإكسبيرت **`Aurum_Imperium_Apex_v8.0`** إلى الشارت.
5. في نافذة الإعدادات اضغط **Load** واختر أحد الإعدادين:
   * **للأمان الصارم مع أقل تراجع ممكن (3.42%):** اختر `Aurum_Imperium_Apex_v8.0_HighPayoff_MaxProfit_Risk095.set`.
   * **للتعافي فائق السرعة في 4 صفقات وأعلى ربح (+36.4%):** اختر `Aurum_Imperium_Apex_v8.0_FastRecovery_Unchoked_Sharpe30.set`.
6. اضغط **OK** وسيبدأ الإكسبيرت بالتداول الآلي فوراً مع افتتاح جلسة لندن.

---

## 🛡️ أرقام الأداء المعتمدة على 100% Real Ticks

* **صافي الربح السنوي:** **+$3,362 إلى +$3,637** على حساب $10,000 (يعادل **~3.2% إلى 3.6% شهرياً**).
* **أقصى تراجع كلي طوال العام (Max Drawdown):** **`3.42%`** (أمان كامل ضد حد الإقصاء 10%).
* **أقصى تراجع يومي (Daily Drawdown):** **`1.62%`** فقط (أمان كامل ضد حد الإقصاء اليومي 5%).
* **معدل الربح المتوقع للصفقة (Expected Payoff):** **`$25.86 إلى $29.82`** لكل صفقة.
* **معامل شارب (Sharpe Ratio):** **`28.69 إلى 30.84`** (استقرار مؤسسي عالمي).
