--
-- GlobalCompany - Objects - GC_PalletCreator
--
-- @Interface: --
-- @Author: LS-Modcompany / GtX
-- @Date: 08.03.2019
-- @Version: 1.1.1.0
--
-- @Support: LS-Modcompany
--
-- Changelog:
--
-- 	v1.1.0.0 (08.03.2019):
-- 		- convert to fs19 
--		- add new functions (GtX)
--
-- 	v1.0.0.0 (26.06.2018):
-- 		- initial fs17 (GtX)
--
-- Notes:
--		- Parent script 'MUST' call delete().
--		- Parent script should call 'loadFromXMLFile' and 'saveToXMLFile' to save/load fillLevel that has not yet been added to a pallet.
--
--		- Using 'activateDebugDraw' in the xml file will display debug boxes and text showing spawn box only when 'Key F6' is pressed. This is for testing only!
--
--
-- ToDo:
--		- Multiplayer Event and warning message for no pallet space.
--

GC_PalletCreator = {};

local GC_PalletCreator_mt = Class(GC_PalletCreator);
InitObjectClass(GC_PalletCreator, "GC_PalletCreator");

GC_PalletCreator.debugIndex = g_company.debug:registerScriptName("PalletCreator");

g_company.palletCreator = GC_PalletCreator;

function GC_PalletCreator:new(isServer, isClient, customMt)
	local self = {};
	setmetatable(self, customMt or GC_PalletCreator_mt);

	self.isServer = isServer;
	self.isClient = isClient;

	self.extraParamater = nil;
	self.triggerManagerRegister = false;	
	
	self.deltaToAdd = 0;
	self.fullPallet = nil;
	self.otherObject = nil;
	self.palletToUse = nil;
	self.spawnerInUse = nil;
	self.locatedNodeId = nil;
	self.selectedPallet = nil;
	self.numberOfSpawners = 0;
	self.levelCheckTimerId = 0;

	return self;
end;

