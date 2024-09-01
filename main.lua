local addonName, AddonNS = ...
AddonNS.main = {};
local self = AddonNS.main

function self:OnRecipeSelected(recipeInfo)
   if not AddonNS.gui then
      AddonNS.createGUI()
      hooksecurefunc(ProfessionsFrame.OrdersPage.OrderView, "SetOrder", function(self, order, b)
         AddonNS.main:OnRecipeSelected(C_TradeSkillUI.GetRecipeInfo(order.spellID))
      end)
   end
   local recipeID = recipeInfo.recipeID;


   local ilvlModifiers, binaryModifiers, illustrousInsight = AddonNS.recipeUtils.getRecipeSlotInfo(recipeInfo)

--    local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false);
--    print(schematic, schematic.currentRecipeInfo, schematic.transaction, schematic.GetRecipeOperationInfo)

--   local t = CreateProfessionsRecipeTransaction(schematic)
  
--   print("tr",t)
  
--   local opInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, {}, t:GetAllocationItemGUID(), false)
   local opInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, {}, "asd", false)
   if (not opInfo) then return end

   local baseSkill = opInfo.baseSkill;
   local baseDifficulty = opInfo.baseDifficulty
   local bonusStats = AddonNS.recipeUtils.getBonusStats(opInfo);

   local toDisplay = {};
   local function addToDisplay(ilvl, tier, binaryModifiers, illustrousInsightUsed, chance, difficulty, skill)
      -- if (chance > 0) then
      table.insert(toDisplay, {
         ilvl = ilvl,
         tier = tier,
         binaryModifiers = binaryModifiers,
         illustrousInsightUsed = illustrousInsightUsed,
         chance = chance,
         difficulty = difficulty,
         skill = skill
      });
      -- end
   end

   local t2BonusSkillFromMaterials, t3BonusSkillFromMaterials = AddonNS.recipeUtils.getBonusSkillFromMaterials(
      recipeInfo)




   local calculateChancesToReachDifficulty = AddonNS.recipeUtils.calculateChancesToReachDifficulty;

   local inspirationBonusChances = 0
   local inspirationSkillBonus = 0
   if (bonusStats["Inspiration"]) then
      inspirationBonusChances = (bonusStats["Inspiration"].ratingPct + 2) /
          100 -- added 2% from using https://www.wowhead.com/item=191501/sagacious-incense
      inspirationSkillBonus = bonusStats["Inspiration"].bonusSkill;
   end
   local hiddenSkillBonus = math.floor(baseDifficulty * 0.05);


   local binaryModifiersUsedGroups = {};
   --if #binaryModifiers > 0 then
   local combinations = 2 ^ #binaryModifiers;
   for a = 0, combinations - 1, 1 do
      local binaryModifiersUsedGroup = {};
      local b = 1;
      local modSelector = 1;
      while (b <= combinations - 1) do
         --print(modSelector,b,combinations,bit.band(b, a))
         table.insert(binaryModifiersUsedGroup,
            {
               name = binaryModifiers[modSelector].name,
               change = binaryModifiers[modSelector].change,
               used = bit.band(b, a) > 0
            });

         modSelector = modSelector + 1;
         b = b * 2;
      end

      table.insert(binaryModifiersUsedGroups, binaryModifiersUsedGroup)
   end

   for mod = #ilvlModifiers, 1, -1 do
      local ilvlModifier = ilvlModifiers[mod];
      for tier, bonusSkillFromMaterials in pairs({ [2] = t2BonusSkillFromMaterials, [3] = t3BonusSkillFromMaterials }) do
         local baseDifficultyWithIlvlModifier = baseDifficulty + ilvlModifier.change;

         -------------------

         for _, binaryModifiersUsedGroup in ipairs(binaryModifiersUsedGroups) do
            local difficulty = baseDifficultyWithIlvlModifier;
            for _, binaryModifiersUsed in ipairs(binaryModifiersUsedGroup) do
               difficulty = difficulty + (binaryModifiersUsed.used and binaryModifiersUsed.change or 0);
            end

            for _, illustrousInsightUsed in ipairs({ true, false }) do
               local procChance, difficulty, skill = calculateChancesToReachDifficulty(
                  difficulty, baseSkill,
                  bonusSkillFromMaterials,
                  illustrousInsightUsed,
                  hiddenSkillBonus,
                  inspirationSkillBonus,
                  inspirationBonusChances
               )

               addToDisplay(ilvlModifier.name, tier, binaryModifiersUsedGroup, illustrousInsightUsed, procChance,
                  difficulty, skill)
            end
         end
      end
   end


   AddonNS.gui.mainFrame:Show();
   AddonNS.gui:DisplayData(toDisplay, AddonNS.recipeUtils.getHighestTierItemLink(recipeInfo));
end

EventRegistry:RegisterCallback("ProfessionsRecipeListMixin.Event.OnRecipeSelected", self.OnRecipeSelected, self);
