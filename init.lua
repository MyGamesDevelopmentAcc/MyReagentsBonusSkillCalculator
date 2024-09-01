local addonName, AddonNS = ...

-- DB
AddonNS.db = {};
AddonNS.init = function(db)
    AddonNS.db = db;
end
--@debug@
LibStub("MyLibrary_DB").asyncLoad("dev_MyReagentsBonusSkillCalculatorDB", AddonNS.init);
GLOBAL_MyBags = AddonNS;
--@end-debug@
--[===[@non-debug@
LibStub("MyLibrary_DB").asyncLoad("MyReagentsBonusSkillCalculatorDB", AddonNS.init);
--@end-non-debug@]===]