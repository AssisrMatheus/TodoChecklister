--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

---@class TableUtils
local TableUtils = TodoAddon.TableUtils

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.TodoList = {}

---@class TodoList
local TodoList = TodoAddon.TodoList

---@class TodoItem
---@field public id string @A concatenated string used as an id
---@field public text string @The text content of an item
---@field public isChecked boolean @Whether or not this item is done. Always false on folders
---@field public isFolder boolean|nil @A folder groups the items right after it. It cannot be checked
---@field public isCollapsed boolean|nil @Whether or not this folder hides its items
---@field public inFolder boolean|nil @This item belongs to the closest folder above it. Folders cannot nest

---
---Account-wide SavedVariable: every list, keyed by its name. Lists are shared by all characters
---@class TodoListsDB
---@field public lists table<string, TodoItem[]>

---
---Per-character SavedVariable
---@class TodoCharacterDB
---@field public selectedList string|nil @Name of the list this character is viewing

--------------------------------------
-- TodoList functions
--------------------------------------
---
---Appends a new TodoItem to the list, outside of any folder
---@param text string @New element to be appended to the list
---@param isFolder boolean|nil @Whether or not the new element is a folder
function TodoList:AddItem(text, isFolder)
	-- If text is not empty
	if (text and text ~= nil and text ~= "") then
		local items = self:GetItems()
		-- Adds one at the end of array
		table.insert(items, #items + 1, {text = text, isChecked = false, id = text .. (#items + 1), isFolder = isFolder or nil})
	end
end

---
---Removes an element from a given position, moving down other elements to close space and decrementing the size of the array.
---Removing a folder keeps its items, outside of any folder
---@param indexToRemove number @The ONE-based location in the array to remove.
function TodoList:RemoveItem(indexToRemove)
	local items = self:GetItems()
	if (indexToRemove > 0 and items[indexToRemove]) then
		local _, last = self:GetBlockRange(indexToRemove)
		for i = indexToRemove + 1, last do
			items[i].inFolder = nil
		end
		table.remove(items, indexToRemove)
		return true
	end
	return false
end

---
---Assign updatedItem values to the item in the given indexToUpdate position.
---The item keeps its table, so references to it (rows, selection) stay valid
---@param indexToUpdate number @The ONE-based location in the array to remove.
---@param updatedItem table @Fields to overwrite
function TodoList:UpdateItem(indexToUpdate, updatedItem)
	local items = self:GetItems()
	-- If the item exists on the list
	if (indexToUpdate > 0 and items[indexToUpdate] and updatedItem) then
		TableUtils:Assign(items[indexToUpdate], updatedItem)
		return true
	end
	return false
end

---
---Return every item of the selected list
---@return TodoItem[] @The saved list of items
function TodoList:GetItems()
	return TodoChecklisterDB.lists[self:GetSelectedListName()]
end

--------------------------------------
-- Folder functions
--------------------------------------
-- The list stays a flat array, so lists saved before folders existed load unchanged.
-- A folder owns the run of `inFolder` items right after it, and the run ends at the first item without it

---
---@param index number @The ONE-based location of an item
---@return number, number @First and last index of the block that moves with this item: a folder and its items, or the item alone
function TodoList:GetBlockRange(index)
	local items = self:GetItems()
	local last = index
	if (items[index] and items[index].isFolder) then
		while (items[last + 1] and items[last + 1].inFolder) do
			last = last + 1
		end
	end
	return index, last
end

---
---@param index number @The ONE-based location of an item
---@return number|nil @The index of the folder holding this item, nil when it is not in a folder
function TodoList:GetFolderIndex(index)
	local items = self:GetItems()
	if (not items[index] or not items[index].inFolder) then
		return nil
	end
	local folderIndex = index - 1
	while (folderIndex > 0 and items[folderIndex].inFolder) do
		folderIndex = folderIndex - 1
	end
	return folderIndex
end

---
---@return TodoItem[] @The items the window displays: every item except the ones inside collapsed folders
function TodoList:GetVisibleItems()
	local visible = {}
	local hidden = false
	for _, item in ipairs(self:GetItems()) do
		if (item.isFolder) then
			hidden = item.isCollapsed == true
		elseif (not item.inFolder) then
			hidden = false
		end
		if (not (item.inFolder and hidden)) then
			table.insert(visible, item)
		end
	end
	return visible
end

---
---@param index number @The ONE-based location of a folder
---@return number, number @How many of its items are checked, and how many it has
function TodoList:GetFolderProgress(index)
	local items = self:GetItems()
	local _, last = self:GetBlockRange(index)
	local checked = 0
	for i = index + 1, last do
		if (items[i].isChecked) then
			checked = checked + 1
		end
	end
	return checked, last - index
end

---
---Turns an item into a folder, or a folder back into an item. Items inside a folder cannot become folders.
---A folder that becomes an item lets go of its items
---@param index number @The ONE-based location of the item
---@return boolean @Whether or not the item changed
function TodoList:ToggleFolder(index)
	local items = self:GetItems()
	local item = items[index]
	if (not item or item.inFolder) then
		return false
	end

	if (item.isFolder) then
		local _, last = self:GetBlockRange(index)
		for i = index + 1, last do
			items[i].inFolder = nil
		end
		item.isFolder = nil
		item.isCollapsed = nil
	else
		item.isFolder = true
		item.isChecked = false
	end
	return true
end

---
---Opens or closes a folder
---@param index number @The ONE-based location of the folder
function TodoList:ToggleCollapsed(index)
	local item = self:GetItems()[index]
	if (item and item.isFolder) then
		item.isCollapsed = (not item.isCollapsed) or nil
	end
end

---
---Works out where an item lands when dropped next to (or onto) another one.
---A folder moves with its items and only lands between blocks; an item lands in a folder when dropped onto the folder,
---between its items, right below an open folder, or above its first item
---@param fromIndex number @The ONE-based location of the item being moved
---@param targetIndex number @The ONE-based location of the item it is dropped on
---@param area "above"|"below"|"inside" @Where it is dropped relative to the target
---@return number|nil, boolean|nil @Index (before the move) the block is inserted at, and whether the item ends in a folder. nil when not allowed
function TodoList:ResolveMove(fromIndex, targetIndex, area)
	local items = self:GetItems()
	local source, target = items[fromIndex], items[targetIndex]
	local first, last = self:GetBlockRange(fromIndex)
	if (not source or not target or (targetIndex >= first and targetIndex <= last)) then
		return nil
	end
	local _, targetLast = self:GetBlockRange(targetIndex)

	if (source.isFolder) then
		-- Folders cannot nest, so they only land before or after another block
		if (area == "above" and not target.inFolder) then
			return targetIndex, false
		elseif (area == "below" and (not target.isFolder or target.isCollapsed or targetLast == targetIndex)) then
			-- Below a lone item, a closed or empty folder, or the last item of a folder
			if (not target.inFolder or targetLast + 1 > #items or not items[targetLast + 1].inFolder) then
				return targetLast + 1, false
			end
		end
		return nil
	end

	if (area == "inside") then
		if (not target.isFolder) then
			return nil
		end
		return targetLast + 1, true
	elseif (area == "above") then
		return targetIndex, target.inFolder == true
	elseif (target.isFolder and not target.isCollapsed) then
		-- Below an open folder: its first item
		return targetIndex + 1, true
	end

	-- Below an item, or after a closed folder. It stays in a folder unless dropped below the folder's last item
	local nextIndex = targetLast + 1
	if (nextIndex == first) then
		nextIndex = last + 1
	end
	return targetLast + 1, (target.inFolder == true and items[nextIndex] ~= nil and items[nextIndex].inFolder == true)
end

---
---Moves an item (a folder moves with its items) next to or into another one. See ResolveMove
---@param fromIndex number @The ONE-based location of the item being moved
---@param targetIndex number @The ONE-based location of the item it is dropped on
---@param area "above"|"below"|"inside" @Where it is dropped relative to the target
---@return boolean @Whether or not the item moved
function TodoList:MoveRelative(fromIndex, targetIndex, area)
	local insertIndex, inFolder = self:ResolveMove(fromIndex, targetIndex, area)
	if (not insertIndex) then
		return false
	end

	local items = self:GetItems()
	local first, last = self:GetBlockRange(fromIndex)
	local block = {}
	for i = last, first, -1 do
		table.insert(block, 1, table.remove(items, i))
	end
	if (insertIndex > last) then
		insertIndex = insertIndex - #block
	end
	for i, item in ipairs(block) do
		table.insert(items, insertIndex + i - 1, item)
	end
	if (not block[1].isFolder) then
		block[1].inFolder = inFolder or nil
	end
	return true
end

---
---Moves an item so it ends up at toIndex, or as close as folders allow
---@param fromIndex number @The ONE-based location in the array to move from.
---@param toIndex number @The ONE-based location in the array to move to.
---@return boolean @Whether or not the item moved
function TodoList:Move(fromIndex, toIndex)
	if (fromIndex == toIndex) then
		return false
	end
	return self:MoveRelative(fromIndex, toIndex, fromIndex < toIndex and "below" or "above")
end

---
---Repairs folder fields that can't be right: an item marked as in a folder with no folder above it,
---or a folder marked as in a folder. Older versions of the addon can reorder a list and leave these behind
---@param items TodoItem[] @A saved list
function TodoList:RepairFolders(items)
	local inFolderAllowed = false
	for _, item in ipairs(items) do
		if (item.isFolder) then
			item.inFolder = nil
			item.isChecked = false
			inFolderAllowed = true
		elseif (not item.inFolder) then
			inFolderAllowed = false
		elseif (not inFolderAllowed) then
			item.inFolder = nil
		end
	end
end

---
---Finds the index of a given item in the saved list
---@param todoItem TodoItem @The item to be used to find its index
---@return number @The index of such item
function TodoList:GetIndexByItem(todoItem)
	local index = TableUtils:FindIndex(
		self:GetItems(),
		function(x)
			return x == todoItem
		end
	)
	if (index > 0) then
		return index
	elseif (todoItem and todoItem.id) then
		return self:GetIndexById(todoItem.id)
	elseif (todoItem) then
		return self:GetIndexByText(todoItem.text)
	else
		return 0
	end
end

---
---Finds the index of a given item in the saved list by its text field
---@param text string @The text value used to search in the list
---@return number @The index of such item
function TodoList:GetIndexByText(text)
	return TableUtils:FindIndex(
		self:GetItems(),
		function(x)
			return x.text == text
		end
	)
end

---
---Finds the index of a given item in the saved list by its id field
---@param text string @The id value used to search in the list
---@return number @The index of such item
function TodoList:GetIndexById(id)
	return TableUtils:FindIndex(
		self:GetItems(),
		function(x)
			return x.id == id
		end
	)
end

--------------------------------------
-- Lists functions
--------------------------------------
---
---@return string @The name of the list a character gets when it has not picked one
function TodoList:GetDefaultListName()
	-- WoW: Forever characters have a surname, which its NameUtil adds to the name.
	-- Retail has no NameUtil, and no surnames
	local name = NameUtil and NameUtil.GetUnmodifiedUnitFullName("player") or UnitName("player")
	return name .. "'s List"
end

---
---@return string @The name of the list this character is viewing
function TodoList:GetSelectedListName()
	return TodoChecklisterCharacterDB.selectedList
end

---
---@return string[] @The names of every saved list, sorted alphabetically
function TodoList:GetListNames()
	local names = {}
	for name in pairs(TodoChecklisterDB.lists) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

---
---@param name string @The name of the list to check
---@return boolean @Whether or not a list with this name exists
function TodoList:HasList(name)
	return TodoChecklisterDB.lists[name] ~= nil
end

---
---Creates a new empty list
---@param name string @The name of the new list
---@return boolean @Whether or not the list was created. False when the name is empty or already taken
function TodoList:CreateList(name)
	if (not name or name == "" or self:HasList(name)) then
		return false
	end
	TodoChecklisterDB.lists[name] = {}
	return true
end

---
---@param name string @The name a new list wants
---@return string @That name, or with a number added when it is taken: "Raid (2)", "Raid (3)"...
function TodoList:GetUniqueListName(name)
	local uniqueName = name
	local copy = 2
	while (self:HasList(uniqueName)) do
		uniqueName = name .. " (" .. copy .. ")"
		copy = copy + 1
	end
	return uniqueName
end

---
---Saves a list someone shared, without touching any existing list.
---When the name is taken, it gets a number: "Raid (2)", "Raid (3)"...
---@param name string @The name it was shared with
---@param items TodoItem[] @Its items. Their ids are replaced
---@return string @The name it was saved under
function TodoList:ImportList(name, items)
	name = strtrim(name or "")
	if (name == "") then
		name = "Imported list"
	end
	local uniqueName = self:GetUniqueListName(name)

	for index, item in ipairs(items) do
		item.id = item.text .. index
	end
	self:RepairFolders(items)
	TodoChecklisterDB.lists[uniqueName] = items
	return uniqueName
end

---
---Makes this character view the given list
---@param name string @The name of an existing list
function TodoList:SelectList(name)
	if (self:HasList(name)) then
		TodoChecklisterCharacterDB.selectedList = name
	end
end

---
---Deletes a list and all its items. A character viewing it falls back to its default list
---@param name string @The name of the list to delete
function TodoList:DeleteList(name)
	TodoChecklisterDB.lists[name] = nil
	self:EnsureSelectedList()

	for _, items in pairs(TodoChecklisterDB.lists) do
		self:RepairFolders(items)
	end
end

---
---Makes sure this character views an existing list.
---When it has not picked one, or the picked one was deleted, it views (and creates) its default list
function TodoList:EnsureSelectedList()
	if (not self:HasList(self:GetSelectedListName())) then
		local name = self:GetDefaultListName()
		self:CreateList(name)
		TodoChecklisterCharacterDB.selectedList = name
	end
end

---
---Gets the message of the day value based on available items the user currently has
---@return string @MOTD value
function TodoList:GetMOTD()
	local items =
		TableUtils:Filter(
		self:GetItems(),
		function(x)
			return not x.isFolder
		end
	)
	if (#items > 0) then
		local completedList =
			TableUtils:Filter(
			items,
			function(x)
				return x.isChecked == true
			end
		)
		local notList =
			TableUtils:Filter(
			items,
			function(x)
				return x.isChecked == false
			end
		)

		if (#completedList > 0 and #notList > 0) then
			local completedTaskPlural = ""
			if (#completedList > 1) then
				completedTaskPlural = "tasks"
			else
				completedTaskPlural = "task"
			end

			local notTaskPlural = ""
			if (#notList > 1) then
				notTaskPlural = "tasks"
			else
				notTaskPlural = "task"
			end

			return "You have |cff6cf900" ..
				tostring(#completedList) ..
					"|r completed " .. completedTaskPlural .. " and |cffff0000" .. tostring(#notList) .. "|r pending " .. notTaskPlural
		elseif (#completedList > 0) then
			return "You have completed all your tasks"
		elseif (#notList > 0) then
			local taskPlural = ""
			if (#notList > 1) then
				taskPlural = "tasks"
			else
				taskPlural = "task"
			end
			return "You have |cffff0000" .. tostring(#notList) .. "|r pending " .. taskPlural
		end
	else
		return "You have no pending tasks."
	end
end

--------------------------------------
-- Lifecycle Events
--------------------------------------
---
---Initializes required properties for this class
function TodoList:Init()
	-- Older versions saved a single flat array of items. It becomes the list of the first character that loads
	if (type(TodoChecklisterDB) ~= "table" or not TodoChecklisterDB.lists) then
		local oldItems = TodoChecklisterDB or {}
		---@type TodoListsDB
		TodoChecklisterDB = {lists = {}}
		if (#oldItems > 0) then
			TodoChecklisterDB.lists[self:GetDefaultListName()] = oldItems
		end
	end

	if (type(TodoChecklisterCharacterDB) ~= "table") then
		---@type TodoCharacterDB
		TodoChecklisterCharacterDB = {}
	end

	self:EnsureSelectedList()

	for _, items in pairs(TodoChecklisterDB.lists) do
		self:RepairFolders(items)
	end
end
