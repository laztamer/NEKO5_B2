--{ FROM SourceLib
--[[
'||''|.                               '||    ||'                                                  
 ||   ||  ... ..   ....   ... ... ...  |||  |||   ....   .. ...    ....     ... .   ....  ... ..  
 ||    ||  ||' '' '' .||   ||  ||  |   |'|..'||  '' .||   ||  ||  '' .||   || ||  .|...||  ||' '' 
 ||    ||  ||     .|' ||    ||| |||    | '|' ||  .|' ||   ||  ||  .|' ||    |''   ||       ||     
.||...|'  .||.    '|..'|'    |   |    .|. | .||. '|..'|' .||. ||. '|..'|'  '||||.  '|...' .||.    
                                                                          .|....'                 
    DrawManager - Tired of having to draw everything over and over again? Then use this!
    Functions:
        DrawManager()
    Methods:
        DrawManager:AddCircle(circle)
        DrawManager:RemoveCircle(circle)
        DrawManager:CreateCircle(position, radius, width, color)
        DrawManager:OnDraw()
--]]
class 'DrawManager'
--[[
    New instance of DrawManager
--]]
function DrawManager:__init()
    self.objects = {}		
    Callback.Bind('Draw', function() self:OnDraw() end)
end
--[[
    Add an existing circle to the draw manager
    @param circle | class | _Circle instance
--]]
function DrawManager:AddCircle(circle)
    assert(circle, "DrawManager: circle is invalid!")
    for _, object in ipairs(self.objects) do
        assert(object ~= circle, "DrawManager: object was already in DrawManager")
    end
    table.insert(self.objects, circle)
end
--[[
    Removes a circle from the draw manager
    @param circle | class | _Circle instance
--]]
function DrawManager:RemoveCircle(circle)
    assert(circle, "DrawManager:RemoveCircle(): circle is invalid!")
    for index, object in ipairs(self.objects) do
        if object == circle then
            table.remove(self.objects, index)
        end
    end
end
--[[
    Create a new circle and add it aswell to the DrawManager instance
    @param position | vector | Center of the circle
    @param radius   | float  | Radius of the circle
    @param width    | int    | Width of the circle outline
    @param color    | table  | Color of the circle in a tale format { a, r, g, b }
    @return         | class  | Instance of the newly create Circle class
--]]
function DrawManager:CreateCircle(position, radius, width, color)
    local circle = _Circle(position, radius, width, color)
    self:AddCircle(circle)
    return circle
end
--[[
    DO NOT CALL THIS MANUALLY! This will be called automatically.
--]]
function DrawManager:OnDraw()
    for _, object in ipairs(self.objects) do
        if object.enabled then
            object:Draw()
        end
    end
end
--[[
                  ..|'''.|  ||                  '||          
                .|'     '  ...  ... ..    ....   ||    ....  
                ||          ||   ||' '' .|   ''  ||  .|...|| 
                '|.      .  ||   ||     ||       ||  ||      
                 ''|....'  .||. .||.     '|...' .||.  '|...' 
    Functions:
        _Circle(position, radius, width, color)
    Members:
        _Circle.enabled  | bool   | Enable or diable the circle (displayed)
        _Circle.mode     | int    | See circle modes below
        _Circle.position | vector | Center of the circle
        _Circle.radius   | float  | Radius of the circle
        -- These are not changeable when a menu is set
        _Circle.width    | int    | Width of the circle outline
        _Circle.color    | table  | Color of the circle in a tale format { a, r, g, b }
        _Circle.quality  | float  | Quality of the circle, the higher the smoother the circle
    Methods:
        _Circle:AddToMenu(menu, paramText, addColor, addWidth, addQuality)
        _Circle:SetEnabled(enabled)
        _Circle:Set2D()
        _Circle:Set3D()
        _Circle:SetMinimap()
        _Circle:SetQuality(qualtiy)
        _Circle:SetDrawCondition(condition)
        _Circle:LinkWithSpell(spell, drawWhenReady)
        _Circle:Draw()
--]]
class '_Circle'
-- Circle modes
CIRCLE_2D      = 0
CIRCLE_3D      = 1
CIRCLE_MINIMAP = 2
-- Number of currently created circles
local circleCount = 1
--[[
    New instance of Circle
    @param position | vector | Center of the circle
    @param radius   | float  | Radius of the circle
    @param width    | int    | Width of the circle outline
    @param color    | table  | Color of the circle in a tale format { a, r, g, b }
--]]
function _Circle:__init(position, radius, width, color)
	assert(position and position.x and (position.y and position.z or position.y), "_Circle: position is invalid!")
	assert(radius and type(radius) == "number", "_Circle: radius is invalid!")
	assert(not color or color and type(color) == "table" and #color == 4, "_Circle: color is invalid!")
	self.enabled   = true
	self.condition = nil
	self.menu        = nil
	self.menuEnabled = nil
	self.menuColor   = nil
	self.menuWidth   = nil
	self.menuQuality = nil
	self.mode = CIRCLE_3D
	self.position = position
	self.radius   = radius
	self.width    = width or 1
	self.color    = color or { 255, 255, 255, 255 }
	self.quality  = radius / 5
	self._circleId  = "circle" .. circleCount
	self._circleNum = circleCount
	circleCount = circleCount + 1
	self.colorStr= {
		"aliceblue", "blue","brown", "crimson", "cyan", "deeppink", "deepskyblue",
		"forestgreen","gold","gray","green","indigo","khaki", "orange", "pink", "purple",  "red", "silver", "violet", "white"
	}
	self.colorStr2= {
		"aliceblue", "antiquewhite", "aqua", "aquamarine", "azure", "beige", "bisque", "black", "blanchedalmond", "blue", "blueviolet", "brown",
		"burlywood", "cadetblue", "chartreuse", "chocolate", "coral", "cornflowerblue", "cornsilk", "crimson", "cyan", "darkblue", "darkcyan",
		"darkgoldenrod", "darkgray", "darkgreen", "darkgrey", "darkkhaki", "darkmagenta", "darkolivegreen", "darkorange", "darkorchid", "darkred",
		"darksalmon", "darkseagreen", "darkslateblue", "darkslategray", "darkslategrey", "darkturquoise", "darkviolet", "deeppink", "deepskyblue",
		"dimgray", "dimgrey", "dodgerblue", "firebrick", "floralwhite", "forestgreen", "fuchsia", "gainsboro", "ghostwhite", "gold",
		"goldenrod", "gray", "grey", "green", "greenyellow", "honeydew", "hotpink", "indianred", "indigo", "ivory", "khaki", "lavender",
		"lavenderblush", "lawngreen", "lemonchiffon", "lightblue", "lightcoral", "lightcyan", "lightgoldenrodyellow", "lightgray",
		"lightgreen", "lightgrey", "lightpink", "lightsalmon", "lightseagreen", "lightskyblue", "lightslategray", "lightslategrey",
		"lightsteelblue", "lightyellow", "lime", "limegreen", "linen", "magenta", "maroon", "mediumaquamarine", "mediumblue", "mediumorchid",
		"mediumpurple", "mediumseagreen", "mediumslateblue", "mediumspringgreen", "mediumturquoise", "mediumvioletred", "midnightblue",
		"mintcream", "mistyrose", "moccasin", "navajowhite", "navy", "oldlace", "olive", "olivedrab", "orange", "orangered", "orchid",
		"palegoldenrod", "palegreen", "paleturquoise", "palevioletred", "papayawhip", "peachpuff", "peru", "pink", "plum",
		"powderblue", "purple",  "red",  "rosybrown", "royalblue", "saddlebrown", "salmon", "sandybrown", "seagreen", "seashell",
		"sienna", "silver", "skyblue", "slateblue", "slategray", "slategrey", "snow", "springgreen", "steelblue",  "teal",  "thistle",
		"tomato", "turquoise", "violet", "wheat", "white", "whitesmoke", "yellow", "yellowgreen" 
	}
end
--[[
    Adds this circle to a given menu
    @param menu       | scriptConfig | Instance of script config to add this circle to
    @param paramText  | string       | Text for the menu entry
    @param addColor   | bool         | Add color option
    @param addWidth   | bool         | Add width option
    @param addQuality | bool         | Add quality option
    @return           | class        | The current instance
--]]
function _Circle:AddToMenu(menu, paramText, addColor, addWidth, addQuality, value)
    assert(menu, "_Circle: menu is invalid!")
    assert(self.menu == nil, "_Circle: Already bound to a menu!")
		menu:Menu(self._circleId, paramText or "Circle " .. self._circleNum)
    self.menu = menu[self._circleId]
    -- Enabled
    local paramId = paramText .. " enable"
    self.menu:Boolean("Enabled", paramText, self.enabled)
    --self.menuEnabled = self.menu._param[#self.menu._param].Value()
    paramId = paramText .. " color"
    self.menu:DropDown("colorss",paramText, value, self.colorStr)		
    -- if addColor or addWidth or addQuality then
        -- -- Color
        -- if addColor then
            -- paramId = self._circleId .. "color"
            -- self.menu:DropDown(paramId, "Color",1, self.colorStr)						
						-- -- menu.Orbwalking:DropDown("cancel", "Animation Cancel Method", 1, { "Move","Laugh","Dance","Taunt","joke","No Cancel"})						
            -- self.menuColor = self.menu.paramId:Value()
        -- end
        -- -- -- Width
        -- -- if addWidth then
            -- -- paramId = self._circleId .. "width"
            -- -- self.menu:Slider(paramId, "Width", self.width, 1, 5, 1)
            -- -- --self.menuWidth = self.menu._param[#self.menu._param]
        -- -- end
        -- -- -- Quality
        -- -- if addQuality then
            -- -- paramId = self._circleId .. "quality"
            -- -- self.menu:Slider(paramId, "Quality", math.round(self.quality), 10, math.round(self.radius / 5))
            -- -- --self.menuQuality = self.menu._param[#self.menu._param]
        -- -- end
    -- end
    return self
end
--[[
    Set the enable status of the circle
    @param enabled | bool  | Enable state of this circle
    @return        | class | The current instance
--]]
function _Circle:SetEnabled(enabled)
    self.enabled = enabled
    return self
end
--[[
    Set this circle to be displayed 2D
    @return | class | The current instance
--]]
function _Circle:Set2D()
    self.mode = CIRCLE_2D
    return self
end
--[[
    Set this circle to be displayed 3D
    @return | class | The current instance
--]]
function _Circle:Set3D()
    self.mode = CIRCLE_3D
    return self
end
--[[
    Set this circle to be displayed on the minimap
    @return | class | The current instance
--]]
function _Circle:SetMinimap()
    self.mode = CIRCLE_MINIMAP
    return self
end
--[[
    Set the display quality of this circle
    @return | class | The current instance
--]]
function _Circle:SetQuality(qualtiy)
    assert(qualtiy and type(qualtiy) == "number", "_Circle: quality is invalid!")
    self.quality = quality
    return self
end
--[[
    Set the draw condition of this circle
    @return | class | The current instance
--]]
function _Circle:SetDrawCondition(condition)
    assert(condition and type(condition) == "function", "_Circle: condition is invalid!")
    self.condition = condition
    return self
end
--[[
    Links the spell range with the circle radius
    @param spell         | class | Instance of Spell class
    @param drawWhenReady | bool  | Decides whether to draw the circle when the spell is ready or not
    @return              | class | The current instance
--]]
function _Circle:LinkWithSpell(spell, drawWhenReady)
    assert(spell, "_Circle:LinkWithSpell(): spell is invalid")
    self._linkedSpell = spell
    self._linkedSpellReady = drawWhenReady or false
    return self
end
--[[
    Draw this circle, should only be called from OnDraw()
--]]
function _Circle:Draw()
    -- Don't draw if condition is not met
    if self.condition ~= nil and self.condition() == false then return end
    -- Update values if linked spell is given
    if self._linkedSpell then
        -- Temporary error prevention
        if not self._linkedSpell.IsReady then
            if not _G.SourceLibLinkedSpellInformed then
                _G.SourceLibLinkedSpellInformed = true
                print("SourceLib: The script \"" .. GetCurrentEnv().FILE_NAME .. "\" is causing issues with circle drawing. Please contact he developer of the named script so he fixes the issue, thanks.")
            end
            return
        else
            if self._linkedSpellReady and not self._linkedSpell:IsReady() then return end
            -- Update the radius with the spell range
            self.radius = self._linkedSpell.range
        end
    end
    -- Menu found
    if self.menu then 
			if self.menuEnabled ~= nil then
				if not self.menu[self.menuEnabled.var] then return end
			end
			if self.menuColor ~= nil then
					-- self.color = self.menu[self.menuColor.var]
					-- print(self.menuColor.var:Value())					
					-- self.color = GetColorTable(self.menuColor.var:Value())
			end
			if self.menuWidth ~= nil then
					self.width = self.menu[self.menuWidth.var]
			end
			if self.menuQuality ~= nil then
					self.quality = self.menu[self.menuQuality.var]
			end
    end
    -- local center = Game.WorldToScreen(D3DXVECTOR3(self.position.x, self.position.y, self.position.z))
    local center = Graphics.WorldToScreen(Geometry.Vector3(self.position.x, self.position.y, self.position.z))
    if not self:PointOnScreen(center.x, center.y) and self.mode ~= CIRCLE_MINIMAP then
        return
    end
		-- print(tostring(self.menu.colorss:Value()))
		-- print(tostring(self.colorStr[self.menu.colorss:Value()]))
		-- print(tostring(GetColor(self.colorStr[self.menu.colorss:Value()])))
		self.SetColors = GetColor(self.colorStr[self.menu.colorss:Value()])
	-- Circle (float.x, float.y, float.z, int.radius, int maxRadius, int innerColor, int outerColor) 
 	-- Circle (float.x, float.y, int minRadius, int maxRadius, int innerColor, int outerColor) 
 	-- Circle (float.x, float.y, int radius, int color)	
	if self.menu.Enabled:Value() then
    if self.mode == CIRCLE_2D then
        Graphics.DrawCircle(self.position.x, self.position.y, self.radius, self.SetColors)
    elseif self.mode == CIRCLE_3D then
        Graphics.DrawCircle(self.position.x, self.position.y, self.position.z, self.radius, self.SetColors)
    elseif self.mode == CIRCLE_MINIMAP then
        Graphics.DrawCircle(self.position.x, self.position.y, self.position.z, self.radius, self.SetColors)
    else
        print("Circle: Something is wrong with the circle.mode!")
    end
	end
end
function TARGB(colorTable)

    assert(colorTable and type(colorTable) == "table" and #colorTable == 4, "TARGB: colorTable is invalid!")
    return Graphics.ARGB(colorTable[1], colorTable[2], colorTable[3], colorTable[4])

end
function _Circle:PointOnScreen(x, y)
    return x <= WINDOW_W and x >= 0 and y >= 0 and y <= WINDOW_H
end
function _Circle:__eq(other)
    return other._circleId and other._circleId == self._circleId or false
end
--[[
 .|'''.|                   '||  '||  
 ||..  '  ... ...    ....   ||   ||  
  ''|||.   ||'  || .|...||  ||   ||  
.     '||  ||    | ||       ||   ||  
|'....|'   ||...'   '|...' .||. .||. 
           ||                        
          ''''                       
    Spell - Handled with ease!
    Functions:
        Spell(spellId, range, packetCast)
    Members:
        Spell.range          | float  | Range of the spell, please do NOT change this value, use Spell:SetRange() instead
        Spell.rangeSqr       | float  | Squared range of the spell, please do NOT change this value, use Spell:SetRange() instead
        Spell.packetCast     | bool   | Set packet cast state
        -- This only applies for skillshots
        Spell.sourcePosition | vector | From where the spell is casted, default: player
        Spell.sourceRange    | vector | From where the range should be calculated, default: player
        -- This only applies for AOE skillshots
        Spell.minTargetsAoe  | int    | Set minimum targets for AOE damage
    Methods:
        Spell:SetRange(range)
        Spell:SetSource(source)
        Spell:SetSourcePosition(source)
        Spell:SetSourceRange(source)
        Spell:SetSkillshot(VP, skillshotType, width, delay, speed, collision)
        Spell:SetAOE(useAoe, radius, minTargetsAoe)
        Spell:SetCharged(spellName, chargeDuration, maxRange, timeToMaxRange, abortCondition)
        Spell:IsCharging()
        Spell:Charge()
        Spell:SetHitChance(hitChance)
        Spell:ValidTarget(target)
        Spell:GetPrediction(target)
        Spell:CastIfDashing(target)
        Spell:CastIfImmobile(target)
        Spell:Cast(param1, param2)
        Spell:AddAutomation(automationId, func)
        Spell:RemoveAutomation(automationId)
        Spell:ClearAutomations()
        Spell:TrackCasting(spellName)
        Spell:WillHitTarget()
        Spell:RegisterCastCallback(func)
        Spell:GetLastCastTime()
        Spell:IsInRange(target, from)
        Spell:IsReady()
        Spell:GetManaUsage()
        Spell:GetCooldown()
        Spell:GetLevel()
        Spell:GetName()
--]]
_G.srcLib = {}
class 'Spell'
-- Class related constants
SKILLSHOT_LINEAR   = 0
SKILLSHOT_CIRCULAR = 1
SKILLSHOT_CONE     = 2
-- Different SpellStates returned when Spell:Cast() is called
SPELLSTATE_TRIGGERED          = 0
SPELLSTATE_OUT_OF_RANGE       = 1
SPELLSTATE_LOWER_HITCHANCE    = 2
SPELLSTATE_COLLISION          = 3
SPELLSTATE_NOT_ENOUGH_TARGETS = 4
SPELLSTATE_NOT_DASHING        = 5
SPELLSTATE_DASHING_CANT_HIT   = 6
SPELLSTATE_NOT_IMMOBILE       = 7
SPELLSTATE_INVALID_TARGET     = 8
SPELLSTATE_NOT_TRIGGERED      = 9
-- Spell identifier number used for comparing spells
local spellNum = 1
--[[
    New instance of Spell
    @param spellId    | int          | Spell ID (_Q, _W, _E, _R)
    @param range      | float        | Range of the spell
    @param packetCast | bool         | (optional) Enable packet casting
    @param menu       | scriptCofnig | (Sub)Menu to add the spell casting menu to
--]]
function Spell:__init(spellId, range, packetCast, menu)
    assert(spellId ~= nil and range ~= nil and type(spellId) == "number" and type(range) == "number", "Spell: Can't initialize Spell without valid arguments.")
    if _G.srcLib.spellMenu == nil then
        DelayAction(function(menu)
            if _G.srcLib.spellMenu == nil and not _G.srcLib.informedOutdated and Prodiction then
                if tonumber(Prodiction.GetVersion()) < 1.1 then
                    print("<b></font> <font color=\"#FF0000\">Please update your Prodiction to at least version 1.1 if you want to use it with SourceLib!</font></b>")
                    _G.srcLib.informedOutdated = true
                else
                    menu = menu or scriptConfig("[SourceLib] SpellClass", "srcSpellClass")
                    menu:addParam("predictionType", "Prediction Type",     SCRIPT_PARAM_LIST, 1, { "VPrediction", "Prodiction" })
                    _G.srcLib.spellMenu = menu
                    print("SourceLib: Prodiction support enabled, but it's highly recommended to use VPrediction at the moment due to error spamming related to Prodiction!")
                end
            end
        end, 3, { menu })
    end
    self.spellId = spellId
    self:SetRange(range)
    self.packetCast = packetCast or false
    self:SetSource(player)
    self._automations = {}
    self._spellNum = spellNum
    spellNum = spellNum + 1
    -- VPredicion default
    self.predictionType = 1
		Callback.Bind('Tick', function() if _G.srcLib.spellMenu ~= nil then self:SetPredictionType(_G.srcLib.spellMenu.predictionType:Value()) end end) 
end
--[[
    Update the spell range with the new given value
    @param range | float | Range of the spell
    @return      | class | The current instance
--]]
function Spell:SetRange(range)
    assert(range and type(range) == "number", "Spell: range is invalid")
    self.range = range
    self.rangeSqr = math.pow(range, 2)
    return self
end
--[[
    Update both the sourcePosition and sourceRange from where everything will be calculated
    @param source | Cunit | Source position, for example player
    @return       | class | The current instance
--]]
function Spell:SetSource(source)
    assert(source, "Spell: source can't be nil!")
    self.sourcePosition = source
    self.sourceRange    = source
    return self
end
--[[
    Update the source posotion from where the spell will be shot
    @param source | Cunit | Source position from where the spell will be shot, player by default
    @ return      | class | The current instance
--]]
function Spell:SetSourcePosition(source)
    assert(source, "Spell: source can't be nil!")
    self.sourcePosition = source
    return self
end
--[[
    Update the source unit from where the range will be calculated
    @param source | Cunit | Source object unit from where the range should be calculed
    @return       | class | The current instance
--]]
function Spell:SetSourceRange(source)
    assert(source, "Spell: source can't be nil!")
    self.sourceRange = source
    return self
end
--[[
    Define this spell as skillshot (can't be reversed)
    @param VP            | class | Instance of VPrediction
    @param skillshotType | int   | Type of this skillshot
    @param width         | float | Width of the skillshot
    @param delay         | float | (optional) Delay in seconds
    @param speed         | float | (optional) Speed in units per second
    @param collision     | bool  | (optional) Respect unit collision when casting
    @rerurn              | class | The current instance
--]]
function Spell:SetSkillshot(VP, skillshotType, width, delay, speed, collision)
    assert(skillshotType ~= nil, "Spell: Need at least the skillshot type!")
    self.VP = VP
    self.skillshotType = skillshotType
    self.width = width or 0
    self.delay = delay or 0
    self.speed = speed
    self.collision = collision
    if not self.hitChance then self.hitChance = 2 end
    return self
end
--[[
    Sets the prediction type
    @param typeId | int | type ID (1 = VPrediction (default), 2 = Prodiction)
--]]
function Spell:SetPredictionType(typeId)
    assert(typeId and type(typeId) == 'number', 'Spell:SetPredictionType(): typeId is invalid!')
    self.predictionType = typeId
end
--[[
    Set the AOE status of this spell, this can be changed later
    @param useAoe        | bool  | New AOE state
    @param radius        | float | Radius of the AOE damage
    @param minTargetsAoe | int   | Minimum targets to be hitted by the AOE damage
    @rerurn              | class | The current instance
--]]
function Spell:SetAOE(useAoe, radius, minTargetsAoe)
    self.useAoe = useAoe or false
    self.radius = radius or self.width
    self.minTargetsAoe = minTargetsAoe or 0
    return self
end
--[[
    Define this spell as charged spell
    @param spellName      | string   | Name of the spell, example: VarusQ
    @param chargeDuration | float    | Seconds of the spell to charge, after the time the charge expires
    @param maxRage        | float    | Max range the spell will have after fully charging
    @param timeToMaxRange | float    | Time in seconds to reach max range after casting the spell
    @param abortCondition | function | (optional) A function which returns true when the charge process should be stopped.
--]]
function Spell:SetCharged(spellName, chargeDuration, maxRange, timeToMaxRange, abortCondition)
    assert(self.skillshotType, "Spell:SetCharged(): Only skillshots can be defined as charged spells!")
    assert(spellName and type(spellName) == "string" and chargeDuration and type(chargeDuration) == "number", "Spell:SetCharged(): Some or all arguments are invalid!")
    assert(self.__charged == nil, "Spell:SetCharged(): Already marked as charged spell!")
    self.__charged           = true
    self.__charged_aborted   = true
    self.__charged_spellName = spellName
    self.__charged_duration  = chargeDuration
    self.__charged_maxRange       = maxRange
    self.__charged_chargeTime     = timeToMaxRange
    self.__charged_abortCondition = abortCondition or function () return false end
    self.__charged_active   = false
    self.__charged_castTime = 0
    -- Register callbacks
    if not self.__tickCallback then
			Callback.Bind('Tick', function()	self:OnTick()	end)
      self.__tickCallback = true
    end
    if not self.__sendPacketCallback then
				Callback.Bind('SendPacket', function(p) self:OnSendPacket(p) end)
        self.__sendPacketCallback = true
    end
    if not self.__processSpellCallback then
			Callback.Bind('ProcessSpell', function(unit, spell) self:OnProcessSpell(unit, spell) end)
      self.__processSpellCallback = true
    end
    return self
end
--[[
    Returns whether the spell is currently charging or not
    @return | bool | Spell charging or not
]]
function Spell:IsCharging()
    return self.__charged_abortCondition() == false and self.__charged_active
end
--[[
    Charges the spell
--]]
function Spell:Charge()
    assert(self.__charged, "Spell:Charge(): Spell is not defined as chargeable spell!")
    if not self:IsCharging() then
        myHero:CastSpell(self.spellId, mousePos.x, mousePos.z)
    end
end
-- Internal function, do not use!
function Spell:_AbortCharge()
    if self.__charged and self.__charged_active then
        self.__charged_aborted = true
        self.__charged_active  = false
        self:SetRange(self.__charged_initialRange)
    end
end
--[[
    Set the hitChance of the predicted target position when to cast
    @param hitChance | int   | New hitChance for predicted positions
    @rerurn          | class | The current instance
--]]
function Spell:SetHitChance(hitChance)
    self.hitChance = hitChance or 2
    return self
end
--[[
    Checks if the given target is valid for the spell
    @param target | userdata | Target to be checked if valid
    @return       | bool     | Valid target or not
--]]
function Spell:ValidTarget(target, range)
    return ValidTarget(target, range or self.range)
end
--[[
    Returns the prediction results from VPrediction/Prodiction in a VPrediction result layout
    @return | various data | Prediction result in VPrediction layout
--]]
function Spell:GetPrediction(target)
    if self.skillshotType ~= nil then
        -- VPrediction
        if self.predictionType == 1 then
            if self.skillshotType == SKILLSHOT_LINEAR then
                if self.useAoe then
                    return self.VP:GetLineAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
                else
                    return self.VP:GetLineCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
                end
            elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                if self.useAoe then
                    return self.VP:GetCircularAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
                else
                    return self.VP:GetCircularCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
                end
             elseif self.skillshotType == SKILLSHOT_CONE then
                if self.useAoe then
                    return self.VP:GetConeAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
                else
                    return self.VP:GetLineCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
                end
            end
        -- Prodiction
        elseif self.predictionType == 2 then
            if self.useAoe then
                if self.skillshotType == SKILLSHOT_LINEAR then
                    local pos, info, objects = Prodiction.GetLineAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    local hitChance = self.collision and info.collision() and -1 or info.hitchance
                    return pos, hitChance, #objects
                elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                    local pos, info, objects = Prodiction.GetCircularAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    local hitChance = self.collision and info.collision() and -1 or info.hitchance
                    return pos, hitChance, #objects
                 elseif self.skillshotType == SKILLSHOT_CONE then
                    local pos, info, objects = Prodiction.GetConeAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    local hitChance = self.collision and info.collision() and -1 or info.hitchance
                    return pos, hitChance, #objects
                end
            else
                local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                local hitChance = self.collision and info.collision() and -1 or info.hitchance
                return pos, hitChance, info.pos
            end
            -- Someday it will look the same as with VPrediction ;D
            --[[
            if self.skillshotType == SKILLSHOT_LINEAR then
                if self.useAoe then
                    local pos, info, objects = Prodiction.GetLineAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, type(objects) == "table" and #objects or 10
                else
                    local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, info.pos
                end
            elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                if self.useAoe then
                    local pos, info, objects = Prodiction.GetCircularAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, type(objects) == "table" and #objects or 10
                else
                    local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, info.pos
                end
             elseif self.skillshotType == SKILLSHOT_CONE then
                if self.useAoe then
                    local pos, info, objects = Prodiction.GetConeAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, type(objects) == "table" and #objects or 10
                else
                    local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, info.pos
                end
            end
            ]]
        end
    end
end
--[[
    Tries to cast the spell when the target is dashing
    @param target | Cunit | Dashing target to attack
    @param return | int   | SpellState of the current spell
--]]
function Spell:CastIfDashing(target)
    -- Don't calculate stuff when target is invalid
    if not ValidTarget(target) then return SPELLSTATE_INVALID_TARGET end
    if self.skillshotType ~= nil then
        local isDashing, canHit, position = self.VP:IsDashing(target, self.delay + 0.07 + Game.Latency() / 2000, self.width, self.speed, self.sourcePosition)
        -- Out of range
        if self.rangeSqr < GetDistanceSqr(self.sourceRange, position,"20") then return SPELLSTATE_OUT_OF_RANGE end
        if isDashing and canHit then
            -- Collision
            if not self.collision or self.collision and not self.VP:CheckMinionCollision(target, position, self.delay + 0.07 + Game.Latency() / 2000, self.width, self.range, self.speed, self.sourcePosition, false, true) then
                return self:__Cast(self.spellId, position.x, position.z)
            else
                return SPELLSTATE_COLLISION
            end
        elseif not isDashing then return SPELLSTATE_NOT_DASHING
        else return SPELLSTATE_DASHING_CANT_HIT end
    else
        local isDashing, canHit, position = self.VP:IsDashing(target, 0.25 + 0.07 + Game.Latency() / 2000, 1, math.huge, self.sourcePosition)
        -- Out of range
        if self.rangeSqr < GetDistanceSqr(self.sourceRange, position,"21") then return SPELLSTATE_OUT_OF_RANGE end
        if isDashing and canHit then
            return self:__Cast(position.x, position.z)
        elseif not isDashing then return SPELLSTATE_NOT_DASHING
        else return SPELLSTATE_DASHING_CANT_HIT end
    end
    return SPELLSTATE_NOT_TRIGGERED
end
--[[
    Tries to cast the spell when the target is immobile
    @param target | Cunit | Immobile target to attack
    @param return | int   | SpellState of the current spell
--]]
function Spell:CastIfImmobile(target)
    -- Don't calculate stuff when target is invalid
    if not ValidTarget(target) then return SPELLSTATE_INVALID_TARGET end
    if self.skillshotType ~= nil then
        local isImmobile, position = self.VP:IsImmobile(target, self.delay + 0.07 + Game.Latency() / 2000, self.width, self.speed, self.sourcePosition)
        -- Out of range
        if self.rangeSqr < GetDistanceSqr(self.sourceRange, position,"22") then return SPELLSTATE_OUT_OF_RANGE end
        if isImmobile then
            -- Collision
            if not self.collision or (self.collision and not self.VP:CheckMinionCollision(target, position, self.delay + 0.07 + Game.Latency() / 2000, self.width, self.range, self.speed, self.sourcePosition, false, true)) then
                return self:__Cast(position.x, position.z)
            else
                return SPELLSTATE_COLLISION
            end
        else return SPELLSTATE_NOT_IMMOBILE end
    else
        local isImmobile, position = self.VP:IsImmobile(target, 0.25 + 0.07 + Game.Latency() / 2000, 1, math.huge, self.sourcePosition)
        -- Out of range
        if self.rangeSqr < GetDistanceSqr(self.sourceRange, target,"23") then return SPELLSTATE_OUT_OF_RANGE end
        if isImmobile then
            return self:__Cast(target)
        else
            return SPELLSTATE_NOT_IMMOBILE
        end
    end
    return SPELLSTATE_NOT_TRIGGERED
end
--[[
    Cast the spell, respecting previously made decisions about skillshots and AOE stuff
    @param param1 | userdata/float | When param2 is nil then this can be the target object, otherwise this is the X coordinate of the skillshot position
    @param param2 | float          | Z coordinate of the skillshot position
    @param return | int            | SpellState of the current spell
--]]
function Spell:Cast(param1, param2)
    if self.skillshotType ~= nil and param1 ~= nil and param2 == nil then
        -- Don't calculate stuff when target is invalid
        if not ValidTarget(param1) then return SPELLSTATE_INVALID_TARGET end
        local castPosition, hitChance, position, nTargets
        if self.skillshotType == SKILLSHOT_LINEAR or self.skillshotType == SKILLSHOT_CONE then
            if self.useAoe then
                castPosition, hitChance, nTargets = self:GetPrediction(param1)
            else
                castPosition, hitChance, position = self:GetPrediction(param1)
                -- Out of range
                if self.rangeSqr < GetDistanceSqr(self.sourceRange, position,"24") then return SPELLSTATE_OUT_OF_RANGE end
            end
        elseif self.skillshotType == SKILLSHOT_CIRCULAR then
            if self.useAoe then
                castPosition, hitChance, nTargets = self:GetPrediction(param1)
            else
                castPosition, hitChance, position = self:GetPrediction(param1)
                -- Out of range
                if math.pow(self.range + self.width + self.VP:GetHitBox(param1), 2) < GetDistanceSqr(self.sourceRange, position,"25") then return SPELLSTATE_OUT_OF_RANGE end
            end
        end
        -- Validation (for Prodiction)
        if not castPosition then return SPELLSTATE_NOT_TRIGGERED end
        -- AOE not enough targets
        if nTargets and nTargets < self.minTargetsAoe then return SPELLSTATE_NOT_ENOUGH_TARGETS end
        -- Collision detected
        if hitChance == -1 then return SPELLSTATE_COLLISION end
        -- Hitchance too low
        if hitChance and hitChance < self.hitChance then return SPELLSTATE_LOWER_HITCHANCE end
        -- Out of range
        if self.rangeSqr < GetDistanceSqr(self.sourceRange, castPosition, "26") then return SPELLSTATE_OUT_OF_RANGE end
        param1 = castPosition.x
        param2 = castPosition.z
    end
    -- Cast charged spell
    if param1 ~= nil and param2 ~= nil and self.__charged and self:IsCharging() then
        --print("Sending xerath Q")
        local p = CLoLPacket(0xE6) 
        p:EncodeF(player.networkID)
        p:Encode1(0xE2)
        p:Encode1(0)
        p:EncodeF(param1)
        p:EncodeF(0)
        p:EncodeF(param2)
        -- SendPacket(p)
				p:Send()
        return SPELLSTATE_TRIGGERED
    end
    -- Cast the spell
    return self:__Cast(param1, param2)
end
--[[
    Internal function, do not use this!
--]]
function Spell:__Cast(param1, param2)
    if self.packetCast then
        if param1 ~= nil and param2 ~= nil then
            if type(param1) ~= "number" and type(param2) ~= "number" and VectorType(param1) and VectorType(param2) then
                Packet("S_CAST", {spellId = self.spellId, toX = param2.x, toY = param2.z, fromX = param1.x, fromY = param1.z}):send()
            else
                Packet("S_CAST", {spellId = self.spellId, toX = param1, toY = param2, fromX = param1, fromY = param2}):send()
            end
        elseif param1 ~= nil then
            Packet("S_CAST", {spellId = self.spellId, toX = param1.x, toY = param1.z, fromX = param1.x, fromY = param1.z, targetNetworkId = param1.networkID}):send()
        else
            Packet("S_CAST", {spellId = self.spellId, toX = player.x, toY = player.z, fromX = player.x, fromY = player.z, targetNetworkId = player.networkID}):send()
        end
    else
        if param1 ~= nil and param2 ~= nil then
            if type(param1) ~= "number" and type(param2) ~= "number" and VectorType(param1) and VectorType(param2) then
                Packet("S_CAST", {spellId = self.spellId, toX = param2.x, toY = param2.z, fromX = param1.x, fromY = param1.z}):send()
            else
                myHero:CastSpell(self.spellId, param1, param2)
            end
        elseif param1 ~= nil then
            myHero:CastSpell(self.spellId, param1)
        else
            myHero:CastSpell(self.spellId)
        end
    end
    return SPELLSTATE_TRIGGERED
end
--[[
    Add an automation to the spell to let it cast itself when a certain condition is met
    @param automationId | string/int | The ID of the automation, example "AntiGapCloser"
    @param func         | function   | Function to be called when checking, should return a bool value indicating if it should be casted and optionally the cast params (ex: target or x and z)
--]]
function Spell:AddAutomation(automationId, func)
    assert(automationId, "Spell: automationId is invalid!")
    assert(func and type(func) == "function", "Spell: func is invalid!")
    for index, automation in ipairs(self._automations) do
        if automation.id == automationId then return end
    end
    table.insert(self._automations, { id == automationId, func = func })
    -- Register callbacks
    if not self.__tickCallback then
      Callback.Bind('Tick', function()	self:OnTick()	end)
      self.__tickCallback = true
    end
end
--[[
    Remove and automation by it's id
    @param automationId | string/int | The ID of the automation, example "AntiGapCloser"
--]]
function Spell:RemoveAutomation(automationId)
    assert(automationId, "Spell: automationId is invalid!")
    for index, automation in ipairs(self._automations) do
        if automation.id == automationId then
            table.remove(self._automations, index)
            break
        end
    end
end
--[[
    Clear all automations assinged to this spell
--]]
function Spell:ClearAutomations()
    self._automations = {}
end
--[[
    Track the spell like in OnProcessSpell to add more features to this Spell instance
    @param spellName | string/table | Case insensitive name(s) of the spell
    @return          | class        | The current instance
--]]
function Spell:TrackCasting(spellName)
    assert(spellName, "Spell:TrackCasting(): spellName is invalid!")
    assert(self.__tracked_spellNames == nil, "Spell:TrackCasting(): This spell is already tracked!")
    assert(type(spellName) == "string" or type(spellName) == "table", "Spell:TrackCasting(): Type of spellName is invalid: " .. type(spellName))
    self.__tracked_spellNames = type(spellName) == "table" and spellName or { spellName }
    -- Register callbacks
    if not self.__processSpellCallback then
			Callback.Bind('ProcessSpell', function(unit, spell) self:OnProcessSpell(unit, spell) end)
      self.__processSpellCallback = true
    end
    return self
end
--[[
    When the spell is casted and about to hit a target, this will return the following
    @return | CUnit,float | The target unit, the remaining time in seconds it will take to hit the target, otherwise nil
--]]
function Spell:WillHitTarget()
    -- TODO: VPrediction expert's work ;D
end
--[[
    Register a function which will be triggered when the spell is being casted the function will be given the spell object as parameter
    @param func | function | Function to be called when the spell is being processed (casted)
--]]
function Spell:RegisterCastCallback(func)
    assert(func and type(func) == "function" and self.__tracked_castCallback == nil, "Spell:RegisterCastCallback(): func is either invalid or a callback is already registered!")
    self.__tracked_castCallback = func
end
--[[
    Returns the os.clock() time when the spell was last casted
    @return | float | Time in seconds when the spell was last casted or nil if the spell was never casted or spell is not tracked
--]]
function Spell:GetLastCastTime()
    return self.__tracked_lastCastTime or 0
end
--[[
    Get if the target is in range
    @return | bool | In range or not
--]]
function Spell:IsInRange(target, from)
    return self.rangeSqr >= GetDistanceSqr(target, from or self.sourcePosition,"27")
end
--[[
    Get if the spell is ready or not
    @return | bool | Spell state ready or not
--]]
function Spell:IsReady()
    return player:CanUseSpell(self.spellId) == Game.SpellState.READY
end
--[[
    Get the mana usage of the spell
    @return | float | Mana usage of the spell
--]]
function Spell:GetManaUsage()
    return player:GetSpellData(self.spellId).mana
end
--[[
    Get the CURRENT cooldown of the spell
    @return | float | Current cooldown of the spell
]]
function Spell:GetCooldown(current)
  return current and player:GetSpellData(self.spellId).currentCd or player:GetSpellData(self.spellId).totalCooldown
end
--[[
    Get the stat points assinged to this spell (level)
    @return | int | Stat points assinged to this spell (level)
--]]
function Spell:GetLevel()
    return player:GetSpellData(self.spellId).level
end
--[[
    Get the name of the spell
    @return | string | Name of the the spell
--]]
function Spell:GetName()
    return player:GetSpellData(self.spellId).name
end
--[[
    Internal callback, don't use this!
--]]
function Spell:OnTick()
    -- Automations
    if self._automations and #self._automations > 0 then
        for _, automation in ipairs(self._automations) do
            local doCast, param1, param2 = automation.func()
            if doCast == true then
                self:Cast(param1, param2)
            end
        end
    end
    -- Charged spells
    if self.__charged then
        if self:IsCharging() then
            self:SetRange(math.min(self.__charged_initialRange + (self.__charged_maxRange - self.__charged_initialRange) * ((os.clock() - self.__charged_castTime) / self.__charged_chargeTime), self.__charged_maxRange))
        elseif not self.__charged_aborted and os.clock() - self.__charged_castTime > 0.1 then
            self:_AbortCharge()
        end
    end
end
--[[
    Internal callback, don't use this!
--]]
function Spell:OnProcessSpell(unit, spell)
    if unit and unit.valid and unit.isMe and spell and spell.name then
        -- Tracked spells
        if self.__tracked_spellNames then
            for _, trackedSpell in ipairs(self.__tracked_spellNames) do
                if trackedSpell:lower() == spell.name:lower() then
                    self.__tracked_lastCastTime = os.clock()
                    self.__tracked_castCallback(spell)
                end
            end
        end
        -- Charged spells
        if self.__charged and self.__charged_spellName:lower() == spell.name:lower() then
            self.__charged_active       = true
            self.__charged_aborted      = false
            self.__charged_initialRange = self.range
            self.__charged_castTime     = os.clock()
            self.__charged_count        = self.__charged_count and self.__charged_count + 1 or 1
            DelayAction(function(chargeCount)
                if self.__charged_count == chargeCount then
                    self:_AbortCharge()
                end
            end, self.__charged_duration, { self.__charged_count })
        end
    end
end
--[[
    Internal callback, don't use this!
--]]
function Spell:OnSendPacket(p)
    -- Charged spells
    if self.__charged then
        if p.header == 0xE6 then
            if os.clock() - self.__charged_castTime <= 0.1 then
                p:Block()
            end
        elseif p.header == Packet.headers.S_CAST then
            local packet = Packet(p)
            if packet:get("spellId") == self.spellId then
                if os.clock() - self.__charged_castTime <= self.__charged_duration then
                    self:_AbortCharge()
                    local newPacket = CLoLPacket(0xE6)
                    newPacket:EncodeF(player.networkID)
                    newPacket:Encode1(0xE2)
                    newPacket:Encode1(0)
                    newPacket:EncodeF(mousePos.x)
                    newPacket:EncodeF(mousePos.y)
                    newPacket:EncodeF(mousePos.z)
                    -- SendPacket(newPacket)
                    newPacket:Send()
                    p:Block()
                end
            end
        end
    end
end
function Spell:__eq(other)
    return other and other._spellNum and other._spellNum == self._spellNum or false
end
--}
