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
---@class Chat
local Chat = TodoAddon.Chat
---@class MinimapIcon
local MinimapIcon = TodoAddon.MinimapIcon

--------------------------------------
-- Init keybindings
--------------------------------------
BINDING_HEADER_TC_HEADER = "TodoChecklister"
BINDING_NAME_TC_TOGGLE_FRAME = "Toggle log visibility"

-- Export the method TodoChecklisterFrame:Toggle to a global function
-- so that it can be called from a keybind
GLOBAL_TodoChecklisterFrameToggle = function () TodoChecklisterFrame:Toggle() end


--------------------------------------
-- Initialization
--------------------------------------
local main = CreateFrame("Frame", addonName .. "MAINFRAME", UIParent)
TodoAddon.main = main

function TodoAddon:Init(event, name)
    if (name ~= addonName) then
        return
    end

    -- Config
    Debug:Init()
    Settings:Init()

    -- Model
    TodoList:Init()

    -- Components
    InterfaceOptions:Init()
    TodoChecklisterFrame:Init()

    -- Modules
    Chat:Init()
    MinimapIcon:Init()

    -------------------------------------------
    Chat:Print(TodoList:GetMOTD())
end

main:RegisterEvent("ADDON_LOADED")
main:SetScript("OnEvent", TodoAddon.Init)
