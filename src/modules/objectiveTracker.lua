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

---Shows the selected list as a section of Blizzard's objective tracker, before its quests, styled like a tracker section: Blizzard's
---section header, folders like quest titles, items like objectives. Retail and Forever only: the Classic clients
---have older quest watch frames instead.
---
---!!! Blizzard's tracker code must never call this code. 2.2.0 added the list as a real tracker module, so the
---tracker's update ran our code, and redraws it asked for ran tainted from their first line. On clients with secret
---values that broke Blizzard code in the same update ("GetAuraDataByIndex(): Auras cannot be accessed when secret
---while tainted by 'TodoChecklister'"). This section is our own frames and pool. It follows the tracker only through
---hooksecurefunc / HookScript post-hooks, which leave Blizzard's code secure, and it only reads Blizzard's state !!!
---
---Its rows only call TodoChecklisterFrame, like every module that changes the list.
---@class ObjectiveTrackerSection
---@field section table|nil @Our section frame, created on Init when the client has the tracker
---@field header table|nil @Blizzard's section header (ObjectiveTrackerModuleHeaderTemplate), ours to own
---@field rowPool table|nil @Pool of TodoChecklisterTrackerLineTemplate rows
---@field isCollapsed boolean|nil @Whether or not the section shows only its header, for this session like Blizzard's
---@field hasRows boolean|nil @Whether or not the last layout had items to show
---@field shifted boolean|nil @Whether or not a tracker section was moved down to make room for ours
---@field events table|nil @Event frame: places the section again after combat
---@field isQuestieHooked boolean|nil @Whether or not the section follows Questie's tracker frame
---@field isQuestieStyle boolean|nil @Whether or not the last layout used Questie's look
---@field questiePoint table|nil @Where Questie wants its tracker: the arguments of its last SetPoint, count in n
---@field isQuestieMoved boolean|nil @Whether or not the section pushed Questie's tracker down
---@field isMovingQuestie boolean|nil @Whether or not the section is moving Questie's tracker right now
---@field needsRefresh boolean|nil @Whether or not a layout waits for a drag to end
---@field dragItem TodoItem|nil @The item being dragged
---@field dropTarget table|nil @Where the dragged item would land: { todoItem, area }
---@field lastDragTime number|nil @When the last drag ended, so the click that ends a drag doesn't also check or collapse
local ObjectiveTrackerSection = TodoAddon.ObjectiveTrackerSection

-- Blizzard's tracker spacing (ObjectiveTrackerModuleMixin): blocks 20px from the left, 10px between blocks (a folder
-- and its items, or a run of items outside folders), 4px between lines
local BLOCK_OFFSET_X = 20
local BLOCK_SPACING = 10
local LINE_SPACING = 4
-- The header is 26px tall, and rows start 10px below it (see TodoChecklisterTrackerSectionTemplate)
local HEADER_HEIGHT = 26
local CONTENTS_OFFSET = 10
-- The middle half of a folder row drops an item into the folder
local FOLDER_INSIDE_FRACTION = 0.5
-- Tracker replacements the section doesn't support: with one loaded, the section isn't created and the list stays in
-- the window. The same two ElvUI steps aside for (BL:ObjectiveTracker_HasQuestTracker)
local UNSUPPORTED_TRACKERS = {"!KalielsTracker", "DugisGuideViewerZ"}
-- Questie's tracker layout (Modules/Tracker): lines start 10px in (TrackerLine lineMarginLeft) and keep 30px clear on
-- the right (TrackerLayout.MARGIN_RIGHT). Zones are gray, quest titles yellow, objectives near white, and a
-- completed quest says "Quest Complete!" in green (LineBuilder, QuestSection, QuestieLib:GetRGBForObjective)
local QUESTIE_LINE_LEFT = 10
local QUESTIE_MARGIN_RIGHT = 30
local QUESTIE_ZONE_COLOR = {r = 0.753, g = 0.753, b = 0.753}
local QUESTIE_TITLE_COLOR = {r = 1, g = 1, b = 0}
local QUESTIE_OBJECTIVE_COLOR = {r = 0.933, g = 0.933, b = 0.933}
local QUESTIE_COMPLETE_COLOR = {r = 0.157, g = 1, b = 0.157}
-- How often and how long to wait for Questie's tracker frame, which Questie creates some time after login
local QUESTIE_WAIT_INTERVAL = 1
local QUESTIE_WAIT_TRIES = 60

