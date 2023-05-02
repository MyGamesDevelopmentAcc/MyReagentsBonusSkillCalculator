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

   local function calculateChancesToReachDifficulty(difficulty,
                                                    baseSkill,
                                                    bonusSkillFromMaterials,
                                                    illustrousInsight,
                                                    hiddenSkillBonus,
                                                    inspirationSkillBonus,
                                                    inspirationBonusChances)
      local skill = baseSkill + bonusSkillFromMaterials + (illustrousInsight and 30 or 0);
      local hiddenSkillBonusRollPossibilities = hiddenSkillBonus +
          1 -- if hidden skill is 10, then there are 11 possible options from 0, 1,2..,10, hence this is what has to be used to calculate chances

      if (difficulty <= skill) then
         return 1
      else
         local skillLacking = difficulty - skill;
         -- chances for 4 out of 10, is 6/11, 0 of 10 it is 11/11, for 10 out of 10 it is 1/11
         if (hiddenSkillBonus >= skillLacking) then
            local extraChance = (hiddenSkillBonusRollPossibilities - skillLacking) / hiddenSkillBonusRollPossibilities;
            return ((1 - (1 - inspirationBonusChances) * (1 - extraChance)))
         elseif (inspirationSkillBonus >= skillLacking) then
            return inspirationBonusChances
         elseif (inspirationSkillBonus + hiddenSkillBonus >= skillLacking) then
            local diff = skillLacking - inspirationSkillBonus;
            local extraChance = (hiddenSkillBonusRollPossibilities - diff) / hiddenSkillBonusRollPossibilities
            return (inspirationBonusChances) * (extraChance)
         else
            return 0;
         end
      end
   end
   local inspirationBonusChances = 0
   local inspirationSkillBonus = 0
   if (bonusStats["Inspiration"]) then
      inspirationBonusChances = (bonusStats["Inspiration"].ratingPct + 2) / 100 -- added 2% from using sanguine
      inspirationSkillBonus = bonusStats["Inspiration"].bonusSkill;
   end
   local hiddenSkillBonus = math.floor(baseDifficulty * 0.05);
   for mod = #ilvlModifiers, 1, -1 do
      for x, bonusSkillFromMaterials in ipairs({t2BonusSkillFromMaterials, t3BonusSkillFromMaterials }) do
         local ilvlModifier = ilvlModifiers[mod];
         local name = ilvlModifier.name;
         local difficulty = baseDifficulty + ilvlModifier.change;
         --name = name .. skill .." - "
         if x == 1 then
            name = name .. "[t2]"
         else
            name = name .. "[t3]"
         end
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
   local addedSkillDifficulties = { 0,
      40,
      70,
      90,
      0,
      15,
      20,
      25,
      30,
      35,
      40,
      45,
      50,
      55,
      60,
      65,
      70,
      75,
      80,
      85,
      90,
      95,
      100,
      105,
      110 }
   for _, addedSkillDifficulty in ipairs(addedSkillDifficulties) do
      -- print("diff", addedSkillDifficulty)
      local difficulty = addedSkillDifficulty + baseDifficulty;
      addChancesForSkillDifficulty(addedSkillDifficulty, calculateChancesToReachDifficulty(
         difficulty, baseSkill,
         t3BonusSkillFromMaterials,
         false,
         hiddenSkillBonus,
         inspirationSkillBonus,
         inspirationBonusChances
      ))
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
