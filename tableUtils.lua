--------------------------------------
-- Namespaces
--------------------------------------
local addonName, core = ...;
core.TableUtils = {}; -- adds Config table to addon namespace

local TableUtils = core.TableUtils;

--------------------------------------
-- TableUtils functions
--------------------------------------
function TableUtils:IndexOf(tb, comparator)
	for i=1, #tb do
		if(comparator(tb[i])) then return i end
	end
end