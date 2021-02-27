--
-- GlobalCompany - Triggers - GC_PlayerTrigger
--
-- @Interface: --
-- @Author: LS-Modcompany / kevink98 / GtX
-- @Date: 26.01.2019
-- @Version: 1.1.1.0
--
-- @Support: LS-Modcompany
--
-- Changelog:
-- 	v1.1.1.0 (26.01.2019):
--		- add function for set triggernode when don't use xml for loading
--
-- 	v1.1.0.0 (14.01.2019):
-- 		- convert to fs19,
--		- add TriggerManager support,
--		- add FS19 class update support,
--		- add new target update functions,
--		- add option to use as activatable (GtX)
--
-- 	v1.0.0.0 (19.05.2018):
-- 		- initial fs17 (kevink98)
--
-- Notes:
--		- Target functions: (isActivatable = true)
--			- playerTriggerActivated() [Activatable Only] - Updated 'once' when input is pressed.
--			- playerTriggerDrawActivate() [Activatable Only] - Updated each frame while player is in trigger.  (optional)
--			- playerTriggerGetActivateText() [Activatable Only] - Get the new input text to be displayed.  (optional)
--			- playerTriggerUpdate(dt) [All] - Updated each frame when player is in trigger.  (optional)
--
--
-- ToDo:
--
--

GC_PlayerTrigger = {};

local GC_PlayerTrigger_mt = Class(GC_PlayerTrigger, Object);
InitObjectClass(GC_PlayerTrigger, "GC_PlayerTrigger");
GC_PlayerTrigger.debugIndex = g_company.debug:registerScriptName("GC_PlayerTrigger");

g_company.playerTrigger = GC_PlayerTrigger;

function GC_PlayerTrigger:new(isServer, isClient, customMt)
	if customMt == nil then
		customMt = GC_PlayerTrigger_mt;
	end;

	local self = Object:new(isServer, isClient, customMt);

	self.isServer = isServer;
	self.isClient = isClient;

	self.triggerManagerRegister = true; -- 'GC_TriggerManager' Requirement.

	return self;
end

-- Load player trigger.
-- @param integer nodeId = id of node.
-- @param table target = target object (self).
-- @param integer xmlFile = id of xml object.
-- @param string xmlKey = xml key to load.
-- @param ______ triggerReference = reference [string], [integer], [table] or [float] value to send to target with functions.
-- @param boolean isActivatable = use activatable feature of trigger.
-- @param string activateText = text that will be displayed when player is in trigger. (Activatable Only)
-- @param boolean removeAfterActivated = remove activatable after input is pressed. (Activatable Only)
-- @return boolean true/false = load success or fail.
function GC_PlayerTrigger:load(nodeId, target, xmlFile, xmlKey, triggerReference, isActivatable, activateText, removeAfterActivated)
	if nodeId == nil or target == nil then
		return false;
	end;

	self.debugData = g_company.debug:getDebugData(GC_PlayerTrigger.debugIndex, target);

	self.rootNode = nodeId;
	self.target = target;
	self.triggerReference = triggerReference;

	self.playerInTrigger = false;
	self.isActivatable = Utils.getNoNil(isActivatable, false);

	if xmlFile ~= nil and xmlKey ~= nil then
		local playerTriggerNode = getXMLString(xmlFile, xmlKey .. "#playerTriggerNode");
		if not self:setTriggerNode(playerTriggerNode) then
			g_company.debug:logWrite(self.debugData, GC_DebugUtils.MODDING, "Error loading 'playerTriggerNode' %s!", playerTriggerNode);
		end;
	end;

	if self.isActivatable then
		if self.target.playerTriggerActivated ~= nil then
			self.removeAfterActivated = Utils.getNoNil(removeAfterActivated, false);
			self.activateText = Utils.getNoNil(activateText, g_i18n:getText("input_ACTIVATE_OBJECT"));
		else
			g_company.debug:logWrite(self.debugData, GC_DebugUtils.DEV, "function 'playerTriggerActivated' does not exist. 'isActivatable' is not an option.");
			self.isActivatable = false;
		end;
	end;

	return true;
end;

function GC_PlayerTrigger:setTriggerNode(playerTriggerNode)
	if playerTriggerNode ~= nil then
		self.playerTriggerNode = I3DUtil.indexToObject(self.rootNode, playerTriggerNode, self.target.i3dMappings);
		if self.playerTriggerNode ~= nil then
			addTrigger(self.playerTriggerNode, "playerTriggerCallback", self);
			return true;
		end;
	end;

	return false;
end;

function GC_PlayerTrigger:delete()
	if self.isActivatable and self.playerInTrigger then
		g_currentMission:removeActivatableObject(self);
	end;

	self.playerInTrigger = false;

	if self.playerTriggerNode ~= nil then
		removeTrigger(self.playerTriggerNode);
	end;
end;

function GC_PlayerTrigger:update(dt)
	if self.target.playerTriggerUpdate ~= nil then
		self.target:playerTriggerUpdate(dt, self.triggerReference);
	end;

	if self.playerInTrigger then
		if self:getIsActivatable() then
			if self.target.playerTriggerGetActivateText ~= nil then
				local text = self.target:playerTriggerGetActivateText(self.triggerReference);
				self:setActivateText(text);
			end;

			self:raiseActive();
		else
			self.playerInTrigger = false;

			if self.isActivatable then
				g_currentMission:removeActivatableObject(self);
			end;
		end;
	end;
end;

function GC_PlayerTrigger:getIsActivatable()
	return g_currentMission.controlPlayer and g_currentMission.controlledVehicle == nil;
end;

function GC_PlayerTrigger:onActivateObject()
	self.target:playerTriggerActivated(self.triggerReference);
end;

function GC_PlayerTrigger:shouldRemoveActivatable()
	return self.removeAfterActivated;
end;

function GC_PlayerTrigger:setActivateText(text)
	self.activateText = tostring(text);
end;

function GC_PlayerTrigger:getPlayerInTrigger()
	return self.playerInTrigger;
end;

function GC_PlayerTrigger:drawActivate()
	if self.target.playerTriggerDrawActivate ~= nil then
		self.target:playerTriggerDrawActivate(self.triggerReference);
	end;
end;

function GC_PlayerTrigger:playerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if (g_currentMission.controlPlayer and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode) then
		if onEnter or onLeave then
			if onEnter then
				self.playerInTrigger = true;

				if self.isActivatable then
					g_currentMission:addActivatableObject(self);
				end;
			elseif onLeave then
				self.playerInTrigger = false;

				if self.isActivatable then
					g_currentMission:removeActivatableObject(self);
				end;
			end;

			self:raiseActive();
		end;
	end;
end;





