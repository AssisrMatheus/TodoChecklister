--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...
core.TodoList = {} -- Creates an instance of this model
local TodoList = core.TodoList

local TableUtils = core.TableUtils

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
function TodoList:AddItem(text)
	-- If text is not empty
	if (text and text ~= nil and text ~= "") then
		-- Adds one at the end of array
		table.insert(
			TodoChecklisterDB,
			#TodoChecklisterDB + 1,
			{text = text, isChecked = false, id = text .. (#TodoChecklisterDB + 1)}
		)
	end
end

function TodoList:RemoveItem(indexToRemove)
	if (indexToRemove > 0 and TodoChecklisterDB and TodoChecklisterDB[indexToRemove]) then
		table.remove(TodoChecklisterDB, indexToRemove)
		return true
	end
	return false
end

function TodoList:UpdateItem(indexToUpdate, updatedItem)
	local item = TodoChecklisterDB[indexToUpdate]
	-- If the list exists and the item exists on the list
	if (indexToUpdate > 0 and TodoChecklisterDB and TodoChecklisterDB[indexToUpdate] and updatedItem) then
		TodoChecklisterDB[indexToUpdate] = TableUtils:Assign({}, TodoChecklisterDB[indexToUpdate], updatedItem)
		return true
	end
	return false
end

function TodoList:Move(fromIndex, toIndex)
	TableUtils:Move(TodoChecklisterDB, fromIndex, toIndex)
end

function TodoList:GetItems()
	return TodoChecklisterDB
end

function TodoList:GetIndexByItem(todoItem)
	if (todoItem and todoItem.id) then
		return TodoList:GetIndexById(todoItem.id)
	elseif (todoItem) then
		return TodoList:GetIndexByText(todoItem.text)
	else
		return 0
	end
end

function TodoList:GetIndexByText(text)
	return TableUtils:IndexOf(
		TodoChecklisterDB,
		function(x)
			return x.text == text
		end
	)
end

function TodoList:GetIndexById(id)
	return TableUtils:IndexOf(
		TodoChecklisterDB,
		function(x)
			return x.id == id
		end
	)
end
