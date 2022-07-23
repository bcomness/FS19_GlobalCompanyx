





Gc_Gui_FactoryBig = {};
Gc_Gui_FactoryBig.xmlFilename = g_company.dir .. "gui/objects/FactoryBig.xml";
Gc_Gui_FactoryBig.debugIndex = g_company.debug:registerScriptName("Gc_Gui_FactoryBig");

Gc_Gui_FactoryBig.BUYSTEP = 500;

local Gc_Gui_FactoryBig_mt = Class(Gc_Gui_FactoryBig);

function Gc_Gui_FactoryBig:new(target, custom_mt)
    if custom_mt == nil then
        custom_mt = Gc_Gui_FactoryBig_mt;
    end;
	local self = setmetatable({}, Gc_Gui_FactoryBig_mt);
            
    self.currentLineId = 0;

    
		
    g_currentMission.environment:addMinuteChangeListener(self)

	return self;
end;

function Gc_Gui_FactoryBig:setData(fabric, lineId)
    self.currentFactory = fabric;
    self.currentLineId = lineId;
end

function Gc_Gui_FactoryBig:onCreate() end;

function Gc_Gui_FactoryBig:onOpen() 
    g_depthOfFieldManager:setBlurState(true)


    self:setOverview();
    self:setProductLines();

    self:openLineId(self.currentLineId);
end;

function Gc_Gui_FactoryBig:onClose() 
    g_depthOfFieldManager:setBlurState(false)
    --self.currentFactory = nil;
end;

function Gc_Gui_FactoryBig:openLineId(lineId)
    if lineId == nil or self.currentLineId == 0 then
        self:onClickToOverview();
    else
        self.gui_overview:setVisible(false);
        self.gui_details:setVisible(true);
        self.currentLineId = lineId;
        self:setDetails();
    end;
    self:updateLineIdTable();
end

function Gc_Gui_FactoryBig:onClickToOverview()
    self.gui_overview:setVisible(true);
    self.gui_details:setVisible(false);
    self.currentLineId = 0;
    self:updateLineIdTable();
end

function Gc_Gui_FactoryBig:updateLineIdTable()     
    for _,element in pairs(self.gui_productLinesTable.items) do
        if element.lineId == self.currentLineId then
            element:setActive(true, true);
        else
            element:setActive(false, true);
        end;
    end;
end

function Gc_Gui_FactoryBig:onClickLineId(element)
    self.currentLineId = element.lineId;
    self.gui_overview:setVisible(false);
    self.gui_details:setVisible(true);
    self:setDetails();
end

function Gc_Gui_FactoryBig:setOverview()
    local data = self.currentFactory:getGuiData();
    self.gui_overview_factoryName:setText(data.factoryTitle);
    self.gui_details_factoryName:setText(data.factoryTitle);
    self.gui_overview_description:setText(data.factoryDescription);

    if data.factoryCamera ~= nil then
        local id = g_company.cameraUtil:getRenderOverlayId(data.factoryCamera, self.gui_overview_image.size[1], self.gui_overview_image.size[2]);
        updateRenderOverlay(id);
        self.gui_overview_image:setImageOverlay(id);
    elseif data.factoryImage ~= nil then
        self.gui_overview_image:setImageFilename(data.factoryImage);
    end;
end

--------------------------------------------------------------------------------------------
----------------------------------ProductLines----------------------------------------------
--------------------------------------------------------------------------------------------
function Gc_Gui_FactoryBig:setProductLines()
    self.gui_productLinesTable:removeElements();
    local i = 1;
    for _,productLine in pairs(self.currentFactory.productLines) do
        self.tmp_productLine = productLine;
        local item = self.gui_productLinesTable:createItem();        
        item.lineId = i;
        --item.buyLiters = 0;
        i = i + 1;
    end;
    self.tmp_productLine = nil;    
end

function Gc_Gui_FactoryBig:onCreateLeftItemTitle(element)
    if self.tmp_productLine ~= nil then
        element:setText(self.tmp_productLine.title);
    end;
end

function Gc_Gui_FactoryBig:onCreateLeftItemActive(element)
    if self.tmp_productLine ~= nil then
        element:setVisible(self.tmp_productLine.active);
    end;
end

function Gc_Gui_FactoryBig:onCreateLeftItemOutput(element)
    if self.tmp_productLine ~= nil then
        element:setText(string.format(g_company.languageManager:getText("GC_gui_productionPerHour"), g_i18n:formatNumber(self.tmp_productLine.outputPerHour, 0)));
    end;
end

--------------------------------------------------------------------------------------------
--------------------------------------Detail------------------------------------------------
--------------------------------------------------------------------------------------------
function Gc_Gui_FactoryBig:setDetails()
    self:minuteChanged(); -- set current time
    self.gui_inputTable:removeElements();
    self.gui_outputTable:removeElements();

    for _,input in pairs(self.currentFactory:getInputs(self.currentLineId)) do
        self.tmp_input = input;
        self.gui_inputTable:createItem();
    end;
    self.tmp_input = nil;   
    
    for _,output in pairs(self.currentFactory:getOutputs(self.currentLineId)) do
        self.tmp_output = output;
        self.gui_outputTable:createItem();
    end;
    self.tmp_output = nil;  
