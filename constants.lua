--------------------------------------
-- Namespaces
--------------------------------------
local addonName, core = ...;
core.Constants = {}; -- adds Config table to addon namespace

local Constants = core.Constants;

if (not TodoChecklisterDB) then
	TodoChecklisterDB = {}
end

--------------------------------------
-- Defaults (usually a database!)
--------------------------------------
Constants.debugMode = true;
Constants.addonName = addonName;
Constants.theme = {
	red = 0.8, -- 204/255
	green = 0.2, -- 51/255
	blue = 1,
	hex = "cc33ff"
};