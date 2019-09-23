--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)
---@class Constants
local Constants = TodoAddon.Constants

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.Utils = {}

---@class Utils
local Utils = TodoAddon.Utils

--------------------------------------
-- Utils functions
--------------------------------------
function Utils:GetThemeColor()
	local theme = Constants.theme
	return theme.red, theme.green, theme.blue, theme.hex
end
