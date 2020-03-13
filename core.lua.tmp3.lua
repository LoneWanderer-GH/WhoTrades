local WhoTrades = LibStub("AceAddon-3.0"):NewAddon("WhoTrades", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
_G["WhoTrades"] = WhoTrades
local TradeFrame = TradeFrame
local TradeFrameRecipientNameText = TradeFrameRecipientNameText
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitClassBase, UnitClass = UnitClassBase, UnitClass-- Returns a unit's class
local UnitIsInMyGuild, GetGuildInfo = UnitIsInMyGuild, GetGuildInfo
local UnitInParty, UnitInOtherParty, UnitInRaid, IsInRaid, GetRaidRosterInfo = UnitInParty, UnitInOtherParty, UnitInRaid, IsInRaid, GetRaidRosterInfo
-- local WhoTradesDB = nil

local texture_path_index = {}

function WhoTrades:OnEnable()
    -- Called when the addon is enabled
    self:Print("OnEnable")
    self.enabled = true
    WhoTrades:RegisterEvent("TRADE_SHOW")
    WhoTrades:RegisterEvent("TRADE_CLOSED")
end

function WhoTrades:OnDisable()
    -- Called when the addon is disabled
    self:Print("OnDisable")
    self.enabled = false
    WhoTrades:UnregisterEvent("TRADE_SHOW")
    WhoTrades:UnregisterEvent("TRADE_CLOSED")
    WhoTrades:UnregisterEvent("PLAYER_TARGET_CHANGED")
end

function WhoTrades:get_player_infos_from_group()
    local unit_id = nil
    for _, v in ipairs{"party1", "party2", "party3", "party4"} do
        if UnitName(v) == self.trading_with then
            unit_id = v
            break
        end
    end
    local localized_class, class_name, classIndex = UnitClass(unit_id)
    local level = UnitLevel(unit_id)
    local rank, group_number = nil, nil
    local guild_name, guild_rank_text, guild_rank_nb = GetGuildInfo(unit_id)
    self.trader_name = self.trading_with
    self.trader_rank = rank
    self.trader_level = level
    self.trader_localized_class = localized_class
    self.trader_class_name = class_name
    self.trader_guild_name = guild_name
    self.trader_guild_rank_text = guild_rank_text
    self.trader_guild_rank_nb = guild_rank_nb
    self.trader_group_number = group_number
end

function WhoTrades:get_player_infos_from_raid()
    local raid_index = UnitInRaid(self.trading_with)
    -- luacheck: ignore zone online isDead role isML -- save for future use ?
    local name, rank, group_number, level, localized_class, class_name, zone, online, isDead, role, isML = GetRaidRosterInfo(raid_index)
    local guild_name, guild_rank_text, guild_rank_nb = GetGuildInfo(self.trading_with)
    --self:Print(format("get_player_infos_from_raid - %s - %s - %02d - %s (%s) - %s %s (%02d) - §01d", name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_number))
    --return name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_number
    self.trader_name = name
    self.trader_rank = rank
    self.trader_level = level
    self.trader_localized_class = localized_class
    self.trader_class_name = class_name
    self.trader_guild_name = guild_name
    self.trader_guild_rank_text = guild_rank_text
    self.trader_guild_rank_nb = guild_rank_nb
    self.trader_group_number = group_number
end

--[[function WhoTrades:get_player_infos_from_pvp_raid()
    local raid_index = UnitInRaid(self.trading_with)
    -- luacheck: ignore zone online isDead role isML -- save for future use ?
    local name, rank, group_number, level, localized_class, class_name, zone, online, isDead, role, isML = GetRaidRosterInfo(raid_index)
    local guild_name, guild_rank_text, guild_rank_nb = GetGuildInfo(self.trading_with)
    self.trader_name = name
    self.trader_rank = rank
    self.trader_level = level
    self.trader_localized_class = localized_class
    self.trader_class_name = class_name
    self.trader_guild_name = guild_name
    self.trader_guild_rank_text = guild_rank_text
    self.trader_guild_rank_nb = guild_rank_nb
    self.trader_group_number = group_number
end--]]

function WhoTrades:get_player_infos_from_target()
    localized_class, class_name, classIndex = UnitClass("target")
    level = UnitLevel("target")
    rank, group_number = nil, nil
    guild_name, guild_rank_text, guild_rank_nb = GetGuildInfo("target")
    self.trader_name = target_name
    self.trader_rank = rank
    self.trader_level = level
    self.trader_localized_class = localized_class
    self.trader_class_name = class_name
    self.trader_guild_name = guild_name
    self.trader_guild_rank_text = guild_rank_text
    self.trader_guild_rank_nb = guild_rank_nb
    self.trader_group_number = group_number
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
end

function WhoTrades:get_player_infos()
    self:Print("get_player_infos")
    
    if self.trading_with then
        self:Print("get_player_infos - Trying to fetch from group or raid")
        local is_in_player_raid = UnitInRaid(self.trading_with)
        local is_in_player_group = UnitInParty(self.trading_with)
        self.trade_assistant_frame.target_button:Hide()
        if is_in_player_raid then
            self:Print("get_player_infos - in raid !")
            self:get_player_infos_from_raid()
            self.trader_group_kind = "Raid"
        elseif is_in_player_group then
            self:Print("get_player_infos - in group !")
            self:get_player_infos_from_group()
            self.trader_group_kind = "Party"
        else
            self:Print("get_player_infos - not in raid nor group, trying from target")
            self.trade_assistant_frame.target_button:Show()
            
            if UnitIsPlayer("target") and UnitName("target") == self.trading_with then
                self:Print("get_player_infos - got it from target")
                self:get_player_infos_from_target()
                self.trade_assistant_frame.target_button:Hide()
            else
                self:RegisterEvent("PLAYER_TARGET_CHANGED")
                self:Print(format("Trader (%s) is not in target, group or raid. Cannot fetch info. Please try to target it manually", self.trading_with))
            end
            
        end
    else
        self:Print("Trader is nil ????")
    end
end

function WhoTrades:OnShowTradeFrame()
    self:Print("OnShowTradeFrame")
    if self.trade_assistant_frame then
        self:Print("OnShowTradeFrame - addon frame exists")
        if self.trading_with then
            
            local mtext = format("/target %s", self.trading_with) -- \n/WT_OnShowTradeFrame
            self.trade_assistant_frame.target_button:SetAttribute("macrotext", mtext)
            
            self:get_player_infos()
            
            local class_color_str = "|r"
            if self.trader_class_name then
                class_color_str = format("|c%s", RAID_CLASS_COLORS[self.trader_class_name].colorStr)
            end
            
            local level_str = "|r[??]|r"
            if self.trader_level then
                level_str = format("|r[%02d]|r", self.trader_level)
            end
            
            local name_str = "|r?|r"
            if self.trading_with then
                name_str = format("%s%s|r", class_color_str, self.trading_with)
            end
            
            if not texture_path_index[self.trader_class_name] then
                texture_path_index[self.trader_class_name] = format("Interface\\AddOns\\DefaultUIScript\\ClassIcons\\%s.tga", self.trader_class_name)
            end
            local texture_path = texture_path_index[self.trader_class_name]
            local texture_path_str = format("|T%s:%d|t", texture_path, 0)
            
            local full_trader_str = format("%s %s %s", level_str, texture_path_str, name_str)
            self.trade_assistant_frame.name:SetText(full_trader_str)
            
            --[[-- NAME labels
            self.trade_assistant_frame.name:SetText(format(" % s ( % 02d)", self.trading_with, self.trader_level))
 
            -- CLASS labels
            local texture_path = "Interface\\Glues\\CharacterCreate\\UI - CharacterCreate - Classes"
            local class_coords = CLASS_ICON_TCOORDS[self.trader_class_name]
            if class_coords then
                --self.trade_assistant_frame.class:SetImage(texture_path, unpack(class_coords))
                self.trade_assistant_frame.class:SetImage(nil)
            else
                self.trade_assistant_frame.class:SetImage(nil)
            end
            self.trade_assistant_frame.class:SetText(self.trader_localized_class)
            if self.trader_class_name then
                local class_color = RAID_CLASS_COLORS[self.trader_class_name]
                local class_color_str = RAID_CLASS_COLORS[self.trader_class_name].colorStr
 
                if class_color then
                    self.trade_assistant_frame.class:SetColor(class_color.r, class_color.g, class_color.b)
                else
                    self.trade_assistant_frame.class:SetColor(0, 0, 0)
            end
        else
            self.trade_assistant_frame.class:SetColor(0, 0, 0)
        end--]]
            
            -- GUILD labels
            if self.trader_guild_name then
                self.trade_assistant_frame.guild:SetText(format(" % s ( % s, % d)", self.trader_guild_name, self.trader_guild_rank_text, self.trader_guild_rank_nb))
            end
            
            if self.trader_group_kind then
                local g = format("group % d", self.trader_group_number) or "(mine)"
                local s = format(" % s % s", self.trader_group_kind, g)
                self.trade_assistant_frame.group_label:SetText(s)
                --[[if self.trader_group_kind == "Party" then
                    self.trade_assistant_frame.group_label:SetText(format(" % s - % s", "Group", "(mine)"))
                    -- self.trade_assistant_frame.group:SetText("mine")
                elseif self.trader_group_kind == "Raid" then
                    local s = "Raid"
                    local g = self.trader_group_number or "None ?"
                    s = format(" % s - % s", s, g)
                    self.trade_assistant_frame.group_label:SetText(s)
                    self.trade_assistant_frame.group_label:SetText("Raid")
                    if self.trader_group_number and self.trader_group_number > 0 then
                        self.trade_assistant_frame.group:SetText(format("Raid, group % 01d", self.trader_group_number))
                    else
                        self.trade_assistant_frame.group:SetText("None")
                    end
                else
                    self.trade_assistant_frame.group_label:SetText("Group / Raid")
                    self.trade_assistant_frame.group:SetText("None")
                end--]]
            else
                self.trade_assistant_frame.group_label:SetText("Wanderer")
                --[[self.trade_assistant_frame.group_label:SetText("Group / Raid")
                self.trade_assistant_frame.group:SetText("None")--]]
            end
            --
            self.trade_assistant_frame:Show()
        else
            self:Print("OnShowTradeFrame - Trading with undefined ?! (recipient text is: "..TradeFrameRecipientNameText:GetText() .. ")")
        end
    else
        self:Print("OnShowTradeFrame - No assitant frame ?!")
    end
end

function WhoTrades:OnHideTradeFrame()
    self:Print("OnHideTradeFrame")
    if self.trade_assistant_frame then
        self.trade_assistant_frame:Hide()
    else
        if self.enabled then
            self:Print("OnHideTradeFrame - No assistant frame ?!")
        else
            self:Print("OnHideTradeFrame - Addon is disabled, doing nothing")
        end
    end
end

function WhoTrades:build_UI()
    self:Print("build_UI")
    if TradeFrame then
        self:Print("build_UI - WOW TradeFrame exists")
        if not self.trade_assistant_frame then
            self:Print("build_UI - trade_assistant_frame does not exists, build it")
            
            self.trade_assistant_frame = AceGUI:Create("Frame")
            self.trade_assistant_frame:SetTitle("WhoTrades")
            self.trade_assistant_frame:SetLayout("Flow")
            self.trade_assistant_frame:SetPoint("TOPLEFT", TradeFrame, "TOPRIGHT")
            self.trade_assistant_frame:SetWidth(180)
            self.trade_assistant_frame:SetHeight(TradeFrame:GetHeight())
            
            self.trade_assistant_frame.name_group = AceGUI:Create("InlineGroup")
            self.trade_assistant_frame.name_group:SetLayout("Flow")
            self.trade_assistant_frame.name_group:SetAutoAdjustHeight(true)
            self.trade_assistant_frame.name = AceGUI:Create("Label")
            
            self.trade_assistant_frame.target_button = CreateFrame("Button", "WhoTrades_targetbutton", self.trade_assistant_frame.frame, "SecureActionButtonTemplate")
            self.trade_assistant_frame.target_button:RegisterForClicks("AnyUp")
            self.trade_assistant_frame.target_button.SetTarget = function () self.trade_assistant_frame.target_button:SetTexture("Interface\\Icons\\Ability_Marksmanship"); end
            self.trade_assistant_frame.target_button:SetAttribute("type", "macro")
            self.trade_assistant_frame.target_button:SetHeight(32)
            self.trade_assistant_frame.target_button:SetWidth(32)
            local targeticon = self.trade_assistant_frame.target_button:CreateTexture(nil, "ARTWORK")
            targeticon:SetWidth(36)
            targeticon:SetHeight(36)
            targeticon:SetTexture("Interface\\Icons\\Ability_Marksmanship")
            targeticon:SetAllPoints(self.trade_assistant_frame.target_button)
            
            self.trade_assistant_frame.target_button:SetPoint("TOPLEFT", self.trade_assistant_frame.frame, "TOPRIGHT")
            self.trade_assistant_frame.target_button:Hide()
            
            self.trade_assistant_frame.name_group:AddChild(self.trade_assistant_frame.name)
            
            self.trade_assistant_frame.class_group = AceGUI:Create("InlineGroup")
            self.trade_assistant_frame.class_group:SetLayout("Flow")
            self.trade_assistant_frame.class_group:SetAutoAdjustHeight(true)
            self.trade_assistant_frame.class = AceGUI:Create("Label")
            self.trade_assistant_frame.class:SetJustifyV("CENTER")
            self.trade_assistant_frame.class_group:AddChild(self.trade_assistant_frame.class)
            
            self.trade_assistant_frame.guild_group = AceGUI:Create("InlineGroup")
            self.trade_assistant_frame.guild_group:SetLayout("Flow")
            self.trade_assistant_frame.guild_group:SetAutoAdjustHeight(true)
            self.trade_assistant_frame.guild = AceGUI:Create("Label")
            self.trade_assistant_frame.guild_group:AddChild(self.trade_assistant_frame.guild)
            
            self.trade_assistant_frame.group_group = AceGUI:Create("InlineGroup")
            self.trade_assistant_frame.group_group:SetLayout("Flow")
            self.trade_assistant_frame.group_group:SetAutoAdjustHeight(true)
            self.trade_assistant_frame.group = AceGUI:Create("Label")
            self.trade_assistant_frame.group_label = AceGUI:Create("Label")
            self.trade_assistant_frame.group_label:SetText("Group / Raid")
            self.trade_assistant_frame.group_group:AddChild(self.trade_assistant_frame.group_label)
            self.trade_assistant_frame.group_group:AddChild(self.trade_assistant_frame.group)
            
            self.trade_assistant_frame:AddChild(self.trade_assistant_frame.name_group)
            self.trade_assistant_frame:AddChild(self.trade_assistant_frame.class_group)
            self.trade_assistant_frame:AddChild(self.trade_assistant_frame.guild_group)
            
            self.trade_assistant_frame:AddChild(self.trade_assistant_frame.group_group)
            self.trade_assistant_frame:Hide()
        else
            self:Print("build_UI - trade_assistant_frame exists")
        end
    else
        self:Print("build_UI - WOW TradeFrame does not exists")
    end
end

function WhoTrades:OnInitialize()
    -- Code that you want to run when the addon is first loaded goes here.
    self:Print("OnInitialize")
    self.enabled = true -- get it from config
    self.trading_with = nil
    self.trader_name = ""
    self.trader_rank = 0
    self.trader_level = 0
    self.trader_localized_class = ""
    self.trader_class_name = ""
    self.trader_guild_name = ""
    self.trader_guild_rank_text = ""
    self.trader_guild_rank_nb = 0
    self.trader_group_number = 0
    
    self:build_UI()
    
end

function WhoTrades:TRADE_SHOW(...)
    self:Print("TRADE_SHOW event")
    self.trading_with = TradeFrameRecipientNameText:GetText()
    self:build_UI()
    self:OnShowTradeFrame()
end

function WhoTrades:PLAYER_TARGET_CHANGED(...)
    self:Print("PLAYER_TARGET_CHANGED event")
    if self.trading_with then
        local target_name = UnitName("target")
        self:Print(format("PLAYER_TARGET_CHANGED event (trading with % s, target is % s)", self.trading_with, target_name))
        if target_name == self.trading_with then
            self:Print("Trader and target are equals")
            self:OnShowTradeFrame()
            self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        end
    else
        self:Print("PLAYER_TARGET_CHANGED event (trading with NOONE ????)")
    end
end

function WhoTrades:TRADE_CLOSED(...)
    self:Print("TRADE_CLOSED event")
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self.trading_with = nil
    self:OnHideTradeFrame()
end
