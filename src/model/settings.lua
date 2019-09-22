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

function Settings:KeepFocus()
	return TodoChecklisterSettingsDB.keepFocus
end

function Settings:ToggleFocus()
	TodoChecklisterSettingsDB.keepFocus = not self:KeepFocus()
end

function Settings:IsKeepFocusShown()
	return TodoChecklisterSettingsDB.isKeepFocusShown
end

function Settings:SetIsKeepFocusShown(isKeepFocusShown)
	TodoChecklisterSettingsDB.isKeepFocusShown = isKeepFocusShown
end

function Settings:Opacity()
	return TodoChecklisterSettingsDB.windowOpacity
end

function Settings:SetOpacity(opacity)
	TodoChecklisterSettingsDB.windowOpacity = opacity
end

function Settings:Defaults()
	TodoChecklisterSettingsDB =
		TableUtils:Assign(
		{},
		TodoChecklisterSettingsDB,
		{
			isShown = true,
			keepFocus = false,
			isKeepFocusShown = true,
			windowOpacity = 1
		}
	)
end

function Settings:Init()
	if (not TodoChecklisterSettingsDB) then
		TodoChecklisterSettingsDB = {}
	end

	if (self:IsKeepFocusShown() == nil) then
		self:SetIsKeepFocusShown(true)
	end

	if (not self:IsShown() == nil) then
		self:SetIsShown(true)
	end
end
