local meta = FindMetaTable("Player")

util.AddNetworkString("GStrike.InitializeVars")
util.AddNetworkString("GStrike.PlayerVar")
util.AddNetworkString("GStrike.PlayerVarRemoval")

function meta:removeTTTVar(var, target)
	hook.Call("GStrike.VarChanged", nil, self, var, (self.TTTVars and self.TTTVars[var]) or nil, nil)
	target = target or player.GetAll()
	self.TTTVars = self.TTTVars or {}
	self.TTTVars[var] = nil

	net.Start("GStrike.PlayerVarRemoval")
		net.WriteUInt(self:UserID(), 16)
		GStrike.writeNetTTTVarRemoval(var)
	net.Send(target)
end

function meta:setTTTVar(var, value, target)
	if not IsValid(self) then return end
	self.targettedTTTVars = self.targettedTTTVars or {}

	if target then
		self.targettedTTTVars[var] = true
	else
		self.targettedTTTVars[var] = nil
	end

	target = target or player.GetAll()

	-- MsgC(Color(0, 255, 0), "Setting TTT var ", var, " to ", value, " for ", self, "\n")
	-- MsgC(Color(0, 255, 0), "Targets: ", target, "\n")
	-- for _, ply in pairs(target) do
	-- 	MsgC(Color(0, 255, 0), "  ", ply, "\n")
	-- end

	if value == nil then return self:removeTTTVar(var, target) end
	hook.Call("GStrike.VarChanged", nil, self, var, (self.TTTVars and self.TTTVars[var]) or nil, value)

	self.TTTVars = self.TTTVars or {}
	self.TTTVars[var] = value

	net.Start("GStrike.PlayerVar")
		net.WriteUInt(self:UserID(), 16)
		GStrike.writeNetTTTVar(var, value)
	net.Send(target)
end

function meta:setSelfTTTVar(var, value)
	self.privateTTTVars = self.privateTTTVars or {}
	self.privateTTTVars[var] = true
	self:setTTTVar(var, value, self)
end

function meta:getTTTVar(var, fallback)
	local vars = self.TTTVars
	if vars == nil then return fallback end

	local results = vars[var]
	if results == nil then return fallback end

	return results
end

function meta:sendTTTVars()
	if self:EntIndex() == 0 then return end

	local plys = player.GetAll()

	net.Start("GStrike.InitializeVars")
		net.WriteUInt(#plys, 8)
		for _, target in pairs(plys) do
			net.WriteUInt(target:UserID(), 16)

			local TTTVars = {}
			for var, value in pairs(target.TTTVars or {}) do
				if self ~= target then
					if (target.privateTTTVars or {})[var] then continue end
					if (target.targettedTTTVars or {})[var] then continue end
				end
				table.insert(TTTVars, var)
			end

			net.WriteUInt(#TTTVars, GStrike.TTT_ID_BITS + 2)
			for i = 1, #TTTVars, 1 do
				GStrike.writeNetTTTVar(TTTVars[i], target.TTTVars[TTTVars[i]])
			end
		end
	net.Send(self)
end

concommand.Add("_sendTTTvars", function(ply)
	ply.TTTVars = ply.TTTVars or {}

	if ply.TTTVarsSent and ply.TTTVarsSent > (CurTime() - 3) then return end
	ply.TTTVarsSent = CurTime()
	ply:sendTTTVars()
end)
