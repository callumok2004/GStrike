-- Entity Crash Catcher v2
-- This script detects entities that are moving too fast, leading to a potential server crash
-- Original by code_gs, Ambro, DarthTealc, TheEMP, and LuaTenshi; v2 by code_gs

-- Oh look at that, a familiar name is in the credits :O

RunConsoleCommand("sv_crazyphysics_defuse", "1")
RunConsoleCommand("sv_crazyphysics_remove", "1")

local function DebugMessage(bRemove, Entity, vEntityPosition, aEntityRotation, vEntityVelocity, vObjectPosition, aObjectRotation, vObjectVelocity)
	return "\n[GS CrazyPhysics] " .. tostring(Entity)
		.. (bRemove and " removed!" or " frozen!")
		.. "\nEntity position:\t" .. tostring(vEntityPosition)
		.. "\nEntity angle:\t" .. tostring(aEntityRotation)
		.. "\nEntity velocity:\t" .. tostring(vEntityVelocity)
		.. "\nPhysics object position:\t" .. (vObjectPosition == nil and "N/A" or tostring(vObjectPosition))
		.. "\nPhysics object rotation:\t" .. (aObjectRotation == nil and "N/A" or tostring(aObjectRotation))
		.. "\nPhysics object velocity:\t" .. (vObjectVelocity == nil and "N/A" or tostring(vObjectVelocity)) .. "\n"
end

local tEntitiesToCheck = {
	"prop_ragdoll",
	"hl2mp_ragdoll"
}

local tIdentifyEntities = { prop_ragdoll = true }
local ttt_announce_body_found = GetConVar("ttt_announce_body_found")

local iEntityLen = #tEntitiesToCheck

local function SetAbsVelocity(pEntity, vAbsVelocity)
	if (pEntity:GetInternalVariable("m_vecAbsVelocity") ~= vAbsVelocity) then
		pEntity:RemoveEFlags(EFL_DIRTY_ABSVELOCITY)

		local tChildren = pEntity:GetChildren()

		for i = 1, #tChildren do
			tChildren[i]:AddEFlags(EFL_DIRTY_ABSVELOCITY)
		end

		pEntity:SetSaveValue("m_vecAbsVelocity", vAbsVelocity)

		local pMoveParent = pEntity:GetMoveParent()

		if (pMoveParent:IsValid()) then
			pEntity:SetSaveValue("velocity", vAbsVelocity)
		else
			pEntity:SetSaveValue("velocity", vAbsVelocity)
		end
	end
end

local function KillVelocity(pEntity)
	pEntity:CollisionRulesChanged()
	pEntity:SetLocalVelocity(vector_origin)
	pEntity:SetVelocity(vector_origin)
	SetAbsVelocity(pEntity, vector_origin)

	for i = 0, pEntity:GetPhysicsObjectCount() - 1 do
		local pPhysObj = pEntity:GetPhysicsObjectNum(i)
		pPhysObj:EnableMotion(false)
		pPhysObj:SetVelocity(vector_origin)
		pPhysObj:SetVelocityInstantaneous(vector_origin)
		pPhysObj:RecheckCollisionFilter()
		pPhysObj:Sleep()
	end
end

local function IdentifyCorpse(pCorpse)
	if (CORPSE.GetFound(pCorpse, false)) then
		return
	end

	CORPSE.SetFound(pCorpse, true)

	local pPlayer = pCorpse:GetDTEntity(CORPSE.dti.ENT_PLAYER)
	local nRole = ROLE_INNOCENT

	if (pPlayer:IsValid()) then
		pPlayer:setTTTVar("body_found", true)
		pPlayer:setTTTVar("role", pPlayer:GetRole())
		nRole = pCorpse.was_role or pPlayer:GetRole()

		if (nRole == ROLE_TRAITOR) then
			SendConfirmedTraitors(GetInnocentFilter(false))
		end
	else
		local sSteamID = pCorpse.sid

		if (sSteamID ~= nil) then
			local pPlayer = player.GetBySteamID(sSteamID)

			if (pPlayer:IsValid()) then
				pPlayer:setTTTVar("body_found", true)
				pPlayer:setTTTVar("role", pPlayer:GetRole())
				nRole = pCorpse.was_role or pPlayer:GetRole()

				if (nRole == ROLE_TRAITOR) then
					SendConfirmedTraitors(GetInnocentFilter(false))
				end
			end
		end
	end

	if (ttt_announce_body_found:GetBool()) then
		LANG.Msg("body_found", {
			finder = "The Server",
			victim = CORPSE.GetPlayerNick(pCorpse, nil) or pPlayer:GetName(),
			role = LANG.Param(nRole == ROLE_TRAITOR and "body_found_t" or nRole == ROLE_DETECTIVE and "body_found_d" or "body_found_i")
		})
	end

	local tKills = pCorpse.kills

	if (tKills ~= nil) then
		for i = 1, #tKills do
			local pVictim = player.GetBySteamID(tKills[i])

			if (pVictim:IsValid() and not pVictim:getTTTVar("body_found")) then
				pVictim:setTTTVar("body_found", true)

				LANG.Msg("body_confirm", {
					finder = "The Server",
					victim = pVictim:GetName()
				})
			end
		end
	end
