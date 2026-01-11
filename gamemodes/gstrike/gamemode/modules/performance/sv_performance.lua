local PLAYER = FindMetaTable("Player")
local realPlySteamId = PLAYER.RealSteamID or PLAYER.SteamID
local realPlySteamId64 = PLAYER.RealSteamID64 or PLAYER.SteamID64
SteamIDCache = SteamIDCache or {}

PLAYER.RealSteamID = realPlySteamId
PLAYER.RealSteamID64 = realPlySteamId64

function PLAYER:SteamID()
	local cache = SteamIDCache[self]
	if cache then
		return cache[1]
	else
		return realPlySteamId(self)
	end
end

function PLAYER:SteamID64()
	local cache = SteamIDCache[self]
	if cache then
		return cache[2]
	else
		return realPlySteamId64(self)
	end
end

hook.Add("PlayerInitialSpawn", "CacheSid", function(ply)
	SteamIDCache[ply] = {realPlySteamId(ply), realPlySteamId64(ply)}
end)

hook.Add("PlayerDisconnected", "UncacheSid", function(ply)
	SteamIDCache[ply] = nil
end)