--
-- GlobalCompany - Additionals - GC_BaleAddon
--
-- @Interface: 1.4.1.0 b5332
-- @Author: LS-Modcompany / aPuehri
-- @Date: 25.08.2019
-- @Version: 1.0.3.0
--
-- @Support: LS-Modcompany
--
-- Changelog:
--
-- 	v1.0.3.0 (23.06.2019)/(aPuehri):
-- 		- bugfixing
--
-- 	v1.0.2.0 (20.06.2019)/(aPuehri):
-- 		- changed client detection
-- 		- added Multiplayer-Support
--
-- 	v1.0.1.0 (01.06.2019)/(aPuehri):
-- 		- smaler changes
--
-- 	v1.0.0.0 (29.03.2019):
-- 		- initial fs19 (aPuehri)
--
--
-- Notes:
--
--
-- ToDo:
-- 
--
--

GC_BaleAddon = {};
local GC_BaleAddon_mt = Class(GC_BaleAddon);
InitObjectClass(GC_BaleAddon, "GC_BaleAddon");

GC_BaleAddon.debugIndex = g_company.debug:registerScriptName("GC_BaleAddon");
GC_BaleAddon.enableCutBale = false;
GC_BaleAddon.object = nil;
GC_BaleAddon.eventId = nil;
GC_BaleAddon.lastFoundBaleNetworkId = nil;

function GC_BaleAddon:load()
    Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, GC_BaleAddon.registerActionEvents);
    Player.removeActionEvents = Utils.appendedFunction(Player.removeActionEvents, GC_BaleAddon.removeActionEventsPlayer);
    --initialize
    GC_BaleAddon.eventName = {};
end;

function GC_BaleAddon:init()
    local self = setmetatable({}, GC_BaleAddon_mt);

    self.isServer = g_server ~= nil;
    self.isClient = g_dedicatedServerInfo == nil;
    self.isMultiplayer = g_currentMission.missionDynamicInfo.isMultiplayer;
    
    self.debugData = g_company.debug:getDebugData(GC_BaleAddon.debugIndex, g_company);

    self.eventId_CutBale = g_company.eventManager:registerEvent(self, self.cutBaleEvent);
    self.eventId_getCanCutBale = g_company.eventManager:registerEvent(self, self.getCanCutBaleEvent);
    self.eventId_sendCanCutBale = g_company.eventManager:registerEvent(self, self.sendCanCutBaleEvent, true);

    if self.isClient then
        g_company.addUpdateable(self, self.update);			
    end;

    g_company.settings:initSetting("cutBales", true);
    
    return self;
end;

function GC_BaleAddon:registerActionEvents()
    local result, eventName = InputBinding.registerActionEvent(g_inputBinding, 'GC_BALEADDON_CUT',self, GC_BaleAddon.actionCut ,false ,true ,false ,true);
    if result then
        table.insert(GC_BaleAddon.eventName, eventName);
        g_inputBinding:setActionEventTextVisibility(eventName, false);
    end;
end;

function GC_BaleAddon:removeActionEventsPlayer()
    GC_BaleAddon.eventName = {};
end;

function GC_BaleAddon:update(dt)
    if self.isClient then
        GC_BaleAddon.enableCutBale = false;
        GC_BaleAddon.eventId = self.eventId_CutBale;
        if g_company.settings:getSetting("cutBales", true) and g_currentMission.player.isControlled and not g_currentMission.player.isCarryingObject and not g_currentMission.player.superStrengthEnabled then
            if not self.isMultiplayer and g_currentMission.player.isObjectInRange then
                local foundObjectId = g_currentMission.player.lastFoundObject;
                if (foundObjectId ~= nil) and (foundObjectId ~= g_currentMission.terrainDetailId) then
                    local object = g_currentMission:getNodeObject(foundObjectId);                    
                    if (object~= nil) then 
                        if object:isa(Bale) then
                            if (object.typeName == nil) and (object.fillType ~= nil) and (object.fillLevel ~= nil) then
                                GC_BaleAddon.object = object;
                                GC_BaleAddon.enableCutBale = GC_BaleAddon:getCanCutBale(GC_BaleAddon.object, self, false);
                            end;
                        end;
                    end;
                end;
            elseif self.isMultiplayer and (GC_ObjectInfo.foundBale~= nil) then
                if GC_BaleAddon.object ~= GC_ObjectInfo.foundBale then
                    GC_BaleAddon.object = GC_ObjectInfo.foundBale;
                    if g_company.debug.printLevel[6] then
                        gc_debugPrint(GC_ObjectInfo.foundBale, nil, nil, "GC_BaleAddon - GC_ObjectInfo.foundBale");
                    end;
                end;
                if (GC_BaleAddon.object.typeName == nil) and (GC_BaleAddon.object.fillType ~= nil) and (GC_BaleAddon.object.fillLevel ~= nil) then
                    GC_BaleAddon.enableCutBale = GC_BaleAddon:getCanCutBale(GC_BaleAddon.object, self, false);
                end;
            end;	
        end;
        GC_BaleAddon:displayHelp(GC_BaleAddon.enableCutBale);
    end;
end;

