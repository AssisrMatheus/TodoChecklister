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

function TodoList:GetMOTD()
	if (TodoChecklisterDB and #TodoChecklisterDB > 0) then
		local completedList =
			core.TableUtils:Filter(
			TodoChecklisterDB,
			function(x)
				return x.isChecked == true
			end
		)
		local notList =
			core.TableUtils:Filter(
			TodoChecklisterDB,
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
function TodoList:Init()
	if (not TodoChecklisterDB) then
		TodoChecklisterDB = {}
	end
end
