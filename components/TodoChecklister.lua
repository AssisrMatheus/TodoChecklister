--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...
core.TodoChecklisterFrame = {} -- adds Config table to addon namespace
local TodoChecklisterFrame = core.TodoChecklisterFrame

local Constants = core.Constants
local ResponsiveFrame = core.ResponsiveFrame
local TableUtils = core.TableUtils;

--------------------------------------
-- TodoChecklisterFrame functions
--------------------------------------
function TodoChecklisterFrame:AddItem(text)
	table.insert(TodoChecklisterDB, #TodoChecklisterDB+1, { text=text, isChecked=false })
	self:OnUpdate()
end

function TodoChecklisterFrame:RemoveItem(text)
	local indexToRemove = TableUtils:IndexOf(TodoChecklisterDB, function(x) return x.text == text end)

	if(indexToRemove > 0) then
		table.remove(TodoChecklisterDB, indexToRemove)
		self:OnUpdate()
	end
end

function TodoChecklisterFrame:CheckItem(text)
	local indexToCheck = TableUtils:IndexOf(TodoChecklisterDB, function(x) return x.text == text end)

	if(indexToCheck > 0) then
		local item = TodoChecklisterDB[indexToCheck];
		TodoChecklisterDB[indexToCheck] = { text=item.text, isChecked=(not item.isChecked) };
		self:OnUpdate()
	end
end

function TodoChecklisterFrame:Toggle()
	if (self.frame:IsShown()) then
		self.frame:Hide();
	else
		self.frame:Show();
	end
end

--------------------------------------
-- TodoChecklisterFrame Events
--------------------------------------
function TodoChecklisterFrame:OnUpdate()
	local scrollFrame = TodoItemsScrollFrame
	local list = TodoChecklisterDB or {}
	if (scrollFrame and scrollFrame.buttons and list) then
		local offset = HybridScrollFrame_GetOffset(scrollFrame)
		
		if (#list > 0) then
			self.frame.Background.BlankText:SetText('')
		else
			self.frame.Background.BlankText:SetText('Oh no! \r\n You have no items on your list \r\n\r\n Start by typing them in the box above \r\n\r\n =)')
		end

		for i=1, #scrollFrame.buttons do
			local idx = i + offset
			local button = scrollFrame.buttons[i]
			
			if ( idx <= #list ) then
				local todoItem = list[idx]								
				button.todoItem = todoItem

				-- Update button values
				if (todoItem.isChecked) then
					button.TodoContent.FontText:SetFontObject(GameFontDarkGraySmall);
				else
					button.TodoContent.FontText:SetFontObject(GameFontNormalSmall);
				end
				button.TodoContent:SetWidth(scrollFrame:GetWidth() - button.RemoveButton:GetWidth() - 30)
				button.TodoContent.FontText:SetText(todoItem.text)

				-- Update checkbox values
				button.TodoCheckButton:SetChecked(todoItem.isChecked)

				button:Show()
			else
				button:Hide()
			end
		end
		
		HybridScrollFrame_Update(scrollFrame, (scrollFrame.buttons[1]:GetHeight()) * #list, scrollFrame:GetHeight())
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
  self:Toggle();
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

function OnSaveItem(frame)
	TodoChecklisterFrame:AddItem(TodoChecklister.TodoText:GetText())
	TodoChecklister.TodoText:SetText("")
	TodoChecklister.TodoText:ClearFocus()
end

function OnRemoveItem(frame)
	TodoChecklisterFrame:RemoveItem(frame:GetParent().TodoContent.FontText:GetText())
end

function OnCheckItem(frame)
	TodoChecklisterFrame:CheckItem(frame:GetParent().TodoContent.FontText:GetText())
end