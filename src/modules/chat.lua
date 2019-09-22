--------------------------------------
-- Namespaces
--------------------------------------
local addonName, core = ...
core.Chat = {} -- adds Config table to addon namespace
local Chat = core.Chat

local Constants = core.Constants
local Utils = core.Utils

--------------------------------------
-- Defaults (usually a database!)
--------------------------------------
Chat.command = "/todo"
Chat.commands = {
    ["tg"] = function()
        core.TodoChecklisterFrame:Toggle()
    end,
    ["add"] = function(...)
        core.TodoChecklisterFrame:AddItem(strjoin(" ", ...))
    end,
    ["rmv"] = function(indexToRemove)
        core.TodoChecklisterFrame:RemoveItemWithIndex(tonumber(indexToRemove))
    end,
    ["mv"] = function(indexFrom, indexTo)
        core.TodoChecklisterFrame:Move(tonumber(indexFrom), tonumber(indexTo), true)
    end,
    ["chk"] = function(indexToCheck)
        core.TodoChecklisterFrame:CheckItemWithIndex(tonumber(indexToCheck))
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
        print(" ")
    end,
    ["reload"] = function()
        core.TodoChecklisterFrame:Defaults()
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
    local hex = select(4, Utils:GetThemeColor())
    local prefix = string.format("|cff%s%s|r", hex:upper(), addonName)
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...))
end

function Chat:Init()
    SLASH_TodoChecklister1 = self.command
    SlashCmdList["TodoChecklister"] = function(msg)
        local str = msg:lower()
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
