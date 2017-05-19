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
		iCookie = cookie['13xs']
	end
	if string.match(mainURL, "%.13xxs%.") then
		siteType = 12
		urlShelf = "http://www.13xxs.com/modules/article/bookcase.php?classid=0"
		reShelf  = '<tr>.-(aid=[^"]*)"[^>]*>([^<]*)<.-<td class="odd"><a href="[^"]*/([0-9]*.html)"[^>]*>([^<]*)<'
		iCookie = cookie['13xxs']
	end
	if string.match(mainURL, "%.dajiadu%.") then
		siteType = 22
		urlShelf = "http://www.dajiadu.net/modules/article/bookcase.php"
		reShelf  = '<tr>.-(aid=[^"]*)&index.-"[^>]*>([^<]*)<.-<td class="odd"><a href="[^"]*cid=([0-9]*)"[^>]*>([^<]*)<'
		iCookie = cookie['dajiadu']
	end
	if string.match(mainURL, "%.biquge%.") then
		siteType = 33
		urlShelf = "http://www.biquge.com.tw/modules/article/bookcase.php"
		reShelf  = '<tr>.-(aid=[^"]*)"[^>]*>([^<]*)<.-<td class="odd"><a href="([^"]*)"[^>]*>([^<]*)<'
		iCookie = cookie['biquge']
	end
	if string.match(mainURL, "%.piaotian%.") then
		siteType = 44
		urlShelf = "http://www.piaotian.com/modules/article/bookcase.php"
		reShelf  = '<tr>.-(aid=[^"]*)".-"[^>]*>([^<]*)<.-<td class="odd"><a href="[^"]*cid=([0-9]*)"[^>]*>([^<]*)<'
		iCookie = cookie['piaotian']
	end
	if string.match(mainURL, "%.xxbiquge%.") then
		siteType = 55
		urlShelf = "http://www.xxbiquge.com/bookcase.php"
		reShelf  = '<li>.-"s2"><a href="([^"]*)"[^>]->([^<]*)<.-"s4"><a href="([^"]*)"[^>]*>([^<]*)<'
		iCookie = cookie['xxbiquge']
	end
	if string.match(mainURL, "%.xqqxs%.") then
		siteType = 66
		urlShelf = "http://www.xqqxs.com/modules/article/bookcase.php?delid=604"
		reShelf  = '<tr>.-(indexflag)[^>]*>([^<]*)<.-cid=([0-9]*)"[^>]*>([^<]*)<'
		iCookie = cookie['xqqxs']
	end
	if siteType == 0 then return nil end  -- 当不在书架规则列表中时，返回nil
	iCookie = cookie2Field(iCookie)
	if '' == iCookie then return nil end  -- 当不存在cookie时，返回nil

	-- 下载获取网页字符串: html
	local html = gethtml(urlShelf, nil, iCookie)  -- 下载书架
	if 55 ~= siteType then -- xxbiquge是个错的编码，实际是UTF8，写的是GBK，坑
		html = html2utf8(html, urlShelf) -- 判断网页编码并转成utf-8
	end

	-- 循环每一记录，比较得到有新章节的书，有用的字段是: 书名, 最新章节的页面地址(可能要合成处理)，其他提示用
	local nn = {}  -- 返回的数组元素: -- bookidx, bookname, bookurl, dellist
	local realPageURLR = ''
	for bookurlR, booknameR, pageurlR, pagenameR in string.gmatch(html, reShelf) do
--		print(bookurlR, utf8gbk(booknameR, false), pageurlR, utf8gbk(pagenameR, false))

		realPageURLR = pageurlR
		if 11 == siteType or 22 == siteType or 44 == siteType or 66 == siteType then realPageURLR = pageurlR .. ".html" end

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

