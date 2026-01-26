local resPath = GlobalResPath
local lib = {}

local json = dofile(resPath .. "json.lua")
local utf16BomHandler = dofile(resPath .. "utf16BomHandler.lua")

local ipairs     = ipairs
local print      = print

local log = {
	level = "info",
	levels = { error=1, warn=2, info=3, debug=4 }
}

----------------------------------------------------------------
-- 1. 單一項目類別 (Item Class)
----------------------------------------------------------------
local TaskItem = {}
TaskItem.__index = TaskItem

function TaskItem.new(data, index, parent)
	local proxy = { _data = data, _index = index, _parent = parent }
    setmetatable(proxy, {
        __index = function(t, key)
            if TaskItem[key] then return TaskItem[key] end
            return t._data[key]
        end,
        
        __newindex = function(t, key, value)
            t._data[key] = value
            
            -- 檢查父層 (Collection) 的 autoSave 開關
            print(t._parent.autoSave)
            if t._parent.autoSave then
                log:print("info", "AutoSave 觸發: 正在存入 " .. t._parent.filePath)
                t._parent:save()
            else
                log:print("info", "AutoSave 已關閉，修改僅保留於記憶體中")
            end
        end
    })
    return proxy
end

function TaskItem:update()
    -- 將目前的資料寫回父層陣列並存檔
    self._parent._raw_data[self._index] = {
        title = self.title,
        check = self.check,
        remind = self.remind,
        important = self.important,
        desc = self.desc
    }
    self._parent:save()
    log:print("info", "Task " .. self._index .. " updated.")
end

function TaskItem:delete()
    -- 叫父層刪除自己
    self._parent:delete(self._index)
end

function TaskItem:isRemind()
    return self.remind == true
end

function TaskItem:isCheck()
    return self.check == true
end

function TaskItem:isImportant()
    return self.important == true
end

function TaskItem:isCombine()
    return self.remind == true and self.important == true
end

----------------------------------------------------------------
-- 2. 集合類別 (Collection Class)
----------------------------------------------------------------
local TaskCollection = {}
TaskCollection.__index = function(table, key)
    -- 如果 key 是數字 (例如 tasks[1])，回傳包裝過的 TaskItem
    if type(key) == "number" then
        if table._raw_data[key] then
            return TaskItem.new(table._raw_data[key], key, table)
        end
        return nil
    end
    -- 否則回傳 TaskCollection 定義的函數 (例如 tasks.read)
    return TaskCollection[key]
end

function TaskCollection.new(filePath, options)
    local self = setmetatable({}, TaskCollection)
    self.filePath = filePath
    options = options or {}
    self.autoSave = (options.autoSave == true) -- 預設為 false，除非明確傳入 true

    if lib.file_exists(filePath) then
    	self._raw_data = self:load()
    else
    	self._raw_data = {}
    	self:save()
    end
    return self
end

----------------------------------------------------------------
-- 在 TaskCollection 類別中新增 create 方法
----------------------------------------------------------------
function TaskCollection:create(task)
	if type(task) == "table" or type(task) == "string" then
		if type(task) == "string" then
			-- 1. 準備新的資料結構
    		local newData = {
    		    title = task
    		}
    		task = newData
		end 

		-- 1. 準備新的資料結構
		-- 目前不需要有什麼調整的結構，接收直接存
		-- 2. 放入原始資料陣列 (Lua table.insert)
    	table.insert(self._raw_data, task)

    	-- 3. 取得剛才插入的索引位置
    	local newIndex = #self._raw_data
	
    	-- 4. 存檔到 JSON
    	self:save()
    	
    	-- 5. 回傳包裝好的 TaskItem 物件，這樣你可以立即對它進行操作
    	return TaskItem.new(self._raw_data[newIndex], newIndex, self)
	end
	-- 若obj 格式有誤，回傳空 obj
	log:print("error", "Wrong task type of create:" .. type(task))
    return {}
