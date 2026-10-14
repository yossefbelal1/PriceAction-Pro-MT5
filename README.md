# 🏛️ PriceAction-Pro-MT5: Institutional Prop Firm Champions & Scalp Architecture (MT5)

[![Platform: MetaTrader 5](https://img.shields.io/badge/Platform-MetaTrader%205-blue.svg)](https://www.metatrader5.com/)
[![Execution: 100% Real Ticks](https://img.shields.io/badge/Data%20Quality-100%25%20Real%20Ticks-success.svg)](#-empirical-verification)
[![Prop Firm Compliance: Strict DD <= 4.0%](https://img.shields.io/badge/Prop%20Firm-Strict%20DD%20%3C%3D%204.0%25-green.svg)](#-prop-firm-compliance)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

An institutional algorithmic trading repository engineered specifically for prop firm challenges (**FTMO, FundedNext, FundingPips, The5ers, Topstep, Apex**), professional account managers, and capital compounding.

Audited with **100% Real Ticks (`Model = 4`)** on tick-by-tick data with variable spreads, realistic broker execution delay (155ms), and institutional order-flow execution.

---

## 📑 جدول المحتويات / Table of Contents
1. [🌟 الإكسبيرتات الرسمية المعتمدة (Certified Expert Advisors)](#-certified-expert-advisors)
2. [📈 1. إكسبيرت داو جونز: PropFirm Titan US30 Supreme (M1 Multi-Tranche & M5 Sniper)](#1-dow-jones-us30-propfirm_titan_us30_supreme)
3. [🥇 2. إكسبيرت الذهب: Ultimate ICT Gold Scalper v3.1](#2-gold-xauusd-ultimate_ict_gold_scalper_v31)
4. [👥 3. دليل إدارة حسابات التليجرام والمشتركين (Telegram Account Management)](#3-telegram-account-management-guide)
5. [📁 هيكل المستودع المنظم (Repository Structure)](#-repository-structure)
6. [⚡ خطوات التثبيت والتشغيل السريع (Quick Installation Guide)](#-quick-installation-guide)

---

## 🌟 Certified Expert Advisors

| Asset | Expert Advisor | Execution Mode | Risk Model | Max Floating DD | Margin Safety | Quality Profile |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **US30 (DJ30)** | **`PropFirm_Titan_US30_Supreme`** | M1 Multi-Tranche (Fast TP + Runner) | Smart Anti-Martingale + Profit Shield | **<= 4.0% Daily / <= 8.0% Cycle** | **Margin Level >= 300%** | **Institutional Spread Immune** |
| **US30 (DJ30)** | **`PropFirm_Titan_US30_Supreme`** | M5 Single Sniper Institutional | Fixed / Compounded Risk | **<= 3.5% Daily** | **Margin Level >= 500%** | **100% Real Ticks Verified** |
| **XAUUSD (Gold)** | **`Ultimate_ICT_Gold_Scalper_v3.1`** | London & NY Silver Bullet FVG | Asymmetric R:R (1:3 - 1:4) | **<= 4.2% Max DD** | **Margin Level >= 400%** | **Dual Session Institutional** |

---

## 1. Dow Jones (US30): `PropFirm_Titan_US30_Supreme`

### 🚀 المعايير الهندسية الصارمة (Strict Institutional Architecture)
* **تنفيذ متعدد العقود النظيف (Clean Multi-Tranche Execution - Max 2-3 Tranches):**
  * تم إلغاء حزم الأوامر المتكررة نهائياً. كل فرصة تتوزع على عقدين إلى 3 عقود كحد أقصى:
    * **العقد الأول (Fast TP):** اقتناص ربح سريع عند (1.15 ATR).
    * **العقد الثاني (Runner TP):** التوجه لأهداف واسعة (2.50 - 3.50 ATR) مع تأمين نقطة الدخول (Breakeven + Cushion).
* **حزام أمان حقوق الملكية اللحظي (Real-Time Floating Equity Safety Belt):**
  * فحص فوري في كل تكة (`OnTick`) لحقوق الملكية العائمة (`Floating Equity`).
  * إغلاق طوارئ فوري لكافة الصفقات (`AutoCloseOnEmergency = true`) إذا وصل التراجع اليومي إلى **4.00%**.
* **حارس الهامش الإجباري (Margin Level Guard >= 300%):**
  * حظر برمجي تام لفتح أي صفقة قد تهبط بمستوى الهامش تحت 300%، مما يحمي الحساب نهائياً من أي مارجن كول.
* **إدارة المخاطر الذكية (Smart Anti-Martingale & Profit Shield):**
  * مخاطرة أساسية صارمة على رأس المال الأصلي: `2.50%`.
  * تفعيل درع الأرباح (`UseProfitShield = true`) بحيث تتم المخاطرة بنسبة 35% فقط من الأرباح المحققة، بينما **65% من الأرباح التراكمية محصنة ومقفولة تماماً**.
  * ميزة `UseStreakRiskReducer` لتقليص المخاطرة إلى النصف بعد أي خسارة لحماية رأس المال.
* **تداول نشط وموزع طوال أيام الأسبوع:**
  * فتح التداول طوال أيام الأسبوع (من الإثنين إلى الجمعة) في جلسة نيويورك الأمريكية (14:30 - 16:30 بتوقيت المنصة).

---

## 2. Gold (XAUUSD): `Ultimate_ICT_Gold_Scalper_v3.1`

### 🥇 المميزات الحصرية
* استراتيجية الـ ICT Silver Bullet مع مناطق قتل السيولة (Kill Zones) في لندن ونيويورك.
* عوائد غير متماثلة بنسبة مخاطرة إلى عائد تصل إلى 1:4 (Take Profit = 4.0 ATR).
* إغلاق جزئي وحجز بريك إيفن فوري لحماية رأس المال.

---

## 3. Telegram Account Management Guide

تم توفير دليل شامل باللغة العربية مخصص لمديري قنوات التليجرام:
👉 [`TELEGRAM_MANAGEMENT_GUIDE_ARABIC.md`](TELEGRAM_MANAGEMENT_GUIDE_ARABIC.md)
* **حماية المشتركين الجدد:** استخدام بريسيت `01_US30_M1_BiWeekly_Subscribers_Shield.set` مع سقف خسارة يومي 4% وسقف دورة 8% على حقوق الملكية.
* **إدارة المشتركين القدامى:** تطبيق "قاعدة الـ 15 يوماً" لسحب الأرباح الدورية وتأمين رأس المال.
* **حسابات التراكم السريع:** استخدام بريسيت `02_US30_M1_Swarm_Doubler_Aggressive.set` للحسابات الصغيرة بنظام التراكم من الأرباح مع فرملة طوارئ عند 5%.

---

## 📁 Repository Structure

```text
PriceAction-Pro-MT5/
│
├── PropFirm_Titan_US30_Supreme.mq5        # Dow Jones Supreme Source Code (Multi-Tranche + Profit Shield + Margin Guard)
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
│   ├── 01_US30_M1_BiWeekly_Subscribers_Shield.set   # الموصى به للمشتركين: دورة 15 يوم + سقف خسارة 4%
│   ├── 02_US30_M1_Swarm_Doubler_Aggressive.set      # التراكم السريع للحسابات الهجومية
│   ├── CHAMPION_SUPREME_US30_12OF12_GREEN.set       # إعداد الـ 12 شهراً رابحاً على فريم M5
│   └── 01_GOLD_XAUUSD_Champion_41K_DualSession.set    # إعداد الذهب المعتمد
│
├── reports/                               # Verified Strategy Tester Reports
│   └── ...
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
   - لإدارة المشتركين وقنوات التليجرام: `01_US30_M1_BiWeekly_Subscribers_Shield.set`
   - لحسابات النمو التراكمي الهجومية: `02_US30_M1_Swarm_Doubler_Aggressive.set`
4. تأكد من تفعيل خيار **"Allow Algo Trading"** من إعدادات الإكسبيرت والشريط العلوي للمنصة.

---

### 🛡️ ترخيص الاستخدام / License
This project is licensed under the MIT License - see the LICENSE file for details.
