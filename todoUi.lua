--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...
core.TodoUI = {} -- adds Config table to addon namespace

local TodoUI = core.TodoUI
local Constants = core.Constants

local UIConfig

--------------------------------------
-- TodoUI functions
--------------------------------------
function TodoUI:Toggle()
	local menu = UIConfig or TodoUI:CreateMenu()
	menu:SetShown(not menu:IsShown())
end

function TodoUI:CreateButton(point, relativeFrame, relativePoint, yOffset, text)
	local btn = CreateFrame("Button", nil, UIConfig.ScrollFrame, "GameMenuButtonTemplate")
	btn:SetPoint(point, relativeFrame, relativePoint, 0, yOffset)
	btn:SetSize(140, 40)
	btn:SetText(text)
	btn:SetNormalFonUIConfigect("GameFontNormalLarge")
	btn:SetHighlightFonUIConfigect("GameFontHighlightLarge")
	return btn
end

local function ScrollFrame_OnMouseWheel(self, delta)
	local newValue = self:GetVerticalScroll() - (delta * 20)
	
	if (newValue < 0) then
		newValue = 0
	elseif (newValue > self:GetVerticalScrollRange()) then
		newValue = self:GetVerticalScrollRange()
	end
	
	self:SetVerticalScroll(newValue)
end

