--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.Constants = {}

---@class Constants
local Constants = TodoAddon.Constants

--------------------------------------
-- Defaults
--------------------------------------
Constants.debugMode = (UnitName("player") == "Assis") -- Not good but it's better than forgetting to set it back to false
Constants.theme = {
	red = 0.8, -- 204/255
	green = 0.2, -- 51/255
	blue = 1,
	hex = "cc33ff"
}

-- Global so XML can reference it through BackdropTemplate's backdropInfo KeyValue
TodoChecklister_BACKDROP = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = {left = 4, right = 4, top = 4, bottom = 4}
}
