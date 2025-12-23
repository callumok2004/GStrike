local maxId = 0
TTTVars = TTTVars or {}
local TTTVarById = {}

local TTT_ID_BITS = 4 -- 2^4 = 16 TTTVars
local UNKNOWN_TTTRPVAR = 16 -- Should be equal to 2^TTT_ID_BITS - 1
GStrike.TTT_ID_BITS = TTT_ID_BITS

function GStrike.registerTTTVar(name, writeFn, readFn)
	maxId = maxId + 1

	if maxId >= UNKNOWN_TTTRPVAR then error(string.format("Too many TTTVar registrations! TTTVar '%s' triggered this error", name), 2) end

	TTTVars[name] = {id = maxId, name = name, writeFn = writeFn, readFn = readFn}
	TTTVarById[maxId] = TTTVars[name]
end

local function writeUnknown(name, value)
	net.WriteUInt(UNKNOWN_TTTRPVAR, 8)
	net.WriteString(name)
	net.WriteType(value)
end

local function readUnknown()
	return net.ReadString(), net.ReadType(net.ReadUInt(8))
end

function GStrike.writeNetTTTVar(name, value)
	local TTTVar = TTTVars[name]
	if not TTTVar then

		return writeUnknown(name, value)
	end

	net.WriteUInt(TTTVar.id, TTT_ID_BITS)
	return TTTVar.writeFn(value)
end

function GStrike.writeNetTTTVarRemoval(name)
	local TTTVar = TTTVars[name]
	if not TTTVar then

		net.WriteUInt(UNKNOWN_TTTRPVAR, 8)
		net.WriteString(name)
		return
	end

	net.WriteUInt(TTTVar.id, TTT_ID_BITS)
end

function GStrike.readNetTTTVar()
	local TTTVarId = net.ReadUInt(TTT_ID_BITS)
	local TTTVar = TTTVarById[TTTVarId]

	if TTTVarId == UNKNOWN_TTTRPVAR then
		local name, value = readUnknown()
		return name, value
	end
	local val = TTTVar.readFn(value)

	return TTTVar.name, val
end

function GStrike.readNetTTTVarRemoval()
	local id = net.ReadUInt(TTT_ID_BITS)
	return id == UNKNOWN_TTTRPVAR and net.ReadString() or TTTVarById[id].name
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