--------------------------------------
-- Tracker detection and styles
--------------------------------------
---
---@return boolean @Whether or not an addon the section doesn't support replaces Blizzard's tracker
local function HasUnsupportedTracker()
	for _, name in ipairs(UNSUPPORTED_TRACKERS) do
		if (C_AddOns.IsAddOnLoaded(name)) then
			return true
		end
	end
	return false
end

---
---@return boolean @Whether or not Questie's tracker is on. Questie then hides Blizzard's tracker and shows
---Questie_BaseFrame where it was (QuestieCompat.HideWatchFrame). Players can turn it on and off while playing
local function IsQuestieTrackerOn()
	local questie = _G.Questie
	return questie ~= nil and questie.db ~= nil and questie.db.profile ~= nil and questie.db.profile.trackerEnabled == true
end

---
---Questie's tracker look, from its settings: fonts (through LibSharedMedia, which Questie loads), sizes, outline,
---indents and padding. The indents come from Questie's own TrackerLayout.GetMargins when it's there, so rows line up
---with its quest titles and objectives even with its focus or voice-over buttons shown
---@return table
local function GetQuestieStyle()
	local profile = _G.Questie.db.profile
	local sharedMedia = LibStub("LibSharedMedia-3.0", true)
	local function Font(name, size)
		local path = sharedMedia and name and sharedMedia:Fetch("font", name, true)
		return {path or STANDARD_TEXT_FONT, size or 10, profile.trackerFontOutline or ""}
	end

	local fontSizeQuest = profile.trackerFontSizeQuest or 10
	-- Questie without focus, voice-over or item buttons: the +/- button column and a 2px gap
	local margins = {quest = fontSizeQuest + 5, objective = fontSizeQuest * 2 + 5}
	local loader = _G.QuestieLoader
	if (loader and loader.ImportModule) then
		local found, layout = pcall(loader.ImportModule, loader, "TrackerLayout")
		if (found and type(layout) == "table" and layout.GetMargins) then
			local measured, questieMargins = pcall(layout.GetMargins)
			if (measured and type(questieMargins) == "table" and questieMargins.quest and questieMargins.objective) then
				margins = questieMargins
			end
		end
	end

	return {
		zone = Font(profile.trackerFontZone, profile.trackerFontSizeZone),
		quest = Font(profile.trackerFontQuest, fontSizeQuest),
		objective = Font(profile.trackerFontObjective, profile.trackerFontSizeObjective),
		questIndent = margins.quest,
		objectiveIndent = margins.objective,
		-- The size of Questie's buttons in front of quest titles
		checkSize = fontSizeQuest + 3,
		-- Space after a quest's last objective
		blockPadding = (profile.trackerQuestPadding or 4) + 2
	}
end

---
---@param todoItem TodoItem
---@param previous TodoItem|nil @The item shown above it
---@return boolean @Whether or not the item starts a block: a folder, or an item outside folders after a folder's items
local function StartsBlock(todoItem, previous)
	local isLoose = not todoItem.isFolder and not todoItem.inFolder
	local previousIsLoose = previous ~= nil and not previous.isFolder and not previous.inFolder
	return todoItem.isFolder == true or (isLoose and not previousIsLoose)
end

--------------------------------------
-- Rows
--------------------------------------
---
---Whether or not a click should be ignored because it ends a drag (it can arrive before or after OnDragStop)
---@return boolean
local function IsDragClick()
	local lastDragTime = ObjectiveTrackerSection.lastDragTime
	return ObjectiveTrackerSection.dragItem ~= nil or (lastDragTime ~= nil and GetTime() - lastDragTime < 0.1)
end

