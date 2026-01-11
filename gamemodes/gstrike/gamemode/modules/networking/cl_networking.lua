GStrikeVars = GStrikeVars or {}

local pmeta = FindMetaTable("Player")
local get_user_id = pmeta.UserID
function pmeta:getVar(var, default)
	if not IsValid(self) then return nil end
	local vars = GStrikeVars[get_user_id(self)]
	return vars and vars[var] or default or nil
end

local function RetrievePlayerVar(userID, var, value)
	local ply = Player(userID)
	GStrikeVars[userID] = GStrikeVars[userID] or {}

	hook.Call("GStrike.VarChanged", nil, ply, var, GStrikeVars[userID][var], value)
	GStrikeVars[userID][var] = value

	if IsValid(ply) then
		ply.GStrikeVars = GStrikeVars[userID]
	end
end

local function doRetrieve()
	local userID = net.ReadUInt(16)
	local var, value = GStrike.readNetVar()
	RetrievePlayerVar(userID, var, value)
end
net.Receive("GStrike.PlayerVar", doRetrieve)

local function doRetrieveRemoval()
	local userID = net.ReadUInt(16)
	local vars = GStrikeVars[userID] or {}
	local var = GStrike.readNetVarRemoval()
	local ply = Player(userID)

	hook.Call("GStrike.VarChanged", nil, ply, var, vars[var], nil)

	vars[var] = nil
end
net.Receive("GStrike.PlayerVarRemoval", doRetrieveRemoval)

local function InitializeVars(len)
	local plyCount = net.ReadUInt(8)

	for i = 1, plyCount, 1 do
		local userID = net.ReadUInt(16)
		local varCount = net.ReadUInt(GStrike.ID_BITS + 2)

		for j = 1, varCount, 1 do
			local var, value = GStrike.readNetVar()
			RetrievePlayerVar(userID, var, value)
		end
	end
end
net.Receive("GStrike.InitializeVars", InitializeVars)
timer.Simple(0, function() RunConsoleCommand("_sendVars") end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "GStrike.VarDisconnect", function( data )
	GStrikeVars[data.userid] = nil
end)

timer.Create("GStrike.EnsureVars", 5, 0, function()
	RunConsoleCommand("_sendVars")
	timer.Remove("GStrike.EnsureVars")
end)
