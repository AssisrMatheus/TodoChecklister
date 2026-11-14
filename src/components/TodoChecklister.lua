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

-- How far right the items inside a folder are drawn
local FOLDER_ITEM_INDENT = 8
-- A row is 30 high (TodoItemTemplate), and taller when its text wraps onto more lines: the text plus 8 above and below
local ROW_HEIGHT = 30
local ROW_TEXT_PADDING = 16
-- The text sits between the checkbox (24) and the remove button (20, 4 from the right edge)
local ROW_TEXT_INSET = 24 + 24
-- The hover highlight is 16 high, and covers every line of wrapped text
local HIGHLIGHT_HEIGHT = 16
-- Drop margins, as a fraction of the row height. Over half only leaves above/below; 0.3 leaves the middle of a folder
-- row to drop into it
local DROP_MARGIN = 0.55
local FOLDER_DROP_MARGIN = 0.3
-- DragIntersectionArea to the names TodoList:ResolveMove uses
local DROP_AREAS = {
	[DragIntersectionArea.Above] = "above",
	[DragIntersectionArea.Below] = "below",
	[DragIntersectionArea.Inside] = "inside"
}

---@class TodoItemFrame : Button
---@field todoItem TodoItem
---@field TodoCheckButton CheckButton
---@field FolderButton Button
---@field RemoveButton Button
---@field Text FontString
---@field Strikethrough Texture
---@field extraStrikethroughs Texture[]|nil @One more for each line of wrapped text after the first
---@field isSetUp boolean|nil
---@class TodoListBackgroundFrame : Frame
---@field BlankText FontString
---@field MeasureText FontString
---@field ScrollBox Frame
---@class TodoChecklisterWindowFrame : Frame
---@field Title FontString
---@field TodoText EditBox
---@field KeepFocus CheckButton
---@field SettingsButton Button
---@field Background TodoListBackgroundFrame
---@field ScrollBar Frame
---@field ResizeButton Button
---@field TodoTooltip GameTooltip

--------------------------------------
-- TodoChecklisterFrame functions
--------------------------------------
---
---Appends a new TodoItem to the list, or renames the selected one
---@param text string @New element to be appended to the list
---@param isFolder boolean|nil @Whether or not a new element is a folder
function TodoChecklisterFrame:AddItem(text, isFolder)
	if (text ~= "" and text ~= nil and text) then
		-- If the item is not selected
		if (self.selectedItem == nil or self.selectedItem == 0) then
			TodoList:AddItem(text, isFolder)
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
	if (type(fromIndex) == "number" and type(toIndex) == "number") then
		self:KeepSelection(
			function()
				return TodoList:Move(fromIndex, toIndex)
			end
		)
	end
end

---
---Moves an item next to or into another one. A folder moves with its items
---@param todoItem TodoItem @The item being moved
---@param targetItem TodoItem @The item it is dropped on
---@param area "above"|"below"|"inside" @Where it is dropped relative to targetItem
function TodoChecklisterFrame:MoveRelative(todoItem, targetItem, area)
	self:KeepSelection(
		function()
			return TodoList:MoveRelative(TodoList:GetIndexByItem(todoItem), TodoList:GetIndexByItem(targetItem), area)
		end
	)
end

---
---Runs a change that can shift indexes, then points the selection back at the same item and repaints
---@param change fun():boolean @Changes the list, returns whether or not it did
function TodoChecklisterFrame:KeepSelection(change)
	local selectedItem
	if (self.selectedItem and self.selectedItem > 0) then
		selectedItem = TodoList:GetItems()[self.selectedItem]
	end

	if (change()) then
		if (selectedItem) then
			self.selectedItem = TodoList:GetIndexByItem(selectedItem)
		end
		self.memoizationId = self.memoizationId + 1
		self:OnUpdate()
	end
end

