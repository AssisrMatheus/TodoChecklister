--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)
---@type string
local addonName = select(1, ...)

---@class TodoChecklisterFrame
local TodoChecklisterFrame = TodoAddon.TodoChecklisterFrame
---@class TodoList
local TodoList = TodoAddon.TodoList
---@class Settings
local Settings = TodoAddon.Settings

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.ObjectiveTrackerSection = {}

---Shows the selected list as a section of Blizzard's objective tracker, above the quests, rendered by Blizzard's own
---module, block and line templates. Retail and Forever only: the Classic clients have no ObjectiveTrackerManager.
---Its rows only call TodoChecklisterFrame, like every module that changes the list.
---Being a tracker module, Blizzard's tracker update runs this code, which taints the rest of that update. To keep
---that out of combat, the section never asks for an update during combat and waits for it to end instead
---@class ObjectiveTrackerSection
---@field module table|nil @The tracker module, created on Init when the client has the tracker
---@field isAttached boolean|nil @Whether or not the module is in the tracker
---@field needsRefresh boolean|nil @Whether or not a refresh waits for combat to end
---@field dragItem TodoItem|nil @The item being dragged
---@field dropTarget table|nil @Where the dragged item would land: { todoItem, area }
---@field lastDragTime number|nil @When the last drag ended, so the click that ends a drag doesn't also check or collapse
local ObjectiveTrackerSection = TodoAddon.ObjectiveTrackerSection

-- Blocks are spaced like quests, lines like objectives
local LOOSE_BLOCK_PREFIX = "loose:"
-- The middle of a folder header, as a fraction of its height, drops an item into the folder
local FOLDER_INSIDE_FRACTION = 0.5

--------------------------------------
-- Rows
--------------------------------------
---
---@param todoItem TodoItem
---@return string|number @A key for blocks and lines that stays the same across layouts
local function GetKey(todoItem)
	return todoItem.id or tostring(todoItem)
end

---
---Whether or not a click should be ignored because it ends a drag (it can arrive before or after OnDragStop)
---@return boolean
local function IsDragClick()
	local lastDragTime = ObjectiveTrackerSection.lastDragTime
	return ObjectiveTrackerSection.dragItem ~= nil or (lastDragTime ~= nil and GetTime() - lastDragTime < 0.1)
end

---
---Makes a pooled row draggable. Pools are per parent, so these frames are only ever ours
---@param region table @A line, its checkbox, or a folder block's HeaderButton
local function SetUpDrag(region)
	if (region.todoChecklisterDrag) then
		return
	end
	region.todoChecklisterDrag = true
	region:EnableMouse(true)
	region:RegisterForDrag("LeftButton")
	region:SetScript(
		"OnDragStart",
		function(self)
			ObjectiveTrackerSection:StartDrag(self.todoItem)
		end
	)
	region:SetScript(
		"OnDragStop",
		function()
			ObjectiveTrackerSection:StopDrag()
		end
	)
end

---
---Sets up a pooled line once: clicking checks the item, hovering highlights it like a quest objective
---@param line table
local function SetUpLine(line)
	SetUpDrag(line)
	if (line.todoChecklisterLine) then
		return
	end
	line.todoChecklisterLine = true
	-- The checkbox works like the window's: it checks the item, and a drag can start on it too
	SetUpDrag(line.TodoCheckButton)
	line.TodoCheckButton:SetScript(
		"OnClick",
		function(self)
			if (IsDragClick()) then
				-- The button already flipped itself: put it back
				self:SetChecked(not self:GetChecked())
				return
			end
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			TodoChecklisterFrame:CheckItem(self.todoItem)
		end
	)
	line:SetScript(
		"OnMouseUp",
		function(self, button)
			if (button == "LeftButton" and self.todoItem and not IsDragClick()) then
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				TodoChecklisterFrame:CheckItem(self.todoItem)
			end
		end
	)
	line:SetScript(
		"OnEnter",
		function(self)
			local colorStyle = self.Text.colorStyle and self.Text.colorStyle.reverse
			if (colorStyle) then
				self.Text:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)
			end
		end
	)
	line:SetScript(
		"OnLeave",
		function(self)
			local colorStyle = self.Text.colorStyle
			if (colorStyle) then
				self.Text:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)
			end
		end
	)
