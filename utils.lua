--------------------------------------
-- Namespaces
--------------------------------------
local addonName, core = ...;
core.Utils = {}; -- adds Config table to addon namespace

local Utils = core.Utils;
local Constants = core.Constants;

--------------------------------------
-- Defaults (usually a database!)
--------------------------------------

--------------------------------------
-- Utils functions
--------------------------------------
function Utils:GetThemeColor()
	local theme = Constants.theme;
	return theme.red, theme.green, theme.blue, theme.hex;
end