---
---@param region table @A row or its checkbox
local function SetUpDrag(region)
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
---Sets up a new pooled row: clicking an item checks it, clicking a folder opens or closes it, hovering highlights it
---like a tracker line
---@param row table
local function SetUpRow(row)
	if (row.isSetUp) then
		return
	end
	row.isSetUp = true
	row:RegisterForClicks("LeftButtonUp")
	SetUpDrag(row)
	SetUpDrag(row.TodoCheckButton)

	row:SetScript(
		"OnClick",
		function(self)
			if (not self.todoItem or IsDragClick()) then
				return
			end
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			if (self.todoItem.isFolder) then
				TodoChecklisterFrame:ToggleCollapsed(self.todoItem)
			else
				TodoChecklisterFrame:CheckItem(self.todoItem)
			end
		end
	)
	row.TodoCheckButton:SetScript(
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
	row:SetScript(
		"OnEnter",
		function(self)
			local colorStyle = self.colorStyle and self.colorStyle.reverse
			if (colorStyle) then
				self.Text:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)
			end
		end
	)
	row:SetScript(
		"OnLeave",
		function(self)
			local colorStyle = self.colorStyle
			if (colorStyle) then
				self.Text:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)
			end
		end
	)
end

---
---Paints a row. Blizzard's style: a folder like a quest title, an item like an objective, gray once checked.
---Questie's style: a folder like a Questie quest title, an item like a Questie objective, green once checked
---@param row table
---@param todoItem TodoItem
---@param questie table|nil @GetQuestieStyle() for Questie's style, nil for Blizzard's
---@return number @The height of the row's text
local function PaintRow(row, todoItem, questie)
	row.todoItem = todoItem
	row.TodoCheckButton.todoItem = todoItem

	local text = row.Text
	local indent, colorStyle
	if (questie) then
		local font = todoItem.isFolder and questie.quest or questie.objective
		text:SetFont(font[1], font[2], font[3])
		-- Items in a folder sit like objectives under a quest, items outside folders like quest titles
		indent = (todoItem.isFolder or not todoItem.inFolder) and questie.questIndent or questie.objectiveIndent
		row.TodoCheckButton:SetSize(questie.checkSize, questie.checkSize)
		if (todoItem.isFolder) then
			colorStyle = QUESTIE_TITLE_COLOR
		elseif (todoItem.isChecked) then
			colorStyle = QUESTIE_COMPLETE_COLOR
		else
			colorStyle = QUESTIE_OBJECTIVE_COLOR
		end
	else
		text:SetFontObject(ObjectiveTrackerLineFont)
		indent = todoItem.isFolder and 0 or 10
		row.TodoCheckButton:SetSize(16, 16)
		if (todoItem.isFolder) then
			colorStyle = OBJECTIVE_TRACKER_COLOR["Header"]
		elseif (todoItem.isChecked) then
			colorStyle = OBJECTIVE_TRACKER_COLOR["Complete"]
		else
			colorStyle = OBJECTIVE_TRACKER_COLOR["Normal"]
		end
	end

	text:ClearAllPoints()
	text:SetPoint("TOPLEFT", indent, 0)
	text:SetPoint("RIGHT")
	row.TodoCheckButton:SetShown(not todoItem.isFolder)
	row.TodoCheckButton:SetChecked(todoItem.isChecked == true)
	-- Blizzard's colors carry a highlight color for hovering (reverse). Questie's don't change on hover
	row.colorStyle = colorStyle
	text:SetTextColor(colorStyle.r, colorStyle.g, colorStyle.b)

	text:SetText(TodoChecklisterFrame:GetDisplayText(todoItem))
	return math.max(text:GetStringHeight(), 1)
end

