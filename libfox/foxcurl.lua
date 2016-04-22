#! /usr/bin/lua

-- 这个是 Binaries-LuaDist-batteries-0.9.8 自带的，可在win32和linux64上执行

curl = require("luacurl")
-- curl=assert(loadlib("[lib]luacurl[.so|.dll]", "luaopen_luacurl"))()

function gethtml(inURL, postData, cookie)
	local tbhtml = {}
	local c = curl.new()
	c:setopt(curl.OPT_TIMEOUT, 5)
--	c:setopt(curl.OPT_CONNECTTIMEOUT, 3)
--	c:setopt(curl.OPT_DNS_CACHE_TIMEOUT, 3)
--	c:setopt(curl.OPT_HTTPHEADER, "Accept-Encoding: gzip, deflate", "Hello: world")
--	c:setopt(curl.OPT_USERAGENT, "IE8")
--	c:setopt(curl.OPT_REFERER, inURL)
	c:setopt(curl.OPT_ENCODING, "gzip, deflate")
	if nil ~= postData then
		c:setopt(curl.OPT_POST, true)
		c:setopt(curl.OPT_POSTFIELDS, postData)
	end
	if nil ~= cookie then
		c:setopt(curl.OPT_COOKIE, cookie)
--		c:setopt(curl.OPT_COOKIEFILE, cookiePath)
	end

	c:setopt(curl.OPT_URL, inURL)
	c:setopt(curl.OPT_WRITEDATA, tbhtml)
	c:setopt(curl.OPT_WRITEFUNCTION, function(tab, buffer)  --call back函数，必须有
		table.insert(tab, buffer)    --tab参数即为result，参考http://luacurl.luaforge.net/
		return #buffer
	end)
	local ok = c:perform()
	local html = table.concat(tbhtml)
	c:close()
	return html, ok
end

-- Wget Cookie 转为HTTP头中Cookie字段
function cookie2Field(iCookie)
	local ostr = ""
	for xx,oo in string.gmatch(iCookie, "\t[0-9]*\t([^\t]*)\t([^\r\n]*)") do
		ostr = ostr .. xx .. '=' .. oo .. '; '
	end
	return ostr
end

-- Functions
-- print(curl.escape("abcd$%^&*()"))
-- print(curl.unescape("abcd%24%25%5E%26%2A%28%29"));

-- html,ok = gethtml("http://www.fsldk.com/fajlskdj.html")  -- ok=nil
-- html,ok = gethtml("http://www.baidu.com/") -- ok=true

-- html,ok = gethtml("http://www.13xs.com/xs/43/43398/index.html", PostData, "/tmp/wiejfwi")
-- print(html,ok)

--[[
-- 这个版本是在ubuntu上发现的，库名是lua-curl，上面使用的库名是luacurl，两接口不同如下

curl = require("curl")
local c = curl.easy_init()
-- 有些 curl.OPT_* 用不了，需要注意
-- 写入变量 curl.OPT_WRITEDATA 这个不需要
	c:setopt(curl.OPT_WRITEFUNCTION, function(buffer)  --call back函数，必须有
		table.insert(tbhtml, buffer)    --tab参数即为result，参考http://luacurl.luaforge.net/
		return #buffer
	end)
-- c:close() 不需要
--]]
