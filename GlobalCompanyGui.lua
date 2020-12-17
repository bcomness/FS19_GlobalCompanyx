-- 
-- GlobalCompanyGui
-- 
-- @Interface: 1.4.4.0 1.4.4RC8
-- @Author: kevink98 
-- @Date: 22.06.2017
-- @Version: 1.0.0
-- 
-- @Support: LS-Modcompany
-- 
local debugIndex = g_debug.registerMod("GlobalCompany-Gui");

GlobalCompanyGui = {};
g_company.gui = GlobalCompanyGui;
GlobalCompanyGui.DevelopementVersion = true;
GlobalCompanyGui.DevelopementVersionTemplatesFilename = {};
addModEventListener(GlobalCompanyGui);

GlobalCompanyGui.guis = {};
GlobalCompanyGui.smallGuis = {};
GlobalCompanyGui.toInit_actionEvents = {};

GlobalCompanyGui.template = {};
GlobalCompanyGui.template.colors = {};
GlobalCompanyGui.template.uvs = {};
GlobalCompanyGui.template.templates = {};
GlobalCompanyGui.template.uiElements = {};

source(g_currentModDirectory .. "gui/elements/Gui.lua");
source(g_currentModDirectory .. "gui/elements/GuiElement.lua");
source(g_currentModDirectory .. "gui/elements/Text.lua");
source(g_currentModDirectory .. "gui/elements/Overlay.lua");
source(g_currentModDirectory .. "gui/elements/FlowLayout.lua");
source(g_currentModDirectory .. "gui/elements/Button.lua");
source(g_currentModDirectory .. "gui/elements/Borders.lua");
source(g_currentModDirectory .. "gui/elements/Table.lua");

source(g_currentModDirectory .. "gui/FakeGui.lua");

function GlobalCompanyGui:init()	
	for _,inAc in pairs(self.toInit_actionEvents) do
		g_gui.inputManager:registerActionEvent(inAc.inputAction, GlobalCompanyGui, inAc.func, false, true, false, true);	
	end;
end;

function GlobalCompanyGui:loadMap()
	self.fakeGui = GC_Gui_FakeGui:new();
	g_gui:loadGui(g_company.dir .. self.fakeGui.guiInformations.guiXml, "gc_fakeGui", self.fakeGui);
end;

function GlobalCompanyGui:update(dt)
	if self.DevelopementVersion then
		if self.DevelopementVersionTimer == nil or self.DevelopementVersionTimer <= 0 then
			for name,gui in pairs(self.guis) do				
				gui.gui:deleteElements();
				gui.gui:loadFromXML();
			end;
			for _, fileName in pairs(GlobalCompanyGui.DevelopementVersionTemplatesFilename) do				
				self:loadGuiTemplates(fileName);
			end;
			if self.activeGui ~= nil then
				self.guis[self.activeGui].gui:openGui();
			end;
			self.DevelopementVersionTimer = 70;
		else
			self.DevelopementVersionTimer = self.DevelopementVersionTimer - 1;
		end;		
	end;

	if self.activeGui == nil then
		for name, open in pairs(self.smallGuis) do
			if open then
				self.guis[name].gui:update(dt);
			end;
		end;
	else
		self.guis[self.activeGui].gui:update(dt);
	end;
end;

function GlobalCompanyGui:mouseEvent(posX, posY, isDown, isUp, button) 
	if self.activeGui == nil then
		for name, open in pairs(self.smallGuis) do
			if open then
				self.guis[name].mouseEvent(posX, posY, isDown, isUp, button);
			end;
		end;
	else
		self.guis[self.activeGui].gui:mouseEvent(posX, posY, isDown, isUp, button);
	end;
end;

function GlobalCompanyGui:keyEvent(unicode, sym, modifier, isDown) 
	if self.activeGui == nil then
		for name, open in pairs(self.smallGuis) do
			if open then
				self.guis[name].gui:keyEvent(unicode, sym, modifier, isDown);
			end;
		end;
	else
		self.guis[self.activeGui].gui:keyEvent(unicode, sym, modifier, isDown);
	end;
end;