--------------------------------------
-- Layout and placement
--------------------------------------
---
---Rebuilds the section from the visible items: a folder starts a block with its items as lines below it, and a run of
---items outside folders shares a block, the way a tracker groups a quest and its objectives.
---Next to Questie's tracker it takes Questie's look and width, with the list name as a Questie zone line; otherwise
---Blizzard's, with Blizzard's section header
function ObjectiveTrackerSection:Layout()
	local section = self.section
	self.rowPool:ReleaseAll()

	local items = TodoList:GetVisibleItems()
	self.hasRows = Settings:DisplayInObjectiveTracker() and #items > 0
	if (not self.hasRows) then
		-- Hides the section and gives Blizzard's sections or Questie's tracker their place back
		self:UpdatePlacement()
		return
	end

	local questieFrame = IsQuestieTrackerOn() and self:GetQuestieFrame()
	local questie = questieFrame and GetQuestieStyle() or nil
	self.isQuestieStyle = questie ~= nil
	local listName = TodoList:GetSelectedListName()
	local contents = section.Contents
	contents:ClearAllPoints()

	local height, rowLeft, rowRight
	if (questie) then
		section:SetWidth(questieFrame:GetWidth())
		self.header:Hide()
		local zoneLine = section.QuestieHeader
		zoneLine.Text:SetFont(questie.zone[1], questie.zone[2], questie.zone[3])
		zoneLine.Text:SetTextColor(QUESTIE_ZONE_COLOR.r, QUESTIE_ZONE_COLOR.g, QUESTIE_ZONE_COLOR.b)
		zoneLine.Text:SetText(listName)
		zoneLine:ClearAllPoints()
		zoneLine:SetPoint("TOPLEFT", QUESTIE_LINE_LEFT, 0)
		zoneLine:SetPoint("RIGHT", -QUESTIE_MARGIN_RIGHT, 0)
		-- Questie adds 4px between a zone line and the first title
		local zoneHeight = zoneLine.Text:GetStringHeight() + 4
		zoneLine:SetHeight(zoneHeight)
		zoneLine:Show()
		contents:SetPoint("TOPLEFT", 0, -zoneHeight)
		height = zoneHeight
		rowLeft, rowRight = QUESTIE_LINE_LEFT, -QUESTIE_MARGIN_RIGHT
	else
		section:SetWidth(ObjectiveTrackerFrame:GetWidth())
		section.QuestieHeader:Hide()
		self.header:Show()
		self.header.Text:SetText(listName)
		contents:SetPoint("TOPLEFT", 0, -(HEADER_HEIGHT + CONTENTS_OFFSET))
		height = HEADER_HEIGHT + CONTENTS_OFFSET
		rowLeft, rowRight = BLOCK_OFFSET_X, 0
	end
	contents:SetPoint("BOTTOMRIGHT")

	-- Questie's zone line has no minimize button, so the section never collapses there
	local isCollapsed = self.isCollapsed and not questie
	if (isCollapsed) then
		height = HEADER_HEIGHT
	else
		local y = 0
		for index, todoItem in ipairs(items) do
			if (not questie and index > 1) then
				y = y + (StartsBlock(todoItem, items[index - 1]) and BLOCK_SPACING or LINE_SPACING)
			end

			local row = self.rowPool:Acquire()
			SetUpRow(row)
			row:SetPoint("TOPLEFT", contents, "TOPLEFT", rowLeft, -y)
			row:SetPoint("RIGHT", contents, "RIGHT", rowRight, 0)
			local rowHeight = PaintRow(row, todoItem, questie)
			row:SetHeight(rowHeight)
			row:Show()
			y = y + rowHeight

			if (questie) then
				-- Questie's spacing: 4px under a title, 1px between objectives, and its quest padding after the
				-- last objective of a quest
				local nextItem = items[index + 1]
				if (todoItem.isFolder) then
					y = y + 4
				elseif (not nextItem or StartsBlock(nextItem, todoItem)) then
					y = y + questie.blockPadding
				else
					y = y + 1
				end
			end
		end
		height = height + y
	end
	contents:SetShown(not isCollapsed)
	section:SetHeight(height)

	self:UpdatePlacement()
end

---
---@return table|nil @Questie's tracker frame once Questie created it. Hooked the first time: the section follows it
function ObjectiveTrackerSection:GetQuestieFrame()
	local frame = _G.Questie_BaseFrame
	if (frame and not self.isQuestieHooked) then
		self.isQuestieHooked = true
		local function UpdatePlacement()
			self:UpdatePlacement()
		end
		frame:HookScript("OnShow", UpdatePlacement)
		frame:HookScript("OnHide", UpdatePlacement)
		-- Questie sets its point when it loads and after the player drags it: remember where Questie wants its tracker,
		-- then place the section there and push the tracker down. Our own push isn't Questie's choice
		hooksecurefunc(
			frame,
			"SetPoint",
			function(_, ...)
				if (self.isMovingQuestie) then
					return
				end
				self.questiePoint = {n = select("#", ...), ...}
				self.isQuestieMoved = nil
				self:UpdatePlacement()
			end
		)
		-- The section takes Questie's width, which follows its content and the player's resizing
		frame:HookScript(
			"OnSizeChanged",
			function()
				self:Refresh()
			end
		)
	end
	return frame
