GM.Name = "GStrike"
GM.Author = "Callum"
GM.Website = "zarpgaming.com"
GM.Version = "0.0.1"
GM.Customized = true
GM.StartTime = SysTime()

GStrike = GStrike or {}

LogSeverity = {
	["Error"] = 1,
	["Info"] = 2,
	["Debug"] = 3,
	["Warn"] = 4,
   ["Game"] = 99
}

local SeverityColors = {
	[1] = Color(100, 100, 255),
	[2] = Color(150, 150, 220),
	[3] = Color(255, 255, 0)
}

function GM:DoLog(message, level)
	if level == 1 then
		error(message, 0)
	elseif level == 2 then
		MsgC(SeverityColors[1], "[GStrike Info] ")
		MsgN(message)
	elseif level == 3 then
		MsgC(SeverityColors[2], "[GStrike Dbg] ")
		MsgN(message)
	elseif level == 4 then
		MsgC(SeverityColors[3], "[GStrike Warn] ")
		MsgN(message)
   elseif level == 99 then
      MsgC(SeverityColors[1], "[GStrike] ")
      MsgN(message)
   end
end

GM:DoLog(string.format("%soading GStrike - v%s", (GAMEMODE or GM).Loaded and "Rel" or "L", GM.Version), LogSeverity.Info)

TEAM_CT = 1
TEAM_T = 2
TEAM_SPEC = TEAM_SPECTATOR

function GM:CreateTeams()
   team.SetUp(TEAM_CT, "Counter Terrorists", Color(0, 200, 0, 255), false)// todo, get colors
   team.SetUp(TEAM_T, "Terrorists", Color(200, 200, 0, 255), true) // todo, get colors
   team.SetUp(TEAM_SPEC, "Spectators", Color(200, 200, 200, 255), true) // todo, get colors

   team.SetSpawnPoint(TEAM_CT, "info_player_terrorist")
   team.SetSpawnPoint(TEAM_T, "info_player_counterterrorist")
end

function GM:PlayerFootstep(ply, pos, foot, sound, volume, rf)
   if IsValid(ply) and (ply:Crouching() or ply:GetMaxSpeed() < 150 or ply:IsSpec()) then
      return true
   end
end

local meta = FindMetaTable( "Entity" )

if not meta then return end

function meta:SetDamageOwner(ply)
   self.dmg_owner = {ply = ply, t = CurTime()}
end

function meta:GetDamageOwner()
   if self.dmg_owner then
      return self.dmg_owner.ply, self.dmg_owner.t
   end
end

function meta:IsExplosive()
   local kv = self:GetKeyValues()["ExplodeDamage"]
   return self:Health() > 0 and kv and kv > 0
end


GM.Loaded = true

hook.Add("OnReloaded", "GStrike.Reloaded", function()
   local time = SysTime() - (GAMEMODE.StartTime or 0)
   GAMEMODE:DoLog(string.format("Reloaded in %.2f seconds", time), LogSeverity.Info)
end)

hook.Add("PostGamemodeLoaded", "GStrike.Loaded", function()
   local time = SysTime() - (GAMEMODE.StartTime or 0)
   GAMEMODE:DoLog(string.format("Loaded in %.2f seconds", time), LogSeverity.Info)

   if GStrike.IsTestServer then
      timer.Simple(5, function()
         GAMEMODE:DoLog("Gamemode is running as a test server, if this is not intentional, please remove the testserver.txt file in the DATA folder!", LogSeverity.Warn)
      end)
   end
end)

OldErrorNoHalt = OldErrorNoHalt or ErrorNoHalt
function ErrorNoHalt(...)
   OldErrorNoHalt(..., "\n")
end
