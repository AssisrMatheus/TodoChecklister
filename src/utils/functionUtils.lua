--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.FunctionUtils = {}

---@class FunctionUtils
local FunctionUtils = TodoAddon.FunctionUtils

local memoizedValues = {}

--------------------------------------
-- TableUtils functions
--------------------------------------

---
---Calls a function once and store its key value, if the function gets called again but the parameters haven't changed.
---Instead of calling it again, it just return the previously calculated value
---@generic T
---@param execution fun(): T @A complex function that you want to Memoize
---@param comparator any @The value used to decide wether or not the function should be called again
---@param name string @A unique name for this memoization
---@return T @The returned value from the executed function
function FunctionUtils:Memoize(execution, comparator, name)
  if (memoizedValues[name] and memoizedValues[name].comparator == comparator) then
    return memoizedValues[name].result
  end

  memoizedValues[name] = {
    result = execution(),
    comparator = comparator
  }

  return memoizedValues[name].result
end
