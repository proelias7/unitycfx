--https://github.com/proelias7/unitycfx  proelias7 by Quantic Store

local resourceName = GetCurrentResourceName()
local SERVER = IsDuplicityVersion()
local CLIENT = not SERVER

local TriggerRemoteEvent = nil
local RegisterLocalEvent = nil
if SERVER then
	TriggerRemoteEvent = TriggerClientEvent
	RegisterLocalEvent = RegisterServerEvent
else
	TriggerRemoteEvent = TriggerServerEvent
	RegisterLocalEvent = RegisterNetEvent
end

local Tunnel = {
    delays = {}
}

local Tools = {}
local IDGenerator = {}

local modules = {}

local Modulos = {
    db = {},
}

function table.maxn(t)
	local max = 0
	for k,v in pairs(t) do
		local n = tonumber(k)
		if n and n > max then max = n end
	end
	return max
end

function module(rsc, path)
	if path == nil then
		path = rsc
		rsc = resourceName
	end

	local key = rsc..path
	local module = modules[key]
	if module then
		return module
	else
		local code = LoadResourceFile(rsc, path..".lua")
		if code then
			local f,err = load(code, rsc.."/"..path..".lua")
			if f then
				local ok, res = xpcall(f, debug.traceback)
				if ok then
					modules[key] = res
					return res
				else
					error("error loading module "..rsc.."/"..path..":"..res)
				end
			else
				error("error parsing module "..rsc.."/"..path..":"..debug.traceback(err))
			end
		else
			error("resource file "..rsc.."/"..path..".lua not found")
		end
	end
end

local function wait(self)
	local rets = Citizen.Await(self.p)
	if not rets then
		rets = self.r
	end
	return table.unpack(rets,1,table.maxn(rets))
end

local function areturn(self, ...)
	self.r = {...}
	self.p:resolve(self.r)
end

function async(func)
	if func then
		Citizen.CreateThreadNow(func)
	else
		return setmetatable({ wait = wait, p = promise.new() }, { __call = areturn })
	end
end

function parseInt(v)
	local n = tonumber(v)
	if n == nil then
		return 0
	else
		return math.floor(n)
	end
end

function parseDouble(v)
	local n = tonumber(v)
	if n == nil then n = 0 end
	return n
end

function parseFloat(v)
	return parseDouble(v)
end

local sanitize_tmp = {}
function sanitizeString(str, strchars, allow_policy)
	local r = ""
	local chars = sanitize_tmp[strchars]
	if chars == nil then
		chars = {}
		local size = string.len(strchars)
		for i=1,size do
			local char = string.sub(strchars,i,i)
			chars[char] = true
		end
		sanitize_tmp[strchars] = chars
	end

	size = string.len(str)
	for i=1,size do
		local char = string.sub(str,i,i)
		if (allow_policy and chars[char]) or (not allow_policy and not chars[char]) then
			r = r..char
		end
	end
	return r
end

