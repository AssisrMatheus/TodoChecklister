--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...
core.TodoChecklisterFrame = {} -- adds Config table to addon namespace
local TodoChecklisterFrame = core.TodoChecklisterFrame

local Constants = core.Constants
local ResponsiveFrame = core.ResponsiveFrame
local TableUtils = core.TableUtils

--------------------------------------
-- TodoChecklisterFrame functions
--------------------------------------
function TodoChecklisterFrame:AddItem(text)
	if(text ~= "" and text ~= nil and text) then
		-- If the item is not selected
		
		print(self.selectedItem)
		if(self.selectedItem == nil or self.selectedItem == 0) then
			-- Adds
			table.insert(TodoChecklisterDB, #TodoChecklisterDB+1, { text=text, isChecked=false })
		else
			-- if editing
			if (TodoChecklisterDB and TodoChecklisterDB[self.selectedItem]) then
				TodoChecklisterDB[self.selectedItem].text = text
			end
			self:ClearSelected()
		end
		self:OnUpdate()
	end
end

function TodoChecklisterFrame:RemoveItem(text)
	local indexToRemove = TableUtils:IndexOf(TodoChecklisterDB, function(x) return x.text == text end)

	if(indexToRemove > 0) then
		-- If we are removing the current selected item
		if (self.selectedItem == indexToRemove) then
			-- Clear selection
			self:ClearSelected()
		end

		local selectedText
		-- If we have something selected, we have to re-find its index after deletion
		if(self.selectedItem and self.selectedItem > 0) then
			-- So we store the current text
			selectedText = TodoChecklisterDB[self.selectedItem].text
		end

		table.remove(TodoChecklisterDB, indexToRemove)

		if(selectedText ~= nil) then
			local indexToSelect = TableUtils:IndexOf(TodoChecklisterDB, function(x) return x.text == selectedText end)
			self.selectedItem = indexToSelect;
		end

		self:OnUpdate()
	end
end

function TodoChecklisterFrame:CheckItem(text)
	local indexToCheck = TableUtils:IndexOf(TodoChecklisterDB, function(x) return x.text == text end)
	if(indexToCheck > 0) then
		local item = TodoChecklisterDB[indexToCheck]
		TodoChecklisterDB[indexToCheck] = { text=item.text, isChecked=(not item.isChecked) }
		self:OnUpdate()
	end
end

function TodoChecklisterFrame:SelectItem(text, buttonFrame)
	local indexToSelect = TableUtils:IndexOf(TodoChecklisterDB, function(x) return x.text == text end)

	if(indexToSelect ~= self.selectedItem) then
		self.selectedItem = indexToSelect
		self.frame.TodoText:SetText(TodoChecklisterDB[self.selectedItem].text)
	else
		self:ClearSelected()
	end

	self:OnUpdate()
end

function TodoChecklisterFrame:ClearSelected()
	self.selectedItem = 0
	self.frame.TodoText:SetText("")
	self.frame.TodoText:ClearFocus()
end

function TodoChecklisterFrame:Toggle()
	if (self.frame:IsShown()) then
		self.frame:Hide()
	else
		self.frame:Show()
	end
end

--------------------------------------
-- TodoChecklisterFrame Events
--------------------------------------
function TodoChecklisterFrame:OnUpdate()
	local scrollFrame = TodoItemsScrollFrame
	if (scrollFrame and scrollFrame.buttons and TodoChecklisterDB) then
		local offset = HybridScrollFrame_GetOffset(scrollFrame)
		
		if (#TodoChecklisterDB > 0) then
			self.frame.Background.BlankText:SetText('')
		else
			self.frame.Background.BlankText:SetText('Oh no! \r\n You have no items on your list \r\n\r\n Start by typing them in the box above \r\n\r\n =)')
		end

		for i=1, #scrollFrame.buttons do
			local idx = i + offset
			local button = scrollFrame.buttons[i]
			
			if ( idx <= #TodoChecklisterDB ) then
				local todoItem = TodoChecklisterDB[idx]								
				button.todoItem = todoItem

				-- Update button values
				if (todoItem.isChecked) then
					button.TodoContent.FontText:SetFontObject(GameFontDarkGraySmall)
				else
					button.TodoContent.FontText:SetFontObject(GameFontNormalSmall)
				end
				button.TodoContent:SetWidth(scrollFrame:GetWidth() - button.RemoveButton:GetWidth() - 30)
				button.TodoContent.FontText:SetText(todoItem.text)

				if (self.selectedItem == idx) then
					local highlightColor = NORMAL_FONT_COLOR

					if (todoItem.isChecked) then
						highlightColor = DISABLED_FONT_COLOR
					end

					button.TodoContent.ButtonHighlightFrame.ButtonHighlightTexture:SetVertexColor(highlightColor.r, highlightColor.g, highlightColor.b)
					button.TodoContent.ButtonHighlightFrame:Show()
				else
					button.TodoContent.ButtonHighlightFrame:Hide()
				end

				-- Update checkbox values
				button.TodoCheckButton:SetChecked(todoItem.isChecked)

				button:Show()
			else
				button:Hide()
			end
		end
		
		HybridScrollFrame_Update(scrollFrame, (scrollFrame.buttons[1]:GetHeight()) * #TodoChecklisterDB, scrollFrame:GetHeight())
	end
end

function TodoChecklisterFrame:OnLoad(frame)
  self.frame = frame
  -- Parent's OnLoad Function
  ResponsiveFrame:OnLoad(frame)

  -- Set up elements
	frame.Title:SetText(UnitName("player").."'s List")
  
	local scrollFrame = frame.ScrollFrame
	scrollFrame.update = function() TodoChecklisterFrame:OnUpdate() end
	HybridScrollFrame_CreateButtons(frame.ScrollFrame, "TodoItemTemplate")

  -- Display the frame
  self:Toggle()
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
	local text = TodoChecklister.TodoText:GetText()
	if (not text) then text = "" end

	TodoChecklisterFrame:AddItem(text)
	TodoChecklister.TodoText:SetText("")
	TodoChecklister.TodoText:ClearFocus()
end

function OnRemoveItem(frame)
	local text = frame:GetParent().TodoContent.FontText:GetText()
	if (not text) then text = "" end

	TodoChecklisterFrame:RemoveItem(text)
end

function OnCheckItem(frame)
	local text = frame:GetParent().TodoContent.FontText:GetText()
	if (not text) then text = "" end

	TodoChecklisterFrame:CheckItem(text)
end

function OnSelectItem(frame)
	local text = frame:GetParent().TodoContent.FontText:GetText()
	if (not text) then text = "" end

	TodoChecklisterFrame:SelectItem(text, frame)
end