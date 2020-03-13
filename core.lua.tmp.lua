local WhoTrades = LibStub("AceAddon-3.0"):NewAddon("WhoTrades", "AceEvent-3.0", "AceConsole-3.0") --, 'LibWho-2.0') --, "AceGUI-3.0")
--LibStub:GetLibrary('LibWho-2.0'):Embed(WhoTrades)
local AceGUI = LibStub("AceGUI-3.0")
--local WhoTrades = WhoTrades
_G["WhoTrades"] = WhoTrades
local TradeFrame = TradeFrame
local TradeFrameRecipientNameText = TradeFrameRecipientNameText
--local CreateFrame = CreateFrame
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitClassBase, UnitClass = UnitClassBase, UnitClass-- Returns a unit's class
local UnitIsInMyGuild, GetGuildInfo = UnitIsInMyGuild, GetGuildInfo
local UnitInParty, UnitInOtherParty, UnitInRaid, IsInRaid, GetRaidRosterInfo = UnitInParty, UnitInOtherParty, UnitInRaid, IsInRaid, GetRaidRosterInfo
-- local WhoTradesDB = nil

function WhoTrades:OnEnable()
    -- Called when the addon is enabled
    self:Print("OnEnable")
    self.enabled = true
    WhoTrades:RegisterEvent("TRADE_SHOW")
    WhoTrades:RegisterEvent("TRADE_CLOSED")
    --[[WhoTrades:RegisterEvent("WHO_LIST_UPDATE")
    WhoTrades:RegisterEvent("CHAT_MSG_SYSTEM")--]]
end

function WhoTrades:OnDisable()
    -- Called when the addon is disabled
    self:Print("OnDisable")
    self.enabled = false
    --WhoTrades:UnRegisterEvent("ADDON_LOADED")
    WhoTrades:UnregisterEvent("TRADE_SHOW")
    WhoTrades:UnregisterEvent("TRADE_CLOSED")
    WhoTrades:UnregisterEvent("PLAYER_TARGET_CHANGED")
    --[[WhoTrades:UnregisterEvent("WHO_LIST_UPDATE")
    WhoTrades:UnregisterEvent("CHAT_MSG_SYSTEM")--]]
end

--[[function UserDataReturned(user, time)
 
end--]]

function WhoTrades:get_player_infos_from_group()
    local raid_index = UnitInRaid(self.trading_with)
    -- luacheck: ignore zone online isDead role isML -- save for future use ?
    local name, rank, group_number, level, localized_class, class_name, zone, online, isDead, role, isML = GetRaidRosterInfo(raid_index)
    local guild_name, guild_rank_text, guild_rank_nb = GetGuildInfo(self.trading_with)
    --self:Print(format("get_player_infos_from_group - %s - %s - %02d - %s (%s) - %s %s (%02d) - §01d", name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_number))
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

function WhoTrades:get_player_infos_from_pvp_raid()
    local raid_index = UnitInRaid(self.trading_with)
    -- luacheck: ignore zone online isDead role isML -- save for future use ?
    local name, rank, group_number, level, localized_class, class_name, zone, online, isDead, role, isML = GetRaidRosterInfo(raid_index)
    local guild_name, guild_rank_text, guild_rank_nb = GetGuildInfo(self.trading_with)
    --self:Print(format("get_player_infos_from_pvp_raid - %s - %s - %02d - %s (%s) - %s %s (%02d) - §01d", name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_number))
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

--[[function WhoTrades:get_player_infos_from_own_guild(unit_name)
    -- local name, rank, group_number, level, localized_class, class_name, zone, online, isDead, role, isML
    --self:Print(format("get_player_infos_from_own_guild - %s - %s - %02d - %s (%s) - %s %s (%02d) - §01d", name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_number))
end--]]

