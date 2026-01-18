OUT_OF_SESSION_COLOR="20,20,20,30"
OUT_OF_SESSION_FONT_COLOR="255,255,255,100"
OUT_OF_SESSION="OUT OF SESSION"
MACRO_COLOR="0,80,150,180"
WHITE_COLOR="255,255,255,200"
LIGHT_COLOR="255,255,255,150"
COUNTDOWN_COLOR="255,255,255,150"
ALERT_COLOR="255,0,0,150"

notifyTimer = 0
notifyMessage = ""
notifyColor = WHITE_COLOR
lastMacroState = false
NOW_UTC = os.time(os.date("!*t"))

DEBUG_MODE = false
DEBUG_NY_TIME_STR="2026-01-13 10:51:51"

local nextRetryTime = 0 
local RETRY_INTERVAL = 3600 -- 每小時 (3600秒) 重試一次

-- ==========================================
-- 2026 年美股休市與特殊交易日判定
-- ==========================================
local holidays2026 = {
    ["2026-01-01"] = "NEW YEAR'S DAY",
    ["2026-01-19"] = "MLK DAY",
    ["2026-02-16"] = "PRESIDENTS' DAY",
    ["2026-04-03"] = "GOOD FRIDAY",
    ["2026-05-25"] = "MEMORIAL DAY",
    ["2026-06-19"] = "JUNETEENTH",
    ["2026-07-03"] = "INDEPENDENCE DAY (OBS)",
    ["2026-09-07"] = "LABOR DAY",
    ["2026-11-26"] = "THANKSGIVING",
    ["2026-12-25"] = "CHRISTMAS DAY"
}

-- 提早 13:00 休市的日期
local earlyClose2026 = {
    ["2026-11-27"] = "EARLY CLOSE (13:00)", -- Black Friday
    ["2026-12-24"] = "EARLY CLOSE (13:00)"  -- Christmas Eve
}


local json
local CurrentEvents = {}

-- 配置：你感興趣的關鍵字
local targetKeywords = { "GDP", "PPI", "CPI", "FOMC", "Unemployment" }
-- 在腳本最上方定義這兩個變數，方便 Update 讀取
local upcomingNewsCD = ""
local upcomingNewsTitle = ""
local upcomingNewsDiff = 0  -- 新增：儲存剩餘秒數
local offset = -5

-- 2. 使用 Initialize 函數 (Rainmeter 專用，初始化時會執行一次)
function Initialize()
    -- 獲取 json.lua 的完整路徑
    local jsonPath = SKIN:GetVariable('@') .. 'json.lua'
    
    -- 使用 loadfile 載入檔案內容
    local f, err = loadfile(jsonPath)
    
    --if f then json = f() end
    if f then
        json = f() -- 執行檔案並將回傳的物件給 json 變數
        print("JSON Library Loaded Successfully via loadfile")
    else
        print("JSON Load Error: " .. tostring(err))
        --!Log "There was an error!" Error
    end

    local thisMonday = GetThisMonday()
    local filteredPath = SKIN:GetVariable('CURRENTPATH') .."News\\".. thisMonday .. ".json"
    
    local f = io.open(filteredPath, "r")
    if f then
        -- 檔案已存在，直接載入過濾後的資料
        local content = f:read("*all")
        f:close()
        -- 【修正：增加長度檢查】
        if content and #content > 0 then
            local success, decoded = pcall(json.decode, content)
            if success then
                CurrentEvents = decoded
                print(">>> [Init] Loaded cached news for " .. thisMonday)
            else
                print(">>> [Init] JSON 格式錯誤，準備重抓...")
                SKIN:Bang('!EnableMeasure', 'MeasureJSONRaw')
                SKIN:Bang('!CommandMeasure', 'MeasureJSONRaw', 'Update')
            end
        else
            print(">>> [Init] 快取檔案為空，準備重抓...")
            SKIN:Bang('!EnableMeasure', 'MeasureJSONRaw')
            SKIN:Bang('!CommandMeasure', 'MeasureJSONRaw', 'Update')
        end
    else
        -- make sure don't have raw.json then praser from internet
        local rawNewsPath = SKIN:GetVariable('CURRENTPATH') .."News\\".. thisMonday .. "-raw.json"
        local rawFile = io.open(rawNewsPath, "r")
        if rawFile then
            local rawJsonStr = rawFile:read("*all")
            rawFile:close()
            -- 【修正處】直接傳入字串，不要先 decode
            CurrentEvents = FilterNewsAndSave(rawJsonStr)
            print(">>> [Init] Found local raw.json, filtered and loaded.")
        else
            -- 檔案不存在，說明這週還沒抓過，啟動 WebParser
            SKIN:Bang('!EnableMeasure', 'MeasureJSONRaw') -- 1. 先啟動
            SKIN:Bang('!CommandMeasure', 'MeasureJSONRaw', 'Update')
        end
    end
