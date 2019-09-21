--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...
core.TodoChecklisterFrame = {} -- adds Config table to addon namespace
local TodoChecklisterFrame = core.TodoChecklisterFrame

local ResponsiveFrame = core.ResponsiveFrame
local TableUtils = core.TableUtils
local TodoList = core.TodoList

--------------------------------------
-- TodoChecklisterFrame functions
--------------------------------------
function TodoChecklisterFrame:AddItem(text)
	if (text ~= "" and text ~= nil and text) then
		-- If the item is not selected
		if (self.selectedItem == nil or self.selectedItem == 0) then
			TodoList:AddItem(text)
		else
			TodoList:UpdateItem(self.selectedItem, {text = text})
		end
		self:ClearSelected()
		self:OnUpdate()
	end
end

function TodoChecklisterFrame:RemoveItem(todoItem)
	local indexToRemove = TodoList:GetIndexByItem(todoItem)

	if (indexToRemove > 0) then
		-- If we are removing the current selected item
		if (self.selectedItem and self.selectedItem == indexToRemove) then
			-- Clear selection before removing it
			self:ClearSelected()
		end

		local selectedItem
		-- If we have something selected, we have to re-find its index after deletion
		if (self.selectedItem and self.selectedItem > 0) then
			-- So we store the current text
			selectedItem = TodoList:GetItems()[self.selectedItem]
		end

		TodoList:RemoveItem(indexToRemove)

		if (selectedItem ~= nil) then
			local indexToSelect = TodoList:GetIndexByItem(selectedItem)
			self.selectedItem = indexToSelect
		end

		self:OnUpdate()
	end
end

function TodoChecklisterFrame:CheckItem(todoItem)
	local indexToCheck = TodoList:GetIndexByItem(todoItem)
	if (indexToCheck > 0) then
		local item = TodoList:GetItems()[indexToCheck]
		TodoList:UpdateItem(indexToCheck, {isChecked = (not item.isChecked)})
		self:OnUpdate()
	end
end

function TodoChecklisterFrame:SelectItem(todoItem, buttonFrame)
	local indexToSelect = TodoList:GetIndexByItem(todoItem)

	-- If index is different = select a new item
	if (indexToSelect ~= self.selectedItem) then
		self.selectedItem = indexToSelect
		self.frame.TodoText:SetText(TodoList:GetItems()[self.selectedItem].text)
	else
		-- If index is the same = deselect the item
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

function TodoChecklisterFrame:PaintItem(frame, todoItem, index)
	index = index or 0
	frame.todoItem = todoItem
	-- Update button values
	if (todoItem.isChecked) then
		frame.TodoContent.FontText:SetFontObject(GameFontDarkGraySmall)
	else
		frame.TodoContent.FontText:SetFontObject(GameFontNormalSmall)
	end
	frame.TodoContent:SetWidth(TodoItemsScrollFrame:GetWidth() - frame.RemoveButton:GetWidth() - 30)
	frame.TodoContent.FontText:SetText(todoItem.text)

	if (self.selectedItem == index) then
		local highlightColor = NORMAL_FONT_COLOR

		if (todoItem.isChecked) then
			highlightColor = DISABLED_FONT_COLOR
		end

		frame.TodoContent.ButtonHighlightFrame.ButtonHighlightTexture:SetVertexColor(
			highlightColor.r,
			highlightColor.g,
			highlightColor.b
		)
		frame.TodoContent.ButtonHighlightFrame:Show()
	else
		frame.TodoContent.ButtonHighlightFrame:Hide()
	end

	-- Update checkbox values
	frame.TodoCheckButton:SetChecked(todoItem.isChecked)
end

