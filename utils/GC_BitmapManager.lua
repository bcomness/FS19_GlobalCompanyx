-- 
-- GlobalCompany - Bitmap Manager
-- 
-- @Interface: 1.4.0.0 b5008
-- @Author: LS-Modcompany
-- @Date: 08.09.2019
-- @Version: 1.0.0.0
-- 
-- @Support: LS-Modcompany
-- 
-- Changelog:
--		
--
-- 	v1.0.0.0 (08.09.2019):
-- 		- initial fs19 (kevink98)
-- 
-- Notes:
--
--
-- ToDo:
--
-- 


GC_BitmapManager = {};
GC_BitmapManager.debugIndex = g_company.debug:registerScriptName("GC_BitmapManager")

local GC_BitmapManager_mt = Class(GC_BitmapManager)

function GC_BitmapManager:new()
    local self = {}
	setmetatable(self, GC_BitmapManager_mt)

    self.debugData = g_company.debug:getDebugData(GC_BitmapManager.debugIndex)

    self.bitmapId = 0 -- based 1
    self.bitmaps = {}

    g_company.addSaveable(self, self.saveBitmaps)

	return self
end;

function GC_BitmapManager:getNextId()
    self.bitmapId = self.bitmapId + 1
    return self.bitmapId
end;

function GC_BitmapManager:loadBitMap(name, filename, numChannels, autosave)
    local haveWrongParams = false
    local success = false
    local createNew = false

    if name == nil or name == "" then
        g_company.debug:writeError(self.debugData, "loadBitMap: Have invalid name.")
        haveWrongParams = true
    end
    if filename == nil or filename == "" then
        g_company.debug:writeError(self.debugData, "loadBitMap: Have invalid filename.")
        haveWrongParams = true
    end
    if numChannels == nil or numChannels == 0 then
        g_company.debug:writeWarning(self.debugData, "loadBitMap: Have invalid numChannels. Set to 8")
        numChannels = 0
    end
    if autosave == nil then
        autosave = true
    end

    if haveWrongParams then
        return
    end

    local bitmap = {}
    bitmap.id = self:getNextId()
    bitmap.name = name
    bitmap.filename = filename
    bitmap.numChannels = numChannels
    bitmap.autosave = autosave

    bitmap.map = createBitVectorMap(bitmap.name)

    if self.mission ~= nil then
        if self.mission.missionInfo.isValid then
            bitmap.fullPath = string.format("%s/%s", self.mission.missionInfo.savegameDirectory, bitmap.filename)

            if fileExists(bitmap.fullPath) then
                success = loadBitVectorMapFromFile(bitmap.map, bitmap.fullPath, bitmap.numChannels)
            else
                g_company.debug:writeModding(self.debugData, "loadBitMap: Can't find file %s - Create a new one", bitmap.fullPath)
            end
        end

        if not success then
            local size = getDensityMapSize(self.mission.terrainDetailId)
            loadBitVectorMapNew(bitmap.map, size, size, bitmap.numChannels, false)
            createNew = true
        end
        bitmap.mapSize = getBitVectorMapSize(bitmap.map)
        table.insert(self.bitmaps, bitmap)
        return bitmap.id, createNew
    else
        g_company.debug:writeError(self.debugData, "loadBitMap: no mission")
    end
    return nil, false
end

function GC_BitmapManager:saveBitmaps()
    for _,bitmap in pairs(self.bitmaps) do
        if bitmap.autosave and bitmap.map ~= 0 then
            saveBitVectorMapToFile(bitmap.map, bitmap.fullPath)
            --print(bitmap.fullPath)
        end
    end
end

function GC_BitmapManager:saveBitmapById(id)
    for _,bitmap in pairs(self.bitmaps) do
        if bitmap.id == id and bitmap.map ~= 0 then
            saveBitVectorMapToFile(bitmap.map, bitmap.fullPath)
            break
        end
    end
end

function GC_BitmapManager:getBitmapById(id)
    for _,bitmap in pairs(self.bitmaps) do
        if bitmap.id == id then
            return bitmap
        end
    end
end