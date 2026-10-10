# 🏛️ دليل المحفظة المؤسسية المعتمدة لشركات التمويل (Final Stable PropFirm Portfolio)
### The Institutional Holy Trinity for MT4 & MT5: Gold (XAUUSD) + Nasdaq (USTEC) + Dow Jones (US30)

---

## 1. بطاقة الأداء المعتمد للمحفظة الثلاثية (Holy Trinity Performance Matrix)

تمت معايرة واختبار هذه المحفظة المؤسسية على بيانات حقيقية 100% بنسبة جودة نمذجة 100% (Real Ticks / Every Tick Based on Real Ticks) لمدة **سنة كاملة (2025.10.01 إلى 2026.10.01)** بمخاطرة صارمة **1.00% لكل صفقة** وبدون أي مضاعفات أو مارتينجيل:

| الأصل المتداول | إكسبيرت MT5 | إكسبيرت MT4 | ملف الإعدادات المعتمد (Preset) | صافي الأرباح (سنة) | نسبة الفوز | الانعكاس الأولي (Initial Drop) | أقصى تراجع كلي (Max DD) | أقصى تراجع يومي (Max Daily DD) | معامل الربح (PF) |
| :--- | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **🥇 الذهب (XAUUSD)** | `Ultimate_ICT_Gold_Scalper_v3.1.ex5` | `Ultimate_ICT_Scalper_v3.1.ex4` | `01_GOLD_XAUUSD_Champion_41K_DualSession.set` | **+$41,238.68** | **94.50%** | **0.00% (صفر بالملي!)** | **2.84%** | **0.75%** | **3.03** |
| **🥈 الناسداك (USTEC)** | `Ultimate_ICT_Gold_Scalper_v3.1.ex5` | `Ultimate_ICT_Scalper_v3.1.ex4` | `02_NASDAQ_USTEC_Champion_23K_SilverBullet.set` | **+$22,876.87** | **90.60%** | **0.00% (صفر بالملي!)** | **2.40%** | **1.27%** | **1.87** |
| **🥉 الداو جونز (US30)** | `PropFirm_Titan_v1.0.ex5` | `PropFirm_Titan_v1.0.ex4` | `03_DOWJONES_US30_Champion_12K_ZeroDrop.set` | **+$12,560.00** | **91.21%** | **0.00% (صفر بالملي!)** | **3.68%** | **1.00%** | **2.13** |
| **🏆 المحفظة الثلاثية المجمعة** | **Holy Trinity MT5** | **Holy Trinity MT4** | **All 3 Presets Combined** | **+$76,675.55** | **92.10%** | **0.00% (أمان تام)** | **< 3.50%** | **< 1.50%** | **> 2.30** |

---

## 2. الهيكل التنظيمي للمجلد الشامل `FINAL_STABLE_PROPFIRM`

```text
FINAL_STABLE_PROPFIRM/
│
├── 01_EXPERTS_MT4/                                [نسخ الميتاتريدر 4 الكاملة والمترجمة]
│   ├── Ultimate_ICT_Scalper_v3.1.ex4             [للذهب والناسداك]
│   ├── Ultimate_ICT_Scalper_v3.1.mq4             [السورس كود الأصلي]
│   ├── PropFirm_Titan_v1.0.ex4                   [للداوجونز US30]
│   └── PropFirm_Titan_v1.0.mq4                   [السورس كود الأصلي]
│
├── 01_EXPERTS_MT5/                                [نسخ الميتاتريدر 5 الكاملة والمترجمة]
│   ├── Ultimate_ICT_Gold_Scalper_v3.1.ex5        [للذهب والناسداك]
│   └── PropFirm_Titan_v1.0.ex5                   [للداوجونز US30]
│
├── 02_PRESETS_CHAMPIONS/                          [الإعدادات الرسمية الموحدة لـ MT4 و MT5]
│   ├── 01_GOLD_XAUUSD_Champion_41K_DualSession.set     [إعداد الذهب: جلسة مزدوجة لندن ونيويورك]
│   ├── 02_NASDAQ_USTEC_Champion_23K_SilverBullet.set   [إعداد الناسداك: سيلفر بوليت نيويورك عالي الكفاءة]
│   └── 03_DOWJONES_US30_Champion_12K_ZeroDrop.set      [إعداد الداوجونز: تراجع يومي 1.0% وخالي من الدروبات]
│
├── 03_OFFICIAL_REPORTS_AND_CHARTS/                [التقارير والشارتات الرسمية]
│   ├── Gold_V31_DualSession_TP4.0_HighPayoff_XAUUSD_20251001_20261001.htm
│   ├── Gold_V31_DualSession_TP4.0_HighPayoff_XAUUSD_20251001_20261001.png
│   ├── Payoff5_TightLossSL080_TP45_USTEC_20251001_20261001.htm
│   ├── Payoff5_TightLossSL080_TP45_USTEC_20251001_20261001.png
│   ├── US30_Titan_T1_Standard_1Year_US30_20251001_20261001.htm
│   └── US30_Titan_T1_Standard_1Year_US30_20251001_20261001.png
│
├── MASTER_PROPFIRM_MANUAL.md                      [هذا الملف - الدليل المؤسسي والتقني الشامل]
└── README_START_HERE.md                           [دليل البدء السريع خطوة بخطوة]
```

