--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

---@class TableUtils
local TableUtils = TodoAddon.TableUtils
---@class MigrationUtils
local MigrationUtils = TodoAddon.MigrationUtils

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.Settings = {}

---@class Settings
local Settings = TodoAddon.Settings

-- !!! Read the USER DATA SAFETY rules in utils/migrationUtils.lua before changing the shape of
-- TodoChecklisterSettingsDB. A new setting is additive: give it a `== nil` default in Settings:Init, never a new format !!!

---
---TodoChecklisterSettingsDB (account-wide).
---Format 1: a flat table of settings, every key optional (filled with its default on load)
---@type MigrationSchema
local SETTINGS_SCHEMA = {
	current = 1,
	minSchemaVersion = 1,
	detect = function(db)
		return 1
	end,
	steps = {}
}

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

---@param opacity number @Sets the alpha value of 0 to 1 for the window opacity
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

---@return boolean @Whether or not to display the icon on minimap
function Settings:DisplayMinimapIcon()
	return TodoChecklisterSettingsDB.displayMinimapIcon
end

---@param displayMinimapIcon boolean @Whether or not to display the icon on minimap
function Settings:SetDisplayMinimapIcon(displayMinimapIcon)
	TodoChecklisterSettingsDB.displayMinimapIcon = displayMinimapIcon
end

---@return boolean @Whether or not to display chat messages
function Settings:ChatMuted()
	return TodoChecklisterSettingsDB.chatMuted
end

---@param displayLinked boolean @Sets whether or not to display chat messages
function Settings:SetChatMuted(chatMuted)
	TodoChecklisterSettingsDB.chatMuted = chatMuted
end

---@return number @The alpha value of 0 to 1 for the window opacity when hovering the mouse
function Settings:OpacityOnHover()
	return TodoChecklisterSettingsDB.windowOpacityOnHover
end

---@param opacity number @Sets the alpha value of 0 to 1 for the window opacity when hovering the mouse
function Settings:SetOpacityOnHover(opacity)
	TodoChecklisterSettingsDB.windowOpacityOnHover = opacity
end

---@return boolean @Whether or not should count bank items on linked items
function Settings:DisplayBankOnLinked()
	return TodoChecklisterSettingsDB.displayBankOnLinked
end

---@param displayBankOnLinked boolean @Whether or not should count bank items on linked items
function Settings:SetDisplayBankOnLinked(displayBankOnLinked)
	TodoChecklisterSettingsDB.displayBankOnLinked = displayBankOnLinked
end

---@return boolean @Whether or not should count charges on linked items
function Settings:DisplayChargesOnLinked()
	return TodoChecklisterSettingsDB.displayChargesOnLinked
end

---@param displayChargesOnLinked boolean @Sets whether or not should count charges on linked items
function Settings:SetDisplayChargesOnLinked(displayChargesOnLinked)
	TodoChecklisterSettingsDB.displayChargesOnLinked = displayChargesOnLinked
end

---@return boolean @Whether or not the list shows as a section of Blizzard's objective tracker (retail and Forever)
function Settings:DisplayInObjectiveTracker()
	return TodoChecklisterSettingsDB.displayInObjectiveTracker
end

---@param displayInObjectiveTracker boolean @Sets whether or not the list shows as a section of the objective tracker
function Settings:SetDisplayInObjectiveTracker(displayInObjectiveTracker)
	TodoChecklisterSettingsDB.displayInObjectiveTracker = displayInObjectiveTracker
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
			displayLinked = true,
			displayMinimapIcon = true,
			chatMuted = false,
			windowOpacityOnHover = 1,
			displayBankOnLinked = true,
			displayChargesOnLinked = true,
			displayInObjectiveTracker = true
		}
	)
end

---
---Loads (and upgrades when needed) the saved settings.
---When it returns "failed" or "incompatible" it changed nothing, and nothing may use Settings this session
---@return MigrationStatus, string|nil @What happened to the saved data, and the error when it failed
function Settings:Init()
	local db, status, err = MigrationUtils:Migrate(TodoChecklisterSettingsDB, SETTINGS_SCHEMA)
	if (status == "failed" or status == "incompatible") then
		return status, err
	end
	TodoChecklisterSettingsDB = db

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
		---@field public displayMinimapIcon boolean|nil @Whether or not to display the icon on minimap
		---@field public chatMuted boolean|nil @Whether or not to display chat messages
		---@field public windowOpacityOnHover number|nil @The alpha value of 0 to 1 for the window opacity when hovering the mouse
		---@field public displayBankOnLinked number|nil @Whether or not should count bank items on linked items
		---@field public displayChargesOnLinked number|nil @Whether or not should count charges on linked items
		---@field public displayInObjectiveTracker boolean|nil @Whether or not the list shows as a section of the objective tracker
		TodoChecklisterSettingsDB = MigrationUtils:Create({}, SETTINGS_SCHEMA)
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

	if (TodoChecklisterSettingsDB.displayMinimapIcon == nil) then
		self:SetDisplayMinimapIcon(true)
	end

	if (TodoChecklisterSettingsDB.displayBankOnLinked == nil) then
		self:SetDisplayBankOnLinked(true)
	end

	if (TodoChecklisterSettingsDB.displayChargesOnLinked == nil) then
		self:SetDisplayChargesOnLinked(true)
	end

	if (TodoChecklisterSettingsDB.displayInObjectiveTracker == nil) then
		self:SetDisplayInObjectiveTracker(true)
	end

	return status
end
