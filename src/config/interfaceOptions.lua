--------------------------------------
-- Namespaces
--------------------------------------
local addonName, core = ...
core.InterfaceOptions = {} -- adds Config table to addon namespace
local InterfaceOptions = core.InterfaceOptions

local Constants = core.Constants

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
  self.frame.Title:SetText(addonName)
  self.frame.Version:SetText("v" .. GetAddOnMetadata(addonName, "version"))
  self.frame.SettingsContainer.Obs.Text:SetText(
    "Found a bug? Report at: https://github.com/AssisrMatheus/TodoChecklister/issues"
  )
  self.frame.SettingsContainer.Obs:SetScript(
    "OnClick",
    function()
      StaticPopup_Show("TodoChecklisterWEBSITE")
    end
  )

  InterfaceOptions_AddCategory(self.frame)

  -- Debugging
  InterfaceOptionsFrame_OpenToCategory(TodoChecklisterInterfaceOptions)
end