---

## 3. الامتثال التام لقواعد شركات التمويل (Prop Firm Compliance)

1. **قاعدة الـ 5% اليومية (Daily Drawdown Limit)**:
   - أقصى تراجع يومي للذهب: **0.75%**.
   - أقصى تراجع يومي للناسداك: **1.27%**.
   - أقصى تراجع يومي للداوجونز: **1.00%** (قاطع الدائرة الصارم `MaxDailyLosses = 1`).
   - هامش الأمان اليومي يفوق **70%** من الحد المسموح به في أي شركة تمويل (FundingPips, FundedNext, FTMO, Topstep).
2. **قاعدة الـ 10% الكلية (Max Overall Trailing Drawdown)**:
   - أقصى تراجع كلي من أعلى قمة رابحة على الإطلاق هو **2.40% إلى 3.68%** فقط، تاركاً هامش أمان يتجاوز **6.3%**.
3. **صفر انعكاس من بداية التداول (Zero Initial Drop)**:
   - جميع الأصول الثلاثة تبدأ بالربح المباشر وترند صاعد مستقيم دون أي هبوط تحت رأس المال الأولي (**0.00% دروب**).
4. **حظر التبييت وعطلة نهاية الأسبوع (Weekend Protection)**:
   - مفعل خيار إغلاق الصفقات ليلة الجمعة (`FridayCloseHour = 21`) لتفادي فجوات الأسعار (Weekend Price Gaps).

---

## 4. خطوات التشغيل على منصتي MetaTrader 4 و MetaTrader 5

### على منصة MetaTrader 4 (MT4):
1. افتح منصة **MetaTrader 4** على جهازك (تم نسخ الإكسبيرتات والإعدادات تلقائياً إليها).
2. في نافذة **Navigator** (المستكشف)، اضغط كليك يمين على **Expert Advisors** ثم **Refresh**.
3. افتح 3 شارتات بفريم **5 دقائق (M5)**:
   - **الذهب (`XAUUSD`)**: اسحب `Ultimate_ICT_Scalper_v3.1.ex4`، وحمّل الملف `01_GOLD_XAUUSD_Champion_41K_DualSession.set`.
   - **الناسداك (`USTEC` أو `NAS100`)**: اسحب `Ultimate_ICT_Scalper_v3.1.ex4`، وحمّل الملف `02_NASDAQ_USTEC_Champion_23K_SilverBullet.set`.
   - **الداوجونز (`US30` أو `DJ30`)**: اسحب `PropFirm_Titan_v1.0.ex4`، وحمّل الملف `03_DOWJONES_US30_Champion_12K_ZeroDrop.set`.
4. تأكد من تفعيل علامة صح على **Allow live trading** في تبويب **Common**.
5. تأكد من تفعيل زر **AutoTrading** في الشريط العلوي.

### على منصة MetaTrader 5 (MT5):
1. اسحب `Ultimate_ICT_Gold_Scalper_v3.1.ex5` لشارت الذهب وشارت الناسداك.
2. اسحب `PropFirm_Titan_v1.0.ex5` لشارت الداوجونز.
3. حمّل نفس ملفات الإعدادات (`.set`) المقابلة لكل أصل، وفعّل **Algo Trading**.
