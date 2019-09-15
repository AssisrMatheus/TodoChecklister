--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...
core.TodoChecklisterFrame = {} -- adds Config table to addon namespace
local TodoChecklisterFrame = core.TodoChecklisterFrame

local Constants = core.Constants
local ResponsiveFrame = core.ResponsiveFrame

--------------------------------------
-- TodoChecklisterFrame functions
--------------------------------------
function TodoChecklisterFrame:OnLoad(frame)
  ResponsiveFrame:OnLoad(frame)
  frame.Title:SetText(Constants.addonName)
  frame:Show()
end

function OnLoad(frame)
  TodoChecklisterFrame:OnLoad(frame)
end