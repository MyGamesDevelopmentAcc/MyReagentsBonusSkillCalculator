local addonName, AddonNS = ...
AddonNS.main = {};
local self = AddonNS.main

local initilized = false;

local function initialize()
   AddonNS.createGUI()
   hooksecurefunc(ProfessionsFrame.OrdersPage.OrderView, "SetOrder", function(self, order, b)
      AddonNS.main:OnRecipeSelected(C_TradeSkillUI.GetRecipeInfo(order.spellID))
   end)
end

function self:OnRecipeSelected(recipeInfo)
   if not initilized then
      initialize();
      initilized = true;
   end


--[[
  *  get all reageents
  * mark if MCR (Modified Crafting Reagent)
  * mark if required
  * mark how many reagents are required
  * slotInfo.mcrSlotID - group by this id reagents.
  * whether a slot is locked, ie. cannot use it due to lack of skill (stated in locked reason how to unlock it)
      locked, lockedReason = C_TradeSkillUI.GetReagentSlotStatus(mcrSlotID, recipeSpellID, skillLineAbilityID)
  
 1. create lowest tier reagents list consiting of required and MCR reagents
 2. create a function that for each required MCR by replacing entire tier with one tier higher. Divide by the number of required quantity. Store information that for a given slot using higher tier single item grants x additional skill points.
 3. For each optional MCR (...) . If slot is locked, write that down that this is currently impossible.
 4. Gather cost for each reagents from AH. (verify if this can be somehow checked if an item is soulbound hence it won't be on AH).
 5. print table with:
   * slotName 
   * required
   * name
   * price
   * skillUp
   * diffUp
   * required quantity
   * locked
   
 There is new option guaranteedCraftingQualityID and other cool thngies in here: https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetCraftingOperationInfo
]]

   local recipeID = recipeInfo.recipeID;
   GLOBAL_RECIPEID = recipeID;
   G_recipeInfo = recipeInfo;
   local ilvlModifiers, binaryModifiers, illustrousInsight = AddonNS.recipeUtils.getRecipeSlotInfo(recipeInfo)

   --    local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false);
   --    print(schematic, schematic.currentRecipeInfo, schematic.transaction, schematic.GetRecipeOperationInfo)

   --   local t = CreateProfessionsRecipeTransaction(schematic)

   --   print("tr",t)

   --   local opInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, {}, t:GetAllocationItemGUID(), false)




   -- Define the recipe ID
   local recipeID = GLOBAL_RECIPEID or 12345 -- Replace with the actual recipe ID
   -- Define the recipe ID
   -- Retrieve the recipe schematic
   local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false) -- 'false' indicates this is not a recraft
