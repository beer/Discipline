# ✔️ Rainmeter Trading Suite (Trading Clock & Task Tracker)

A professional Rainmeter widget suite designed for serious traders. This toolset combines a high-precision market timing engine with a rule-based task tracker to help maintain awareness and discipline during live trading and journaling.

這是一套為專業交易員打造的 Rainmeter 插件組合。結合了「高精度市場時鐘」與「規則化任務追蹤器」，旨在幫助交易員在截圖記錄與交易日誌中，保持紀律意識與時空同步。

## 🎞️ Preview / 預覽

<div align="center">
  <img src="screenshots/photo-example-6.png" width="800">
  <br>
  <p><i>Synchronized high-precision market clock and trading discipline tracker.</i></p>
  
  <table border="0">
    <tr>
      <td><img src="screenshots/photo-example-1.png" width="400"></td>
      <td><img src="screenshots/photo-example-8.png" width="400"></td>
    </tr>
    <tr>
      <td><img src="screenshots/photo-example-7.png" width="400"></td>
      <td><img src="screenshots/photo-example-3.png" width="400"></td>
    </tr>
    <tr>
      <td><img src="screenshots/photo-example-4.png" width="400"></td>
      <td><img src="screenshots/photo-example-5.png" width="400"></td>
    </tr>
  </table>
</div>

---

## 🕒 Module 1: Professional Trading Clock / 模組 1：專業交易時鐘
A timing engine specifically calibrated for New York markets with institutional session logic and economic data.
專為紐約市場校準的高精度時間引擎，整合了機構級的時段邏輯與經濟數據。

- **Auto DST / 自動夏令時**: Intelligent detection of UTC-4 / UTC-5. / 智能偵測 DST，無需手動調整。
- **2026 Calendar / 2026 市場日曆**: Built-in US holidays and early close (13:00) alerts. / 內建 2026 全年美股節日與提早收盤提醒。
- **Session Logic / 交易時段邏輯**: Real-time detection of **Asia, London, NY AM/PM, and Silver Bullet** sessions with contextual UI colors. / 即時識別各大時段，UI 顏色隨當前活躍時段自動切換。
- **Economic Calendar / 智能財經日曆**: Auto-fetches "High Impact USD" news from Forex Factory with countdowns and 10s flash warnings. / 自動抓取高影響力 USD 新聞，具備新聞倒數與 10 秒閃爍預警。
- **Simulation Mode / 穿越模擬模式**: "Time Travel" feature for backtesting behavior on any specific date. / 開發者可設定特定日期測試時段變換與 UI 行為。

---

## 📝 Module 2: Trading Task Tracker / 模組 2：交易規則追蹤器
Highly flexible criteria tracking optimized for monitoring setups and execution rules.
高度靈活的進場條件追蹤工具，透過權重計算，將你的交易紀律視覺化。

- **Flexible Structure / 完全自定義結構**: 
  - **Renameable Folders**: Rename `Setups-ICT` to anything (e.g., `SMC-Strategy`). / 可隨意更改資料夾名稱。
  - **Duplicate .ini**: Rename or duplicate `.ini` files to run multiple independent trackers. / 檔案可隨意改名或複制，同時開啟多個獨立策略追蹤器。
- **Weighted Progress / 權重進度條**: Visualize Major vs. Minor rules; Important tasks can hold 80% weight. / 區分主要與一般條件，主要條件可佔進度條 80%。
- **Screenshot Mode / 截圖模式**: Instantly hide edit icons for a clean look in your journal. / 一鍵隱藏編輯按鈕，呈現乾淨介面供截圖存檔。
- **Trash Bin / 垃圾桶系統**: Recover accidentally deleted rules. / 防止意外刪除重要的交易規則。

---

## 🛠️ Configuration Guide / 設定指南

### 1. Market Clock Settings (`MarketClock.ini`)
| Variable / 變數 | Description / 說明 |
| :--- | :--- |
| `Scale` | Overall UI size (e.g., `3.4` for 4K screens). / 整體縮放比例（如 4K 螢幕建議設定 3.4 以上）。 |
| `SHOW_NEWS` | Expand or collapse the news panel (`0`/`1`). / 開啟或關閉下方的新聞面板。 |

### 2. Task Tracker Settings (`Rules.ini` / `Setup.ini`)
| Category / 類別 | Variable / 變數 | Description / 說明 |
| :--- | :--- | :--- |
| **Layout / 佈局** | `FONT_SIZE` | Base font size; all icons and bars scale accordingly. / 基礎字體大小，Icon 與進度條會自動縮放。 |
| | `SkinWidth` | Window width (recommended min: 350). / 視窗寬度，推薦不要小於 350。 |
| **Logic / 邏輯** | `MAX_MAJOR_DONE_RATE` | Progress bar weight for "Important" tasks (Default: 80). / 主要條件被勾選後佔進度條的比例。 |
| | `SHOW_IMPORTANT` | Toggle Major (Star) rule buttons. / 是否啟用主要條件（星號）功能。 |
| **Color / 顏色** | `ColorMajorDone` | Progress bar color for completed major rules. / 主要條件達成時的進度條顏色。 |
| | `SolidColor` | Background color and transparency (R,G,B,Alpha). / 背景色與透明度。 |

---

## 📦 Installation / 安裝步驟

1. **Install Rainmeter**: Download from [rainmeter.net](https://www.rainmeter.net/).
2. **Download Suite**: Place the folder in `Documents\Rainmeter\Skins\`.
3. **Activate Clock**: Load `MarketClock > MarketClock.ini`.
4. **Activate Tracker**: Load `.ini` from `Setups-ICT` (or your custom folder).
5. **Sync Data**: Use Dropbox/OneDrive to sync rules across multiple PCs.

1. **下載 Rainmeter** 並將此資料夾放入 `Documents\Rainmeter\Skins\`。
2. **啟動時鐘**：載入 `MarketClock.ini`。
3. **啟動追蹤器**：載入 `Setups-ICT` 資料夾下的 `.ini` 檔案。
4. **同步數據**：可將 Skins 路徑設於雲端空間，實現多端同步。

---

## 🤖 Advanced Simulation (Developer Only) / 進階模擬測試
To test future dates, edit the top of `MarketClock.lua`:
若要測試未來日期，請修改 `MarketClock.lua` 頂部：
```lua
DEBUG_MODE = true
DEBUG_NY_TIME_STR = "2026-01-14 09:30:00" -- Jump to NY Open / 模擬紐約開盤