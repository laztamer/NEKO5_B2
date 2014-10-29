--{ CLASS from all class 
local _error = function(str) print("Allclass: "..tostring(str)) end
local _Chat = function(str) Game.Chat.Print(tostring(str)) end	
local _func_GetDistance = function(v1, v2)
	local p1, p2
	if type(v1) == "Vector2" then
		p1 = v1
	elseif type(v1) == "Vector3" then
		p1 = v1:To2D()
	elseif type(v1) == "Unit" then
		p1 = v1.pos:To2D()
	else
		_error("GetDistance p1 not V2 or V3. Got: "..tostring(type(v1)))
		return
	end	
	if type(v2) == "Vector2" then
		p2 = v2
	elseif type(v2) == "Vector3" then
		p2 = v2:To2D()
	elseif type(v2) == "Unit" then
		p2 = v2.pos:To2D()
	else
		p2 = myHero.pos:To2D()
	end
	return p1:DistanceTo(p2)
end
local _func_GetDistanceSqr = function(v1, v2, str)
	if not v1 then 
		if str then 
			print("GetDistanceSqr Error! >> " .. str)
		else
			print("GetDistanceSqr Error! >> ")
		end
		return
	end
	v2 = v2 or player
	return (v1.x - v2.x) ^ 2 + ((v1.z or v1.y) - (v2.z or v2.y)) ^ 2    
end
local _func_ValidTarget = function(Obj, Dist, enemyTeam)
	local enemy = enemyTeam or nil
	return Obj ~= nil and Obj.valid and (enemy == nil or Obj.team == enemy) and Obj.visible and not Obj.dead and (Dist == nil or _func_GetDistanceSqr(Obj) <= Dist * Dist)	
end
local _func_GetDistanceFromMouse = function(Obj)
	local Obj = Obj or myHero
	if Obj and Obj.valid and Obj.networkID then
		return _func_GetDistance(Obj, mousePos)
	end
end
local _func_CreateProtectedTable = function(table)
   return setmetatable({}, {
     __index = table,
     __newindex = function(table, key, value)
                    print("Attempt to modify read-only table")
                  end,
     __metatable = false
   })
end
local _table_EnemyHeroes = nil
local _func_GetEnemyHeroes = function()
	if type(_table_EnemyHeroes) == "table" then return _table_EnemyHeroes end
	local _table_EnemyHeroes = {}
     for i = 1, Game.HeroCount() do
        local hero = Game.Hero(i)
        if hero.team ~= player.team then
            table.insert(_table_EnemyHeroes, hero)
        end
        _func_CreateProtectedTable(_table_EnemyHeroes)
    end
    return _table_EnemyHeroes
end
local _table_AllyHeroes = nil
local _func_GetAllyHeroes = function()
    if type(_table_AllyHeroes) == "table" then return _table_AllyHeroes end
    local _table_AllyHeroes = {}
    for i = 1, Game.HeroCount() do
        local hero = Game.Hero(i)
        if hero.team == player.team and hero.networkID ~= player.networkID then
            table.insert(_table_AllyHeroes, hero)
        end
        _func_CreateProtectedTable(_table_AllyHeroes_TMP)
    end
    return _table_AllyHeroes
end
local _func_GetNextEnemyMinion = function(From, Distance)
	From = From or myHero
	Distance = Distance or 25000
	local Result = {Unit = nil, Distance = 25000}	
	for i = 0,Game.ObjectCount() do	
		local minion = Game.Object(i)
		if minion and (minion.type == "obj_AI_Minion" or minion.type:find("Minion")) and not minion.charName:find("Odin") and minion.valid and minion.visible and not minion.dead and minion.team ~= myHero.team then
			if minion:DistanceTo(From) < Result.Distance then
				Result.Distance = minion:DistanceTo(From)
				Result.Unit = minion
			end
		end
	end	
	return Result.Unit, Result.Distance
end
local _func_GetNextAllyMinion = function(From, Distance)
	From = From or myHero
	Distance = Distance or 25000
	local Result = {Unit = nil, Distance = 25000}	
	for i = 0,Game.ObjectCount() do	
		local minion = Game.Object(i)
		if minion and (minion.type == "obj_AI_Minion" or minion.type:find("Minion")) and not minion.charName:find("Odin") and minion.valid and minion.visible and not minion.dead and minion.team == myHero.team then
			if minion:DistanceTo(From) < Result.Distance then
				Result.Distance = minion:DistanceTo(From)
				Result.Unit = minion
			end
		end
	end	
	return Result.Unit, Result.Distance
end
local _table_delayedActions = {}
local _func_DelayAction = function(func, delay, args)
	local t = Core.GetTickCount() + (delay or 0)
	local t = os.clock(t) + (delay or 0)
	if not _table_delayedActions[t] then
		_table_delayedActions[t] = {}
	end
	table.insert(_table_delayedActions[t], {func = func, args = args})
end
Callback.Bind('Tick', function()
	for t, funcs in pairs(_table_delayedActions) do
		-- if t <= Core.GetTickCount() then
		if t <= os.clock(t) then
			for _, f in ipairs(funcs) do 
				f.func(unpack(f.args or {}))
			end
			_table_delayedActions[t] = nil
		end
	end
end)
local _func_CountEnemyHeroInRange = function(range, object)
    object = object or myHero
    range = range and range * range or myHero.range * myHero.range
    local enemyInRange = 0
    for i = 1, Game.HeroCount(), 1 do
        local hero = Game.Hero(i)
        if _func_ValidTarget(hero) and _func_GetDistanceSqr(object, hero) <= range then
            enemyInRange = enemyInRange + 1
        end
    end
    return enemyInRange
end
local _func_CountAllyHeroInRange = function(range, object)
    object = object or myHero
    range = range and range * range or myHero.range * myHero.range
    local allyInRange = 0
    for i = 1, Game.HeroCount(), 1 do
        local hero = Game.Hero(i)
        if hero.valid and not hero.dead and hero.team == myHero.team and _func_GetDistanceSqr(object, hero) <= range then
            allyInRange = allyInRange + 1
        end
    end
    return allyInRange
end
local _func_ClosestAlly = function(object)
	object = object or myHero
	local distance = 25000
	local closest = nil
	for i = 1, Game.HeroCount(), 1 do
		local ally = Game.Hero(i)
		if ally.charName ~= myHero.charName and ally.team == myHero.team then
			if object:DistanceTo(ally) < distance or closest == nil then
				distance = object:DistanceTo(ally)
				closest = ally
			end
		end
	end
	return closest
end
local _func_ClosestEnemy = function(object)
	object = object or myHero
	local distance = 25000
	local closest = nil
	for i = 1, Game.HeroCount(), 1 do
		local enemy = Game.Hero(i)
		if _func_ValidTarget(enemy) then
			if object:DistanceTo(enemy) < distance or closest == nil then
				distance = object:DistanceTo(enemy)
				closest = enemy
			end
		end
	end
	return closest
end
local _table_MapData = {
	SummonersRift = {
		name = "Summoner's Rift",
		min = { x = -538, y = -165 },
		max = { x = 14279, y = 14527 },
		x = 14817,
		y = 14692,
		grid = { width = 13982 / 2, height = 14446 / 2 },
		player = 10,
		shop = nil,
	},
	TheTwistedTreeline = {
		name = "The Twisted Treeline",
		min = { x = -996, y = -1239 },
		max = { x = 14120, y = 13877 },
		x = 15116,
		y = 15116,
		grid = { width = 15436 / 2, height = 14474 / 2 },
		player = 6,
		shop = nil,
	},
	ProvingGround = {
		name = "The Proving Grounds",
		min = { x = -56, y = -38 },
		max = { x = 12820, y = 12839 },
		x = 12876,
		y = 12877,
		grid = { width = 12948 / 2, height = 12812 / 2 },
		player = 10,
		shop = nil,
	},
	CrystalScar = {
		name = "The Crystal Scar",
		min = { x = -15, y = 0 },
		max = { x = 13911, y = 13703 },
		x = 13926,
		y = 13703,
		grid = { width = 13894 / 2, height = 13218 / 2 },
		player = 10,
		shop = nil,
	},
	TwistedTreelineBeta = {
		name = "The Twisted Treeline Beta",
		min = { x = 0, y = 0 },
		max = { x = 15398, y = 15398 },
		x = 15398,
		y = 15398,
		grid = { width = 15416 / 2, height = 14454 / 2 },
		player = 6,
		shop = nil,
	},
	HowlingAbyss = {
		name = "Howling Abyss",
		min = { x = -56, y = -38 },
		max = { x = 12820, y = 12839 },
		x = 12876,
		y = 12877,
		grid = { width = 13120 / 2, height = 12618 / 2 },
		player = 10,
		shop = nil,
	},
	}	
local _table_CurrentMap = nil
local _func_GetCurrentMap = function()
	if type(_table_CurrentMap) == "table" then return _table_CurrentMap end
	for i = 1, Game.ObjectCount(), 1 do
		local Obj = Game.Object(i)
		if Obj and Obj.valid then
			if math.floor(Obj.x) == -175 and math.floor(Obj.y) == 163 and math.floor(Obj.z) == 1056 then
				_table_MapData.SummonersRift.shop = Obj
				_table_CurrentMap = _func_CreateProtectedTable(_table_MapData.SummonersRift)
				return _table_CurrentMap
			elseif math.floor(Obj.x) == -217 and math.floor(Obj.y) == 276 and math.floor(Obj.z) == 7039 then
				_table_MapData.TheTwistedTreeline.shop = Obj
				_table_CurrentMap = _func_CreateProtectedTable(_table_MapData.TheTwistedTreeline)
				return _table_CurrentMap
			elseif math.floor(Obj.x) == 556 and math.floor(Obj.y) == 191 and math.floor(Obj.z) == 1887 then
				_table_MapData.ProvingGround.shop = Obj
				_table_CurrentMap = _func_CreateProtectedTable(_table_MapData.ProvingGround)
				return _table_CurrentMap		
			elseif math.floor(Obj.x) == 16 and math.floor(Obj.y) == 168 and math.floor(Obj.z) == 4452 then
				_table_MapData.CrystalScar.shop = Obj
				_table_CurrentMap = _func_CreateProtectedTable(_table_MapData.CrystalScar)
				return _table_CurrentMap
			elseif math.floor(Obj.x) == 1313 and math.floor(Obj.y) == 123 and math.floor(Obj.z) == 8005 then
				_table_MapData.TwistedTreelineBeta.shop = Obj
				_table_CurrentMap = _func_CreateProtectedTable(_table_MapData.TwistedTreelineBeta)
				return _table_CurrentMap			
			elseif math.floor(Obj.x) == 497 and math.floor(Obj.y) == -40 and math.floor(Obj.z) == 1932 then
				_table_MapData.HowlingAbyss.shop = Obj
				_table_CurrentMap = _func_CreateProtectedTable(_table_MapData.HowlingAbyss)
				return _table_CurrentMap
			end
		end
	end
end
local _func_GetShop = function()
	if type(_table_CurrentMap) == "table" then
		return _table_CurrentMap.shop
	else		
		return _func_GetCurrentMap().shop
	end
end
local OnGameEndCallback = function(win)
	for k, v in ipairs(Callback.GetCallbacks('OnGameEnd')) do
		v(win)
	end
end
Callback.Bind("CreateObj", function(Obj) 
	if Obj and Obj.valid and Obj.name:lower():find("nexusdestroyedexplosion") then
		OnGameEndCallback(myHero.team ~= Obj.team)
	end
end)
local _table_Item = {}
local _table_InventorySlots = {
	Game.Slots.ITEM_1,
	Game.Slots.ITEM_2,
	Game.Slots.ITEM_3,
	Game.Slots.ITEM_4,
	Game.Slots.ITEM_5,
	Game.Slots.ITEM_6,
	Game.Slots.ITEM_7,
}
_table_Item._func_GetInventorySlot = function(itemID, target)
	assert(type(itemID) == "number", "Item.GetInventorySlot: wrong argument types (<number> expected) got: "..type(itemID))
	local target = target or myHero
	for _, Slot in pairs(_table_InventorySlots) do
		if target:GetInventorySlot(Slot) == itemID then return Slot end
	end
end
_table_Item._func_GetInventoryHaveItem = function(itemID, target)
    assert(type(itemID) == "number", "GetInventoryHaveItem: wrong argument types (<number> expected)")
    local target = target or myHero
    return (_table_Item._func_GetInventorySlot(itemID, target) ~= nil)
end
_table_Item._func_GetInventorySlotIsEmpty = function(Slot, target)
    local target = target or myHero
    return (target:GetInventorySlot(Slot) == 0)
end
_table_Item._func_GetInventoryItemIsCastable = function(itemID, target)
    assert(type(itemID) == "number", "GetInventoryItemIsCastable: wrong argument types (<number> expected)")
    local target = target or myHero
    local slot = _table_Item._func_GetInventorySlot(itemID, target)
    if slot == nil then return false end
    return (target:CanUseSpell(slot) == Game.SpellState.READY)
end
_table_Item._func_CastItem = function(itemID, var1, var2)
    assert(type(itemID) == "number", "CastItem: wrong argument types (<number> expected)")
    local slot = _table_Item.GetInventorySlot(itemID)
	if slot == nil or myHero:CanUseSpell(slot) ~= Game.SpellState.READY then return end
	if type(var1) == "Unit" then
		myHero:CastSpell(slot, var1)
	elseif type(var1) == "Vector2" then
		myHero:CastSpell(slot, var1.x, var1.y)
	elseif type(var1) == "Vector3" then
		myHero:CastSpell(slot, var1.x, var1.z)
	elseif type(var1) == "number" and type(var2) == "number" then
		myHero:CastSpell(slot, var1, var2)
	else
		myHero:CastSpell(slot)
	end
end
local _func_Cast = function(Spell, TO, Packet)
	local SpellID = nil
	local To = { X = nil, Z = nil, NID = nil, Target = nil }
	local Targeted = false
	local Invalid = false
	if Spell == "Q" or Spell == "_Q" or Spell == 0 then
		SpellID = 0
	elseif Spell == "W" or Spell == "_W" or Spell == 1 then
		SpellID = 1	
	elseif Spell == "E" or Spell == "_E" or Spell == 2 then
		SpellID = 2	
	elseif Spell == "R" or Spell == "_R" or Spell == 3 then
		SpellID = 3	
	elseif type(Spell) == 'number' and Spell > 1000 and Spell < 5000 then		
	    local ItemSlots = {Game.Slots.ITEM_1, Game.Slots.ITEM_2, Game.Slots.ITEM_3, Game.Slots.ITEM_4, Game.Slots.ITEM_5, Game.Slots.ITEM_6, Game.Slots.ITEM_7}
        for i, slot in pairs(ItemSlots) do
        	local item = myHero:GetItem(slot)
        	if item and item.id == Spell then
        		SpellID = slot
				packet = false
        	end
        end	
	if SpellID == nil then Invalid = true end
	end
	if type(TO) == 'Unit' then
		To.X = TO.visionPos.x
		To.Z = TO.visionPos.z
		To.NID = TO.networkID
		To.Target = TO
		Targeted = true
	elseif type(TO) == 'Vector3' then
		To.X = TO.x
		To.Z = TO.z
	elseif type(TO) == 'Vector2' then
		To.X = TO.x
		To.Z = TO.y
	else
		To.X = myHero.visionPos.x
		To.Z = myHero.visionPos.z
		To.NID = myHero.networkID
	end
	if not Invalid then
		if Packet ~= false then		
			local p = Network.EnetPacket(0x9A)
			p.channel = 1
			p.flag = 0
			p:Encode4(myHero.networkID)
			p:Encode1(1)
			p:EncodeF(myHero.x)
			p:EncodeF(myHero.y)
			p:EncodeF(To.X)
			p:EncodeF(To.Z)
			if Targeted then
				p:Encode4(To.NID)
			else
				p:Encode4(0)
			end
			p:Hide()
			p:Send()			
		else		
			if Targeted then
				myHero:CastSpell(SpellID, To.Target)
			else
				myHero:CastSpell(SpellID, To.X, To.Z)
			end	
		end		
	else
		--print("Allclass.Cast: Invalid Input.")		
	end
end
local _table_Packet = {}
_table_Packet._func_DumpPacketData = function(p,s,e)
    s, e = math.max(1,s or 1), math.min(p.size-1,e and e-1 or p.size-1)
    local pos, data = p.pos, ""
    p.pos = s
    for i=p.pos, e do
        data = data .. string.format("%02X ",p:Decode1())
    end
    p.pos = pos
    return data
end
_table_Packet._func_DumpPacket = function(p, Path)
    local packet = {}
    packet.time = Core.GetTickCount()
    packet.dwArg1 = p.dwArg1
    packet.dwArg2 = p.dwArg2
    packet.header = string.format("%02X",p.header)
    packet.data = _table_Packet._func_DumpPacketData(p)
	if Path and type(Path) == "string" then
		SaveTo("----------", Path)
		saveTo("Header: "..packet.header, Path)
		saveTo("HEX: "..packet.data, Path)
		saveTo("", Path)
	end
    return packet
end
local _func_SaveTo = function(text, Path)
	local p = Path or "PacketDump.txt"
		local file = io.open(p, "a")
		file:write(tostring(text))
		file:write("\n")
		file:flush()
		file:close()
end
local _func_StringToHex = function(str, spacer)
	return (
		string.gsub(str,"(.)",
			function (c)
				return string.format("%02X%s",string.byte(c), spacer or " ")
			end)
		)
end
local _func_NumberToHex = function(num, spacer)
	local hexstr = '0123456789abcdef'
	local s = ''
	local step = 1
	while num > 0 do
		local mod = math.fmod(num, 16)
		step = step + 1
		if step == 2 then
			step = 0
			s = (spacer or " ")..s
		end
		s = string.sub(hexstr, mod+1, mod+1) .. s
		num = math.floor(num / 16)
		end
	if s == '' then s = '0' end
	return s
end
local _func_SavePacket = function(p, Path)
	if not Path or type(Path) ~= "string" then return end
	local save = function(text)	_func_saveTo(tostring(text), Path) end
	local Dump = function(p)
		local data = ""
		p.pos = 1
		for i = 1, p.size do
			data = data..string.format("%02X ",p:Decode1())
		end
		return data
	end	
	local ost = function() return tostring(os.date("%H:%M:%S")) end	
	local DataString	
	save("-- "..string.format("%02X ",p.header).." -------------------------------")
	save("HeaderHEX: "..string.format("%02X ",p.header))
	save("HeaderDEC: "..p.header)
	save("Size: "..p.size)
	save("Info: "..tostring(p:Decode1()))
	save("myHeroNID: "..myHero.networkID)
	save("pos.x: "..tostring(myHero.x))
	save("pos.y: "..tostring(myHero.y))
	save("pos.z: "..tostring(myHero.z))
	save("HexDump: "..Dump(p))
	for i = 1, p.size do
		p.pos = i
		local unk1 = p:Decode1()
		p.pos = i
		local unk2 = p:Decode2()
		p.pos = i
		local unk4 = p:Decode4()
		p.pos = i
		local unkF = p:DecodeF()
		local FoundSmth = false
		DataString = ost().." -Pos: "..i.." |Decode1: "..unk1.." |Decode2: "..unk2.." |Decode4: "..unk4.." |DecodeF: "..unkF	
		save(DataString)
	end	
	save(" ")
	save(" ")
end
local _func_ReadFile = function(Path)
	assert(type(Path) == "string", "ReadFile: wrong argument types (<string> expected for Path)")
	local file = io.open(Path, "r")
	if not file then
		file = io.open(path .. Path, "r")			
		if not file then return end		
	end
	local text = file:read("*all")
	file:close()
	return text
end
local _func_ReadIni = function(Path)
	local raw = _func_ReadFile(Path)
	--print(raw)
	if not raw then return {} end
	local t, section = {}, nil
	for _, s in ipairs(raw:split("\n")) do
		local v = s:trim()
		local commentBegin = v:find(";") or v:find("#")
		if commentBegin then v = v:sub(1, commentBegin) end
		if v:sub(1, 3) == "tr " then v = v:sub(4, #v) end --ignore
		if v:sub(1, 1) == "[" and v:sub(#v, #v) == "]" then --Section
			section = v:sub(2, #v - 1):trim()
			t[section] = {}
		elseif section and v:find("=") then --Key = Value
		print(v)
			local kv = v:split("=") -- fixed split
			if #kv == 2 then
				local key, value = kv[1]:trim(), kv[2]:trim()
				if value:lower() == "true" then value = true
				elseif value:lower() == "false" then value = false
				elseif tonumber(value) then value = tonumber(value)
				elseif (value:sub(1, 1) == "\"" and value:sub(#value, #value) == "\"") or
				(value:sub(1, 1) == "'" and value:sub(#value, #value) == "'") then
					value = value:sub(2, #value - 1):trim()
				end
				if key ~= "" and value ~= "" then
					if section then t[section][key] = value else t[key] = value end
				end
			end
		end
end
return t	
end
local _table_GameCFG = {
		loaded = false,
		window = { x = nil, y = nil },
		minimap = {
			ratio = 1,
			flip = false, --false = minimap right side
		}
	}
local GetGameCFG = function() --GetGameSettings()
	local RADSPATH = Game.Path()
	return ReadIni(RADSPATH:sub(1, RADSPATH:find("\\RADS")) .. "Config\\game.cfg")
end
local _table_MiniMap, _boolean_MiniMapGathered = {}, false
local _func_GetMinimapData = function()
if _boolean_MiniMapGathered then return _table_MiniMap end
	local minimapRatio, minimapFlip, windowWidth, windowHeight = 1, false, WINDOW_W, WINDOW_H
	local gameSettings = GetGameCFG()--GetGameSettings()	
	if gameSettings and gameSettings.General and gameSettings.General.Width and gameSettings.General.Height then
		windowWidth, windowHeight = gameSettings.General.Width, gameSettings.General.Height
		local HudPath = path .. "DATA\\menu\\hud\\hud" .. windowWidth .. "x" .. windowHeight .. ".ini"
		local hudSettings = ReadIni(HudPath)
		if hudSettings and hudSettings.Globals and hudSettings.Globals.MinimapScale then
			minimapRatio = (windowHeight / 1080) * hudSettings.Globals.MinimapScale
		else
			minimapRatio = (windowHeight / 1080)
		end	
		minimapFlip = (gameSettings.HUD and gameSettings.HUD.FlipMiniMap and gameSettings.HUD.FlipMiniMap == 1)
	end
	local map = _func_GetCurrentMap()
	_table_MiniMap.step = { x = 265 * minimapRatio / map.x, y = -264 * minimapRatio / map.y }
	if minimapFlip then
		_table_MiniMap.x = 5 * minimapRatio - _table_MiniMap.step.x * map.min.x
	else
		_table_MiniMap.x = windowWidth - 270 * minimapRatio - _table_MiniMap.step.x * map.min.x
	end
	  _table_MiniMap.y = windowHeight - 8 * minimapRatio - _table_MiniMap.step.y * map.min.y -- added this line
	_boolean_MiniMapGathered = true
	return _table_MiniMap
end
local _func_GetMinimapPos = function(v1, v2)
	local x, y
	local GetX = function(n) return ( _table_MiniMap.x + _table_MiniMap.step.x * n)	end
	local GetY = function(n) return ( _table_MiniMap.y + _table_MiniMap.step.y * n)	end	
	if type(v1) == "Unit" then
		x = v1.pos.x
		y = v1.pos.z
	elseif type(v1) == "Vector3" then
		x = v1.x
		y = v1.z
	elseif type(v1) == "Vector2" then
		x = v1.x
		y = v1.y
	elseif type(v1) == "number" and type(v2) == "number" then
		x = v1
		y = v2		
	end
	if x and y then
		return Geometry.Vector2(GetX(x),GetY(y))
	end
end
local _table_Colors = {
		["aliceblue"]            = {240, 248, 255, 255},
		["antiquewhite"]         = {250, 235, 215, 255},
		["aqua"]                 = { 0, 255, 255, 255},
		["aquamarine"]           = {127, 255, 212, 255},
		["azure"]                = {240, 255, 255, 255},
		["beige"]                = {245, 245, 220, 255},
		["bisque"]               = {255, 228, 196, 255},
		["black"]                = { 0, 0, 0, 0},
		["blanchedalmond"]       = {255, 235, 205, 255},
		["blue"]                 = { 0, 0, 255, 255},
		["blueviolet"]           = {138, 43, 226, 255},
		["brown"]                = {165, 42, 42, 255},
		["burlywood"]            = {222, 184, 135, 255},
		["cadetblue"]            = { 95, 158, 160, 255},
		["chartreuse"]           = {127, 255, 0, 255},
		["chocolate"]            = {210, 105, 30, 255},
		["coral"]                = {255, 127, 80, 255},
		["cornflowerblue"]       = {100, 149, 237, 255},
		["cornsilk"]             = {255, 248, 220, 255},
		["crimson"]              = {220, 20, 60, 255},
		["cyan"]                 = { 0, 255, 255, 255},
		["darkblue"]             = { 0, 0, 139, 255},
		["darkcyan"]             = { 0, 139, 139, 255},
		["darkgoldenrod"]        = {184, 134, 11, 255},
		["darkgray"]             = {169, 169, 169, 255},
		["darkgreen"]            = { 0, 100, 0, 255},
		["darkgrey"]             = {169, 169, 169, 255},
		["darkkhaki"]            = {189, 183, 107, 255},
		["darkmagenta"]          = {139, 0, 139, 255},
		["darkolivegreen"]       = { 85, 107, 47, 255},
		["darkorange"]           = {255, 140, 0, 255},
		["darkorchid"]           = {153, 50, 204, 255},
		["darkred"]              = {139, 0, 0, 255},
		["darksalmon"]           = {233, 150, 122, 255},
		["darkseagreen"]         = {143, 188, 143, 255},
		["darkslateblue"]        = { 72, 61, 139, 255},
		["darkslategray"]        = { 47, 79, 79, 255},
		["darkslategrey"]        = { 47, 79, 79, 255},
		["darkturquoise"]        = { 0, 206, 209, 255},
		["darkviolet"]           = {148, 0, 211, 255},
		["deeppink"]             = {255, 20, 147, 255},
		["deepskyblue"]          = { 0, 191, 255, 255},
		["dimgray"]              = {105, 105, 105, 255},
		["dimgrey"]              = {105, 105, 105, 255},
		["dodgerblue"]           = { 30, 144, 255, 255},
		["firebrick"]            = {178, 34, 34, 255},
		["floralwhite"]          = {255, 250, 240, 255},
		["forestgreen"]          = { 34, 139, 34, 255},
		["fuchsia"]              = {255, 0, 255, 255},
		["gainsboro"]            = {220, 220, 220, 255},
		["ghostwhite"]           = {248, 248, 255, 255},
		["gold"]                 = {255, 215, 0, 255},
		["goldenrod"]            = {218, 165, 32, 255},
		["gray"]                 = {128, 128, 128, 255},
		["grey"]                 = {128, 128, 128, 255},
		["green"]                = { 0, 128, 0, 255},
		["greenyellow"]          = {173, 255, 47, 255},
		["honeydew"]             = {240, 255, 240, 255},
		["hotpink"]              = {255, 105, 180, 255},
		["indianred"]            = {205, 92, 92, 255},
		["indigo"]               = { 75, 0, 130, 255},
		["ivory"]                = {255, 255, 240, 255},
		["khaki"]                = {240, 230, 140, 255},
		["lavender"]             = {230, 230, 250, 255},
		["lavenderblush"]        = {255, 240, 245, 255},
		["lawngreen"]            = {124, 252, 0, 255},
		["lemonchiffon"]         = {255, 250, 205, 255},
		["lightblue"]            = {173, 216, 230, 255},
		["lightcoral"]           = {240, 128, 128, 255},
		["lightcyan"]            = {224, 255, 255, 255},
		["lightgoldenrodyellow"] = {250, 250, 210, 255},
		["lightgray"]            = {211, 211, 211, 255},
		["lightgreen"]           = {144, 238, 144, 255},
		["lightgrey"]            = {211, 211, 211, 255},
		["lightpink"]            = {255, 182, 193, 255},
		["lightsalmon"]          = {255, 160, 122, 255},
		["lightseagreen"]        = { 32, 178, 170, 255},
		["lightskyblue"]         = {135, 206, 250, 255},
		["lightslategray"]       = {119, 136, 153, 255},
		["lightslategrey"]       = {119, 136, 153, 255},
		["lightsteelblue"]       = {176, 196, 222, 255},
		["lightyellow"]          = {255, 255, 224, 255},
		["lime"]                 = { 0, 255, 0, 255},
		["limegreen"]            = { 50, 205, 50, 255},
		["linen"]                = {250, 240, 230, 255},
		["magenta"]              = {255, 0, 255, 255},
		["maroon"]               = {128, 0, 0, 255},
		["mediumaquamarine"]     = {102, 205, 170, 255},
		["mediumblue"]           = { 0, 0, 205, 255},
		["mediumorchid"]         = {186, 85, 211, 255},
		["mediumpurple"]         = {147, 112, 219, 255},
		["mediumseagreen"]       = { 60, 179, 113, 255},
		["mediumslateblue"]      = {123, 104, 238, 255},
		["mediumspringgreen"]    = { 0, 250, 154, 255},
		["mediumturquoise"]      = { 72, 209, 204, 255},
		["mediumvioletred"]      = {199, 21, 133, 255},
		["midnightblue"]         = { 25, 25, 112, 255},
		["mintcream"]            = {245, 255, 250, 255},
		["mistyrose"]            = {255, 228, 225, 255},
		["moccasin"]             = {255, 228, 181, 255},
		["navajowhite"]          = {255, 222, 173, 255},
		["navy"]                 = { 0, 0, 128, 255},
		["oldlace"]              = {253, 245, 230, 255},
		["olive"]                = {128, 128, 0, 255},
		["olivedrab"]            = {107, 142, 35, 255},
		["orange"]               = {255, 165, 0, 255},
		["orangered"]            = {255, 69, 0, 255},
		["orchid"]               = {218, 112, 214, 255},
		["palegoldenrod"]        = {238, 232, 170, 255},
		["palegreen"]            = {152, 251, 152, 255},
		["paleturquoise"]        = {175, 238, 238, 255},
		["palevioletred"]        = {219, 112, 147, 255},
		["papayawhip"]           = {255, 239, 213, 255},
		["peachpuff"]            = {255, 218, 185, 255},
		["peru"]                 = {205, 133, 63, 255},
		["pink"]                 = {255, 192, 203, 255},
		["plum"]                 = {221, 160, 221, 255},
		["powderblue"]           = {176, 224, 230, 255},
		["purple"]               = {128, 0, 128, 255},
		["red"]                  = {255, 0, 0, 255},
		["rosybrown"]            = {188, 143, 143, 255},
		["royalblue"]            = { 65, 105, 225, 255},
		["saddlebrown"]          = {139, 69, 19, 255},
		["salmon"]               = {250, 128, 114, 255},
		["sandybrown"]           = {244, 164, 96, 255},
		["seagreen"]             = { 46, 139, 87, 255},
		["seashell"]             = {255, 245, 238, 255},
		["sienna"]               = {160, 82, 45, 255},
		["silver"]               = {192, 192, 192, 255},
		["skyblue"]              = {135, 206, 235, 255},
		["slateblue"]            = {106, 90, 205, 255},
		["slategray"]            = {112, 128, 144, 255},
		["slategrey"]            = {112, 128, 144, 255},
		["snow"]                 = {255, 250, 250, 255},
		["springgreen"]          = { 0, 255, 127, 255},
		["steelblue"]            = { 70, 130, 180, 255},        
		["teal"]                 = { 0, 128, 128, 255},
		["thistle"]              = {216, 191, 216, 255},
		["tomato"]               = {255, 99, 71, 255},
		["turquoise"]            = { 64, 224, 208, 255},
		["violet"]               = {238, 130, 238, 255},
		["wheat"]                = {245, 222, 179, 255},
		["white"]                = {255, 255, 255, 255},
		["whitesmoke"]           = {245, 245, 245, 255},
		["yellow"]               = {255, 255, 0, 0},
		["yellowgreen"]          = {154, 205, 50, 255}
	}
local _func_GetColor = function(str)
    assert(type(str) == "string", "GetColor: wrong argument types <str> expected got: "..type(str))
	if _table_Colors[str] ~= nil then		
		return Graphics.RGBA(_table_Colors[str][1],_table_Colors[str][2],_table_Colors[str][3],_table_Colors[str][4])
	end
	return Graphics.RGBA(255,255,255,255)
end
local _func_GetColorTable = function(str)
    assert(type(str) == "string", "GetColorTable: wrong argument types <str> expected got: "..type(str))
	return _table_Colors[str] or {255, 255, 255, 255}
end
-- Easy Draw ---
local _table_ED = {
	ID = 0,
	Circles = {},
	Lines = {},
	Spheres = {},
	Cubes = {},
}
local _boolean_initiated = false
Callback.Bind("GameStart", function() _boolean_initiated = true end)
local _func_RemoveDraw = function(num)
	for i, d in pairs(_table_ED.Circles) do
		if d.id == num then
			table.remove(_table_ED.Circles, i)
			return true
		end
	end
	for i, d in pairs(_table_ED.Lines) do
		if d.id == num then
			table.remove(_table_ED.Lines, i)
			return true
		end
	end
	for i, d in pairs(_table_ED.Spheres) do
		if d.id == num then
			table.remove(_table_ED.Spheres, i)
			return true
		end
	end
	for i, d in pairs(_table_ED.Cubes) do
		if d.id == num then
			table.remove(_table_ED.Cubes, i)
			return true
		end
	end
	return false
end
local _func_AddCircle = function(Position, Range, Color, RemoveOnDeath)
	if type(Position) == "Unit" then
		pos = Position.pos
	elseif type(Position) == "Vector3" then
		pos = Position
	else
		print("AddCircle wrong type for Position. Expected Unit, V3 got: "..type(Position))
		return
	end
	range = Range or 1000
	if type(Color) == "table" and type(Color[1]) == "number" and type(Color[2]) == "number"and type(Color[3]) == "number"and type(Color[4]) == "number" and Color[1] <= 255 and Color[2] <= 255 and Color[3] <= 255 and Color[4] <= 255 then
		color = Graphics.RGBA(Color[1],Color[2],Color[3],Color[4])
	elseif type(Color) == type(Graphics.RGBA(0,0xFF,0,0xFF)) then
		color = Color
	elseif type(Color) == "string" then
		color = _func_GetColor(Color)
	else
		color = Graphics.RGBA(255,255,255,255)
	end
	if type(Position) == "Unit" and RemoveOnDeath then
		rod = RemoveOnDeath
		unit = Position
	else
		rod = false
	end
	_table_ED.ID = _table_ED.ID + 1	
	table.insert(_table_ED.Circles, {pos = Geometry.Vector3(pos.x, pos.y, pos.z), range = range, color = color, rod = rod, unit = unit, id = _table_ED.ID})
	return _table_ED.ID
end
local _func_AddLine = function(PositionA, PositionB, Width, Color, RemoveOnDeath)
	if type(PositionA) == "Unit" then
		pos1 = PositionA.pos
	elseif type(PositionA) == "Vector3" then
		pos1 = PositionA
	else
		print("AddLine wrong type for PositionA. Expected Unit, V3 got: "..type(PositionA))
		return
	end	
	if type(PositionB) == "Unit" then
		pos2 = PositionB.pos
	elseif type(PositionB) == "Vector3" then
		pos2 = PositionB
	else
		print("AddLine wrong type for PositionB. Expected Unit, V3 got: "..type(PositionB))
		return
	end
	width = Width or 1
	if type(Color) == "table" and type(Color[1]) == "number" and type(Color[2]) == "number"and type(Color[3]) == "number"and type(Color[4]) == "number" and Color[1] <= 255 and Color[2] <= 255 and Color[3] <= 255 and Color[4] <= 255 then
		color = Graphics.RGBA(Color[1],Color[2],Color[3],Color[4])
	elseif type(Color) == type(Graphics.RGBA(0,0xFF,0,0xFF)) then
		color = Color
	elseif type(Color) == "string" then
		color = _func_GetColor(Color)
	else
		color = Graphics.RGBA(255,255,255,255)
	end	
	if type(PositionA) == "Unit" and RemoveOnDeath then
		rodA = RemoveOnDeath
		unitA = Position
	else
		rodA = false
	end
	if type(PositionB) == "Unit" and RemoveOnDeath then
		rodB = RemoveOnDeath
		unitB = Position
	else
		rodB = false
	end
	_table_ED.ID = _table_ED.ID + 1	
	table.insert(_table_ED.Lines, {posA = pos1, posB = pos2, rodA = rodA, rodB = rodB, unitA = unitA, unitB = unitB, color = color, width = width, id = _table_ED.ID})
	return _table_ED.ID
end
Callback.Bind('Draw', function()
	if not _boolean_initiated then return end	
	for i, d in pairs(_table_ED.Circles) do
		if d.rod and not d.unit or not d.pos then table.remove(_table_ED.Circles, i) end
		if d.rod and d.unit and d.unit.valid and d.unit.visible then
			Graphics.DrawCircle(d.unit.pos.x, d.unit.pos.y, d.unit.pos.z, d.range, d.color)
		else
			Graphics.DrawCircle(d.pos.x, d.pos.y, d.pos.z, d.range, d.color)
		end		
	end
	for i, d in pairs(_table_ED.Lines) do
		if (d.rodA and not d.unitA.valid) or (d.rodB and not d.unitB.valid) then table.remove(_table_ED.Lines, i) end
		local p1, p2
		if d.rodA and d.unitA.valid and d.unitA.visible then
			p1 = d.unitA.pos
		else
			p1 = d.posA
		end
		if d.rodB and d.unitB.valid and d.unitB.visible then
			p2 = d.unitB.pos
		else
			p2 = d.posB
		end		
		Graphics.DrawLine(Geometry.Vector2(p1.x, p1.y), Geometry.Vector2(p2.x, p2.y), d.width, d.color)		
	end	
end)
-- to be continued..add sphere/cube..later..not so important atm
-- Easy Draw ---
local _func_Attack = function(Unit, Packet)
	Packet = Packet or true
	if Unit.valid and Unit.team ~= myHero.team then
		if Packet then
			local p = Network.EnetPacket(0x72)
			p.channel = 1
			p.flag = 0
			p:Encode4(myHero.networkID)
			p:Encode1(3)
			p:EncodeF(Unit.visionPos.x)
			p:EncodeF(Unit.visionPos.z)
			p:Encode4(Unit.networkID)
			p:Encode4(myHero.networkID)
			p:Hide()			
			p:Send()
		else
			myHero:Attack(Unit)
		end
	end
end
local _func_AttackMove = function(Pos, Packet)
	Packet = Packet or true
	PosX = Pos.x
	PosY = Pos.z or Pos.y
	if PosX and PosY then
		if Packet then
			local p = Network.EnetPacket(0x72)
			p.channel = 1
			p.flag = 0
			p:Encode4(myHero.networkID)
			p:Encode1(7)
			p:EncodeF(PosX)
			p:EncodeF(PosY)
			p:Encode4(0)
			p:Encode4(myHero.networkID)
			p:Hide()			
			p:Send()
		else
			myHero:AttackMove(PosX, PosY)
		end
	end
end
local GetActiveWayPoints = function(Target)
	local WayPoints = {}
	if Target and Target.hasMovePath then
		table.insert(WayPoints, Geometry.Vector3(Target.visionPos.x, Target.visionPos.y, Target.visionPos.z))
		for i = Target.pathIndex, Target.pathCount do
			if Target:GetPath(i) then WayPoints[#WayPoints + 1] = Target:GetPath(i) end
		end
	else
		table.insert(WayPoints, Geometry.Vector3(Target.visionPos.x, Target.visionPos.y, Target.visionPos.z))	
	end	
	return WayPoints
end
--{ -- Alerter Class
-- written by Weee
--[[
    PrintAlert(text, duration, r, g, b, sprite)           - Pushes an alert message (notification) to the middle of the screen. Together with first message it also adds a configuration menu to the scriptConfig.
                text:   Alert text                        - <string>
            duration:   Alert duration (in seconds)       - <number>
                   r:   Red                               - <number>: 0..255
                   g:   Green                             - <number>: 0..255
                   b:   Blue                              - <number>: 0..255
              sprite:   Sprite                            - sprite!
]]
local __mAlerter, __Alerter_OnTick, __Alerter_OnDraw = nil, nil, nil
function PrintAlert(text, duration, r, g, b, sprite)
	if not __mAlerter then __mAlerter = __Alerter() end
	return __mAlerter:Push(text, duration, r, g, b, sprite)
end
class("__Alerter")
function __Alerter_OnTick() 
	if __mAlerter then 
		__mAlerter:OnTick() 
	end 
end
function __Alerter_OnDraw() 
	if __mAlerter then 
		__mAlerter:OnDraw() 
	end 
end
function __Alerter:__init()
	Callback.Bind('Tick', function() __Alerter_OnTick() end)
	Callback.Bind('Draw', function() __Alerter_OnDraw() end)
	
	self.config = MenuConfig("Alerter", "alerterClass")
	self.config:Slider("max", "Max Alerts", 4, 2, 5, 1)
	self.config:Slider("yOffset", "Y Offset", 0.25, 0.1, 0.5, 0.05)
	self.config:Slider("textSize", "Font Size", 20, 12, 30, 1)
	self.config:Slider("textOutline", "Font Outline (May cause FPS drops)", 0, 0, 3, 1)
	self.config:Slider("fadeDuration", "Fade In/Out Duration (Sec)", 1, 0, 3, 1)
	self.config:Slider("fadeOffset", "Fade In/Out X Offset", 50, 20, 200, 1)

	self.yO = -WINDOW_H * self.config.yOffset:Value()
	self.x = WINDOW_W/2
	self.y = WINDOW_H/2 + self.yO
	self._alerts = {}
	self.activeCount = 0
	return self
end
function __Alerter:OnTick()
    self.yO = -WINDOW_H * self.config.yOffset:Value()
    self.x = WINDOW_W/2
    self.y = WINDOW_H/2 + self.yO
    --if #self._alerts == 0 then self:__finalize() end
end
function __Alerter:OnDraw()
    local gameTime = Game.ServerTimer()
    for i, alert in ipairs(self._alerts) do
        self.activeCount = 0
        for j = 1, i do
            local cAlert = self._alerts[j]
            if not cAlert.outro then self.activeCount = self.activeCount + 1 end
        end
        if self.activeCount <= self.config.max:Value() and (not alert.playT or alert.playT + self.config.fadeDuration:Value()*2 + alert.duration > gameTime) then
            alert.playT = not alert.playT and self._alerts[i-1] and (self._alerts[i-1].playT + 0.5 >= gameTime and self._alerts[i-1].playT + 0.5 or gameTime) or alert.playT or gameTime
            local intro = alert.playT + self.config.fadeDuration:Value() > gameTime
            alert.outro = alert.playT + self.config.fadeDuration:Value() + alert.duration <= gameTime
            alert.step = alert.outro and math.min(1, (gameTime - alert.playT - self.config.fadeDuration:Value() - alert.duration) / self.config.fadeDuration:Value())
                    or gameTime >= alert.playT and math.min(1, (gameTime - alert.playT) / self.config.fadeDuration:Value())
                    or 0
            local xO = alert.outro and self:Easing(alert.step, 0, self.config.fadeOffset:Value()) or self:Easing(alert.step, -self.config.fadeOffset:Value(), self.config.fadeOffset:Value())
            local alpha = alert.outro and self:Easing(alert.step, 255, -255) or self:Easing(alert.step, 0, 255)
            local yOffsetTar = Render.Text(alert.text, self.config.textSize:Value()):GetTextArea().y * 1.2 * (self.activeCount-1)
            alert.yOffset = intro and alert.step == 0 and yOffsetTar
                    or #self._alerts > 1 and not alert.outro and (alert.yOffset < yOffsetTar and math.min(yOffsetTar, alert.yOffset + 0.5) or alert.yOffset > yOffsetTar and math.max(yOffsetTar, alert.yOffset - 0.5))
                    or alert.yOffset
            local x = self.x + xO
            local y = self.y - alert.yOffset
            -- outline:
            local o = self.config.textOutline:Value()
            if o > 0 then
                for j = -o, o do
                    for k = -o, o do
                        DrawTextA(alert.text, self.config.textSize:Value(), math.floor(x+j), math.floor(y+k), Graphics.ARGB(alpha, 0, 0, 0), "center", "center")
                    end
                end
            end
            -- sprite:
            if alert.sprite then
                alert.sprite:SetScale(alert.spriteScale, alert.spriteScale)
                alert.sprite:Draw(math.floor(x - Render.Text(alert.text, self.config.textSize:Value()):GetTextArea().x/2 - alert.sprite.width * alert.spriteScale * 1.5), math.floor(y - alert.sprite.width * alert.spriteScale / 2), alpha)
            end
            -- text:
            DrawTextA(alert.text, self.config.textSize:Value(), math.floor(x), math.floor(y), Graphics.ARGB(alpha, alert.r, alert.g, alert.b), "center", "center")
        elseif alert.playT and alert.playT + self.config.fadeDuration:Value()*2 + alert.duration <= gameTime then
            table.remove(self._alerts, i)
        end
    end
end
function __Alerter:Push(text, duration, r, g, b, sprite)
    local alert = {}
    alert.text = text
    alert.sprite = sprite
    alert.spriteScale = sprite and self.config.textSize:Value() / sprite.height
    alert.duration = duration or 1
    alert.r = r
    alert.g = g
    alert.b = b

    alert.parent = self
    alert.yOffset = 0

    alert.reset = function(duration)
        alert.playT = Game.ServerTimer() - self.config.fadeDuration:Value()
        alert.duration = duration or 0
        alert.yOffset = Render.Text(alert.text, self.config.textSize:Value()):GetTextArea().y * (self.activeCount-1)
    end
    self._alerts[#self._alerts+1] = alert
    return alert
end
function __Alerter:Easing(step, sPos, tPos)
    step = step - 1
    return tPos * (step ^ 3 + 1) + sPos
end
function __Alerter:__finalize()
    __Alerter_OnTick = nil
    __Alerter_OnDraw = nil
    __mAlerter = nil
end 
function DrawTextA(text, size, x, y, color, halign, valign)
	--local textArea = Geometry.Vector2:GetTextArea(tostring(text) or "", size or 12)
	local textArea = Render.Text(tostring(text) or "", size or 12):GetTextArea()
	halign, valign = halign and halign:lower() 	or "left", valign and valign:lower() or "top"
	x = (halign == "right" 	and x - textArea.x) or (halign == "center" and x - textArea.x*0.5) or x or 0
	y = (valign == "bottom" and y - textArea.y) or (valign == "center" and y - textArea.y*0.5) or y or 0	
	Graphics.DrawText(tostring(text) or "", size or 12, math.floor(x), math.floor(y), color or 4294967295)
end

--}
--}
--{ namespace 'Allclass'
	_G.GetDistance = function(v1, v2) return _func_GetDistance(v1, v2) end -- WORKING
	_G.GetDistanceSqr = function(v1, v2, str) return _func_GetDistanceSqr(v1, v2, str) end -- FIXED
	_G.ValidTarget = function(Obj, Dist, enemyTeam) return _func_ValidTarget(Obj, Dist, enemyTeam) end -- FIXED
	_G.GetDistanceFromMouse = function(Obj) return _func_GetDistanceFromMouse(Obj) end -- WORKING
	_G.CreateProtectedTable = function(table) return _func_CreateProtectedTable(table) end -- WORKING
	_G.GetEnemyHeroes = function() return _func_GetEnemyHeroes() end -- FIXED
	_G.GetAllyHeroes = function() return _func_GetAllyHeroes() end -- FIXED
	_G.GetNextEnemyMinion = function(From, Distance)return _func_GetNextEnemyMinion(From, Distance) end
	_G.GetNextAllyMinion = function(From, Distance) return _func_GetNextAllyMinion(From, Distance) end
	_G.DelayAction = function(func, delay, args) _func_DelayAction(func, delay, args) end	
	_G.CountEnemyHeroInRange = function(range, object) return _func_CountEnemyHeroInRange(range, object) end -- FIXED
	_G.CountAllyHeroInRange = function(range, object) return _func_CountAllyHeroInRange(range, object) end -- FIXED
	_G.ClosestAlly = function(object) return _func_ClosestAlly(object) end -- NEW
	_G.ClosestEnemy = function(object) return _func_ClosestAlly(object) end -- NEW
	_G.GetCurrentMap = function() return _func_GetCurrentMap() end -- WORKING
	_G.GetShop = function() return _func_GetShop() end
	--"OnGameEnd" arg1 = win boolean
	_G.GetInventorySlot = function(itemID, target) return _table_Item._func_GetInventorySlot(itemID, target) end
	_G.GetInventoryHaveItem = function(itemID, target) return _table_Item._func_GetInventoryHaveItem(itemID, target) end
	_G.GetInventorySlotIsEmpty = function(Slot, target) return _table_Item._func_GetInventorySlotIsEmpty(Slot, target) end
	_G.GetInventoryItemIsCastable = function(itemID, target) return _table_Item._func_GetInventoryItemIsCastable(itemID, target) end
	_G.CastItem = function(itemID, var1, var2) return _table_Item._func_CastItem(itemID, var1, var2) end
	_G.Cast = function(Spell, TO, Packet) _func_Cast(Spell, TO, Packet) end
	_G.DumpPacketData = function(p, s, e) return _table_Item._func_DumpPacketData(p, s, e) end
	_G.DumpPacket = function(p, Path) return _table_Item._func_DumpPacket(p, Path) end
	_G.SaveTo = function(text, Path) return _func_SaveTo(text, Path) end
	_G.StringToHex = function(str, spacer) return _func_StringToHex(str, spacer) end
	_G.NumberToHex = function(num, spacer) return _func_NumberToHex(num, spacer) end
	_G.SavePacket = function(p, Path) return _func_SavePacket(p, Path) end
	_G.ReadFile = function(Path) return _func_ReadFile(Path) end
	_G.ReadIni = function(Path) return _func_ReadIni(Path) end
	_G.GetGameCFG = function() return GetGameCFG() end
	_G.GetColor = function(str) return _func_GetColor(str) end
	_G.GetColorTable = function(str) return _func_GetColorTable(str) end
	_G.GetMinimapData = function() return _func_GetMinimapData() end
	_G.GetMinimapPos = function(v1, v2) return _func_GetMinimapPos(v1, v2) end
	_G.RemoveDraw = function(num) return _func_RemoveDraw(num) end
	_G.AddCircle = function(p, r, c, d) return _func_AddCircle(p, r, c, d) end
	_G.AddLine = function(a, b, c, d, e) return  _func_AddLine(a, b, c, d, e) end
	_G.Attack = function(u, p) _func_Attack(u, p) end
	_G.AttackMove = function(po, p) _func_AttackMove(po, p) end
	_G.GetActiveWayPoints = function(t) return GetActiveWayPoints(t) end
	_G.HeroCanMove = function() return _func_HeroCanMove() end -- WORKING
	_G.TimeToShoot = function() return _func_TimeToShoot() end -- WORKING
	_G.Orbwalk = function(u) _func_Orbwalking(u) end -- FIXED 
	_G.CLoLPacket = Game.CLoLPacket
	_G.SendPacket = function(p) p:Send(p) end
	-- _G.Game.CLoLPacket.getRemaining = function(self) return self:GetRemaining() end
--}