end

function ProcessNews(now_utc)
    if not json then return end

    local displayList = {}
    local maxDisplay = 4

    -- debug
    if DEBUG_MODE then
        local formattedDate = os.date("%b %d %a", now_utc)
        print(formattedDate) -- 輸出結果範例: Jan 10 Fri
    end
    
    local isBlinking = 0  -- 用於控制背景是否閃爍
    local countdownText = ""

    upcomingNewsCD = ""    -- 每次執行先清空
    upcomingNewsTitle = ""
    upcomingNewsDiff = 0    -- 重設

    -- debug
    if DEBUG_MODE then
        -- This is what I using to print the timestamp
        local ev_time = os.time({year=2026, month=01, day=17, hour=08, min=30, sec=00})
        local ev_utc = ev_time + (5 * 3600)
        print(ev_utc)
    end

    if CurrentEvents and #CurrentEvents > 0 then
        for i, event in ipairs(CurrentEvents) do
            local diff = event.utc_timestamp - now_utc

            --print(event.title)

            -- 處理顯示列表 (僅顯示未發生的)
            if diff > 0 then
                local dayStr = os.date("%a", event.utc_timestamp)
                local shortTime = event.ny_time:sub(-5)
                
                -- 如果是第一筆且在 15 分鐘內
                if upcomingNewsCD == "" and diff <= 900 then
                    upcomingNewsDiff = diff -- 儲存精確秒數
                    local m = math.floor(diff / 60)
                    local s = diff % 60
                    upcomingNewsCD = string.format("%02d:%02d", m, s)
                    countdownText = upcomingNewsCD -- 也要同步給 local 變數，列表才會顯示
                    upcomingNewsTitle = event.title
                    
                    -- 最後 10 秒閃爍
                    if diff <= 10 then isBlinking = 1 end
                end

                local eventString = string.format("[%s %s] %s", dayStr, shortTime, event.title)
                table.insert(displayList, eventString)
                if #displayList >= maxDisplay then break end
            end
        end
    end

    -- 將結果傳回 Rainmeter
    local hasNews = (#displayList > 0)
    local finalDisplay = hasNews and table.concat(displayList, "\n") or "No More News"
    
    
    SKIN:Bang('!SetVariable', 'EventDisplay', finalDisplay)
    SKIN:Bang('!SetVariable', 'IsNewsFlash', isBlinking)
   
    return "OK"
    
end

-- 通知觸發函數：支援訊息、秒數、顏色
function SetNotification(msg, seconds, color)
    notifyMessage = msg
    notifyTimer = os.time() + seconds
    notifyColor = color or OUT_OF_SESSION_FONT_COLOR -- 若未指定則預設白色
end

function Update()

    -- 1. 自動計算紐約夏令時 (DST)
    -- 拿 UTC 算新聞
    local now_utc = GetCurrentTime(false)
        -- 拿 紐約時間 (自動處理 -4/-5) 算 Session 與顯示
    local ny_now_ts = GetCurrentTime(true)

    -- 核心檢查：如果目前資料無效 (全是舊聞)
    if not DEBUG_MODE and not CheckDataValidity() then
        -- 如果已經到了重試時間
        if os.time() >= nextRetryTime then
            print(">>> [Data Watchdog] No future news found. Retrying fetch...")
            SKIN:Bang('!EnableMeasure', 'MeasureJSONRaw')
            SKIN:Bang('!CommandMeasure', 'MeasureJSONRaw', 'Update')
            -- 設定下一次重試時間
            nextRetryTime = os.time() + RETRY_INTERVAL
        end
    end

    -- 取得紐約當下的日期資訊
    -- wday:1=週日, 6=週五, 7=週六
    local d = os.date("*t", ny_now_ts)
    local wday, h = d.wday, d.hour
    local dateKey = os.date("%Y-%m-%d", ny_now_ts)

    -- --- 判定各項開關 ---
    local holidayName = holidays2026[dateKey]
    local earlyCloseName = earlyClose2026[dateKey]
    
    -- A. 徹底關閉：週五 17:00 後 ~ 週六全天 (這段時間不看新聞)
    local isStrictlyClosed = (wday == 6 and h >= 17) or (wday == 7)
    
    -- B. 準備模式：週日全天 OR 國定休假日 OR 提早收盤後的時段
    local isHoliday = (holidayName ~= nil)
    local isEarlyClosePassed = (earlyCloseName and h >= 13)
    local isSunday = (wday == 1)
    local isPrepMode = isSunday or isHoliday or isEarlyClosePassed

    -- ==========================================
    -- 1. 邏輯：週五晚與週六 (徹底休息)
    -- ==========================================
    if isStrictlyClosed then
        -- 週末模式：隱藏所有動態面板，顯示「MARKET CLOSED」
        SKIN:Bang('!SetVariable', 'Message', "MARKET CLOSED")
        SKIN:Bang('!SetVariable', 'MessageColor', OUT_OF_SESSION_FONT_COLOR)
        SKIN:Bang('!SetVariable', 'CountdownText', "")
        SKIN:Bang('!SetVariable', 'BarPercent', "0")
        SKIN:Bang('!SetVariable', 'HideMacro', "1")
        SKIN:Bang('!SetVariable', 'HideCountdown', "1")
        SKIN:Bang('!SetVariable', 'HideCountdownBar', "1")
        SKIN:Bang('!SetVariable', 'HideNewsToggleButton', "1") -- 週末不顯示新聞按鈕
        SKIN:Bang('!HideMeterGroup', 'NewsGroup')
        
        -- 更新日期與時鐘即可，不執行後續的 Session 判定
        SKIN:Bang('!SetVariable', 'CurrentSessionColor', OUT_OF_SESSION_COLOR)
        if DEBUG_MODE then
            SKIN:Bang('!SetVariable', 'CurrentDate', os.date("%b %d %a %H:%M:%S", ny_now_ts))
        else
            SKIN:Bang('!SetVariable', 'CurrentDate', os.date("%b %d %a", ny_now_ts))
        end
        SKIN:Bang('!Redraw')
        return "OK" 
    end

    -- ==========================================
    -- 2. 邏輯：準備模式 (週日/休假日/提早收盤後)
    --    功能：顯示新聞，隱藏 Session/Macro
    -- ==========================================
    if isPrepMode then
        -- 執行新聞處理，以便週日看下週計畫
        ProcessNews(now_utc)
        
        local hasNews = (CurrentEvents and #CurrentEvents > 0)
        local showNewsVar = tonumber(SKIN:GetVariable('SHOW_NEWS')) or 0
        
        if hasNews then
            SKIN:Bang('!SetVariable', 'HideNewsToggleButton', "0")
            if showNewsVar == 1 then SKIN:Bang('!ShowMeterGroup', 'NewsGroup') end
        end

        -- 動態設定顯示文字
        local msg = "WEEKEND PREP"
        if holidayName then msg = holidayName -- 例如顯示 "MLK DAY"
        elseif isEarlyClosePassed then msg = earlyCloseName -- 例如 "EARLY CLOSE (13:00)"
        end

        SKIN:Bang('!SetVariable', 'Message', "WEEKEND PREP")
        SKIN:Bang('!SetVariable', 'MessageColor', LIGHT_COLOR)
        SKIN:Bang('!SetVariable', 'CurrentSessionColor', OUT_OF_SESSION_COLOR)
        SKIN:Bang('!SetVariable', 'HideMacro', "1")
        SKIN:Bang('!SetVariable', 'HideCountdown', "1")
        SKIN:Bang('!SetVariable', 'HideCountdownBar', "1")
        SKIN:Bang('!UpdateMeter', 'MeterNews')
        SKIN:Bang('!UpdateMeter', 'MeterNewsBG')
        if DEBUG_MODE then
            SKIN:Bang('!SetVariable', 'CurrentDate', os.date("%b %d %a %H:%M:%S", ny_now_ts))
        else
            SKIN:Bang('!SetVariable', 'CurrentDate', os.date("%b %d %a", ny_now_ts))
        end

        SKIN:Bang('!Redraw')
        return "OK"
    end

    -- ==========================================
    -- 邏輯 C：正常交易時段 (週日 17:00 ~ 週五 16:59)
    -- ==========================================
    ProcessNews(now_utc)
    
    -- 15 mins
    local countdown_sec = 900
    local currentTime = os.time()
    local displayTitle = ""
    local displayColor = ""
    local notify_duration = tonumber(SKIN:GetVariable('NOTIFY_DURATION')) or 5

    -- Windows 環境下 %#d 可以去掉前導零，若要固定兩位數則用 %d
    -- 更新左上角日期 (Sep 04 Fri)
    if DEBUG_MODE then
        SKIN:Bang('!SetVariable', 'CurrentDate', os.date("%b %d %a %H:%M:%S", ny_now_ts))
    else
        SKIN:Bang('!SetVariable', 'CurrentDate', os.date("%b %d %a", ny_now_ts))
    end

    -- ==========================================
    -- 核心修正點：直接從 ny_now_ts 取得時間，不要用 Measure
    -- ==========================================
    local d = os.date("*t", ny_now_ts)
    local h, m, s = d.hour, d.min, d.sec

    --[[
    local ny_time_m = SKIN:GetMeasure('MeasureNYTime')
    if not ny_time_m then return "Waiting for Measure..." end
    
    local ny_time_str = ny_time_m:GetStringValue()
    --if ny_time_str == "" then return "Initializing..." end

    -- 拆解 時:分:秒
    local h, m, s = ny_time_str:match("(%d+):(%d+):(%d+)")
    h, m, s = tonumber(h), tonumber(m), tonumber(s)
    ]]
    local hhmm = h * 100 + m
    local total_now_seconds = (h * 3600) + (m * 60) + s

    -- 3. Session 資料表
    local sessions = {
        {start=0300, stop=0400, name="SILVER BULLET",    color="0,80,150,100", fColor="255,255,255,150"},
        {start=1000, stop=1100, name="SILVER BULLET",    color="0,80,150,100", fColor="255,255,255,150"},
        {start=1400, stop=1500, name="SILVER BULLET",    color="0,80,150,100", fColor="255,255,255,150"},
        {start=2000, stop=2400, name="ASIA SESSION",     color="255,215,0,30",  fColor="255,255,255,150"},
        {start=0200, stop=0500, name="LONDON SESSION",   color="0,255,255,20",  fColor="255,255,255,150"},
        {start=0930, stop=1100, name="NY AM SESSION",    color="238,118,104,15",  fColor="255,255,255,150"},
        {start=1330, stop=1600, name="NY PM SESSION",    color="238,118,104,15", fColor="255,255,255,150"}
    }

    local resName, resColor, resFont = OUT_OF_SESSION, OUT_OF_SESSION_COLOR, OUT_OF_SESSION_FONT_COLOR
    local barPercent = 0
    local barColor = "0,0,0,0" -- 沒倒數時設為全透明

    -- ==========================================
    -- 7. 財經日曆 JSON 解析邏輯
    -- ==========================================

    

   -- 4. 邏輯 A: 判定當前 Session (依時長自動判斷主次)
    local active_sessions = {}
    
    for _, sess in ipairs(sessions) do
        local is_active = false
        -- 考慮跨午夜的時長計算
        local duration = 0
        local start_sec = (math.floor(sess.start / 100) * 3600) + (sess.start % 100 * 60)
        local stop_sec = (math.floor(sess.stop / 100) * 3600) + (sess.stop % 100 * 60)
        
        if sess.start < sess.stop then
            is_active = (hhmm >= sess.start and hhmm < sess.stop)
            duration = stop_sec - start_sec
        else
            is_active = (hhmm >= sess.start or hhmm < sess.stop)
            duration = (86400 - start_sec) + stop_sec
        end

        if is_active then
            sess.currentDuration = duration -- 暫存時長用於排序
            table.insert(active_sessions, sess)
        end
    end

    -- 排序：時長長的在前
    table.sort(active_sessions, function(a, b) return a.currentDuration > b.currentDuration end)

    local mainSess = active_sessions[1] -- 最長的 (例如 London)
    local subSess = active_sessions[#active_sessions] -- 最短的 (例如 Silver Bullet)
    if mainSess == subSess then subSess = nil end -- 如果只有一個，就沒有次要

    -- 輸出結果決定
    if mainSess and subSess then
        resName = mainSess.name .. " : " .. subSess.name
        resColor = mainSess.color   -- 主背景用大盤色
        resFont = mainSess.fColor
        subColor = subSess.color    -- 給你稍後要用的邊框或副標題
    elseif mainSess then
        resName, resColor, resFont = mainSess.name, mainSess.color, mainSess.fColor
        subColor = "0,0,0,0"
    else
        resName, resColor, resFont = OUT_OF_SESSION, OUT_OF_SESSION_COLOR, OUT_OF_SESSION_FONT_COLOR
        subColor = "0,0,0,0"
    end

    -- 5. 判定倒數 (包含倒數時間文字)
    local min_diff = 999999
    local active_bar_color = "0,0,0,0"
    local active_bar_percent = 0
    local countdown_text = ""

    for _, sess in ipairs(sessions) do
        local s_h = math.floor(sess.start / 100)
        local s_m = sess.start % 100
        local total_start_seconds = (s_h * 3600) + (s_m * 60)
        
        local diff = total_start_seconds - total_now_seconds
        if diff <= 0 then diff = diff + 86400 end

        -- 檢查此 Session 是否已在 active_sessions 中
        local is_already_active = false
        for _, active in ipairs(active_sessions) do
            if active.name == sess.name and active.start == sess.start then
                is_already_active = true
                break
            end
        end

        if not is_already_active and diff < min_diff then
            min_diff = diff
            if diff <= countdown_sec then
                -- 【通知邏輯 B：偵測 Session 倒數 (15分鐘整)】
                -- 假設你目前的變數名為 next_sess_name 且 diff 是倒數秒數
                if diff == 900 then 
                    -- 觸發通知：顯示 10 秒
                    SetNotification(sess.name .. " COMING SOON", notify_duration)
                end

                active_bar_percent = diff / countdown_sec
                active_bar_color = sess.color
                
                -- 格式化倒數時間: MM:SS
                local m_left = math.floor(diff / 60)
                local s_left = diff % 60
                countdown_text = string.format("%02d:%02d", m_left, s_left)
            end
        end
    end

    barPercent = active_bar_percent
    barColor = active_bar_color

    -- 5. Macro 邏輯 (前 15 分縮減，後 15 分增長)
    local macroLeft = 0   -- 後 15 分 (45-60)
    local macroRight = 0  -- 前 15 分 (00-15)
    local total_m_sec = (m * 60) + s
    local mColor = "0,0,0,0"
    local hideMacro = 1

    if m < 15 then
        -- 前 15 分鐘：由左向右縮減 (1.0 -> 0.0)
        macroRight = 1 - (total_m_sec / 900)
    elseif m >= 45 then
        -- 後 15 分鐘：由左向右縮減 (1.0 -> 0.0)
        -- 注意：這裡邏輯是計算經過了多少百分比
        macroLeft = 1 - ((total_m_sec - 2700) / 900)
    end

    SKIN:Bang('!SetVariable', 'MacroLeft', macroLeft)
    SKIN:Bang('!SetVariable', 'MacroRight', macroRight)
    
    if (m < 15 or m >= 45) then
        if m < 15 then
            -- 前 15 分鐘：由左向右縮減 (1.0 -> 0.0)
            macroRight = 1 - (total_m_sec / 900)
        elseif m >= 45 then
            -- 後 15 分鐘：由左向右縮減 (1.0 -> 0.0)
            -- 注意：這裡邏輯是計算經過了多少百分比
            macroLeft = 1 - ((total_m_sec - 2700) / 900)
        end
        mColor = MACRO_COLOR
        hideMacro = 0 
    end

    -- 【通知邏輯 A：偵測 Macro 開始】
    local is_currently_macro = (m < 15 or m >= 45)
    if is_currently_macro and not lastMacroState then
        -- 觸發通知：顯示 10 秒，顏色設為亮青色
        SetNotification("IN MACRO...", notify_duration)
    end
    lastMacroState = is_currently_macro

    -- ==========================================
    -- 優先級判定：1. 通知 > 2. 新聞倒數 > 3. Session
    -- ==========================================
    local finalMessage = resName          -- 預設為 Session 名稱
    local finalCountdown = countdown_text -- 預設為 Session 倒數
    local finalMsgColor = resFont         -- 預設為 Session 字體顏色
    local finalBarColor = barColor
    local finalBarPercent = barPercent
    local finalCountdownColor = COUNTDOWN_COLOR

    -- 【最終MESSAGE顯示判定】
    if notifyTimer > 0 and currentTime < notifyTimer then
        -- 顯示「暫時通知」狀態
        finalMessage = notifyMessage
        finalMsgColor = notifyColor

    -- 邏輯 B：如果有新聞倒數 (優先於 Session)
    elseif upcomingNewsCD ~= "" then
        finalMessage = "NEWS: " .. upcomingNewsTitle .. " in"
        finalCountdown = upcomingNewsCD
        finalMsgColor = WHITE_COLOR       -- 新聞時讓文字全亮
        finalBarColor = ALERT_COLOR       -- 倒數條變白色 (共用變數)
        finalCountdownColor = WHITE_COLOR

        -- 【核心修改：計算新聞進度比例】
        -- 比例 = 剩餘秒數 / 900秒 (15分鐘)
        -- 使用 math.min/max 確保數值在 0~1 之間
        finalBarPercent = math.max(0, math.min(1, upcomingNewsDiff / 900))
        --SKIN:Bang('!SetVariable', 'HideCountdown', 0)
        --SKIN:Bang('!SetVariable', 'HideCountdownBar', 0)
    else
        -- 回歸「正常顯示」狀態
        displayTitle = subSess and (mainSess.name.." : "..subSess.name) or (mainSess and mainSess.name or OUT_OF_SESSION)
        displayColor = OUT_OF_SESSION_FONT_COLOR -- 正常狀態的預設白色
    end

    -- 邏輯：使用者在變數裡設為隱藏Macro，都不顯示 Macro Bar
    if ((hideMacro == 0) and (SKIN:GetVariable('SHOW_MACRO_BAR') == "0")) then 
        hideMacro = 1
    end

    -- ==========================================
    -- 最後統一更新變數
    -- ==========================================
    -- 如果沒有倒數文字，則設為 1 (隱藏)，否則設為 0 (顯示)
    -- 邏輯：如果沒文字，或者使用者在變數裡設為隱藏，則結果為 1
    local hideCD = ((finalCountdown == "") or (SKIN:GetVariable('SHOW_COUNTDOWN') == "0")) and 1 or 0
    local hideCD_bar = ((finalCountdown == "") or (SKIN:GetVariable('SHOW_COUNTDOWN_BAR') == "0")) and 1 or 0
    SKIN:Bang('!SetVariable', 'HideCountdown', hideCD)
    SKIN:Bang('!SetVariable', 'HideCountdownBar', hideCD_bar)

    SKIN:Bang('!SetVariable', 'Message', finalMessage)
    SKIN:Bang('!SetVariable', 'MessageColor', finalMsgColor)
    SKIN:Bang('!SetVariable', 'CountdownText', finalCountdown)
    SKIN:Bang('!SetVariable', 'CountdownColor', finalCountdownColor)
    SKIN:Bang('!SetVariable', 'NextSessionColor', ForceOpaque(finalBarColor, 200)) -- 可用於邊框或進度條

    SKIN:Bang('!SetVariable', 'MacroColor', mColor)
    SKIN:Bang('!SetVariable', 'HideMacro', hideMacro)
    SKIN:Bang('!SetVariable', 'BarPercent', finalBarPercent)
    SKIN:Bang('!SetVariable', 'CurrentSessionColor', resColor)         -- 主背景
    SKIN:Bang('!SetVariable', 'SubSessionColor', ForceOpaque(subColor, 150))             -- 重疊時的副顏色 (邊框)

    -- 幫助你確認 Lua 算出來的顏色到底是什麼
    --SKIN:Log("Notify Color: " .. notifyColor .. " | Display Color: " .. displayColor, "Debug")

    -- ==========================================
    -- 核心修正：統一控制新聞群組顯示與按鈕隱藏
    -- ==========================================
    
    -- 1. 重新確認是否有新聞 (由 ProcessNews 填充的 CurrentEvents)
    local hasNews = false
    local now_utc = GetCurrentTime(false)

    if CurrentEvents and #CurrentEvents > 0 then
        -- 檢查是否還有未來的事件
        for _, ev in ipairs(CurrentEvents) do
            if ev.utc_timestamp - now_utc > 0 then
                hasNews = true
                break
            end
        end
    end

    -- 2. 獲取使用者開關狀態 (0 或 1)
    local showNewsVar = tonumber(SKIN:GetVariable('SHOW_NEWS')) or 0
    
    -- 3. 執行邏輯判斷
    if hasNews then
        -- 有新聞時：顯示按鈕
        SKIN:Bang('!SetVariable', 'HideNewsToggleButton', '0')
        
        -- 判斷是否展開面板 (使用者想看才展開)
        if showNewsVar == 1 then
            SKIN:Bang('!ShowMeterGroup', 'NewsGroup')
        else
            SKIN:Bang('!HideMeterGroup', 'NewsGroup')
        end
        --print("HideNewsToggleButton:0,SHOW_NEWS:" .. showNewsVar .. ", hasNews:" .. tostring(hasNews))
    else
        -- 沒新聞時：隱藏按鈕與面板
        SKIN:Bang('!SetVariable', 'HideNewsToggleButton', '1')
        SKIN:Bang('!HideMeterGroup', 'NewsGroup')
        --print("HideNewsToggleButton:1,SHOW_NEWS:" .. showNewsVar .. ", hasNews:" .. tostring(hasNews))
    end

    SKIN:Bang('!UpdateMeter', 'MeterNews')
    SKIN:Bang('!UpdateMeter', 'MeterNewsBG')

    SKIN:Bang('!Redraw')

    return "OK"
    --return "NY: " .. ny_time_str .. " | Session: " .. resName
end

-- 輸入 "80,80,80,150", 輸出 "80,80,80,alpha"
function ForceOpaque(colorStr, alpha)
    if not colorStr or colorStr == "0,0,0,0" or colorStr == "" then return "0,0,0,0" end
    -- 抓取前三個數字 (R, G, B)
    local r, g, b = colorStr:match("(%d+),(%d+),(%d+)")
    if r and g and b then
        return r .. "," .. g .. "," .. b .. "," .. (alpha or "255") -- 強制設定 Alpha 為 255
    end
    return colorStr
end

-- 這是由 WebParser 抓完資料後觸發的回調函數
function OnDownloadComplete()
    local measureObj = SKIN:GetMeasure('MeasureJSONRaw')
    if not measureObj then return end
    
    local rawJsonStr = measureObj:GetStringValue()
    if rawJsonStr == "" then return end

    -- 先試著過濾看看，但不馬上存檔
    local tempData = FilterNews(rawJsonStr)
    
    -- 驗貨：檢查這份新抓到的資料有沒有未來新聞
    local now_utc = GetCurrentTime(false)
    local isDataNew = false
    for _, ev in ipairs(tempData) do
        if ev.utc_timestamp > now_utc then
            isDataNew = true
            break
        end
    end

    if isDataNew then
        -- 貨是對的：儲存、更新全域變數、關閉重試
        local thisMonday = GetThisMonday() -- 取得本週一的日期字串 YYYY-MM-DD
        local resPath = SKIN:GetVariable('CURRENTPATH') .."News\\"
    
        -- 1. 儲存 Raw Data 檔案 (日期-raw.json)
        local rawFile = io.open(resPath .. thisMonday .. "-raw.json", "w")
        if rawFile then
            rawFile:write(rawJsonStr)
            rawFile:close()
            print("Raw data saved: " .. thisMonday .. "-raw.json")
        end
    
        -- 2. 執行過濾並儲存 Filtered Data (日期.json)
        -- FilterNews 是你之前的邏輯：只抓 USD High Impact 且包含關鍵字的
        CurrentEvents = FilterNewsAndSave(rawJsonStr)
        -- 4. 執行清理 (刪除 31 天前的雙檔案)
        CleanupCache(resPath)
        -- disable MeasureJSONRaw prevent unnassary download
        SKIN:Bang('!DisableMeasure', 'MeasureJSONRaw')
        print(">>> [Fetcher] Successfully updated to the NEW week's calendar.")
    else
        -- 貨是舊的：不存檔，讓 Update() 裡的計時器繼續跑
        print(">>> [Fetcher] Server still providing OLD calendar. Waiting for next hourly retry.")
    end
end

function CleanupCache(path)
    -- 計算約一個月前 (31天) 的時間戳
    local oneYearAgoTime = os.time() - (365 * 86400)
    
    -- 取得那一週的週一日期
    local d = os.date("*t", oneYearAgoTime)
    local diff = (d.wday == 1) and 6 or (d.wday - 2)
    local targetDate = os.date("%Y-%m-%d", oneYearAgoTime - (diff * 86400))
    
    -- 嘗試刪除兩個檔案，並正確使用 os.remove 的回傳值
    local files = { targetDate .. ".json", targetDate .. "-raw.json" }
    
    for _, fileName in ipairs(files) do
        local success, err = os.remove(path .. fileName)
        if success then
            print(">>> [Cleanup] 成功刪除舊檔: " .. fileName)
        elseif err and not err:find("No such file") then
            -- 只有在「不是因為找不到檔案」的錯誤才印出（例如權限問題）
            print(">>> [Cleanup] 刪除失敗 (" .. fileName .. "): " .. err)
        end
    end
end

-- 獲取本週一的日期字串 (格式: YYYY-MM-DD)
function GetThisMonday()
    local now = GetCurrentTime(false)
    local d = os.date("*t", now)
    
    -- d.wday: 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
    
    local diff
    if d.wday == 1 then
        -- 【關鍵修正】如果是週日 (1)，我們想要的是「明天」(下週一)
        -- 所以位移設為 +1 天 (86400 秒)
        diff = 1
    else
        -- 如果是週一到週六，邏輯維持不變：找回這週的週一
        -- 週二(3)要減1天，週三(4)要減2天... 週六(7)要減5天
        diff = 2 - d.wday
    end
    
    local targetTime = now + (diff * 86400)
    return os.date("%Y-%m-%d", targetTime)
end

-- 過濾邏輯
function FilterNews(rawData)
    local data = json.decode(rawData)
    local filtered = {}
    if not data then return filtered end

    for _, event in ipairs(data) do
        -- 1. 條件過濾：USD + High Impact
        if event.country == "USD" and event.impact == "High" then
        --if event.country == "USD" then
            -- 2. 解析原始時間 (ISO 格式)
            local year, month, day, hr, min, sc = event.date:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
            
            -- 3. 核心處理：將這組數字直接重新格式化為「純紐約時間」
            -- 我們不再存那個帶有時區尾巴的 ISO 字串，改存易讀格式
            local ny_date_string = string.format("%s-%s-%s %s:%s", year, month, day, hr, min)

            -- 4. 計算 UTC Timestamp (為了讓 ProcessNews 依然能精準倒數)
            local ev_time = os.time({year=year, month=month, day=day, hour=hr, min=min, sec=sc})
            local ev_utc = ev_time + (5 * 3600) 

            -- 5. 存入新表格
            table.insert(filtered, {
                title = event.title,
                country = event.country,
                impact = event.impact,
                ny_time = ny_date_string,   -- 這是給你看的紐約時間
                utc_timestamp = ev_utc      -- 這是給程式算的秒數
            })
        end
    end
    return filtered
end

function FilterNewsAndSave(rawStr)
    -- 1. 呼叫 Filter 邏輯 (接收字串，回傳 Table)
    local filteredTable = FilterNews(rawStr) 
    
    -- 2. 存檔 (將 Table 轉回字串存檔)
    local thisMonday = GetThisMonday()
    local resPath = SKIN:GetVariable('CURRENTPATH') .."News\\"
    local filteredFile = io.open(resPath .. thisMonday .. ".json", "w")
    if filteredFile then
        filteredFile:write(json.encode(filteredTable))
        filteredFile:close()
        print("Filtered data saved: " .. thisMonday .. ".json")
    end

    return filteredTable
end

-- ==========================================
-- 終極時間函數：自動處理 DST、DEBUG 與偏移
-- @param applyOffset: (布林值) 是否套用自動判定的紐約偏移 (-4 或 -5)
-- @return: Timestamp
-- ==========================================
function GetCurrentTime(applyOffset)
    local base_utc
    
    -- 1. 取得基準 UTC 時間
    if DEBUG_MODE then
        local debugStr = DEBUG_NY_TIME_STR
        local y, m, d, h, min, s = debugStr:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
        if y then
            -- 假設 Debug 字串是紐約時間，我們先推回 UTC (Debug 基準建議用 -5)
            base_utc = os.time({year=y, month=m, day=d, hour=h, min=min, sec=s}) + (5 * 3600)
        else
            base_utc = os.time(os.date("!*t"))
        end
    else
        base_utc = os.time(os.date("!*t"))
    end

    -- 2. 如果不需偏移，直接回傳 UTC
    if not applyOffset then return base_utc end

    -- 3. 自動計算該年份的 DST 範圍 (美國標準：3月第二個週日 ~ 11月第一個週日)
    local nowT = os.date("!*t", base_utc)
    local year = nowT.year
    local dst_start = os.time({year=year, month=3, day=14 - (os.date("*t", os.time({year=year, month=3, day=1})).wday - 1), hour=7})
    local dst_end = os.time({year=year, month=11, day=7 - (os.date("*t", os.time({year=year, month=11, day=1})).wday - 1), hour=6})
    
    -- 4. 判定偏移量
    offset = (base_utc >= dst_start and base_utc < dst_end) and -4 or -5
    
    -- 順便更新 Skin 的變數，讓 .ini 也能顯示正確的 UTC 字樣
    SKIN:Bang('!SetVariable', 'NYOffset', offset)
    
    return base_utc + (offset * 3600)
end

function CheckDataValidity()
    local now_utc = GetCurrentTime(false)
    if not CurrentEvents or #CurrentEvents == 0 then return false end
    
    -- 檢查是否有任何一則新聞的時間是在「現在」之後
    for _, ev in ipairs(CurrentEvents) do
        if ev.utc_timestamp > now_utc then
            return true -- 找到未來新聞，資料有效
        end
    end
    return false -- 全是舊聞，資料無效
end