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

ResponsiveFrame.minWidth = 120
ResponsiveFrame.minHeight = 147
ResponsiveFrame.minScale = 0.5

--------------------------------------
-- ResponsiveFrame functions
--------------------------------------
---
---Pins the frame to UIParent by one corner, where it is now. Sizing and scaling grow it away from that corner
---@param frame Frame
---@param point "TOPLEFT"|"BOTTOMLEFT"
local function AnchorCorner(frame, point)
  local left = frame:GetLeft()
  local y = point == "TOPLEFT" and frame:GetTop() or frame:GetBottom()
  frame:ClearAllPoints()
  frame:SetPoint(point, UIParent, "BOTTOMLEFT", left, y)
end

---
---Scales the frame so its right edge follows the cursor, keeping the bottom left corner in place
---@param frame Frame
local function ScaleToCursor(frame)
  local scale = frame:GetScale()
  local cursorX = GetCursorPosition() / frame:GetEffectiveScale()
  local newScale = scale * (cursorX - frame:GetLeft()) / frame:GetWidth()

  if (newScale > ResponsiveFrame.minScale) then
    -- Point offsets are in the frame's own scale, so convert the corner to the new one
    local left, bottom = frame:GetLeft() * scale / newScale, frame:GetBottom() * scale / newScale
    frame:SetScale(newScale)
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
  end
end

---
---Makes the frame movable by dragging it, resizable with the grip's left button and scalable with its right button
---@param frame Frame @A frame created from TodoChecklisterResponsiveFrameTemplate
function ResponsiveFrame:OnLoad(frame)
  frame:SetResizeBounds(self.minWidth, self.minHeight)
  frame:RegisterForDrag("LeftButton")

  frame:SetScript(
    "OnDragStart",
    function(frame)
      frame:StartMoving()
    end
  )

  frame:SetScript(
    "OnDragStop",
    function(frame)
      frame:StopMovingOrSizing()
      AnchorCorner(frame, "BOTTOMLEFT")
    end
  )

  local grip = frame.ResizeButton

  grip:SetScript(
    "OnMouseDown",
    function(grip, button)
      if (button == "LeftButton") then
        -- The grip drags the bottom right corner, so the opposite corner must stay put
        AnchorCorner(frame, "TOPLEFT")
        frame:StartSizing("BOTTOMRIGHT")
      elseif (button == "RightButton") then
        AnchorCorner(frame, "BOTTOMLEFT")
        -- Only runs every frame while the button is held
        grip:SetScript(
          "OnUpdate",
          function()
            ScaleToCursor(frame)
          end
        )
      end
    end
  )

  grip:SetScript(
    "OnMouseUp",
    function(grip)
      grip:SetScript("OnUpdate", nil)
      frame:StopMovingOrSizing()
      AnchorCorner(frame, "BOTTOMLEFT")
    end
  )
end
