local addonName, core = ...; -- Namespace

-- WARNING: self keyword automatically becomes events frame!
function core:Init(event, name)
    if (name ~= addonName) then return end 
    
    if (not TodoChecklisterDB) then
        TodoChecklisterDB = {}
    end
	
    core.Debug:Init();
    core.Chat:Init();
    core.MinimapIcon:Init();

    if (#TodoChecklisterDB > 0) then
        local completedList = core.TableUtils:Filter(TodoChecklisterDB, function(x) return x.isChecked == true end)
        local notList = core.TableUtils:Filter(TodoChecklisterDB, function(x) return x.isChecked == false end)
        
        if (#completedList > 0 and #notList > 0) then
            local completedTaskPlural = ""
            if (#completedList > 1) then
                completedTaskPlural = "tasks"
            else
                completedTaskPlural = "task"
            end

            local notTaskPlural = ""
            if (#notList > 1) then
                notTaskPlural = "tasks"
            else
                notTaskPlural = "task"
            end

            core.Chat:Print("You have |cff6cf900"..tostring(#completedList).."|r completed "..completedTaskPlural.." and |cffff0000"..tostring(#notList).."|r pending "..notTaskPlural);
        elseif (#completedList > 0) then
            core.Chat:Print("You have completed all your tasks");
        elseif (#notList > 0) then
            local taskPlural = ""
            if (#notList > 1) then
                taskPlural = "tasks"
            else
                taskPlural = "task"
            end
            core.Chat:Print("You have |cffff0000"..tostring(#notList).."|r pending "..taskPlural);
        end
    else
        core.Chat:Print("You have no pending tasks.");
    end    
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.Init);