end

---
---Adds an item as an objective line with a checkbox, gray once checked like a completed objective
---@param block table
---@param todoItem TodoItem
local function AddItemLine(block, todoItem)
	local line =
		block:AddObjective(
		GetKey(todoItem),
		TodoChecklisterFrame:GetDisplayText(todoItem),
		nil,
		true,
		OBJECTIVE_DASH_STYLE_HIDE,
		todoItem.isChecked and OBJECTIVE_TRACKER_COLOR["Complete"] or OBJECTIVE_TRACKER_COLOR["Normal"]
	)
	-- Present hides Blizzard's own completed check: the checkbox shows the state
	line:SetState(ObjectiveTrackerAnimLineState.Present)
	line.todoItem = todoItem
	line.TodoCheckButton.todoItem = todoItem
	line.TodoCheckButton:SetChecked(todoItem.isChecked == true)
	SetUpLine(line)
end

--------------------------------------
-- Tracker module
--------------------------------------
---Overrides for Blizzard's ObjectiveTrackerModuleMixin, applied on top of the module template
local SectionMixin = {
	blockTemplate = "ObjectiveTrackerBlockTemplate",
	lineTemplate = "TodoChecklisterTrackerLineTemplate"
}

---
---Lays out the visible items: a folder is a block with its name as the header and its items as lines,
---and a run of items outside folders shares one block without a header
function SectionMixin:LayoutContents()
	self:SetHeader(TodoList:GetSelectedListName())

	---@type table|nil
	local block
	for _, todoItem in ipairs(TodoList:GetVisibleItems()) do
		local startsBlock = todoItem.isFolder or not (todoItem.inFolder or (block and block.isLoose))
		if (startsBlock or not block) then
			-- Stop as soon as a block doesn't fit, like Blizzard's modules
			if (block and not self:LayoutBlock(block)) then
				return
			end
			if (todoItem.isFolder) then
				block = self:GetBlock(GetKey(todoItem))
				block.isLoose = nil
				block.todoItem = todoItem
				block:SetHeader(TodoChecklisterFrame:GetDisplayText(todoItem))
				block.HeaderButton.todoItem = todoItem
				SetUpDrag(block.HeaderButton)
			else
				block = self:GetBlock(LOOSE_BLOCK_PREFIX .. GetKey(todoItem))
				block.isLoose = true
				block.todoItem = nil
				block.HeaderButton.todoItem = nil
			end
		end
		if (not todoItem.isFolder) then
			AddItemLine(block, todoItem)
		end
	end

	if (block) then
		self:LayoutBlock(block)
	end
end

---
---Clicking a folder's name opens or closes it
---@param block table
---@param mouseButton string
function SectionMixin:OnBlockHeaderClick(block, mouseButton)
	if (mouseButton == "LeftButton" and block.todoItem and not IsDragClick()) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		TodoChecklisterFrame:ToggleCollapsed(block.todoItem)
	end
end

--------------------------------------
-- Drag and drop
--------------------------------------
---
---@return table[] @Every row the module shows, top to bottom isn't guaranteed: { region, todoItem }
function ObjectiveTrackerSection:GetRows()
	local rows = {}
	self.module:EnumerateActiveBlocks(
		function(block)
			if (block.todoItem) then
				table.insert(rows, {region = block.HeaderButton, todoItem = block.todoItem})
			end
			block:ForEachUsedLine(
				function(line)
					if (line.todoItem) then
						table.insert(rows, {region = line, todoItem = line.todoItem})
					end
				end
			)
		end
	)
	return rows
end

