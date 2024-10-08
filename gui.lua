local addonName, AddonNS = ...
local GS = LibStub("MyLibrary_GUI");

--- @type WowList
local WowList = LibStub("WowList-1.5");

function AddonNS.createGUI()
    AddonNS.gui = {};

    local self = AddonNS.gui;


    --self.mainFrame = GS:CreateSimpleFrame(addonName, 100, 460);

    local f = CreateFrame("Frame", nil, ProfessionsFrame, "SimplePanelTemplate");
    f:SetWidth(520);
    f:SetHeight(500);
    self.mainFrame = f;
    self.mainFrame:SetPoint("TOPLEFT", ProfessionsFrame, "TOPRIGHT", 0, 0);


    self.mainFrame.reagentsContainer = CreateFrame("Frame", addonName .. "-reagentsContainer", self.mainFrame)
    local containerFrame = self.mainFrame.reagentsContainer;
    containerFrame:SetPoint("TOPLEFT", 8, -30)
    containerFrame:SetPoint("BOTTOMRIGHT")


    local list
    do
        containerFrame.list = WowList:CreateNew(addonName .. "_spellList",
            {
                columns = {
                    {
                        id = "basic",
                        name = "basic",
                        width = 200,
                    },
                    -- {
                    --     id = "basicCost",
                    --     name = "basicCost",
                    --     width = 60,
                    -- },
                    -- {
                    --     id = "basicBonusSkill",
                    --     name = "basicBonusSkill",
                    --     width = 40,
                    -- },
                    {
                        id = "mod",
                        name = "mod",
                        width = 50,
                        sortFunction = function(a, b)
                            return a > b
                        end,
                    },
                    {
                        id = "tier",
                        name = "tier",
                        width = 30,
                        sortFunction = function(a, b)
                            return a > b
                        end,
                    },
                    {
                        id = "skill",
                        name = "skill",
                        width = 50,
                        sortFunction = function(a, b)
                            return a > b
                        end,
                    },
                    {
                        id = "difficulty",
                        name = "difficulty",
                        width = 50,
                        sortFunction = function(a, b)
                            return a > b
                        end,
                    },
                    {
                        id = "cost",
                        name = "cost",
                        width = 100,
                        displayFunction = function (val)
                            return val and GetMoneyString(val, true) or ""
                            
                        end,
                        sortFunction = function(a, b)
                            return a > b
                        end,
                    },
                   

                },
                rows = 20,
                height = 420
            }, containerFrame);

        -- containerFrame.list = WowList:CreateNew(addonName .. "_spellList",
        --     {
        --         columns = {
        --             {
        --                 id = "ilvl",
        --                 name = "ilvl",
        --                 width = 40,

        --                 textureDisplayFunction = nil,
        --                 displayFunction = function(cellData)
        --                     if (cellData.itemID or cellData.name or cellData.value) then return; end
        --                     return cellData.ilvl
        --                 end,
        --                 sortFunction = function(a, b)
        --                     return a.ilvl > b.ilvl
        --                 end,
        --             },
        --             {
        --                 id = "itier",
        --                 name = "itier",
        --                 width = 40,

        --                 textureDisplayFunction = nil,
        --                 displayFunction = function(cellData)
        --                     if (cellData.itemID or cellData.name or cellData.value) then return; end
        --                     --return "tier " .. cellData.tier
        --                     return " |A:Professions-Icon-Quality-Tier" .. cellData.tier .. ":25:25|a"
        --                 end,
        --                 sortFunction = function(a, b)
        --                     return a.tier > b.tier
        --                 end,
        --             },
        --             {
        --                 id = "embellishment",
        --                 name = "embel",
        --                 width = 40,

        --                 textureDisplayFunction = nil,
        --                 displayFunction = function(cellData)
        --                     return cellData and "x" or ""
        --                 end,
        --                 sortFunction = function(a, b)
        --                     return a and not b
        --                 end,
        --             }, {
        --             id = "missive",
        --             name = "miss",
        --             width = 40,

        --             textureDisplayFunction = nil,
        --             displayFunction = function(cellData)
        --                 return cellData and "x" or ""
        --             end,
        --             sortFunction = function(a, b)
        --                 return a and not b
        --             end,
        --         },
        --             {
        --                 id = "illustrousInsightUsed",
        --                 name = "illust",
        --                 width = 40,

        --                 textureDisplayFunction = nil,
        --                 displayFunction = function(cellData)
        --                     if (cellData.itemID or cellData.name or cellData.value) then return; end
        --                     return cellData.illustrousInsightUsed and "x" or ""
        --                 end,
        --                 sortFunction = function(a, b)
        --                     return a.illustrousInsightUsed and not b.illustrousInsightUsed
        --                 end,
        --             },
        --             {
        --                 id = "chance",
        --                 name = "%",
        --                 width = 40,

        --                 textureDisplayFunction = nil,
        --                 displayFunction = function(cellData)
        --                     if (cellData.itemID or cellData.name or cellData.value) then return; end

        --                     return (math.floor(cellData.chance * 1000 + 0.5) / 10) .. "%"
        --                 end,
        --                 sortFunction = function(a, b)
        --                     return a.chance > b.chance
        --                 end,
        --             },
        --             {
        --                 id = "diff",
        --                 name = "diff",
        --                 width = 40,

        --                 textureDisplayFunction = nil,
        --                 displayFunction = function(cellData)
        --                     if (cellData.itemID or cellData.name or cellData.value) then return; end

        --                     return cellData.difficulty
        --                 end,
        --                 sortFunction = function(a, b)
        --                     return a.difficulty > b.difficulty
        --                 end,
        --             },
        --             {
        --                 id = "skill",
        --                 name = "skill",
        --                 width = 40,

        --                 textureDisplayFunction = nil,
        --                 displayFunction = function(cellData)
        --                     if (cellData.itemID or cellData.name or cellData.value) then return; end

        --                     return cellData.skill
        --                 end,
        --                 sortFunction = function(a, b)
        --                     return a.skill > b.skill
        --                 end,
        --             },

        --         },
        --         rows = 20,
        --         height = 420
        --     }, containerFrame);

        list = containerFrame.list;
        list:SetPoint('TOPLEFT', containerFrame, 'TOPLEFT', 0, 0);
        list:SetMultiSelection(false);
    end

    function self:DisplayData(dataToDisplay, title)
        self.mainFrame.title:SetText(title);
        list:RemoveAll()
        for i, toDisplay in ipairs(dataToDisplay) do
            -- print(toDisplay.basic,
            -- GetMoneyString(toDisplay.basicCost),
            --     toDisplay.basicBonusSkill,
            --     toDisplay.modyfing,
            --     toDisplay.difficulty,
            --     toDisplay.tier)
            -- local embelishment = false;
            -- local row = {
            --     -- modyfingRequired=,
            --     basic = basicPrint,
            --     basicCost = tier.basicCost,
            --     basicBonusSkill = tier.basicBonusSkill,
            --     modyfing = modyfingCombinationPrint,
            --     -- modyfingDiffIncreased = modyfingDiffIncreased,
            --     -- finishing=,
            --     difficulty = tier.skillThreshold,
            --     tier = tier.tier
            --  }

            list:AddData({ toDisplay.basic,
                -- toDisplay.basicCost,
                -- 
                toDisplay.modyfing,
                -- 
                toDisplay.tier,
                toDisplay.skill,
                toDisplay.difficulty,
                toDisplay.basicCost
            });
            -- -- tier, illu, embel, miss, %, ilvl
            -- list:Sort(1, function(a, b)
            --     return a.tier < b.tier
            -- end)
            -- list:Sort(1, function(a, b)
            --     return not a.illustrousInsightUsed and b.illustrousInsightUsed
            -- end)
            -- list:Sort(3, function(a, b)
            --     return a and not b
            -- end)
            -- list:Sort(4, function(a, b)
            --     return a and not b
            -- end)
            -- list:Sort(6, function(a, b)
            --     return a.chance > b.chance
            -- end)
            -- list:Sort(1, function(a, b)
            --     return a.ilvl > b.ilvl
            -- end)\
            list:Sort(2, function(a, b)
                return a > b
            end)
            list:Sort(3, function(a, b)
                return a > b
            end)
        end
        list:UpdateView()
    end

    self.mainFrame.title = GS.CreateFontString(self.mainFrame, nil, "ARTWORK", "Title", "TOP", self.mainFrame, "TOP", 0,
        -10);
    self.mainFrame.title:SetTextColor(1, 1, 1, 1);

    self.mainFrame:SetHyperlinksEnabled(true)
    self.mainFrame:SetScript("OnHyperlinkClick", function(self, link, text, button)
        SetItemRef(link, text, button, self)
    end)
end
