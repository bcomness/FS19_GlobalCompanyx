-- 
-- GlobalCompany - Utils - GC_languageManager
-- 
-- @Interface: --
-- @Author: LS-Modcompany / kevink98
-- @Date: 17.12.2018
-- @Version: 1.0.0.0
-- 
-- @Support: LS-Modcompany
-- 
-- Changelog:
--		
-- 	v1.0.0.0 ():
-- 		- initial fs19 (kevink98)
-- 
-- Notes:
-- 
-- 
-- ToDo:
-- 
-- 

GC_languageManager = {};
GC_languageManager.debugIndex = g_company.debug:registerScriptName("GC_LanguageManager");

g_company.languageManager = GC_languageManager;

function GC_languageManager:load(modLanguageFiles)
	GC_languageManager.debugData = g_company.debug:getDebugData(GC_languageManager.debugIndex, g_company);

	if modLanguageFiles == nil then
		g_company.debug:writeDev(GC_languageManager.debugData, "'modLanguageFiles' parameter is nil!");
		
		local modLanguageFiles = {};
		-- local selectedMods = g_modSelectionScreen.missionDynamicInfo.mods;
		-- for _, mod in pairs(selectedMods) do
			-- local langFullPath = GC_languageManager:getLanguagesFullPath(mod.modDir);
			-- if langFullPath ~= nil then
				-- modLanguageFiles[modName] = langFullPath;
			-- end;
		-- end;
	end;

	local fullPathCount = 0;
	for modName, fullPath in pairs(modLanguageFiles) do
		local langXml = loadXMLFile("TempConfig", fullPath);
		g_i18n:loadEntriesFromXML(langXml, "l10n.elements.e(%d)", "Warning: Duplicate text in l10n %s",  g_i18n.texts);
		
		fullPathCount = fullPathCount + 1;
	end;
	
	g_company.debug:writeLoad(GC_languageManager.debugData, "'%d' language XML files have been loaded successfully.", fullPathCount);
end;

function GC_languageManager:getLanguagesFullPath(modPath)
	local fullPath = string.format("%s/l10n%s.xml", modPath, g_languageSuffix);
	if fileExists(fullPath) then
		return fullPath;
	end;	

	fullPath = string.format("%s/languages/l10n%s.xml", modPath, g_languageSuffix);
	if fileExists(fullPath) then
		return fullPath;
	end;

	fullPath = string.format("%s/l10n_en.xml", modPath);
	if fileExists(fullPath) then
		return fullPath;
	end;	
	
	fullPath = string.format("%s/languages/l10n_en.xml", modPath);
	if fileExists(fullPath) then
		return fullPath;
	end;
	
	return;
end;

function GC_languageManager:getText(text)
	if text ~= nil then
		local addColon = false;
		local lenght = text:len();
		if text:sub(lenght, lenght+1) == ":" then
			text = text:sub(1, lenght-1);
			addColon = true;
		end;
		if text:sub(1,6) == "$l10n_" then
			text = g_i18n:getText(text:sub(7));
		elseif g_i18n:hasText(text) then
			text = g_i18n:getText(text);
		end;
		if addColon and text ~= "" then
			text = text .. ":";
		end;
		return text;
	end;
	return "";
end;


