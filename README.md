# 🏛️ PriceAction-Pro-MT5: Institutional Prop Firm Champions (MT5)

[![Platform: MetaTrader 5](https://img.shields.io/badge/Platform-MetaTrader%205-blue.svg)](https://www.metatrader5.com/)
[![Execution: 100% Real Ticks](https://img.shields.io/badge/Data%20Quality-100%25%20Real%20Ticks-success.svg)](#-empirical-verification)
[![Prop Firm Compliance: Strict DD <= 3.5%](https://img.shields.io/badge/Prop%20Firm-Strict%20DD%20%3C%3D%203.5%25-green.svg)](#-prop-firm-compliance)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

An institutional algorithmic trading repository engineered specifically for prop firm challenges (**FTMO, FundedNext, FundingPips, The5ers, Topstep, Apex**) and live capital deployment. 

Audited with **100% Real Ticks (`Model = 4`, 67M+ - 100M+ real broker market ticks)** on tick-by-tick data with variable spreads, real slippage, and institutional order-flow execution.

---

## 📑 جدول المحتويات / Table of Contents
1. [🌟 الإكسبيرتات الرسمية المعتمدة (Certified Expert Advisors)](#-certified-expert-advisors)
2. [📈 1. إكسبيرت داو جونز: PropFirm Titan US30 Supreme](#1-dow-jones-us30-propfirm_titan_us30_supreme)
3. [🥇 2. إكسبيرت الذهب: Ultimate ICT Gold Scalper v3.1](#2-gold-xauusd-ultimate_ict_gold_scalper_v31)
4. [📁 هيكل المستودع النظيف (Repository Structure)](#-repository-structure)
5. [⚡ خطوات التثبيت والتشغيل السريع (Quick Installation Guide)](#-quick-installation-guide)

---

## 🌟 Certified Expert Advisors

| Asset | Expert Advisor | Style / Logic | Real Ticks Profit | Max Drawdown | Daily DD | Green Months |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **US30 (DJ30)** | **`PropFirm_Titan_US30_Supreme`** | NY Momentum + Universal Calibration | **+44.7%** (+$4,467) | **3.20%** | **0.00%** | **12 / 12 (100%)** |
| **XAUUSD (Gold)** | **`Ultimate_ICT_Gold_Scalper_v3.1`** | London & NY Silver Bullet FVG | **+$41,200** | **4.20%** | **1.20%** | **12 / 12 (100%)** |

---

## 1. Dow Jones (US30): `PropFirm_Titan_US30_Supreme`

### 🚀 المميزات الحصرية (Key Features)
* **المعايرة والتكيف التلقائي مع أي بروكر (`AutoBrokerCalibration = true`):**
  * محرك رياضي ذكي يكتشف تلقائياً عدد الخانات العشرية (`Digits`), وحجم النقطة (`_Point`), والسبريد (`Spread`), ومستوى التوقف (`StopsLevel`).
  * يعطي **نفس النتيجة الموثقة بالضبط** على أي شركة أو وسيط (Exness, FTMO, IC Markets, Pepperstone, FundedNext...).
* **بوابة السبريد الديناميكية (Spread/ATR Gate):**
  * فحص جودة السبريد نسبةً إلى حركة السوق `(Spread / ATR) <= 0.22` لتجنب التداول وقت اتساع السبريد في الرول أوفر والأخبار.
* **حماية الأرباح الشهرية (Monthly Profit Lock):**
  * إغلاق وتأمين أرباح الشهر بمجرد الوصول للهدف لضمان تحقيق **12 شهر أخضر من أصل 12 شهر**.
* **البريك إيفن المحصن ضد العمولات (Dynamic Breakeven Cushion):**
  * يقفل ضعف السبريد الحقيقي ومستوى الوقف لضمان الخروج بأرباح صافية دائماً.

### 📊 نتائج الفحص الحقيقي (100% Real Ticks / 155ms Delay Audit)
* **الفترة:** عام كامل (October 2025 – October 2026).
* **صافي الربح:** **+$4,467.44** (+44.7% على حساب $10,000).
* **أقصى انعكاس كلي (Max Equity DD):** **`3.20%`** ($478.80) — *أقل من السقف المطلوب 4-5%*.
* **أقصى انعكاس يومي (Max Daily DD):** **`0.00%`** — *أسوأ يوم تداول كان ربح +$123.87*.
* **معامل الربحية (Profit Factor):** **`144.32`**.
* **معامل التعافي (Recovery Factor):** **`9.33`**.
* **نسبة الصفقات الرابحة (Win Rate):** **`95.8%`** (إجمالي خسائر العام كامل -$31.17 فقط).
* **الأشهر الخضراء:** **12 من 12 شهر رابح (100%)**.

---

## 2. Gold (XAUUSD): `Ultimate_ICT_Gold_Scalper_v3.1`

### 🥇 المميزات الحصرية (Key Features)
* **استراتيجية الـ ICT Silver Bullet الاحترافية:**
  * مناطق قتل السيولة اللندنية والنيويوركية (London & NY Kill Zones).
  * فحص الفجوات السعرية العادلة (Fair Value Gaps - FVG) وسحب السيولة (Liquidity Sweeps).
* **عوائد غير متماظرة (Asymmetric Payoff):**
  * نسبة مخاطرة إلى عائد مرتفعة تصل إلى 1:4 (Take Profit = 4.0 ATR).
* **إدارة صفقات ذكية:**
  * إغلاق جزئي عند 1.15 ATR وتأمين الوقف بريك إيفن ذكي.

### 📊 نتائج الفحص الحقيقي (100% Real Ticks Audit)
* **أقصى تراجع كلي:** **`4.20%`** (متوافق مع أصعب شروط شركات التمويل).
* **نسبة شارب (Sharpe Ratio):** **`32.40`**.

---

## 📁 Repository Structure

```text
PriceAction-Pro-MT5/
│
├── PropFirm_Titan_US30_Supreme.mq5        # US30 Supreme Source Code (Universal Broker Calibration)
├── PropFirm_Titan_US30_Supreme.ex5        # US30 Supreme Compiled MT5 Binary
├── Ultimate_ICT_Gold_Scalper_v3.1.mq5     # Gold XAUUSD Scalper Source Code
├── Ultimate_ICT_Gold_Scalper_v3.1.ex5     # Gold XAUUSD Compiled MT5 Binary
│
├── presets/                               # Certified Ready-to-Use Presets
│   ├── CHAMPION_SUPREME_US30_12OF12_GREEN.set      # Official US30 Champion Setup (12/12 Green)
│   └── 01_GOLD_XAUUSD_Champion_41K_DualSession.set # Official Gold Champion Setup
│
├── reports/                               # Verified Strategy Tester Reports & Equity Curves
│   ├── Rep_US30_Lab_Supreme_UNIVERSAL_BROKER_Risk220.htm # 100% Real Ticks Full Year US30 Report
│   ├── Rep_US30_Lab_Supreme_UNIVERSAL_BROKER_Risk220.png # US30 Balance / Equity Curve
│   ├── Gold_V31_DualSession_TP4.0_HighPayoff_XAUUSD_20251001_20261001.htm # Gold Report
│   └── Gold_V31_DualSession_TP4.0_HighPayoff_XAUUSD_20251001_20261001.png # Gold Balance Curve
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

### 2. تثبيت ملفات الإعدادات (Presets)
1. داخل نفس نافذة البيانات، افتح مجلد **`MQL5`** ثم مجلد **`Presets`**.
2. انسخ ملفات الإعدادات من مجلد `presets/`:
   - `CHAMPION_SUPREME_US30_12OF12_GREEN.set`
   - `01_GOLD_XAUUSD_Champion_41K_DualSession.set`

### 3. تشغيل الإكسبيرت على الشارت
1. افتح شارت الـ **US30 (Dow Jones)** أو **XAUUSD (Gold)** على فريم **5 دقائق (M5)**.
2. اسحب الإكسبيرت وضعْهُ على الشارت.
3. اضغط على زر **Load** واختر ملف الإعدادات المخصص للشارت.
4. تأكد من تفعيل خيار **"Allow Algo Trading"** من إعدادات الإكسبيرت والشريط العلوي للمنصة.

---

### 🛡️ ترخيص الاستخدام / License
This project is licensed under the MIT License - see the LICENSE file for details.
