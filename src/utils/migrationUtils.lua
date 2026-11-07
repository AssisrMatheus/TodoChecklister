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
TodoAddon.MigrationUtils = {}

---@class MigrationUtils
local MigrationUtils = TodoAddon.MigrationUtils

--[[
	!!! USER DATA SAFETY: READ THIS BEFORE CHANGING ANYTHING THAT IS SAVED !!!

	SavedVariables (TodoChecklisterDB, TodoChecklisterSettingsDB, TodoChecklisterCharacterDB) hold months or years of
	someone's notes. There is no server copy and no undo: if the addon breaks them, they are gone. Users also move
	between addon versions in BOTH directions (a stale copy on another PC, a rollback after a bad release, a flavor
	whose download lags behind), so data saved by this code WILL be read by older code, and the other way around.

	Every saved table carries:
	  schemaVersion     the format it is in. A table saved before versions existed has none: a schema's `detect`
	                    works out its version from its shape
	  minSchemaVersion  the oldest code that may still read and write it. Older code refuses to touch it
	  schemaBackup      { fromVersion, data }: the table as it was before the last upgrade, kept in case it went wrong
	These three keys are reserved in every saved table. Never use them for anything else.

	Rules:
	1. Prefer additive changes. Add new fields that old code ignores (that is how folders were added). Never
	   rename, move, retype or delete a saved field in place: old code would read garbage or drop it.
	2. When a change can't be additive, raise `current`, add steps[current] and raise `minSchemaVersion` to it, so
	   older code stops instead of corrupting the new format.
	3. A step receives a deep copy and returns the upgraded table. It must not write globals, frames or other saved
	   tables (it may read the game API, like the character name), and must never drop user data: anything it
	   doesn't understand is carried over as is.
	4. Never edit or remove a step that has shipped, and never reuse a version number. Users skip versions:
	   steps 1 to N must still run in order from any older release.
	5. Loading only fills missing values (`== nil`). It never overwrites a value the user saved.
	6. Before releasing a step, test it against the SavedVariables files of every released version
	   (WTF/Account/<account>/SavedVariables/TodoChecklister.lua), including empty and very old ones.
]]

---
---How a saved table upgrades from one format to the next
---@class MigrationSchema
---@field public current integer @The format this code reads and writes
---@field public minSchemaVersion integer @The oldest format whose code can safely edit data in the current format
---@field public steps table<integer, fun(db: table): table> @steps[n] turns a format n - 1 table into format n
---@field public detect fun(db: table): integer @The format of a table saved before schemaVersion existed

---@alias MigrationStatus
---| "current" # Already in the current format. Nothing changed except the version keys
---| "migrated" # Upgraded. The original is in schemaBackup
---| "newer" # Saved by newer code that still allows this code to use it. Left as it is
---| "incompatible" # Saved by newer code that forbids older code to touch it. Left as it is: don't use it
---| "failed" # An upgrade step errored. Left as it is: don't use it

--------------------------------------
-- MigrationUtils functions
--------------------------------------

---
---Brings a saved table to the current format. The table passed in is never changed when anything goes wrong:
---steps run on a copy, and the copy replaces it only once every step succeeded
---@param db any @The saved table, as the game loaded it. nil for a new user
---@param schema MigrationSchema
---@return any, MigrationStatus, string|nil @The table to save (the same one unless it was upgraded), what happened, and the error when it failed
function MigrationUtils:Migrate(db, schema)
	if (db == nil) then
		return nil, "current"
	end
	if (type(db) ~= "table") then
		-- Not something this addon ever saved. Leave it for a human to look at rather than guess
		return db, "failed", "saved data is a " .. type(db) .. ", not a table"
	end

	local version = type(db.schemaVersion) == "number" and db.schemaVersion or schema.detect(db)

	if (version > schema.current) then
		-- Never "upgrade" down and never lower schemaVersion: the newer code would skip its own steps next time
		local minVersion = tonumber(db.minSchemaVersion) or version
		if (minVersion > schema.current) then
			return db, "incompatible"
		end
		return db, "newer"
	end

	if (version == schema.current) then
		db.schemaVersion = schema.current
		db.minSchemaVersion = schema.minSchemaVersion
		return db, "current"
	end

	local upgraded = TableUtils:DeepCopy(db)
	-- Don't carry an older backup inside the new one
	upgraded.schemaBackup = nil
	local ok, err =
		pcall(
		function()
			for step = version + 1, schema.current do
				local upgrade = schema.steps[step] --[[@as (fun(db: table): table)|nil]]
				if (not upgrade) then
					error("missing upgrade step " .. step)
				end
				upgraded = upgrade(upgraded)
				assert(type(upgraded) == "table", "upgrade step " .. step .. " returned no table")
			end
		end
	)
	if (not ok) then
		return db, "failed", tostring(err)
	end

	local original = TableUtils:DeepCopy(db)
	original.schemaBackup = nil
	upgraded.schemaVersion = schema.current
	upgraded.minSchemaVersion = schema.minSchemaVersion
	upgraded.schemaBackup = {fromVersion = version, data = original}
	return upgraded, "migrated"
end

---
---Stamps a table made for a new user with the current format
---@generic T
---@param db T @A new, empty saved table
---@param schema MigrationSchema
---@return T
function MigrationUtils:Create(db, schema)
	db.schemaVersion = schema.current
	db.minSchemaVersion = schema.minSchemaVersion
	return db
end
