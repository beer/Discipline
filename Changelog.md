# Changelog

## [1.3.0] - 2026-01-19

### Added
- **Futures-Centric Market Logic**: 
  - Rewrote the market state engine to align with CME/CBOT futures schedules.
  - Implemented **Sunday Open Logic**: The suite now transitions from "Weekend Prep" to active trading at 18:00 NY Time on Sundays.
  - Implemented **Holiday Partial Session Logic**: During US federal holidays (e.g., MLK Day), the clock now remains active for the morning session and enters "Holiday Prep" mode only after the 13:00 Early Close.
- **Externalized Session Management**:
  - Migrated all trading session definitions from hardcoded Lua tables to an external `Sessions.json` file.
  - Added support for dynamic session reloading without modifying core script logic.
- **Pre-Session Visual Alert (Blinking System)**:
  - Developed a "Pre-Alert" engine that triggers background color flashing $N$ seconds (customizable via `blinking` variable in JSON) before a session begins.
  - Implemented a **State-Aware Flash Override**: Blinking automatically ceases upon session entry to ensure visual stability during active trading.
- **Advanced News Filtering & Prioritization**:
  - **Conflict Resolution Logic**: When multiple "High Impact" news events occur at the same timestamp, the engine now uses a weight-based priority system (e.g., FOMC > GDP > CPI) to display the most critical data.
  - **String Purification**: Implemented regex-based title cleaning to remove cluttering units such as `q/q`, `m/m`, and `y/y` from the news display.

### Changed
- **Session UI Architecture**:
  - Updated **Asia Session** default start time to 18:00 to match the futures market globex open.
  - Redefined **Silver Bullet** visual identity to "Plasma Purple" (`138,43,226`) to eliminate visual collision with Macro Bar (Deep Blue) overlays.
- **Blinking Animation Controller**: Utilizes `os.clock()` modulation for the flash state to ensure consistent 1Hz oscillation regardless of the Rainmeter `Update` frequency.

### Fixed
- **Sunday "Dead Zone" Bug**: Resolved an issue where the clock would stay in "Weekend Prep" for the entire Sunday, causing traders to miss the Sunday evening open.
- **News Redundancy**: Fixed the "Duplicate Timestamp Overcrowding" in the news panel by implementing a time-slot hashing algorithm in the `FilterNews` function.
- **Cross-Day Duration Math**: Fixed a calculation error in `distToStart` for sessions spanning across the 00:00 UTC/NY threshold.

### Technical Notes
- **Priority Weights**: The current hierarchy is set as: `FOMC (110) > GDP (100) > CPI (95) > PCE (90) > NFP (85)`.
- **JSON Schema**: `Sessions.json` now requires `start`, `stop`, `name`, `color`, `fColor`, and `blinking` keys for full functionality.


## [1.2.0] - 2026-01-18

### Added
- **Temporal Synchronization Engine (NY Core)**:
  - Implemented a unified New York time-base as the "Single Source of Truth" for all session and news logic.
  - Developed a **Local-to-UTC Offset Neutralizer** that automatically compensates for the host PC's timezone, ensuring consistent execution whether the user is in Australia or the US.
- **Institutional Session Intelligence**:
  - Introduced dynamic detection for **Asia, London, NY AM/PM**, and **Silver Bullet** sessions.
  - Added a session-duration sorting algorithm that automatically determines primary vs. secondary (overlapping) sessions for UI display.
- **Economic Calendar Integration & Watchdog**:
  - Integrated real-time "High Impact USD" news fetching from Forex Factory via JSON parsing.
  - Implemented a **Data Watchdog** that monitors the validity of news events and triggers an hourly re-fetch if no future events are detected in the local cache.
- **Time-Travel Simulation Mode (Safe Debug)**:
  - Created a robust simulation framework allowing users to jump to specific dates (e.g., Jan 2026) for backtesting.
  - Implemented a **Fail-Safe Mechanism**: The engine automatically reverts to real-time system clocks if the debug string is empty or incorrectly formatted.
