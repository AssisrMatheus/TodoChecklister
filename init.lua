local addonName, core = ...; -- Namespace

-- WARNING: self keyword automatically becomes events frame!
function core:Init(event, name)
    if (name ~= addonName) then return end 
    
    if (not TodoChecklisterDB) then
        TodoChecklisterDB = {}
    end
	
    core.Debug:Init();
    core.Chat:Init();
	
    core.Chat:Print("All loaded :)");
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.Init);