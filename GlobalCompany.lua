-- 
-- GlobalCompany 
-- 
-- @Interface: --
-- @Author: LS-Modcompany / kevink98
-- @Date: 11.05.2018
-- @Version: 1.0.0.0
-- 
-- @Support: LS-Modcompany
--
 
local version = "1.0.0.0 (04.05.2018)";

GlobalCompany = {};
GlobalCompany.dir = g_currentModDirectory;

GlobalCompany.LOADTYP_XMLFILENAME = 1;

getfenv(0)["g_company"] = GlobalCompany;
addModEventListener(GlobalCompany);

source(GlobalCompany.dir .. "Debug.lua"); -- TEMP 'Need to convert all then scripts using this to remove it'

function GlobalCompany.initialLoad()
	if GlobalCompany.initialLoadComplete ~= nil then
		return;
	end;	

	--| Appended / Prepended functions |--
	Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, GlobalCompany.init);	
	Mission00.load = Utils.prependedFunction(Mission00.load, GlobalCompany.preMapLoad);

	--| Debug |--
	source(GlobalCompany.dir .. "utils/GC_DebugUtils.lua");
	g_company.debug = GC_DebugUtils:new();
	local debugIndex = g_company.debug:registerMod("GlobalCompany");
		
	GlobalCompany.inits = {};
	GlobalCompany.loadables = {};
	GlobalCompany.updateables = {};
	GlobalCompany.environments = {};
	GlobalCompany.loadParameters = {};
	GlobalCompany.loadParametersToEnvironment = {};
	
	GlobalCompany.loadSourceFiles();

	GlobalCompany.initialLoadComplete = true;
	g_company.debug:singleWrite(debugIndex, GC_DebugUtils.BLANK, "Loaded Version: %s", version);	
end;

--|| Init ||--
function GlobalCompany.addInit(target, init)
	table.insert(GlobalCompany.inits, {init=init, target=target});
end;

--|| Load ||--	
function GlobalCompany.addLoadable(target, loadF)
	table.insert(GlobalCompany.loadables, {loadF=loadF, target=target});
end;

--|| Updateables ||--
function GlobalCompany.addUpdateable(target, update)
	table.insert(GlobalCompany.updateables, {update=update, target=target});
end;

function GlobalCompany.removeUpdateable(target, update)
	for key, u in pairs(GlobalCompany.updateables) do
		if u.target == target then
			table.remove(GlobalCompany.updateables, key);
			break;
		end;
	end;
end;

--|| Parameters ||--
function GlobalCompany.addLoadParameter(name, key, typ)
	GlobalCompany.loadParameters[name] = {key=key, typ=typ, value=nil, environment=nil};
end;

--| Load Source Files |--
function GlobalCompany.loadSourceFiles()
	if GlobalCompany.initialLoadComplete ~= nil then
		return;
	end;
	
	source(GlobalCompany.dir .. "utils/GC_utils.lua");
	source(GlobalCompany.dir .. "utils/GC_i3dLoader.lua");
	source(GlobalCompany.dir .. "utils/GC_shopManager.lua");
	source(GlobalCompany.dir .. "utils/GC_TriggerManager.lua");
	source(GlobalCompany.dir .. "utils/GC_specializations.lua");
	source(GlobalCompany.dir .. "utils/GC_languageManager.lua");
	source(GlobalCompany.dir .. "utils/GC_densityMapHeight.lua");
	source(GlobalCompany.dir .. "utils/GC_cameraUtil.lua");
	
	
	--|| Gui ||--
	source(GlobalCompany.dir .. "GlobalCompanyGui.lua");
	
	
	--|| Objects ||--
	source(GlobalCompany.dir .. "objects/GC_Animations.lua");
	source(GlobalCompany.dir .. "objects/GC_DynamicHeap.lua");
	source(GlobalCompany.dir .. "objects/GC_ConveyorEffekt.lua");
	source(GlobalCompany.dir .. "objects/GC_ParticleEffects.lua");
	source(GlobalCompany.dir .. "objects/GC_ProductionFactory.lua");
	
	
	--|| Triggers ||--
	source(GlobalCompany.dir .. "triggers/GC_WoodTrigger.lua");
	source(GlobalCompany.dir .. "triggers/GC_PlayerTrigger.lua");
	source(GlobalCompany.dir .. "triggers/GC_UnloadingTrigger.lua");
end;

