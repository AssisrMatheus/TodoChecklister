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
---The SavedVariable where the items are stored into
---@type TodoItem[]|nil
local DB

-- {
--   pages = [
--     {
--       name,
--       categories = [
--         {
--           name,
--           todos: [
--             {
--               id: 0
--               content: "",
--               done: false
--             }
--           ]
--         }
--       ]
--     }
--   ]
-- }

--------------------------------------
-- TodoList functions
--------------------------------------
---
---Appends a new TodoItem to the list
---@param text string @New element to be appended to the list
function TodoList:AddItem(text)
	-- If text is not empty
	if (text and text ~= nil and text ~= "") then
		-- Adds one at the end of array
		table.insert(DB, #DB + 1, {text = text, isChecked = false, id = text .. (#DB + 1)})
	end
end

---
---Removes an element from a given position, moving down other elements to close space and decrementing the size of the array
---@param indexToRemove number @The ONE-based location in the array to remove.
function TodoList:RemoveItem(indexToRemove)
	if (indexToRemove > 0 and DB and DB[indexToRemove]) then
		table.remove(DB, indexToRemove)
		return true
	end
	return false
end

---
---Assign updatedItem values to the item in the given indexToUpdate position.
---@param indexToUpdate number @The ONE-based location in the array to remove.
---@param updatedItem TodoItem @Source object
function TodoList:UpdateItem(indexToUpdate, updatedItem)
	local item = DB[indexToUpdate]
	-- If the list exists and the item exists on the list
	if (indexToUpdate > 0 and DB and DB[indexToUpdate] and updatedItem) then
		DB[indexToUpdate] = TableUtils:Assign({}, DB[indexToUpdate], updatedItem)
		return true
	end
	return false
end

---
---Moves an item from a given position of an array to a new one, moving up other elements
---@param fromIndex number @The ONE-based location in the array to move from.
---@param toIndex number @The ONE-based location in the array to move to.
function TodoList:Move(fromIndex, toIndex)
	TableUtils:Move(DB, fromIndex, toIndex)
end

---
---Return every item
---@return TodoItem[] @The saved list of items
function TodoList:GetItems()
	return DB
end

---
---Finds the index of a given item in the saved list
---@param todoItem TodoItem @The item to be used to find its index
---@return number @The index of such item
function TodoList:GetIndexByItem(todoItem)
	if (todoItem and todoItem.id) then
		return TodoList:GetIndexById(todoItem.id)
	elseif (todoItem) then
		return TodoList:GetIndexByText(todoItem.text)
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
		DB,
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
		DB,
		function(x)
			return x.id == id
		end
	)
end

---
---Gets the message of the day value based on available items the user currently has
---@return string @MOTD value
function TodoList:GetMOTD()
	if (DB and #DB > 0) then
		local completedList =
			TableUtils:Filter(
			DB,
			function(x)
				return x.isChecked == true
			end
		)
		local notList =
			TableUtils:Filter(
			DB,
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
	DB = TodoChecklisterDB

	if (not DB) then
		DB = {}
	end
end
