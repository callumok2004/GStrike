TTTVars = TTTVars or {}

local pmeta = FindMetaTable("Player")
local get_user_id = pmeta.UserID
function pmeta:getTTTVar(var, default)
	if not IsValid(self) then return nil end
	local vars = TTTVars[get_user_id(self)]
	return vars and vars[var] or default or nil
end

local function RetrievePlayerVar(userID, var, value)
	local ply = Player(userID)
	TTTVars[userID] = TTTVars[userID] or {}

	hook.Call("GStrike.VarChanged", nil, ply, var, TTTVars[userID][var], value)
	TTTVars[userID][var] = value

	if IsValid(ply) then
		ply.TTTVars = TTTVars[userID]
	end
end

local function doRetrieve()
	local userID = net.ReadUInt(16)
	local var, value = GStrike.readNetTTTVar()
	RetrievePlayerVar(userID, var, value)
end
net.Receive("GStrike.PlayerVar", doRetrieve)

local function doRetrieveRemoval()
	local userID = net.ReadUInt(16)
	local vars = TTTVars[userID] or {}
	local var = GStrike.readNetTTTVarRemoval()
	local ply = Player(userID)

	hook.Call("GStrike.VarChanged", nil, ply, var, vars[var], nil)

	vars[var] = nil
end
net.Receive("GStrike.PlayerVarRemoval", doRetrieveRemoval)

local function InitializeTTTVars(len)
	local plyCount = net.ReadUInt(8)

	for i = 1, plyCount, 1 do
		local userID = net.ReadUInt(16)
		local varCount = net.ReadUInt(GStrike_ID_BITS + 2)

		for j = 1, varCount, 1 do
			local var, value = GStrike.readNetTTTVar()
			RetrievePlayerVar(userID, var, value)
		end
	end
end
net.Receive("GStrike.InitializeVars", InitializeTTTVars)
timer.Simple(0, function() RunConsoleCommand("_sendTTTVars") end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "GStrike.VarDisconnect", function( data )
	TTTVars[data.userid] = nil
end)

timer.Create("GStrike.EnsureVars", 5, 0, function()
	RunConsoleCommand("_sendTTTVars")
	timer.Remove("GStrike.EnsureVars")
end)
