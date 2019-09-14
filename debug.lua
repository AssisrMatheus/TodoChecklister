--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...;
core.Debug = {}; -- adds Config table to addon namespace
local Debug = core.Debug;

local Constants = core.Constants;

--------------------------------------
-- Debug functions
--------------------------------------
function Debug:Init()
    if (Constants.debugMode) then
		-- allows using left and right buttons to move through chat 'edit' box
		for i = 1, NUM_CHAT_WINDOWS do
			_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
		end

		----------------------------------
		-- Register Slash Commands!
		----------------------------------
		SLASH_RELOADUI1 = "/rl"; -- new slash command for reloading UI
		SlashCmdList.RELOADUI = ReloadUI;

		SLASH_FRAMESTK1 = "/fs"; -- new slash command for showing framestack tool
		SlashCmdList.FRAMESTK = function()
			LoadAddOn("Blizzard_DebugTools");
			FrameStackTooltip_Toggle();
		end
	end
end
