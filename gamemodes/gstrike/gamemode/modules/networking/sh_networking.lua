local maxId = 0
PlayerVars = PlayerVars or {}
local PlayerVarsById = {}

local ID_BITS = 4 -- 2^4 = 16 PlayerVars
local UNKNOWN_VAR = 16 -- Should be equal to 2^ID_BITS - 1
GStrike.ID_BITS = ID_BITS

function GStrike.registerVar(name, writeFn, readFn)
	maxId = maxId + 1

	if maxId >= UNKNOWN_VAR then error(string.format("Too many Var registrations! Var '%s' triggered this error", name), 2) end

	PlayerVars[name] = {id = maxId, name = name, writeFn = writeFn, readFn = readFn}
	PlayerVarsById[maxId] = PlayerVars[name]
end

local function writeUnknown(name, value)
	net.WriteUInt(UNKNOWN_VAR, 8)
	net.WriteString(name)
	net.WriteType(value)
end

local function readUnknown()
	return net.ReadString(), net.ReadType(net.ReadUInt(8))
end

function GStrike.writeNetVar(name, value)
	local Var = PlayerVars[name]
	if not Var then

		return writeUnknown(name, value)
	end

	net.WriteUInt(Var.id, ID_BITS)
	return Var.writeFn(value)
end

function GStrike.writeNetVarRemoval(name)
	local Var = PlayerVars[name]
	if not Var then

		net.WriteUInt(UNKNOWN_VAR, 8)
		net.WriteString(name)
		return
	end

	net.WriteUInt(Var.id, ID_BITS)
end

function GStrike.readNetVar()
	local VarId = net.ReadUInt(ID_BITS)
	local Var = PlayerVarsById[VarId]

	if VarId == UNKNOWN_VAR then
		local name, value = readUnknown()
		return name, value
	end
	local val = Var.readFn(value)

	return Var.name, val
end

function GStrike.readNetVarRemoval()
	local id = net.ReadUInt(ID_BITS)
	return id == UNKNOWN_VAR and net.ReadString() or PlayerVarsById[id].name
end

function net.WriteSteamID(steamid)
	local one, two, three = string.match(steamid, "STEAM_(%d):(%d):(%d+)")
	net.WriteUInt(one, 2)
	net.WriteUInt(two, 2)
	net.WriteUInt(three, 32)
end

function net.ReadSteamID()
	local one = net.ReadUInt(2)
	local two = net.ReadUInt(2)
	local three = net.ReadUInt(32)
	return string.format("STEAM_%d:%d:%d", one, two, three)
end

function net.WriteSteamID64(steamid)
	net.WriteSteamID(util.SteamIDFrom64(steamid))
end

function net.ReadSteamID64()
	return util.SteamIDTo64(net.ReadSteamID())
end
