#! /usr/bin/lua

function gethtml(inURL, postData, cookie)
	if nil == string.match(package.path, '/') then
		return gethtmlI(inURL, postData, cookie) -- win 用内置库
	else
		require "libfox.foxnovel"
		if fileexist('/aaa/') then
			return gethtmlI(inURL, postData, cookie) -- wrt 用内置库
		else
			return gethtmlW(inURL, postData, cookie) -- linux 用wget
		end
	end
end

function gethtmlW(inURL, postData, cookie)
	local tmpName = os.tmpname()
	if nil == string.match(tmpName, '/') then tmpName = "." .. tmpName end -- win下使用当前路径，linux是绝对路径
	local cmd = 'wget -q -U "IE6" -T 5 -t 3 -O "' .. tmpName .. '" "' .. inURL .. '"'
	if nil ~= cookie then cmd = cmd .. ' --header="Cookie: ' .. cookie .. '"' end
	if nil ~= postData then cmd = cmd .. ' --post-data=' .. postData end
	local aa, bb, cc = os.execute(cmd) -- 版本区别 5.1:aa=0 else:cc=0
	require "libfox.foxnovel"
	local html = fileread(tmpName)
	os.remove(tmpName)
	local code = 0
	if nil == cc then -- =5.1版
		code = aa
	else -- >5.1版
		code = cc
	end

	if 0 == code then
		return html, 200
	else
		return html, 404
	end
end

-- http://w3.impa.br/~diego/software/luasocket/http.html
function gethtmlI(inURL, postData, cookie)
	local http = require("socket.http")
	http.TIMEOUT = 5
--	http.USERAGENT = "IE8"  -- 这个也有效
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

