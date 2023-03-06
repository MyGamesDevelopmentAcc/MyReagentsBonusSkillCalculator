local addonName, AddonNS = ...
AddonNS.main = {};
local self = AddonNS.main

function self:OnRecipeSelected(recipeInfo, recipeList)
   local recipeID = recipeInfo.recipeID;

   local recipeSchematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false);
   local recipeReagents = {}
   local repo = {
      [111] = "Infuse with Power",
      [126] = "Infuse with Power",
      [180] = "Add Embellishment",
      [123] = "Add Embellishment",
      [125] = "Customize Secondary Stats",
      [227] = "Customize Secondary Stats",
      [184] = "Chain Oil",
      [189] = "Empower with Training Matrix",
      [116] = "Empower with Training Matrix",
      [185] = "Curing Agent",
      [93] = "Illustrous Insight",
      [92] = "Lesser Illustrous Insight",
   };
   local modifiers = {
      ["Add Embellishment"] = 25,
      ["Customize Secondary Stats"] = 15,
   }
   local ilvlModifiers = { { name = "", change = 0 }, }
   local binaryModifiers = {};
   local inspirationModifier = false;
   local illustrousInsight = false;

   local function updateModifiers(id)
      if (id == 111 or id == 126) then ---  "Infuse with Power"
         ilvlModifiers = { { name = "392", change = 0 }, { name = "405", change = 30 }, { name = "418", change = 50 } }
      elseif (id == 189) then          --"Empower with Training Matrix"
         ilvlModifiers = { { name = "343", change = 0 }, { name = "356", change = 40 }, { name = "369", change = 60 },
            { name = "382", change = 150 } }
      elseif (id == 116) then ---"Empower with Training Matrix"
         ilvlModifiers = { { name = "316", change = 0 }, { name = "343", change = 20 }, { name = "356", change = 40 },
            { name = "369", change = 60 }, { name = "382", change = 150 } }
      elseif (id == 92 or id == 93) then                    ---(Lesser) Illustrous Insight
         illustrousInsight = true;
      elseif (repo[id] == "Add Embellishment") then         -- i know that I could send a string here already, but I dont know yet if I wont need the repo table above for smth different
         table.insert(binaryModifiers, { name = "E", change = 25 })
      elseif (repo[id] == "Customize Secondary Stats") then -- i know that I could send a string here already, but I dont know yet if I wont need the repo table above for smth different
         table.insert(binaryModifiers, { name = "M", change = 15 })
      elseif (repo[id] == "Chain Oil") then                 -- i know that I could send a string here already, but I dont know yet if I wont need the repo table above for smth different
         inspirationModifier = true;
      end
   end

   for i, v in ipairs(recipeSchematic.reagentSlotSchematics) do
      if (v.reagentType == 1 and #v.reagents > 1) then -- basic reagent
         local reagents = {}
         table.insert(recipeReagents, reagents)
         for n, reagent in ipairs(v.reagents) do
            table.insert(reagents,
               {
                  name = v.slotInfo.slotText .. " Q" .. n,
                  itemID = reagent.itemID,
                  dataSlotIndex = v.dataSlotIndex,
                  quantity = v.quantityRequired
               })
         end
      elseif (v.reagentType == 2) then --optional
         -- if not (repo[v.slotInfo.mcrSlotID]) then
         updateModifiers(v.slotInfo.mcrSlotID)
         -- print("optional", v.slotInfo.mcrSlotID, v.slotInfo.slotText)
         --  print(v.reagentType, v.slotInfo.mcrSlotID, v.slotInfo.slotText)
         --end
      elseif (v.reagentType == 0) then --finishing
         -- if not (repo[v.slotInfo.mcrSlotID]) then
         updateModifiers(v.slotInfo.mcrSlotID)
         -- print("finishing", v.slotInfo.mcrSlotID, v.slotInfo.slotText)
         -- print(v.reagentType, v.slotInfo.mcrSlotID, v.slotInfo.slotText)
      end
   end


   local opInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, {})
   if (not opInfo) then return end
   local baseBonusSkill = opInfo.bonusSkill;
   local baseSkill = opInfo.baseSkill;
   local baseDifficulty = opInfo.baseDifficulty
   local bonusStats = {};
   for _, v in ipairs(opInfo.bonusStats) do
      bonusStats[v.bonusStatName] = { ratingPct = v.ratingPct }
      if (v.bonusStatName == "Inspiration") then
         local _, _, bonusSkill = strfind(v.ratingDescription, " (%d+) ")
         bonusStats[v.bonusStatName]["bonusSkill"] = tonumber(bonusSkill);
      end
   end
   local reagentsInfo = {};
   for i = 1, #recipeReagents, 1 do
      for i2 = 1, #recipeReagents[i], 1 do
         local craftingReagents = {}
         table.insert(craftingReagents, recipeReagents[i][i2])
         for i3 = 1, #recipeReagents, 1 do
            if (i3 ~= i) then
               table.insert(craftingReagents, recipeReagents[i3][1])
            end
         end
         local opInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents)
         local addedBonus = opInfo.bonusSkill - baseBonusSkill
         local reagentInfo = {
            qualityTier = i2,
            addedValue = addedBonus,
            bonusSkill = opInfo.bonusSkill,
            itemID = recipeReagents[i][i2].itemID
         }
         table.insert(reagentsInfo, reagentInfo);
      end
   end

   local craftingReagents = {}
   for i = 1, #recipeReagents, 1 do
      table.insert(craftingReagents, recipeReagents[i][#recipeReagents[i] > 1 and 3 or 1])
   end
   local t3BonusFromMaterials = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents).bonusSkill;
   local t3SkillFromMaterials = baseSkill + t3BonusFromMaterials;

   craftingReagents = {}
   for i = 1, #recipeReagents, 1 do
      table.insert(craftingReagents, recipeReagents[i][#recipeReagents[i] > 1 and 2 or 1])
   end
   local t2BonusFromMaterials = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents).bonusSkill;
   local t2SkillFromMaterials = baseSkill + t2BonusFromMaterials;


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
   local function addChancesForSkillDifficulty(difficulty, chance)
      table.insert(reagentsInfo,
         { name = difficulty, value = (math.floor(chance * 1000 + 0.5) / 10) .. "%" });
   end

   local function calculateChancesToReachDifficulty(difficulty,
                                                    skill,
                                                    hiddenSkillBonus,
                                                    inspirationSkillBonus,
                                                    inspirationBonusChances)
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
   --name/change
   --[[ local ilvlModifiers = { { name = "", change = 0 }, }
   local binaryModifiers = {};
   local inspirationModifier = false;]]
   for _, ilvlModifier in ipairs(ilvlModifiers) do
      local name = ilvlModifier.name;
      local difficulty = baseDifficulty + ilvlModifier.change;
   for mod = #ilvlModifiers, 1, -1 do
      for x, skill in ipairs({ t2SkillFromMaterials, t3SkillFromMaterials }) do
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
            difficulty + binaryModifiersBonusDifficulty, skill,
            hiddenSkillBonus,
            inspirationSkillBonus,
            inspirationBonusChances
         )
         addChancesForSkillDifficulty(name .. binaryModifiersName, procChance)
         if (procChance < 1 and illustrousInsight) then
            procChance = calculateChancesToReachDifficulty(
               difficulty + binaryModifiersBonusDifficulty, skill + 30,
               hiddenSkillBonus,
               inspirationSkillBonus,
               inspirationBonusChances
            )
            addChancesForSkillDifficulty(name .. binaryModifiersName .. "+i", procChance)
            if (procChance < 1) then
               procChance = calculateChancesToReachDifficulty(
                  difficulty, skill,
                  hiddenSkillBonus,
                  inspirationSkillBonus,
                  inspirationBonusChances
               )
               addChancesForSkillDifficulty(name, procChance)
               if (procChance < 1) then
                  procChance = calculateChancesToReachDifficulty(
                     difficulty, skill + 30,
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
   for _, addedSkillDifficulty in ipairs(addedSkillDifficulties) do
      -- print("diff", addedSkillDifficulty)
      local difficulty = addedSkillDifficulty + baseDifficulty;
      addChancesForSkillDifficulty(addedSkillDifficulty, calculateChancesToReachDifficulty(
         difficulty, t3SkillFromMaterials,
         hiddenSkillBonus,
         inspirationSkillBonus,
         inspirationBonusChances
      ))
   end

   AddonNS.gui.mainFrame:Show();
   AddonNS.gui:DisplayData(reagentsInfo);
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