function splitString(str, sep)
	if sep == nil then sep = "%s" end

	local t={}
	local i=1

	for str in string.gmatch(str, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end

	return t
end

function joinStrings(list, sep)
	if sep == nil then sep = "" end

	local str = ""
	local count = 0
	local size = #list
	for k,v in pairs(list) do
		count = count+1
		str = str..v
		if count < size then str = str..sep end
	end
	return str
end

function catch(what)
	return what[1]
end
 
function try(what)
	status, result = pcall(what[1])
	if not status then
		what[2](result)
	end
	return result
end

function Tools.newIDGenerator()
	local r = setmetatable({}, { __index = IDGenerator })
	r:construct()
	return r
end

function IDGenerator:construct()
	self:clear()
end

function IDGenerator:clear()
	self.max = 0
	self.ids = {}
end

function IDGenerator:gen()
	if #self.ids > 0 then
		return table.remove(self.ids)
	else
		local r = self.max
		self.max = self.max+1
		return r
	end
end

function IDGenerator:free(id)
	table.insert(self.ids,id)
end

function Tunnel.setDestDelay(dest,delay)
	Tunnel.delays[dest] = { delay,0 }
end

local function tunnel_resolve(itable,key)
	local mtable = getmetatable(itable)
	local iname = mtable.name
	local ids = mtable.tunnel_ids
	local callbacks = mtable.tunnel_callbacks
	local identifier = mtable.identifier
	local fname = key
	local no_wait = false
	if string.sub(key,1,1) == "_" then
		fname = string.sub(key,2)
		no_wait = true
	end
	local fcall = function(...)
		local r = nil
		local profile

		local args = {...}
		local dest = nil
		if SERVER then
			dest = args[1]
			args = {table.unpack(args,2,table.maxn(args))}
			if dest >= 0 and not no_wait then
				r = async()
			end
		elseif not no_wait then
			r = async()
		end

		local delay_data = nil
		if dest then delay_data = Tunnel.delays[dest] end
		if delay_data == nil then
			delay_data = {0,0}
		end

		local add_delay = delay_data[1]
		delay_data[2] = delay_data[2]+add_delay

		if delay_data[2] > 0 then
			SetTimeout(delay_data[2], function()
				delay_data[2] = delay_data[2]-add_delay
				local rid = -1
				if r then
					rid = ids:gen()
					callbacks[rid] = r
				end

				if SERVER then
					TriggerRemoteEvent(iname..":unity_req",dest,fname,args,identifier,rid)
				else
					TriggerRemoteEvent(iname..":unity_req",fname,args,identifier,rid)
				end
			end)
		else
			local rid = -1
			if r then
				rid = ids:gen()
				callbacks[rid] = r
			end

			if SERVER then
				TriggerRemoteEvent(iname..":unity_req",dest,fname,args,identifier,rid)
			else
				TriggerRemoteEvent(iname..":unity_req",fname,args,identifier,rid)
			end
		end

		if r then
			if profile then
				local rets = { r:wait() }
				return table.unpack(rets,1,table.maxn(rets))
			else
				return r:wait()
			end
		end
	end

	itable[key] = fcall
	return fcall
end

function Tunnel.bindInterface(name,interface)
	RegisterLocalEvent(name..":unity_req")
	AddEventHandler(name..":unity_req",function(member,args,identifier,rid)
		local source = source

		local f = interface[member]

		local rets = {}
		if type(f) == "function" then
			rets = { f(table.unpack(args,1,table.maxn(args))) }
		end

		if rid >= 0 then
			if SERVER then
				TriggerRemoteEvent(name..":"..identifier..":unity_res",source,rid,rets)
			else
				TriggerRemoteEvent(name..":"..identifier..":unity_res",rid,rets)
			end
		end
	end)
end

function Tunnel.getInterface(name,identifier)
	if not identifier then identifier = resourceName end

	local ids = Tools.newIDGenerator()
	local callbacks = {}
	local r = setmetatable({},{ __index = tunnel_resolve, name = name, tunnel_ids = ids, tunnel_callbacks = callbacks, identifier = identifier })

	RegisterLocalEvent(name..":"..identifier..":unity_res")
	AddEventHandler(name..":"..identifier..":unity_res",function(rid,args)
		local callback = callbacks[rid]
		if callback then
			ids:free(rid)
			callbacks[rid] = nil
			callback(table.unpack(args,1,table.maxn(args)))
		end
	end)
	return r
end

function import(module)
    if Modulos[module] then
        local status, resp = pcall(Modulos[module]:new())
        if status then
            return resp
        else
            print('unitycfx:: Erro ao executar Modulo:'..module..'.')
            return false
        end
    else
        print('unitycfx:: Modulo:'..module..' não existe.')
        return false
    end
end

function debug(content)
    print(json.encode(content,{indent = true}))
end

Functions = Tunnel.getInterface(resourceName..":unitycfx:functions")
Tunnel.bindInterface(resourceName..":unitycfx:functions",Functions)

lib = Tunnel.getInterface(resourceName..":unitycfx:tunnel")
Tunnel.bindInterface(resourceName..":unitycfx:tunnel",lib)

if CLIENT then
    local object
    
    function Functions.blockPlayer(status)
        if status then StartBlock() end
        LocalPlayer["state"]["unitycfx:blockPlayer"] = status
    end

    function Functions.createObject(dict,anim,prop,flag,hand,xPos,yPos,zPos,xRot,yRot,zRot)
        local ped = PlayerPedId()
    
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(10)
        end
        TaskPlayAnim(ped,dict,anim,3.0,3.0,-1,flag,0,0,0,0)
    
        RequestModel(GetHashKey(prop))
        while not HasModelLoaded(GetHashKey(prop)) do
            Citizen.Wait(10)
        end           
    
        local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,-5.0)
        object = CreateObject(GetHashKey(prop),coords.x,coords.y,coords.z,true,true,true)
        SetEntityCollision(object,false,false)
        if xPos then
            AttachEntityToEntity(object,ped,GetPedBoneIndex(ped,hand),xPos,yPos,zPos,xRot,yRot,zRot,true,true,false,true,1,true)
        else
            AttachEntityToEntity(object,ped,GetPedBoneIndex(ped,hand),0.0,0.0,0.0,0.0,0.0,0.0,true,true,false,true,1,true)
        end
        SetEntityAsMissionEntity(object,true,true)
    end
    
    function Functions.deleteObject()
        ClearPedTasks(PlayerPedId())
        if DoesEntityExist(object) then
            FreezeEntityPosition(object,false)
            DetachEntity(object,false,false)
            PlaceObjectOnGroundProperly(object)
            SetEntityAsNoLongerNeeded(object)
            SetEntityAsMissionEntity(object,true,true)
            DeleteObject(object)
            object = nil
        end
    end
    
    function Functions.playAnim(upper,seq,looping)
        ClearPedTasks(PlayerPedId())
        local flags = 0
        if upper then flags = flags+48 end
        if looping then flags = flags+1 end
    
        if seq.task then
            Functions.stopAnim(true)
    
            local ped = PlayerPedId()
            if seq.task == "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER" then
                local x,y,z = Functions.getPosition()
                TaskStartScenarioAtPosition(ped,seq.task,x,y,z-1,GetEntityHeading(ped),0,0,false)
            else
                TaskStartScenarioInPlace(ped,seq.task,0,not seq.play_exit)
            end
        else
            while not HasAnimDictLoaded(seq.dict) do
                Citizen.Wait(1)
                RequestAnimDict(seq.dict)
            end
            TaskPlayAnim(PlayerPedId(),seq.dict,seq.anim,2.0,2.0,-1,flags,0,0,0,0)
        end
    end

    function Functions.stopAnim(upper)
        if upper then
            ClearPedSecondaryTask(PlayerPedId())
        else
            ClearPedTasks(PlayerPedId())
        end
    end

    function Functions.getPosition()
        local tD = function(n) return math.ceil(n * 100) / 100 end
        local x,y,z = table.unpack(GetEntityCoords(PlayerPedId()))
        return tD(x),tD(y),tD(z)
    end

    function Functions.addBlip(x,y,z,idtype,idcolor,text,scale,route)
        local blip = AddBlipForCoord(x,y,z)
        SetBlipSprite(blip,idtype)
        SetBlipAsShortRange(blip,true)
        SetBlipColour(blip,idcolor)
        SetBlipScale(blip,scale)
        if route then
            SetBlipRoute(blip,true)
        end
        if text then
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(text)
            EndTextCommandSetBlipName(blip)
        end
    end

    function Functions.removeBlip(id)
        RemoveBlip(id)
    end

    function Functions.drawText3D(x,y,z,text,scale)
        local scale = (scale == nil and 0.43 or scale)
        local onScreen,_x,_y = World3dToScreen2d(x,y,z)
        SetTextFont(0)
        SetTextScale(scale,scale)
        SetTextColour(255,255,255,255)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
        local factor = (string.len(text)) / 400
        DrawRect(_x,_y+0.0125,0.01+factor,0.03,255,255,255,0)
    end

    function Functions.teleport(x,y,z)
        local ply = PlayerPedId()
        FreezeEntityPosition(ply, true)
        SetEntityCoords(ply, x + 0.0001, y + 0.0001, z + 0.0001, 1, 0, 0, 1)
        while not HasCollisionLoadedAroundEntity(ply) do
            FreezeEntityPosition(ply, true)
            SetEntityCoords(ply, x + 0.0001, y + 0.0001, z + 0.0001, 1, 0, 0, 1)
            RequestCollisionAtCoord(x, y, z)
            Wait(500)
        end
        SetEntityCoords(ply, x + 0.0001, y + 0.0001, z + 0.0001, 1, 0, 0, 1)
        FreezeEntityPosition(ply, false)
    end

    function Functions.distance(x,y,z,distancia)
        if #(GetEntityCoords(PlayerPedId()) - vector3(x,y,z)) <= distancia then
            return true
        end
        return false
    end

    function Functions.playSound(dict,name)
        PlaySoundFrontend(-1,dict,name,false)
    end

    function Functions.getVehicle(radius)
        local vehicle
        local getNearestVehicles = function(radius)
            local r = {}
            local px,py,pz = table.unpack(GetEntityCoords(PlayerPedId()))
    
            local vehs = {}
            local it,veh = FindFirstVehicle()
            if veh then
                table.insert(vehs,veh)
            end
            local ok
            repeat
                ok,veh = FindNextVehicle(it)
                if ok and veh then
                    table.insert(vehs,veh)
                end
            until not ok
            EndFindVehicle(it)
    
            for _,veh in pairs(vehs) do
                local x,y,z = table.unpack(GetEntityCoords(veh,true))
                local distance = #(GetEntityCoords(veh) - vector3(px,py,pz))
                if distance <= radius then
                    r[veh] = distance
                end
            end
            return r
        end
        
        local vehs = getNearestVehicles(radius)
        local min = radius+0.0001
        for _veh,dist in pairs(vehs) do
            if dist < min then
                min = dist
                vehicle = _veh
            end
        end
        return vehicle
    end

    function StartBlock()
        Citizen.CreateThread(function()
            while true do
                if LocalPlayer["state"]["unitycfxblockPlayer"] then
                    BlockWeaponWheelThisFrame()
                    DisablePlayerFiring(PlayerPedId(), true)
                    FreezeEntityPosition(PlayerPedId(), true)
                    DisableControlAction(0,21,true)
                    DisableControlAction(0,22,true)
                    DisableControlAction(0,23,true)
                    DisableControlAction(0,24,true)
                    DisableControlAction(0,25,true)
                    DisableControlAction(0,29,true)
                    DisableControlAction(0,32,true)
                    DisableControlAction(0,33,true)
                    DisableControlAction(0,34,true)
                    DisableControlAction(0,35,true)
                    DisableControlAction(0,47,true)
                    DisableControlAction(0,56,true)
                    DisableControlAction(0,58,true)
                    DisableControlAction(0,73,true)
                    DisableControlAction(0,75,true)
                    DisableControlAction(0,83,true)
                    DisableControlAction(0,137,true)
                    DisableControlAction(0,140,true)
                    DisableControlAction(0,141,true)
                    DisableControlAction(0,142,true)
                    DisableControlAction(0,143,true)
                    DisableControlAction(0,166,true)
                    DisableControlAction(0,167,true)
                    DisableControlAction(0,168,true)
                    DisableControlAction(0,169,true)
                    DisableControlAction(0,170,true)
                    DisableControlAction(0,177,true)
                    DisableControlAction(0,182,true)
                    DisableControlAction(0,187,true)
                    DisableControlAction(0,188,true)
                    DisableControlAction(0,189,true)
                    DisableControlAction(0,190,true)
                    DisableControlAction(0,243,true)
                    --DisableControlAction(0,245,true)
                    DisableControlAction(0,257,true)
                    DisableControlAction(0,263,true)
                    DisableControlAction(0,264,true)
                    DisableControlAction(0,268,true)
                    DisableControlAction(0,269,true)
                    DisableControlAction(0,270,true)
                    DisableControlAction(0,271,true)
                    DisableControlAction(0,288,true)
                    DisableControlAction(0,289,true)
                    DisableControlAction(0,311,true)
                    DisableControlAction(0,344,true)
                else
                    FreezeEntityPosition(PlayerPedId(), false)
                    break
                end
                Citizen.Wait(1)
            end
        end)
    end
