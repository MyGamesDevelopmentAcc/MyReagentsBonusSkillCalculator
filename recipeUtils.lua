local addonName, AddonNS = ...
AddonNS.recipeUtils = {};
local self = AddonNS.recipeUtils
function self.getRecipeSlotInfo(recipeInfo)
   local reagentSlotSchematics = C_TradeSkillUI.GetRecipeSchematic(recipeInfo.recipeID, false).reagentSlotSchematics;

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
   local ilvlModifiers = { { name = "", change = 0 }, }
   local binaryModifiers = {};
   local inspirationModifier = false;
   local illustrousInsight = false;

   local function updateModifiers(id)
      if (id == 111 or id == 126) then ---  "Infuse with Power"
         ilvlModifiers = { { name = "391", change = 0 }, { name = "437", change = 30 }, { name = "447", change = 50 } }
      elseif (id == 189) then          --"Empower with Training Matrix"
         ilvlModifiers = { { name = "343", change = 0 }, { name = "356", change = 40 }, { name = "369", change = 60 },
            { name = "382", change = 140 }, { name = "395", change = 150 }, { name = "408", change = 160 } }
      elseif (id == 116) then ---"Empower with Training Matrix"
         ilvlModifiers = { { name = "316", change = 0 }, { name = "343", change = 20 }, { name = "356", change = 40 },
            { name = "369", change = 60 }, { name = "382", change = 140 }, { name = "395", change = 150 },
            { name = "408", change = 160 } }
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

   for i, v in ipairs(reagentSlotSchematics) do
      if (v.reagentType == 2) then --optional
         -- if not (repo[v.slotInfo.mcrSlotID]) then
         updateModifiers(v.slotInfo.mcrSlotID)
         print("optional", v.slotInfo.mcrSlotID, v.slotInfo.slotText)
         print(v.reagentType, v.slotInfo.mcrSlotID, v.slotInfo.slotText)
         --end
      elseif (v.reagentType == 0) then --finishing
         -- if not (repo[v.slotInfo.mcrSlotID]) then
         updateModifiers(v.slotInfo.mcrSlotID)
         print("finishing", v.slotInfo.mcrSlotID, v.slotInfo.slotText)
         print(v.reagentType, v.slotInfo.mcrSlotID, v.slotInfo.slotText)
      end
   end
   return ilvlModifiers, binaryModifiers, illustrousInsight
end

function self.getBonusStats(opInfo)
   local bonusStats = {};

   for _, v in ipairs(opInfo.bonusStats) do
      bonusStats[v.bonusStatName] = { ratingPct = v.ratingPct }
      if (v.bonusStatName == "Inspiration") then
         local _, _, bonusSkill = strfind(v.ratingDescription, " (%d+) ")
         bonusStats[v.bonusStatName]["bonusSkill"] = tonumber(bonusSkill);
      end
   end
   return bonusStats;
end

local function getBonusSkillFromMaterials(recipeReagents, recipeID, tier)
   local craftingReagents = {}
   for i = 1, #recipeReagents, 1 do
      table.insert(craftingReagents, recipeReagents[i][#recipeReagents[i] > 1 and tier or 1])
   end
   local t3BonusFromMaterials = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents).bonusSkill;
   return t3BonusFromMaterials;
end

function self.getBonusSkillFromMaterials(recipeInfo)
   local reagentSlotSchematics = C_TradeSkillUI.GetRecipeSchematic(recipeInfo.recipeID, false).reagentSlotSchematics;
   local recipeReagents = {};
   for i, v in ipairs(reagentSlotSchematics) do
      if (v.reagentType == 1 and #v.reagents > 1) then -- basic reagent
         local reagents = {}
         for n, reagent in ipairs(v.reagents) do
            table.insert(reagents,
               {
                  name = v.slotInfo.slotText .. " Q" .. n,
                  itemID = reagent.itemID,
                  dataSlotIndex = v.dataSlotIndex,
                  quantity = v.quantityRequired
               })
         end
         table.insert(recipeReagents, reagents)
      end
   end
   return getBonusSkillFromMaterials(recipeReagents, recipeInfo.recipeID, 2),
       getBonusSkillFromMaterials(recipeReagents, recipeInfo.recipeID, 3)
end

function self.calculateChancesToReachDifficulty(difficulty,
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
