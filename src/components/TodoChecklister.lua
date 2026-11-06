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

---@class TodoItemFrame : Button
---@field todoItem TodoItem
---@field TodoCheckButton CheckButton
---@field RemoveButton Button
---@field Text FontString
---@field Strikethrough Texture
---@class TodoListBackgroundFrame : Frame
---@field BlankText FontString
---@field ScrollBox Frame
---@class TodoChecklisterWindowFrame : Frame
---@field Title FontString
---@field TodoText EditBox
---@field KeepFocus CheckButton
---@field Background TodoListBackgroundFrame
---@field ScrollBar Frame
---@field ResizeButton Button

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
---@param toIndex number @The ONE-based location the item ends up in.
function TodoChecklisterFrame:Move(fromIndex, toIndex)
	local items = TodoList:GetItems()
	if (type(fromIndex) == "number" and type(toIndex) == "number" and items[fromIndex] and items[toIndex]) then
		local selectedItem
		if (self.selectedItem and self.selectedItem > 0) then
			selectedItem = items[self.selectedItem]
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
function TodoChecklisterFrame:SelectItem(todoItem)
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
	if (not Settings:KeepFocus()) then
		self.frame.TodoText:ClearFocus()
	end
end

---
---Makes the window display another saved list
---@param name string @The name of an existing list
function TodoChecklisterFrame:SwitchList(name)
	TodoList:SelectList(name)
	self:OnListChanged()
end

---
---Creates a new empty list and switches to it
---@param name string @The name of the new list
---@return boolean @Whether or not the list was created. False when the name is empty or already taken
function TodoChecklisterFrame:CreateList(name)
	if (not TodoList:CreateList(name)) then
		return false
	end
	self:SwitchList(name)
	return true
end

---
---Deletes a list. If it was the displayed one, the window falls back to the character's default list
---@param name string @The name of the list to delete
function TodoChecklisterFrame:DeleteList(name)
	TodoList:DeleteList(name)
	self:OnListChanged()
end

---
---Resets the window state after the displayed list changed
function TodoChecklisterFrame:OnListChanged()
	self:ClearSelected()
	self.frame.Title:SetText(TodoList:GetSelectedListName())
	self.frame.Background.ScrollBox:ScrollToBegin()
	self.memoizationId = self.memoizationId + 1
	self:OnUpdate()
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
	if (todoItem.isChecked) then
		return DISABLED_FONT_COLOR
	end
	return NORMAL_FONT_COLOR
end

---
---Appends the bag count after every item link in the text: "[Chipped Claw](2)"
---@param text string @The item text
---@return string
function TodoChecklisterFrame:GetTextWithItemCounts(text)
	local includeBank, includeCharges = self.displayBankOnLinked, self.displayChargesOnLinked
	return (text:gsub(
		"|Hitem:.-|r",
		function(link)
			local count = C_Item.GetItemCount(link, includeBank, includeCharges, includeBank, includeBank)
			if (count and count > 0) then
				return link .. "(" .. count .. ")"
			end
		end
	))
end

---
---Set the given frame's properties to the given item ones
---@param frame TodoItemFrame @The row to paint
---@param todoItem TodoItem @The item displayed by the row
---@param index number @The current item index on the list, 0 for the drag clone
function TodoChecklisterFrame:PaintItem(frame, todoItem, index)
	frame.todoItem = todoItem

	if (todoItem.isChecked) then
		frame:SetNormalFontObject(GameFontDarkGraySmall)
	else
		frame:SetNormalFontObject(GameFontNormalSmall)
	end

	local text = todoItem.text
	if (self.displayLinked and text:find("|Hitem:", 1, true)) then
		-- Links only change their count when bags change, so it's cached until memoizationId changes
		local identifier = todoItem.id or todoItem.text
		text =
			FunctionUtils:Memoize(
			function()
				return self:GetTextWithItemCounts(todoItem.text)
			end,
			identifier .. self.memoizationId,
			identifier .. "Count"
		)
	end
	frame:SetText(text)

	-- A drag starts on mouse down, so the row can be left in its pushed state
	frame:SetButtonState("NORMAL")
	local highlightColor = self:GetColor(todoItem)
	frame:GetHighlightTexture():SetVertexColor(highlightColor.r, highlightColor.g, highlightColor.b)
	if (index > 0 and self.selectedItem == index) then
		frame:LockHighlight()
	else
		frame:UnlockHighlight()
	end

	frame.TodoCheckButton:SetChecked(todoItem.isChecked)

	frame.Strikethrough:SetShown(todoItem.isChecked)
end

