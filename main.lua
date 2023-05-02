local addonName, AddonNS = ...
AddonNS.main = {};
local self = AddonNS.main

function self:OnRecipeSelected(recipeInfo, recipeList)
   local recipeID = recipeInfo.recipeID;


   local ilvlModifiers, binaryModifiers, illustrousInsight = AddonNS.recipeUtils.getRecipeSlotInfo(recipeInfo)


   local opInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, {})
   if (not opInfo) then return end

   local baseSkill = opInfo.baseSkill;
   local baseDifficulty = opInfo.baseDifficulty
   local bonusStats = AddonNS.recipeUtils.getBonusStats(opInfo);

   local toDisplay = {};
   local function addToDisplay(ilvl, tier, binaryModifiers, illustrousInsightUsed, chance)
      -- if (chance > 0) then
      table.insert(toDisplay, {
         ilvl = ilvl,
         tier = tier,
         binaryModifiers = binaryModifiers,
         illustrousInsightUsed = illustrousInsightUsed,
         chance = chance
      });
      -- end
   end

   local t2BonusSkillFromMaterials, t3BonusSkillFromMaterials = AddonNS.recipeUtils.getBonusSkillFromMaterials(
      recipeInfo)





   local calculateChancesToReachDifficulty = AddonNS.recipeUtils.calculateChancesToReachDifficulty;

   local inspirationBonusChances = 0
   local inspirationSkillBonus = 0
   if (bonusStats["Inspiration"]) then
      inspirationBonusChances = (bonusStats["Inspiration"].ratingPct + 2) / 100 -- added 2% from using sanguine
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
            { name = binaryModifiers[modSelector].name, change = binaryModifiers[modSelector].change,
               used = bit.band(b, a) > 0 });

         modSelector = modSelector + 1;
         b = b * 2;
      end

      table.insert(binaryModifiersUsedGroups, binaryModifiersUsedGroup)
   end

   for mod = #ilvlModifiers, 1, -1 do
      local ilvlModifier = ilvlModifiers[mod];
      for tier, bonusSkillFromMaterials in pairs({ [2] = t2BonusSkillFromMaterials, [3] = t3BonusSkillFromMaterials }) do
         local difficulty = baseDifficulty + ilvlModifier.change;

         -------------------

         for _, binaryModifiersUsedGroup in ipairs(binaryModifiersUsedGroups) do
            for _, binaryModifiersUsed in ipairs(binaryModifiersUsedGroup) do
               difficulty = difficulty + (binaryModifiersUsed.used and binaryModifiersUsed.change or 0);
            end

            for _, illustrousInsightUsed in ipairs({ true, false }) do
               local procChance = calculateChancesToReachDifficulty(
                  difficulty, baseSkill,
                  bonusSkillFromMaterials,
                  illustrousInsightUsed,
                  hiddenSkillBonus,
                  inspirationSkillBonus,
                  inspirationBonusChances
               )

               addToDisplay(ilvlModifier.name, tier, binaryModifiersUsedGroup, illustrousInsightUsed, procChance)
            end
         end
      end
   end


   AddonNS.gui.mainFrame:Show();
   AddonNS.gui:DisplayData(toDisplay);
end

function self:SelectRecipe(recipeInfo)
   -- The selected recipe from the list will be the first level.
   -- Always forward the highest learned recipe to the schematic.
   local highestRecipe = Professions.GetHighestLearnedRecipe(recipeInfo);
   self.SchematicForm.Details:CancelAllAnims();

   self.SchematicForm:ClearTransaction();
   self.SchematicForm:Init(highestRecipe or recipeInfo);

   self.GuildFrame:Clear();

   self:ValidateControls();
end

EventRegistry:RegisterCallback("ProfessionsRecipeListMixin.Event.OnRecipeSelected", self.OnRecipeSelected, self);