function GC_BaleAddon:getCanCutBale(foundObject, ref, noEventSend)
    local self = ref;
   
    if (foundObject.fillLevel ~= nil) and (foundObject.fillType ~= nil) and (foundObject.nodeId ~= nil) and (foundObject.nodeId ~= 0) then
        if self.isClient and self.isMultiplayer then
            local networkId = NetworkUtil.getObjectId(foundObject);

            if GC_BaleAddon.lastFoundBaleNetworkId ~= networkId then
                GC_BaleAddon.lastFoundBaleNetworkId = networkId;
                self.canCut = nil;
                self:getCanCutBaleEvent({networkId}, noEventSend);
            end;
            return self.canCut;
        else
            local testDrop = g_densityMapHeightManager:getMinValidLiterValue(foundObject.fillType);
            local sx,sy,sz = getWorldTranslation(foundObject.nodeId);
            local radius = (DensityMapHeightUtil.getDefaultMaxRadius(foundObject.fillType) / 2);
            
            if DensityMapHeightUtil.getCanTipToGroundAroundLine(nil, testDrop, foundObject.fillType, sx, sy, sz, (sx + 0.1), (sy - 0.1), (sz + 0.1), radius, nil, 3, true, nil, true) then
                return true;
            end;            
        end;
    end;
    
    return false;
end;

function GC_BaleAddon:displayHelp(state)
    for i=1, #GC_BaleAddon.eventName, 1 do
        if (GC_BaleAddon.eventName[i] ~= nil) then
            g_inputBinding:setActionEventTextVisibility(GC_BaleAddon.eventName[i], state);
        end;	
    end;
end;

function GC_BaleAddon:actionCut(actionName, keyStatus, arg3, arg4, arg5)
    if GC_BaleAddon.enableCutBale and (GC_BaleAddon.object ~= nil) then
        GC_BaleAddon:cutBale(GC_BaleAddon.object, self.isServer, self.isClient, GC_BaleAddon.eventId, false);
    end;
end;

function GC_BaleAddon:cutBale(foundObject, isServer, isClient, eventId, noEventSend)   
    self.isServer = isServer;
    self.isClient = isClient;
    self.eventId = eventId;
    self.foundObjectNetworkId = NetworkUtil.getObjectId(foundObject);
    
    self:cutBaleEvent({self.foundObjectNetworkId}, foundObject, noEventSend);
end;

function GC_BaleAddon:cutBaleEvent(data, foundObject, noEventSend)      
    g_company.eventManager:createEvent(self.eventId, data, false, noEventSend);
    -- Arguments
    -- table	vehicle	vehicle that is tipping
    -- float	delta	delta to tip
    -- integer	filltype	fill type to tip
    -- float	sx	start x position
    -- float	sy	start y position
    -- float	sz	start z position
    -- float	ex	end x position
    -- float	ey	end y position
    -- float	ez	end z position
    -- float	innerRadius	inner radius
    -- float	radius	radius
    -- float	lineOffset	line offset
    -- boolean	limitToLineHeight	limit to line height
    -- table	occlusionAreas	occlusion areas
    -- boolean	useOcclusionAreas	use occlusion areas
    -- Return Values
    -- float	dropped	real fill level dropped
    -- float	lineOffset	line offset
    
    local object = nil;
    if self.isClient then
        object = foundObject;
    else
        object = NetworkUtil.getObject(data[1]);
    end;

    if object~= nil and type(object) == "table" then
        if object:isa(Bale) then
            if (object.fillLevel ~= nil) and (object.fillType ~= nil) then
                local sx,sy,sz = getWorldTranslation(object.nodeId);
                local radius = (DensityMapHeightUtil.getDefaultMaxRadius(object.fillType) / 2);
                local minLevel = g_densityMapHeightManager:getMinValidLiterValue(object.fillType);
                
                local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(nil, object.fillLevel, object.fillType, sx, sy, sz, (sx + 0.1), (sy - 0.1), (sz + 0.1), 0, radius, 3, false, nil, false);
                object:setFillLevel(object:getFillLevel() - dropped);
        
                if self.isServer then
                    if (object:getFillLevel() <= minLevel) then
                        object:delete();
                    end;
                end;
            end;
        end;
    end;    
end;

function GC_BaleAddon:getCanCutBaleEvent(data, noEventSend)
    g_company.eventManager:createEvent(self.eventId_getCanCutBale, data, false, noEventSend);

    local object = nil;
    if self.isServer then
        object = NetworkUtil.getObject(data[1]);

        local testDrop = g_densityMapHeightManager:getMinValidLiterValue(object.fillType);
        local sx,sy,sz = getWorldTranslation(object.nodeId);
        local radius = (DensityMapHeightUtil.getDefaultMaxRadius(object.fillType) / 2);
        
        if DensityMapHeightUtil.getCanTipToGroundAroundLine(nil, testDrop, object.fillType, sx, sy, sz, (sx + 0.1), (sy - 0.1), (sz + 0.1), radius, nil, 3, true, nil, true) then
            self:sendCanCutBaleEvent({true});
        end;
    end;
end;

function GC_BaleAddon:sendCanCutBaleEvent(data, noEventSend)   
	if self.isServer then
		g_company.eventManager:createEvent(self.eventId_sendCanCutBale, data, false, noEventSend);
	else
        self.canCut = data[1];
	end;
end;

g_company.addInit(GC_BaleAddon, GC_BaleAddon.init);
g_company.addLoadable(GC_BaleAddon, GC_BaleAddon.load);