function TodoChecklisterFrame:FloatingButton(parent)
	-- Create an initial offset based on where the mouse is
	local cx = GetCursorPosition()
	local xOffset = cx / self.frame:GetEffectiveScale() - (parent:GetLeft())

	-- Create or reuse a frame
	local floatingFrame = self.floatingFrame or CreateFrame("Frame", "TODODragButton", UIParent, "TodoItemTemplate")

	-- Fill the frame's values
	self:PaintItem(floatingFrame, parent:GetParent().todoItem)

	-- When moving
	floatingFrame:SetScript(
		"OnUpdate",
		function(frame)
			-- Make the clone follow the mouse
			if frame.isMoving then
				local cx, cy = GetCursorPosition()
				local x, y = cx / self.frame:GetEffectiveScale(), cy / self.frame:GetEffectiveScale()
				frame:ClearAllPoints()
				frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x - xOffset - 20, y - 15)
			end
		end
	)

	floatingFrame:SetScale(self.frame:GetScale())
	floatingFrame:SetMovable(true)
	floatingFrame:SetToplevel(true)
	floatingFrame:SetFrameStrata("TOOLTIP")
	floatingFrame.Background:Show()
	return floatingFrame
end

--------------------------------------
-- TodoChecklisterFrame Events
--------------------------------------
function TodoChecklisterFrame:OnUpdate()
	local scrollFrame = TodoItemsScrollFrame
	local list = TodoList:GetItems()
	if (scrollFrame and scrollFrame.buttons and list) then
		local offset = HybridScrollFrame_GetOffset(scrollFrame)

		if (#list > 0) then
			self.frame.Background.BlankText:SetText("")
		else
			self.frame.Background.BlankText:SetText(
				"You have no items on your list \r\n\r\n Start by typing them in the box above \r\n\r\n =)"
			)
		end

		for i = 1, #scrollFrame.buttons do
			local idx = i + offset
			local button = scrollFrame.buttons[i]

			if (idx <= #list) then
				local todoItem = list[idx]
				self:PaintItem(button, todoItem, idx)

				-- Setup drag
				button.TodoContent:RegisterForDrag("LeftButton")
				button.TodoContent:SetScript(
					"OnDragStart",
					function(button)
						-- Disabled the item on the list
						-- Highlight where the clone will be dropped
						-- When dropped, move the dragged item to the new position and enable it

						-- Clone the original button
						self.floatingFrame = self:FloatingButton(button)
						self.floatingFrame:Show()
						self.floatingFrame.isMoving = true
						self.floatingFrame:StartMoving()
					end
				)

				button.TodoContent:SetScript(
					"OnDragStop",
					function(button)
						self.floatingFrame.isMoving = false
						self.floatingFrame:StopMovingOrSizing()
						self.floatingFrame:Hide()

						button.FontText:ClearAllPoints()
						button.FontText:SetPoint("LEFT", button, "LEFT", 0, 0)
						-- TODO: reorder item
					end
				)

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
	frame.Title:SetText(UnitName("player") .. "'s List")

	local scrollFrame = frame.ScrollFrame
	scrollFrame.update = function()
		self:OnUpdate()
	end
	HybridScrollFrame_CreateButtons(frame.ScrollFrame, "TodoItemTemplate")

	-- Display the frame
	self:OnUpdate()
	self:Toggle()
end

function OnLoad(frame)
	TodoChecklisterFrame:OnLoad(frame)
end

function OnShow(frame)
	TodoChecklisterFrame:OnUpdate()
end

function OnSizeChanged(frame)
	TodoChecklisterFrame:OnUpdate()
end

function OnSaveItem(frame)
	local text = TodoChecklister.TodoText:GetText()
	if (not text) then
		text = ""
	end

	TodoChecklisterFrame:AddItem(text)
end

function OnRemoveItem(frame)
	--TODO: RECEIVE ENTIRE ITEM AND CHECK IF THERE'S ID. IF THERE'S NOT, USE TEXT
	TodoChecklisterFrame:RemoveItem(frame:GetParent().todoItem)
end

function OnCheckItem(frame)
	TodoChecklisterFrame:CheckItem(frame:GetParent().todoItem)
end

function OnSelectItem(frame)
	TodoChecklisterFrame:SelectItem(frame:GetParent().todoItem)
end