end

local function SendMessage(bRemove, bCheckObjectVel, pEntity, vEntityPos, aEntityRot, vEntityVel, vObjectPos, aObjectRot, vObjectVel)
	ServerLog(DebugMessage(bRemove, pEntity, vEntityPos, aEntityRot, vEntityVel, vObjectPos, aObjectRot, vObjectVel))
end

local flNextCheck = 0

hook.Add("Think", "GS_CrazyPhysics", function()
	local flCurTime = CurTime()

	if (flNextCheck > flCurTime) then return end

	flNextCheck = flCurTime + .2

	local flRemoveSpeed = 6000
	flRemoveSpeed = flRemoveSpeed * flRemoveSpeed
	local flDefuseSpeed = 4000
	flDefuseSpeed = flDefuseSpeed * flDefuseSpeed

	for i = 1, iEntityLen do
		local sClass = tEntitiesToCheck[i]
		local tEntities = ents.FindByClass(sClass)

		for i = 1, #tEntities do
			local pEntity = tEntities[i]
			local vEntityVel = pEntity:GetVelocity()
			local flEntityVel = vEntityVel:LengthSqr()
			local pPhysObj = pEntity:GetPhysicsObject()
			local bCheckObjectVel = pPhysObj:IsValid()
			local vObjectVel, flObjectVel

			if (bCheckObjectVel) then
				vObjectVel = pPhysObj:GetVelocity()
				flObjectVel = vObjectVel:LengthSqr()
			end

			if (flEntityVel >= flRemoveSpeed or bCheckObjectVel and flObjectVel >= flRemoveSpeed) then
				KillVelocity(pEntity)
				pEntity:Remove()

				if tIdentifyEntities[sClass] then
					IdentifyCorpse(pEntity)
				end

				local vObjectPos, aObjectRot

				if (bCheckObjectVel) then
					vObjectPos = pPhysObj:GetPos()
					aObjectRot = pPhysObj:GetAngles()
				end

				SendMessage(true, bCheckObjectVel, pEntity, pEntity:GetPos(), pEntity:GetAngles(), vEntityVel, vObjectPos, aObjectRot, vObjectVel)
			elseif (flEntityVel >= flDefuseSpeed or bCheckObjectVel and flObjectVel >= flDefuseSpeed) then
				KillVelocity(pEntity)

				timer.Simple(1, function()
					if (pEntity:IsValid()) then
						pEntity:SetLocalVelocity(vector_origin)
						pEntity:SetVelocity(vector_origin)
						SetAbsVelocity(pEntity, vector_origin)

						for i = 0, pEntity:GetPhysicsObjectCount() - 1 do
							local pPhysObj = pEntity:GetPhysicsObjectNum(i)
							pPhysObj:EnableMotion(true)
							pPhysObj:SetVelocity(vector_origin)
							pPhysObj:SetVelocityInstantaneous(vector_origin)
							pPhysObj:Wake()
							pPhysObj:RecheckCollisionFilter()
						end

						pEntity:CollisionRulesChanged()
					end
				end)

				local vObjectPos, aObjectRot

				if (bCheckObjectVel) then
					vObjectPos = pPhysObj:GetPos()
					aObjectRot = pPhysObj:GetAngles()
				end

				SendMessage(false, bCheckObjectVel, pEntity, pEntity:GetPos(), pEntity:GetAngles(), vEntityVel, vObjectPos, aObjectRot, vObjectVel)
			end
		end
	end
end)

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