end

---
---Where the section goes, from what Blizzard's tracker shows:
---"inside" the tracker, before its campaign and quest sections; "questie" above Questie's tracker when it's on;
---"top" in the tracker's place when nothing else is there; or nil to hide.
---It only takes the tracker's place when no other tracker can be there. A tracker hidden while its sections still
---have content means an addon we don't know replaced it, so the section hides instead of overlapping that addon
---@return "inside"|"questie"|"top"|nil
function ObjectiveTrackerSection:GetPlacement()
	local tracker = ObjectiveTrackerFrame
	if (IsQuestieTrackerOn()) then
		local questieFrame = self:GetQuestieFrame()
		if (not questieFrame) then
			-- Questie hasn't made it yet: it will appear where Blizzard's tracker is
			return nil
		end
		-- Questie hides its frame when it has nothing to show. Its spot is free then
		return questieFrame:IsShown() and "questie" or "top"
	end

	if (tracker:IsShown()) then
		-- A hidden parent or a faded tracker: hide with it. Collapsed "All Objectives": hide like its sections
		if (not tracker:IsVisible() or tracker:GetEffectiveAlpha() < 0.05) then
			return nil
		end
		if (tracker.IsCollapsed and tracker:IsCollapsed()) then
			return nil
		end
		-- Its background shows whenever one of its sections does
		return tracker.NineSlice:IsShown() and "inside" or "top"
	end

	for _, module in ipairs(tracker.modules or {}) do
		if (module:GetContentsHeight() > 0) then
			return nil
		end
	end
	return "top"
end

---
---The tracker sections around ours: the last one shown before the campaign and quest sections (scenarios and widgets
---stay on top), and the first one shown from there on, which moves down to make room
---@return table|nil, table|nil @The section before ours, and the section after ours
function ObjectiveTrackerSection:GetNeighbors()
	local tracker = ObjectiveTrackerFrame
	local campaign, quests = CampaignQuestObjectiveTracker, QuestObjectiveTracker
	local insertOrder = (campaign and campaign.uiOrder) or (quests and quests.uiOrder) or 3
	local previous
	-- Blizzard keeps tracker.modules sorted by uiOrder, and anchors the ones with content in that order
	for _, module in ipairs(tracker.modules or {}) do
		if (module:GetContentsHeight() > 0) then
			if ((module.uiOrder or 0) >= insertOrder) then
				return previous, module
			end
			previous = module
		end
	end
	return previous, nil
end

---
---Moves the tracker section after ours down by `extra`, or back with 0. Blizzard anchors the first section it shows to
---its top and every other one to the section before it, so the rest of the tracker and its background follow. The
---offset is a number, the way Blizzard sets it: Blizzard's frames never anchor to ours, and anchors are no Lua state
---that could carry taint. Blizzard sets the anchor again on every layout, and the NineSlice hook moves it again
---@param after table|nil @The section after ours
---@param before table|nil @The section before ours
---@param extra number @How far to move it down
function ObjectiveTrackerSection:ShiftSection(after, before, extra)
	if (not after) then
		return
	end
	-- Anchors of protected frames can't change in combat. Wait for it to end
	if (InCombatLockdown() and after:IsProtected()) then
		self.events:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	local tracker = ObjectiveTrackerFrame
	if (before) then
		after:SetPoint("TOP", before, "BOTTOM", 0, -tracker.moduleSpacing - extra)
	else
		after:SetPoint("TOP", tracker, "TOP", 0, -tracker.topModulePadding - extra)
	end
	self.shifted = extra > 0
end

