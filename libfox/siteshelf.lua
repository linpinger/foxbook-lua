#! /usr/bin/lua

-- 获取有新章的书列表,　返回的数组元素: -- bookid, bookname, bookurl, dellist
function compareShelfToGetNew()
	require("libfox.foxdb3")
	require("libfox.foxhttp")

	-- 获取主要的url: mainURL
	local mainURL = ''
	for cc in db3_rows("select URL from book where ( isEnd isnull or isEnd < 1 ) limit 1") do mainURL = cc end

	-- 根据mainURL 得到 书架地址 urlShelf, Shelf匹配正则表达式
	local siteType = 0
	local urlShelf, reShelf = '', '<tr>.-(aid=[^"]*)"[^>]*>([^<]*)<.-<td class="odd"><a href="([^"]*)"[^>]*>([^<]*)<'
	if string.match(mainURL, "\.13xs\.") then
		siteType = 11
		urlShelf = "http://www.13xs.com/shujia.aspx"
		reShelf  = '<tr>.-(aid=[^"]*)&index.-"[^>]*>([^<]*)<.-<td class="odd"><a href="[^"]*cid=([0-9]*)"[^>]*>([^<]*)<'
	end
	if string.match(mainURL, "\.dajiadu\.") then
		siteType = 22
		urlShelf = "http://www.dajiadu.net/modules/article/bookcase.php"
		reShelf  = '<tr>.-(aid=[^"]*)&index.-"[^>]*>([^<]*)<.-<td class="odd"><a href="[^"]*cid=([0-9]*)"[^>]*>([^<]*)<'
	end
	if string.match(mainURL, "\.biquge\.") then
		siteType = 33
		urlShelf = "http://www.biquge.com.tw/modules/article/bookcase.php"
		reShelf  = '<tr>.-(aid=[^"]*)"[^>]*>([^<]*)<.-<td class="odd"><a href="([^"]*)"[^>]*>([^<]*)<'
	end
	if string.match(mainURL, "\.qreader\.") then
		siteType = 99
		urlShelf = "http://m.qreader.me/update_books.php"
-- {"id":4776339,"status":0,"img":1,"catalog_t":1461247953,"chapter_c":686,"chapter_i":838,"chapter_n":"\u7b2c745\u7ae0 \u51e0\u76cf\u706f"}
		reShelf = '"id":([0-9]*),"status":([0-9]*).-"chapter_i":([0-9]*),"chapter_n":"([^"]*)"' -- bookid, status, pageurl_ID, pagename_xxxx
	end
	if siteType == 0 then return nil end  -- 当不在书架规则列表中时，返回nil
	
	local postData, iCookie = '', ''
	if 99 == siteType then
		-- qreader 获取PostData
		local tb = {}
		for cc in db3_rows("select URL from book where url like '%m.qreader.me/query_catalog.php?bid=%'") do
			table.insert(tb, '{"t":0,"i":' .. string.match(cc, 'bid=([0-9]*)') .. '}')
		end
		postData = '{"books":[' .. table.concat(tb, ',') .. ']}'
	else
		-- 根据URL获得网站cookie: iCookie
		for cc in db3_rows("SELECT cookie from config where site like '%" .. string.match(mainURL, '(http://[^/]*)/') .. "%'") do iCookie = cc end
		iCookie = cookie2Field(iCookie)
	end

	-- 下载获取网页字符串: html
	local html = ''
	local downTry = 0
	while downTry < 4 do
		if 99 == siteType then
			html, httpok = gethtml(urlShelf, postData)  -- 下载书架
			if 200 == httpok then break end
		else
			html, httpok = gethtml(urlShelf, nil, iCookie)  -- 下载书架
			if 200 == httpok then
				if string.len(html) > 2048 then
					break
				end
			end
		end
		downTry = downTry + 1
		if nil == html then html = '' end
		print(bookid, "warn: downShelf retry:", downTry, string.len(html))
	end
--	filewrite(html, "xxxxx.html")
--	html = fileread("xxxxx.html")

	-- 判断网页编码并转成utf-8
	if string.match(string.lower(html), '<meta.-charset=([^"]*)[^>]->') ~= "utf-8" then
		require("libfox.utf8gbk")
		html = utf8gbk(html, true)
	end

	-- 循环每一记录，比较得到有新章节的书，有用的字段是: 书名, 最新章节的页面地址(可能要合成处理)，其他提示用
	local nn = {}  -- 返回的数组元素: -- bookid, bookname, bookurl, dellist
	local realPageURLR = ''
	for bookurlR, booknameR, pageurlR, pagenameR in string.gmatch(html, reShelf) do
--		if bDebug then print(bookurlR, u2g(booknameR), pageurlR, u2g(pagenameR)) end

		realPageURLR = pageurlR
		if 11 == siteType then realPageURLR = pageurlR .. ".html" end
		if 22 == siteType then realPageURLR = pageurlR .. ".html" end

		local addSQLStr = "where name = '" .. booknameR .. "'"
		if 99 == siteType then
			realPageURLR = '#' .. pageurlR
			addSQLStr = "where url like '%bid=" .. bookurlR .. "'"
		end

		local bookidL = 0
		local booknameL, bookurlL, delListL = '', '', ''
		-- 将未读页面追加入pageListInDB
		for bookid, bookname, bookurl, pageListInDB in db3_rows("SELECT id,name,url,DelURL from book " .. addSQLStr) do
			for pagename, pageurl in db3_rows("SELECT name,url from page where bookid=" .. bookid) do
				pageListInDB = pageListInDB .. pageurl .. "|" .. pagename .. "\n"
			end
			bookidL = bookid
			booknameL = bookname
			bookurlL = bookurl
			delListL = pageListInDB
		end

		-- 判断最新章节链接是否在链接列表中，否就有新章节，添加到返回表中
		if '' ~= delListL then
			if not string.match(delListL, '\n' .. realPageURLR .. '\|') then
				local ll = {bookid=bookidL, bookname=booknameL, bookurl=bookurlL, dellist=delListL}
				table.insert(nn, ll)
--				if bDebug then print("NewPage: ", #nn, u2g(booknameR), u2g(pagenameR), realPageURLR) end
			end
		end
	end

--	if bDebug then print("Book Counts of which have newPages:", #nn) end

	return nn
end


-- main
--[[
db3_open("FoxBook.db3")
	
	bDebug = false
	nn = compareShelfToGetNew()
	print('-------')
	for i, t in ipairs(nn) do
		for k, v in pairs(t) do
			print(k, u2g(v))
		end
		print('--')
	end

	print("Book Counts of which have newPages:", #nn)
db3_close()
--]]

