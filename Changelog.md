# Changelog

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