function GC_PalletCreator:load(nodeId, target, xmlFile, xmlKey, baseDirectory, permittedFillTypeIndex)
	if nodeId == nil or target == nil or xmlFile == nil or xmlKey == nil then
		local text = "Loading failed! 'nodeId' parameter = %s, 'target' parameter = %s 'xmlFile' parameter = %s, 'xmlKey' parameter = %s";
		g_company.debug:logWrite(GC_PalletCreator.debugIndex, GC_DebugUtils.DEV, text, nodeId ~= nil, target ~= nil, xmlFile ~= nil, xmlKey ~= nil);
		return false;
	end;

	self.debugData = g_company.debug:getDebugData(GC_PalletCreator.debugIndex, target);

	self.rootNode = nodeId;
	self.target = target;

	self.baseDirectory = GlobalCompanyUtils.getParentBaseDirectory(target, baseDirectory);

	local returnValue = false;
	local palletCreatorsKey = string.format("%s.palletCreators", xmlKey);

	local fillTypeName = getXMLString(xmlFile, palletCreatorsKey .. "#fillType");
	local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName);
	if fillTypeIndex ~= nil then
		if permittedFillTypeIndex == nil then
			permittedFillTypeIndex = fillTypeIndex;
		end;

		if fillTypeIndex == permittedFillTypeIndex then
			local filename = Utils.getNoNil(getXMLString(xmlFile, palletCreatorsKey .. "#xmlFilename"), "");
			self.palletFilename = Utils.getFilename(filename, self.baseDirectory);
			if self.palletFilename ~= nil and self.palletFilename ~= "" then
				self.palletFillTypeIndex = fillTypeIndex;
				self.palletFillUnitIndex = Utils.getNoNil(getXMLFloat(xmlFile, palletCreatorsKey .. "#fillUnitIndex"), 1);

				local palletCapacity = getXMLFloat(xmlFile, palletCreatorsKey .. "#palletCapacity");
				self.palletCapacity = math.max(Utils.getNoNil(palletCapacity, 0), 0);

				if self.palletCapacity > 0 then
					local sizeWidth, sizeLength, widthOffset, lengthOffset = StoreItemUtil.getSizeValues(self.palletFilename, "vehicle", 0, {});
					if sizeWidth ~= nil and sizeLength ~= nil then
						self.palletSizeWidth = sizeWidth;
						self.palletSizeLength = sizeLength;
						self.palletSizeWidthExtent = sizeWidth * 0.5;
						self.palletSizeLengthExtent = sizeLength * 0.5;
	
						local startFill = Utils.getNoNil(getXMLFloat(xmlFile, palletCreatorsKey .. "#startFillThreshold"), 1);
						self.startFillThreshold = math.max(startFill, 0.75); -- Minimum we will accept is 0.75 litres.
	
						self.showWarnings = Utils.getNoNil(getXMLBool(xmlFile, palletCreatorsKey .. "#showWarnings"), false); -- TO DO
	
						local i = 0;
						while true do
							local key = string.format("%s.palletCreator(%d)", palletCreatorsKey, i);
							if not hasXMLProperty(xmlFile, key) then
								break;
							end;
	
							local node = I3DUtil.indexToObject(nodeId, getXMLString(xmlFile, key .. "#node"), target.i3dMappings);
							if node ~= nil then
								if self.palletSpawners ~= nil then
									table.insert(self.palletSpawners, node);
								else
									self.palletSpawners = {node};
								end;

								local palletInteractionTrigger = I3DUtil.indexToObject(nodeId, getXMLString(xmlFile, key .. "#palletInteractionTrigger"), target.i3dMappings);
								if palletInteractionTrigger ~= nil then	
									if self.target.palletCreatorInteraction ~= nil then
										if self.palletInteractionTriggers == nil then
											self.palletInteractionTriggers = {};											
										end;
										
										-- Do this now so we can still check these loaded on the client side.
										if self.isServer then
											addTrigger(palletInteractionTrigger, "palletInteractionTriggerCallback", self);
										end;

										table.insert(self.palletInteractionTriggers, palletInteractionTrigger);
									else
										g_company.debug:writeModding(self.debugData, "'palletInteractionTrigger' can not be loaded! Parent script does not contain function 'palletCreatorInteraction(totalLevel, blockedLevel, deltaWaiting, fillTypeIndex, extraParamater)'.");
									end;
								end;
							end;
	
							i = i + 1;
						end;
	
						self.numberOfSpawners = #self.palletSpawners;
						
						if self.numberOfSpawners > 0 then	
							local activateDebugDraw = Utils.getNoNil(getXMLBool(xmlFile, palletCreatorsKey .. "#activateDebugDraw"), false);
							if self.isClient and activateDebugDraw then
								g_company.addUpdateable(self, self.debugDraw);								
								
								self.debugDrawData = {};
								for i = 1, self.numberOfSpawners do
									self.debugDrawData[i] = {name = "", id = ""};
									self.debugDrawData[i].name = getName(self.palletSpawners[i]);
									self.debugDrawData[i].id = string.format("<palletCreator(%d) />", i - 1);
									self.debugDrawData[i].colours = {0.5, 1.0, 0.5, 1.0};
								end;
								
								g_company.debug:writeWarning(self.debugData, "'drawDebug' is active at %s#activateDebugDraw! Make sure to disable this before release.", palletCreatorsKey);
							end;
							
							returnValue = true;
						else
							g_company.debug:writeModding(self.debugData, "No 'palletCreator' nodes have been found at %s", palletCreatorsKey);
						end;
					else
						g_company.debug:writeModding(self.debugData, "A store item using xml filename '%s' could not be found. ( %s#xmlFilename )", self.palletFilename, palletCreatorsKey);
					end;
				else
					g_company.debug:writeModding(self.debugData, "No 'palletCapacity' has been given, this should match capacity given in pallet xml file. ( %s )", palletCreatorsKey);
				end;
			else
				g_company.debug:writeModding(self.debugData, "'xmlFilename' key is 'nil' at %s#xmlFilename", palletCreatorsKey);
			end;
		end;
	end;

	return returnValue;
end;

