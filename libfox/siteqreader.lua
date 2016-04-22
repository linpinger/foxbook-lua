#! /usr/bin/lua

-- https://github.com/grafi-tt/lunajson
-- http://lua-users.org/wiki/JsonModules

	require("libfox.foxcurl")
	local iconv = require("iconv")
	local g2u = iconv.new("utf-8", "gbk")
	local u2g = iconv.new("gbk", "utf-8")

function qreader_GetIndex(dbBookUrl) -- dbBookUrl = "http://m.qreader.me/query_catalog.php?bid=4872388"
	local postData = '{"id":' .. string.match(dbBookUrl, 'bid=([0-9]*)') .. '}'

	local html = ''
	local downTry = 0
	while downTry < 4 do
		html, httpok = gethtml("http://m.qreader.me/query_catalog.php", postData) -- 下载目录
		if httpok then break end
		downTry = downTry + 1
		print("warn: downPage retry:", downTry, string.len(html))
	end

	local lunajson = require("libfox.lunajson")
	local t = lunajson.decode(html)

	local gg = {}
	for _, v in ipairs(t.catalog) do
		local it = {}
		it.l = "#" .. v.i
		it.n = v.n
		table.insert(gg, it)
	end
	return gg
end

function qreader_GetContent(PgURL) -- "http://m.qreader.me/query_catalog.php?bid=4872388#321"
	local bookid, pageid = string.match(PgURL, 'bid=([0-9]*)#([0-9]*)')
	local postData = '{"id":' .. bookid .. ',"cid":' .. pageid .. '}'

	local html = ''
	local downTry = 0
	while downTry < 4 do
		html, httpok = gethtml("http://chapter.qreader.me/download_chapter.php", postData) -- 下载章节
		if httpok then break end
		downTry = downTry + 1
		print("warn: downPage retry:", downTry, string.len(html))
	end

	html = g2u:iconv(html)

	html = string.gsub(html, '　　', '')  -- 删除所有空白

	return html
end

--[[

sTime = os.clock()
	dbBookUrl = "http://m.qreader.me/query_catalog.php?bid=4872388"
	gg = qreader_GetIndex(dbBookUrl) -- dbBookUrl = "http://m.qreader.me/query_catalog.php?bid=4872388"
	for i, v in ipairs(gg) do
		print(i, v.l, u2g:iconv(v.n))
	end

	PgURL = "http://m.qreader.me/query_catalog.php?bid=4872388#321"
	local text = qreader_GetContent(PgURL)
	print(u2g:iconv(text))

eTime = os.clock() - sTime
print('Used Time: ' .. eTime)
--]]

