--------------------------------------
-- Namespaces
--------------------------------------
local addonName, core = ...
core.InterfaceOptions = {} -- adds Config table to addon namespace
local InterfaceOptions = core.InterfaceOptions

local Constants = core.Constants
local Settings = core.Settings

--------------------------------------
-- InterfaceOptions functions
--------------------------------------
--------------------------------------
-- Lifecycle Events
--------------------------------------
function InterfaceOptions:Defaults()
  -- This will also call Settings:Defaults
  core.TodoChecklisterFrame:Defaults()
  self:LoadCFG()
end

function InterfaceOptions:LoadCFG()
  if (self.frame) then
    self.frame.SettingsContainer.FocusCheckButton:SetChecked(Settings:IsKeepFocusShown())

    self.frame.SettingsContainer.FocusCheckButton:SetChecked(Settings:IsKeepFocusShown())
    self.frame.SettingsContainer.KeepFocusCheckButton:SetChecked(Settings:KeepFocus())

    if (Settings:Opacity()) then
      self.frame.SettingsContainer.Opacity:SetValue(Settings:Opacity())
      self.frame.SettingsContainer.Opacity.Value:SetText(string.format("%d%s", Settings:Opacity() * 100, "%"))
    end
  end

  if (core.TodoChecklisterFrame) then
    core.TodoChecklisterFrame:LoadCFG()
  end
end

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