---
---Follows the tracker: places the section before its campaign and quest sections (moving them down) or in its place,
---and hides it when the tracker can't be seen
function ObjectiveTrackerSection:UpdatePlacement()
	local section = self.section
	-- Questie's tracker was turned on or off, or appeared: lay out again in the other style (Layout places it)
	local wantsQuestieStyle = self.hasRows and IsQuestieTrackerOn() and _G.Questie_BaseFrame ~= nil
	if (self.hasRows and wantsQuestieStyle ~= (self.isQuestieStyle == true)) then
		self:Layout()
		return
	end
	local tracker = ObjectiveTrackerFrame
	local placement = self.hasRows and self:GetPlacement()
	local before, after = self:GetNeighbors()

	if (placement ~= "questie") then
		self:RestoreQuestie()
	end

	if (placement ~= "inside") then
		-- Give Blizzard's sections their place back
		if (self.shifted) then
			self:ShiftSection(after, before, 0)
		end
		if (not placement) then
			section:Hide()
			return
		end
		section:ClearAllPoints()
		if (placement == "questie") then
			self:PlaceAboveQuestie()
			return
		else
			section:SetPoint("TOPLEFT", tracker, "TOPLEFT")
		end
		section:Show()
		return
	end

	section:ClearAllPoints()
	if (before) then
		section:SetPoint("TOP", before, "BOTTOM", 0, -tracker.moduleSpacing)
		section:SetPoint("LEFT", tracker, "LEFT")
	else
		section:SetPoint("TOPLEFT", tracker, "TOPLEFT", 0, -tracker.topModulePadding)
	end
	section:Show()
	self:ShiftSection(after, before, section:GetHeight() + tracker.moduleSpacing)
end

---
---@return table @Where Questie wants its tracker: the arguments of its last SetPoint, or its current point when it set
---it before the hook existed
function ObjectiveTrackerSection:GetQuestiePoint()
	if (not self.questiePoint) then
		local frame = _G.Questie_BaseFrame
		self.questiePoint = {n = 5, frame:GetPoint(1)}
	end
	return self.questiePoint
end

---
---Moves Questie's tracker without taking it for Questie's own choice (see GetQuestieFrame)
---@param point table @SetPoint arguments, with their count in n
---@param offsetY number @How far to move it down from that point
function ObjectiveTrackerSection:MoveQuestie(point, offsetY)
	local frame = _G.Questie_BaseFrame
	local anchorPoint, relativeTo, relativePoint, x, y = unpack(point, 1, point.n)
	self.isMovingQuestie = true
	frame:ClearAllPoints()
	if (type(relativeTo) == "number" or relativeTo == nil) then
		-- SetPoint(point, x, y): relative to its parent
		frame:SetPoint(anchorPoint, relativeTo or 0, (relativePoint or 0) - offsetY)
	else
		frame:SetPoint(anchorPoint, relativeTo, relativePoint or anchorPoint, x or 0, (y or 0) - offsetY)
	end
	self.isMovingQuestie = nil
end

---
---Above Questie's tracker. When Questie anchors it by a top corner (it grows down), the section takes the spot Questie
---wants and pushes the tracker down by the section's height, so it never overlaps what is above (the minimap by
---default). When anchored by a bottom corner (it grows up), the section just sits on top of it.
---Questie saves its position only when the player drops it, from where it was dropped, so the push never ends up in
---Questie's settings
function ObjectiveTrackerSection:PlaceAboveQuestie()
	local section = self.section
	local frame = _G.Questie_BaseFrame
	local point = self:GetQuestiePoint()
	local anchorPoint = point[1]
	section:ClearAllPoints()

	if (type(anchorPoint) ~= "string" or anchorPoint:find("BOTTOM")) then
		self:RestoreQuestie()
		section:SetPoint("BOTTOMLEFT", frame, "TOPLEFT")
		section:Show()
		return
	end

	-- Our top-left corner where Questie wants its own, then Questie's tracker right below us
	section:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, section:GetHeight())
	self:MoveQuestie(point, section:GetHeight())
	self.isQuestieMoved = true
	section:Show()
end