function TodoUI:CreateMenu()
	--[[
		PARENT FRAME: AssisTODOUI
			This frame is an empty frame with the anchor and resizing capabilities
	--]]
		UIConfig = CreateFrame("Frame", "AssisTODOUI", UIParent, "UIPanelDialogTemplate")
    UIConfig:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -120, 30) -- Doesn't need to be ("CENTER", UIParent, "CENTER")
    UIConfig:SetSize(250, 300)
    UIConfig:EnableMouse(true)
    UIConfig:SetMovable(true)
    UIConfig:SetResizable(true)
    UIConfig:SetScript("OnDragStart", function(self) 
        self.isMoving = true
        self:StartMoving() 
    end)
    UIConfig:SetScript("OnDragStop", function(self) 
        self.isMoving = false
        self:StopMovingOrSizing() 
        self.x = self:GetLeft() 
        self.y = (self:GetTop() - self:GetHeight()) 
        self:ClearAllPoints()
        self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.x, self.y)
    end)
    UIConfig:SetScript("OnUpdate", function(self) 
        if self.isMoving == true then
            self.x = self:GetLeft() 
            self.y = (self:GetTop() - self:GetHeight()) 
            self:ClearAllPoints()
            self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.x, self.y)
        end
    end)
    UIConfig:SetClampedToScreen(true)
    UIConfig:RegisterForDrag("LeftButton")
    UIConfig:SetScale(1)
    UIConfig.x = UIConfig:GetLeft() 
    UIConfig.y = (UIConfig:GetTop() - UIConfig:GetHeight()) 
 
	--[[
		PARENT FRAME: resButton
			The resize button which the user can click to resize the window
		
		 -> Anchors to AssisTODOUI
	--]]
    UIConfig.ResizeButton = CreateFrame("Button", "resButton", UIConfig)
    UIConfig.ResizeButton:SetSize(16, 16)
    UIConfig.ResizeButton:SetPoint("BOTTOMRIGHT", -5, 7)
    UIConfig.ResizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    UIConfig.ResizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    UIConfig.ResizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	
	--[[
		PARENT FRAME: Title
			Sets the template title
	--]]
	UIConfig.Title:ClearAllPoints()
	UIConfig.Title:SetFontObject("GameFontHighlight")
	UIConfig.Title:SetPoint("LEFT", AssisTODOUITitleBG, "LEFT", 6, 0)
	UIConfig.Title:SetText(Constants.addonName)
	
	--[[
		SCROLL FRAME
			This is the viewable part of the scroll component
	--]]
	UIConfig.ScrollFrame = CreateFrame("ScrollFrame", nil, UIConfig, "UIPanelScrollFrameTemplate")
	UIConfig.ScrollFrame:SetPoint("TOPLEFT", AssisTODOUIDialogBG, "TOPLEFT", 4, -8)
	UIConfig.ScrollFrame:SetPoint("BOTTOMRIGHT", AssisTODOUIDialogBG, "BOTTOMRIGHT", -3, 4)
	UIConfig.ScrollFrame:SetClipsChildren(true)
	-- UIConfig.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel)
	
	--[[
		SCROLL FRAME: Scrollbar
	--]]
	UIConfig.ScrollFrame.ScrollBar:ClearAllPoints()
	UIConfig.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", UIConfig.ScrollFrame, "TOPRIGHT", -12, -18)
	UIConfig.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", UIConfig.ScrollFrame, "BOTTOMRIGHT", -7, 18)

	--[[
		SCROLL FRAME: child frame
			The actual content that gets scrolled
	--]]
	local child = CreateFrame("Frame", nil, UIConfig.ScrollFrame)
	child:SetSize(UIConfig:GetWidth()-42, 500)
	UIConfig.ScrollFrame:SetScrollChild(child)	

	--[[
		CHILD FRAME: Textbox
	--]]
	UIConfig.input1 = CreateFrame("EditBox", nil, UIConfig.ScrollFrame, "InputBoxTemplate")
	UIConfig.input1:SetPoint("TOPLEFT", child, "TOPLEFT", 4, -8)
	UIConfig.input1:SetPoint("TOPRIGHT", child, "TOPRIGHT", -3, 4)
	UIConfig.input1:SetSize(1, 20)
	UIConfig.input1:SetAutoFocus(false)

	UIConfig.input1:SetScript("OnEnter", function(self)
		local text = UIConfig.input1:GetText()
		if text ~= "" then
			core.Chat:Print(text)
		end
	end)
	UIConfig.input1:SetScript("OnLeave", function() 
		local text = UIConfig.input1:GetText()
		if text ~= "" then
			core.Chat:Print(text)
		end
	 end)
	UIConfig.input1:SetScript("OnEnterPressed", function()
		local text = UIConfig.input1:GetText()
		if text ~= "" then
			core.Chat:Print(text)
		end
	end)
	UIConfig.input1:SetScript("OnTabPressed", function()
		local text = UIConfig.input1:GetText()
		if text ~= "" then
			core.Chat:Print(text)
		end
	end)
	UIConfig.input1:SetScript("OnTextChanged", function()
		local text = UIConfig.input1:GetText()
		if text ~= "" then
			core.Chat:Print(text)
		end
	end)
	UIConfig.input1:SetScript("OnEscapePressed", function()
		UIConfig.input1:ClearFocus()
	end)

	UIConfig.ResizeButton:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            self.isSizing = true
            self:GetParent():StartSizing("BOTTOMRIGHT")
            self:GetParent():SetUserPlaced(true)
        elseif button == "RightButton" then
            self.isScaling = true
        end
    end)
    UIConfig.ResizeButton:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self.isSizing = false
            self:GetParent():StopMovingOrSizing()
        elseif button == "RightButton" then
            self.isScaling = false
        end
    end)
    UIConfig.ResizeButton:SetScript("OnUpdate", function(self, button)
        if self.isScaling == true then
            local cx, cy = GetCursorPosition()
            cx = cx / self:GetEffectiveScale() - self:GetParent():GetLeft() 
            cy = self:GetParent():GetHeight() - (cy / self:GetEffectiveScale() - self:GetParent():GetBottom() )
 
            local tNewScale = cx / self:GetParent():GetWidth()
            local tx, ty = self:GetParent().x / tNewScale, self:GetParent().y / tNewScale
            
            self:GetParent():ClearAllPoints()
            self:GetParent():SetScale(self:GetParent():GetScale() * tNewScale)
            self:GetParent():SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", tx, ty)
            self:GetParent().x, self:GetParent().y = tx, ty
				end
		
			child:SetSize(UIConfig:GetWidth()-42, 500)
    end)

	
	-- ----------------------------------
	-- -- Buttons
	-- ----------------------------------
	-- -- Save Button:
	-- UIConfig.saveBtn = self:CreateButton("CENTER", child, "TOP", -70, "Save")

	-- -- Reset Button:	
	-- UIConfig.resetBtn = self:CreateButton("TOP", UIConfig.saveBtn, "BOTTOM", -10, "Reset")

	-- -- Load Button:	
	-- UIConfig.loadBtn = self:CreateButton("TOP", UIConfig.resetBtn, "BOTTOM", -10, "Load")

	-- ----------------------------------
	-- -- Sliders
	-- ----------------------------------
	-- -- Slider 1:
	-- UIConfig.slider1 = CreateFrame("SLIDER", nil, UIConfig.ScrollFrame, "OptionsSliderTemplate")
	-- UIConfig.slider1:SetPoint("TOP", UIConfig.loadBtn, "BOTTOM", 0, -20)
	-- UIConfig.slider1:SetMinMaxValues(1, 100)
	-- UIConfig.slider1:SetValue(50)
	-- UIConfig.slider1:SetValueStep(30)
	-- UIConfig.slider1:SetObeyStepOnDrag(true)

	-- -- Slider 2:
	-- UIConfig.slider2 = CreateFrame("SLIDER", nil, UIConfig.ScrollFrame, "OptionsSliderTemplate")
	-- UIConfig.slider2:SetPoint("TOP", UIConfig.slider1, "BOTTOM", 0, -20)
	-- UIConfig.slider2:SetMinMaxValues(1, 100)
	-- UIConfig.slider2:SetValue(40)
	-- UIConfig.slider2:SetValueStep(30)
	-- UIConfig.slider2:SetObeyStepOnDrag(true)

	-- ----------------------------------
	-- -- Check Buttons
	-- ----------------------------------
	-- -- Check Button 1:
	-- UIConfig.checkBtn1 = CreateFrame("CheckButton", nil, UIConfig.ScrollFrame, "UICheckButtonTemplate")
	-- UIConfig.checkBtn1:SetPoint("TOPLEFT", UIConfig.slider1, "BOTTOMLEFT", -10, -40)
	-- UIConfig.checkBtn1.text:SetText("My Check Button!")

	-- -- Check Button 2:
	-- UIConfig.checkBtn2 = CreateFrame("CheckButton", nil, UIConfig.ScrollFrame, "UICheckButtonTemplate")
	-- UIConfig.checkBtn2:SetPoint("TOPLEFT", UIConfig.checkBtn1, "BOTTOMLEFT", 0, -10)
	-- UIConfig.checkBtn2.text:SetText("Another Check Button!")
	-- UIConfig.checkBtn2:SetChecked(true)

	
	
	UIConfig:Hide()
	return UIConfig
end