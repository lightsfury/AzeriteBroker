local _, addon = ...;

AzeriteBroker = LibStub("AceAddon-3.0"):NewAddon(addon, "AzeriteBroker", "AceEvent-3.0");

local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteBroker");

local factionGroup = UnitFactionGroup("player");

local db;
local defaults = {
    profile = {
        DataStream = {
            Color = {
				r = 1.0,
				g = 1.0,
				b = 1.0,
			},
            Show = {
				Level = true,
				Remaining = true,
				Percent = true,
            },
        },
    },
};

addon.LDBObject = {
    type = 'data source',
    icon = [[Interface\PVPFrame\PVP-Currency-]] .. factionGroup .. [[.blp]],
    label = "AzeriteBroker",
    text = "Loading...",
    tocname = "AzeriteBroker",
    OnClick = function(self, button)
        -- if button == "LeftButton" then
            -- ToggleCharacter("ReputationFrame");
        -- end
        if button == "RightButton" then
            addon:OpenConfig();
        end
    end,
};

addon.Options = {
    type = 'group',
    name = "AzeriteBroker",
    get = function(info)
        return db[ info[#info] ];
    end,
    set = function(info, value)
        db[ info[#info] ] = value;
        addon:UpdateText();
    end,
    childGroups = "tab",
    args = {
        DataStream = {
            type = 'group',
            order = 2,
            name = L["DataBroker"],
            desc = L["DataBroker display options"],
            get = function(info)
                return db.DataStream[ info[#info] ];
            end,
            set = function(info, value)
                db.DataStream[ info[#info] ] = value;
                addon:UpdateText();
            end,
            args = {
                Show = {
                    type = 'group',
                    order = 1,
                    guiInline = true,
                    name = L["Output control"],
                    desc = L["Control what is shown in the DataBroker output."],
                    get = function(info)
                        return db.DataStream.Show[ info[#info] ];
                    end,
                    set = function(info, value)
                        db.DataStream.Show[ info[#info] ] = value;
                        addon:UpdateText();
                    end,
                    args = {
						Level = {
							type = 'toggle',
							order = 1,
							name = L["Level"],
							desc = L["Show the level of the Heart of Azeroth"]
						},
						Remaining = {
							type = 'toggle',
							order = 2,
							name = L["Remaining"],
							desc = L["Show the amount of Azerite Power to reach the next level of the Heart of Azeroth"]
						},
						Percent = {
							type = 'toggle',
							order = 3,
							name = L["Percent"],
							desc = L["Show the amount of Azerite Power remaining as a percentage"]
						},
                    },
                },
                Color = {
                    type = 'color',
                    order = 1,
                    name = L["Text color"],
                    desc = L["Color used for the LibDataBroker text"],
                    hasAlpha = false,
                },
            },
        },
    },
};

function addon:OnInitialize()
    self.Vars = LibStub("AceDB-3.0"):New("AzeriteBrokerDB", defaults);
    
    self.Vars.RegisterCallback(self, "OnProfileChanged", "UpdateDB");
    self.Vars.RegisterCallback(self, "OnProfileCopied", "UpdateDB");
    self.Vars.RegisterCallback(self, "OnProfileReset", "UpdateDB");
    
    db = self.Vars.profile;
    
    LibStub("LibDataBroker-1.1"):NewDataObject("AzeriteBroker", self.LDBObject);
end

function addon:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateText");
	self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED", "UpdateText");
	self:RegisterEvent("CVAR_UPDATE", "UpdateText");
	
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("AzeriteBroker", self.Options);
	
	self.OptionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AzeriteBroker", "AzeriteBroker", nil);
    self.Options.args.Profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.Vars);
end

function addon:OnDisable()
    self:UnregisterAllEvents();
end

function addon:UpdateDB()
	self:UpdateText();
end

function addon:UpdateText()
	local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem();
	
	--[===[
		{1}: Level
		{2}: Current progress
		{3}: XP at next level
		{4}: Remaining
		{5}: Percent
	--]===]
	
	local str = "{2}/{3}";
	
    if db.DataStream.Show.Level then
        str = L["Level"] .. " {1}," .. str;
    end
	
    if db.DataStream.Show.Remaining then
        str = str .. " ({4})";
    end
	
    if db.DataStream.Show.Percent then
        str = str .. " {5}";
    end
	
	local text = L["Loading..."];
	
	if azeriteItemLocation then
		local level = C_AzeriteItem.GetPowerLevel(azeriteItemLocation);
		local currentXp, nextLevelXp = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation);
		local remainingXp = nextLevelXp - currentXp;
		local percent = currentXp / nextLevelXp;
		
		text = self:Format(str, level, currentXp, nextLevelXp, remainingXp, percent);
		
		local color = db.DataStream.Color;
		
		text = string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text);
	end
	
	self.LDBObject.text = text;
end

function addon:OpenConfig()
    InterfaceOptionsFrame_OpenToCategory(self.OptionsFrame);
end

do
    local format_args = {};

    function addon:Format(msg, ...)
        local limit = select("#", ...);
        for i = 1, limit do
            format_args[i] = select(i, ...);
        end
        
        local str = string.gsub(msg, "{(%d+)}", function(d)
            return tostring(format_args[tonumber(d)]);
        end);
        wipe(format_args);
        return str;
    end
end