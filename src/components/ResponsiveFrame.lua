--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.ResponsiveFrame = {}

---@class ResponsiveFrame
local ResponsiveFrame = TodoAddon.ResponsiveFrame

--------------------------------------
-- ResponsiveFrame functions
--------------------------------------
---
---Sets up required properties so the frame can properly function
function ResponsiveFrame:OnLoad(frame)
  self.frame = frame

  frame:RegisterForDrag("LeftButton")
  frame:SetScale(1)
  frame.x = frame:GetLeft()
  frame.y = (frame:GetTop() - frame:GetHeight())

  frame:SetScript(
    "OnDragStart",
    function(frame)
      frame.isMoving = true
      frame:StartMoving()
    end
  )

  frame:SetScript(
    "OnDragStop",
    function(frame)
      frame.isMoving = false
      frame:StopMovingOrSizing()
      frame.x = frame:GetLeft()
      frame.y = (frame:GetTop() - frame:GetHeight())
      frame:ClearAllPoints()
      frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", frame.x, frame.y)
    end
  )

  frame:SetScript(
    "OnUpdate",
    function(frame)
      if frame.isMoving == true then
        frame.x = frame:GetLeft()
        frame.y = (frame:GetTop() - frame:GetHeight())
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", frame.x, frame.y)
      end
    end
  )
end

--------------------------------------
-- XML Events
--------------------------------------
function OnLoad(frame)
  ResponsiveFrame:OnLoad(frame)
end

function OnUpdate(self)
  if (self.isSizing == true) then
    -- If the width or height is less than the allowed ammount
    -- stop resizing
    local width, height = self:GetParent():GetWidth(), self:GetParent():GetHeight()
    if (width <= 105 or height <= 140) then
      self.isSizing = false
      self:GetParent():StopMovingOrSizing()
    end
  end

  if self.isScaling == true then
    local cx, cy = GetCursorPosition()
    cx = cx / self:GetEffectiveScale() - self:GetParent():GetLeft()
    cy = self:GetParent():GetHeight() - (cy / self:GetEffectiveScale() - self:GetParent():GetBottom())

    local tNewScale = cx / self:GetParent():GetWidth()
    local tx, ty = self:GetParent().x / tNewScale, self:GetParent().y / tNewScale
    local newScale = self:GetParent():GetScale() * tNewScale

    if (newScale > 0) then
      local finalScale = self:GetParent():GetScale() * tNewScale
      if (finalScale > 0.5) then
        self:GetParent():ClearAllPoints()
        self:GetParent():SetScale(self:GetParent():GetScale() * tNewScale)
        self:GetParent():SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", tx, ty)
        self:GetParent().x, self:GetParent().y = tx, ty
      end
    end
  end
end

function OnMouseUp(self, button)
  if button == "LeftButton" then
    self.isSizing = false
    self:GetParent():StopMovingOrSizing()
  elseif button == "RightButton" then
    self.isScaling = false
  end
end

function OnMouseDown(self, button)
  local width, height = self:GetParent():GetWidth(), self:GetParent():GetHeight()

  -- If the width or height is less than the allowed ammount
  -- Resets the size and don't do anything
  if (width <= 116) then
    self:GetParent():SetWidth(120)
  end

  if (height <= 146) then
    self:GetParent():SetHeight(147)
  end

  -- Fix a bug if you click too much in the scale button
  self:GetParent():StartMoving()
  self:GetParent():StopMovingOrSizing()

  if button == "LeftButton" then
    self.isSizing = true
    self:GetParent():StartSizing("BOTTOMRIGHT")
    self:GetParent():SetUserPlaced(true)
  end

  if button == "RightButton" then
    self.isScaling = true
  end
end
