local json
local sessions = {}
local hasSessions = false
local notifyTimer, notifyMessage, notifyColor = 0, "", ""
local lastCountdownState = 0 -- 紀錄上一秒是否在倒數 (0: 否, 1: 是)

local OUT_OF_SESSION_COLOR = "20,20,20,30"
local OUT_OF_SESSION_FONT_COLOR = "255,255,255,100"
local DEFAULT_COUNTDOWN = 3600

function Initialize()
    local jsonPath = SKIN:GetVariable('@') .. 'json.lua'
    local f = loadfile(jsonPath)
    if f then json = f() end

    local sessPath = SKIN:GetVariable('CURRENTPATH') .. "Sessions.json"
    local sess_f = io.open(sessPath, "r")
    if sess_f then
        local content = sess_f:read("*all")
        sess_f:close()
        if json then 
            sessions = json.decode(content) 
            hasSessions = (sessions and #sessions > 0)
        end
    end
end

function Update()
    local manualOffset = SKIN:GetVariable('TimeZoneOffset')
    local now_ts = GetTimeWithDST(manualOffset)
    
    local d = os.date("*t", now_ts)
    local hhmm = d.hour * 100 + d.min
    local total_now_seconds = (d.hour * 3600) + (d.min * 60) + d.sec

    local finalMsg, countdown_text, barPercent, nextColor, flashColor = "", "", 0, "0,0,0,0", nil
    local finalColor = OUT_OF_SESSION_FONT_COLOR
    local finalBG = OUT_OF_SESSION_COLOR
    local showCountdown = 0

    if hasSessions then
        print("in the session: hasSessions:" .. tostring(hasSessions))
        local flashState = math.floor(os.clock() % 2)
        for _, sess in ipairs(sessions) do
            local start_sec = (math.floor(sess.start / 100) * 3600) + (sess.start % 100 * 60)
            local diff = start_sec - total_now_seconds
            if diff < -43200 then diff = diff + 86400 end
            if diff > 43200 then diff = diff - 86400 end
            if sess.blinking and diff > 0 and diff <= sess.blinking then
                flashColor = (flashState == 1) and ForceOpaque(sess.color, 150) or nil
                break
            end
        end

        local active_sessions = {}
        for _, sess in ipairs(sessions) do
            local is_active = false
            local s_total = (math.floor(sess.start/100)*3600 + sess.start%100*60)
            local e_total = (math.floor(sess.stop/100)*3600 + sess.stop%100*60)
            if sess.start < sess.stop then
                is_active = (hhmm >= sess.start and hhmm < sess.stop)
                sess.duration = e_total - s_total
            else
                is_active = (hhmm >= sess.start or hhmm < sess.stop)
                sess.duration = (86400 - s_total) + e_total
            end
            if is_active then table.insert(active_sessions, sess) end
        end
        table.sort(active_sessions, function(a, b) return a.duration > b.duration end)

        -- C. 倒數邏輯 (嚴格過濾版)
        local min_diff = 999999
        
        local activeCountdownText = ""
        local activeBarPercent = 0
        local activeNextColor = "0,0,0,0"

        for _, sess in ipairs(sessions) do
            local t_start = (math.floor(sess.start / 100) * 3600) + (sess.start % 100 * 60)
            local diff = t_start - total_now_seconds
            
            -- 1. 處理跨日
            if diff <= 0 then diff = diff + 86400 end
            
            -- 2. 檢查是否已在該 Session 內
            local is_already_active = false
            for _, active in ipairs(active_sessions) do
                if active.name == sess.name then is_already_active = true break end
            end

            -- 3. 獲取倒數設定
            local sessCountdown = tonumber(sess.countdown) or DEFAULT_COUNTDOWN

            -- 【核心修正】：只有在符合所有條件時，才去更新顯示變數
            if not is_already_active and diff <= sessCountdown then
                -- 確保我們抓到的是「最近」的一個倒數
                if diff < min_diff then
                    min_diff = diff
                    activeCountdownText = string.format("%02d:%02d", math.floor(diff / 60), diff % 60)
                    activeBarPercent = diff / sessCountdown
                    activeNextColor = sess.color
                    showCountdown = 1
                end
            end
            -- --- 觸發倒數通知邏輯 ---
            if showCountdown == 1 and lastCountdownState == 0 then
                -- 剛進入倒數範圍的那一秒：觸發通知
                -- 這裡設定通知訊息、持續秒數 (如 5 秒)、顏色
                SetNotification(sess.name, 10)
            end
            -- 更新狀態給下一秒使用
            lastCountdownState = showCountdown
        end
        
        -- 將結果賦值給外部變數
        countdown_text = activeCountdownText
        barPercent = activeBarPercent
        nextColor = activeNextColor

        finalMsg = (active_sessions[1] and active_sessions[1].name) or ""
        finalColor = (active_sessions[1] and active_sessions[1].fColor) or OUT_OF_SESSION_FONT_COLOR
        finalBG = (active_sessions[1] and active_sessions[1].color) or OUT_OF_SESSION_COLOR
    end

    -- 新增：通知覆蓋邏輯 (若有 Active Notification)
    if notifyTimer > 0 and os.time() < notifyTimer then
        finalMsg, finalColor = notifyMessage, notifyColor
    end

    -- 5. 輸出變數至 Rainmeter
    -- 判定是否隱藏倒數與進度條：必須有 JSON 且正在倒數
    local finalHide = (hasSessions and showCountdown == 1) and "0" or "1"
    
    SKIN:Bang('!SetVariable', 'Message', finalMsg)
    SKIN:Bang('!SetVariable', 'MessageColor', finalColor)
    SKIN:Bang('!SetVariable', 'CurrentSessionColor', flashColor or finalBG)
    SKIN:Bang('!SetVariable', 'CountdownText', countdown_text)
    SKIN:Bang('!SetVariable', 'BarPercent', barPercent)
    SKIN:Bang('!SetVariable', 'NextSessionColor', ForceOpaque(nextColor,150))
    SKIN:Bang('!SetVariable', 'HideSessElements', finalHide)
    SKIN:Bang('!SetVariable', 'CurrentDate', os.date("%b %d %a", now_ts))

    return os.date("%H:%M:%S", now_ts)
end

function GetTimeWithDST(manualOffset)
    local utc = os.time(os.date("!*t"))
    
    -- 如果沒有手動設定時區，直接回傳本機時間，並動態計算目前的本機偏移值
    if not manualOffset or manualOffset == "" then 
        local local_ts = os.time()
        local diff = os.difftime(local_ts, utc)
        local currentOffset = math.floor(diff / 3600 + 0.5)
        SKIN:Bang('!SetVariable', 'NYOffset', (currentOffset >= 0 and "+" or "") .. currentOffset)
        return local_ts 
    end

    local offsetNum = tonumber(manualOffset)
    local nowT = os.date("!*t", utc)
    local year = nowT.year

    -- 1. 亞洲排除區 (固定時區)
    if offsetNum == 8 or offsetNum == 9 then
        -- 直接回傳，不改 offsetNum
    -- 2. 北美規則
    elseif offsetNum <= -4 and offsetNum >= -10 then
        local dst_start = os.time({year=year, month=3, day=14 - (os.date("*t", os.time({year=year, month=3, day=1})).wday - 1), hour=7})
        local dst_end = os.time({year=year, month=11, day=7 - (os.date("*t", os.time({year=year, month=11, day=1})).wday - 1), hour=6})
        if utc >= dst_start and utc < dst_end then offsetNum = offsetNum + 1 end
    -- 3. 澳洲規則
    elseif offsetNum >= 9.5 and offsetNum <= 11 then
        local this_year_start = os.time({year=year, month=10, day=7 - (os.date("*t", os.time({year=year, month=10, day=1})).wday - 1), hour=16})
        local this_year_end = os.time({year=year, month=4, day=7 - (os.date("*t", os.time({year=year, month=4, day=1})).wday - 1), hour=15})
        local last_year_start = os.time({year=year-1, month=10, day=7 - (os.date("*t", os.time({year=year-1, month=10, day=1})).wday - 1), hour=16})
        if (utc >= last_year_start and utc < this_year_end) or (utc >= this_year_start) then offsetNum = offsetNum + 1 end
    end

    SKIN:Bang('!SetVariable', 'NYOffset', (offsetNum >= 0 and "+" or "") .. offsetNum)
    return utc + (offsetNum * 3600)
end

function ForceOpaque(colorStr, alpha)
    if not colorStr or colorStr == "" then return "0,0,0,0" end
    local r, g, b = colorStr:match("(%d+),(%d+),(%d+)")
    return r .. "," .. g .. "," .. b .. "," .. (alpha or "255")
end

-- Notification setter function / 通知訊息設定函數
function SetNotification(msg, seconds, color)
    notifyMessage = msg
    notifyTimer = os.time() + seconds
    notifyColor = color or OUT_OF_SESSION_FONT_COLOR 
end