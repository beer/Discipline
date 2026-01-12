# ✔️ Rainmeter Trading Tracker

A small Rainmeter widget to help track trading setups and monitor daily trading rules. Designed for traders who want a quick reference while taking screenshots for their trading journey.
This project is based on [rainmeter-todo](https://github.com/alperenozlu/rainmeter-todo), with additional features tailored for trading, including setup tracking, rule checks, and multi-layered progress tracking.

## 🎞️ Preview

Here are some preview photos you can check out.

![Screenshot of Rainmeter Trading-Tracker](screenshots/photo-example-6.png)
![Screenshot of Rainmeter Trading-Tracker](screenshots/photo-example-1.png)
![Screenshot of Rainmeter Trading-Tracker](screenshots/photo-example-3.png)
![Screenshot of Rainmeter Trading-Tracker](screenshots/photo-example-4.png)
![Screenshot of Rainmeter Trading-Tracker](screenshots/photo-example-5.png)
![Screenshot of Rainmeter Trading-Tracker](screenshots/photo-example-2.png)


## 📝 Features

- **Task Management**: Add, Delete, and Reorder criteria with ease. Supports "Remind" and "Important" flagging.
- **Trash Bin System**: Recover accidentally deleted rules or setups.
- **Screenshot Mode**: Hide edit options for a cleaner widget.
- **Minimize Mode**: Toggle between a full list and a clean title-only view.
- **Multi-Layer Progress Bar**: Visualizes Major Tasks (Important) and Minor Tasks separately within a single unified bar.
- **Chinese Support**: an be in Chinese, but needs to be copy-pasteable.

## Install

1. Install [Rainmeter](https://www.rainmeter.net/) if you don’t have it already.
2. Load this skin in Rainmeter.
3. Customize your trading setups and daily rules to track your trades.
4. Use it while taking screenshots to document your trading journey.

###### Via Installer

+ Go to the [Releases](https://github.com/beer/rainmeter-trading-tracker/releases) page and download the latest .rmskin file.
+ Install skin with a double click to the downloaded file.
+ [Activate the skin](#activate-skin)

###### Via Source Code

- Download this source code and place the entire `rainmeter-trading-tracker` folder in the location of your Rainmeter skin. Generally it is look like `C:\Users\<USERNAME>\Documents\Rainmeter\Skins\`
- [Activate the skin](#activate-skin)

##### Activate Skin

- Activate `rainmeter-trading-tracker` skin
  - You can do this by right-clicking on an already active skin to bring up the Rainmeter menu
  - Navigate to `Rainmeter > Skins > rainmeter-trading-tracker > Setups/Rules > Large/Medium/Small.ini`
    - If you do not see `rainmeter-trading-tracker` in the skin selection, try navigating to `Rainmeter > Refresh all`

# 🖋️ Customize & Trading Tracker Variables Guide (User Settings)

You can fully customize your Trading Tracker by editing the `[Variables]` section within the `.ini` file. Below is a detailed breakdown of each setting:

## 1. General Appearance & Features
Controls the basic layout and visibility of UI elements.

| Variable | Description | Recommended / Example |
| :--- | :--- | :--- |
| `TITLE` | The title displayed at the top of the widget. | `TITLE=Daily Trading Rules` |
| `SolidColor` | Background color and transparency (R,G,B,Alpha). | `0,0,0,150` (Dark Semi-transparent) |
| `SkinWidth` | The overall width of the widget. | `350` (Recommended minimum) |
| `SHOW_REMIND` | Toggle "Reminder" icons (Does not affect progress). | `0` (Off), `1` (On) |
| `SHOW_IMPORTANT`| Toggle "Major" icons (Affects 80% of progress). | `0` (Off), `1` (On) |
| `SHOW_DATE` | Show/Hide the date at the bottom. | `0` (Off), `1` (On) |
| `SHOW_TIME` | Show/Hide the time (Static, updates on refresh). | `0` (Off), `1` (On) |

## 2. Typography & Dynamic Scaling
This widget uses **Dynamic Proportional Scaling**. You only need to adjust `FONT_SIZE`, and other dimensions will scale automatically to maintain alignment.

| Variable | Description | Default Formula / Ref |
| :--- | :--- | :--- |
| `FONT_FACE` | The name of the font to be used. | `Inter`, `Arial`, `Roboto` |
| `FONT_SIZE` | Base font size for all text. | `12` (Default), `15` (Large) |
| `LINE_HEIGHT` | Vertical spacing between task lines. | `(#FONT_SIZE# * 2.1)` |
| `BUTTON_SIZE` | Size of all action icons (Add, Refresh, etc.). | `(#FONT_SIZE# + 2)` |
| `BAR_HEIGHT` | Thickness of the progress bar at the bottom. | `(#FONT_SIZE# * 2)` |

## 3. Color Configuration
Colors use the format `Red, Green, Blue, Alpha` (Range: 0-255).

### 🔹 Task Text Colors
| Task Type | Active (Pending) Color | Ticked (Completed) Color |
| :--- | :--- | :--- |
| **Normal Rules** | `ACTIVE_TASK_COLOR` | `DONE_TASK_COLOR` |
| **Major Rules** | `IMPORTANT_TASK_COLOR` | `DONE_IMPORTANT_TASK_COLOR` |

### 🔹 Progress Bar Colors
* **ColorTodo**: Background color of the bar (Incomplete portion).
* **ColorDone**: Fill color for completed normal rules.
* **ColorMajorDone**: Fill color for completed major rules (Usually a high-contrast color).

## 4. Advanced Logic
| Variable | Description | Default Value |
| :--- | :--- | :--- |
| `MAX_MAJOR_DONE_RATE` | Max percentage weight for rules marked as "Major". | `80` (Major rules take 80%) |
| `TRASH_LIMIT` | Maximum number of deleted items kept in the trash. | `10` |

---

## 💡 Quick Tips for Customization
1. **Visual Balance**: For a modern look, try using a vibrant Cyan or Orange for `ColorMajorDone`.
2. **Transparency**: The 4th value (Alpha) in colors controls opacity. `0` is invisible, `255` is fully solid.
3. **Applying Changes**: After saving your `.ini` file, **Right-click the widget > Refresh skin** to see the updates immediately.


## 🤖 Technical Details & Notes

### 🗒️ Tasks and Editing Tasks Manually

In an emergency, you may want to edit the task file manually. For this, you must first know the structure of the task file.

- **First Line**: `task|x|x` (Header info, do not delete).
- **Remind Tasks**: Excluded from the progress bar to focus on core execution.
- **Important Tasks**: Counted as "Major Progress" and highlighted on the bar.

| 1         | 2            | 3            | 4            |
| --------- | ------------ | ------------ | ------------ |
| Task Text | Is Completed | Is Remind | Is Important |

For example, a completed and important task would look like this `task title|x||x` 
    
If it's just a completed task, it's look like `task title|x||` 

### ☁️ Sync With Multiple Device

Added and deleted tasks are stored on a file basis. Since there is no database connection, you can use programs such as Google Drive, Dropbox, and OneDrive to synchronize between multiple devices.

- Go to `rainmeter-trading-tracker` folder in your Rainmeter skins location
- Start the sync process for the folder you are using through the cloud program you use.

### 😔 Known Bugs and Issues
- If Windows commands are entered as a task, the relevant command is triggered.
- If the task contains the `'` character, it's not saved.

---
*This widget is tailored for professional trading documentation. Contributions and feedback are welcome!*
