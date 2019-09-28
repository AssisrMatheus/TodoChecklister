--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

---@class Settings
local Settings = TodoAddon.Settings
---@class ResponsiveFrame
local ResponsiveFrame = TodoAddon.ResponsiveFrame
---@class TableUtils
local TableUtils = TodoAddon.TableUtils
---@class TodoList
local TodoList = TodoAddon.TodoList
---@class FunctionUtils
local FunctionUtils = TodoAddon.FunctionUtils

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.TodoChecklisterFrame = {}

---@class TodoChecklisterFrame
local TodoChecklisterFrame = TodoAddon.TodoChecklisterFrame

---@class TodoItemFrame : ButtonFrame
---@class TodoChecklisterWindowFrame : Frame

--------------------------------------
-- TodoChecklisterFrame functions
--------------------------------------
---
---Appends a new TodoItem to the list
---@param text string @New element to be appended to the list
function TodoChecklisterFrame:AddItem(text)
	if (text ~= "" and text ~= nil and text) then
		-- If the item is not selected
		if (self.selectedItem == nil or self.selectedItem == 0) then
			TodoList:AddItem(text)
		else
			TodoList:UpdateItem(self.selectedItem, {text = text})
		end
		self.memoizationId = self.memoizationId + 1
		self:ClearSelected()
		self:OnUpdate()
	end
end

---
---Removes an element from a given position, moving down other elements to close space and decrementing the size of the array
---@param indexToRemove number @The ONE-based location in the array to remove.
function TodoChecklisterFrame:RemoveItemWithIndex(indexToRemove)
	if (indexToRemove and type(indexToRemove) == "number" and indexToRemove > 0) then
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

		self.memoizationId = self.memoizationId + 1
		self:OnUpdate()
	end
end

---
---Removes the given element from the list
---@param todoItem TodoItem @The item to be removed from the list
function TodoChecklisterFrame:RemoveItem(todoItem)
	local indexToRemove = TodoList:GetIndexByItem(todoItem)
	self:RemoveItemWithIndex(indexToRemove)
end

---
---Moves an item from a given position of an array to a new one, moving up other elements
---@param fromIndex number @The ONE-based location in the array to move from.
---@param toIndex number @The ONE-based location in the array to move to.
---@param fromChat boolean @Whether or not is removing from chatbox slash command
function TodoChecklisterFrame:Move(fromIndex, toIndex, fromChat)
	if
		(fromIndex and type(fromIndex) == "number" and fromIndex > 0 and toIndex and type(toIndex) == "number" and toIndex > 0)
	 then
		local selectedItem
		if (self.selectedItem and self.selectedItem > 0) then
			selectedItem = TodoList:GetItems()[self.selectedItem]
		end

		if (not fromChat and fromIndex < toIndex) then
			toIndex = toIndex - 1
		end

		TodoList:Move(fromIndex, toIndex)

		if (selectedItem) then
			self.selectedItem = TodoList:GetIndexByItem(selectedItem)
		end

		self.memoizationId = self.memoizationId + 1
		self:OnUpdate()
	end
end

---
---Mark the item on indexToCheck position as done
---@param indexToCheck number @The ONE-based location in the array to check.
function TodoChecklisterFrame:CheckItemWithIndex(indexToCheck)
	if (indexToCheck and type(indexToCheck) == "number" and indexToCheck > 0) then
		local item = TodoList:GetItems()[indexToCheck]
		TodoList:UpdateItem(indexToCheck, {isChecked = (not item.isChecked)})
		self.memoizationId = self.memoizationId + 1
		self:OnUpdate()
		if
			(Settings:PlayFanfare() and
				TableUtils:Every(
					TodoList:GetItems(),
					function(item)
						return item.isChecked == true
					end
				))
		 then
			PlaySound(SOUNDKIT.READY_CHECK)
			TodoAddon.Chat:Print("|cff00cc66Congratulations!!|r You have completed your list")
		end
	end
end

---
---Mark the given item as done
---@param todoItem TodoItem @The item to be marked as checked
function TodoChecklisterFrame:CheckItem(todoItem)
	local indexToCheck = TodoList:GetIndexByItem(todoItem)
	self:CheckItemWithIndex(indexToCheck)
end

---
---Set the given item as selected
---@param todoItem TodoItem @The item to be marked as selected
---@param buttonFrame ButtonFrame @The button frame to set as highlighted
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

	self.memoizationId = self.memoizationId + 1
	self:OnUpdate()
end

