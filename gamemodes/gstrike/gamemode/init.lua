GStrike = GStrike or {}
GStrike.IsTestServer = GStrike.IsTestServer or file.Exists("testserver.txt", "DATA")

include("sv_database.lua")
include("shared.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

local fol = GM.FolderName.."/gamemode/modules/"
local files, folders = file.Find(fol .. "*", "LUA")

for _, folder in SortedPairs(folders,true) do
	local files = file.Find(fol .. folder .."/*.lua", "LUA")
	for _,File in SortedPairs(files,true) do
		if File:StartWith("sh_") then
			AddCSLuaFile(fol..folder .. "/" ..File)
			include(fol.. folder .. "/" ..File)
		end
	end

	for _,File in SortedPairs(files,true) do
		if File:StartWith("sv_") then
			include(fol.. folder .. "/" ..File)
		end

		if File:StartWith("cl_") then
			AddCSLuaFile(fol.. folder .. "/" ..File)
		end
	end
end

function GM:Initialize()
   self:DoLog("Initializing GStrike...", LogSeverity.Debug)
   RunConsoleCommand("mp_friendlyfire", "1")
end

-- Make Ladders Great Again!

local grabdist, grabhdelta = 12, Vector(0, 0, 6)

local function onladder(tab, ply)
	local tr = util.TraceEntityHull(tab, ply)
	tab.mask = bit.bxor(tab.mask, CONTENTS_PLAYERCLIP)
	if bit.band(tr.Contents, CONTENTS_LADDER) != 0 then return true end
	local sd = util.GetSurfaceData(tr.SurfaceProps)
	if IsValid(sd) and sd.climbable != 0 then return true end

	return false
end

hook.Add("PlayerSpawn", "GStrike.LadderFix", function(ply, trans)
	ply.HasWalkMovedSinceLastJump = false
end, HOOK_MONITOR_HIGH)

hook.Add("Move", "GStrike.LadderFix", function(ply, mv)
	if ply:GetMoveType() == MOVETYPE_LADDER and ply:GetInternalVariable("m_vecLadderNormal") == vector_up then
		ply:SetMoveType(MOVETYPE_WALK)
		return
	end

	if ply:GetMoveType() != MOVETYPE_WALK then return end

	local velo = mv:GetVelocity()
	local origin = mv:GetOrigin()
	local wishdir = velo:GetNormalized()
	local trable = {}
	trable.start = origin
	trable.endpos = origin + wishdir
	trable.mask = MASK_PLAYERSOLID
	trable.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
	trable.filter = ply

	local trace = util.TraceEntityHull(trable, ply)
	if trace.Fraction == 1 or !onladder(trable, ply) then
		if ply.HasWalkMovedSinceLastJump and ply:GetGroundEntity() == NULL and velo.z <= 0 and velo.z > -50 and math.abs(velo.x) > 0 and math.abs(velo.y) > 0 then
			trable.start = origin - grabhdelta
			trable.endpos = origin - (wishdir * grabdist)
			trace = util.TraceEntityHull(trable, ply)
			if trace.Fraction != 1 and onladder(trable, ply) and trace.HitNormal.z != 1 then
				ply:SetMoveType(MOVETYPE_LADDER)
				ply:SetSaveValue("m_vecLadderNormal", trace.HitNormal)
				trable.mask = MASK_PLAYERSOLID
				trace = util.TraceEntityHull(trable, ply)
				mv:SetOrigin(trace.HitPos)
			end
		end
	end
end, HOOK_MONITOR_HIGH)

hook.Add("FinishMove", "GStrike.LadderFix", function(ply, mv)
	if ply:GetGroundEntity() != NULL then
		ply.HasWalkMovedSinceLastJump = true
	end

	if bit.band(mv:GetButtons(), IN_JUMP) == IN_JUMP then
		ply.HasWalkMovedSinceLastJump = false
	end
end, HOOK_MONITOR_HIGH)