---
---Puts Questie's tracker back where Questie wants it, after the section pushed it down
function ObjectiveTrackerSection:RestoreQuestie()
	if (not self.isQuestieMoved or not _G.Questie_BaseFrame or not self.questiePoint) then
		return
	end
	self.isQuestieMoved = nil
	self:MoveQuestie(self.questiePoint, 0)
end

---
---Opens or closes the section, from the header's minimize button
function ObjectiveTrackerSection:ToggleCollapsed()
	self.isCollapsed = not self.isCollapsed
	self.header:SetCollapsed(self.isCollapsed)
	self:Layout()
end

--------------------------------------
-- Drag and drop
--------------------------------------
---
---@param todoItem TodoItem|nil @The item being dragged
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
	cursorRow:SetWidth(self.section:GetWidth())
	self.dropIndicator:Show()
	cursorRow:Show()
	self:UpdateDrag()
end

---
---Runs every frame during a drag: moves the clone to the cursor and updates the drop indicator.
---The drag also ends here when the button is up: the game sends no OnDragStop when the dragged row is hidden
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
	for row in self.rowPool:EnumerateActive() do
		if (row.todoItem ~= dragItem and row:IsVisible() and row:IsMouseOver()) then
			local scale = row:GetEffectiveScale()
			local top, bottom = row:GetTop() * scale, row:GetBottom() * scale
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
					box:SetPoint("TOPLEFT", row, "TOPLEFT", -4, 3)
					box:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, -3)
					box:Show()
				else
					local point, relativePoint, offsetY = "BOTTOM", "TOP", 1
					if (area == DragIntersectionArea.Below) then
						point, relativePoint, offsetY = "TOP", "BOTTOM", -1
					end
					line:ClearAllPoints()
					line:SetPoint(point .. "LEFT", row, relativePoint .. "LEFT", 0, offsetY)
					line:SetPoint(point .. "RIGHT", row, relativePoint .. "RIGHT", 0, offsetY)
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

	if (dropTarget) then
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
---@return boolean @Whether or not the section exists: retail and Forever, without an unsupported tracker replacement
function ObjectiveTrackerSection:IsAvailable()
	return self.section ~= nil
end

---
---Lays the section out again after the list changed
function ObjectiveTrackerSection:Refresh()
	if (not self.section) then
		return
	end
	-- Laying out during a drag would recycle the dragged row. Wait for the drop instead
	if (self.dragItem) then
		self.needsRefresh = true
		return
	end
	self.needsRefresh = nil
	self:Layout()
end

---
---Load required configuration for this class
function ObjectiveTrackerSection:LoadCFG()
	self:Refresh()
end

---
---Gives our header ElvUI's look when ElvUI skins the tracker, so it matches the sections around it.
---A copy of ElvUI's SkinOjectiveTrackerHeaders (Skins/ObjectiveTracker.lua), on our own header
function ObjectiveTrackerSection:ApplyElvUISkin()
	local elvUI = _G.ElvUI
	local E = elvUI and elvUI[1]
	local skins = E and E.private and E.private.skins
	if (not (skins and skins.blizzard and skins.blizzard.enable and skins.blizzard.objectiveTracker)) then
		return
	end
	local textures = E.Media and E.Media.Textures
	if (not textures) then
		return
	end

	local header = self.header
	header.Background:SetAtlas(nil)
	header.MinimizeButton:SetSize(15, 15)
	header.MinimizeButton:SetHighlightAtlas("UI-QuestTrackerButton-Red-Highlight", "ADD")
	local function SetCollapsed(_, collapsed)
		local texture = collapsed and textures.PlusButton or textures.MinusButton
		header.MinimizeButton:GetNormalTexture():SetTexture(texture)
		header.MinimizeButton:GetPushedTexture():SetTexture(texture)
	end
	SetCollapsed(header, self.isCollapsed)
	hooksecurefunc(header, "SetCollapsed", SetCollapsed)
end