function GlobalCompanyGui:draw() end;
function GlobalCompanyGui:drawB() 
	if GlobalCompanyGui.activeGui == nil then
		for name, open in pairs(GlobalCompanyGui.smallGuis) do
			if open then
				GlobalCompanyGui.guis[name].gui:draw();
			end;
		end;
	else
		GlobalCompanyGui.guis[GlobalCompanyGui.activeGui].gui:draw();
	end;
end;

function GlobalCompany:deleteMap() 
	self:delete();
end;

function GlobalCompanyGui:delete()
	
end;

function GlobalCompanyGui:registerGui(name, inputAction, class, isFullGui, canExit)
	if self.guis[name] ~= nil then
		g_debug.write(debugIndex, Debug.ERROR, "Gui %s already exist.", name);
		return;
	else 
		self.guis[name] = {};
	end;
	
	local classGui = class:new();
	local newGui = GC_Gui:new(name);
	newGui:assignClass(classGui);
	self.guis[name].gui = newGui;
	self.guis[name].isFullGui = isFullGui or true;
	self.guis[name].canExit = canExit;
		
	if not self.guis[name].isFullGui then
		self.smallGuis[name] = false;		
	end;
	
	if inputAction ~= nil then
		local func = function() GlobalCompanyGui:openGui(name) end;	
		table.insert(self.toInit_actionEvents, {inputAction=inputAction, func=func});
	end;
	
	newGui:loadFromXML();
	
	return newGui;
end;

function GlobalCompanyGui:unregisterGui()
	if self.guis[name] ~= nil then
		self.guis[name].gui:delete();
		self.guis[name] = nil;
	end;
end;

function GlobalCompanyGui:openGui(name)
	if self.guis[name] == nil then
		g_debug.write(debugIndex, Debug.ERROR, "Gui %s not exist.", name);
		return;
	end;
	if self.guis[name].isFullGui then
		g_gui:showGui("gc_fakeGui");
		self.fakeGui:setExit(self.guis[name].canExit);
		
		for nameG,_ in pairs(self.smallGuis) do
			self.guis[nameG].gui:closeGui();
		end;
		
		self.activeGui = name;
	else
		self.smallGuis[name] = true;
	end;
	self.guis[name].gui:openGui();
end;

function GlobalCompanyGui:closeGui(name)
	if self.guis[name].isFullGui then
		for nameG,open in pairs(self.smallGuis) do
			if open then
				self.guis[nameG].gui:openGui();
			end;
		end;
		self.activeGui = nil;
	else
		self.smallGuis[name] = false;
	end;	
	self.fakeGui:setExit(true);
	self.guis[name].gui:closeGui();
	g_gui:showGui("");
end;

function GlobalCompanyGui:closeActiveGui()
	if self.activeGui ~= nil then
		self:closeGui(self.activeGui);
	end;
end;

function GlobalCompanyGui:getGuiFromName(name)
	return self.guis[name].gui;
end;

