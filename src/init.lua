--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

---@type string
local addonName = select(1, ...)

---@class Debug
local Debug = TodoAddon.Debug
---@class Settings
local Settings = TodoAddon.Settings
---@class TodoList
local TodoList = TodoAddon.TodoList
---@class InterfaceOptions
local InterfaceOptions = TodoAddon.InterfaceOptions
---@class TodoChecklisterFrame
local TodoChecklisterFrame = TodoAddon.TodoChecklisterFrame
---@class ListShareDialog
local ListShareDialog = TodoAddon.ListShareDialog
---@class Chat
local Chat = TodoAddon.Chat
---@class MinimapIcon
local MinimapIcon = TodoAddon.MinimapIcon
---@class ObjectiveTrackerSection
local ObjectiveTrackerSection = TodoAddon.ObjectiveTrackerSection

--------------------------------------
-- Init keybindings
--------------------------------------
BINDING_HEADER_TC_HEADER = addonName
BINDING_NAME_TC_TOGGLE_FRAME = "Toggle window"

-- Export the method TodoChecklisterFrame:Toggle to a global function
-- so that it can be called from a keybind
GLOBAL_TodoChecklisterFrameToggle = function()
    -- No window when start-up stopped to protect the saved data
    ---@diagnostic disable-next-line: unnecessary-if
    if (TodoChecklisterFrame.frame) then
        TodoChecklisterFrame:Toggle()
    end
end

--------------------------------------
-- Initialization
--------------------------------------
local main = CreateFrame("Frame", addonName .. "MAINFRAME", UIParent)
TodoAddon.main = main

---
---Messages about the saved data always show, even with chat muted: they are about the user's notes
---@param color string @Hex RGB of the message
---@param text string
local function PrintDataMessage(color, text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100" .. addonName .. "|r |cff" .. color .. text .. "|r")
end

---
---Tells the user what happened to a saved table
---@param what string @What the table holds, for the message: "lists", "settings"
---@param status MigrationStatus
---@param err string|nil
---@return boolean @Whether or not the addon may use this data. When false it must stop starting up, so it never
---writes to data it could damage. The game then saves the data back exactly as it was loaded
local function CheckSavedData(what, status, err)
    if (status == "failed") then
        PrintDataMessage(
            "ff2211",
            "could not upgrade your saved " .. what .. ". Nothing was changed, and the addon is off for this session so it can't damage them. " ..
                "Please report this at https://github.com/AssisrMatheus/TodoChecklister/issues with this error: " .. tostring(err)
        )
        return false
    elseif (status == "incompatible") then
        PrintDataMessage(
            "ff2211",
            "your saved " .. what .. " come from a newer version of " .. addonName .. ", which this version can't safely edit. " ..
                "The addon is off for this session so it can't damage them. Update it to use them again."
        )
        return false
    elseif (status == "newer") then
        PrintDataMessage(
            "ffd100",
            "your saved " .. what .. " come from a newer version of " .. addonName .. ". Update the addon to see everything you saved."
        )
    end
    return true
end

function TodoAddon:Init(event, name)
    if (name ~= addonName) then
        return
    end

    -- Config
    Debug:Init()

    -- Model. Load the saved data before anything else, and stop if it isn't safe to use (see utils/migrationUtils.lua)
    if (not CheckSavedData("settings", Settings:Init())) then
        return
    end
    local listsStatus, listsError, listsMessage = TodoList:Init()
    if (not CheckSavedData("lists", listsStatus, listsError)) then
        return
    end
    if (listsMessage) then
        PrintDataMessage("ffffff", listsMessage)
    end

    -- Components
    InterfaceOptions:Init()
    TodoChecklisterFrame:Init()
    ListShareDialog:Init()

    -- Modules
    Chat:Init()
    MinimapIcon:Init()
    ObjectiveTrackerSection:Init()

    -------------------------------------------
    Chat:Print(TodoList:GetMOTD())
end

main:RegisterEvent("ADDON_LOADED")
main:SetScript("OnEvent", TodoAddon.Init)
