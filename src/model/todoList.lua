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
---@field public isChecked boolean @Whether or not this item is done

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
---Appends a new TodoItem to the list
---@param text string @New element to be appended to the list
function TodoList:AddItem(text)
	-- If text is not empty
	if (text and text ~= nil and text ~= "") then
		local items = self:GetItems()
		-- Adds one at the end of array
		table.insert(items, #items + 1, {text = text, isChecked = false, id = text .. (#items + 1)})
	end
end

---
---Removes an element from a given position, moving down other elements to close space and decrementing the size of the array
---@param indexToRemove number @The ONE-based location in the array to remove.
function TodoList:RemoveItem(indexToRemove)
	local items = self:GetItems()
	if (indexToRemove > 0 and items[indexToRemove]) then
		table.remove(items, indexToRemove)
		return true
	end
	return false
end

---
---Assign updatedItem values to the item in the given indexToUpdate position.
---@param indexToUpdate number @The ONE-based location in the array to remove.
---@param updatedItem TodoItem @Source object
function TodoList:UpdateItem(indexToUpdate, updatedItem)
	local items = self:GetItems()
	-- If the item exists on the list
	if (indexToUpdate > 0 and items[indexToUpdate] and updatedItem) then
		items[indexToUpdate] = TableUtils:Assign({}, items[indexToUpdate], updatedItem)
		return true
	end
	return false
end

---
---Moves an item from a given position of an array to a new one, moving up other elements
---@param fromIndex number @The ONE-based location in the array to move from.
---@param toIndex number @The ONE-based location in the array to move to.
function TodoList:Move(fromIndex, toIndex)
	TableUtils:Move(self:GetItems(), fromIndex, toIndex)
end

---
---Return every item of the selected list
---@return TodoItem[] @The saved list of items
function TodoList:GetItems()
	return TodoChecklisterDB.lists[self:GetSelectedListName()]
end

---
---Finds the index of a given item in the saved list
---@param todoItem TodoItem @The item to be used to find its index
---@return number @The index of such item
function TodoList:GetIndexByItem(todoItem)
	if (todoItem and todoItem.id) then
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
	-- WoW: Forever characters have a surname. Blizzard loads a different NameUtil per game:
	-- on Forever it returns the name plus surname, elsewhere just the name
	return NameUtil.GetUnmodifiedUnitFullName("player") .. "'s List"
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
	local items = self:GetItems()
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
end