---
---@param todoItem TodoItem @The item being dragged
function ObjectiveTrackerSection:StartDrag(todoItem)
	if (not todoItem) then
		return
	end
	self.dragItem = todoItem
	self.dropTarget = nil
	-- The clone that follows the cursor: the window's row, painted and highlighted the same way as the window's
	-- drag clone. Its OnUpdate drives the drag, and only runs while a drag shows it
	local cursorRow = self.cursorRow
	TodoChecklisterFrame:PaintItem(cursorRow, todoItem, 0)
	cursorRow:SetBackdrop(TodoChecklister_BACKDROP)
	cursorRow:LockHighlight()
	cursorRow:SetWidth(self.module:GetWidth())
	self.dropIndicator:Show()
	cursorRow:Show()
	self:UpdateDrag()
end

---
---Runs every frame during a drag: moves the clone to the cursor and updates the drop indicator.
---The drag also ends here when the button is up: the game doesn't send OnDragStop when the dragged row is hidden
function ObjectiveTrackerSection:UpdateDrag()
	if (not IsMouseButtonDown("LeftButton")) then
		self:StopDrag()
		return
	end
	local x, y = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	self.cursorRow:ClearAllPoints()
	self.cursorRow:SetPoint("LEFT", UIParent, "BOTTOMLEFT", x / scale + 8, y / scale)
	self:UpdateDrop()
end

---
---Works out the row under the cursor and shows where the dragged item would land
function ObjectiveTrackerSection:UpdateDrop()
	local dragItem = self.dragItem
	if (not dragItem) then
		return
	end
	local line, box = self.dropIndicator.Line, self.dropIndicator.Box
	line:Hide()
	box:Hide()
	self.dropTarget = nil

	local _, cursorY = GetCursorPosition()
	for _, row in ipairs(self:GetRows()) do
		local region = row.region
		if (row.todoItem ~= dragItem and region:IsVisible() and region:IsMouseOver()) then
			local scale = region:GetEffectiveScale()
			local top, bottom = region:GetTop() * scale, region:GetBottom() * scale
			local fraction = (top - cursorY) / math.max(top - bottom, 1)

			local area
			if (row.todoItem.isFolder and not dragItem.isFolder and math.abs(fraction - 0.5) < FOLDER_INSIDE_FRACTION / 2) then
				area = DragIntersectionArea.Inside
			elseif (fraction < 0.5) then
				area = DragIntersectionArea.Above
			else
				area = DragIntersectionArea.Below
			end

			-- Same rules as the window: TodoList decides which drops are allowed
			if (TodoChecklisterFrame:ResolveDrop(dragItem, {elementData = row.todoItem, area = area}) ~= nil) then
				self.dropTarget = {todoItem = row.todoItem, area = area}
				if (area == DragIntersectionArea.Inside) then
					box:ClearAllPoints()
					box:SetPoint("TOPLEFT", region, "TOPLEFT", -4, 3)
					box:SetPoint("BOTTOMRIGHT", region, "BOTTOMRIGHT", 0, -3)
					box:Show()
				else
					local point, relativePoint = "BOTTOM", "TOP"
					if (area == DragIntersectionArea.Below) then
						point, relativePoint = "TOP", "BOTTOM"
					end
					line:ClearAllPoints()
					line:SetPoint(point .. "LEFT", region, relativePoint .. "LEFT", 0, area == DragIntersectionArea.Above and 1 or -1)
					line:SetPoint(point .. "RIGHT", region, relativePoint .. "RIGHT", 0, area == DragIntersectionArea.Above and 1 or -1)
					line:Show()
				end
			end
			return
		end
	end
end

---
---Drops the dragged item where the indicator shows
function ObjectiveTrackerSection:StopDrag()
	local dragItem, dropTarget = self.dragItem, self.dropTarget
	if (not dragItem) then
		return
	end
	self.dragItem = nil
	self.dropTarget = nil
	self.dropIndicator:Hide()
	self.cursorRow:Hide()
	self.lastDragTime = GetTime()

	if (dragItem and dropTarget) then
		local areaNames = {
			[DragIntersectionArea.Above] = "above",
			[DragIntersectionArea.Below] = "below",
			[DragIntersectionArea.Inside] = "inside"
		}
		TodoChecklisterFrame:MoveRelative(dragItem, dropTarget.todoItem, areaNames[dropTarget.area])
	end
	-- A refresh asked for during the drag, when no move happened
	if (self.needsRefresh) then
		self:Refresh()
	end
