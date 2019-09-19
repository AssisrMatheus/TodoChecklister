--------------------------------------
-- Namespaces
--------------------------------------
local addonName, core = ...;
core.MinimapIcon = {}; -- adds Config table to addon namespace

local MinimapIcon = core.MinimapIcon;
local Constants = core.Constants;

--------------------------------------
-- MinimapIcon functions
--------------------------------------
function MinimapIcon:Init()
	if type(TodoChecklisterMapIcon) ~= "table" then
		TodoChecklisterMapIcon = { hide=false }
	end
	if LibStub("LibDBIcon-1.0", true) then
		local minimapIconLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName.."MinimapIcon", {
			type = "data source",
			text = addonName,
			icon = "Interface\\Icons\\INV_Misc_Note_03",
			OnClick = function (self, button) core.TodoChecklisterFrame:Toggle() end,
			OnTooltipShow = function(GameTooltip)
				GameTooltip:SetText(addonName, 1,1,1)
				GameTooltip:AddLine("Click to toggle your list", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
			end
		});

		LibStub("LibDBIcon-1.0"):Register(addonName, minimapIconLDB, TodoChecklisterMapIcon)
	end
end
