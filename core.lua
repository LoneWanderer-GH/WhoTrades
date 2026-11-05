local WhoTrades = LibStub("AceAddon-3.0"):NewAddon("WhoTrades", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local _G = _G
_G["WhoTrades"] = WhoTrades
local TradeFrame = TradeFrame
local TradeFrameRecipientNameText = TradeFrameRecipientNameText
local pairs, format, unpack, print = pairs, format, unpack, print
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local CreateFrame = CreateFrame
local _, UnitClass, UnitName, UnitLevel, UnitIsPlayer = UnitClassBase, UnitClass, UnitName, UnitLevel, UnitIsPlayer
local _, GetGuildInfo = UnitIsInMyGuild, GetGuildInfo
local GetRaidRosterInfo = GetRaidRosterInfo
local floor = math.floor
local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS

local texture_path_index = {}
if CLASS_ICON_TCOORDS then
    for class_name, coords in pairs(CLASS_ICON_TCOORDS) do
        if coords[1] and coords[2] and coords[3] and coords[4] then
            texture_path_index[class_name] = format(
                "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:%d:%d:%d:%d|t",
                floor(coords[1] * 256 + 0.5),
                floor(coords[2] * 256 + 0.5),
                floor(coords[3] * 256 + 0.5),
                floor(coords[4] * 256 + 0.5)
            )
        end
    end
end

local DEFAULT_GUILD_TEXT = "(no guild info)"
local DEFAULT_GROUP_TEXT = "(no grouping info)"

local function create_information_label(parent, name, text)
    local label = CreateFrame("Frame", name, parent)
    local font_string = label:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    font_string:SetPoint("CENTER", label, "CENTER", 0, 0)
    font_string:SetText(text)
    font_string:SetJustifyH("LEFT")
    label.fs = font_string
    return label
end

local function find_group_member(name)
    local function matches_unit(unit_id)
        local unit_name, realm_name = UnitName(unit_id)
        return unit_name == name or (realm_name and name == unit_name .. "-" .. realm_name)
    end

    for raid_index = 1, 40 do
        local unit_id = "raid" .. raid_index
        if matches_unit(unit_id) then
            return unit_id, raid_index, "Raid"
        end
    end

    for party_index = 1, 4 do
        local unit_id = "party" .. party_index
        if matches_unit(unit_id) then
            return unit_id, nil, "Party"
        end
    end
end

function WhoTrades:OnEnable()
    -- Called when the addon is enabled
    --self:Print("OnEnable")
    self.enabled = true
    WhoTrades:RegisterEvent("TRADE_SHOW")
    WhoTrades:RegisterEvent("TRADE_CLOSED")
end

function WhoTrades:OnDisable()
    -- Called when the addon is disabled
    --self:Print("OnDisable")
    self.enabled = false
    WhoTrades:UnregisterEvent("TRADE_SHOW")
    WhoTrades:UnregisterEvent("TRADE_CLOSED")
    WhoTrades:UnregisterEvent("PLAYER_TARGET_CHANGED")
end

function WhoTrades:get_player_infos_from_group(unit_id)
    local localized_class, class_name = UnitClass(unit_id)
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

function WhoTrades:get_player_infos_from_raid(raid_index, unit_id)
    -- luacheck: ignore zone online isDead role isML -- save for future use ?
    local name, rank, group_number, level, localized_class, class_name, zone, online, isDead, role, isML = GetRaidRosterInfo(raid_index)
    local guild_name, guild_rank_text, guild_rank_nb = GetGuildInfo(unit_id)
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
    --self:Print("get_player_infos")
    local data_found = false
    if self.trading_with then
        --self:Print("get_player_infos - Trying to fetch from group or raid")
        local group_unit, raid_index, group_kind = find_group_member(self.trading_with)
        self.button_target_trader:Hide()
        if group_unit and group_kind == "Raid" then
            --self:Print("get_player_infos - in raid !")
            self:get_player_infos_from_raid(raid_index, group_unit)
            data_found = true
        elseif group_unit then
            --self:Print("get_player_infos - in group !")
            self:get_player_infos_from_group(group_unit)
            data_found = true
        else
            --self:Print("get_player_infos - not in raid nor group, trying from target")
            self.button_target_trader:Show()
            if UnitIsPlayer("target") and UnitName("target") == self.trading_with then
                --self:Print("get_player_infos - got it from target")
                self:get_player_infos_from_target()
                self.button_target_trader:Hide()
                data_found = true
            else
                data_found = false
                self:RegisterEvent("PLAYER_TARGET_CHANGED")
                --self:Print(format("Trader (%s) is not in target, group or raid. Cannot fetch info. Please try to target it manually", self.trading_with))
            end
        end
    else
        --self:Print("Trader is nil ????")
    end
    return data_found
end

local function build_class_color_str(class_name)
    local class_color_str = "|r"
    local class_color = class_name and RAID_CLASS_COLORS[class_name]
    if class_color then
        local color_str = class_color.colorStr
        if not color_str and class_color.r and class_color.g and class_color.b then
            color_str = format(
                "ff%02x%02x%02x",
                floor(class_color.r * 255 + 0.5),
                floor(class_color.g * 255 + 0.5),
                floor(class_color.b * 255 + 0.5)
            )
        end
        if color_str then
            class_color_str = format("|c%s", color_str)
        end
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
        guild_str = format("%s [%s, %d]", guild_name, guild_rank_text, guild_rank_nb)
    end
    return format("|cFF64FB64%s|r", guild_str)
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
    --self:Print("OnShowTradeFrame")
    if self.simple_group_trade_assistant then
        --self:Print("OnShowTradeFrame - addon frame exists")

        if self.trading_with then
            --
            local mtext = format("/target %s", self.trading_with) -- \n/WT_OnShowTradeFrame
            self.button_target_trader:SetAttribute("macrotext", mtext)
            --
            local full_trader_str = self.trading_with
            local guild_str = DEFAULT_GUILD_TEXT
            local grouping_str = DEFAULT_GROUP_TEXT
            local found = self:get_player_infos()
            --
            if found then
                local class_color_str = build_class_color_str(self.trader_class_name)
                local level_str = build_level_str(self.trader_level)
                local name_str = build_name_str(self.trading_with, class_color_str)
                local texture_path_str = texture_path_index[self.trader_class_name] or "|TInterface\\Icons\\INV_Misc_QuestionMark:14|t"
                full_trader_str = format("%s %s %s %s", level_str, texture_path_str, name_str, self.trader_class_name)
                guild_str = build_guild_str(self.trader_guild_name, self.trader_guild_rank_text, self.trader_guild_rank_nb)
                grouping_str = build_grouping_status_str(self.trader_group_kind, self.trader_group_number)
            end
            self.simple_group_trade_assistant.label_name_informations.fs:SetText(full_trader_str)
            self.simple_group_trade_assistant.label_guild_informations.fs:SetText(guild_str)
            self.simple_group_trade_assistant.label_group_informations.fs:SetText(grouping_str)

            --
            self.simple_group_trade_assistant.label_name_informations:Show()
            self.simple_group_trade_assistant.label_guild_informations:Show()
            self.simple_group_trade_assistant.label_group_informations:Show()
            self.simple_group_trade_assistant:Show()
        else
            --self:Print("OnShowTradeFrame - Trading with undefined ?! (recipient text is: "..TradeFrameRecipientNameText:GetText() .. ")")
        end
    else
        --self:Print("OnShowTradeFrame - No assitant frame ?!")
    end
end

function WhoTrades:OnHideTradeFrame()
    --self:Print("OnHideTradeFrame")
    if self.simple_group_trade_assistant then
        self.button_target_trader:Hide()
        self.simple_group_trade_assistant:Hide()
        self.simple_group_trade_assistant.label_name_informations:Hide()
        self.simple_group_trade_assistant.label_guild_informations:Hide()
        self.simple_group_trade_assistant.label_group_informations:Hide()
    else
        if self.enabled then
            --self:Print("OnHideTradeFrame - No assistant frame ?!")
        else
            --self:Print("OnHideTradeFrame - Addon is disabled, doing nothing")
        end
    end
end

function WhoTrades:build_UI()
    --self:Print("build_UI")
    if TradeFrame then
        --self:Print("build_UI - WOW TradeFrame exists")
        if not self.simple_group_trade_assistant then
            --self:Print("build_UI - trade_assistant_frame does not exists, build it")

            self.simple_group_trade_assistant = CreateFrame("frame", "WhoTrades", TradeFrame)
            self.simple_group_trade_assistant:SetPoint("TOPRIGHT", TradeFrameCloseButton, "BOTTOMRIGHT", 2, 6)
            self.simple_group_trade_assistant:SetWidth(TradeFrameRecipientNameText:GetWidth() * 2)
            self.simple_group_trade_assistant:SetHeight(TradeRecipientItem1ItemButton:GetHeight() + 5)

            self.simple_group_trade_assistant.label_name_informations = create_information_label(
                self.simple_group_trade_assistant,
                "WhoTrades_name",
                "?"
            )
            self.simple_group_trade_assistant.label_guild_informations = create_information_label(
                self.simple_group_trade_assistant,
                "WhoTrades_guild",
                DEFAULT_GUILD_TEXT
            )
            self.simple_group_trade_assistant.label_group_informations = create_information_label(
                self.simple_group_trade_assistant,
                "WhoTrades_group",
                DEFAULT_GROUP_TEXT
            )

            self.simple_group_trade_assistant.label_name_informations:SetPoint("TOPRIGHT", TradeFrameCloseButton, "BOTTOMRIGHT", 0,0)
            self.simple_group_trade_assistant.label_name_informations:SetWidth(TradeFrameRecipientNameText:GetWidth() * 2)
            self.simple_group_trade_assistant.label_name_informations:SetHeight(TradeFrameRecipientNameText:GetHeight())

            self.simple_group_trade_assistant.label_guild_informations:SetPoint("TOP", self.simple_group_trade_assistant.label_name_informations, "BOTTOM", 0, 0)
            self.simple_group_trade_assistant.label_guild_informations:SetWidth(self.simple_group_trade_assistant.label_name_informations:GetWidth())
            self.simple_group_trade_assistant.label_guild_informations:SetHeight(self.simple_group_trade_assistant.label_name_informations:GetHeight())

            self.simple_group_trade_assistant.label_group_informations:SetPoint("TOP", self.simple_group_trade_assistant.label_guild_informations, "BOTTOM", 0, 0)
            self.simple_group_trade_assistant.label_group_informations:SetWidth(self.simple_group_trade_assistant.label_name_informations:GetWidth())
            self.simple_group_trade_assistant.label_group_informations:SetHeight(self.simple_group_trade_assistant.label_name_informations:GetHeight())

            -- heavily inspired from WoWPro
            --self.button_target_trader = CreateFrame("Button", "WhoTrades_targetbutton", self.simple_group_trade_assistant.frame, "SecureActionButtonTemplate")
            if not self.button_target_trader then
                self.button_target_trader = CreateFrame("Button", "WhoTrades_targetbutton", TradeFrame, "SecureActionButtonTemplate")
                self.button_target_trader:RegisterForClicks("AnyUp")
                self.button_target_trader.SetTarget = function () self.button_target_trader:SetTexture("Interface\\Icons\\Ability_Marksmanship"); end
                self.button_target_trader:SetAttribute("type", "macro")
                self.button_target_trader:SetHeight(32)
                self.button_target_trader:SetWidth(32)
                local targeticon = self.button_target_trader:CreateTexture(nil, "ARTWORK")
                targeticon:SetWidth(36)
                targeticon:SetHeight(36)
                targeticon:SetTexture("Interface\\Icons\\Ability_Marksmanship")
                targeticon:SetAllPoints(self.button_target_trader)

                self.button_target_trader:SetPoint("BOTTOMRIGHT", TradeFrame, "TOPRIGHT")
            end
            self.button_target_trader:Hide()
            self.simple_group_trade_assistant:Hide()

        else
            --self:Print("build_UI - trade_assistant_frame exists")
        end
    else
        --self:Print("build_UI - WOW TradeFrame does not exists")
    end
end

function WhoTrades:OnInitialize()
    -- Code that you want to run when the addon is first loaded goes here.
    --self:Print("OnInitialize")

    self.enabled = true -- get it from config
    self:ResetTraderData()

    self:build_UI()

end

function WhoTrades:TRADE_SHOW(...)
    --self:Print("TRADE_SHOW event")
    self.trading_with = TradeFrameRecipientNameText:GetText()
    self:build_UI()
    self:OnShowTradeFrame()
end

function WhoTrades:PLAYER_TARGET_CHANGED(...)
    --self:Print("PLAYER_TARGET_CHANGED event")
    if self.trading_with then
        local target_name = UnitName("target")
        --self:Print(format("PLAYER_TARGET_CHANGED event (trading with % s, target is % s)", self.trading_with, target_name))
        if target_name == self.trading_with then
            --self:Print("Trader and target are equals")
            self:build_UI()
            self:OnShowTradeFrame()
            self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        end
    else
        --self:Print("PLAYER_TARGET_CHANGED event (trading with NOONE ????)")
    end
end

function WhoTrades:TRADE_CLOSED(...)
    --self:Print("TRADE_CLOSED event")
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self.trading_with = nil
    self:OnHideTradeFrame()
    self:ResetTraderData()
end
