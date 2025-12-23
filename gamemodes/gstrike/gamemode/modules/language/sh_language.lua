LANGUAGE = LANGUAGE or {}
LANGUAGE.CurrentLangauge = {}
LANGUAGE.Formats = {}
LANGUAGE.Types = {}

LANGUAGE.NetworkBitSize = 5
LANGUAGE.TypeBitSize = 3

NOTIFY_GENERIC	= 0
NOTIFY_ERROR	= 1
NOTIFY_UNDO		= 2
NOTIFY_HINT		= 3
NOTIFY_CLEANUP	= 4

local NetworkID = 1
function LANGUAGE.AddNewPhrase(name, phrase, ...)
	LANGUAGE.CurrentLangauge[name] = {}

	if CLIENT then LANGUAGE.CurrentLangauge[name].phrase = phrase end

	LANGUAGE.CurrentLangauge[name].arguments = {...}

	if (NetworkID >= 31) then ErrorNoHalt("Language Net Message size needs increasing. More than 31 strings found!") end

	LANGUAGE.CurrentLangauge[name].networkid = NetworkID
	NetworkID = (NetworkID + 1)
end

LANGUAGE.Formats.PlayerName = {function(ply) net.WriteEntity(ply) end, function() local ply = net.ReadEntity() return IsValid(ply) and ply:IsPlayer() and ply:Nick() or "Someone" end}
LANGUAGE.Formats.String = {function(s) net.WriteString(s) end, function() return net.ReadString() end}
LANGUAGE.Formats.Number = {function(a) net.WriteInt(a, 32) end, function() return net.ReadInt(32) end}
LANGUAGE.Formats.DecimalNumber = {function(n) net.WriteFloat(n) end, function() return net.ReadFloat() end}
LANGUAGE.Formats.NiceTime = {function(a) net.WriteUInt(a, 32) end, function() return string.NiceTime(net.ReadUInt(32)) end}

-- ID, Prefix, PrefixColor, TextColor, WhitePrefixBorder, ?Sound, ?SoundForTypes
LANGUAGE.Types.GAME = {1, "GStrike", Color(50,205,50), color_white, true}

if CLIENT then
	function LANGUAGE.DecodeNetworkedString(networkid)
		local name
		for k,v in pairs(LANGUAGE.CurrentLangauge) do
			if (v.networkid == networkid) then name = k break end
		end

		local args = {}

		for k,v in pairs(LANGUAGE.CurrentLangauge[name].arguments) do
			table.insert(args, v[2]())
		end

		local phrase = LANGUAGE.CurrentLangauge[name].phrase
		if isfunction(phrase) then
			return phrase(unpack(args))
		else
			return {string.format(phrase, unpack(args))}
		end
	end

	function LANGUAGE.ReceiveNotify(len)
		local networkid = net.ReadUInt(11)
		local msgtype = net.ReadUInt(3)
		local txt = LANGUAGE.DecodeNetworkedString(networkid)
		GAMEMODE:AddNotify(txt, msgtype, 4)
		surface.PlaySound("buttons/lightswitch2.wav")
		MsgC(Color(51,255,102), "[GStrike-Notice]: ", color_white, txt.."\n")
	end
	net.Receive("LangString", LANGUAGE.ReceiveNotify)

	function LANGUAGE.ReceiveMessage(len)
		local networkid = net.ReadUInt(LANGUAGE.NetworkBitSize)
		local msgtype = net.ReadUInt(3)

		local txt = unpack(LANGUAGE.DecodeNetworkedString(networkid))
		if (msgtype < 4) then
			LocalPlayer():PrintMessage(msgtype, txt)
		elseif msgtype == 4 then
			-- center message
		elseif msgtype == 5 then
			LocalPlayer():ChatPrint(txt)
		elseif msgtype == 6 then
			chat.AddText(Color(227,141,141), txt)
			chat.PlaySound()
		elseif msgtype == 7 then
			chat.AddText(Color(225,50,50), txt)
			chat.PlaySound()
		end
	end
	net.Receive("PrintMessage", LANGUAGE.ReceiveMessage)

	function LANGUAGE.ReceiveLiquidChat(len)
		local networkid = net.ReadUInt(LANGUAGE.NetworkBitSize)
		local msgtype = net.ReadUInt(LANGUAGE.TypeBitSize)

		local typedata
		for k,v in pairs(LANGUAGE.Types) do
			if (v[1] == msgtype) then typedata = v break end
		end

		local txt = LANGUAGE.DecodeNetworkedString(networkid)

		local name
		for k,v in pairs(LANGUAGE.CurrentLangauge) do
			if (v.networkid == networkid) then name = k break end
		end

		chat.AddText(typedata[5] and color_white or typedata[3], "[", typedata[3], typedata[2], typedata[5] and color_white or "", "] ", typedata[4] or color_white, unpack(txt))

		if typedata[6] and (not typedata[7] or table.HasValue(typedata[7], name)) then
			GStrike.PlaySound(typedata[6])
		end

		chat.PlaySound()
	end
	net.Receive("LiquidChat", LANGUAGE.ReceiveLiquidChat)

	function LANGUAGE.ClientsideLiquidChat(networkid, msgtype, ...)
		local txt = LANGUAGE.CurrentLangauge[msgtype].phrase
		txt = string.format(txt, unpack({...}))

		chat.AddText(unpack({networkid[3],"[" .. networkid[2] .. "] ",Color(255,255,255),txt}))
		chat.PlaySound()
	end

	function LANGUAGE.GetPhrase(name, ...)
		return string.format(LANGUAGE.CurrentLangauge[name].phrase, unpack({...}))
	end
end

-- Phrases
