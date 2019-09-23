--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)
---@type string
local addonName = select(1, ...)

---@class Constants
local Constants = TodoAddon.Constants

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.Debug = {}

---@class Debug
local Debug = TodoAddon.Debug

--------------------------------------
-- Lifecycle Events
--------------------------------------
---
---Initializes the debug context by adding some development slash commands
function Debug:Init()
	if (Constants.debugMode) then
		-- allows using left and right buttons to move through chat 'edit' box
		for i = 1, NUM_CHAT_WINDOWS do
			_G["ChatFrame" .. i .. "EditBox"]:SetAltArrowKeyMode(false)
		end

		----------------------------------
		-- Register Slash Commands!
		----------------------------------
		SLASH_RELOADUI1 = "/rl" -- new slash command for reloading UI
		SlashCmdList.RELOADUI = ReloadUI

		SLASH_FRAMESTK1 = "/fs" -- new slash command for showing framestack tool
		SlashCmdList.FRAMESTK = function()
			LoadAddOn("Blizzard_DebugTools")
			FrameStackTooltip_Toggle()
		end
	end
end

function printDBG(...)
	if (Constants.debugMode) then
		print(...)
	end
end
