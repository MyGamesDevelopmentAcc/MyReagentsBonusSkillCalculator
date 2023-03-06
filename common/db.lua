local addonName, AddonNS = ...
AddonNS.db = nil; -- to make sure this field is not used for anything else.
AddonNS.dbload = LibStub("AceAddon-3.0"):NewAddon(addonName.."-db")
local dbload = AddonNS.dbload;

function dbload:OnInitialize()
	_G[addonName.."DB"] = _G[addonName.."DB"] or {};
	AddonNS.db = _G[addonName.."DB"];
end