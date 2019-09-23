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

--------------------------------------
-- Settings functions
--------------------------------------

---@return boolean @Whether or not the window is displayed on the user's screen
function Settings:IsShown()
	return TodoChecklisterSettingsDB.isShown
end

---@param isShown boolean @Sets whether or not the window is displayed on the user's screen
function Settings:SetIsShown(isShown)
	TodoChecklisterSettingsDB.isShown = isShown
end

---@return boolean @Whether or not the KeepFocus checkbox is checked
function Settings:KeepFocus()
	return TodoChecklisterSettingsDB.keepFocus
end

---
---Toggles whether or not the KeepFocus checkbox is checked
function Settings:ToggleFocus()
	TodoChecklisterSettingsDB.keepFocus = not self:KeepFocus()
end

---@return boolean @Whether or not the KeepFocus checkbox is displayed to the user
function Settings:IsKeepFocusShown()
	return TodoChecklisterSettingsDB.isKeepFocusShown
end

---@param isKeepFocusShown boolean @Sets whether or not the KeepFocus checkbox is displayed to the user
function Settings:SetIsKeepFocusShown(isKeepFocusShown)
	TodoChecklisterSettingsDB.isKeepFocusShown = isKeepFocusShown
end

---@return number @The alpha value of 0 to 1 for the window opacity
function Settings:Opacity()
	return TodoChecklisterSettingsDB.windowOpacity
end

---@param isKeepFocusShown boolean @Sets the alpha value of 0 to 1 for the window opacity
function Settings:SetOpacity(opacity)
	TodoChecklisterSettingsDB.windowOpacity = opacity
end

---@return boolean @Whether or not a fanfare sound should be played
function Settings:PlayFanfare()
	return TodoChecklisterSettingsDB.playFanfare
end

---@param playFanfare boolean @Sets whether or not a fanfare sound should be played
function Settings:SetPlayFanfare(playFanfare)
	TodoChecklisterSettingsDB.playFanfare = playFanfare
end

---@return boolean @Whether or not to display linked items count from bag
function Settings:DisplayLinked()
	return TodoChecklisterSettingsDB.displayLinked
end

---@param displayLinked boolean @Sets whether or not to display linked items count from bag
function Settings:SetDisplayLinked(displayLinked)
	TodoChecklisterSettingsDB.displayLinked = displayLinked
end

--------------------------------------
-- Lifecycle Events
--------------------------------------
---
---Resets all properties to their default values
function Settings:Defaults()
	TodoChecklisterSettingsDB =
		TableUtils:Assign(
		TodoChecklisterSettingsDB,
		{
			isShown = true,
			keepFocus = false,
			isKeepFocusShown = true,
			windowOpacity = 1,
			playFanfare = true,
			displayLinked = true
		}
	)
end

---
---Initializes required properties for this class
function Settings:Init()
	if (not TodoChecklisterSettingsDB) then
		---
		---The SavedVariable where the settings are stored into
		---@class TodoSettings
		---@field public isShown boolean|nil @Whether or not the window is displayed on the user's screen
		---@field public keepFocus boolean|nil @Whether or not the KeepFocus checkbox is checked
		---@field public isKeepFocusShown boolean|nil @Whether or not the KeepFocus checkbox is displayed to the user
		---@field public windowOpacity number|nil @The alpha value of 0 to 1 for the window opacity
		---@field public playFanfare boolean|nil @Whether or not a fanfare sound should be played
		---@field public displayLinked boolean|nil @Whether or not to display linked items count from bag
		TodoChecklisterSettingsDB = {}
		self:Defaults()
	end

	if (TodoChecklisterSettingsDB.isShown == nil) then
		self:SetIsShown(true)
	end

	if (TodoChecklisterSettingsDB.isKeepFocusShown == nil) then
		self:SetIsKeepFocusShown(true)
	end

	if (TodoChecklisterSettingsDB.playFanfare == nil) then
		self:SetPlayFanfare(true)
	end

	if (TodoChecklisterSettingsDB.displayLinked == nil) then
		self:SetDisplayLinked(true)
	end
end
