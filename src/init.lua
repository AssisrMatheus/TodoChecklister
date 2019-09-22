local addonName, core = ... -- Namespace

local main = CreateFrame("Frame", addonName .. "MAINFRAME", UIParent)
core.main = main

function core:Init(event, name)
    if (name ~= addonName) then
        return
    end

    -- Config
    core.Debug:Init()
    core.Settings:Init()

    -- Model
    core.TodoList:Init()

    -- Components
    core.InterfaceOptions:Init()
    core.TodoChecklisterFrame:Init()

    -- Modules
    core.Chat:Init()
    core.MinimapIcon:Init()

    -------------------------------------------
    core.Chat:Print(core.TodoList:GetMOTD())
end

main:RegisterEvent("ADDON_LOADED")
main:SetScript("OnEvent", core.Init)