- **2026 Market Intelligence**: Pre-loaded all 2026 US market holidays and Early Close (13:00) logic to prevent false session alerts during non-trading days.

### Changed
- **UI Interaction Protocol**:
  - Decoupled the News Toggle logic from the main update cycle using a `lastShowNewsState` variable to prevent manual UI expansion from being overridden by per-second script refreshes.
  - Refactored the main clock meter (`MeterNYClock`) to use a direct string-injection method during Debug Mode to eliminate sub-pixel jitter.
- **Alert Visuals**: Implemented a 10-second pulse-flash warning layer using a Calc-based animation formula (`MeasureFlashAnim`) to provide high-visibility warnings before high-impact news releases.

### Fixed
- **Timezone Drift Artifacts**: Resolved a critical bug where news events were shifted by +/- 5 hours during JSON parsing due to Lua's automatic local-time conversion.
- **News Persistence Bug**: Fixed an issue where the News Icon would remain hidden after the first daily fetch; implemented a future-event checking loop to manage the `HideNewsToggleButton` variable state.
- **Session Overlap Collision**: Fixed a logic error where shorter sessions (e.g., Silver Bullet) would be masked by longer sessions (e.g., London) by implementing a priority duration-based sort.

### Technical Notes
- **DST Logic**: The engine now calculates Daylight Saving Time transition points (Second Sunday of March / First Sunday of November) algorithmically, requiring zero manual updates for future years.
- **Simulation Accuracy**: Elapsed time during Debug Mode is now calculated using `os.clock()` as a delta, providing second-level precision during prolonged simulation sessions.

## [1.1.0] - 2026-01-12 (Updated)

### Added
- **Dynamic Proportional Scaling Engine**: Implemented a font-centric scaling logic where `LINE_HEIGHT`, `BAR_HEIGHT`, and `BUTTON_SIZE` are calculated as multiples of `FONT_SIZE`.
- **HidingUI Group Logic**: Introduced a systematic way to batch-toggle UI elements during `InputText` execution to prevent z-index overlapping and layout flickering.
- **Absolute Centering Formula**: Developed a robust vertical alignment algorithm using Section Variables `[Meter:Y]` to ensure sub-pixel precision across different font metrics.

### Changed
- **Progress Bar Rendering Architecture**: 
  - Refactored `Meter=Shape` to use a multi-layered composite structure.
  - Applied a `0.5px` Y-axis offset and `-1px` height delta to `Shape2` and `Shape3` to counteract anti-aliasing "bleeding" and border-thickening artifacts.
- **Icon Rendering Protocol**: Migrated from generic Material Icon ligatures to specific Unicode point references (`[\xe7f5]`, etc.) in `MUI.inc` to resolve path-fill inversion issues.

### Fixed
- **Recursive Refresh Loop Fix**: 
  - Migrated the refresh logic from `.ini` (Calc Measure) to the Lua `Initialize()` function.
  - Implemented a **State-Aware Boot Refresh**: The script now uses a `NeedsRefresh` flag to trigger exactly one final refresh upon skin initialization. This ensures all Lua-generated dynamic meters are properly registered by the Rainmeter engine without causing an infinite loop.
- **Cumulative Relative Positioning Bug**: Fixed the "staircase effect" where icons cascaded downwards due to recursive `Y=...r` positioning in loops.
- **UTF-16 LE BOM Encoding**: Implemented a dedicated BOM handler to prevent data corruption when saving Traditional Chinese characters in `tasks.txt`.
- **Input Field Collision**: Resolved a bug where the Task Input field would overlap with the Title/Date meters on smaller skin widths.

### Technical Notes
- **UI Metrics**: The baseline for vertical alignment is now calculated as: 
  `Y = ([BaseMeter:Y] + ([BaseMeter:H] - [TargetMeter:H]) / 2)`.
- **Refresh Optimization**: By moving the refresh trigger to Lua, we reduced CPU spikes during skin loading and ensured a 100% success rate for dynamic include file generation.

## [1.0.0] - 2026-01-05
### Added, delete, sort, trash bin
- Basic functions