---
---Turns an item into a folder, or a folder back into an item
---@param todoItem TodoItem @The item to turn
function TodoChecklisterFrame:ToggleFolder(todoItem)
	local index = TodoList:GetIndexByItem(todoItem)
	if (index > 0 and todoItem.inFolder) then
		TodoAddon.Chat:Print("Folders cannot be placed inside folders. Drag the item out of its folder first")
		return
	end
	if (index > 0 and TodoList:ToggleFolder(index)) then
		self.memoizationId = self.memoizationId + 1
		self:OnUpdate()
	end
end

---
---Opens or closes a folder. Closing it clears the selection when the selected item gets hidden
---@param todoItem TodoItem @The folder
function TodoChecklisterFrame:ToggleCollapsed(todoItem)
	local index = TodoList:GetIndexByItem(todoItem)
	if (index > 0 and todoItem.isFolder) then
		TodoList:ToggleCollapsed(index)
		if (todoItem.isCollapsed and self.selectedItem and self.selectedItem > 0) then
			if (TodoList:GetFolderIndex(self.selectedItem) == index) then
				self:ClearSelected()
			end
		end
		self.memoizationId = self.memoizationId + 1
		self:OnUpdate()
	end
end

---
---What a click on a row does: right click turns it into a folder (or back), left click selects it for editing,
---which is also how a folder is renamed. A folder opens and closes from its +/- button instead
---@param todoItem TodoItem @The clicked item
---@param button string @The mouse button
function TodoChecklisterFrame:ClickItem(todoItem, button)
	if (button == "RightButton") then
		self:ToggleFolder(todoItem)
	else
		self:SelectItem(todoItem)
	end
end