end

if SERVER then
    function Functions.getTools()
        return Tools
    end

    function Functions.getIdentity(source,identity)
        local identifiers = GetPlayerIdentifiers(source)
        for k,v in ipairs(identifiers) do
            if string.find(v,identity) then
                if identity == "discord" then
                    return v:sub(9)
                else
                    return v
                end
            end
        end
        return false
    end
    
    function Functions.log(webhook,message)
        if webhook ~= nil and webhook ~= "" then
            PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({embeds = message}), { ['Content-Type'] = 'application/json' })
        end
    end
    
    function Functions.format(n)
        local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
        return left..(num:reverse():gsub('(%d%d%d)','%1.'):reverse())..right
    end

    function Modulos.db:new()
        local instance = setmetatable({}, { __index = self })

        instance.prepares = {}
        instance.drivedb = nil

        local databases = {'oxmysql', 'ghmattimysql', 'GHMattiMySQL', 'haze_mysql', 'mysql-async'}
        for i, c in ipairs(databases) do
            if GetResourceState(c) == 'started' then
                instance.drivedb = c
            end
        end

        if not instance.drivedb then
            print('unitycfx:: DRIVER DE BANCO DE DADOS INCOMPATÍVEL')
            return 
        end

        instance.prepare = function(self, Name, Query)
            self.prepares[Name] = Query
        end

        instance.query = function(self, Name, d)
            local e = 0
            local f = {}
            local c = (self.prepares[Name] ~= nil and self.prepares[Name] or nil)
            
            if not c then 
                print('unitycfx:: CHAMADA DE FUNÇÃO NÃO PREPARADA => '..Name)
                return
            end
    
            if self.drivedb ~= 'haze_mysql' and self.drivedb ~= 'oxmysql' then
                c = string.gsub(c, "?", function()
                    e = e + 1
                    f['@' .. e] = d[e]
                    return '@' .. e
                end)
            end
    
            local result
            local success
    
            if self.drivedb == 'ghmattimysql' then
                success, result = pcall(exports.ghmattimysql.execute, c, f)
            elseif self.drivedb == 'hydra' then
                result = exports.vrp.query(c, f)
                return result
            elseif self.drivedb == 'oxmysql' then
                local m = GetResourceMetadata('oxmysql', 'version', 0)
                if m and tonumber(m:match("^(%d+)")) >= 2 then
                    success, result = pcall(exports.oxmysql.query_async,"",c, d)
                else
                    result = exports.oxmysql.execute(c, d)
                    return result
                end
            elseif self.drivedb == 'haze_mysql' then
                success, result = pcall(exports.haze_mysql.query, c, d)
            elseif self.drivedb == 'GHMattiMySQL' then
                success, result = pcall(exports.GHMattiMySQL.QueryResultAsync, c, f)
            elseif self.drivedb == 'mysql-async' then
                local n = string.match(c, 'INSERT|REPLACE') and 'mysql_insert' or 'mysql_fetch_all'
                success, result = pcall(exports['mysql-async'][n], c, f)
            end
    
            if success then
                return result
            else
                print('unitycfx:: Erro ao executar "' .. c .. '" com argumentos ' .. json.encode(d))
                return
            end
        end

        return instance
    end
end