function GlobalCompanyGui:loadGuiTemplates(xmlFilename)
    local xmlFile = loadXMLFile("Temp", xmlFilename);

	if xmlFile == nil or xmlFile == 0 then		
		g_debug.write(debugIndex, Debug.ERROR, "Gui can't load templates %s", xmlFilename);
		return;
	end;
	
	GlobalCompanyGui.DevelopementVersionTemplatesFilename[xmlFilename] = xmlFilename;
	
	local i = 0;
	while true do
		local key = string.format("guiTemplates.colors.color(%d)", i);
		if not hasXMLProperty(xmlFile, key) then
			break;
		end;
		local name = getXMLString(xmlFile, string.format("%s#name", key));
		local value = getXMLString(xmlFile, string.format("%s#value", key));
		
		if name == nil or name == "" then			
			g_debug.write(debugIndex, Debug.ERROR, "Gui template haven't name at %s", key);
			break;
		end;
		if GlobalCompanyGui.template.colors[name] ~= nil and not GlobalCompanyGui.DevelopementVersion then	
			g_debug.write(debugIndex, Debug.ERROR, "Gui template colour %s already exist", name);
			break;
		end;
		
		if value == nil or value == "" then			
			g_debug.write(debugIndex, Debug.ERROR, "Gui template haven't value at %s", key);
			break;
		end;
		
		local r,g,b,a = unpack(g_company.utils.splitString(value, " "));
		if r == nil or g == nil or b == nil or a == nil then		
			g_debug.write(debugIndex, Debug.ERROR, "Gui template haven't correct color at %s", key);
			break;
		end;
		
		GlobalCompanyGui.template.colors[name] = {tonumber(r), tonumber(g), tonumber(b), tonumber(a)};
		i = i + 1;
	end;
	
	if hasXMLProperty(xmlFile, "guiTemplates.uvs") then
		i = 0;
		while true do
			local key = string.format("guiTemplates.uvs.uv(%d)", i);
			if not hasXMLProperty(xmlFile, key) then
				break;
			end;
			local name = getXMLString(xmlFile, string.format("%s#name", key));
			local value = getXMLString(xmlFile, string.format("%s#value", key));
			
			if name == nil or name == "" then			
				g_debug.write(debugIndex, Debug.ERROR, "Gui template haven't name at %s", key);
				break;
			end;
			if GlobalCompanyGui.template.uvs[name] ~= nil and not GlobalCompanyGui.DevelopementVersion then	
				g_debug.write(debugIndex, Debug.ERROR, "Gui template uv %s already exist", name);
				break;
			end;
			
			if value == nil or value == "" then			
				g_debug.write(debugIndex, Debug.ERROR, "Gui template haven't value at %s", key);
				break;
			end;
			
			--local x,y,wX,wY = unpack(g_company.utils.splitString(value:replace(, " "));
			--if x == nil or y == nil or wX == nil or wY == nil then		
			--	g_debug.write(debugIndex, Debug.ERROR, "Gui template haven't correct uv at %s", key);
			--	break;
			--end;
			
			GlobalCompanyGui.template.uvs[name] = value;
		i = i + 1;
		end;
	end;
	
	i = 0;
	while true do
		local key = string.format("guiTemplates.templates.template(%d)", i);
		if not hasXMLProperty(xmlFile, key) then
			break;
		end;
		local name = getXMLString(xmlFile, string.format("%s#name", key));
		local anchor = getXMLString(xmlFile, string.format("%s#anchor", key));
		local extends = getXMLString(xmlFile, string.format("%s#extends", key));
		
		if name == nil or name == "" then			
			g_debug.write(debugIndex, Debug.ERROR, "Gui template haven't name at %s", key);
			break;
		end;
		if GlobalCompanyGui.template.templates[name] ~= nil and not GlobalCompanyGui.DevelopementVersion then	
			g_debug.write(debugIndex, Debug.ERROR, "Gui template template %s already exist", name);
			break;
		end;
		
		if anchor == nil or anchor == "" then			
			anchor = "middleCenter";
		end;
		
		GlobalCompanyGui.template.templates[name] = {};
		GlobalCompanyGui.template.templates[name].anchor = anchor;
		GlobalCompanyGui.template.templates[name].values = {};
		GlobalCompanyGui.template.templates[name].extends = {};		
		
		if extends ~= nil and extends ~= "" then
			GlobalCompanyGui.template.templates[name].extends = g_company.utils.splitString(extends, " ");
		end;
		
		local j = 0;
		while true do
			local key = string.format("guiTemplates.templates.template(%d).value(%d)", i, j);
			if not hasXMLProperty(xmlFile, key) then
				break;
			end;
			
			local nameV = getXMLString(xmlFile, string.format("%s#name", key));
			local valueV = getXMLString(xmlFile, string.format("%s#value", key));
			
			if nameV ~= nil and nameV ~= "" and valueV ~= nil and valueV ~= "" then
				if GlobalCompanyGui.template.templates[name].values[nameV] ~= nil and not GlobalCompanyGui.DevelopementVersion then	
					g_debug.write(debugIndex, Debug.ERROR, "Gui template template %s already exist", nameV);
					break;
				end;
				GlobalCompanyGui.template.templates[name].values[nameV] = valueV;
			else
				g_debug.write(debugIndex, Debug.ERROR, "Gui template template error at %s", key);
			end;				
			j = j + 1;
		end;
		i = i + 1;
	end;
end;

function GlobalCompanyGui:registerUiElements(name, path)
	GlobalCompanyGui.template.uiElements[name] = path;
end;

function GlobalCompanyGui:getUiElement(name)
	return GlobalCompanyGui.template.uiElements[name];
end;

function GlobalCompanyGui:getTemplateValueParents(templateName, valueName)
	if GlobalCompanyGui.template.templates[templateName] ~= nil then
		local val;
		for _,extend in pairs(GlobalCompanyGui.template.templates[templateName].extends) do
			local rVal = self:getTemplateValue(extend, valueName, nil, true);
			if rVal ~= nil then
				val = rVal;
				break;
			end;
		end;
		if val ~= nil then
			return val;
		end;
		for _,extend in pairs(GlobalCompanyGui.template.templates[templateName].extends) do
			local rVal = self:getTemplateValueParents(extend, valueName, nil);
			if rVal ~= nil then
				val = rVal;
				break;
			end;
		end;
		return val;
	end;
	return nil;
end;

function GlobalCompanyGui:getTemplateValue(templateName, valueName, default, ignoreExtends)
	if GlobalCompanyGui.template.templates[templateName] ~= nil then
		if GlobalCompanyGui.template.templates[templateName].values[valueName] ~= nil then
			return GlobalCompanyGui.template.templates[templateName].values[valueName];
		elseif not ignoreExtends then
			local parentV = self:getTemplateValueParents(templateName, valueName);
			if parentV ~= nil then
				return parentV;
			else
				return default;
			end;
		else
			return default;
		end;
	else
		return default;
	end;
end;

function GlobalCompanyGui:getTemplateValueBool(templateName, valueName, default)
	local val = self:getTemplateValue(templateName, valueName)
	if val ~= nil then
		return val:lower() == "true";
	end;
	return default;
end;

function GlobalCompanyGui:getTemplateValueNumber(templateName, valueName, default)
	local val = self:getTemplateValue(templateName, valueName, default)
	if val ~= nil and val ~= "nil" then
		return tonumber(val);
	end;
	return default;
end;

function GlobalCompanyGui:getTemplateValueColor(templateName, valueName, default)
	local var = g_company.gui:getTemplateValue(templateName, valueName);
	
	if GlobalCompanyGui.template.colors[var] ~= nil then
		return GlobalCompanyGui.template.colors[var];
	else
		return GuiUtils.getColorArray(var, default);
	end;
end;

function GlobalCompanyGui:getTemplateValueUVs(templateName, valueName, imageSize, default)
	local var = g_company.gui:getTemplateValue(templateName, valueName);
	
	if GlobalCompanyGui.template.uvs[var] ~= nil then
		return GuiUtils.getUVs(GlobalCompanyGui.template.uvs[var], imageSize, default);
	else
		return GuiUtils.getUVs(var, imageSize, default);
	 end;
end;

function GlobalCompanyGui:getTemplateValueXML(xmlFile, name, key, default)
	local val = getXMLString(xmlFile, string.format("%s#%s", key, name));	
	if val ~= nil then
		return val;
	end;
	return default;
end;

function GlobalCompanyGui:getTemplateValueNumberXML(xmlFile, name, key, default)
	local val = getXMLString(xmlFile, string.format("%s#%s", key, name));	
	if val ~= nil then
		return tonumber(val);
	end;
	return default;
end;

function GlobalCompanyGui:getTemplateValueBoolXML(xmlFile, name, key, default)
	local val = getXMLString(xmlFile, string.format("%s#%s", key, name));	
	if val ~= nil then
		return val:lower() == "true";
	end;
	return default;
end;

function GlobalCompanyGui:getTemplateAnchor(templateName)
	return GlobalCompanyGui.template.templates[templateName].anchor;
end;

function GlobalCompanyGui:calcDrawPos(element, index)
	local x,y;	
	local anchor = element:getAnchor():lower();
	local isLeft = g_company.utils.find(anchor, "left");
	local isMiddle = g_company.utils.find(anchor, "middle");
	local isRight = g_company.utils.find(anchor, "right");
	local isTop = g_company.utils.find(anchor, "top");
	local isCenter = g_company.utils.find(anchor, "center");
	local isBottom = g_company.utils.find(anchor, "bottom");	
	
	if element.parent.name == "flowLayout" then
		if element.parent.orientation == GC_Gui_flowLayout.ORIENTATION_X then			
			if element.parent.alignment == GC_Gui_flowLayout.ALIGNMENT_LEFT then
				x = 0;
				for i, elementF in pairs(element.parent.elements) do
					if i == index then
						break;
					else
						x = x + elementF.size[1] + elementF.margin[1] + elementF.margin[3];
					end;
				end;
				
				x = x + element.parent.drawPosition[1] + element.margin[1] + element.position[1];					
			elseif element.parent.alignment == GC_Gui_flowLayout.ALIGNMENT_MIDDLE then			
				local fullSize = 0;
				for i, elementF in pairs(element.parent.elements) do
					fullSize = fullSize + elementF.size[1] + elementF.margin[1] + elementF.margin[3];
				end;	
				local leftToStart = (element.parent.size[1] - fullSize) / 2;
				
				x = 0;
				for i, elementF in pairs(element.parent.elements) do
					if i == index then
						break;
					else
						x = x + elementF.size[1] + elementF.margin[1] + elementF.margin[3];
					end;
				end;

				x = x + leftToStart + element.parent.drawPosition[1] + element.margin[1] + element.position[1];			
			elseif element.parent.alignment == GC_Gui_flowLayout.ALIGNMENT_RIGHT then			
				x = 0;
				local search = true;
				for i, elementF in pairs(element.parent.elements) do
					if search then
						if i == index then
							search = false;
						end;
					else
						x = x + elementF.size[1] + elementF.margin[1] + elementF.margin[3];
					end;
				end;
				
				x = element.parent.drawPosition[1] + element.parent.size[1] - element.margin[3] - element.size[1] + element.position[1] - x;	
			end;
			
			if isTop then
				y = element.parent.drawPosition[2] + element.parent.size[2] - element.margin[2] - element.size[2] + element.position[2];
			elseif isCenter then
				y = element.parent.drawPosition[2] + (element.parent.size[2] * 0.5) + element.position[2] - (element.size[2] * 0.5);
			elseif isBottom then
				y = element.parent.drawPosition[2] + element.margin[4] + element.position[2];
			end;
		elseif element.parent.orientation == GC_Gui_flowLayout.ORIENTATION_Y then		
			if element.parent.alignment == GC_Gui_flowLayout.ALIGNMENT_TOP then
				y = 0;
				for i, elementF in pairs(element.parent.elements) do
					if i == index then
						break;
					else
						y = y + elementF.size[2] + elementF.margin[2] + elementF.margin[4];
					end;
				end;
				
				y = element.parent.drawPosition[2] + element.parent.size[2] - y - element.size[2] - element.margin[2] + element.position[2];	
			elseif element.parent.alignment == GC_Gui_flowLayout.ALIGNMENT_CENTER then
				local fullSize = 0;
				for i, elementF in pairs(element.parent.elements) do
					fullSize = fullSize + elementF.size[2] + elementF.margin[2] + elementF.margin[4];
				end;	
				local topToStart = (element.parent.size[2] - fullSize) / 2;
				
				y = 0;
				for i, elementF in pairs(element.parent.elements) do
					if i == index then
						break;
					else
						y = y + elementF.size[2] + elementF.margin[2] + elementF.margin[4];
					end;
				end;
				
				y = element.parent.drawPosition[2] + element.parent.size[2] - topToStart - y - element.size[2] - element.margin[2] + element.position[2];			
			elseif element.parent.alignment == GC_Gui_flowLayout.ALIGNMENT_BOTTOM then
				local fullSize = 0;
				for i, elementF in pairs(element.parent.elements) do
					fullSize = fullSize + elementF.size[2] + elementF.margin[2] + elementF.margin[4];
				end;	
				local topToStart = element.parent.size[2] - fullSize;
				
				y = 0;
				for i, elementF in pairs(element.parent.elements) do
					if i == index then
						break;
					else
						y = y + elementF.size[2] + elementF.margin[2] + elementF.margin[4];
					end;
				end;
				
				y = element.parent.drawPosition[2] + element.parent.size[2] - topToStart - y - element.size[2] - element.margin[2] + element.position[2];		
			end;
		
			if isLeft then
				x = element.parent.drawPosition[1] + element.margin[1] + element.position[1];
			elseif isMiddle then
				x = element.parent.drawPosition[1] + (element.parent.size[1] * 0.5) + element.position[1]  - (element.size[1] * 0.5);
			elseif isRight then
				x = element.parent.drawPosition[1] + element.parent.size[1] - element.margin[3] - element.size[1] + element.position[1];
			end;
		end;
	elseif element.parent.name == "table" then
		if element.parent.orientation == GC_Gui_table.ORIENTATION_X then				
			local xRow = math.floor((index - 1) / element.parent.maxItemsY);
			local yRow = (index - 1) % element.parent.maxItemsY;
			
			x = element.parent.drawPosition[1] + xRow * (element.margin[1] + element.size[1] + element.margin[3]) + element.margin[1];
			y = element.parent.drawPosition[2] + element.parent.size[2] - (yRow) * (element.margin[2] + element.size[2] + element.margin[4]) - element.margin[2] - element.size[2];
		elseif element.parent.orientation == GC_Gui_table.ORIENTATION_Y then	
			
			local yRow = math.floor((index - 1) / element.parent.maxItemsX);
			local xRow = (index - 1) % element.parent.maxItemsX;
			
			x = element.parent.drawPosition[1] + xRow * (element.margin[1] + element.size[1] + element.margin[3]) + element.margin[1];
			y = element.parent.drawPosition[2] + element.parent.size[2] - (yRow) * (element.margin[2] + element.size[2] + element.margin[4]) - element.margin[2] - element.size[2];
			
			
		end;
	else
		if isLeft then
			x = element.parent.drawPosition[1] + element.margin[1] + element.position[1];
		elseif isMiddle then
			x = element.parent.drawPosition[1] + (element.parent.size[1] * 0.5) + element.position[1]  - (element.size[1] * 0.5) + element.margin[1];
		elseif isRight then
			x = element.parent.drawPosition[1] + element.parent.size[1] - element.margin[3] - element.size[1] + element.position[1];
		end;
		
		if isTop then
			y = element.parent.drawPosition[2] + element.parent.size[2] - element.margin[2] - element.size[2] + element.position[2];
		elseif isCenter then
			y = element.parent.drawPosition[2] + (element.parent.size[2] * 0.5) + element.position[2] - (element.size[2] * 0.5) + element.margin[2];
		elseif isBottom then
			y = element.parent.drawPosition[2] + element.margin[4] + element.position[2];
		end;
	end;
	
	
	if x == nil or y == nil then
		--error
		x = 0;
		y = 0;
	end;

	return x,y;
end;

-- http://alienryderflex.com/polygon/
function GlobalCompanyGui:checkClickZone(x,y, clickZone, isRound)		
	if isRound then
		local r = (clickZone[3] - clickZone[1]) / 2;
		local mx = clickZone[1] + r;
		local my = clickZone[2] + r;
		return math.sqrt(math.pow(x - mx, 2) + math.pow(y - my, 2)) <= r ;		
	else	
		local polyX = {clickZone[1], clickZone[3], clickZone[5], clickZone[7]};
		local polyY = {clickZone[2], clickZone[4], clickZone[6], clickZone[8]};	
		
		local j = 4;
		local insert = false;
		
		for i=1, 4 do
			if polyY[i]< y and polyY[j]>=y or polyY[j]< y and polyY[i]>=y then
				if polyX[i] + (y-polyY[i]) / (polyY[j]-polyY[i])*(polyX[j]-polyX[i]) < x then
					insert = not insert;
				end;
			end;
			j=i;
		end;		
		return insert;
	end;
end;

function GlobalCompanyGui:checkClickZoneNormal(x,y, drawX, drawY, sX, sY)
	return x > drawX and y > drawY and x < drawX + sX and y < drawY + sY;
end;

g_company.gui:loadGuiTemplates(g_company.dir .. "gui/guiTemplates.xml");
g_company.addInit(GlobalCompanyGui, GlobalCompanyGui.init);
BaseMission.draw = Utils.appendedFunction(BaseMission.draw, GlobalCompanyGui.drawB);




