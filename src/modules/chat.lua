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
    ["help"] = function()
        print(" ")
        Chat:Print("List of slash commands:")
        Chat:Print("|cff00cc66/todo tg|r - Toggle todo window")
        Chat:Print("|cff00cc66/todo add|r {message} - Adds a message from chat")
        Chat:Print("|cff00cc66/todo reload|r - Reset you window to its original properties(size, position, scale)")
        print(" ")
    end,
    ["reload"] = function()
        if (core.mainFrame) then
            core.mainFrame:SetSize(200, 200)
            core.mainFrame:ClearAllPoints()
            core.mainFrame:SetPoint("BOTTOMRIGHT", "$parent", "BOTTOMRIGHT", -120, 30)
            core.mainFrame:SetScale(1)
            core.mainFrame:Show()
            core.mainFrame.ScrollFrame:SetValue(0)
        end
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
