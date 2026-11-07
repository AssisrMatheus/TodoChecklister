--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

---@type string
local addonName = select(1, ...)

-- Blizzard's settings panel API. Captured before the addon's own Settings module shadows the name below
local BlizzardSettings = _G.Settings

---@class Constants
local Constants = TodoAddon.Constants
---@class Settings
local Settings = TodoAddon.Settings
---@class TodoList
local TodoList = TodoAddon.TodoList
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
    -- Refresh the dropdown text after the displayed list changed
    self.frame.SettingsContainer.ListDropdown:GenerateMenu()
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
    nil,
    "TodoChecklisterInterfaceOptionsTemplate"
  )
  -- Called by the Blizzard settings panel
  self.frame.OnDefault = function(frame)
    self:Defaults()
  end
  self.frame.OnRefresh = function(frame)
    self:LoadCFG()
  end

  -- Set up fixed values
  self.frame.Title:SetText(addonName)
  self.frame.Version:SetText("v" .. C_AddOns.GetAddOnMetadata(addonName, "Version"))
  self.frame.SettingsContainer.Obs.Text:SetText(
    "To report bugs visit: https://github.com/AssisrMatheus/TodoChecklister/issues"
  )

  -- Feature guide under the options, same content as the README's Features section
  local heading = "|cffffd100%s|r"
  local key = "|cff00cc66%s|r"
  self.frame.SettingsContainer.Guide.Text:SetText(
    table.concat(
      {
        heading:format("How to use"),
        "- " .. heading:format("Track items: ") .. key:format("Shift-click") ..
          " an item in your bags while typing to link it. The list shows how many you carry.",
        "- " .. heading:format("Folders: ") .. key:format("Right-click") ..
          " an item to turn it into a folder, then drag items into it. " ..
            key:format("Left-click") .. " a folder to rename it, and use its +/- button to open or close it.",
        "- " .. heading:format("Reorder: ") .. "drag any item up or down the list.",
        "- " .. heading:format("Quick add: ") ..
          "tick it at the top of the window and the text box stays open after Enter.",
        "- " .. heading:format("Lists: ") ..
          "every character on your account sees your lists. Pick the one this character shows in " ..
            key:format("Displayed list") .. " above.",
        "- " .. heading:format("Share: ") .. key:format("Export list") ..
          " gives you a code to send a friend. They paste it into " ..
            key:format("Import list") .. " and get a copy, folders and checks included.",
        "",
        "Type " .. key:format("/todo") .. " in chat to see every command."
      },
      "\n"
    )
  )

  -- Set up the github popup
  StaticPopupDialogs[addonName .. "WEBSITE"] = {
    text = "Copy the url and paste it on your browser",
    button1 = "Done",
    OnShow = function(dialog, data)
      dialog:GetEditBox():SetText("https://github.com/AssisrMatheus/TodoChecklister/issues")
      dialog:GetEditBox():SetWidth(260)
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

  self:InitLists()

  self:LoadCFG()
  local category = BlizzardSettings.RegisterCanvasLayoutCategory(self.frame, addonName)
  BlizzardSettings.RegisterAddOnCategory(category)
end

---
---Sets up the lists section: the dropdown and the new/delete list dialogs
function InterfaceOptions:InitLists()
  local container = self.frame.SettingsContainer

  -- Lists are read at the time the menu opens, so new and deleted lists always show up
  container.ListDropdown:SetupMenu(
    function(dropdown, rootDescription)
      local function IsSelected(name)
        return name == TodoList:GetSelectedListName()
      end
      local function SetSelected(name)
        TodoAddon.TodoChecklisterFrame:SwitchList(name)
        self:LoadCFG()
      end

      for _, name in ipairs(TodoList:GetListNames()) do
        rootDescription:CreateRadio(name, IsSelected, SetSelected, name)
      end
    end
  )

  StaticPopupDialogs[addonName .. "NEWLIST"] = {
    text = "Name of the new list",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = true,
    maxLetters = 64,
    OnShow = function(dialog)
      dialog:GetButton1():Disable()
    end,
    OnAccept = function(dialog)
      local name = strtrim(dialog:GetEditBox():GetText())
      if (not TodoAddon.TodoChecklisterFrame:CreateList(name)) then
        TodoAddon.Chat:Print("A list named |cffff2211" .. name .. "|r already exists")
      end
      self:LoadCFG()
    end,
    EditBoxOnTextChanged = function(editBox)
      StaticPopup_StandardNonEmptyTextHandler(editBox)
    end,
    EditBoxOnEnterPressed = function(editBox)
      local dialog = editBox:GetParent()
      if (dialog:GetButton1():IsEnabled()) then
        dialog:GetButton1():Click()
      end
    end,
    EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
    timeout = 0,
    exclusive = true,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
  }

  -- Deleting needs the user to type DELETE, in all caps
  StaticPopupDialogs[addonName .. "DELETELIST"] = {
    text = 'Delete the list "%s" and all its items?\n\nType DELETE to confirm.',
    button1 = "Delete",
    button2 = "Cancel",
    hasEditBox = true,
    maxLetters = 6,
    OnShow = function(dialog)
      dialog:GetButton1():Disable()
    end,
    OnAccept = function(dialog, name)
      TodoAddon.TodoChecklisterFrame:DeleteList(name)
      self:LoadCFG()
    end,
    EditBoxOnTextChanged = function(editBox)
      editBox:GetParent():GetButton1():SetEnabled(editBox:GetText() == "DELETE")
    end,
    EditBoxOnEnterPressed = function(editBox)
      local dialog = editBox:GetParent()
      if (dialog:GetButton1():IsEnabled()) then
        dialog:GetButton1():Click()
      end
    end,
    EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
    timeout = 0,
    exclusive = true,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
    preferredIndex = 3
  }

  container.NewListButton:SetScript(
    "OnClick",
    function()
      StaticPopup_Show(addonName .. "NEWLIST")
    end
  )

  container.DeleteListButton:SetScript(
    "OnClick",
    function()
      local name = TodoList:GetSelectedListName()
      StaticPopup_Show(addonName .. "DELETELIST", name, nil, name)
    end
  )

  -- ListShareDialog is a component, which loads after this file
  container.ExportListButton:SetScript(
    "OnClick",
    function()
      TodoAddon.ListShareDialog:ShowExport(TodoList:GetSelectedListName())
    end
  )

  container.ImportListButton:SetScript(
    "OnClick",
    function()
      TodoAddon.ListShareDialog:ShowImport()
    end
  )
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
