--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...
core.Settings = {} -- Creates an instance of this model
local Settings = core.Settings

local TableUtils = core.TableUtils

--------------------------------------
-- Settings functions
--------------------------------------
function Settings.IsShown()
	return TodoChecklisterSettingsDB.isShown
end

function Settings:SetIsShown(isShown)
	TodoChecklisterSettingsDB.isShown = isShown
end
