--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)
---@type string
local addonName = select(1, ...)

---@class Constants
local Constants = TodoAddon.Constants
---@class Utils
local Utils = TodoAddon.Utils
---@class TodoChecklisterFrame
local TodoChecklisterFrame = TodoAddon.TodoChecklisterFrame
---@class InterfaceOptions
local InterfaceOptions = TodoAddon.InterfaceOptions
---@class Settings
local Settings = TodoAddon.Settings
---@class TodoList
local TodoList = TodoAddon.TodoList

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.Chat = {}

---@class Chat
local Chat = TodoAddon.Chat

--------------------------------------
-- Defaults
--------------------------------------
Chat.command = "/todo"
Chat.commands = {
    ["tg"] = function()
        TodoChecklisterFrame:Toggle()
    end,
    ["add"] = function(...)
        if (TodoChecklisterFrame.selectedItem and TodoChecklisterFrame.selectedItem > 0) then
            TodoChecklisterFrame:ClearSelected()
            TodoChecklisterFrame:OnUpdate()
        end
        TodoChecklisterFrame:AddItem(strjoin(" ", ...))
    end,
    ["rmv"] = function(indexToRemove)
        TodoChecklisterFrame:RemoveItemWithIndex(tonumber(indexToRemove))
    end,
    ["mv"] = function(indexFrom, indexTo)
        TodoChecklisterFrame:Move(tonumber(indexFrom), tonumber(indexTo), true)
    end,
    ["chk"] = function(indexToCheck)
        TodoChecklisterFrame:CheckItemWithIndex(tonumber(indexToCheck))
    end,
    ["lists"] = function()
        Chat:Print("Saved lists:")
        for index, name in ipairs(TodoList:GetListNames()) do
            if (name == TodoList:GetSelectedListName()) then
                Chat:Print("|cff00cc66" .. index .. ". " .. name .. "|r (displayed)")
            else
                Chat:Print(index .. ". " .. name)
            end
        end
    end,
    ["switch"] = function(...)
        -- Accepts the position shown by "/todo lists" or the list name (case-insensitive, may contain spaces)
        local query = strjoin(" ", ...)
        local names = TodoList:GetListNames()
        local position = tonumber(query)
        local name = position and names[position]
        if (not name) then
            for _, listName in ipairs(names) do
                if (listName:lower() == query:lower()) then
                    name = listName
                end
            end
        end

        if (name) then
            TodoChecklisterFrame:SwitchList(name)
            InterfaceOptions:LoadCFG()
            Chat:Print("Displaying |cff00cc66" .. name .. "|r")
        else
            Chat:Print("No list matches |cffff2211" .. query .. "|r. Type |cff00cc66/todo lists|r to see them")
        end
    end,
    ["help"] = function()
        print(" ")
        Chat:Print("List of commands:")
        Chat:Print("|cff00cc66/todo reload|r - Reset you window to its default properties(size, position, scale)")
        Chat:Print("|cff00cc66/todo tg|r - Toggle todo window")
        Chat:Print("|cff00cc66/todo add|r |cffff2211message|r - Adds |cffff2211message|r to your item list")
        Chat:Print("|cff00cc66/todo rmv|r |cffff2211position|r - Remove item in |cffff2211position|r")
        Chat:Print(
            "|cff00cc66/todo mv|r |cffff2211original_position target_position|r - Move item from |cffff2211original_position|r to |cffff2211target_position|r"
        )
        Chat:Print("|cff00cc66/todo chk|r |cffff2211position|r - Check or unchecks an item in |cffff2211position|r")
        Chat:Print("|cff00cc66/todo lists|r - Show every saved list")
        Chat:Print(
            "|cff00cc66/todo switch|r |cffff2211position or name|r - Display the list in |cffff2211position|r (from |cff00cc66/todo lists|r) or with that |cffff2211name|r"
        )
        print(" ")
    end,
    ["reload"] = function()
        InterfaceOptions:Defaults()
    end

    -- ["example"] = {
    -- 	["test"] = function(...)
    -- 		Chat:Print("My Value:", tostringall(...));
    -- 	end
    -- }
}

--------------------------------------
-- Chat functions
--------------------------------------
function Chat:Print(...)
    if (not Settings:ChatMuted()) then
        local hex = select(4, Utils:GetThemeColor())
        local prefix = string.format("|cff%s%s|r", hex:upper(), addonName)
        DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...))
    end
end

--------------------------------------
-- Lifecycle Events
--------------------------------------
---
---Initializes the chat slash commands
function Chat:Init()
    SLASH_TodoChecklister1 = self.command
    SlashCmdList["TodoChecklister"] = function(msg)
        local str = msg
        if (#str == 0) then
            -- User just entered "/todo" with no additional args.
            Chat.commands.help()
            return
        end

        local args = {}
        for _, arg in ipairs({string.split(" ", str)}) do
            if (#arg > 0) then
                table.insert(args, arg)
            end
        end

        local path = Chat.commands -- required for updating found table.

        for id, arg in ipairs(args) do
            if (#arg > 0) then -- if string length is greater than 0.
                arg = arg:lower()
                if (path[arg]) then
                    if (type(path[arg]) == "function") then
                        -- all remaining args passed to our function!
                        path[arg](select(id + 1, unpack(args)))
                        return
                    elseif (type(path[arg]) == "table") then
                        path = path[arg] -- another sub-table found!
                    end
                else
                    -- does not exist!
                    Chat.commands.help()
                    return
                end
            end
        end
    end
end
