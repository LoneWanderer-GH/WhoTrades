--[[-----------------------------------------------------------------------------
SecureButton Widget
Graphical Button.

Modified version of default AceGUI-3.0 button
-------------------------------------------------------------------------------]]
local Type, Version = "SecureActionTemplateButton", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local _G = _G
local PlaySound, CreateFrame, UIParent = PlaySound, CreateFrame, UIParent

-- local wowMoP
-- do
-- 	local _, _, _, interface = GetBuildInfo()
-- 	wowMoP = (interface >= 50000)
-- end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame.obj:Fire("OnLeave")
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		-- restore default values
		self:SetHeight(24)
		self:SetWidth(200)
		self:SetDisabled(false)
		self:SetText()
	end,

	-- ["OnRelease"] = nil,

	["SetText"] = function(self, text)
		self.text:SetText(text)
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.frame:Disable()
		else
			self.frame:Enable()
		end
	end,
	
	--Custom functions
	["SetAction"] = function(self,actionType, actionId)
		self.frame:SetAttribute("type", actionType)
		self.frame:SetAttribute(actionType,actionId)
	end,
	["SetTooltip"] = function(self,tooltipText)
		self:SetCallback("OnEnter",function(widget) GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT");
													GameTooltip:SetText(tooltipText, nil, nil, nil, 0.5, 1); 
													end);
		self:SetCallback("OnLeave",function(widget) GameTooltip:Hide(); end);
	end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local name = "AceGUI30Button" .. AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Button", name, UIParent,"UIPanelButtonTemplate,SecureActionButtonTemplate")
	frame:Hide()

	frame:EnableMouse(true)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)

	local text = frame:GetFontString()
	text:ClearAllPoints()
	text:SetPoint("TOPLEFT", 15, -1)
	text:SetPoint("BOTTOMRIGHT", -15, 1)
	text:SetJustifyV("MIDDLE")

	local widget = {
		text  = text,
		frame = frame,
		type  = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)