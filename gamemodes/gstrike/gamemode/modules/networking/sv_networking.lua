local meta = FindMetaTable("Player")

util.AddNetworkString("GStrike.InitializeVars")
util.AddNetworkString("GStrike.PlayerVar")
util.AddNetworkString("GStrike.PlayerVarRemoval")

function meta:removeVar(var, target)
	hook.Call("GStrike.VarChanged", nil, self, var, (self.GStrikeVars and self.GStrikeVars[var]) or nil, nil)
	target = target or player.GetAll()
	self.GStrikeVars = self.GStrikeVars or {}
	self.GStrikeVars[var] = nil

	net.Start("GStrike.PlayerVarRemoval")
		net.WriteUInt(self:UserID(), 16)
		GStrike.writeNetVarRemoval(var)
	net.Send(target)
end

function meta:setVar(var, value, target)
	if not IsValid(self) then return end
	self.targettedGStrikeVars = self.targettedGStrikeVars or {}

	if target then
		self.targettedGStrikeVars[var] = true
	else
		self.targettedGStrikeVars[var] = nil
	end

	target = target or player.GetAll()

	if value == nil then return self:removeVar(var, target) end
	hook.Call("GStrike.VarChanged", nil, self, var, (self.GStrikeVars and self.GStrikeVars[var]) or nil, value)

	self.GStrikeVars = self.GStrikeVars or {}
	self.GStrikeVars[var] = value

	net.Start("GStrike.PlayerVar")
		net.WriteUInt(self:UserID(), 16)
		GStrike.writeNetVar(var, value)
	net.Send(target)
end

function meta:setSelfVar(var, value)
	self.privateGStrikeVars = self.privateGStrikeVars or {}
	self.privateGStrikeVars[var] = true
	self:setVar(var, value, self)
end

function meta:getVar(var, fallback)
	local vars = self.GStrikeVars
	if vars == nil then return fallback end

	local results = vars[var]
	if results == nil then return fallback end

	return results
end

function meta:sendVars()
	if self:EntIndex() == 0 then return end

	local plys = player.GetAll()

	net.Start("GStrike.InitializeVars")
		net.WriteUInt(#plys, 8)
		for _, target in ipairs(plys) do
			net.WriteUInt(target:UserID(), 16)

			local GStrikeVars = {}
			for var, value in pairs(target.GStrikeVars or {}) do
				if self ~= target then
					if (target.privateGStrikeVars or {})[var] then continue end
					if (target.targettedGStrikeVars or {})[var] then continue end
				end
				table.insert(GStrikeVars, var)
			end

			net.WriteUInt(#GStrikeVars, GStrike.ID_BITS + 2)
			for i = 1, #GStrikeVars, 1 do
				GStrike.writeNetVar(GStrikeVars[i], target.GStrikeVars[GStrikeVars[i]])
			end
		end
	net.Send(self)
end

concommand.Add("_sendGStrikeVars", function(ply)
	if not ply:CheckCooldown("GStrikeVars", 5) then return end
	ply.GStrikeVars = ply.GStrikeVars or {}
	ply.GStrikeVarsSent = CurTime()
	ply:sendVars()
end)