---
---Set the given item as selected
---@param todoItem TodoItem @The item to be marked as checked
function TodoChecklisterFrame:ClearSelected()
	self.selectedItem = 0
	self.frame.TodoText:SetText("")
	if (not Settings.KeepFocus()) then
		self.frame.TodoText:ClearFocus()
	end
end

---
---Toggle the frame's visibility
function TodoChecklisterFrame:Toggle()
	if (self.frame:IsShown()) then
		self.frame:Hide()
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
	else
		self.frame:Show()
		PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
	end

	Settings:SetIsShown(self.frame:IsShown())
end

---
---Get the color based on the given item's properties
---@param todoItem TodoItem @The item to get the color to
function TodoChecklisterFrame:GetColor(todoItem)
	local highlightColor = NORMAL_FONT_COLOR

	if (todoItem.isChecked) then
		highlightColor = DISABLED_FONT_COLOR
	end

	return highlightColor
end

---
---Set the given frame's properties to the given item ones
---@param frame TodoItemFrame @The item to get the color to
---@param todoItem TodoItem @The item to get the color to
---@param index number @The current item index on the list
function TodoChecklisterFrame:PaintItem(frame, todoItem, index)
	index = index or 0

	frame.todoItem = todoItem
	-- Update button values
	if (todoItem.isChecked) then
		frame.TodoContent.FontText:SetFontObject(GameFontDarkGraySmall)
	else
		frame.TodoContent.FontText:SetFontObject(GameFontNormalSmall)
	end
	frame.TodoContent:SetWidth(TodoItemsScrollFrame:GetWidth() - frame.RemoveButton:GetWidth() - 23)

	if (self.displayLinked) then
		local identifier

		if (todoItem.id) then
			identifier = todoItem.id
		else
			identifier = todoItem.text
		end

		local text =
			FunctionUtils:Memoize(
			function()
				-- Startup regex process by storing string values
				local finalString = ""
				local remainingString = todoItem.text

				-- If the remaining string still has linked items
				while (remainingString and not (not GetItemInfo(remainingString))) do
					-- Find the linked item position
					local st, en = string.find(remainingString, "|Hitem:.-|r")

					if (en) then
						-- Set the final string to:
						local count = GetItemCount(remainingString, self.displayBankOnLinked, self.displayChargesOnLinked)
						if (count and count > 0) then
							finalString =
								table.concat {
								finalString, -- Current final string
								remainingString:sub(1, en), -- Current string until now
								"(",
								count,
								")"
							}
						else
							finalString =
								table.concat {
								finalString, -- Current final string
								remainingString:sub(1, en) -- Current string until now
							}
						end

						-- Remove the current linked item from the remaining string to continue the process
						remainingString = remainingString:sub(en + 1)
					else
						remainingString = ""
					end
				end

				-- If the final string has been set
				if (string.len(finalString) > 0) then
					return finalString .. remainingString
				else
					-- If not, the string doesn't have links
					return todoItem.text
				end
			end,
			identifier .. self.memoizationId,
			identifier .. "Count"
		)

		frame.TodoContent.FontText:SetText(text)
	else
		frame.TodoContent.FontText:SetText(todoItem.text)
	end

	if (self.selectedItem == index) then
		local highlightColor = self:GetColor(todoItem)

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

---
---Creates and returns the floating button frame to drag and drop items
---@param parent TodoChecklisterWindowFrame @The parent frame for all items
---@return TodoItemFrame @The item to get the color to
function TodoChecklisterFrame:FloatingButton(parent)
	-- Create an initial offset based on where the mouse is
	local cx = GetCursorPosition()
	local xOffset = cx / self.frame:GetEffectiveScale() - (parent:GetLeft())

	-- Create or reuse a frame
	local floatingFrame = self.floatingFrame or CreateFrame("Frame", "TODODragButton", UIParent, "TodoItemTemplate")

	floatingFrame.todoItem = parent:GetParent().todoItem
	-- Fill the frame's values
	self:PaintItem(floatingFrame, floatingFrame.todoItem)

	-- When moving
	floatingFrame:SetScript(
		"OnUpdate",
		function(frame)
			-- Make the clone follow the mouse
			parent:GetParent().BottomDropIndicator:Hide()
			if frame.isMoving then
				local cx, cy = GetCursorPosition()
				local x, y = cx / self.frame:GetEffectiveScale(), cy / self.frame:GetEffectiveScale()
				frame:ClearAllPoints()
				frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x - xOffset + 30, y - 25)
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

