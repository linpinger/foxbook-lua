#! /usr/bin/lua

-- http://w3.impa.br/~diego/software/luasocket/http.html

function gethtml(inURL, postData, cookie)
	local http = require("socket.http")
--	local ltn12 = require("ltn12")
	local html = {}
	local tbhtml = {}
	tbhtml.url = inURL
	tbhtml.sink = ltn12.sink.table(html)
	local tbhead = { Accept = "*/*", ["User-Agent"]="IE6" }
	if nil ~= cookie then tbhead.Cookie = cookie end
	if nil ~= postData then
		tbhtml.method = 'POST'
		tbhtml.source = ltn12.source.string(postData)
		tbhead["Content-Type"]  = 'application/x-www-form-urlencoded'
		tbhead["Content-Length"] = string.len(postData)
	end
	tbhtml.headers = tbhead
	local b, c, h, s = http.request(tbhtml)
	return table.concat(html), c, h, s
end

-- Wget Cookie 转为HTTP头中Cookie字段
function cookie2Field(iCookie)
	local ostr = ""
	for xx,oo in string.gmatch(iCookie, "\t[0-9]*\t([^\t]*)\t([^\r\n]*)") do
		ostr = ostr .. xx .. '=' .. oo .. '; '
	end
	return ostr
end