function GC_PalletCreator:delete()
	if self.isClient and self.debugDrawData ~= nil then
		g_company.removeUpdateable(self);
	end;
	
	if self.isServer then
		if self.palletInteractionTriggers ~= nil then
			for i = 1, #self.palletInteractionTriggers do
				removeTrigger(self.palletInteractionTriggers[i]);
			end;
			self.palletInteractionTriggers = nil;
		end;
		
		if self.levelCheckTimerId ~= 0 then
			removeTimer(self.levelCheckTimerId);
		end;
	end;
end;

function GC_PalletCreator:debugDraw(dt)
	if self.debugDrawData ~= nil then
		for i = 1, self.numberOfSpawners do
			local spawner = self.palletSpawners[i];
			local x, y, z = getWorldTranslation(spawner);
			local rx, ry, rz = getWorldRotation(spawner);
			DebugUtil.drawOverlapBox(x, y - 5, z, rx, ry, rz, self.palletSizeWidthExtent, 10, self.palletSizeLengthExtent, 0.5, 1.0, 0.5);			
			Utils.renderTextAtWorldPosition(x, y + 5.5, z, self.debugDrawData[i].name, getCorrectTextSize(0.018), 0, self.debugDrawData[i].colours);
			Utils.renderTextAtWorldPosition(x, y + 5, z, self.debugDrawData[i].id, getCorrectTextSize(0.018), 0, self.debugDrawData[i].colours);
		end;
	end;
end;

function GC_PalletCreator:updatePalletCreators(delta, getBlockedLevel, includeDeltaToAdd)
	if self.isServer then
		self.deltaToAdd = self.deltaToAdd + delta;

		if self.deltaToAdd > 0 then
			if self.selectedPallet ~= nil then
				if self:checkPalletIsValid() then
					self:addToPallet();

					-- If we have 'deltaToAdd' then we must have finished filling last pallet?
					if self.deltaToAdd > 0 and self.deltaToAdd > self.startFillThreshold then
						self:findNextPallet(true);
					end;
				else
					if self.deltaToAdd > self.startFillThreshold then
						self:findNextPallet(true);
					end;
				end;
			else
				if self.deltaToAdd > self.startFillThreshold then
					self:findNextPallet(true);
				end;
			end;
		end;

		return self:getTotalFillLevel(getBlockedLevel, includeDeltaToAdd);
	else
		g_company.debug:writeDev(self.debugData, "'updatePalletCreators' is a client only function!");
	end;
end;

function GC_PalletCreator:addToPallet()
	if self.selectedPallet ~= nil then
		local appliedDelta = self.selectedPallet:addFillUnitFillLevel(self.target:getOwnerFarmId(), self.palletFillUnitIndex, self.deltaToAdd, self.palletFillTypeIndex, ToolType.UNDEFINED);
		self.deltaToAdd = self.deltaToAdd - appliedDelta;
	else
		self:sendWarning();
	end;
end;

function GC_PalletCreator:sendWarning() -- TO DO
	if self.showWarnings then
		if self:getNumFullPallets() == self.numberOfSpawners then
			-- Need to create a new event for this.
			print("Send to clients. ( All pallets are now full. )");
		end;
	end;
end;

function GC_PalletCreator:checkPalletIsValid()
	if self.spawnerInUse == nil then
		return false;
	end;

	local selectedPallet = self.selectedPallet;
	if entityExists(selectedPallet.rootNode) then
		if selectedPallet:getFillUnitFreeCapacity(self.palletFillUnitIndex) < 0.001 then
			return false;
		end;

		local x, _, z = localToLocal(selectedPallet.rootNode, self.spawnerInUse, 0, 0, 0);
		if x < 0 or z < 0 or x > self.palletSizeWidth or z > self.palletSizeLength then
			return false;
		end;
	else
		return false;
	end;

	return true;
end;

