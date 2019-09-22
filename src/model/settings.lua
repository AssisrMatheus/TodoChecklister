--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

---@class TableUtils
local TableUtils = TodoAddon.TableUtils

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.Settings = {}

---@class Settings
local Settings = TodoAddon.Settings

---
---The SavedVariable where the settings are stored into
---@class TodoSettings
---@field public isShown boolean|nil @Whether or not the window is displayed on the user's screen
---@field public keepFocus boolean|nil @Whether or not the KeepFocus checkbox is checked
---@field public isKeepFocusShown boolean|nil @Whether or not the KeepFocus checkbox is displayed to the user
---@field public windowOpacity number|nil @The alpha value of 0 to 1 for the window opacity
---@field public playFanfare boolean|nil @Whether or not a fanfare sound should be played
local DB

--------------------------------------
-- Settings functions
--------------------------------------

---@return boolean @Whether or not the window is displayed on the user's screen
function Settings.IsShown()
	return DB.isShown
end

---@param isShown boolean @Sets whether or not the window is displayed on the user's screen
function Settings:SetIsShown(isShown)
	DB.isShown = isShown
end

---@return boolean @Whether or not the KeepFocus checkbox is checked
function Settings:KeepFocus()
	return DB.keepFocus
end

---
---Toggles whether or not the KeepFocus checkbox is checked
function Settings:ToggleFocus()
	DB.keepFocus = not self:KeepFocus()
end

---@return boolean @Whether or not the KeepFocus checkbox is displayed to the user
function Settings:IsKeepFocusShown()
	return DB.isKeepFocusShown
end

---@param isKeepFocusShown boolean @Sets whether or not the KeepFocus checkbox is displayed to the user
function Settings:SetIsKeepFocusShown(isKeepFocusShown)
	DB.isKeepFocusShown = isKeepFocusShown
end

---@return number @The alpha value of 0 to 1 for the window opacity
function Settings:Opacity()
	return DB.windowOpacity
end

---@param isKeepFocusShown boolean @Sets the alpha value of 0 to 1 for the window opacity
function Settings:SetOpacity(opacity)
	DB.windowOpacity = opacity
end

---@return boolean @Whether or not a fanfare sound should be played
function Settings:PlayFanfare()
	return DB.playFanfare
end

---@param playFanfare boolean @Sets whether or not a fanfare sound should be played
function Settings:SetPlayFanfare(playFanfare)
	DB.playFanfare = playFanfare
end

--------------------------------------
-- Lifecycle Events
--------------------------------------
---
---Resets all properties to their default values
function Settings:Defaults()
	DB =
		TableUtils:Assign(
		DB,
		{
			isShown = true,
			keepFocus = false,
			isKeepFocusShown = true,
			windowOpacity = 1,
			playFanfare = true
		}
	)
end

---
---Initializes required properties for this class
function Settings:Init()
	DB = TodoChecklisterSettingsDB

	if (not DB) then
		DB = {}
		self:Defaults()
	end

	if (DB.isShown == nil) then
		self:SetIsShown(true)
	end

	if (DB.isKeepFocusShown == nil) then
		self:SetIsKeepFocusShown(true)
	end

	if (DB.playFanfare == nil) then
		self:SetPlayFanfare(true)
	end
end
