--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)
---@type string
local addonName = select(1, ...)

---@class TodoChecklisterFrame
local TodoChecklisterFrame = TodoAddon.TodoChecklisterFrame

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.MinimapIcon = {}

---@class MinimapIcon
local MinimapIcon = TodoAddon.MinimapIcon

---
---The SavedVariable where the map settings are stored into
---@class TodoMapIcon
local DB = TodoChecklisterMapIcon

--------------------------------------
-- Lifecycle Events
--------------------------------------
---
---Initializes the minimap icon if the user can have it
function MinimapIcon:Init()
	if type(DB) ~= "table" then
		DB = {hide = false}
	end

	if LibStub("LibDBIcon-1.0", true) then
		local minimapIconLDB =
			LibStub("LibDataBroker-1.1"):NewDataObject(
			addonName .. "MinimapIcon",
			{
				type = "data source",
				text = addonName,
				icon = "Interface\\Icons\\INV_Misc_Note_03",
				OnClick = function(self, button)
					TodoChecklisterFrame:Toggle()
				end,
				OnTooltipShow = function(GameTooltip)
					GameTooltip:SetText(addonName, 1, 1, 1)
					GameTooltip:AddLine("Click to toggle your list", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
				end
			}
		)

		LibStub("LibDBIcon-1.0"):Register(addonName, minimapIconLDB, DB)
	end
end
