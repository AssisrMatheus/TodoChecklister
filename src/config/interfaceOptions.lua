--------------------------------------
-- Namespaces
--------------------------------------
local addonName, core = ...
core.InterfaceOptions = {} -- adds Config table to addon namespace
local InterfaceOptions = core.InterfaceOptions

local Constants = core.Constants
local TodoChecklisterFrame = core.TodoChecklisterFrame
local Settings = core.Settings

--------------------------------------
-- InterfaceOptions functions
--------------------------------------
function InterfaceOptions:Init()
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

  self.frame =
    CreateFrame(
    "Frame",
    "TodoChecklisterInterfaceOptions",
    InterfaceOptionsFrame,
    "TodoChecklisterInterfaceOptionsTemplate"
  )
  self.frame.name = addonName
  self.frame.default = function(frame)
    TodoChecklisterFrame:Defaults()

    self.frame.SettingsContainer.FocusCheckButton:SetChecked(Settings:IsKeepFocusShown())

    self.frame.SettingsContainer.FocusCheckButton:SetChecked(Settings:IsKeepFocusShown())
    self.frame.SettingsContainer.KeepFocusCheckButton:SetChecked(Settings:KeepFocus())

    if (Settings:Opacity()) then
      self.frame.SettingsContainer.Opacity:SetValue(Settings:Opacity())
      self.frame.SettingsContainer.Opacity.Value:SetText(string.format("%d%s", Settings:Opacity() * 100, "%"))
    end
  end
  self.frame.Title:SetText(addonName)
  self.frame.Version:SetText("v" .. GetAddOnMetadata(addonName, "version"))
  self.frame.SettingsContainer.Obs.Text:SetText(
    "To report bugs visit: https://github.com/AssisrMatheus/TodoChecklister/issues"
  )
  self.frame.SettingsContainer.Obs:SetScript(
    "OnClick",
    function()
      StaticPopup_Show(addonName .. "WEBSITE")
    end
  )

  self.frame.SettingsContainer.FocusCheckButton:SetChecked(Settings:IsKeepFocusShown())
  self.frame.SettingsContainer.KeepFocusCheckButton:SetChecked(Settings:KeepFocus())

  if (Settings:Opacity()) then
    self.frame.SettingsContainer.Opacity:SetValue(Settings:Opacity())
    self.frame.SettingsContainer.Opacity.Value:SetText(string.format("%d%s", Settings:Opacity() * 100, "%"))
  end

  InterfaceOptions_AddCategory(self.frame)

  -- Debugging
  InterfaceOptionsFrame_OpenToCategory(self.frame)
end

function ShowKeepFocusClick(frame)
  Settings:SetIsKeepFocusShown(frame:GetChecked())
  if (frame:GetChecked()) then
    TodoChecklisterFrame.frame.KeepFocus:Show()
  else
    TodoChecklisterFrame.frame.KeepFocus:Hide()
  end
end

function KeepFocusClick(frame)
  Settings:ToggleFocus()
  TodoChecklisterFrame.frame.KeepFocus:SetChecked(Settings:KeepFocus())
end

function OpacityValueChanged(frame)
  if (TodoChecklisterFrame.frame) then
    TodoChecklisterFrame.frame:SetAlpha(frame:GetValue())
    Settings:SetOpacity(frame:GetValue())
  end
end
