--------------------------------------
-- Namespaces
--------------------------------------
local addonName, core = ...
core.TableUtils = {} -- adds Config table to addon namespace

local TableUtils = core.TableUtils

--------------------------------------
-- TableUtils functions
--------------------------------------
function TableUtils:IndexOf(tb, comparator)
	for i = 1, #tb do
		if (comparator(tb[i])) then
			return i
		end
	end
	return 0
end

function TableUtils:Filter(tb, comparator)
	local newTb = {}
	for i = 1, #tb do
		if (comparator(tb[i])) then
			table.insert(newTb, #newTb + 1, tb[i])
		end
	end
	return newTb
end

function TableUtils:Output(tb)
	if not tb then
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

function TableUtils:Move(tb, fromIndex, toIndex)
	local item = tb[fromIndex]
	table.remove(tb, fromIndex)
	table.insert(tb, toIndex, item)
end

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
