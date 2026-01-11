LANGUAGE = LANGUAGE or {}

util.AddNetworkString("LangString")
util.AddNetworkString("LiquidChat")
util.AddNetworkString("PrintMessage")

function LANGUAGE.StringExists(name)
	return LANGUAGE.CurrentLangauge[name] != nil
end

function LANGUAGE.NotifyAll(name, msgtype, ...)
	if not LANGUAGE.StringExists(name) then ErrorNoHalt("Language string does not exist: " .. name) return end
	net.Start("LangString")
		net.WriteUInt(LANGUAGE.CurrentLangauge[name].networkid, LANGUAGE.NetworkBitSize)
		net.WriteUInt(msgtype, 3)
		local args = {...}
		for k,v in pairs(LANGUAGE.CurrentLangauge[name].arguments) do
			v[1](args[k])
		end
	net.Broadcast()
end

function LANGUAGE.Notify(ply, name, msgtype, ...)
	if not LANGUAGE.StringExists(name) then ErrorNoHalt("Language string does not exist: " .. name) return end
	net.Start("LangString")
		net.WriteUInt(LANGUAGE.CurrentLangauge[name].networkid, LANGUAGE.NetworkBitSize)
		net.WriteUInt(msgtype, 3)
		local args = {...}
		for k,v in pairs(LANGUAGE.CurrentLangauge[name].arguments) do
			v[1](args[k])
		end
	net.Send(ply)
end

function LANGUAGE.PrintMessage(ply, name, msgtype, ...)
	if not LANGUAGE.StringExists(name) then ErrorNoHalt("Language string does not exist: " .. name) return end
	net.Start("PrintMessage")
		net.WriteUInt(LANGUAGE.CurrentLangauge[name].networkid, LANGUAGE.NetworkBitSize)
		net.WriteUInt(msgtype, 3)
		local args = {...}
		for k,v in pairs(LANGUAGE.CurrentLangauge[name].arguments) do
			v[1](args[k])
		end
	net.Send(ply)
end

function LANGUAGE.PrintMessageAll(name, msgtype, ...)
	if not LANGUAGE.StringExists(name) then ErrorNoHalt("Language string does not exist: " .. name) return end
	net.Start("PrintMessage")
		net.WriteUInt(LANGUAGE.CurrentLangauge[name].networkid, LANGUAGE.NetworkBitSize)
		net.WriteUInt(msgtype, 3)
		local args = {...}
		for k,v in pairs(LANGUAGE.CurrentLangauge[name].arguments) do
			v[1](args[k])
		end
	net.Broadcast()
end

function LANGUAGE.LiquidChat(ply, name, msgtype, ...)
	if not LANGUAGE.StringExists(name) then ErrorNoHalt("Language string does not exist: " .. name) return end
	net.Start("LiquidChat")
		net.WriteUInt(LANGUAGE.CurrentLangauge[name].networkid, LANGUAGE.NetworkBitSize)
		net.WriteUInt(msgtype[1], LANGUAGE.TypeBitSize)
		local args = {...}
		for k,v in pairs(LANGUAGE.CurrentLangauge[name].arguments) do
			v[1](args[k])
		end
	net.Send(ply)
end

function LANGUAGE.LiquidChatAll(msgtype, name, ...)
	if not LANGUAGE.StringExists(name) then ErrorNoHalt("Language string does not exist: " .. name) return end
	net.Start("LiquidChat")
		net.WriteUInt(LANGUAGE.CurrentLangauge[name].networkid, LANGUAGE.NetworkBitSize)
		net.WriteUInt(msgtype[1], LANGUAGE.TypeBitSize)
		local args = {...}
		for k,v in pairs(LANGUAGE.CurrentLangauge[name].arguments) do
			v[1](args[k])
		end
	net.Broadcast()
end

local PlayerMeta = FindMetaTable("Player")
function PlayerMeta:ChatMessage(msgtype, name, ...)
	LANGUAGE.LiquidChat(self, name, msgtype, ...)
end