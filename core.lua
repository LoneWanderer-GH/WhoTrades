local WhoTrades = LibStub("AceAddon-3.0"):NewAddon("WhoTrades", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
_G["WhoTrades"] = WhoTrades
local TradeFrame = TradeFrame
local TradeFrameRecipientNameText = TradeFrameRecipientNameText
local pairs, format, unpack, print = pairs, format, unpack, print
local RAID_CLASS_COLORS, CLASS_ICON_TCOORDS = RAID_CLASS_COLORS, CLASS_ICON_TCOORDS
local CreateFrame = CreateFrame
local _, UnitClass, UnitName, UnitLevel, UnitIsPlayer = UnitClassBase, UnitClass, UnitName, UnitLevel, UnitIsPlayer
local _, GetGuildInfo = UnitIsInMyGuild, GetGuildInfo
local UnitInParty, _, UnitInRaid, _, GetRaidRosterInfo = UnitInParty, UnitInOtherParty, UnitInRaid, IsInRaid, GetRaidRosterInfo
local WARRIOR = "WARRIOR"
local MAGE = "MAGE"
local ROGUE = "ROGUE"
local DRUID = "DRUID"
local HUNTER = "HUNTER"
local SHAMAN = "SHAMAN"
local PRIEST = "PRIEST"
local WARLOCK = "WARLOCK"
local PALADIN = "PALADIN"
-- local WhoTradesDB = nil

-- local class_icons_texture_path = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local texture_path_index = {
    [WARRIOR] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:0:64:0:64|t",
    [MAGE] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:64:128:0:64|t",
    [ROGUE] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:128:196:0:64|t",
    [DRUID] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:196:256:0:64|t",
    [HUNTER] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:0:64:64:128|t",
    [SHAMAN] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:64:128:64:128|t",
    [PRIEST] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:128:196:64:128|t",
    [WARLOCK] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:196:256:64:128|t",
    [PALADIN] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:0:64:128:196|t",

}

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
    local localized_class, class_name, _ --[[classIndex]] = UnitClass(unit_id)
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
    self.trader_group_kind = "Party"
end

function WhoTrades:get_player_infos_from_raid()
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
    self.trader_group_kind = "Raid"
end

function WhoTrades:get_player_infos_from_target()
    local localized_class, class_name, _ --[[classIndex]] = UnitClass("target")
    local level = UnitLevel("target")
    local rank, group_number = nil, nil
    local guild_name, guild_rank_text, guild_rank_nb = GetGuildInfo("target")
    self.trader_name = self.trading_with
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
        elseif is_in_player_group then
            self:Print("get_player_infos - in group !")
            self:get_player_infos_from_group()
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

local function build_class_color_str(class_name)
    local class_color_str = "|r"
    if class_name then
        class_color_str = format("|c%s", RAID_CLASS_COLORS[class_name].colorStr)
    end
    return class_color_str
end

local function build_level_str(level)
    local level_str = "|r[??]|r"
    if level then
        level_str = format("|r[%02d]|r", level)
    end
    return level_str
end

local function build_name_str(name, coloring_str)
    local name_str = "|r?|r"
    if name then
        name_str = format("%s%s|r", coloring_str, name)
    end
    return name_str
end

--[[local function build_class_texture_path(class_name)
    return texture_path_index[class_name]
end--]]

local function build_guild_str(guild_name, guild_rank_text, guild_rank_nb)
    local guild_str = "no guild info"
    if guild_name then
        guild_str = format(" %s [%s, %d]", guild_name, guild_rank_text, guild_rank_nb)
    end
    return guild_str
end

local function build_grouping_status_str(group_kind, group_number)
    local grouping_str = "Wanderer"
    if group_kind then
        -- either a group
        local g = "(mine)"
        if group_number then
            -- a raid
            g = format("group %d", group_number)
        end
        grouping_str = format("%s %s", group_kind, g)
    end
    return grouping_str
end

function WhoTrades:ResetTraderData()
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
end

function WhoTrades:OnShowTradeFrame()
    self:Print("OnShowTradeFrame")
    if self.trade_assistant_frame then
        self:Print("OnShowTradeFrame - addon frame exists")
        if self.trading_with then
            --
            local mtext = format("/target %s", self.trading_with) -- \n/WT_OnShowTradeFrame
            self.trade_assistant_frame.target_button:SetAttribute("macrotext", mtext)
            --
            self:get_player_infos()
            --
            local class_color_str = build_class_color_str(self.trader_class_name)
            local level_str = build_level_str(self.trader_level)
            local name_str = build_name_str(self.trading_with, class_color_str)
            local texture_path_str = texture_path_index[self.trader_class_name] or "shit !"-- build_class_texture_path(self.trader_class_name)
            local full_trader_str = format("%s %s %s %s", level_str, texture_path_str, name_str, self.trader_class_name)
            local guild_str = build_guild_str(self.trader_guild_name, self.trader_guild_rank_text, self.trader_guild_rank_nb)
            local grouping_str = build_grouping_status_str(self.trader_group_kind, self.trader_group_number)
            --
            self.trade_assistant_frame.name:SetText(full_trader_str)
            self.trade_assistant_frame.guild:SetText(guild_str)
            self.trade_assistant_frame.group_label:SetText(grouping_str)
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
            --self.trade_assistant_frame.name:SetTexT0
            -- heavily inspired from WoWPro
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

            --[[self.trade_assistant_frame.class_group = AceGUI:Create("InlineGroup")
            self.trade_assistant_frame.class_group:SetLayout("Flow")
            self.trade_assistant_frame.class_group:SetAutoAdjustHeight(true)
            self.trade_assistant_frame.class = AceGUI:Create("Label")
            self.trade_assistant_frame.class:SetJustifyV("CENTER")
            self.trade_assistant_frame.class_group:AddChild(self.trade_assistant_frame.class)--]]

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
            --[[self.trade_assistant_frame:AddChild(self.trade_assistant_frame.class_group)--]]
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

    --[[    -- fill dict <class, chat texture string>
    -- build it once and for all
    for class_name, class_coords in pairs(CLASS_ICON_TCOORDS) do
        -- texture_path_index[class_name] = format("|T%s:%d:0:0:0:0:0:%f:%f:%f:%f|t", class_icons_texture_path, 0, unpack(class_coords))
        texture_path_index[class_name] = format("|T%s:0::0:0:256:256:%f:%f:%f:%f|t", class_icons_texture_path, unpack(class_coords))
        -- self:Print(format("Class %s, coords %-3.2f,%-3.2f,%-3.2f,%-3.2f", class_name, unpack(class_coords)))
        --self:Print(format("Class %s : %s:%d::::::%f:%f:%f:%f",class_name, class_icons_texture_path, 0, unpack(class_coords)))
        self:Print(format("Class %s %s", class_name, texture_path_index[class_name]))
    end--]]

    -- texture_path_index[WARRIOR] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:0:64:0:64|t"
    -- texture_path_index[MAGE]    = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:64:128:0:64|t"
    -- texture_path_index[ROGUE]   = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:128:196:0:64|t"
    -- texture_path_index[DRUID]   = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:196:256:0:64|t"
    -- texture_path_index[HUNTER]  = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:0:64:64:128|t"
    -- texture_path_index[SHAMAN]  = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:64:128:64:128|t"
    -- texture_path_index[PRIEST]  = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:128:196:64:128|t"
    -- texture_path_index[WARLOCK] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:196:256:64:128|t"
    -- texture_path_index[PALADIN] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:0:64:128:196|t"

    self.enabled = true -- get it from config
    self:ResetTraderData()

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
    self:ResetTraderData()
end
