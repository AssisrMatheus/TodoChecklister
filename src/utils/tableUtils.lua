--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.TableUtils = {}

---@class TableUtils
local TableUtils = TodoAddon.TableUtils

--------------------------------------
-- TableUtils functions
--------------------------------------

---
---Calls comparator once for each element of the array, in ascending order, until it finds one where comparator returns true. If such an element is found, FindIndex immediately returns that element index. Otherwise, findIndex returns 0.
---@generic T
---@param tb T[] @An INDEXED table where you want to find the occurrence
---@param comparator fun(value: T, index: number, array: T[]):boolean @A function that results in a boolean comparison. The filter method calls the comparator function one time for each element in the array.
---@return number @The index of the first element in the array where comparator is true, and 0 otherwise.
function TableUtils:FindIndex(tb, comparator)
	for i = 1, #tb do
		if (comparator(tb[i], i, tb)) then
			return i
		end
	end
	return 0
end

---
---Returns the elements of an array that meet the condition specified in the comparator function.
---@generic T
---@param tb T[] @An INDEXED table where you want to find the occurrence
---@param comparator fun(value: T, index: number, array: T[]):boolean @A function that results in a boolean comparison. The filter method calls the comparator function one time for each element in the array.
---@return T[] @Elements of an array that meet the condition specified in the comparator function.
function TableUtils:Filter(tb, comparator)
	local newTb = {}
	for i = 1, #tb do
		if (comparator(tb[i], i, tb)) then
			table.insert(newTb, #newTb + 1, tb[i])
		end
	end
	return newTb
end

---
---Deep print a table
---@param tb table @A table where you want to print values from
function TableUtils:Output(tb)
	if (not tb or type(tb) ~= "table") then
		print(tb)
		return
	end

	for key, value in next, tb do
		if (type(value) == "table") then
			print("--- Start " .. key)
			self:Output(value)
			print("-----------------")
		else
			print(key .. ": " .. tostring(value))
		end
	end
end

---
---Moves an element from a given position of an array to a new one, moving up other elements
---@generic T
---@param tb T[] @An INDEXED table where you want to move elements
---@param fromIndex number @The ONE-based location in the array to move from.
---@param toIndex number @The ONE-based location in the array to move to.
function TableUtils:Move(tb, fromIndex, toIndex)
	if (fromIndex == toIndex) then
		return
	end

	local item = tb[fromIndex]
	table.remove(tb, fromIndex)
	table.insert(tb, toIndex, item)
end

---
---Copies the values of all own properties from one or more source objects to a target object. It will then return the target object.
---@generic T, K
---@param target table<K, T> @The target table where keys will be overwritten to.
---@vararg table<K, T> @An array of tables where the keys should be sourced from
---@return table<K, T>
function TableUtils:Assign(target, ...)
	local arg = {...}
	for key, value in pairs(arg) do
		if (value) then
			local tb = value
			for key, value in next, tb do
				if (type(value) == "table") then
					target[key] = self:Assign({}, target[key], value)
				else
					target[key] = value
				end
			end
		end
	end
	return target
end

---
---Determines whether all the members of an array satisfy the specified test.
---@generic T
---@param tb T[] @An INDEXED table where you want to find the occurrence
---@param comparator fun(value: T, index: number, array: T[]):boolean @A function that results in a boolean comparison. The filter method calls the comparator function one time for each element in the array.
---@return boolean @Whether all the members of an array satisfy the specified test.
function TableUtils:Every(tb, comparator)
	local newTb = {}
	for i = 1, #tb do
		if (not comparator(tb[i], i, tb)) then
			return false
		end
	end
	return true
end