---
---The main update function for this class
---(Used to update the scrollbar and the view)
function TodoChecklisterFrame:OnUpdate()
	local scrollFrame = TodoItemsScrollFrame
	local list = TodoList:GetItems()
	if (self.frame and scrollFrame and scrollFrame.buttons and list) then
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
					function(todoContent)
						-- Clone the original button as a floating window
						self.floatingFrame = self:FloatingButton(todoContent)

						-- Display the window and drag it with the mouse
						self.floatingFrame:Show()
						self.floatingFrame.isMoving = true
						self.floatingFrame:StartMoving()

						-- Show that this item is being moved
						button.isMoving = true
						-- todoContent.ButtonHighlightFrame:Show()
					end
				)

				button.TodoContent:SetScript(
					"OnDragStop",
					function(todoContent)
						-- Hide that this item is being moved
						button.isMoving = false
						-- todoContent.ButtonHighlightFrame:Hide()

						-- Hide the floating window
						self.floatingFrame.isMoving = false
						self.floatingFrame:StopMovingOrSizing()
						self.floatingFrame:Hide()

						-- Resets fake animation
						todoContent.FontText:ClearAllPoints()
						todoContent.FontText:SetPoint("LEFT", todoContent, "LEFT", 0, 0)

						if (self.floatingFrame.targetIndex and self.floatingFrame.targetIndex > 0) then
							button.BottomDropIndicator:Hide()
							button.TopDropIndicator:Hide()

							local moveIndex = TodoList:GetIndexByItem(self.floatingFrame.todoItem)
							self:Move(moveIndex, self.floatingFrame.targetIndex)
						end

						self.floatingFrame.targetIndex = 0
						self.floatingFrame.todoItem = nil
					end
				)

				local highlightColor = self:GetColor(todoItem)
				button.TodoContent:SetScript(
					"OnUpdate",
					function(todoContent)
						if (self.selectedItem ~= idx) then
							todoContent.ButtonHighlightFrame:Hide()
						end

						-- If dragging
						if (self.floatingFrame and self.floatingFrame.isMoving) then
							button.BottomDropIndicator:Hide()
							button.TopDropIndicator:Hide()

							-- Every item have highlight on the top
							local topOffset = 10
							if (idx == 1) then
								topOffset = 800
							end
							if (todoContent:IsMouseOver(topOffset)) then
								self.floatingFrame.targetIndex = idx
								-- Highlight where dragged item will be dropped
								button.TopDropIndicator:Show()
							end

							if (idx == #list and todoContent:IsMouseOver(0, -800)) then
								self.floatingFrame.targetIndex = idx + 1
								button.BottomDropIndicator:Show()
							end
						else
							button.BottomDropIndicator:Hide()
							button.TopDropIndicator:Hide()
							-- If not dragging but hovering
							if (todoContent:IsMouseOver(5, 5)) then
								-- Display hover effect
								todoContent.ButtonHighlightFrame.ButtonHighlightTexture:SetVertexColor(
									highlightColor.r,
									highlightColor.g,
									highlightColor.b
								)
								todoContent.ButtonHighlightFrame:Show()
							end
						end
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

--------------------------------------
-- Lifecycle Events
--------------------------------------
---
---Resets all properties to their default values
function TodoChecklisterFrame:Defaults()
	self.frame:SetSize(300, 300)
	self.frame:ClearAllPoints()
	self.frame:SetPoint("BOTTOMRIGHT", "$parent", "BOTTOMRIGHT", -120, 30)
	self.frame:SetScale(1)
	self.frame:SetAlpha(1)
	self.memoizationId = 0

	Settings:Defaults()
	self:LoadCFG()
end

---
---Load required configuration for this class
function TodoChecklisterFrame:LoadCFG()
	if (self.frame) then
		if (Settings:IsKeepFocusShown()) then
			self.frame.KeepFocus:Show()
		else
			self.frame.KeepFocus:Hide()
		end

		self.memoizationId = self.memoizationId + 1
		self.frame.KeepFocus:SetChecked(Settings:KeepFocus())

		if (not Settings:KeepFocus()) then
			TodoChecklister.TodoText:ClearFocus()
		end

		if (Settings:Opacity()) then
			self.frame:SetAlpha(Settings:Opacity())
		end

		-- Set up scroll bar
		self.frame.ScrollFrame.update = function()
			self.memoizationId = self.memoizationId + 1
			self:OnUpdate()
		end
		HybridScrollFrame_CreateButtons(self.frame.ScrollFrame, "TodoItemTemplate")

		self.displayLinked = Settings:DisplayLinked()
		self.displayBankOnLinked = Settings:DisplayBankOnLinked()
		self.displayChargesOnLinked = Settings:DisplayChargesOnLinked()

		self:OnUpdate()
	end
end

---
---Initializes required properties for this class
function TodoChecklisterFrame:Init()
	-- Creates the addon frame
	local frame = CreateFrame("Frame", "TodoChecklister", UIParent, "TodoChecklisterTemplate")

	-- Store a value to be used as a memoization id
	self.memoizationId = 0

	frame:RegisterEvent("BAG_UPDATE_DELAYED")
	frame:HookScript(
		"OnEvent",
		function(frame, event)
			if (event == "BAG_UPDATE_DELAYED") then
				self.memoizationId = self.memoizationId + 1
				self:OnUpdate()
			end
		end
	)

	-- Set up responsive frame
	ResponsiveFrame:OnLoad(frame)

	--- @class TodoChecklisterWindowFrame
	self.frame = frame

	-- Display window title
	self.frame.Title:SetText(UnitName("player") .. "'s List")

	-- Change window close button to minimize button
	_G["TodoChecklisterClose"]:SetNormalTexture("Interface\\Buttons\\UI-Panel-HideButton-Up")
	_G["TodoChecklisterClose"]:SetPushedTexture("Interface\\Buttons\\UI-Panel-HideButton-Down")
	_G["TodoChecklisterClose"]:SetScript(
		"OnClick",
		function()
			TodoChecklisterFrame:Toggle()
		end
	)

	self.frame.TodoText:SetHyperlinksEnabled(true)
	self.frame:SetHyperlinksEnabled(true)

	-- Set up defaults
	self:LoadCFG()

	if (Settings:IsShown()) then
		-- Display the frame
		self:Toggle()
	end
end

hooksecurefunc(
	"ContainerFrameItemButton_OnModifiedClick",
	function(self, button)
		-- If any of these conditions are true, the link will have been posted
		-- to another UI element by the time this hook is called.
		if
			not TodoChecklisterFrame.frame.TodoText:HasFocus() or
				(ChatEdit_GetActiveWindow() or (BrowseName and BrowseName:IsVisible()) or
					(MacroFrameText and MacroFrameText:HasFocus()) or
					(TradeSkillFrame and TradeSkillFrame.SearchBox and TradeSkillFrame.SearchBox:HasFocus()) or
					(CommunitiesFrame and CommunitiesFrame.ChatEditBox and CommunitiesFrame.ChatEditBox:HasFocus()) or
					(SocialPostFrame and Social_IsShown()))
		 then
			-- Link will have been posted to one of the above areas. Ignore.
			return false
		end

		local bag = self:GetParent():GetID()
		local slot = self:GetID()
		local link = GetContainerItemLink(bag, slot)

		if self.hasStackSplit == 1 then
			StackSplitFrame:Hide()
		end

		TodoChecklisterFrame.frame.TodoText:Insert(link)
	end
)

--------------------------------------
-- XML Events
--------------------------------------
function OnShow(frame)
	TodoChecklisterFrame:OnUpdate()
end

function OnSizeChanged(frame)
	frame.ScrollFrame:SetHeight(frame.Background:GetHeight())
	HybridScrollFrame_CreateButtons(frame.ScrollFrame, "TodoItemTemplate")
	TodoChecklisterFrame:OnUpdate()
end

function OnSaveItem(frame)
	local text = TodoChecklister.TodoText:GetText()
	if (not text or text == "") then
		text = ""
	else
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
	end

	TodoChecklisterFrame:AddItem(text)
end

function OnRemoveItem(frame)
	TodoChecklisterFrame:RemoveItem(frame:GetParent().todoItem)
end

function OnCheckItem(frame)
	TodoChecklisterFrame:CheckItem(frame:GetParent().todoItem)
end

function OnSelectItem(frame)
	TodoChecklisterFrame:SelectItem(frame:GetParent().todoItem)
end

function ToggleFocusSettings(frame)
	Settings:ToggleFocus()
	TodoChecklisterFrame:LoadCFG()
end

function ToggleFocusLoad(frame)
	frame:SetChecked(Settings:KeepFocus())
end

function OnEnter(frame)
	-- if (Settings:OpacityOnHover()) then
	-- 	frame:SetAlpha(Settings:OpacityOnHover())
	-- end
end

function OnLeave(frame)
	-- if (Settings:Opacity()) then
	-- 	frame:SetAlpha(Settings:Opacity())
	-- else
	-- 	frame:SetAlpha(1)
	-- end
end
