#! /usr/bin/lua


function gethtmlW(inURL, postData, cookie)
	local tmpName = os.tmpname()
	if nil == string.match(tmpName, '/') then tmpName = "." .. tmpName end -- win下使用当前路径，linux是绝对路径
	local cmd = 'wget -q -U "IE6" -T 5 -t 3 -O "' .. tmpName .. '" "' .. inURL .. '"'
	if nil ~= cookie then cmd = cmd .. ' --header="Cookie: ' .. cookie .. '"' end
	if nil ~= postData then cmd = cmd .. ' --post-data=' .. postData end
	local aa, bb, cc = os.execute(cmd) -- 版本区别 5.1:aa=0 else:cc=0
	require "libfox.foxos"
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

function gethtmlOne(inURL, postData, cookie)
	if nil == string.match(package.path, '/') then
		return gethtmlI(inURL, postData, cookie) -- win 用内置库
	else
		require "libfox.foxos"
		if fileexist('/aaa/') then
			return gethtmlI(inURL, postData, cookie) -- wrt 用内置库
		else
			return gethtmlW(inURL, postData, cookie) -- linux 用wget
		end
	end
end

function gethtml(inURL, postData, cookie)
	local html = ''
	local downTry = 0
	while downTry < 4 do
		html, httpok = gethtmlOne(inURL, postData, cookie)  -- 下载页面
		if nil == html then html = '' end
		if 200 == httpok then
			if string.len(html) > 2048 then
				break
			end
		end
		downTry = downTry + 1
		print("    Download: retry: " .. downTry .. "  len(html): " .. string.len(html))
	end
	return html
end

-- Wget Cookie 转为HTTP头中Cookie字段
function cookie2Field(iCookie)
	local ostr = ""
	for xx,oo in string.gmatch(iCookie, "\t[0-9]*\t([^\t]*)\t([^\r\n]*)") do
		ostr = ostr .. xx .. '=' .. oo .. '; '
	end
	return ostr
end

function html2utf8(html, inURL)
	if nil == inURL then inURL = '' end
	if string.match(inURL, "files%.qidian%.com") then
		require("libfox.utf8gbk")
		html = utf8gbk(html, true)
	elseif string.match(inURL, "%.qidian%.com") then
		return html
	elseif string.match(inURL, "%.xxbiquge%.com") then
		return html
	else -- 判断网页编码并转成utf-8
		if string.match(string.lower(html), '<meta.-charset=([^"]*)[^>]->') ~= "utf-8" then
			require("libfox.utf8gbk")
			html = utf8gbk(html, true)
		end
	end
	return html
end

