--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

---@class EncodingUtils
local EncodingUtils = TodoAddon.EncodingUtils
---@class TodoList
local TodoList = TodoAddon.TodoList

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.ListShare = {}

---@class ListShare
local ListShare = TodoAddon.ListShare

---
---A list as it travels in a share string
---@class SharedList
---@field public name string
---@field public items TodoItem[]

-- !!! Share strings are user data too: people post them in guild chat, Discord and websites, and paste them into any
-- version of the addon, older or newer, on any flavor. Follow the USER DATA SAFETY rules in utils/migrationUtils.lua:
-- never change how an existing version reads, and never reuse a version number !!!
--
-- A share string is PREFIX .. version .. ":" .. minVersion .. "!" .. EncodeForPrint(payload).
--   version     the format that wrote it
--   minVersion  the oldest format reader that can still read it. A newer format that only adds data keeps it low, so
--               older addons still import the parts they know. A format older readers can't parse raises it
-- Version 1 payload, all strings written with EncodingUtils:WriteString:
--   name, listExtra, then per item: one hex digit of flags, text, itemExtra
-- listExtra and itemExtra are "" in version 1 and ignored by its reader. They are where an additive newer format puts
-- new data (say, a note per item), so a version 1 reader skips it instead of failing. Flags beyond these 4 go there too
local PREFIX = "!TodoChecklister:"
local VERSION = 1
local MIN_VERSION = 1

local FLAG_CHECKED = 1
local FLAG_FOLDER = 2
local FLAG_COLLAPSED = 4
local FLAG_IN_FOLDER = 8

---@param flags number
---@param flag number
---@return boolean|nil @true when the flag is set, nil otherwise, which is how the saved items store false
local function HasFlag(flags, flag)
	return (flags % (flag * 2) >= flag) or nil
end

--------------------------------------
-- ListShare functions
--------------------------------------

---
---@param name string @The name of a saved list
---@return string|nil @A string that ImportString reads back on any client. nil when the list doesn't exist
function ListShare:Export(name)
	local items = TodoChecklisterDB.lists[name]
	if (not items) then
		return nil
	end

	local payload = {EncodingUtils:WriteString(name), EncodingUtils:WriteString("")}
	for _, item in ipairs(items) do
		local flags = 0
		if (item.isChecked) then
			flags = flags + FLAG_CHECKED
		end
		if (item.isFolder) then
			flags = flags + FLAG_FOLDER
		end
		if (item.isCollapsed) then
			flags = flags + FLAG_COLLAPSED
		end
		if (item.inFolder) then
			flags = flags + FLAG_IN_FOLDER
		end
		payload[#payload + 1] =
			string.format("%x", flags) .. EncodingUtils:WriteString(item.text or "") .. EncodingUtils:WriteString("")
	end

	return PREFIX .. VERSION .. ":" .. MIN_VERSION .. "!" .. EncodingUtils:EncodeForPrint(table.concat(payload))
end

---
---SHIPPED FORMAT: never change what it accepts. Also reads newer formats whose minVersion is 1
---@param payload string @A decoded payload of version 1, or of a newer version with minVersion 1
---@return SharedList|nil
local function ReadVersion1(payload)
	local name, listExtra, position
	name, position = EncodingUtils:ReadString(payload, 1)
	listExtra, position = EncodingUtils:ReadString(payload, position)
	if (not name or not listExtra) then
		return nil
	end

	local items = {}
	while (position <= #payload) do
		local flags = tonumber(payload:sub(position, position), 16)
		local text, itemExtra
		text, position = EncodingUtils:ReadString(payload, position + 1)
		itemExtra, position = EncodingUtils:ReadString(payload, position)
		if (not flags or not text or not itemExtra) then
			return nil
		end
		items[#items + 1] = {
			text = text,
			isChecked = HasFlag(flags, FLAG_CHECKED) or false,
			isFolder = HasFlag(flags, FLAG_FOLDER),
			isCollapsed = HasFlag(flags, FLAG_COLLAPSED),
			inFolder = HasFlag(flags, FLAG_IN_FOLDER)
		}
	end
	return {name = name, items = items}
end

---Readers by the format version they read. Add one per new format; never remove or change one
local readers = {
	[1] = ReadVersion1
}
local LATEST_READER = #readers

---
---Reads a share string. Nothing is saved: pass the result to TodoChecklisterFrame:ImportList
---@param text string @What the user pasted
---@return SharedList|nil, string|nil @The list and, when it came from a newer version, a note that some details may be
---missing. Or nil and a message saying why it can't be read
function ListShare:Decode(text)
	text = strtrim(text or "")
	if (text:sub(1, #PREFIX) ~= PREFIX) then
		return nil, "This is not a TodoChecklister list"
	end

	local versionText, minVersionText, encoded = text:match("^(%d+):(%d+)!(.*)$", #PREFIX + 1)
	local version, minVersion = tonumber(versionText), tonumber(minVersionText)
	if (not version or not minVersion or not encoded) then
		return nil, "This list is incomplete or damaged"
	end
	if (minVersion > LATEST_READER) then
		return nil, "This list was made by a newer version of TodoChecklister. Update the addon to import it"
	end

	-- A newer format that kept minVersion low still reads with the newest reader here, which skips what it doesn't know
	local readerVersion = math.min(version, LATEST_READER)
	local reader = readers[readerVersion]
	local payload = EncodingUtils:DecodeForPrint(encoded --[[@as string]])
	local list = reader and payload and reader(payload)
	if (not list) then
		return nil, "This list is incomplete or damaged"
	end
	if (version > LATEST_READER) then
		return list, "Made by a newer version of TodoChecklister: update the addon to import every detail"
	end
	return list
end
