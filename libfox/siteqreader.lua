#! /usr/bin/lua

-- https://github.com/grafi-tt/lunajson
-- http://lua-users.org/wiki/JsonModules

function qreader_GetIndex(dbBookUrl) -- dbBookUrl = "http://m.qreader.me/query_catalog.php?bid=4872388"
	require("libfox.foxhttp")
	local bid = string.match(dbBookUrl, 'bid=([0-9]*)')
	local postData = '{"id":' .. bid .. '}'

	local html = ''
	local downTry = 0
	while downTry < 4 do
		html, httpok = gethtml("http://m.qreader.me/query_catalog.php", postData) -- 下载目录
		if 200 == httpok then break end
		downTry = downTry + 1
		print("    Download: retry: " .. downTry .. "  bid: " .. bid .. "  len(html): " .. string.len(html))
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
	require("libfox.foxhttp")
	local bookid, pageid = string.match(PgURL, 'bid=([0-9]*)#([0-9]*)')
	local postData = '{"id":' .. bookid .. ',"cid":' .. pageid .. '}'

	local html = ''
	local downTry = 0
	while downTry < 4 do
		html, httpok = gethtml("http://chapter.qreader.me/download_chapter.php", postData) -- 下载章节
		if 200 == httpok then break end
		downTry = downTry + 1
		print("    Download: retry: " .. downTry .. "  bid: " .. bookid .. "  len(html): " .. string.len(html))
	end

	require("libfox.utf8gbk")
	html = utf8gbk(html, true)

	html = string.gsub(html, '　　', '')  -- 删除所有空白

	return html
end

--[[

sTime = os.clock()
	dbBookUrl = "http://m.qreader.me/query_catalog.php?bid=4872388"
	gg = qreader_GetIndex(dbBookUrl) -- dbBookUrl = "http://m.qreader.me/query_catalog.php?bid=4872388"
	for i, v in ipairs(gg) do
		print(i, v.l, u2g(v.n))
	end

	PgURL = "http://m.qreader.me/query_catalog.php?bid=4872388#321"
	local text = qreader_GetContent(PgURL)
	print(u2g(text))

eTime = os.clock() - sTime
print('Used Time: ' .. eTime)
--]]