end

-- 讀取 JSON
function TaskCollection:load()
	local content, encoding = utf16BomHandler.read(self.filePath)
    -- 這裡假設你使用的 JSON 庫函數是 json.decode
    -- return json.decode(content)
    return json.decode(content)
end

-- 存檔 JSON
function TaskCollection:save()
	return utf16BomHandler.write(self.filePath, json.encode(self._raw_data))
end

function TaskCollection:read(index)
    return self[index] -- 觸發 __index 邏輯
end

function TaskCollection:delete(index)
    local target = self._raw_data[index]
    if not target then return false end

    -- 先丟到垃圾桶
    self:_addToTrash(target)

    -- 再正式刪除
    table.remove(self._raw_data, index)
    self:save()
    log:print("info", "Task " .. index .. " deleted and moved to trash.")
    return true
end

-- 讓 Collection 可以用 #tasks 取得長度
function TaskCollection:count()
    return #self._raw_data
end

----------------------------------------------------------------
-- 垃圾桶功能 (Trash System)
----------------------------------------------------------------
-- 私有函數：管理 trash.json 的寫入與 10 筆限制
function TaskCollection:_addToTrash(itemData)
    local trashPath = self.filePath:gsub("tasks", "trash")
    local trashData = {}

    -- 1. 讀取現有的垃圾桶
    if lib.file_exists(trashPath) then
        local content = utf16BomHandler.read(trashPath)
        trashData = json.decode(content) or {}
    end

    -- 2. 將新刪除的資料塞到最前面 (index 1)
    table.insert(trashData, 1, {
        data = itemData,
        deletedAt = os.date("%Y-%m-%d %H:%M:%S")
    })

    -- 3. 限制只保留 10 筆
    while #trashData > 10 do
        table.remove(trashData) -- 移除最後一筆 (最舊的)
    end

    -- 4. 存檔
    utf16BomHandler.write(trashPath, json.encode(trashData))
    log:print("info", "Task moved to trash. Current trash count: " .. #trashData)
end

-- 新增 restore 方法 (回復最近一筆)
function TaskCollection:restore()
    local trashPath = self.filePath:gsub("tasks", "trash")
    if not lib.file_exists(trashPath) then return false end

    local trashData = json.decode(utf16BomHandler.read(trashPath))
    if #trashData == 0 then return false end

    -- 1. 取出最近的一筆 (index 1)
    local lastDeleted = table.remove(trashData, 1)

    -- 2. 重新寫回垃圾桶 (更新剩下的資料)
    utf16BomHandler.write(trashPath, json.encode(trashData))

    -- 3. 呼叫 create 重新加入目前的清單
    self:create(lastDeleted.data)
    
    log:print("info", "Task restored from trash.")
    return true
end

function TaskCollection:swap(indexA, indexB)
    -- 1. 安全檢查：確保索引都在範圍內
    local count = self:count()
    if indexA < 1 or indexA > count or indexB < 1 or indexB > count then
        log:print("warn", "Switch 失敗：索引超出範圍 (" .. indexA .. ", " .. indexB .. ")")
        return false
    end

    -- 2. 如果索引相同，不需要對調
    if indexA == indexB then return true end

    -- 3. 執行對調 (Lua 的多重賦值語法非常適合做這個)
    self._raw_data[indexA], self._raw_data[indexB] = self._raw_data[indexB], self._raw_data[indexA]

    -- 4. 存檔
    self:save()
    
    log:print("info", "已對調 Task " .. indexA .. " 與 " .. indexB)
    return true
end

-- 往上移一格
function TaskCollection:moveUp(index)
    if index > 1 then
        return self:swap(index, index - 1)
    end
    return false
end

-- 往下移一格
function TaskCollection:moveDown(index)
    if index < self:count() then
        return self:swap(index, index + 1)
    end
    return false
end

----------------------------------------------------------------
-- 暴露 API
----------------------------------------------------------------
function lib.tasks(filePath, options)
    return TaskCollection.new(filePath, options)
end

function lib.file_exists(filePath)
  	local f = io.open(filePath, "r")
  	if f then
  	  	io.close(f)
  	  	return true
  	else
  	  	return false
  	end
end

function lib.file_create(filePath, content)
	return utf16BomHandler.write(filePath,content)
end

function lib.get_content(filePath, default_content_if_create)
	--Get Content and Encoding from input path
	--local inputpath = SKIN:MakePathAbsolute(filePath)
	local content, encoding

	if lib.file_exists(filePath) then
		content, encoding = utf16BomHandler.read(filePath)
	else
		if default_content_if_create == nil then
			default_content_if_create = ""
		end
		content = lib.file_create(filePath, default_content_if_create)
	end
	return content
end

-- 在 lib.lua 的匯入區塊添加
function lib.import(fromPath, targetCollection)
    -- 1. 檢查來源檔案
    if not lib.file_exists(fromPath) then
        log:print("error", "Import source not found: " .. fromPath)
        return false
    end

    -- 2. 使用你的 utf16BomHandler 讀取內容 (這會自動轉為 UTF-8)
    local content, enc = utf16BomHandler.read(fromPath)
    if not content then
        log:print("error", "Failed to read import file.")
        return false
    end
    
    log:print("info", "Importing " .. enc .. " file from: " .. fromPath)

    -- 3. 關閉 autoSave 以提升大量匯入效能
    local originalAutoSave = targetCollection.autoSave
    targetCollection.autoSave = false

    -- 4. 逐行解析
    local count = 0
    -- 使用 gmatch 分離每一行 (相容 LF 和 CRLF)
    for line in content:gmatch("[^\n]+") do
        local taskData = lib._parse_line(line)
        if taskData then
            targetCollection:create(taskData)
            count = count + 1
        end
    end

    -- 5. 恢復 autoSave 並手動執行一次大存檔
    targetCollection.autoSave = originalAutoSave
    targetCollection:save()

    log:print("info", "Successfully imported " .. count .. " tasks.")
    return true
end

-- 核心解析邏輯 (支援 title|check|remind|important)
function lib._parse_line(line)
    -- 去除頭尾空白
    line = line:match("^%s*(.-)%s*$")
    if line == "" then return nil end

    if line:find("|") then
        local fields = {}
        -- 技巧：在末尾加 | 確保捕捉最後一個空欄位
        for segment in (line .. "|"):gmatch("([^|]*)|") do
            table.insert(fields, segment)
        end

        return {
            title     = fields[1] or "Untitled",
            check     = lib.to_bool(fields[2]),
            remind    = lib.to_bool(fields[3]),
            important = lib.to_bool(fields[4]),
            desc      = fields[5] or ""
        }
    else
        return { title = line } -- 格式 B: 純文字
    end
end

-- 輔助函數：解析字串中的布林值 (處理 "true" 轉為 true)
function lib.to_bool(str)
    if str == "true" or str == "1" then return true end
    return false
end

function lib.get_filename()
	local info = debug.getinfo(1).source

    -- 1. 取得完整路徑 (去掉開頭的 @)
    local fullPath = info:sub(1,1) == "@" and info:sub(2) or info
    
    -- 2. 僅取得檔名 (例如: lib.lua)
    local fileName = fullPath:match("([^\\/]+)$")
    
    -- 3. 取得不含副檔名的名稱 (例如: lib)
    local nameOnly = fileName:match("(.+)%..+")
    
    --print("完整路徑: " .. fullPath)
    --print("檔案名稱: " .. fileName)
    --print("純檔案名: " .. nameOnly)
    return nameOnly
end

function log:print(lvl, msg)
	if self.levels[lvl] <= self.levels[self.level] then
		print(string.format("[%s] %s\n", lvl:upper(), msg))
	end
end
lib.log = log

return lib
