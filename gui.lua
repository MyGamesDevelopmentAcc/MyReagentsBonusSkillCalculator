local addonName, AddonNS = ...
local GS = LibStub("MyLibrary_GUI");

--- @type WowList
local WowList = LibStub("WowList-1.5");

AddonNS.gui = {};

local self = AddonNS.gui;
local gui = self;



--self.mainFrame = GS:CreateSimpleFrame(addonName, 100, 460);

local f = CreateFrame("Frame", frameName, ProfessionsFrame, "SimplePanelTemplate");
f:SetWidth(160);
f:SetHeight(500);
self.mainFrame=f;
self.mainFrame:SetPoint("TOPLEFT", ProfessionsFrame, "TOPRIGHT", 0, 0);


self.mainFrame.reagentsContainer = CreateFrame("Frame", addonName .. "-reagentsContainer", self.mainFrame)
local containerFrame = self.mainFrame.reagentsContainer;
containerFrame:SetPoint("TOPLEFT", 8, -30)
containerFrame:SetPoint("BOTTOMRIGHT")


local list
do
    containerFrame.list = WowList:CreateNew(addonName .. "_spellList",
        {

            columns = { {
                id = "reagent",
                name = "Skill added",
                width = 140,
                
                textureDisplayFunction = function(reagentInfo)
                    if (reagentInfo.name) then return; end
                    return C_Item.GetItemIconByID(reagentInfo.itemID),nil,30,30;
                end,
                displayFunction = function(reagentInfo)
                    if (reagentInfo.name) then return reagentInfo.name..": "..reagentInfo.value; end
                    --local icon = C_Item.GetItemIconByID(reagentInfo.itemID);
                    --local name = C_Item.GetItemNameByID(reagentInfo.itemID)
                   
                    return " |A:Professions-Icon-Quality-Tier"..reagentInfo.qualityTier..":25:25|a  "..reagentInfo.bonusSkill.."(+"..reagentInfo.addedValue..")" --..name
                end
            }},
            rows = 10,
            height = 400
        }, containerFrame);

    list = containerFrame.list;
    list:SetPoint('TOPLEFT', containerFrame, 'TOPLEFT', 0, 0);
    list:SetMultiSelection(false);
end

function self:DisplayData(reagentsInfo) 

	list:RemoveAll()
    for i =1,#reagentsInfo,1 do
        list:AddData({reagentsInfo[i]});
    end
	list:UpdateView()
end