---
---Initializes required properties for this class. Waits for login: every addon has loaded by then, so it can tell
---which tracker the player uses
function ObjectiveTrackerSection:Init()
	-- The Classic clients have the older quest watch frames instead
	if (not ObjectiveTrackerFrame or not ObjectiveTrackerFrame.NineSlice) then
		return
	end
	local loginFrame = CreateFrame("Frame")
	loginFrame:RegisterEvent("PLAYER_LOGIN")
	loginFrame:SetScript(
		"OnEvent",
		function(frame)
			frame:UnregisterEvent("PLAYER_LOGIN")
			-- One more frame: ElvUI sets up its settings on login too
			C_Timer.After(
				0,
				function()
					self:Setup()
				end
			)
		end
	)
end

---
---Creates the section for the player's tracker: Blizzard's (ElvUI keeps it and skins it) or Questie's. With a tracker
---replacement the section doesn't support, it creates nothing and the list stays in the window
function ObjectiveTrackerSection:Setup()
	if (HasUnsupportedTracker()) then
		return
	end

	local section = CreateFrame("Frame", addonName .. "ObjectiveTracker", UIParent, "TodoChecklisterTrackerSectionTemplate")
	self.section = section
	-- Anchored from the start, even while hidden, so rows can measure wrapped text before the first placement
	section:SetPoint("TOPLEFT", ObjectiveTrackerFrame, "TOPLEFT")
	self.rowPool = CreateFramePool("Button", section.Contents, "TodoChecklisterTrackerLineTemplate")

	-- Blizzard's section header ("Quests"), owned by our section. Its minimize button calls its parent's
	-- ToggleCollapsed, and clicking the title opens or closes the window
	self.header = CreateFrame("Frame", nil, section, "ObjectiveTrackerModuleHeaderTemplate")
	self.header:SetPoint("TOPLEFT")
	section.ToggleCollapsed = function()
		self:ToggleCollapsed()
	end
	self.header:EnableMouse(true)
	self.header:SetScript(
		"OnMouseUp",
		function(_, button)
			if (button == "LeftButton") then
				TodoChecklisterFrame:Toggle()
			end
		end
	)

	-- Shown only while dragging, like the clone below, so nothing runs every frame while idle
	self.dropIndicator = CreateFrame("Frame", nil, section)
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

	self.events = CreateFrame("Frame")
	self.events:SetScript(
		"OnEvent",
		function(events)
			events:UnregisterEvent("PLAYER_REGEN_ENABLED")
			self:UpdatePlacement()
		end
	)

	-- Follow the tracker with post-hooks only, which keep Blizzard's code secure (Questie hooks it the same way):
	-- it moves its background after every layout, shows and hides itself, collapses, and other addons hide, fade or
	-- reparent it
	local tracker = ObjectiveTrackerFrame
	local function UpdatePlacement()
		self:UpdatePlacement()
	end
	hooksecurefunc(tracker.NineSlice, "SetPoint", UpdatePlacement)
	hooksecurefunc(tracker, "SetAlpha", UpdatePlacement)
	hooksecurefunc(tracker, "SetParent", UpdatePlacement)
	if (tracker.SetCollapsed) then
		hooksecurefunc(tracker, "SetCollapsed", UpdatePlacement)
	end
	tracker:HookScript("OnShow", UpdatePlacement)
	tracker:HookScript("OnHide", UpdatePlacement)
	-- The tracker's width follows Edit Mode
	tracker:HookScript(
		"OnSizeChanged",
		function()
			self:Refresh()
		end
	)

	self:ApplyElvUISkin()

	-- Questie loads its settings and creates its tracker frame some time after login, so at this point it may not
	-- say yet whether its tracker is on. Check again until the frame exists, Questie says its tracker is off, or a
	-- minute passed, then place the section. Installing or removing Questie takes a reload, which runs this again
	if (C_AddOns.IsAddOnLoaded("Questie") and not _G.Questie_BaseFrame) then
		local tries = 0
		local ticker
		ticker =
			C_Timer.NewTicker(
			QUESTIE_WAIT_INTERVAL,
			function()
				tries = tries + 1
				local questie = _G.Questie
				local isTrackerOff = questie and questie.db and questie.db.profile and not questie.db.profile.trackerEnabled
				if (_G.Questie_BaseFrame or isTrackerOff or tries >= QUESTIE_WAIT_TRIES) then
					ticker:Cancel()
					self:UpdatePlacement()
				end
			end
		)
	end

	self:LoadCFG()
end
