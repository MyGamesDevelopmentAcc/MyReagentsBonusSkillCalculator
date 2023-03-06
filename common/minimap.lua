local addonName, AddonNS = ...
AddonNS.minimap = LibStub("AceAddon-3.0"):NewAddon(addonName.."-minimap")
local minimap = AddonNS.minimap;
local LibDBIcon = LibStub("LibDBIcon-1.0")


local addonDescription = "Addon shows spells casted."


local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
	type = "data source",
	text = addonName.." Addon",
	icon = "Interface\\Icons\\achievement_arena_2v2_1",
	OnClick = function(self, btn)
		 AddonNS:MinimapOnClick();
	end,

	OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then return end
		tooltip:AddLine(addonName.." "..addonDescription)
	end,
})


function minimap:OnInitialize()
	if (AddonNS.MinimapOnClick) then 
		AddonNS.db.minimap = AddonNS.db.minimap or {hide=false};
		LibDBIcon:Register(addonName, miniButton, AddonNS.db.minimap)
	end
end