end

--------------------------------------
-- Lifecycle Events
--------------------------------------
---
---Asks the tracker to lay the section out again. During combat it waits for combat to end
function ObjectiveTrackerSection:Refresh()
	if (not self.isAttached) then
		return
	end
	-- Laying out during a drag would recycle the dragged row. Wait for the drop instead
	if (InCombatLockdown() or self.dragItem) then
		self.needsRefresh = true
		return
	end
	self.needsRefresh = nil
	self.module:MarkDirty()
end

---
---Load required configuration for this class: adds the section to the tracker or takes it out
function ObjectiveTrackerSection:LoadCFG()
	-- Not ready before the tracker set itself up (see Init)
	if (not self.module or not self.isReady) then
		return
	end

	if (Settings:DisplayInObjectiveTracker()) then
		if (not self.isAttached) then
			-- Above the campaign and quest sections, below the scenario and widget ones
			local questModule = CampaignQuestObjectiveTracker or QuestObjectiveTracker
			self.module.uiOrder = ((questModule and questModule.uiOrder) or 3) - 0.5
			ObjectiveTrackerManager:SetModuleContainer(self.module, ObjectiveTrackerFrame)
			self.isAttached = ObjectiveTrackerFrame:HasModule(self.module)
		end
		self:Refresh()
	elseif (self.isAttached) then
		self.isAttached = nil
		ObjectiveTrackerFrame:RemoveModule(self.module)
		self.module:Hide()
	end
end

---
---Initializes required properties for this class
function ObjectiveTrackerSection:Init()
	-- Classic clients have the older quest watch frame instead
	if (not ObjectiveTrackerManager or not ObjectiveTrackerFrame) then
		return
	end

	self.module = CreateFrame("Frame", addonName .. "ObjectiveTracker", UIParent, "ObjectiveTrackerModuleTemplate")
	Mixin(self.module, SectionMixin)

	-- Clicking the section's title opens or closes the window. Its minimize button keeps working: it is a child
	-- button and takes its own clicks
	self.module.Header:EnableMouse(true)
	self.module.Header:SetScript(
		"OnMouseUp",
		function(_, button)
			if (button == "LeftButton") then
				TodoChecklisterFrame:Toggle()
			end
		end
	)

	-- Shown only while dragging, like the clone below, so nothing runs every frame while idle
	self.dropIndicator = CreateFrame("Frame", nil, self.module)
	self.dropIndicator:SetAllPoints()
	self.dropIndicator:Hide()
	self.dropIndicator.Line = CreateFrame("Frame", nil, self.dropIndicator, "DropIndicatorTemplate")
	self.dropIndicator.Box = CreateFrame("Frame", nil, self.dropIndicator, "ScrollBoxDragBoxTemplate")

	self.cursorRow = CreateFrame("Button", nil, UIParent, "TodoItemTemplate")
	self.cursorRow:SetFrameStrata("TOOLTIP")
	self.cursorRow:SetHeight(24)
	self.cursorRow:Hide()
	-- The clone never takes the mouse, so the drop still finds the row under the cursor
	self.cursorRow:EnableMouse(false)
	for _, child in ipairs({self.cursorRow:GetChildren()}) do
		child:EnableMouse(false)
	end
	self.cursorRow:SetScript(
		"OnUpdate",
		function()
			self:UpdateDrag()
		end
	)

	local events = CreateFrame("Frame")
	events:RegisterEvent("PLAYER_REGEN_ENABLED")
	events:SetScript(
		"OnEvent",
		function()
			if (self.needsRefresh) then
				self:Refresh()
			end
		end
	)

	-- The tracker adds its own sections once both events fired, and only accepts new ones after that
	EventUtil.ContinueAfterAllEvents(
		function()
			RunNextFrame(
				function()
					self.isReady = true
					self:LoadCFG()
				end
			)
		end,
		"PLAYER_ENTERING_WORLD",
		"VARIABLES_LOADED"
	)
end
