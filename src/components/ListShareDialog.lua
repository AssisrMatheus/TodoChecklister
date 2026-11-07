--------------------------------------
-- Imports
--------------------------------------
---@class TodoAddon
local TodoAddon = select(2, ...)

---@type string
local addonName = select(1, ...)

---@class ListShare
local ListShare = TodoAddon.ListShare
---@class TodoChecklisterFrame
local TodoChecklisterFrame = TodoAddon.TodoChecklisterFrame

--------------------------------------
-- Declarations
--------------------------------------
TodoAddon.ListShareDialog = {}

---@class ListShareDialog
local ListShareDialog = TodoAddon.ListShareDialog

---@type "export"|"import"|nil
ListShareDialog.mode = nil
---@type string @The share string while exporting, restored when the user types over it
ListShareDialog.exportText = ""

--------------------------------------
-- ListShareDialog functions
--------------------------------------

---
---@return table @The edit box inside the scroll frame
function ListShareDialog:GetEditBox()
	return self.frame.TextBox.EditBox
end

---
---Shows the share string of a list, selected so Ctrl+C copies it
---@param name string @The name of a saved list
function ListShareDialog:ShowExport(name)
	local text = ListShare:Export(name)
	if (not text) then
		return
	end

	self.mode = "export"
	self.exportText = text
	self.frame.Title:SetText("Export list")
	self.frame.Description:SetText(
		'Press Ctrl+C to copy "' .. name .. '", then send it to anyone. They import it from the TodoChecklister options.'
	)
	self.frame.Status:SetText("")
	self.frame.AcceptButton:Hide()
	self.frame.CancelButton:SetText("Close")

	self.frame:Show()
	local editBox = self:GetEditBox()
	editBox:SetText(text)
	editBox:SetFocus()
	editBox:HighlightText()
end

---
---Shows an empty box to paste a share string into
function ListShareDialog:ShowImport()
	self.mode = "import"
	self.frame.Title:SetText("Import list")
	self.frame.Description:SetText(
		"Paste a list someone shared with Ctrl+V. It is added as a new list: none of your lists change."
	)
	self.frame.AcceptButton:Show()
	self.frame.CancelButton:SetText("Cancel")

	self.frame:Show()
	local editBox = self:GetEditBox()
	editBox:SetText("")
	editBox:SetFocus()
	self:OnImportTextChanged()
end

---
---Previews the pasted text, and only enables Import when it can be read
function ListShareDialog:OnImportTextChanged()
	local text = self:GetEditBox():GetText()
	if (strtrim(text) == "") then
		self.frame.Status:SetText("")
		self.frame.AcceptButton:Disable()
		return
	end

	local list, errorMessage = ListShare:Decode(text)
	if (list) then
		local ready =
			string.format('|cff6cf900Ready to import "%s" with %d %s|r', list.name, #list.items, #list.items == 1 and "item" or "items")
		-- A list from a newer version imports what this version knows, and says so
		if (errorMessage) then
			ready = ready .. "\n|cffffd100" .. errorMessage .. "|r"
		end
		self.frame.Status:SetText(ready)
		self.frame.AcceptButton:Enable()
	else
		self.frame.Status:SetText("|cffff2211" .. errorMessage .. "|r")
		self.frame.AcceptButton:Disable()
	end
end

---
---Saves the pasted list and switches to it
function ListShareDialog:Import()
	local list = ListShare:Decode(self:GetEditBox():GetText())
	if (not list) then
		return
	end

	local name = TodoChecklisterFrame:ImportList(list)
	if (name ~= list.name) then
		TodoAddon.Chat:Print('Imported "' .. list.name .. '" as |cff6cf900' .. name .. "|r, because that name was taken")
	else
		TodoAddon.Chat:Print("Imported |cff6cf900" .. name .. "|r")
	end
	self.frame:Hide()
	TodoAddon.InterfaceOptions:LoadCFG()
end

--------------------------------------
-- Lifecycle Events
--------------------------------------

---
---Initializes required properties for this class
function ListShareDialog:Init()
	self.frame = CreateFrame("Frame", addonName .. "ShareDialog", UIParent, "TodoChecklisterShareDialogTemplate")
	-- Escape closes it, like Blizzard's own dialogs
	table.insert(UISpecialFrames, self.frame:GetName())

	local editBox = self:GetEditBox()
	editBox:HookScript(
		"OnTextChanged",
		function(box, userInput)
			if (self.mode == "export") then
				-- Read only: undo any typing, and keep it selected for Ctrl+C
				if (userInput) then
					box:SetText(self.exportText)
					box:HighlightText()
				end
			elseif (self.mode == "import") then
				self:OnImportTextChanged()
			end
		end
	)
	editBox:HookScript(
		"OnEditFocusGained",
		function(box)
			if (self.mode == "export") then
				box:HighlightText()
			end
		end
	)

	self.frame.AcceptButton:SetScript(
		"OnClick",
		function()
			self:Import()
		end
	)
	self.frame.CancelButton:SetScript(
		"OnClick",
		function()
			self.frame:Hide()
		end
	)
	self.frame:SetScript(
		"OnHide",
		function()
			self.mode = nil
			self.exportText = ""
			self:GetEditBox():SetText("")
		end
	)
end