G_schematic = schematic;
   -- Prepare a table to store reagent impacts
   local reagentImpact = {}

   -- Iterate over the reagent slots defined in the schematic
   for _, reagentSlot in ipairs(schematic.reagentSlotSchematics) do
      local reagentInfo = {}
      local name = #reagentSlot.reagents > 1 and (reagentSlot.slotText or reagentSlot.slotInfo and reagentSlot.slotInfo.slotText) or C_Item.GetItemNameByID(reagentSlot.reagents[1].itemID);
      print("Name:", name)
      -- Iterate over each reagent option in the current slot
      for _, reagent in ipairs(reagentSlot.reagents) do
         print(
            reagent.itemID,
            reagentSlot.quantityRequired,
            reagentSlot.dataSlotIndex
         )
         
         if (reagentSlot.quantityRequired) then
            print("weszlo")
            local craftingReagents = { {
               itemID = reagent.itemID,
               quantity = reagentSlot.quantityRequired,
               dataSlotIndex = reagentSlot.dataSlotIndex
            } }
            
            

            -- Simulate the crafting operation with this reagent
            local operationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents, "asd", false)

            print("operationInfo", operationInfo)
            -- local operationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, {}, "asd", false)
            if (operationInfo) then
               -- Store the relevant information
               table.insert(reagentInfo, {
                  itemID = reagent.itemID,
                  itemLink =C_Item.GetItemNameByID( reagent.itemID), -- Optional: Get item link for display
                  baseDifficulty = operationInfo.baseDifficulty,
                  bonusDifficulty = operationInfo.bonusDifficulty,
                  baseSkill = operationInfo.baseSkill,
                  bonusSkill = operationInfo.bonusSkill,
                  quality = operationInfo.quality,
                  isQualityCraft = operationInfo.isQualityCraft,
                  craftingQualityID = operationInfo.craftingQualityID,
                  guaranteedCraftingQualityID= operationInfo.guaranteedCraftingQualityID or -1
               })
            end
            print("-----")
         end
      end

      -- Store the information for this reagent slot
      reagentImpact[reagentSlot.slotIndex] = {
         slotName = name or ("Slot " .. reagentSlot.slotIndex),
         reagents = reagentInfo
      }
      print("====")
   end


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
   -- Print the results (or process as needed)
   for slotIndex, slotData in pairs(reagentImpact) do
      print("Slot:", slotData.slotName)
      for _, reagent in ipairs(slotData.reagents) do
         print(string.format(
            "  Reagent: %s (ItemID: %d) - Base Difficulty: %d, Bonus Difficulty: %d, Base Skill: %d, Bonus Skill: %d, Quality: %s, guaranteedCraftingQualityID: %d",
            reagent.itemLink, reagent.itemID, reagent.baseDifficulty, reagent.bonusDifficulty, reagent.baseSkill,
            reagent.bonusSkill, reagent.quality or "N/A", reagent.guaranteedCraftingQualityID)
         )
      end
   end
   
   
   addToDisplay(ilvlModifier.name, tier, binaryModifiersUsedGroup, illustrousInsightUsed, procChance,
                  difficulty, skill)

   -- local opInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, {}, "asd", false)
   -- if (not opInfo) then return end

   -- local baseSkill = opInfo.baseSkill;
   -- local baseDifficulty = opInfo.baseDifficulty
   -- local bonusStats = AddonNS.recipeUtils.getBonusStats(opInfo);

   -- local toDisplay = {};
   -- local function addToDisplay(ilvl, tier, binaryModifiers, illustrousInsightUsed, chance, difficulty, skill)
   --    -- if (chance > 0) then
   --    table.insert(toDisplay, {
   --       ilvl = ilvl,
   --       tier = tier,
   --       binaryModifiers = binaryModifiers,
   --       illustrousInsightUsed = illustrousInsightUsed,
   --       chance = chance,
   --       difficulty = difficulty,
   --       skill = skill
   --    });
   --    -- end
   -- end

   -- local t2BonusSkillFromMaterials, t3BonusSkillFromMaterials = AddonNS.recipeUtils.getBonusSkillFromMaterials(
   --    recipeInfo)




   -- local calculateChancesToReachDifficulty = AddonNS.recipeUtils.calculateChancesToReachDifficulty;

   -- local inspirationBonusChances = 0
   -- local inspirationSkillBonus = 0
   -- if (bonusStats["Inspiration"]) then
   --    inspirationBonusChances = (bonusStats["Inspiration"].ratingPct + 2) /
   --        100 -- added 2% from using https://www.wowhead.com/item=191501/sagacious-incense
   --    inspirationSkillBonus = bonusStats["Inspiration"].bonusSkill;
   -- end
   -- local hiddenSkillBonus = math.floor(baseDifficulty * 0.05);


   -- local binaryModifiersUsedGroups = {};
   -- --if #binaryModifiers > 0 then
   -- local combinations = 2 ^ #binaryModifiers;
   -- for a = 0, combinations - 1, 1 do
   --    local binaryModifiersUsedGroup = {};
   --    local b = 1;
   --    local modSelector = 1;
   --    while (b <= combinations - 1) do
   --       --print(modSelector,b,combinations,bit.band(b, a))
   --       table.insert(binaryModifiersUsedGroup,
   --          {
   --             name = binaryModifiers[modSelector].name,
   --             change = binaryModifiers[modSelector].change,
   --             used = bit.band(b, a) > 0
   --          });

   --       modSelector = modSelector + 1;
   --       b = b * 2;
   --    end

   --    table.insert(binaryModifiersUsedGroups, binaryModifiersUsedGroup)
   -- end

   -- for mod = #ilvlModifiers, 1, -1 do
   --    local ilvlModifier = ilvlModifiers[mod];
   --    for tier, bonusSkillFromMaterials in pairs({ [2] = t2BonusSkillFromMaterials, [3] = t3BonusSkillFromMaterials }) do
   --       local baseDifficultyWithIlvlModifier = baseDifficulty + ilvlModifier.change;

   --       -------------------

   --       for _, binaryModifiersUsedGroup in ipairs(binaryModifiersUsedGroups) do
   --          local difficulty = baseDifficultyWithIlvlModifier;
   --          for _, binaryModifiersUsed in ipairs(binaryModifiersUsedGroup) do
   --             difficulty = difficulty + (binaryModifiersUsed.used and binaryModifiersUsed.change or 0);
   --          end

   --          for _, illustrousInsightUsed in ipairs({ true, false }) do
   --             local procChance, difficulty, skill = calculateChancesToReachDifficulty(
   --                difficulty, baseSkill,
   --                bonusSkillFromMaterials,
   --                illustrousInsightUsed,
   --                hiddenSkillBonus,
   --                inspirationSkillBonus,
   --                inspirationBonusChances
   --             )

   --             addToDisplay(ilvlModifier.name, tier, binaryModifiersUsedGroup, illustrousInsightUsed, procChance,
   --                difficulty, skill)
   --          end
   --       end
   --    end
   -- end


   AddonNS.gui.mainFrame:Show();
   AddonNS.gui:DisplayData(toDisplay, AddonNS.recipeUtils.getHighestTierItemLink(recipeInfo));
end

EventRegistry:RegisterCallback("ProfessionsRecipeListMixin.Event.OnRecipeSelected", self.OnRecipeSelected, self);
