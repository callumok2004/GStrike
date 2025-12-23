NETWORK = NETWORK or {}
NETWORK.Variables = NETWORK.Variables or {}
NETWORK.ReadFuncs = NETWORK.ReadFuncs or {}
NETWORK.WriteFuncs = NETWORK.WriteFuncs or {}
NETWORK.NetworkIds = NETWORK.NetworkIds or {}

if SERVER then
	util.AddNetworkString("GStrike.SetNWVar")
	util.AddNetworkString("GStrike.RequestNWVars")
end

function NETWORK.RegisterType(meta, type, write, read, networkId, forceDefault)
	local SetKey = string.format("GStrikeHasSetNW%s", type)

	if meta[SetKey] then return end
	meta[SetKey] = true

	local SetFunction = string.format("SetNW%s", type)
	local GetFunction = string.format("GetNW%s", type)

	for i = 1, 2 do
		if i == 2 then
			SetFunction = string.format("SetNW2%s", type)
			GetFunction = string.format("GetNW2%s", type)
		end


		if SERVER then
			meta[SetFunction] = function(self, key, value)
				if not NETWORK.Variables[self:EntIndex()] then
					NETWORK.Variables[self:EntIndex()] = {}
				elseif NETWORK.Variables[self:EntIndex()][key] == value then
					return
				end

				NETWORK.Variables[self:EntIndex()][key] = value

				net.Start("GStrike.SetNWVar")
					net.WriteUInt(self:EntIndex(), 16)
					net.WriteUInt(networkId, 3)
					net.WriteString(key)
					write(value)
				net.Broadcast()
			end

			NETWORK.WriteFuncs[networkId] = write
		end

		meta[GetFunction] = function(self, key, default)
			if not NETWORK.Variables[self:EntIndex()] then
				NETWORK.Variables[self:EntIndex()] = {}
			end

			if NETWORK.Variables[self:EntIndex()][key] == nil then
				return default or forceDefault
			end

			return NETWORK.Variables[self:EntIndex()][key]
		end

		NETWORK.ReadFuncs[networkId] = read
		NETWORK.NetworkIds[string.lower(type)] = networkId
	end
end

if CLIENT then
	net.Receive("GStrike.SetNWVar", function()
		local ent = net.ReadUInt(16)
		local networkId = net.ReadUInt(3)
		local key = net.ReadString()
		local value = NETWORK.ReadFuncs[networkId]()

		if not NETWORK.Variables[ent] then
			NETWORK.Variables[ent] = {}
		end

		NETWORK.Variables[ent][key] = value

		hook.Call("NETWORK.EntityVarChanged", nil, ent, key, value)
	end)
else
	hook.Add("PlayerInitialSpawn", "NETWORK.SyncNWVars", function(ply)
		for ent, vars in pairs(NETWORK.Variables) do
			for key, value in pairs(vars) do
				local type = type(value)
				if type == "number" then type = "int" end
				if type == "boolean" then type = "bool" end
				local networkId = NETWORK.NetworkIds[type]
				if not networkId then continue end
				net.Start("GStrike.SetNWVar")
					net.WriteUInt(ent, 16)
					net.WriteUInt(networkId, 3)
					net.WriteString(key)
					NETWORK.WriteFuncs[networkId](value)
				net.Send(ply)
			end
		end
	end)
end

hook.Add("EntityRemoved", "NETWORK.EntityRemoved", function(ent)
	if NETWORK.Variables[ent:EntIndex()] then NETWORK.Variables[ent:EntIndex()] = nil end
end)

local EntityMeta = FindMetaTable("Entity")
NETWORK.RegisterType(EntityMeta, "Angle", net.WriteAngle, net.ReadAngle, 1, Angle(0, 0, 0))
NETWORK.RegisterType(EntityMeta, "Bool", net.WriteBool, net.ReadBool, 2, false)
NETWORK.RegisterType(EntityMeta, "Entity", net.WriteEntity, net.ReadEntity, 3, Entity(0))
NETWORK.RegisterType(EntityMeta, "Float", net.WriteFloat, net.ReadFloat, 4, 0)
NETWORK.RegisterType(EntityMeta, "Int", function(v) net.WriteInt(v, 32) end, function() return net.ReadInt(32) end, 5, 0)
NETWORK.RegisterType(EntityMeta, "String", net.WriteString, net.ReadString, 6, "")
NETWORK.RegisterType(EntityMeta, "Vector", net.WriteVector, net.ReadVector, 7, Vector(0, 0, 0))
