require "love.system"
require "love.timer"

local script_path = debug.getinfo(1, "S").source:sub(2)
local script_dir = script_path:match("(.*/)")

package.path = script_dir .. "?.lua;" .. package.path
package.cpath = script_dir .. "?.so;" .. package.cpath
local index_os = love.system.getOS()

if index_os == 'OS X' then
	https = require("macos-https")
elseif index_os == 'Linux' then
	https = require("linux-https")
else
	https = require("https")
end

auth = require("auth")
assert(auth)
assert(https)
love.thread.getChannel('send_shock'):pop()

while true do
	if love.thread.getChannel('send_shock'):pop() then
		local code, body = https.request("https://api.openshock.app/2/shockers/control",
			{ method = "post", headers = { ["OpenShockToken"] = tostring(auth['api_key']), ["Content-Type"] = tostring("application/json"), ["accept"] = tostring("application/json") }, data =
			'{"shocks": [{"id": "' ..
			auth['shocker_id'] ..
			'","type": "Vibrate","intensity": 20,"duration": 400,"exclusive": true}],"customName": "Balatro"}' })
		if code ~= 200 then
			love.thread.getChannel('shock_response'):push("HttpsError - " .. code)
		end
	end	
end
