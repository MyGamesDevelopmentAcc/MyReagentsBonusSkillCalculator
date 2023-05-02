local addonName, AddonNS = ...
local GS = LibStub("MyLibrary_GUI");

--- @type WowList
local WowList = LibStub("WowList-1.5");

AddonNS.gui = {};

local self = AddonNS.gui;
local gui = self;



--self.mainFrame = GS:CreateSimpleFrame(addonName, 100, 460);

local f = CreateFrame("Frame", frameName, ProfessionsFrame, "SimplePanelTemplate");
f:SetWidth(280);
f:SetHeight(500);
self.mainFrame = f;
self.mainFrame:SetPoint("TOPLEFT", ProfessionsFrame, "TOPRIGHT", 0, 0);


self.mainFrame.reagentsContainer = CreateFrame("Frame", addonName .. "-reagentsContainer", self.mainFrame)
local containerFrame = self.mainFrame.reagentsContainer;
containerFrame:SetPoint("TOPLEFT", 8, -30)
containerFrame:SetPoint("BOTTOMRIGHT")


local list
do
    -- {
    --     ilvl = ilvl,
    --     tier = tier,
    --     embellishment = binaryModifiersApplied,
    --     missive = binaryModifiersApplied,
    --     illustrousInsightUsed = illustrousInsightUsed,
    --     chance = chance
    --  }
    containerFrame.list = WowList:CreateNew(addonName .. "_spellList",
        {
            columns = {
                {
                    id = "ilvl",
                    name = "ilvl",
                    width = 40,

                    textureDisplayFunction = nil,
                    displayFunction = function(cellData)
                        if (cellData.itemID or cellData.name or cellData.value) then return; end
                        return cellData.ilvl
                    end,
                    sortFunction = function(a, b)
                        return a.ilvl > b.ilvl
                    end,
                },
                {
                    id = "tier",
                    name = "tier",
                    width = 40,

                    textureDisplayFunction = nil,
                    displayFunction = function(cellData)
                        if (cellData.itemID or cellData.name or cellData.value) then return; end
                        --return "tier " .. cellData.tier
                        return " |A:Professions-Icon-Quality-Tier" .. cellData.tier .. ":25:25|a"
                    end,
                    sortFunction = function(a, b)
                        return a.tier > b.tier
                    end,
                },
                {
                    id = "embellishment",
                    name = "embel",
                    width = 40,

                    textureDisplayFunction = nil,
                    displayFunction = function(cellData)
                        return cellData and "x" or ""
                    end,
                    sortFunction = function(a, b)
                        return a and not b
                    end,
                }, {
                id = "missive",
                name = "miss",
                width = 40,

                textureDisplayFunction = nil,
                displayFunction = function(cellData)
                    return cellData and "x" or ""
                end,
                sortFunction = function(a, b)
                    return a and not b
                end,
            }, {
                id = "illustrousInsightUsed",
                name = "illust",
                width = 40,

                textureDisplayFunction = nil,
                displayFunction = function(cellData)
                    if (cellData.itemID or cellData.name or cellData.value) then return; end
                    return cellData.illustrousInsightUsed and "x" or ""
                end,
                sortFunction = function(a, b)
                    return a.illustrousInsightUsed and not b.illustrousInsightUsed
                end,
            }, {
                id = "chance",
                name = "%",
                width = 40,

                textureDisplayFunction = nil,
                displayFunction = function(cellData)
                    if (cellData.itemID or cellData.name or cellData.value) then return; end

                    return (math.floor(cellData.chance * 1000 + 0.5) / 10) .. "%"
                end,
                sortFunction = function(a, b)
                    return a.chance > b.chance
                end,
            },

            },
            rows = 20,
            height = 420
        }, containerFrame);

    list = containerFrame.list;
    list:SetPoint('TOPLEFT', containerFrame, 'TOPLEFT', 0, 0);
    list:SetMultiSelection(false);
end

function self:DisplayData(toDisplay)
    list:RemoveAll()
    for i = 1, #toDisplay, 1 do
        local embelishment = false;
        for _, binaryModifier in ipairs(toDisplay[i].binaryModifiers) do
            if (binaryModifier.name =="E" and binaryModifier.used) then embelishment = true;
            end
        end
        local missive = false;
        for _, binaryModifier in ipairs(toDisplay[i].binaryModifiers) do
            if (binaryModifier.name =="M" and binaryModifier.used) then missive = true;
            end
        end

        list:AddData({ toDisplay[i], toDisplay[i], embelishment, missive, toDisplay[i], toDisplay[i], toDisplay[i] });
        list:Sort(1, function(a, b)
            return a.tier < b.tier
        end)
        list:Sort(3, function(a, b)
            return a and not b
        end)
        list:Sort(4, function(a, b)
            return a and not b
        end)
        list:Sort(6, function(a, b)
            return a.chance > b.chance
        end)
        list:Sort(1, function(a, b)
            return a.ilvl > b.ilvl
        end)
    end
    list:UpdateView()
end
