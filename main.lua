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
-- local finishingReagents = {};
-- local modyfingReagents = {};
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
   -- local recipeTemplate = {
   --    name = "asd",
   --    recipeId = 123,
   --    slots = {
   --       ["Add Embelishment"] = {
   --          required = false,
   --          mcr = true,
   --          quantity = 1,
   --          reagents = {
   --             {
   --                itemID = reagent.itemID,
   --                quantity = reagentSlot.quantityRequired,
   --                dataSlotIndex = reagentSlot.dataSlotIndex,
   --                diffIncr = 35,
   --             },
   --             {
   --                itemID = reagent.itemID,
   --                quantity = reagentSlot.quantityRequired,
   --                dataSlotIndex = reagentSlot.dataSlotIndex,
   --                diffIncr = 35,
   --             },
   --             {
   --                itemID = reagent.itemID,
   --                quantity = reagentSlot.quantityRequired,
   --                dataSlotIndex = reagentSlot.dataSlotIndex,
   --                diffIncr = 35,
   --             }
   --          },
   --       },
   --       ["Add Embelishment"] = {
   --          required = true,
   --          mcr = true,


   --       }
   --    }
   -- }
   local ilvlModifiers, binaryModifiers, illustrousInsight = AddonNS.recipeUtils.getRecipeSlotInfo(recipeInfo)

   --    local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false);
   --   -- print(schematic, schematic.currentRecipeInfo, schematic.transaction, schematic.GetRecipeOperationInfo)

   --   local t = CreateProfessionsRecipeTransaction(schematic)

   --  -- print("tr",t)

   --   local opInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, {}, t:GetAllocationItemGUID(), false)




   -- Define the recipe ID
   local recipeID = GLOBAL_RECIPEID or 12345 -- Replace with the actual recipe ID
   -- Define the recipe ID
   -- Retrieve the recipe schematic
   local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false) -- 'false' indicates this is not a recraft
   G_schematic = schematic;
   -- Prepare a table to store reagent impacts
   -- local reagentImpact = {}

   local reagents = AddonNS.recipeUtils.GetRequiredMCRReagents(recipeInfo);
   local basicReagents = {};
   for key, value in pairs(reagents) do
      table.insert(basicReagents, value);
   end


   -- print(#basicReagents)
   local craftingReagents = {}
   for i = 1, #basicReagents, 1 do
      table.insert(craftingReagents, basicReagents[i][1]);
   end
   local baseCraftingOperationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents, "", false)

   local reagentsImpact = {};
   for i = 1, #basicReagents, 1 do
      for j = 1, #basicReagents[i], 1 do
         craftingReagents[i] = basicReagents[i][j];
         local craftingOperationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents, "", false)
         reagentsImpact[basicReagents[i][j].itemID] = {
            tier = j,
            bonusSkill = (craftingOperationInfo.bonusSkill - baseCraftingOperationInfo.bonusSkill) /
                basicReagents[i][j].quantity,
            bonusDifficulty = (craftingOperationInfo.bonusDifficulty - baseCraftingOperationInfo.bonusDifficulty) /
                basicReagents[i][j].quantity,
            name = basicReagents[i][j].name,
            cost = Auctionator and
                Auctionator.API.v1.GetAuctionPriceByItemID(addonName, basicReagents[i][j].itemID) or 0,
         }
      end
      craftingReagents[i] = basicReagents[i][1];
   end
   for index, value in pairs(reagentsImpact) do
      -- print(index, value.name, value.bonusSkill, value.bonusDifficulty, value.cost, value.tierIncreaseCostDiff)
   end

   local filteredBasicReagents = {};
   for i = 1, #basicReagents, 1 do
      filteredBasicReagents[i] = {};
      for j = #basicReagents[i], 1, -1 do
         if (j < #basicReagents[i]) then
            if (reagentsImpact[basicReagents[i][j].itemID].cost < reagentsImpact[basicReagents[i][j + 1].itemID].cost) then
               table.insert(filteredBasicReagents[i], 1, basicReagents[i][j]);
            end
         else
            table.insert(filteredBasicReagents[i], 1, basicReagents[i][j]);
         end
      end
   end

   craftingReagents = {}
   for i = 1, #filteredBasicReagents, 1 do
      table.insert(craftingReagents, basicReagents[i][1]);
   end

   local currentDistributionIteration = {}

   for i = 1, #filteredBasicReagents, 1 do
      currentDistributionIteration[i] = {};
      for j = #filteredBasicReagents[i], 1, -1 do
         table.insert(currentDistributionIteration[i], 0);
      end
      currentDistributionIteration[i][1] = filteredBasicReagents[i][1].quantity;
      -- print("q", filteredBasicReagents[i][1].quantity);
   end

   local reagentsToIterateOn = #filteredBasicReagents;


   local function getfilteredBasicReagentsFromPermutation(permutation)
      local craftingReagents = {}
      for i = 1, #filteredBasicReagents, 1 do
         for j = 1, #filteredBasicReagents[i], 1 do
            if permutation[i][j] > 0 then
               table.insert(craftingReagents, {
                  name = filteredBasicReagents[i][j].name,
                  itemID = filteredBasicReagents[i][j].itemID,
                  dataSlotIndex = filteredBasicReagents[i][j].dataSlotIndex,
                  quantity = permutation[i][j],
               })
            end
         end
      end
      return craftingReagents
   end
   local function printPermutation(permutation)
      local craftingReagents = getfilteredBasicReagentsFromPermutation(permutation)

      local permutationCraftingOperationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents, "",
         false)

      local hyperlink = C_TradeSkillUI.GetRecipeOutputItemData(recipeInfo.recipeID, craftingReagents).hyperlink;
      local itemQuality = C_TradeSkillUI.GetItemCraftedQualityByItemInfo(hyperlink);
      local effectiveILvl, isPreview, baseILvl = C_Item.GetDetailedItemLevelInfo(hyperlink);
      local printit =
          hyperlink .. " - " .. (itemQuality or "") .. "/" .. (effectiveILvl or "") ..
          " - "
          .. "bonusSkill: " .. permutationCraftingOperationInfo.bonusSkill .. " - "
          .. "craftingQuality: " .. permutationCraftingOperationInfo.craftingQuality .. " - "
          .. "quality: " .. permutationCraftingOperationInfo.quality .. " - "
          .. "craftingQualityID: " .. permutationCraftingOperationInfo.craftingQualityID .. " - "
          .. "lowerSkillThreshold: " .. permutationCraftingOperationInfo.lowerSkillThreshold .. " - "
          .. "upperSkillTreshold: " .. permutationCraftingOperationInfo.upperSkillTreshold .. " - "
      ;
      for i, v in ipairs(permutation) do
         printit = printit .. "("
         for xi, xv in ipairs(v) do
            printit = printit .. xv .. ", "
         end
         printit = printit .. "), "
      end
      -- print(printit);
   end
   local basicsReagentsPermutationSkillCost = {}
   local function addPermutation(permutation)
      local permutationInfo = {}
      permutationInfo.cost = 0;
      permutationInfo.bonusSkill = 0;
      permutationInfo.permutation = {};

      -- copy permutation
      for i = 1, #permutation, 1 do
         permutationInfo.permutation[i] = {}
         for j = 1, #permutation[i], 1 do
            permutationInfo.permutation[i][j] = permutation[i][j]
            permutationInfo.bonusSkill = permutationInfo.bonusSkill +
                reagentsImpact[filteredBasicReagents[i][j].itemID].bonusSkill * permutation[i][j];
            permutationInfo.cost = permutationInfo.cost +
                reagentsImpact[filteredBasicReagents[i][j].itemID].cost * permutation[i][j];
         end
      end
      table.insert(basicsReagentsPermutationSkillCost, permutationInfo);
   end
   local function permutateOverReagents(currentDistributionIteration, reagentNo)
      if reagentNo > #currentDistributionIteration then
         addPermutation(currentDistributionIteration)
      else
         local finished = false;
         while (not finished) do
            -- do
            permutateOverReagents(currentDistributionIteration, reagentNo + 1);
            -- move one
            finished = true;
            for i = 1, #currentDistributionIteration[reagentNo] - 1, 1 do
               if (currentDistributionIteration[reagentNo][i] > 0) then
                  currentDistributionIteration[reagentNo][i] = currentDistributionIteration[reagentNo][i] - 1;
                  currentDistributionIteration[reagentNo][i + 1] = currentDistributionIteration[reagentNo][i + 1] + 1;
                  finished = false;
               end
            end
         end
         currentDistributionIteration[reagentNo][1] = currentDistributionIteration[reagentNo]
             [#currentDistributionIteration[reagentNo]];
         for i = 2, #currentDistributionIteration[reagentNo], 1 do
            currentDistributionIteration[reagentNo][i] = 0;
         end
      end
      -- if reagentNo == #filteredBasicReagents
   end
   permutateOverReagents(currentDistributionIteration, 1);

   table.sort(basicsReagentsPermutationSkillCost, function(a, b)
      return math.floor(a.bonusSkill) < math.floor(b.bonusSkill) or
          math.floor(a.bonusSkill) == math.floor(b.bonusSkill) and a.cost > b.cost;
   end)

   -- remove those that increase cost
   local largestCost = basicsReagentsPermutationSkillCost[#basicsReagentsPermutationSkillCost].cost
   local basicsFilteredReagentsPermutationSkillCost = {};
   for i = #basicsReagentsPermutationSkillCost, 1, -1 do
      if (basicsReagentsPermutationSkillCost[i].cost <= largestCost) then
         table.insert(basicsFilteredReagentsPermutationSkillCost, basicsReagentsPermutationSkillCost[i]);
         largestCost = basicsReagentsPermutationSkillCost[i].cost
      end
   end

   -- print
   for i, permutationInfo in ipairs(basicsFilteredReagentsPermutationSkillCost) do
      -- print(baseCraftingOperationInfo.bonusSkill + permutationInfo.bonusSkill, permutationInfo.cost)
      printPermutation(permutationInfo.permutation)
   end
   -- printPermutation(permutation)

   -- find reachable item tiers
   local basicReachableItemTiers = {};

   local function getReagentsForPermutation(permutation)
      local craftingReagents = {}
      for i = 1, #filteredBasicReagents, 1 do
         for j = 1, #filteredBasicReagents[i], 1 do
            if permutation[i][j] > 0 then
               table.insert(craftingReagents, {
                  name = filteredBasicReagents[i][j].name,
                  itemID = filteredBasicReagents[i][j].itemID,
                  dataSlotIndex = filteredBasicReagents[i][j].dataSlotIndex,
                  quantity = permutation[i][j],
               })
            end
         end
      end
      return craftingReagents;
   end

   local function getCraftingOperationInfoForPermutation(permutation)
      local craftingReagents = getReagentsForPermutation(permutation)

      return C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents,
         "",
         false);
   end

   local lowestSkillPermutation = basicsFilteredReagentsPermutationSkillCost
       [#basicsFilteredReagentsPermutationSkillCost].permutation;

   local lowestSkillPermutationCraftingOperationInfo = getCraftingOperationInfoForPermutation(lowestSkillPermutation)

   table.insert(basicReachableItemTiers,
      {
         tier = lowestSkillPermutationCraftingOperationInfo.craftingQuality,
         skillThreshold =
             lowestSkillPermutationCraftingOperationInfo.lowerSkillThreshold
      });
   if (lowestSkillPermutationCraftingOperationInfo.lowerSkillThreshold ~= lowestSkillPermutationCraftingOperationInfo.upperSkillTreshold) then
      table.insert(basicReachableItemTiers,
         {
            tier = lowestSkillPermutationCraftingOperationInfo.craftingQuality + 1,
            skillThreshold =
                lowestSkillPermutationCraftingOperationInfo.upperSkillTreshold
         });
   end
   local basicReachableItemTiersMaxTierFound = false;
   for i = #basicsFilteredReagentsPermutationSkillCost, 1, -1 do
      ---- print(basicsFilteredReagentsPermutationSkillCost[i].bonusSkill)
      if (baseCraftingOperationInfo.bonusSkill + baseCraftingOperationInfo.baseSkill + basicsFilteredReagentsPermutationSkillCost[i].bonusSkill >= basicReachableItemTiers[#basicReachableItemTiers].skillThreshold) then
         local craftingOperationInfoForPermutation = getCraftingOperationInfoForPermutation(
            basicsFilteredReagentsPermutationSkillCost[i].permutation);
         ---- print("o co chodzi", craftingOperationInfoForPermutation.craftingQuality + 1,
         -- craftingOperationInfoForPermutation.lowerSkillThreshold,
         -- craftingOperationInfoForPermutation.upperSkillTreshold)
         if (craftingOperationInfoForPermutation.lowerSkillThreshold ~= craftingOperationInfoForPermutation.upperSkillTreshold) then
            table.insert(basicReachableItemTiers,
               {
                  tier = craftingOperationInfoForPermutation.craftingQuality + 1,
                  skillThreshold =
                      craftingOperationInfoForPermutation.upperSkillTreshold
               });
         else
            basicReachableItemTiersMaxTierFound = true;
         end
      end
   end
   for index, value in ipairs(basicReachableItemTiers) do
      -- print("initial tiers", basicReachableItemTiers[index].tier, basicReachableItemTiers[index].skillThreshold)
   end






   -- figour out possible modyfing increases of diffuculty
   local modyfingReagents = AddonNS.recipeUtils.GetReagents(recipeInfo, Enum.CraftingReagentType.Modifying)
   -- -- -- ---- print("modyfingReagents", #modyfingReagents)

   local craftingReagents = {}
   for i = 1, #basicReagents, 1 do
      table.insert(craftingReagents, basicReagents[i][1]);
   end

   local modyfingReagentsImpact = {}
   local function getIncreasedDifficulty(reagent)
      if (not modyfingReagentsImpact[reagent.itemID]) then
         table.insert(craftingReagents, reagent);
         local operationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents, "", false);
         modyfingReagentsImpact[reagent.itemID] = (operationInfo.bonusDifficulty - baseCraftingOperationInfo.bonusDifficulty) /
             reagent.quantity;
         reagentsImpact[reagent.itemID] = {
            bonusSkill = (operationInfo.bonusSkill - baseCraftingOperationInfo.bonusSkill) /
                reagent.quantity,
            bonusDifficulty = (operationInfo.bonusDifficulty - baseCraftingOperationInfo.bonusDifficulty) /
                reagent.quantity,
            name = reagent.name,
            cost = Auctionator and
                Auctionator.API.v1.GetAuctionPriceByItemID(addonName, reagent.itemID) or 0,
         }
         craftingReagents[#craftingReagents] = nil;
      end
      return modyfingReagentsImpact[reagent.itemID];
   end
   local increasedDifficultyTable = {};
   for slotName, reagents in pairs(modyfingReagents) do
      ---- print("modyfingReagents", slotName)
      local slotDifficultyIncrease = {};
      for index, reagent in ipairs(reagents) do
         slotDifficultyIncrease[getIncreasedDifficulty(reagent)] = true;
      end
      increasedDifficultyTable[slotName] = slotDifficultyIncrease;
   end

   local increaseDiffcombinationsTableHelper = {};
   local possibleDiffIncreases = {};

   local i = 1;
   for slotName, value in pairs(increasedDifficultyTable) do
      increaseDiffcombinationsTableHelper[i] = { 0 } -- as we do not have to use those, so zero should always be there.
      increaseDiffcombinationsTableHelper[i].slotName = slotName;
      for key, v in pairs(value) do
         if key ~= 0 then
            table.insert(increaseDiffcombinationsTableHelper[i], key);
         end
         ---- print(slotName, key);
      end
      i = i + 1;
   end
   function calculateModyfingIncreasedDiff(i, sum, combination) -- todo: this when increaseDiffcombinationsTableHelper is empty will create one possible diffIncrease with zero. If it is not empty, then will contain the  0 iteration. So handling empty, or set to nothing is done in two separate places which can easily lead to an error so this should be somehow cleared.
      -- ---- print(i, sum)
      if (i > #increaseDiffcombinationsTableHelper) then
         possibleDiffIncreases[sum] = possibleDiffIncreases[sum] or {};
         local combinationCopy = {}
         for i, v in pairs(combination) do
            combinationCopy[i] = v;
         end
         table.insert(possibleDiffIncreases[sum], combinationCopy);
         return
      end
      local oldI = i;
      i = i + 1;
      for index, value in ipairs(increaseDiffcombinationsTableHelper[oldI]) do
         combination[increaseDiffcombinationsTableHelper[oldI].slotName] = value;
         calculateModyfingIncreasedDiff(i, sum + value, combination);
         combination[increaseDiffcombinationsTableHelper[oldI].slotName] = nil -- this is not needed
      end
   end

   calculateModyfingIncreasedDiff(1, 0, {})
   for key, value in pairs(possibleDiffIncreases) do
      ---- print("==========")
      ---- print("diff", key);
      for index, value2 in ipairs(value) do
         for key3, value3 in pairs(value2) do
            ---- print(index, key3, value3);
         end
         ---- print("---------")
      end
   end



   -- finishing [i think this can be a duplicate of the above, its just different field access ie. to bonus skill, not difficulty and reagent type]
   local finishingReagents = AddonNS.recipeUtils.GetReagents(recipeInfo, Enum.CraftingReagentType.Finishing)
   -- ---- print("modyfingReagents", #modyfingReagents)

   local craftingReagents = {}
   for i = 1, #basicReagents, 1 do
      table.insert(craftingReagents, basicReagents[i][1]);
   end

   local finishingReagentsImpact = {}
   local function getIncreasedSkill(reagent)
      if (not finishingReagentsImpact[reagent.itemID]) then
         table.insert(craftingReagents, reagent);
         local operationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents, "", false);
         finishingReagentsImpact[reagent.itemID] = (operationInfo.bonusSkill - baseCraftingOperationInfo.bonusSkill) /
             reagent.quantity;

         reagentsImpact[reagent.itemID] = {
            bonusSkill = (operationInfo.bonusSkill - baseCraftingOperationInfo.bonusSkill) /
                reagent.quantity,
            bonusDifficulty = (operationInfo.bonusDifficulty - baseCraftingOperationInfo.bonusDifficulty) /
                reagent.quantity,
            name = reagent.name,
            cost = Auctionator and
                Auctionator.API.v1.GetAuctionPriceByItemID(addonName, reagent.itemID) or 0,
         }
         craftingReagents[#craftingReagents] = nil;
      end
      return finishingReagentsImpact[reagent.itemID];
   end
   local increasedSkillTable = {};
   for slotName, reagents in pairs(finishingReagents) do
      ---- print("finishingReagents", slotName)
      local slotSkillIncrease = {};
      for index, reagent in ipairs(reagents) do
         slotSkillIncrease[getIncreasedSkill(reagent)] = true;
      end
      increasedSkillTable[slotName] = slotSkillIncrease;
   end


   local increaseSkillcombinationsTableHelper = {};
   local possibleSkillIncreases = {};
   local i = 1;
   for slotName, value in pairs(increasedSkillTable) do
      increaseSkillcombinationsTableHelper[i] = { 0 } -- as we do not have to use those, so zero should always be there.
      increaseSkillcombinationsTableHelper[i].slotName = slotName;
      for key, v in pairs(value) do
         if key ~= 0 then
            table.insert(increaseSkillcombinationsTableHelper[i], key);
         end
         ---- print(slotName, key);
      end
      i = i + 1;
   end
   local function calculateFinishingIncreasedSkill(i, sum, combination)
      -- ---- print(i, sum)
      if (i > #increaseSkillcombinationsTableHelper) then
         possibleSkillIncreases[sum] = possibleSkillIncreases[sum] or {};
         local combinationCopy = {}
         for i, v in pairs(combination) do
            combinationCopy[i] = v;
         end
         table.insert(possibleSkillIncreases[sum], combinationCopy);
         return
      end
      local oldI = i;
      i = i + 1;
      for index, value in ipairs(increaseSkillcombinationsTableHelper[oldI]) do
         combination[increaseSkillcombinationsTableHelper[oldI].slotName] = value;
         calculateFinishingIncreasedSkill(i, sum + value, combination);
         combination[increaseSkillcombinationsTableHelper[oldI].slotName] = nil -- this is not needed
      end
   end

   calculateFinishingIncreasedSkill(1, 0, {})
   -- for combinationsSkillIncrease, combinations in pairs(possibleSkillIncreases) do
   --    print("==========")
   --    print("diff", combinationsSkillIncrease);
   --    for combinationNo, reagents in ipairs(combinations) do
   --       for reagentSlot, reagentSkillIncrease in pairs(reagents) do
   --          print(combinationNo, reagentSlot, reagentSkillIncrease);
   --       end
   --       print("---------")
   --    end
   -- end



   --- update with finishing
   function findFinishingReagent(slotName, increaseInSkill)
      for i, reagent in ipairs(finishingReagents[slotName]) do
         if (getIncreasedSkill(reagent) == increaseInSkill) then
            return reagent;
         end;
      end
   end

   if not basicReachableItemTiersMaxTierFound then
      for key, combinationsOfReagents in pairs(possibleSkillIncreases) do
         if (baseCraftingOperationInfo.bonusSkill + baseCraftingOperationInfo.baseSkill + basicsFilteredReagentsPermutationSkillCost[1].bonusSkill + key >= basicReachableItemTiers[#basicReachableItemTiers].skillThreshold) then
            local craftingReagents = getReagentsForPermutation(
               basicsFilteredReagentsPermutationSkillCost[1].permutation);

            for slotName, increaseInSkill in pairs(combinationsOfReagents[1]) do
               table.insert(craftingReagents, findFinishingReagent(slotName, increaseInSkill))
            end

            local craftingOperationInfoForPermutation = C_TradeSkillUI.GetCraftingOperationInfo(recipeID,
               craftingReagents,
               "",
               false);
            ---- print("skill - ",craftingOperationInfoForPermutation.craftingQuality, craftingOperationInfoForPermutation.bonusSkill, craftingOperationInfoForPermutation.lowerSkillThreshold, craftingOperationInfoForPermutation.upperSkillTreshold)
            if (craftingOperationInfoForPermutation.lowerSkillThreshold ~= craftingOperationInfoForPermutation.upperSkillTreshold) then
               table.insert(basicReachableItemTiers,
                  {
                     tier = craftingOperationInfoForPermutation.craftingQuality + 1,
                     skillThreshold =
                         craftingOperationInfoForPermutation.upperSkillTreshold
                  });
            end
         end
      end
   end
   for index, value in ipairs(basicReachableItemTiers) do
      -- print("extended", basicReachableItemTiers[index].tier, basicReachableItemTiers[index].skillThreshold)
   end





   --- extend reachble tiers with modyfing increased difficulty
   ---
   local alltiers = {};
   for index, value in ipairs(basicReachableItemTiers) do
      -- print("extended", basicReachableItemTiers[index].tier, basicReachableItemTiers[index].skillThreshold)
      -- table.insert(alltiers, {tier = basicReachableItemTiers[index].tier, skillThreshold = basicReachableItemTiers[index].skillThreshold})
      for key, value in pairs(possibleDiffIncreases) do
         table.insert(alltiers,
            {
               tier = basicReachableItemTiers[index].tier,
               skillThreshold = basicReachableItemTiers[index].skillThreshold +
                   key,
               modyfingDiffIncreased = key,
               modyfingCombinations = value
            })
      end
   end
   table.sort(alltiers, function(a, b)
      return a.skillThreshold < b.skillThreshold;
   end)

   -- for index, value in ipairs(alltiers) do
   --   -- print("alltiers", alltiers[index].tier, alltiers[index].skillThreshold, alltiers[index].modyfingDiffIncreased,
   --       -- alltiers[index].modyfingCombinations and #alltiers[index].modyfingCombinations)
   -- end



   local basicsFilteredReagentsPermutationSkillCostNo = #basicsFilteredReagentsPermutationSkillCost;
   -- local finishingReagentsBoostNo = 1;
   local finishingPossibleSkillIncreases = {};
   for combinationsSkillIncrease, combinations in pairs(possibleSkillIncreases) do
      table.insert(finishingPossibleSkillIncreases, combinationsSkillIncrease);
   end
   table.sort(finishingPossibleSkillIncreases);

   local finishingForTierFound = {};

   local finalTiers = {}
   local function createNewFinalTier(tier)
      local newTier = {};
      for key, value in pairs(tier) do
         newTier[key] = value;
      end
      table.insert(finalTiers, newTier)
      return newTier;
   end

   for index, tier in ipairs(alltiers) do
      while (basicsFilteredReagentsPermutationSkillCostNo > 0 and basicsFilteredReagentsPermutationSkillCost[basicsFilteredReagentsPermutationSkillCostNo].bonusSkill + baseCraftingOperationInfo.bonusSkill + baseCraftingOperationInfo.baseSkill < tier.skillThreshold) do
         for i, finishingSkillIncreaseValue in ipairs(finishingPossibleSkillIncreases) do
            finishingForTierFound[index] = finishingForTierFound[index] or {};
            if (not finishingForTierFound[index][finishingSkillIncreaseValue]) then
               if (basicsFilteredReagentsPermutationSkillCost[basicsFilteredReagentsPermutationSkillCostNo].bonusSkill + baseCraftingOperationInfo.bonusSkill + baseCraftingOperationInfo.baseSkill + finishingSkillIncreaseValue >= tier.skillThreshold) then
                  finishingForTierFound[index][finishingSkillIncreaseValue] = true;
                  finishingForTierFound[index].found = true;
                  local newTier = createNewFinalTier(tier);
                  newTier.skill = basicsFilteredReagentsPermutationSkillCost
                      [basicsFilteredReagentsPermutationSkillCostNo]
                      .bonusSkill + baseCraftingOperationInfo.bonusSkill + baseCraftingOperationInfo.baseSkill +
                      finishingSkillIncreaseValue;
                  newTier.finishingSkillIncrease = finishingSkillIncreaseValue;
                  newTier.permutation = basicsFilteredReagentsPermutationSkillCost
                      [basicsFilteredReagentsPermutationSkillCostNo]
                      .permutation;
                  newTier.basicCost = basicsFilteredReagentsPermutationSkillCost
                      [basicsFilteredReagentsPermutationSkillCostNo].cost;
                  newTier.basicBonusSkill = basicsFilteredReagentsPermutationSkillCost
                      [basicsFilteredReagentsPermutationSkillCostNo]
                      .bonusSkill
               end
            end
         end

         basicsFilteredReagentsPermutationSkillCostNo = basicsFilteredReagentsPermutationSkillCostNo - 1;
      end

      if (basicsFilteredReagentsPermutationSkillCostNo > 0) then
         local newTier = createNewFinalTier(tier);
         newTier.skill = basicsFilteredReagentsPermutationSkillCost[basicsFilteredReagentsPermutationSkillCostNo]
             .bonusSkill + baseCraftingOperationInfo.bonusSkill + baseCraftingOperationInfo.baseSkill;
         newTier.permutation = basicsFilteredReagentsPermutationSkillCost[basicsFilteredReagentsPermutationSkillCostNo]
             .permutation;
         newTier.basicCost = basicsFilteredReagentsPermutationSkillCost[basicsFilteredReagentsPermutationSkillCostNo]
             .cost;
         newTier.basicBonusSkill = basicsFilteredReagentsPermutationSkillCost
             [basicsFilteredReagentsPermutationSkillCostNo]
             .bonusSkill
      elseif (not finishingForTierFound[index] or not finishingForTierFound[index].found) then
         createNewFinalTier(tier);
      end

      -- for combinationsSkillIncrease, combinations in pairs(possibleSkillIncreases) do
      --    print("==========")
      --    print("diff", combinationsSkillIncrease);
      --    for combinationNo, reagents in ipairs(combinations) do
      --       for reagentSlot, reagentSkillIncrease in pairs(reagents) do
      --          print(combinationNo, reagentSlot, reagentSkillIncrease);
      --       end
      --       print("---------")
      --    end
      -- end
      -- if (basicsFilteredReagentsPermutationSkillCostNo == 0) then
      --    -- print("finishingPossibleSkillIncreases[finishingReagentsBoostNo]",
      --    --    finishingPossibleSkillIncreases[finishingReagentsBoostNo])
      --    while (finishingReagentsBoostNo <= #finishingPossibleSkillIncreases and basicsFilteredReagentsPermutationSkillCost[1].bonusSkill + baseCraftingOperationInfo.bonusSkill + baseCraftingOperationInfo.baseSkill + finishingPossibleSkillIncreases[finishingReagentsBoostNo] < tier.skillThreshold) do
      --       -- print("finishingPossibleSkillIncreases[finishingReagentsBoostNo]",
      --       --    finishingPossibleSkillIncreases[finishingReagentsBoostNo])
      --       finishingReagentsBoostNo = finishingReagentsBoostNo + 1;
      --    end

      --    if (finishingReagentsBoostNo <= #finishingPossibleSkillIncreases) then
      --       tier.skill = basicsFilteredReagentsPermutationSkillCost[1]
      --           .bonusSkill + baseCraftingOperationInfo.bonusSkill + baseCraftingOperationInfo.baseSkill +
      --           finishingPossibleSkillIncreases[finishingReagentsBoostNo];
      --       tier.finishingSkillIncrease = finishingPossibleSkillIncreases[finishingReagentsBoostNo];
      --       tier.permutation = basicsFilteredReagentsPermutationSkillCost[1]
      --           .permutation;
      --       tier.basicCost = basicsFilteredReagentsPermutationSkillCost[1].cost;
      --       tier.basicBonusSkill = basicsFilteredReagentsPermutationSkillCost[1]
      --           .bonusSkill
      --    end
      -- end
   end

   -- for index, value in ipairs(alltiers) do
   --   -- print("Final", alltiers[index].tier, alltiers[index].skillThreshold, alltiers[index].modyfingDiffIncreased,
   --       -- alltiers[index].modyfingCombinations and #alltiers[index].modyfingCombinations)
   --    if (alltiers[index].permutation) then printPermutation(alltiers[index].permutation); end
   -- end




   G_alltiers = alltiers
   -- local columns = {"Modyfing required", "Basic", "Basic cost", "Modyfing", "Finishing",  "Difficulty", "Tier"}; -- "Modyfing diff increased", wewnatrz modyfing, "ilvl comes from modyfing required"
   -- local rows = {};
   local modyfingOrder = {};
   for key, diffIncrease in pairs(alltiers[1].modyfingCombinations[1]) do
      table.insert(modyfingOrder, key)
   end
   table.sort(modyfingOrder);
   local toDisplay = {}
   for index, tier in ipairs(finalTiers) do
      local basicPrint = "";
      if tier.permutation then
         local basicReagents = getfilteredBasicReagentsFromPermutation(tier.permutation)
         local currentItemName;
         for i, v in ipairs(basicReagents) do
            if currentItemName ~= v.name then
               -- if currentItemName then
               --    basicPrint = basicPrint .. ", "
               -- end
               currentItemName = v.name;
               local iconId =
                   C_Item.GetItemIconByID(v.itemID)

               basicPrint = basicPrint .. "|T" .. iconId .. ":16|t";
            end
            -- print(currentItemName)
            basicPrint = basicPrint
                --  .. "["
                --  .. "|A:Professions-Icon-Quality-Tier"
                .. reagentsImpact[v.itemID].tier
                --  .. ":25:25|a"
                .. ":" .. v.quantity .. ","
         end
         if tier.finishingSkillIncrease then
            basicPrint = basicPrint .. " +" .. tier.finishingSkillIncrease .. "b";
         end
      else
         basicPrint = "unreachable"
      end



      local row = {
         -- modyfingRequired=,
         basic = basicPrint,
         basicCost = tier.basicCost,
         skill = tier.skill,
         modyfing = tier.modyfingDiffIncreased,
         -- modyfingDiffIncreased = modyfingDiffIncreased,
         -- finishing=,
         difficulty = tier.skillThreshold,
         tier = tier.tier
      }
      table.insert(toDisplay, row)


      -- for i, modyfingCombination in ipairs(tier.modyfingCombinations) do -- I think this should be in the printing function of the array
      --    local modyfingCombinationPrint
      --    if #modyfingOrder == 0 then
      --       modyfingCombinationPrint = "";
      --    else
      --       modyfingCombinationPrint = "";
      --       for i, v in ipairs(modyfingOrder) do
      --          modyfingCombinationPrint = modyfingCombinationPrint .. modyfingCombination[v];
      --          if (i < #modyfingOrder) then
      --             modyfingCombinationPrint = modyfingCombinationPrint .. "+"
      --          else
      --             modyfingCombinationPrint = modyfingCombinationPrint .. "=" .. tier.modyfingDiffIncreased;
      --          end
      --       end
      --       -- modyfingCombinationPrint = modyfingCombinationPrint .. ")";
      --    end


      --    local row = {
      --       -- modyfingRequired=,
      --       basic = basicPrint,
      --       basicCost = tier.basicCost,
      --       basicBonusSkill = tier.basicBonusSkill,
      --       modyfing = modyfingCombinationPrint,
      --       -- modyfingDiffIncreased = modyfingDiffIncreased,
      --       -- finishing=,
      --       difficulty = tier.skillThreshold,
      --       tier = tier.tier
      --    }
      --    table.insert(toDisplay, row)
      -- end
   end
   G_toDisplay = toDisplay;





   -- for index, value in ipairs(basicReachableItemTiers) do
   --   -- print("initial tiers", basicReachableItemTiers[index].tier, basicReachableItemTiers[index].skillThreshold)
   -- end
   --------------==============================

   -- for i, permutationInfo in ipairs(basicsFilteredReagentsPermutationSkillCost) do
   --   -- print(baseCraftingOperationInfo.bonusSkill + permutationInfo.bonusSkill, permutationInfo.cost)
   --    local permutationCraftingOperationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents, "",
   --       false)

   --    printPermutation(permutationInfo.permutation)
   -- end






   -- AddonNS.recipeUtils.GetTierReagents(basicReagents, 1);


   -- -----------------------------------------
   --    -- Iterate over the reagent slots defined in the schematic
   --    for _, reagentSlot in ipairs(schematic.reagentSlotSchematics) do
   --       local reagentInfo = {}
   --       local name = #reagentSlot.reagents > 1 and
   --           (reagentSlot.slotText or reagentSlot.slotInfo and reagentSlot.slotInfo.slotText) or
   --           C_Item.GetItemNameByID(reagentSlot.reagents[1].itemID);
   --      -- print("Name:", name)
   --       -- Iterate over each reagent option in the current slot
   --       for _, reagent in ipairs(reagentSlot.reagents) do
   --         -- print(
   --             reagent.itemID,
   --             reagentSlot.quantityRequired,
   --             reagentSlot.dataSlotIndex
   --          )

   --          if (reagentSlot.quantityRequired) then
   --            -- print("weszlo")
   --             local craftingReagents = { {
   --                itemID = reagent.itemID,
   --                quantity = reagentSlot.quantityRequired,
   --                dataSlotIndex = reagentSlot.dataSlotIndex
   --             } }



   --             -- Simulate the crafting operation with this reagent
   --             local operationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, craftingReagents, "asd", false)

   --            -- print("operationInfo", operationInfo)
   --             -- local operationInfo = C_TradeSkillUI.GetCraftingOperationInfo(recipeID, {}, "asd", false)
   --             if (operationInfo) then
   --                -- Store the relevant information
   --                table.insert(reagentInfo, {
   --                   itemID = reagent.itemID,
   --                   itemLink = C_Item.GetItemNameByID(reagent.itemID), -- Optional: Get item link for display
   --                   baseDifficulty = operationInfo.baseDifficulty,
   --                   bonusDifficulty = operationInfo.bonusDifficulty,
   --                   baseSkill = operationInfo.baseSkill,
   --                   bonusSkill = operationInfo.bonusSkill,
   --                   quality = operationInfo.quality,
   --                   isQualityCraft = operationInfo.isQualityCraft,
   --                   craftingQualityID = operationInfo.craftingQualityID,
   --                   guaranteedCraftingQualityID = operationInfo.guaranteedCraftingQualityID or -1
   --                })
   --             end
   --            -- print("-----")
   --          end
   --       end

   --       -- Store the information for this reagent slot
   --       reagentImpact[reagentSlot.slotIndex] = {
   --          slotName = name or ("Slot " .. reagentSlot.slotIndex),
   --          reagents = reagentInfo
   --       }
   --      -- print("====")
   --    end


   --    local toDisplay = {};
   --    local function addToDisplay(ilvl, tier, binaryModifiers, illustrousInsightUsed, chance, difficulty, skill)
   --       -- if (chance > 0) then
   --       table.insert(toDisplay, {
   --          ilvl = ilvl,
   --          tier = tier,
   --          binaryModifiers = binaryModifiers,
   --          illustrousInsightUsed = illustrousInsightUsed,
   --          chance = chance,
   --          difficulty = difficulty,
   --          skill = skill
   --       });
   --       -- end
   --    end
   --    -- Print the results (or process as needed)
   --    for slotIndex, slotData in pairs(reagentImpact) do
   --      -- print("Slot:", slotData.slotName)
   --       for _, reagent in ipairs(slotData.reagents) do
   --         -- print(string.format(
   --             "  Reagent: %s (ItemID: %d) - Base Difficulty: %d, Bonus Difficulty: %d, Base Skill: %d, Bonus Skill: %d, Quality: %s, guaranteedCraftingQualityID: %d",
   --             reagent.itemLink, reagent.itemID, reagent.baseDifficulty, reagent.bonusDifficulty, reagent.baseSkill,
   --             reagent.bonusSkill, reagent.quality or "N/A", reagent.guaranteedCraftingQualityID)
   --          )
   --       end
   --    end


   --    addToDisplay(ilvlModifier.name, tier, binaryModifiersUsedGroup, illustrousInsightUsed, procChance,
   --       difficulty, skill)
   -- ---------------------------------------------------------------------------------------------------------
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
   AddonNS.gui:DisplayData(toDisplay,
      "Max skill: " ..
      (basicsFilteredReagentsPermutationSkillCost[1].bonusSkill + baseCraftingOperationInfo.bonusSkill + baseCraftingOperationInfo.baseSkill) ..
      ", "
      .. "Finishing max: " ..
      finishingPossibleSkillIncreases[#finishingPossibleSkillIncreases] .. ", "
      .. AddonNS.recipeUtils.getHighestTierItemLink(recipeInfo));
end

EventRegistry:RegisterCallback("ProfessionsRecipeListMixin.Event.OnRecipeSelected", self.OnRecipeSelected, self);
