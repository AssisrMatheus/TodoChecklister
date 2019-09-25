--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

---@type string
local addonName = select(1, ...)

---@class Constants
local Constants = TodoAddon.Constants
---@class Settings
local Settings = TodoAddon.Settings
---@class MinimapIcon
local MinimapIcon = TodoAddon.MinimapIcon

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.InterfaceOptions = {}

---@class InterfaceOptions
local InterfaceOptions = TodoAddon.InterfaceOptions

--------------------------------------
-- Lifecycle Events
--------------------------------------
---
---Resets all properties to their default values
function InterfaceOptions:Defaults()
  -- This will also call Settings:Defaults
  TodoAddon.TodoChecklisterFrame:Defaults()
  self:LoadCFG()
  TodoAddon.MinimapIcon:LoadCFG()
end

---
---Load required configuration for this class
function InterfaceOptions:LoadCFG()
  if (self.frame) then
    self.frame.SettingsContainer.FocusCheckButton:SetChecked(Settings:IsKeepFocusShown())

    self.frame.SettingsContainer.FocusCheckButton:SetChecked(Settings:IsKeepFocusShown())
    self.frame.SettingsContainer.KeepFocusCheckButton:SetChecked(Settings:KeepFocus())

    if (Settings:Opacity()) then
      self.frame.SettingsContainer.Opacity:SetValue(Settings:Opacity())
      self.frame.SettingsContainer.Opacity.Value:SetText(string.format("%d%s", Settings:Opacity() * 100, "%"))
    end

    if (Settings:OpacityOnHover()) then
      self.frame.SettingsContainer.OpacityOnHover:SetValue(Settings:OpacityOnHover())
      self.frame.SettingsContainer.OpacityOnHover.Value:SetText(
        string.format("%d%s", Settings:OpacityOnHover() * 100, "%")
      )
    end

    self.frame.SettingsContainer.FanfareCheck:SetChecked(Settings:PlayFanfare())
    self.frame.SettingsContainer.LinkedCounterCheckButton:SetChecked(Settings:DisplayLinked())
    self.frame.SettingsContainer.MuteChatCheckButton:SetChecked(Settings:ChatMuted())
    self.frame.SettingsContainer.ToggleMapButton:SetChecked(Settings:DisplayMinimapIcon())
    self.frame.SettingsContainer.DisplayBankOnLinked:SetChecked(Settings:DisplayBankOnLinked())
    self.frame.SettingsContainer.DisplayChargesOnLinked:SetChecked(Settings:DisplayChargesOnLinked())
  end

  if (TodoAddon.TodoChecklisterFrame) then
    TodoAddon.TodoChecklisterFrame:LoadCFG()
  end
end

---
---Initializes required properties for this class
function InterfaceOptions:Init()
  -- Create interface options frame
  self.frame =
    CreateFrame(
    "Frame",
    addonName .. "InterfaceOptions",
    InterfaceOptionsFrame,
    "TodoChecklisterInterfaceOptionsTemplate"
  )
  self.frame.name = addonName
  self.frame.default = function(frame)
    self:Defaults()
  end
  self.frame.refresh = function(frame)
    self:LoadCFG()
  end

  -- Set up fixed values
  self.frame.Title:SetText(addonName)
  self.frame.Version:SetText("v" .. GetAddOnMetadata(addonName, "version"))
  self.frame.SettingsContainer.Obs.Text:SetText(
    "To report bugs visit: https://github.com/AssisrMatheus/TodoChecklister/issues"
  )

  -- Set up the github popup
  StaticPopupDialogs[addonName .. "WEBSITE"] = {
    text = "Copy the url and paste it on your browser",
    button1 = "Done",
    OnShow = function(self, data)
      self.editBox:SetText("https://github.com/AssisrMatheus/TodoChecklister/issues")
      self.editBox:SetWidth(260)
    end,
    hasEditBox = true,
    exclusive = true,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
  }

  -- Open github pop up
  self.frame.SettingsContainer.Obs:SetScript(
    "OnClick",
    function()
      StaticPopup_Show(addonName .. "WEBSITE")
    end
  )

  self:LoadCFG()
  InterfaceOptions_AddCategory(self.frame)
end

--------------------------------------
-- XML Events
--------------------------------------
function ShowKeepFocusClick(frame)
  Settings:SetIsKeepFocusShown(frame:GetChecked())
  InterfaceOptions:LoadCFG()
end

function KeepFocusClick(frame)
  Settings:ToggleFocus()
  InterfaceOptions:LoadCFG()
end

function OpacityValueChanged(frame)
  if (InterfaceOptions.frame) then
    Settings:SetOpacity(frame:GetValue())
    InterfaceOptions:LoadCFG()
  end
end

function OnFanfarreCheck(frame)
  Settings:SetPlayFanfare(frame:GetChecked())
  InterfaceOptions:LoadCFG()
end

function DisplayLinkedCountClick(frame)
  Settings:SetDisplayLinked(frame:GetChecked())
  InterfaceOptions:LoadCFG()
end

function ToggleMapClick(frame)
  Settings:SetDisplayMinimapIcon(frame:GetChecked())
  TodoAddon.MinimapIcon:LoadCFG()
end

function MuteChatClick(frame)
  Settings:SetChatMuted(frame:GetChecked())
end

function OpacityOnHoverValueChanged(frame)
  if (InterfaceOptions.frame) then
    Settings:SetOpacityOnHover(frame:GetValue())
    InterfaceOptions:LoadCFG()
  end
end

function DisplayBankClick(frame)
  Settings:SetDisplayBankOnLinked(frame:GetChecked())
  InterfaceOptions:LoadCFG()
end

function DisplayChargesClick(frame)
  Settings:SetDisplayChargesOnLinked(frame:GetChecked())
  InterfaceOptions:LoadCFG()
end
