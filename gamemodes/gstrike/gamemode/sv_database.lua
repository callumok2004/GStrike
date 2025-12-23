GStrike = GStrike or {}
GStrike.DB = GStrike.DB or {}

if GStrike.DB.Connected then return end

require("mysqloo")

local DBINFO = {
	host = "localhost",
	username = "root",
	pass = "",
	db = "gstrike",
	port = 3306
}

GStrike.DB.Connection = mysqloo.connect(DBINFO.host, DBINFO.username, DBINFO.pass, DBINFO.db, DBINFO.port)

function GStrike.DB.Connection:onConnected()
	GAMEMODE:DoLog("Database connection established!", LogSeverity.Info)
	timer.Simple(0, function() hook.Run("GStrike.DatabaseInitialized") end)
	GStrike.DB.Connected = true
end

function GStrike.DB.Connection:onConnectionFailed(err)
	GAMEMODE:DoLog("Database connection failed! (" .. err .. ")", LogSeverity.Error)
end

function GStrike.DB:Query(qs, callback)
	-- GAMEMODE:DoLog("[DB DEBUG] Running query: " .. qs, LogSeverity.Debug)

	local q = GStrike.DB.Connection:query(qs)

	function q:onSuccess(data)
			if callback and isfunction(callback) then callback(data) end
	end

	function q:onError(err, sql)
		GAMEMODE:DoLog("Database query failed! (" .. err .. ")", LogSeverity.Error)
		GAMEMODE:DoLog("Query: " .. sql, LogSeverity.Error)
	end

	q:start()
end

function GStrike.DB:Escape(qs, wrap)
	if wrap then
		return string.format("'%s'", GStrike.DB.Connection:escape(qs))
	else
		return GStrike.DB.Connection:escape(qs)
	end
end
GStrike.DB.escape = GStrike.DB.Escape

function GStrike.DB:CreateTable(tb, valueColumns, callback, extra)
	local valuesStr = ""
	for k, v in ipairs(valueColumns) do
			valuesStr = string.format("%s%s %s %s%s", valuesStr, (k ~= 1) and "," or "", v.ColName, v.DatType, v.Extra and (string.format(" %s", v.Extra)) or "")
	end

	local qs = string.format("CREATE TABLE IF NOT EXISTS %s(%s%s);", tb, valuesStr, extra and string.format(", %s", extra) or "")
	GStrike.DB:Query(qs, callback)
end

GStrike.DB.Connection:connect()