---
---Sets up the scrolling list: one pooled row per visible item, and drag and drop to reorder
function TodoChecklisterFrame:InitScrollBox()
	local scrollBox = self.frame.Background.ScrollBox

	local view = CreateScrollBoxListLinearView()
	view:SetElementInitializer(
		"TodoItemTemplate",
		function(row, todoItem)
			self:PaintItem(row, todoItem, row:GetElementDataIndex())
		end
	)
	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, self.frame.ScrollBar, view)

	local dragBehavior = ScrollUtil.InitDefaultLinearDragBehavior(scrollBox)
	dragBehavior:SetReorderable(true)

	-- Over half the row height: the drop always goes above or below a row, never swaps with it
	dragBehavior:SetAreaIntersectMargin(16)

	-- The clone that follows the cursor: the same row, with a backdrop and highlighted
	dragBehavior:SetCursorFactory(
		function()
			return "TodoItemTemplate", function(cursorRow, sourceRow, todoItem)
				cursorRow:SetSize(sourceRow:GetSize())
				self:PaintItem(cursorRow, todoItem, 0)
				cursorRow:SetBackdrop(TodoChecklister_BACKDROP)
				cursorRow:LockHighlight()
			end
		end
	)

	dragBehavior:SetDropEnter(
		function(factory, candidate)
			local indicator = factory("DropIndicatorTemplate")
			if (candidate.area == DragIntersectionArea.Above) then
				indicator:SetPoint("BOTTOMLEFT", candidate.frame, "TOPLEFT", 0, -2)
				indicator:SetPoint("BOTTOMRIGHT", candidate.frame, "TOPRIGHT", 0, -2)
			else
				indicator:SetPoint("TOPLEFT", candidate.frame, "BOTTOMLEFT", 0, 2)
				indicator:SetPoint("TOPRIGHT", candidate.frame, "BOTTOMRIGHT", 0, 2)
			end
		end
	)

	-- The data provider is already reordered here. Apply the same move to the saved list
	dragBehavior:SetPostDrop(
		function(contextData)
			self:Move(contextData.sourceData.elementDataIndex, contextData.newSourceData.elementDataIndex)
		end
	)
end

---
---The main update function for this class: repaints the visible rows from the saved list
function TodoChecklisterFrame:OnUpdate()
	if (not self.frame) then
		return
	end

	local items = TodoList:GetItems()
	if (#items > 0) then
		self.frame.Background.BlankText:SetText("")
	else
		self.frame.Background.BlankText:SetText(
			"You have no items on your list \r\n\r\n Start by typing them in the box above \r\n\r\n =)"
		)
	end

	-- Hidden windows are repainted by OnShow
	if (self.frame:IsShown()) then
		self.frame.Background.ScrollBox:SetDataProvider(CreateDataProvider(items), ScrollBoxConstants.RetainScrollPosition)
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
	self.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -120, 30)
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
			self.frame.TodoText:ClearFocus()
		end

		if (Settings:Opacity()) then
			self.frame:SetAlpha(Settings:Opacity())
		end

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
	self:InitScrollBox()

	-- Display window title
	self.frame.Title:SetText(TodoList:GetSelectedListName())

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

-- Shift-clicking an item calls HandleModifiedItemClick(link), which only knows about
-- Blizzard's own edit boxes. Insert the link into ours when it has focus.
hooksecurefunc(
	"HandleModifiedItemClick",
	function(link)
		if
			not link or not IsModifiedClick("CHATLINK") or not TodoChecklisterFrame.frame or
				not TodoChecklisterFrame.frame.TodoText:HasFocus() or
				ChatFrameUtil.GetActiveWindow()
		 then
			-- Link will have been posted to the chat box instead. Ignore.
			return
		end

		TodoChecklisterFrame.frame.TodoText:Insert(link)
	end
)

-- Shift-click on a bag stack also opens the stack split frame, close it while linking
local function CloseStackSplitWhileLinking()
	if (TodoChecklisterFrame.frame and TodoChecklisterFrame.frame.TodoText:HasFocus()) then
		StackSplitFrame:Hide()
	end
end
if (StackSplitFrame.OpenStackSplitFrame) then
	-- Retail and Forever: a method of StackSplitMixin
	hooksecurefunc(StackSplitFrame, "OpenStackSplitFrame", CloseStackSplitWhileLinking)
else
	-- Classic clients (Mists, TBC Anniversary, Era): a global function (Blizzard_FrameXML/Classic/StackSplitFrame.lua)
	hooksecurefunc("OpenStackSplitFrame", CloseStackSplitWhileLinking)
end

--------------------------------------
-- XML Events
--------------------------------------
function OnShow(frame)
	TodoChecklisterFrame:OnUpdate()
end

function OnSaveItem(frame)
	local text = TodoChecklisterFrame.frame.TodoText:GetText()
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
	TodoChecklisterFrame:SelectItem(frame.todoItem)
end

function ToggleFocusSettings(frame)
	Settings:ToggleFocus()
	TodoChecklisterFrame:LoadCFG()
end