--| Environments and Language |--
function GlobalCompany.preMapLoad()
	if GlobalCompany.preLoadComplete ~= nil then
		return;
	end;
	
	debugPrint("GlobalCompany.preMapLoad") -- TESTING

	local activeMods = g_modManager:getActiveMods();
	for _, mod in pairs(activeMods) do		
		local modName = mod.modName;
		local path = mod.modDir .. "globalCompany.xml";
		if not fileExists(path) then
			path = mod.modDir .. "xml/globalCompany.xml";
			if not fileExists(path) then
				path = nil;
			end;
		end;
		
		if path ~= nil then
			local xmlFile = loadXMLFile("globalCompany", path);
			
			GlobalCompany.environments[modName] = {};
			GlobalCompany.environments[modName].path = path;
			GlobalCompany.environments[modName].xmlFile = xmlFile;
			GlobalCompany.environments[modName].specializations = getXMLString(xmlFile, "globalCompany.specializations#xmlFilename");
			GlobalCompany.environments[modName].shopManager = getXMLString(xmlFile, "globalCompany.shopManager#xmlFilename");
		end;
	end;

--[[This is the old method for reference if I missed something in the one above ;-)
	local mods = Files:new(g_modsDirectory);
	for _,v in pairs(mods.files) do
		local modName = nil;
		if v.isDirectory then
			modName = v.filename;
		else
			local l = v.filename:len();
			if l > 4 then
				local ext = v.filename:sub(l-3);
				if ext == ".zip" or ext == ".gar" then
					modName = v.filename:sub(1, l-4);
				end;
			end;
		end;
		local currentPath = string.format("%s%s/",g_modsDirectory, modName);
		local fullPath = currentPath .. "globalCompany.xml";
		if not fileExists(fullPath) then
			fullPath = currentPath .. "xml/globalCompany.xml";
			if not fileExists(fullPath) then
				fullPath = nil;
			end;
		end;
		
		if fullPath ~= nil then
			local xmlFile = loadXMLFile("globalCompany", fullPath);
			
			GlobalCompany.environments[modName] = {};
			GlobalCompany.environments[modName].fullPath = fullPath;
			GlobalCompany.environments[modName].xmlFile = xmlFile;
			GlobalCompany.environments[modName].specializations = getXMLString(xmlFile, "globalCompany.specializations#xmlFilename");
			GlobalCompany.environments[modName].shopManager = getXMLString(xmlFile, "globalCompany.shopManager#xmlFilename");
		end;
	end;
]]--

	for modName, values in pairs(GlobalCompany.environments) do
		if values.specializations ~= nil and values.specializations ~= "" then	
			g_company.specializations:loadFromXML(modName, g_company.utils.createModPath(modName, values.specializations));
		end;
	end;
	
	g_company.languageManager:load(); -- Load language manager.
	GlobalCompany.preLoadComplete = true;
end;

--| Main |--
function GlobalCompany:init() 
	for _, init in pairs(GlobalCompany.inits) do
		init.init(init.target);
	end; 
end;	

function GlobalCompany:loadMap()
	g_company.debug:loadConsoleCommands(); -- Load Debug console commands.

	-- Load parameters from environments table.
	for modName, e in pairs(GlobalCompany.environments) do
		for name, v in pairs(GlobalCompany.loadParameters) do
			if v.typ == GlobalCompany.LOADTYP_XMLFILENAME then
				local value = getXMLString(e.xmlFile, string.format("globalCompany%s#xmlFilename", v.key));
				if value ~= nil then
					GlobalCompany.loadParameters[name].value = value;
					GlobalCompany.loadParameters[name].environment = modName;
				end;
			end;
		end;		
		
		if e.shopManager ~= nil and e.shopManager ~= "" then	
			g_company.shopManager:loadFromXML(modName, g_company.utils.createModPath(modName, e.shopManager));
		end;
		
		delete(e.xmlFile);
	end;

	-- Update loadables
	for _,loadable in pairs(GlobalCompany.loadables) do
		loadable.loadF(loadable.target);
	end;
end;

function GlobalCompany:update(dt) 
	for _,updateable in pairs(GlobalCompany.updateables) do
		updateable.update(updateable.target, dt);
	end; 
end;

function GlobalCompany:delete()
	for _,updateable in pairs(GlobalCompany.updateables) do
        if updateable.delete ~= nil then
			updateable:delete();
		end;
    end;
end;

function GlobalCompany:deleteMap()
	g_company.debug:deleteConsoleCommands();
end;

function GlobalCompany:getLoadParameterValue(name) 
	if GlobalCompany.loadParameters[name] == nil or GlobalCompany.loadParameters[name].value == nil then 
		return "";
	end;
	
	return GlobalCompany.loadParameters[name].value;
end;

function GlobalCompany:getLoadParameterEnvironment(name) 
	if GlobalCompany.loadParameters[name] == nil or GlobalCompany.loadParameters[name].environment == nil then
		return "";
	end;
	
	return GlobalCompany.loadParameters[name].environment;
end;

GlobalCompany.initialLoad();