end

function Gc_Gui_FactoryBig:minuteChanged()
    self.gui_details_currentTime:setText(string.format("%s:%s", g_currentMission.environment.currentHour, g_currentMission.environment.currentMinute));
end

function Gc_Gui_FactoryBig:onCreateDetailInputTitle(element)
    if self.tmp_input ~= nil then
        element:setText(self.tmp_input.title);
    end;
end

function Gc_Gui_FactoryBig:onCreateDetailInputCapacity(element)
    if self.tmp_input ~= nil then
        element:setText(string.format(g_company.languageManager:getText("GC_gui_liter"), g_i18n:formatNumber(self.tmp_input.capacity, 0)));
    end;
end

function Gc_Gui_FactoryBig:onCreateDetailInputFillLevel(element)
    if self.tmp_input ~= nil then
        element:setText(string.format(g_company.languageManager:getText("GC_gui_liter"), g_i18n:formatNumber(self.tmp_input.fillLevel, 0)));
   end;
end

function Gc_Gui_FactoryBig:onCreateDetailInputBar(element)
    if self.tmp_input ~= nil then
        element:setScale(self.tmp_input.fillLevel / self.tmp_input.capacity);
    end;
end

function Gc_Gui_FactoryBig:onCreateDetailInputPercent(element)
    if self.tmp_input ~= nil then
        element:setText(string.format("%s%%", g_i18n:formatNumber(self.tmp_input.fillLevel / self.tmp_input.capacity * 100, 0)));
    end;
end

function Gc_Gui_FactoryBig:onCreateDetailInputButtonMinusPlus(element)
    if self.tmp_input ~= nil then
        element.input = self.tmp_input;
    end;
end

function Gc_Gui_FactoryBig:onCreateDetailInputBuyText(element)
    if self.tmp_input ~= nil then
        element.parent.buyTextElement = element;
        element:setText(string.format(g_company.languageManager:getText("GC_gui_liter"), g_i18n:formatNumber(Utils.getNoNil(element.parent.buyLiters, 0), 0)));
    end;
end

function Gc_Gui_FactoryBig:onCreateDetailInputBuyButton(element)
    if self.tmp_input ~= nil then
        if element.name == "button" then
            element.input = self.tmp_input;
        end;
        if element.name == "text" then
            element.parent.parent.buyButtonTextElement = element;
            element:setText(string.format(g_company.languageManager:getText("GC_gui_buyText"), g_i18n:formatMoney(0, 0)));
        end;
    end;
end

function Gc_Gui_FactoryBig:onClickDetailMinus(element)
    self.currentFactory:changeBuyLiters(element.input, Gc_Gui_FactoryBig.BUYSTEP * -1);
    local liters, price = self.currentFactory:getProductBuyPrice(element.input);
    element.parent.buyTextElement:setText(string.format(g_company.languageManager:getText("GC_gui_liter"), g_i18n:formatNumber(liters, 0)));
    element.parent.buyButtonTextElement:setText(string.format(g_company.languageManager:getText("GC_gui_buyText"), g_i18n:formatMoney(price, 0)));
end

function Gc_Gui_FactoryBig:onClickDetailPlus(element)   
    self.currentFactory:changeBuyLiters(element.input, Gc_Gui_FactoryBig.BUYSTEP);
    local liters, price = self.currentFactory:getProductBuyPrice(element.input);
    element.parent.buyTextElement:setText(string.format(g_company.languageManager:getText("GC_gui_liter"), g_i18n:formatNumber(liters, 0))); 
    element.parent.buyButtonTextElement:setText(string.format(g_company.languageManager:getText("GC_gui_buyText"), g_i18n:formatMoney(price, 0)));
end

function Gc_Gui_FactoryBig:onClickDetailBuy(element)   
    self.currentFactory:doProductPurchase(element.input);
    self:setDetails();
end

function Gc_Gui_FactoryBig:onCreateDetailOutputTitle(element)
    if self.tmp_output ~= nil then
        element:setText(self.tmp_output.title);
    end;
end

function Gc_Gui_FactoryBig:onCreateDetailOutputCapacity(element)
    if self.tmp_output ~= nil then
        element:setText(string.format(g_company.languageManager:getText("GC_gui_liter"), g_i18n:formatNumber(self.tmp_output.capacity, 0)));
    end;
end

function Gc_Gui_FactoryBig:onCreateDetailOutputFillLevel(element)
    if self.tmp_output ~= nil then
        element:setText(string.format(g_company.languageManager:getText("GC_gui_liter"), g_i18n:formatNumber(self.tmp_output.fillLevel, 0)));
   end;
end

function Gc_Gui_FactoryBig:onCreateDetailOutputBar(element)
    if self.tmp_output ~= nil then
        element:setScale(self.tmp_output.fillLevel / self.tmp_output.capacity);
    end;
end

function Gc_Gui_FactoryBig:onCreateDetailOutputPercent(element)
    if self.tmp_output ~= nil then
        element:setText(string.format("%s%%", g_i18n:formatNumber(self.tmp_output.fillLevel / self.tmp_output.capacity * 100, 0)));
    end;
end