function GC_PalletCreator:findNextPallet(addToPallet)
	local nextSpawnerToUse;
	self.selectedPallet = nil;

	-- Fill all of the started pallets first.
	for i = 1, self.numberOfSpawners do
		local spawner = self.palletSpawners[i];

		self.locatedNodeId = 0;
		self.palletToUse = nil;
		self:checkSpawner(spawner);
		
		if self.palletToUse ~= nil then
			self.spawnerInUse = spawner;
			self.selectedPallet = self.palletToUse;
			break;
		else		
			if nextSpawnerToUse == nil then
				if self.locatedNodeId == 0 then
					nextSpawnerToUse = {spawner = spawner, spawnerId = i};
				end;
			end;
		end
	end;

	-- If no pallets to fill then find a free node to create a new one at.
	if self.selectedPallet == nil and nextSpawnerToUse ~= nil then
		self.spawnerInUse = nextSpawnerToUse.spawner;
		local x, _, z = getWorldTranslation(self.spawnerInUse);
		local _, ry, _ = getWorldRotation(self.spawnerInUse);
		self.selectedPallet = g_currentMission:loadVehicle(self.palletFilename, x, nil, z, 1.2, ry, true, 0, Vehicle.PROPERTY_STATE_OWNED, self.target:getOwnerFarmId(), nil, nil);

		-- We do not want to update 'target:palletCreatorInteraction()' when creating a new pallet.
		self.spawnedPallet = self.palletInteractionTriggers[nextSpawnerToUse.spawnerId] ~= nil;
	end;

	if addToPallet then
		self:addToPallet();
	end;
end;

function GC_PalletCreator:checkSpawner(spawner)
	self.spawner = spawner;
	local x, y, z = getWorldTranslation(spawner);
	local rx, ry, rz = getWorldRotation(spawner);
	local overlap = overlapBox(x, y - 5, z, rx, ry, rz, self.palletSizeWidthExtent, 10, self.palletSizeLengthExtent, "spawnAreaCallback", self, nil, true, false, true);

	return x, y, z, rx, ry, rz;
end;

function GC_PalletCreator:spawnAreaCallback(transformId)
	if transformId ~= g_currentMission.terrainRootNode and transformId ~= self.spawner then
		local object = g_currentMission:getNodeObject(transformId)
		if object ~= nil and object.isa ~= nil and object:isa(Vehicle) then
			self.locatedNodeId = transformId; -- Did we collide with another object?
			if object.typeName == "pallet" then
				if object:getFillUnitSupportsFillType(self.palletFillUnitIndex, self.palletFillTypeIndex) then
					self.palletInSpawner = object;
					if object:getFillUnitFillLevel(self.palletFillUnitIndex) < object:getFillUnitCapacity(self.palletFillUnitIndex) then
						self.palletToUse = object;
					else
						self.fullPallet = object;
					end;
				end;
			else
				self.otherObject = object;
			end;
		else
			if transformId ~= nil and getName(transformId) == "PlayerCCT" then				
				self.locatedNodeId = transformId; -- A player is standing in the spawn area.
			end;
		end;
	end;
end;

function GC_PalletCreator:loadFromXMLFile(xmlFile, key)
	self.deltaToAdd = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".palletCreator#deltaToAdd"), self.deltaToAdd);
end;

function GC_PalletCreator:saveToXMLFile(xmlFile, key, usedModNames)
	setXMLFloat(xmlFile, key .. ".palletCreator#deltaToAdd", self.deltaToAdd);
end;

function GC_PalletCreator:getTotalCapacity()
	return self.palletCapacity * self.numberOfSpawners;
end;

function GC_PalletCreator:getIndividualCapacity()
	return self.palletCapacity;
end;

function GC_PalletCreator:getTotalSpace()
	local pallets = {};
	local totalLevel = 0;
	local totalCapacity = self.palletCapacity * self.numberOfSpawners;

	for i = 1, self.numberOfSpawners do
		self.palletInSpawner = nil;
		self.otherObject = nil;
		self:checkSpawner(self.palletSpawners[i]);

		-- If spawn area is blocked then remove available capicity for this space.
		if self.otherObject ~= nil then
			totalCapacity = totalCapacity - self.palletCapacity;
		end;

		-- If we have a pallet then add it's level to total.
		if self.palletInSpawner ~= nil and pallets[self.palletInSpawner] ~= true then
			pallets[self.palletInSpawner] = true;
			totalLevel = totalLevel + self.palletInSpawner:getFillUnitFillLevel(self.palletFillUnitIndex);
		end;
	end;

	return totalCapacity - totalLevel;
