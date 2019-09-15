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
function TodoChecklisterFrame:OnUpdate()
  local todoList = {
		{text="Item one",    isChecked=false},
		{text="Item Two",    isChecked=false},
		{text="Item Three",  isChecked=true},
		{text="Item four",   isChecked=false}
	}

	local scrollFrame = TodoItemsScrollFrame
	if (scrollFrame and scrollFrame.buttons) then
		local offset = HybridScrollFrame_GetOffset(scrollFrame)

		for i=1, #scrollFrame.buttons do
			local idx = i + offset
			local button = scrollFrame.buttons[i]

			if ( idx <= #todoList ) then
				local todoItem = todoList[idx]

				button.todoItem = todoItem
				button.TodoContent:SetText(todoItem.text)

				button:Show()
			else
				button:Hide()
			end
		end
		
		HybridScrollFrame_Update(scrollFrame, (scrollFrame.buttons[1]:GetHeight()) * #todoList, scrollFrame:GetHeight())
	end
end

function TodoChecklisterFrame:OnLoad(frame)
  self.frame = frame
  -- Parent's OnLoad Function
  ResponsiveFrame:OnLoad(frame)

  -- Set up elements
  frame.Title:SetText(Constants.addonName)
  
	local scrollFrame = frame.ScrollFrame
	scrollFrame.update = function() TodoChecklisterFrame:OnUpdate() end
	HybridScrollFrame_CreateButtons(frame.ScrollFrame, "TodoItemTemplate")

  -- Display the frame
  frame:Show()
end

function TodoChecklisterFrame:OnShow(frame)
  self:OnUpdate()
end

function TodoChecklisterFrame:OnSizeChanged(frame)
  self:OnUpdate()
end

function OnLoad(frame)
  TodoChecklisterFrame:OnLoad(frame)
end

function OnShow(frame)
  TodoChecklisterFrame:OnShow(frame)
end

function OnSizeChanged(frame)
  TodoChecklisterFrame:OnSizeChanged(frame)
end