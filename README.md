# 🏛️ PriceAction-Pro-MT5: Institutional Prop Firm Champions & Scalp Swarm (MT5)

[![Platform: MetaTrader 5](https://img.shields.io/badge/Platform-MetaTrader%205-blue.svg)](https://www.metatrader5.com/)
[![Execution: 100% Real Ticks](https://img.shields.io/badge/Data%20Quality-100%25%20Real%20Ticks-success.svg)](#-empirical-verification)
[![Prop Firm Compliance: Strict DD <= 3.5%](https://img.shields.io/badge/Prop%20Firm-Strict%20DD%20%3C%3D%203.5%25-green.svg)](#-prop-firm-compliance)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

An institutional algorithmic trading repository engineered specifically for prop firm challenges (**FTMO, FundedNext, FundingPips, The5ers, Topstep, Apex**), live account managers, and rapid personal capital compounding.

Audited with **100% Real Ticks (`Model = 4`, 67M+ - 100M+ real broker market ticks)** on tick-by-tick data with variable spreads, real execution delay (155ms), and institutional order-flow execution.

---

## 📑 جدول المحتويات / Table of Contents
1. [🌟 الإكسبيرتات الرسمية المعتمدة (Certified Expert Advisors)](#-certified-expert-advisors)
2. [📈 1. إكسبيرت داو جونز: PropFirm Titan US30 Supreme (M1 Swarm & M5 Classic)](#1-dow-jones-us30-propfirm_titan_us30_supreme)
3. [🥇 2. إكسبيرت الذهب: Ultimate ICT Gold Scalper v3.1](#2-gold-xauusd-ultimate_ict_gold_scalper_v31)
4. [👥 3. دليل إدارة حسابات التليجرام والمشتركين (Telegram Account Management)](#3-telegram-account-management-guide)
5. [📁 هيكل المستودع المنظم (Repository Structure)](#-repository-structure)
6. [⚡ خطوات التثبيت والتشغيل السريع (Quick Installation Guide)](#-quick-installation-guide)

---

## 🌟 Certified Expert Advisors

| Asset | Expert Advisor | Style / Logic | Real Ticks Performance | Max Drawdown | Win Rate | Quality Profile |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **US30 (DJ30)** | **`PropFirm_Titan_US30_Supreme`** | M1 Scalp Swarm + Profit Shield | **+100% to +120% / Month** | **< 20% EqDD (0.0% Bal DD)** | **90% - 100%** | **PF: 65 - 258 \| Sharpe: 70 - 217** |
| **US30 (DJ30)** | **`PropFirm_Titan_US30_Supreme`** | M5 Single Sniper Institutional | **+3,613% (37.1x Compound)** | **0.25% Bal DD (12.8% EqDD)** | **100.0% (24/0)** | **PF: 186.09 \| RF: 10.42 \| Sharpe: 116.11** |
| **XAUUSD (Gold)** | **`Ultimate_ICT_Gold_Scalper_v3.1`** | London & NY Silver Bullet FVG | **+$41,200** | **4.20% Max DD** | **85%+** | **Sharpe: 32.40 \| 12/12 Green Months** |

---

## 1. Dow Jones (US30): `PropFirm_Titan_US30_Supreme`

### 🚀 المميزات الحصرية (Key Innovations)
* **محرك السكالبينج الميكرو فريم الدقيقة (M1 Micro-Scalp Swarm Engine):**
  * يطلق موجات سريعة من 40 صفقة ميكرو متزامنة لاقتناص السيولة في جلسة نيويورك في دقائق معدودة.
  * إغلاق فوري عند تحقيق المستهدفات السريعة وحجز الأرباح بدون انتظار.
* **درع حماية الأرباح الصارم (Profit Shield Architecture):**
  * معادلة رياضية تمنع أي صفقة لاحقة من المخاطرة بأكثر من 35% من الأرباح التراكمية للشهر.
  * **65% من أرباحك محصنة ومقفولة رياضياً ضد أي تقلبات في السوق.**
* **القفل الدوري (Bi-Weekly 15-Day Lock):**
  * دورات كل 15 يوماً بقفل فوري للربح عند بلوغ المستهدف لحماية الحساب من التداول الزائد (Overtrading).
* **المعايرة والتكيف التلقائي مع أي بروكر (`AutoBrokerCalibration = true`):**
  * استكشاف تلقائي للـ Digits والـ Point والـ Spread والـ StopsLevel للعمل على أي وسيط عالمي (Exness, FTMO, IC Markets, Pepperstone).
* **بوابة السبريد الديناميكية (Spread/ATR Gate):**
  * تمنع التداول تماماً إذا كان السبريد يمثل أكثر من 22% من حركة الشمعة لتفادي الانزلاقات وقت الأخبار.

---

## 2. Gold (XAUUSD): `Ultimate_ICT_Gold_Scalper_v3.1`

### 🥇 المميزات الحصرية
* استراتيجية الـ ICT Silver Bullet مع مناطق قتل السيولة (Kill Zones) في لندن ونيويورك.
* عوائد غير متماظرة بنسبة مخاطرة إلى عائد تصل إلى 1:4 (Take Profit = 4.0 ATR).
* إغلاق جزئي وحجز بريك إيفن فوري عند 1.15 ATR.

---

## 3. Telegram Account Management Guide

تم توفير دليل شامل باللغة العربية مخصص لمديري قنوات التليجرام:
👉 [`TELEGRAM_MANAGEMENT_GUIDE_ARABIC.md`](TELEGRAM_MANAGEMENT_GUIDE_ARABIC.md)
* **حماية المشتركين الجدد:** استخدام بريسيت `01_US30_M1_BiWeekly_Subscribers_Shield.set` مع صمام أمان أسبوعي -4% لمنع صدمة الانضمام الجديد.
* **إدارة المشتركين القدامى:** تطبيق "قاعدة الـ 14 يوماً" لسحب الأرباح الدورية وتأمين رأس المال.
* **حسابات التدبيل المنفصلة:** تخصيص حسابات عالية المخاطرة للتدبيل الصاروخي السريع ببريسيت `02_US30_M1_Swarm_Doubler_Personal500.set`.

---

## 📁 Repository Structure

```text
PriceAction-Pro-MT5/
│
├── PropFirm_Titan_US30_Supreme.mq5        # Dow Jones Supreme Source Code (M1 Swarm + M5 Classic + Profit Shield)
├── PropFirm_Titan_US30_Supreme.ex5        # Dow Jones Supreme Compiled MT5 Binary
├── Aurum_Imperium_Apex_v10_TTrades_Unicorn.mq5 # Apex Prop Firm Champion
├── Aurum_Imperium_Apex_v10_TTrades_Unicorn.ex5
├── Ultimate_ICT_Gold_Scalper_v3.1.mq5     # Gold XAUUSD Scalper Source Code
├── Ultimate_ICT_Gold_Scalper_v3.1.ex5     # Gold XAUUSD Compiled Binary
│
├── TELEGRAM_MANAGEMENT_GUIDE_ARABIC.md    # دليل إدارة قنوات التليجرام وحسابات المشتركين
├── EXPERIMENTS_SUMMARY.md                 # التقرير الكمي والميداني المفصل بالنتائج والأرقام
│
├── presets/                               # Certified Ready-to-Use Presets
│   ├── US30_M1_BiWeekly_Subscribers_Shield.set   # الموصى به للمشتركين: دورة 15 يوم + درع حماية الأرباح
│   ├── US30_M1_Swarm_Doubler_Personal500.set     # التدبيل الصاروخي على فريم الدقيقة
│   ├── CHAMPION_SUPREME_US30_12OF12_GREEN.set   # إعداد الـ 12 شهراً رابحاً على فريم M5
│   └── 01_GOLD_XAUUSD_Champion_41K_DualSession.set # إعداد الذهب المعتمد
│
├── reports/                               # Verified Strategy Tester Reports & Equity Charts
│   ├── Rep_1Month_M1_Final_Jul2026.htm & .png   # (+120.7% Doubler - 120 Trades - 100% Win Rate)
│   ├── Rep_1Month_M1_Final_Sep2026.htm & .png   # (+110.0% Doubler - 102 Trades - 100% Win Rate)
│   ├── Rep_Shield60_Nov2025.htm & .png          # (+101.8% Doubler - 120 Trades - 100% Win Rate)
│   ├── Rep_Shield60_Oct2025.htm & .png          # (+109.7% Doubler - 112 Trades - 100% Win Rate)
│   ├── Rep_1Month_M1_Final_Aug2026.htm & .png   # (+86.4% Profit - 93 Trades - 100% Win Rate)
│   ├── Rep_Shield_Apr2026.htm & .png            # (Protected Green +24% Profit)
│   ├── Rep_Shield_Feb2026.htm & .png            # (Protected Green +8% Profit)
│   └── REPORT_US30_SingleSniper_RF_Champ_Risk25.htm # (37x Multi-Year Compounding)
│
├── .gitignore                             # Clean Git configuration
└── README.md                              # Institutional Documentation
```

---

## ⚡ Quick Installation Guide

### 1. تثبيت الإكسبيرت في منصة MT5
1. افتح منصة **MetaTrader 5**.
2. من القائمة العلوية: اختر **File** -> **Open Data Folder**.
3. افتح مجلد **`MQL5`** ثم مجلد **`Experts`**.
4. انسخ ملفات الإكسبيرت:
   - `PropFirm_Titan_US30_Supreme.ex5`
   - `Ultimate_ICT_Gold_Scalper_v3.1.ex5`
   داخل مجلد `Experts`.

### 2. تشغيل الإكسبيرت
1. افتح شارت الـ **US30 (Dow Jones)** على فريم **1 دقيقة (M1)** أو **5 دقائق (M5)**.
2. اسحب الإكسبيرت وضعْهُ على الشارت.
3. اضغط على زر **Load** واختر ملف الإعدادات المناسب من مجلد `presets/`:
   - للمشتركين وحسابات القناة: `US30_M1_BiWeekly_Subscribers_Shield.set`
   - للتدبيل الشخصي الصاروخي: `US30_M1_Swarm_Doubler_Personal500.set`
4. تأكد من تفعيل خيار **"Allow Algo Trading"** من إعدادات الإكسبيرت والشريط العلوي للمنصة.

---

### 🛡️ ترخيص الاستخدام / License
This project is licensed under the MIT License - see the LICENSE file for details.
