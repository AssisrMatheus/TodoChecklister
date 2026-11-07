--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.EncodingUtils = {}

---@class EncodingUtils
local EncodingUtils = TodoAddon.EncodingUtils

-- Pure Lua 5.1, no game API: share strings must read the same on every client, including ones without C_EncodingUtil.
-- The text encoding follows LibDeflate's EncodeForPrint (https://github.com/SafeteeWoW/LibDeflate): 6 bits per
-- character, least significant bits first, with an alphabet that avoids "|" (WoW's escape character), "+", "/" and "="
local ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()"

local charToValue = {}
local valueToChar = {}
for i = 1, #ALPHABET do
	local char = ALPHABET:sub(i, i)
	valueToChar[i - 1] = char
	charToValue[char] = i - 1
end

--------------------------------------
-- EncodingUtils functions
--------------------------------------

---
---Turns any byte string into printable characters that survive copy and paste through an edit box
---@param bytes string @Any string, binary included
---@return string @Only characters from ALPHABET. 3 bytes become 4 characters
function EncodingUtils:EncodeForPrint(bytes)
	local output = {}
	---@type number, number
	local cache, cacheBits = 0, 0
	for i = 1, #bytes do
		cache = cache + bytes:byte(i) * 2 ^ cacheBits
		cacheBits = cacheBits + 8
		while (cacheBits >= 6) do
			local value = cache % 64
			output[#output + 1] = valueToChar[value]
			cache = (cache - value) / 64
			cacheBits = cacheBits - 6
		end
	end
	if (cacheBits > 0) then
		output[#output + 1] = valueToChar[cache]
	end
	return table.concat(output)
end

---
---Reverses EncodeForPrint. Whitespace anywhere is ignored, so line breaks added while pasting don't matter
---@param text string @Output of EncodeForPrint
---@return string|nil @The original bytes, nil when text has a character EncodeForPrint never writes
function EncodingUtils:DecodeForPrint(text)
	text = text:gsub("%s+", "")
	local output = {}
	---@type number, number
	local cache, cacheBits = 0, 0
	for i = 1, #text do
		local value = charToValue[text:sub(i, i)]
		if (not value) then
			return nil
		end
		cache = cache + value * 2 ^ cacheBits
		cacheBits = cacheBits + 6
		if (cacheBits >= 8) then
			local byte = cache % 256
			output[#output + 1] = string.char(byte --[[@as integer]])
			cache = (cache - byte) / 256
			cacheBits = cacheBits - 8
		end
	end
	return table.concat(output)
end

---
---Writes a string so it can be read back from the middle of a longer one: its length, a colon, then the string
---@param value string
---@return string
function EncodingUtils:WriteString(value)
	return #value .. ":" .. value
end

---
---Reads a string written by WriteString
---@param data string @The whole payload
---@param position integer @Where the length starts
---@return string|nil, integer @The string (nil when data is malformed), and the position right after it
function EncodingUtils:ReadString(data, position)
	local colon = data:find(":", position, true)
	if (not colon) then
		return nil, position
	end
	local length = tonumber(data:sub(position, colon - 1))
	if (not length or length < 0 or length % 1 ~= 0 or colon + length > #data) then
		return nil, position
	end
	---@cast length integer
	return data:sub(colon + 1, colon + length), colon + length + 1
end