function WhoTrades:get_player_infos_from_wild_world(unit_name)
    --local name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_number = "", 0, 0, "", "", "", "", 0, 0
    -- unit is necessarily in trade range
    -- target it
    if not UnitAffectingCombat("player") then
        local target_name = UnitName("target")
        if target_name == unit_name then
            --self:RegisterEvent("PLAYER_TARGET_CHANGED")
            --self.trade_assistant_frame.target_button:SetDisabled(true)
            self.trade_assistant_frame.target_button:Hide()
            -- name = unit_name
            -- luacheck: ignore classIndex -- save for future use ?
            localized_class, class_name, classIndex = UnitClass("target")
            level = UnitLevel("target")
            rank, group_number = nil, nil
            guild_name, guild_rank_text, guild_rank_nb = GetGuildInfo("target")
        else
            --name = unit_name
            -- luacheck: ignore classIndex -- save for future use ?
            localized_class, class_name, classIndex = "", "", 0
            level = 0
            rank, group_number = "", ""
            guild_name, guild_rank_text, guild_rank_nb = "", "", 0
            self:Print(format("Not targeting unit %s (targetting %s), cannot fetch infos", unit_name, target_name))
            self.trade_assistant_frame.target_button:Show()
            --self.trade_assistant_frame.target_button:SetDisabled(false)
        end
    else
        self.trade_assistant_frame.target_button:Hide()
        --self.trade_assistant_frame.target_button:SetDisabled(true)
        self:Print("Player is in combat. Don't try to target the other player.")
    end
    --return name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_number
    self.trader_name = unit_name
    self.trader_rank = rank
    self.trader_level = level
    self.trader_localized_class = localized_class
    self.trader_class_name = class_name
    self.trader_guild_name = guild_name
    self.trader_guild_rank_text = guild_rank_text
    self.trader_guild_rank_nb = guild_rank_nb
    self.trader_group_number = group_number
end

function WhoTrades:get_player_infos()
    --local name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_kind, group_number = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
    -- local is_in_my_guild = UnitIsInMyGuild(unit_name)
    local is_in_player_raid = UnitInRaid(self.trading_with)
    local is_in_player_group = UnitInParty(self.trading_with)
    
    if is_in_player_raid then
        --name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_number =  --
        self:get_player_infos_from_raid()
        self.trader_group_kind = "raid"
    elseif is_in_player_group then
        --name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_number =
        self:get_player_infos_from_group()
        self.trader_group_kind = "party"
    else
        -- name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_number =
        --self:get_player_infos_from_wild_world(unit_name)
        self:RegisterEvent("PLAYER_TARGET_CHANGED")
        self:Print(format("Trader (%s) is not in group or raid. Cannot fetch info. Please try to target it manually", unit_name))
    end
    --return name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_kind, group_number
end

function WhoTrades:OnShowTradeFrame()
    self:Print("OnShowTradeFrame")
    if self.trade_assistant_frame then
        self:Print("OnShowTradeFrame - addon frame exists")
        --local other_player_name = TradeFrameRecipientNameText:GetText()
        
        local mtext = format("/target %s", self.trading_with) -- \n/WT_OnShowTradeFrame
        self.trade_assistant_frame.target_button:SetAttribute("macrotext", mtext)
        
        --local name, rank, level, localized_class, class_name, guild_name, guild_rank_text, guild_rank_nb, group_kind, group_number =
        self:get_player_infos()
        
        -- NAME labels
        self.trade_assistant_frame.name:SetText(format("%s (%02d)", self.trader_name, self.trader_level))
        
        -- CLASS labels
        local texture_path = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
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
            if class_color then
                self.trade_assistant_frame.class:SetColor(class_color.r, class_color.g, class_color.b)
            else
                self.trade_assistant_frame.class:SetColor(0, 0, 0)
            end
        else
            self.trade_assistant_frame.class:SetColor(0, 0, 0)
        end
        
        -- GUILD labels
        if self.trader_guild_name then
            self.trade_assistant_frame.guild:SetText(format("%s (%s, %d)", self.trader_guild_name, self.trader_guild_rank_text, self.trader_guild_rank_nb))
        end
        
        if self.trader_group_kind then
            if self.trader_group_kind == "party" then
                self.trade_assistant_frame.group_label:SetText("Group")
                self.trade_assistant_frame.group:SetText("mine")
            elseif self.trader_group_kind == "raid" then
                self.trade_assistant_frame.group_label:SetText("Raid")
                if self.trader_group_number and self.trader_group_number > 0 then
                    self.trade_assistant_frame.group:SetText(format("Raid, group #§01dd", self.trader_group_number))
                else
                    self.trade_assistant_frame.group:SetText("None")
                end
            else
                self.trade_assistant_frame.group_label:SetText("Group/Raid")
                self.trade_assistant_frame.group:SetText("None")
            end
        else
            self.trade_assistant_frame.group_label:SetText("Group/Raid")
            self.trade_assistant_frame.group:SetText("None")
        end
        --
        self.trade_assistant_frame:Show()
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
    --local other_player_name = TradeFrameRecipientNameText:GetText()
    if self.trading_with then
        if UnitName("target") == self.trading_with then
            self:get_player_infos_from_wild_world(self.trading_with)
            self:UnregisterEvent("PLAYER_TARGET_CHANGED")
        end
    end
end

function WhoTrades:TRADE_CLOSED(...)
    self:Print("TRADE_CLOSED event")
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self.trading_with = nil
    -- self.trade_assistant_frame:Hide()
    self:OnHideTradeFrame()
end

