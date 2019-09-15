--------------------------------------
-- Namespaces
--------------------------------------
local addonName, core = ...;
core.Constants = {}; -- adds Config table to addon namespace

local Constants = core.Constants;

--------------------------------------
-- Defaults (usually a database!)
--------------------------------------
Constants.debugMode = true;
Constants.addonName = addonName;
Constants.theme = {
	red = 0, 
	green = 0.8, -- 204/255
	blue = 1,
	hex = "00ccff"
};