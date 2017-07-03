#! /usr/bin/lua


function gethtmlW(inURL, postData, cookie)
	local tmpName = os.tmpname()
	if nil == string.find(tmpName, '/', 1, true) then tmpName = "." .. tmpName end -- win下使用当前路径，linux是绝对路径
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
	if nil == string.find(package.path, '/', 1, true) then
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
	if string.find(inURL, "files.qidian.com", 1, true) then
		require("libfox.utf8gbk")
		html = utf8gbk(html, true)
	elseif string.find(inURL, ".qidian.com", 1, true) then
		return html
	elseif string.find(inURL, ".xxbiquge.com", 1, true) then
		return html
	else -- 判断网页编码并转成utf-8
		if string.match(string.lower(html), '<meta.-charset=([^"]*)[^>]->') ~= "utf-8" then
			require("libfox.utf8gbk")
			html = utf8gbk(html, true)
		end
	end
	return html
end

-- 通过TCP模拟http Post单文件实现上传文件到http服务器，依赖:socket,lfs
function postFileTCP(tIP, tPort, postURL, filePath, saveName)
	-- 文件路径及保存名字初始化
	if nil == filePath then
		return nil, 'no file to post'
	else
		if nil == saveName then
			require("libfox.foxos")
			saveName = getFileName(filePath)
		end
	end

	-- 默认POST地址
	if nil == postURL then postURL = '/f' end
	if nil == tPort then tPort = 80 end
	if nil == tIP then tIP = '127.0.0.1' end

	local socket = require("socket")
	local c = socket.tcp()
	if not c then return nil, 'open tcp error' end
	c:settimeout(3)

	local boundary = '----------------------------b03747cc70aa'
	local size = 2^13  -- good buffer size (8K)

	local ret = c:connect(tIP, tPort)
	if not ret then return nil, 'connect tcp error' end

	local lfs = require("lfs")
	local file_attr = lfs.attributes(filePath)
	local fileSize = file_attr.size  --获取文件大小

	-- PostData 预计算大小
	local headPart = '--' .. boundary .. '\r\nContent-Disposition: form-data; name="f"; filename="' .. saveName .. '"\r\nContent-Type: application/octet-stream\r\n\r\n'
	local footPart = '\r\n--' .. boundary .. '--\r\n'
	local allLen = #headPart + fileSize + #footPart
--	print('# start of Post: ' .. saveName .. "  size: " .. fileSize .. "  PostSize: " .. allLen)

	c:send('POST ' .. postURL .. ' HTTP/1.0\r\n')
	c:send('Host: ' .. tIP .. '\r\n')
	c:send('Accept: */*\r\n')
	c:send('Content-Type: multipart/form-data; boundary=' .. boundary .. '\r\n')
	c:send('Content-Length: ' .. allLen .. '\r\n')
	c:send('Connection: close\r\n')
	c:send('\r\n')

	c:send(headPart)
	local f = assert(io.open(filePath, "rb"))
	while true do
		local block = f:read(size)
		if not block then break end
		c:send(block)
	end
	f:close()
	c:send(footPart)

	c:shutdown('send')
--	print('# end of Post')

	-- receive
	local html = c:receive("*a")
	c:close()
	return html
end
-- print( postFileTCP('127.0.0.1', 80, '/f', 'c:/bin/AutoHotkey/AutoHotkey.exe', 'xxxxxxxx') )

-- 通过http Post单文件实现上传文件到http服务器，依赖:socket,lfs，注意io.open读取参数需加b
function postFileHTTP(postURL, filePath, saveName)
	-- 文件路径及保存名字初始化
	if nil == filePath then
		return nil, 'no file to post'
	else
		if nil == saveName then
			require("libfox.foxos")
			saveName = getFileName(filePath)
		end
	end

	-- 默认POST地址
	if nil == postURL then postURL = 'http://127.0.0.1/f' end
	local boundary = '----------------------------b03747cc70aa'

	local http = require("socket.http")
	http.TIMEOUT = 5
	local ltn12 = require("ltn12")
	local lfs = require("lfs")

	-- PostData 预计算大小
	local file_attr = lfs.attributes(filePath)
	local fileSize = file_attr.size
	local headPart = '--' .. boundary .. '\r\nContent-Disposition: form-data; name="f"; filename="' .. saveName .. '"\r\nContent-Type: application/octet-stream\r\n\r\n'
	local footPart = '\r\n--' .. boundary .. '--\r\n'

	local respbody = {}
	local body, code, headers, status = http.request {
		method = "POST",
		url = postURL,
		headers = {
			["Content-Type"] = "multipart/form-data; boundary=" .. boundary ,
			["Content-Length"] = #headPart + fileSize + #footPart
		},
		source = ltn12.source.cat( ltn12.source.string(headPart), ltn12.source.file( io.open(filePath, 'rb') ), ltn12.source.string(footPart) ),
		sink = ltn12.sink.table(respbody)
	}
	return table.concat(respbody), code, headers, status
end

-- 通过http 下载到文件
function getFileHTTP(inURL, savePath)
	local http = require("socket.http")
	http.TIMEOUT = 5
	local ltn12 = require("ltn12")

	return http.request {
		url = inURL,
		headers = {
			["Accept"] = "*/*",
			["User-Agent"] = "IE6"
		},
		sink = ltn12.sink.file( io.open(savePath, 'wb') ),
	}
end

