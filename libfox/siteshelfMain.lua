#! /usr/bin/lua

-- 获取有新章的书列表,　返回的数组元素: -- bookid, bookname, bookurl, dellist
function compareShelfToGetNew(shelf, cookie)
	require("libfox.foxhttp")

	local mainURL = shelf[1].bookurl -- 获取主要的url: mainURL

	-- 根据mainURL 得到 书架地址 urlShelf, Shelf匹配正则表达式
	local siteType = 0
	local iCookie, urlShelf, reShelf = '', '', '<tr>.-(aid=[^"]*)"[^>]*>([^<]*)<.-<td class="odd"><a href="([^"]*)"[^>]*>([^<]*)<'
	if string.match(mainURL, "%.13xs%.") then
		siteType = 11
		urlShelf = "http://www.13xs.com/shujia.aspx"
		reShelf  = '<tr>.-(aid=[^"]*)&index.-"[^>]*>([^<]*)<.-<td class="odd"><a href="[^"]*cid=([0-9]*)"[^>]*>([^<]*)<'
		iCookie = cookie.site13xs
	end
	if string.match(mainURL, "%.dajiadu%.") then
		siteType = 22
		urlShelf = "http://www.dajiadu.net/modules/article/bookcase.php"
		reShelf  = '<tr>.-(aid=[^"]*)&index.-"[^>]*>([^<]*)<.-<td class="odd"><a href="[^"]*cid=([0-9]*)"[^>]*>([^<]*)<'
		iCookie = cookie.sitedajiadu
	end
	if string.match(mainURL, "%.biquge%.") then
		siteType = 33
		urlShelf = "http://www.biquge.com.tw/modules/article/bookcase.php"
		reShelf  = '<tr>.-(aid=[^"]*)"[^>]*>([^<]*)<.-<td class="odd"><a href="([^"]*)"[^>]*>([^<]*)<'
		iCookie = cookie.sitebiquge
	end
	if string.match(mainURL, "%.piaotian%.") then
		siteType = 44
		urlShelf = "http://www.piaotian.com/modules/article/bookcase.php"
		reShelf  = '<tr>.-(aid=[^"]*)".-"[^>]*>([^<]*)<.-<td class="odd"><a href="[^"]*cid=([0-9]*)"[^>]*>([^<]*)<'
		iCookie = cookie.sitepiaotian
	end
	if siteType == 0 then return nil end  -- 当不在书架规则列表中时，返回nil
	iCookie = cookie2Field(iCookie)
	if '' == iCookie then return nil end  -- 当不存在cookie时，返回nil

	-- 下载获取网页字符串: html
	local html = ''
	local downTry = 0
	while downTry < 4 do
		html, httpok = gethtml(urlShelf, nil, iCookie)  -- 下载书架
		if 200 == httpok then
			if string.len(html) > 2048 then
				break
			end
		end
		downTry = downTry + 1
		if nil == html then html = '' end
		print("    Download: retry: " .. downTry .. "  Shelf  len(html): " .. string.len(html))
	end

--	filewrite(html, "xxxxx.html")
--	html = fileread("xxxxx.html")

	-- 判断网页编码并转成utf-8
	if string.match(string.lower(html), '<meta.-charset=([^"]*)[^>]->') ~= "utf-8" then
		require("libfox.utf8gbk")
		html = utf8gbk(html, true)
	end

	-- 循环每一记录，比较得到有新章节的书，有用的字段是: 书名, 最新章节的页面地址(可能要合成处理)，其他提示用
	local nn = {}  -- 返回的数组元素: -- bookidx, bookname, bookurl, dellist
	local realPageURLR = ''
	for bookurlR, booknameR, pageurlR, pagenameR in string.gmatch(html, reShelf) do
--		if bDebug then print(bookurlR, u2g(booknameR), pageurlR, u2g(pagenameR)) end

		realPageURLR = pageurlR
		if 11 == siteType then realPageURLR = pageurlR .. ".html" end
		if 22 == siteType then realPageURLR = pageurlR .. ".html" end
		if 44 == siteType then realPageURLR = pageurlR .. ".html" end

		local bookIDX = 0
		local booknameL, bookurlL, delListL = '', '', ''
		-- 将未读页面追加入pageListInBook
		for i, book in ipairs(shelf) do
			if booknameR == book.bookname then
				local pageListInBook = book.delurl
				for j, page in ipairs(book.chapters) do
					pageListInBook = pageListInBook .. page.pageurl .. "|" .. page.pagename .. "\n"
				end
				bookIDX = i
				booknameL = book.bookname
				bookurlL = book.bookurl
				delListL = pageListInBook
				break
			end
		end

		-- 判断最新章节链接是否在链接列表中，否就有新章节，添加到返回表中
		if '' ~= delListL then
			if not string.match(delListL, '\n' .. realPageURLR .. '%|') then
--				print("idx=" .. bookIDX .. "\nname=" .. booknameL .. "\nurl=" .. bookurlL .. "\nlist=" .. delListL)
				local ll = {bookidx=bookIDX, bookname=booknameL, bookurl=bookurlL, dellist=delListL}
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