---
---Mark the item on indexToCheck position as done
---@param indexToCheck number @The ONE-based location in the array to check.
function TodoChecklisterFrame:CheckItemWithIndex(indexToCheck)
	if (indexToCheck and type(indexToCheck) == "number" and indexToCheck > 0) then
		local item = TodoList:GetItems()[indexToCheck]
		-- Folders can't be checked
		if (not item or item.isFolder) then
			return
		end
		TodoList:UpdateItem(indexToCheck, {isChecked = (not item.isChecked)})
		self.memoizationId = self.memoizationId + 1
		self:OnUpdate()
		if
			(Settings:PlayFanfare() and
				TableUtils:Every(
					TodoList:GetItems(),
					function(item)
						return item.isFolder or item.isChecked == true
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
---Stops editing the selected item without saving: the item keeps its text, and the input box empties
function TodoChecklisterFrame:CancelEdit()
	if (self.selectedItem and self.selectedItem > 0) then
		self:ClearSelected()
		self.memoizationId = self.memoizationId + 1
		self:OnUpdate()
	end
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
---Saves a list someone shared and switches to it
---@param list SharedList @Output of ListShare:Decode
---@return string @The name it was saved under, which has a number added when the name was taken
function TodoChecklisterFrame:ImportList(list)
	local name = TodoList:ImportList(list.name, list.items)
	self:SwitchList(name)
	return name
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
---The text a row shows for an item: its text with bag counts after item links, and a folder's progress
---@param todoItem TodoItem @The item to display
---@return string
function TodoChecklisterFrame:GetDisplayText(todoItem)
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
	if (todoItem.isFolder) then
		-- Checked and total items, in gray: "Raid prep (2/5)"
		local folderIndex = TodoList:GetIndexByItem(todoItem)
		if (folderIndex > 0) then
			local checked, total = TodoList:GetFolderProgress(folderIndex)
			if (total > 0) then
				text = text .. " |cff808080(" .. checked .. "/" .. total .. ")|r"
			end
		end
	end
	return text
end

---
---@param todoItem TodoItem
---@return FontObject @The font a row uses for the item: white for folders, gray once checked, yellow otherwise
function TodoChecklisterFrame:GetFontObject(todoItem)
	if (todoItem.isFolder) then
		return GameFontHighlightSmall
	elseif (todoItem.isChecked) then
		return GameFontDarkGraySmall
	end
	return GameFontNormalSmall
end

---
---Sets how a row's text handles running out of room: wrapped onto more lines, or cut short with "..." (the game adds
---the "..." itself to a one-line text that doesn't fit)
---@param fontString FontString
---@param wrap boolean|nil @nil (before LoadCFG read the setting) cuts short
function TodoChecklisterFrame:SetTextWrap(fontString, wrap)
	fontString:SetWordWrap(wrap == true)
	-- A word too long for the line (a pasted url) breaks instead of running out of the row
	fontString:SetNonSpaceWrap(wrap == true)
	-- One line when cut short, so its measured height is one line too (Blizzard caps tracker lines the same way)
	fontString:SetMaxLines(wrap == true and 0 or 1)
end

---
---Measures an item's text the way a row shows it, on the hidden MeasureText of the list (the way Blizzard's achievement
---list measures its rows): rows only exist for the visible items, but the ScrollBox needs the height of every one
---@param todoItem TodoItem
---@param rowWidth number @The width of the row
---@return number @The text's height
function TodoChecklisterFrame:MeasureText(todoItem, rowWidth)
	local measure = self.frame.Background.MeasureText
	measure:SetFontObject(self:GetFontObject(todoItem))
	self:SetTextWrap(measure, self.wrapText)
	measure:SetWidth(math.max(rowWidth - (todoItem.inFolder and FOLDER_ITEM_INDENT or 0) - ROW_TEXT_INSET, 1))
	-- Clears what the string measured before, or the height can be stale (ObjectiveTrackerBlockMixin:SetStringText)
	measure:SetHeight(0)
	measure:SetText(self:GetDisplayText(todoItem))
	return measure:GetStringHeight()
end

---
---@param textHeight number @From MeasureText
---@return number @The height of a row with that text
function TodoChecklisterFrame:GetRowHeight(textHeight)
	return math.max(ROW_HEIGHT, math.ceil(textHeight) + ROW_TEXT_PADDING)
end

-- The last character index CalculateScreenAreaFromCharacterSpan accepts, by text. It counts the characters on screen,
-- without the color and link codes around them, so it's shorter than the stored text when the text has links
local spanEnds = {}

---
---@param fontString FontString
---@param last number @The last character to measure
---@return table[]|nil @The areas of the lines from the first character to `last`, or nil when the game refuses `last`
local function CalculateAreas(fontString, last)
	local found, areas = pcall(fontString.CalculateScreenAreaFromCharacterSpan, fontString, 1, last)
	if (found and type(areas) == "table" and #areas > 0) then
		return areas
	end
end

---
---Where each line of a FontString's text sits: one { left, bottom, width, height } per line, from its bottom left corner.
---The game measures the glyphs, the way Blizzard's chat highlights selected text (ScrollingMessageFrame)
---@param fontString FontString
---@return table[]
local function GetLineAreas(fontString)
	local boxWidth = fontString:GetWidth()
	-- One line (wrap off): the game would also measure the text hidden behind the "...". Strike the line that shows,
	-- up to the end of the text or of its box, before the remove button
	if (not fontString:CanWordWrap()) then
		return {
			{
				left = 0,
				bottom = 0,
				width = math.min(fontString:GetStringWidth(), boxWidth),
				height = fontString:GetStringHeight()
			}
		}
	end

	local text = fontString:GetText() or ""
	local last = spanEnds[text]
	if (not last) then
		last = #text
		if (not CalculateAreas(fontString, last)) then
			-- The stored text is longer than what shows: find the last character the game accepts
			local low, high = 0, last
			while (high - low > 1) do
				local middle = math.floor((low + high) / 2)
				if (CalculateAreas(fontString, middle)) then
					low = middle
				else
					high = middle
				end
			end
			last = low
		end
		if (last > 0) then
			spanEnds[text] = last
		end
	end

	local areas = last > 0 and CalculateAreas(fontString, last --[[@as number]])
	if (areas) then
		-- Only the lines that show, each kept inside the text's box
		local shown = {}
		for line = 1, math.min(#areas, math.max(fontString:GetNumLines(), 1)) do
			local area = areas[line]
			local width = math.min(tonumber(area.width) or 0, boxWidth - (tonumber(area.left) or 0))
			if (width > 0) then
				shown[#shown + 1] = {left = area.left, bottom = area.bottom, width = width, height = area.height}
			end
		end
		if (#shown > 0) then
			return shown
		end
	end

	-- The game measured nothing: split the text's height into its lines, each as wide as the widest
	local lineCount = math.max(fontString:GetNumLines(), 1)
	local lineHeight = fontString:GetStringHeight() / lineCount
	local width = math.min(fontString:GetWrappedWidth(), boxWidth)
	areas = {}
	for line = 1, lineCount do
		areas[line] = {left = 0, bottom = (lineCount - line) * lineHeight, width = width, height = lineHeight}
	end
	return areas
end

---
---Strikes through a checked item's text: a line through the middle of each line of text, as wide as its glyphs. The
---first uses the template's Strikethrough, more lines get their own
---The objective tracker section strikes its Questie-style rows the same way: any frame with a Text FontString and a
---Strikethrough texture works. Call it once the frame has its width, which decides where the text wraps
---@param frame TodoItemFrame|table
---@param isShown boolean
---@param color table|nil @The strike color, NORMAL_FONT_COLOR (the window's yellow) when nil
function TodoChecklisterFrame:PaintStrikethrough(frame, isShown, color)
	color = color or NORMAL_FONT_COLOR
	frame.extraStrikethroughs = frame.extraStrikethroughs or {}
	local areas = isShown and GetLineAreas(frame.Text) or {}
	for line = 1, math.max(#areas, #frame.extraStrikethroughs + 1) do
		local texture = line == 1 and frame.Strikethrough or frame.extraStrikethroughs[line - 1]
		if (not texture) then
			texture = frame:CreateTexture(nil, "OVERLAY", nil, 7)
			texture:SetHeight(1)
			frame.extraStrikethroughs[line - 1] = texture
		end
		local area = areas[line]
		if (area) then
			texture:SetColorTexture(color.r, color.g, color.b)
			texture:ClearAllPoints()
			texture:SetPoint("LEFT", frame.Text, "BOTTOMLEFT", area.left, area.bottom + area.height / 2)
			texture:SetWidth(math.max(area.width, 1))
			texture:Show()
		else
			texture:Hide()
		end
	end
end

---
---Shows a row's whole text in a tooltip when it was cut short with "...", like Blizzard's lists do
---@param frame TodoItemFrame
function TodoChecklisterFrame:ShowTruncatedText(frame)
	if (not frame.todoItem or not frame.Text:IsTruncated()) then
		return
	end
	local tooltip = self.frame.TodoTooltip
	tooltip:SetOwner(frame, "ANCHOR_NONE")
	tooltip:ClearAllPoints()
	tooltip:SetPoint("BOTTOMLEFT", frame, "TOPLEFT")
	tooltip:SetText(self:GetDisplayText(frame.todoItem), 1, 1, 1, 1, true)
	tooltip:Show()
end

---
---Set the given frame's properties to the given item ones
---@param frame TodoItemFrame @The row to paint, already sized
---@param todoItem TodoItem @The item displayed by the row
---@param index number @The current item index on the list, 0 for the drag clone
---@return number @The height the row needs for its text
function TodoChecklisterFrame:PaintItem(frame, todoItem, index)
	frame.todoItem = todoItem

	frame.Text:SetFontObject(self:GetFontObject(todoItem))

	-- Items inside a folder sit slightly to the right. Text, highlight and strikethrough follow the checkbox
	frame.TodoCheckButton:ClearAllPoints()
	frame.TodoCheckButton:SetPoint("LEFT", todoItem.inFolder and FOLDER_ITEM_INDENT or 0, 0)
	-- A folder shows a +/- in place of the checkbox
	frame.TodoCheckButton:SetShown(not todoItem.isFolder)
	frame.FolderButton:SetShown(todoItem.isFolder == true)
	if (todoItem.isFolder) then
		local sign = todoItem.isCollapsed and "Plus" or "Minus"
		frame.FolderButton:SetNormalTexture("Interface\\Buttons\\UI-" .. sign .. "Button-Up")
		frame.FolderButton:SetPushedTexture("Interface\\Buttons\\UI-" .. sign .. "Button-Down")
	end

	self:SetTextWrap(frame.Text, self.wrapText)
	frame.Text:SetText(self:GetDisplayText(todoItem))
	-- The row already has its width (the ScrollBox lays rows out before painting them, the drag clones are sized first)
	local textHeight = frame.Text:GetStringHeight()

	-- A drag starts on mouse down, so the row can be left in its pushed state
	frame:SetButtonState("NORMAL")
	local highlightColor = self:GetColor(todoItem)
	frame:GetHighlightTexture():SetVertexColor(highlightColor.r, highlightColor.g, highlightColor.b)
	frame:GetHighlightTexture():SetHeight(math.max(HIGHLIGHT_HEIGHT, textHeight + 4))
	-- Rows only show visible items, so their index isn't the saved one. Compare the items instead
	local selectedItem = self.selectedItem and self.selectedItem > 0 and TodoList:GetItems()[self.selectedItem]
	if (index > 0 and selectedItem == todoItem) then
		frame:LockHighlight()
	else
		frame:UnlockHighlight()
	end

	frame.TodoCheckButton:SetChecked(todoItem.isChecked)

	self:PaintStrikethrough(frame, todoItem.isChecked == true and not todoItem.isFolder)
	return self:GetRowHeight(textHeight)
end

---
---Sets up the scrolling list: one pooled row per visible item, and drag and drop to reorder
function TodoChecklisterFrame:InitScrollBox()
	local scrollBox = self.frame.Background.ScrollBox

	-- Row heights by item, from the last time the ScrollBox measured them. The drop margins read them
	self.rowHeights = setmetatable({}, {__mode = "k"})

	local view = CreateScrollBoxListLinearView()
	-- Wrapped text makes a row as tall as its lines. Cut short, every row is one line
	view:SetElementExtentCalculator(
		function(_, todoItem)
			local height = ROW_HEIGHT ---@type number
			if (self.wrapText) then
				height = self:GetRowHeight((self:MeasureText(todoItem, scrollBox:GetWidth())))
			end
			self.rowHeights[todoItem] = height
			return height
		end
	)
	view:SetElementInitializer(
		"TodoItemTemplate",
		function(row, todoItem)
			if (not row.isSetUp) then
				row.isSetUp = true
				row:HookScript(
					"OnEnter",
					function(frame)
						self:ShowTruncatedText(frame)
					end
				)
				row:HookScript(
					"OnLeave",
					function()
						self.frame.TodoTooltip:Hide()
					end
				)
			end
			self:PaintItem(row, todoItem, row:GetElementDataIndex())
		end
	)
	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, self.frame.ScrollBar, view)

	-- A narrower or wider window wraps the text onto a different number of lines: measure the rows again
	scrollBox:HookScript(
		"OnSizeChanged",
		function(_, width)
			if (self.wrapText and self.frame:IsShown() and width ~= self.listWidth) then
				self:RefreshRows()
			end
		end
	)

	local dragBehavior = ScrollUtil.InitDefaultLinearDragBehavior(scrollBox)
	dragBehavior:SetReorderable(true)

	-- Over half the row height: the drop goes above or below a row, never swaps with it.
	-- Except an item over a folder: the middle of the folder row drops the item into it
	dragBehavior:SetAreaIntersectMargin(
		function(targetItem, _, contextData)
			local sourceItem = contextData.sourceData and contextData.sourceData.elementData
			local height = self.rowHeights[targetItem] or ROW_HEIGHT
			if (targetItem.isFolder and sourceItem and not sourceItem.isFolder) then
				return height * FOLDER_DROP_MARGIN
			end
			return height * DROP_MARGIN
		end
	)

	-- Only offer drops TodoList accepts (folders can't go inside folders)
	dragBehavior:SetDropPredicate(
		function(sourceItem, candidate)
			return self:ResolveDrop(sourceItem, candidate) ~= nil
		end
	)

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
			-- Remembered for PostDrop, which doesn't receive the drop area
			self.dropTarget = {elementData = candidate.elementData, area = DROP_AREAS[candidate.area]}

			if (candidate.area == DragIntersectionArea.Inside) then
				-- Into a folder: a box around the folder row
				local box = factory("ScrollBoxDragBoxTemplate")
				box:SetPoint("TOPLEFT", candidate.frame, "TOPLEFT", 0, -3)
				box:SetPoint("BOTTOMRIGHT", candidate.frame, "BOTTOMRIGHT", 0, 3)
				return
			end

			-- A line, indented when the item would end up inside a folder
			local _, inFolder = self:ResolveDrop(dragBehavior.sourceData.elementData, candidate)
			local indent = inFolder and FOLDER_ITEM_INDENT or 0
			local indicator = factory("DropIndicatorTemplate")
			if (candidate.area == DragIntersectionArea.Above) then
				indicator:SetPoint("BOTTOMLEFT", candidate.frame, "TOPLEFT", indent, -2)
				indicator:SetPoint("BOTTOMRIGHT", candidate.frame, "TOPRIGHT", 0, -2)
			else
				indicator:SetPoint("TOPLEFT", candidate.frame, "BOTTOMLEFT", indent, 2)
				indicator:SetPoint("TOPRIGHT", candidate.frame, "BOTTOMRIGHT", 0, 2)
			end
		end
	)

	-- The data provider is already reordered here, but it only holds the visible rows.
	-- Apply the move to the saved list instead, and OnUpdate replaces the data provider
	dragBehavior:SetPostDrop(
		function(contextData)
			local dropTarget = self.dropTarget
			self.dropTarget = nil
			if (dropTarget) then
				self:MoveRelative(contextData.sourceData.elementData, dropTarget.elementData, dropTarget.area)
			else
				self:OnUpdate()
			end
		end
	)
end

---
---Where a dragged item would land on a drop candidate
---@param sourceItem TodoItem @The dragged item
---@param candidate table @The drag behavior's candidate: elementData and area
---@return number|nil, boolean|nil @See TodoList:ResolveMove
function TodoChecklisterFrame:ResolveDrop(sourceItem, candidate)
	local area = DROP_AREAS[candidate.area]
	if (not area or not candidate.elementData) then
		return nil
	end
	return TodoList:ResolveMove(TodoList:GetIndexByItem(sourceItem), TodoList:GetIndexByItem(candidate.elementData), area)
end

---
---The main update function for this class: repaints the visible rows from the saved list
function TodoChecklisterFrame:OnUpdate()
	if (not self.frame) then
		return
	end

	-- The objective tracker section shows the same list. Looked up at call time: modules load after components
	TodoAddon.ObjectiveTrackerSection:Refresh()

	if (#TodoList:GetItems() > 0) then
		self.frame.Background.BlankText:SetText("")
	else
		self.frame.Background.BlankText:SetText(
			"You have no items on your list \r\n\r\n Start by typing them in the box above \r\n\r\n =)"
		)
	end

	-- Hidden windows are repainted by OnShow
	if (self.frame:IsShown()) then
		self:RefreshRows()
	end
end

---
---Hands the visible items to the ScrollBox, which measures every row again and repaints the visible ones
function TodoChecklisterFrame:RefreshRows()
	local scrollBox = self.frame.Background.ScrollBox
	self.listWidth = scrollBox:GetWidth()
	scrollBox:SetDataProvider(CreateDataProvider(TodoList:GetVisibleItems()), ScrollBoxConstants.RetainScrollPosition)
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
		self.wrapText = Settings:WrapText()

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

	self.frame.SettingsButton:SetScript(
		"OnClick",
		function()
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			TodoAddon.InterfaceOptions:Open()
		end
	)

	self.frame.TodoText:SetHyperlinksEnabled(true)
	self.frame:SetHyperlinksEnabled(true)
	-- InputBoxTemplate's Escape only drops focus. While editing an item it also cancels the edit, so the next Enter
	-- doesn't overwrite the item. A new item being typed keeps its text
	self.frame.TodoText:HookScript(
		"OnEscapePressed",
		function()
			self:CancelEdit()
		end
	)

	-- Set up defaults
	self:LoadCFG()

	if (Settings:IsShown()) then
		-- Display the frame
		self:Toggle()
	end
end

-- Retail and Forever: when InsertLink returns false, quest click handlers fall through to their shift-click
-- behavior (objective tracker untracks, quest log toggles tracking, map pins track and super-track). The hook
-- can't change that return value without replacing Blizzard's function, which would taint every link click.
-- Instead, remember the quest's tracking state before the fallback runs and put it back on the next frame
local function KeepQuestTracking(link)
	local questID = tonumber(strmatch(link, "|Hquest:(%d+)") or "")
	if (not questID or not C_QuestLog.GetQuestWatchType or not C_SuperTrack.SetSuperTrackedQuestID) then
		return
	end

	local watchType = C_QuestLog.GetQuestWatchType(questID)
	local superTrackedID = C_SuperTrack.GetSuperTrackedQuestID()
	C_Timer.After(
		0,
		function()
			local isWorldQuest = C_QuestLog.IsWorldQuest(questID)
			local currentWatchType = C_QuestLog.GetQuestWatchType(questID)
			if (watchType and not currentWatchType) then
				if (isWorldQuest) then
					C_QuestLog.AddWorldQuestWatch(questID, watchType)
				else
					C_QuestLog.AddQuestWatch(questID)
				end
			elseif (not watchType and currentWatchType) then
				if (isWorldQuest) then
					C_QuestLog.RemoveWorldQuestWatch(questID)
				else
					C_QuestLog.RemoveQuestWatch(questID)
				end
			end
			if (C_SuperTrack.GetSuperTrackedQuestID() ~= superTrackedID) then
				C_SuperTrack.SetSuperTrackedQuestID(superTrackedID or 0)
			end
		end
	)
end

-- Every shift-click link (items through HandleModifiedItemClick, quests, spells, achievements, currencies,
-- recipes, mounts, pets, toys, quest rewards...) ends in ChatFrameUtil.InsertLink, which only knows about
-- Blizzard's own edit boxes. Insert the link into ours when it has focus. hooksecurefunc keeps Blizzard's
-- function secure
local function InsertLinkIntoTodoText(link)
	if
		type(link) ~= "string" or link == "" or not IsModifiedClick("CHATLINK") or not TodoChecklisterFrame.frame or
			not TodoChecklisterFrame.frame.TodoText:HasFocus() or
			ChatFrameUtil.GetActiveWindow()
	 then
		-- Link will have been posted to the chat box instead. Ignore.
		return
	end

	TodoChecklisterFrame.frame.TodoText:Insert(link)
	KeepQuestTracking(link)
end
hooksecurefunc(ChatFrameUtil, "InsertLink", InsertLinkIntoTodoText)
-- Blizzard_DeprecatedChatInfo keeps ChatEdit_InsertLink pointing at the original function, and other addons
-- still call it. A call goes through only one of the two, so hooking both never inserts twice
if (ChatEdit_InsertLink and ChatEdit_InsertLink ~= ChatFrameUtil.InsertLink) then
	hooksecurefunc("ChatEdit_InsertLink", InsertLinkIntoTodoText)
end

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

	-- Shift+Enter (or shift-clicking +) adds a folder
	TodoChecklisterFrame:AddItem(text, IsShiftKeyDown())
end

function OnRemoveItem(frame)
	TodoChecklisterFrame:RemoveItem(frame:GetParent().todoItem)
end

function OnCheckItem(frame)
	TodoChecklisterFrame:CheckItem(frame:GetParent().todoItem)
end

function OnSelectItem(frame, button)
	TodoChecklisterFrame:ClickItem(frame.todoItem, button)
end

function TodoChecklister_OnFolderButtonClick(frame)
	TodoChecklisterFrame:ToggleCollapsed(frame:GetParent().todoItem)
end

function ToggleFocusSettings(frame)
	Settings:ToggleFocus()
	TodoChecklisterFrame:LoadCFG()
end
