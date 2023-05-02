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
   local function addToDisplay(ilvl, tier, embellishment, missive, illustrousInsight, chance)
      table.insert(toDisplay, {
         ilvl = ilvl,
         tier = tier,
         embellishment = embellishment,
         missive = missive,
         illustrousInsight = illustrousInsight,
         chance = chance
      });
   end

   local t2BonusSkillFromMaterials, t3BonusSkillFromMaterials = AddonNS.recipeUtils.getBonusSkillFromMaterials(
      recipeInfo)



   local function addChancesForSkillDifficulty(difficulty, chance)
      if (chance > 0) then
         table.insert(toDisplay,
            { name = difficulty, value = (math.floor(chance * 1000 + 0.5) / 10) .. "%" });
      end
   end

   local calculateChancesToReachDifficulty = AddonNS.recipeUtils.calculateChancesToReachDifficulty;

   local inspirationBonusChances = 0
   local inspirationSkillBonus = 0
   if (bonusStats["Inspiration"]) then
      inspirationBonusChances = (bonusStats["Inspiration"].ratingPct + 2) / 100 -- added 2% from using sanguine
      inspirationSkillBonus = bonusStats["Inspiration"].bonusSkill;
   end
   local hiddenSkillBonus = math.floor(baseDifficulty * 0.05);
   for mod = #ilvlModifiers, 1, -1 do
      for tier, bonusSkillFromMaterials in pairs({ [2] = t2BonusSkillFromMaterials, [3] = t3BonusSkillFromMaterials }) do
         local ilvlModifier = ilvlModifiers[mod];
         local name = ilvlModifier.name;
         local difficulty = baseDifficulty + ilvlModifier.change;
         --name = name .. skill .." - "

         name = name .. "[t" .. tier .. "]"

         local binaryModifiersBonusDifficulty = 0;
         local binaryModifiersName = ""
         if #binaryModifiers > 0 then
            binaryModifiersName = binaryModifiersName .. "[";
            for i = 1, #binaryModifiers, 1 do
               binaryModifiersBonusDifficulty = binaryModifiersBonusDifficulty + binaryModifiers[i].change;
               binaryModifiersName = binaryModifiersName .. binaryModifiers[i].name;
               if i ~= #binaryModifiers then binaryModifiersName = binaryModifiersName .. "/"; end
            end
            binaryModifiersName = binaryModifiersName .. "]";
         end
         local procChance = calculateChancesToReachDifficulty(
            difficulty + binaryModifiersBonusDifficulty, baseSkill,
            bonusSkillFromMaterials,
            illustrousInsight,
            hiddenSkillBonus,
            inspirationSkillBonus,
            inspirationBonusChances
         )
         print(name .. binaryModifiersName, procChance)
         addChancesForSkillDifficulty(name .. binaryModifiersName, procChance)
         if (procChance < 1 and illustrousInsight) then
            procChance = calculateChancesToReachDifficulty(
               difficulty + binaryModifiersBonusDifficulty, baseSkill,
               bonusSkillFromMaterials,
               illustrousInsight,
               hiddenSkillBonus,
               inspirationSkillBonus,
               inspirationBonusChances
            )
            addChancesForSkillDifficulty(name .. binaryModifiersName .. "+i", procChance)
            if (procChance < 1) then
               procChance = calculateChancesToReachDifficulty(
                  difficulty, baseSkill,
                  bonusSkillFromMaterials,
                  illustrousInsight,
                  hiddenSkillBonus,
                  inspirationSkillBonus,
                  inspirationBonusChances
               )
               addChancesForSkillDifficulty(name, procChance)
               if (procChance < 1) then
                  procChance = calculateChancesToReachDifficulty(
                     difficulty, baseSkill,
                     bonusSkillFromMaterials,
                     illustrousInsight,
                     hiddenSkillBonus,
                     inspirationSkillBonus,
                     inspirationBonusChances
                  )
                  addChancesForSkillDifficulty(name .. "+i", procChance)
               end
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