end;

function GC_PalletCreator:getTotalFillLevel(getBlockedLevel, includeDeltaToAdd)
	local pallets, totalLevel, blockedLevel = {}, 0, 0;
	
	if includeDeltaToAdd == true then
		totalLevel = totalLevel + self.deltaToAdd;
	end;

	for i = 1, self.numberOfSpawners do
		self.palletInSpawner = nil;
		self.otherObject = nil;
		self:checkSpawner(self.palletSpawners[i]);		
		
		if self.palletInSpawner ~= nil then
			if pallets[self.palletInSpawner] ~= true then
				pallets[self.palletInSpawner] = true;
				totalLevel = totalLevel + self.palletInSpawner:getFillUnitFillLevel(self.palletFillUnitIndex);
			else
				-- If a pallet is sharing the spawn area with another pallet we count it as lost fill area. (e.g  + pallet capacity for the spawner).
				blockedLevel = blockedLevel + self.palletCapacity;
			end;
		else
			if self.otherObject ~= nil then
				-- If another object is blocking we count it as lost fill area. (e.g + pallet capacity for the spawner).
				blockedLevel = blockedLevel + self.palletCapacity;
			end;
		end;
	end;

	if getBlockedLevel == true then
		return totalLevel, blockedLevel;
	end;
	
	return totalLevel;
end;

function GC_PalletCreator:getDeltaWaiting()
	return self.deltaToAdd;
end;

function GC_PalletCreator:getNumFullPallets()
	local count = 0;

	for i = 1, self.numberOfSpawners do
		self.fullPallet = nil;
		self:checkSpawner(self.palletSpawners[i]);
		if self.fullPallet ~= nil then
			count = count + 1
		end
	end;

	return count;
end;

-- This can provide data for the gui. (FillLevel, Capacity and Vehicle Store Data [if in spawn area])
function GC_PalletCreator:getAllSpawnerData()
	local spawnerData = {};	
	
	for i = 1, self.numberOfSpawners do
		self.palletInSpawner = nil;
		self.otherObject = nil;
		self:checkSpawner(self.palletSpawners[i]);
		
		local spawner = {};		
		if self.palletInSpawner == nil then
			spawner.level = 0;
			spawner.capacity = 0;
			if self.otherObject ~= nil then
				spawner.vehicleStoreInfo = g_storeManager:getItemByXMLFilename(self.otherObject.configFileName:lower());
			end;
		else
			spawner.level = self.palletInSpawner:getFillUnitFillLevel(self.palletFillUnitIndex);
			spawner.capacity = self.palletCapacity;
		end;
		table.insert(spawnerData, spawner)
	end;	
	
	return spawnerData;
end;

function GC_PalletCreator:palletInteractionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if onEnter or onLeave then
		local object = g_currentMission:getNodeObject(otherShapeId);
		if object ~= nil and object.isa ~= nil and object:isa(Vehicle) and object.typeName == "pallet" then
			
			-- If another timer is set then remove it so we only check once.
			if self.levelCheckTimerId ~= 0 then
				removeTimer(self.levelCheckTimerId);
			end;

			-- Wait 2 seconds to do the check so we can make sure the pallet made it to the overlapBox area.
			self.levelCheckTimerId = addTimer(2000, "levelCheckTimerCallback", self);
		end;
	end;
end;

function GC_PalletCreator:levelCheckTimerCallback()
	if self.spawnedPallet ~= true then
		local level, blockedLevel = self:getTotalFillLevel(true);
		self.target:palletCreatorInteraction(level, blockedLevel, self.deltaToAdd, self.palletFillTypeIndex, self.extraParamater);
	end;

	self.spawnedPallet = false;
	self.levelCheckTimerId = 0;
	
	return false;
end;





