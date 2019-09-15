--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...
core.ResponsiveFrame = {} -- adds Config table to addon namespace
local ResponsiveFrame = core.ResponsiveFrame

--------------------------------------
-- ResponsiveFrame functions
--------------------------------------
function ResponsiveFrame:OnLoad(frame)
  self.frame = frame;
  frame:RegisterForDrag("LeftButton")
  frame:SetScale(1)
  frame.x = frame:GetLeft() 
  frame.y = (frame:GetTop() - frame:GetHeight()) 

  frame:SetScript("OnDragStart", function(frame) 
    frame.isMoving = true
    frame:StartMoving() 
  end)

  frame:SetScript("OnDragStop", function(frame)
    frame.isMoving = false
    frame:StopMovingOrSizing() 
    frame.x = frame:GetLeft() 
    frame.y = (frame:GetTop() - frame:GetHeight()) 
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", frame.x, frame.y)
  end)

  frame:SetScript("OnUpdate", function(frame) 
    if frame.isMoving == true then
        frame.x = frame:GetLeft() 
        frame.y = (frame:GetTop() - frame:GetHeight()) 
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", frame.x, frame.y)
    end
  end)
end

function OnLoad(frame)
  ResponsiveFrame:OnLoad(frame)
end