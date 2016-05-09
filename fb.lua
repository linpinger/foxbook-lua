#! /usr/bin/lua

-- 判断是不是Linux环境
if nil == string.match(package.path, '/') then
	isLinux = false
	package.path = package.path .. ";C:\\bin\\Lua\\?.lua;D:\\bin\\Lua\\?.lua;"
	dbPath = "FoxBook.db3"
else
	isLinux = true
	package.path = package.path .. ";/aaa/bin/?.lua;/root/bin/?.lua;/home/fox/bin/?.lua;"
	dbPath = "FoxBook.db3"
end

-- 各种依赖
require("libfox.foxnovel")
require("libfox.foxdb3")

	if nil ~= arg[1] then dbPath = arg[1] end -- 命令行分析
	local bGetShelfFirst = true  -- 是否先下载书架比较得到新书？

function getAllBooksToUpdate()
	local nn = {}
	for bookidD, booknameD, bookurlD, pageListInDB in db3_rows("SELECT id,name,url,DelURL from book where isEnd isnull or isEnd < 1") do
		-- 将未读页面追加入pageListInDB
		for pagename, pageurl in db3_rows("SELECT name,url from page where bookid=" .. bookidD) do
			pageListInDB = pageListInDB .. pageurl .. "|" .. pagename .. "\n"
		end
		local ll = {bookid=bookidD, bookname=booknameD, bookurl=bookurlD, dellist=pageListInDB}
		table.insert(nn, ll)
	end
	return nn
end

db3_open(dbPath)

print("##########  START  " .. dbPath .. "  ##########")

local upBooksList = {}
if bGetShelfFirst then
--	print('-- get Shelf Books First')
	require("libfox.siteshelf")
	upBooksList = compareShelfToGetNew() -- 获取有新章的书列表,　返回的数组元素: -- bookid, bookname, bookurl, dellist
	if nil == upBooksList then
		upBooksList = getAllBooksToUpdate() 
		print('-- DB Have ' .. #upBooksList .. ' Books To Update because Now MainSite shelf is not Suportted Yet')
	else
		if #upBooksList > 0 then
			print('-- Shelf Have ' .. #upBooksList .. ' Books To Update')
		end
	end
	if 0 == #upBooksList then
		db3_close()
		print("##########  Exit  No NewPages in " .. dbPath .. "  ##########")
		os.exit(0)
	end
else
	print('-- update All Books in DB')
	upBooksList = getAllBooksToUpdate() 
	print('-- DB Have ' .. #upBooksList .. ' Books To Update')
end


-- { 循环要更新的书
	require("libfox.foxhttp")
	local allNewCount = 0

for i, t in ipairs(upBooksList) do
	local bookid = t.bookid
	local bookname = t.bookname
	local bookurl = t.bookurl
	local pageListInDB = t.dellist
	if not isLinux then
		require("libfox.utf8gbk")
		bookname = utf8gbk(bookname, false)
	end
-- { 不同站点下载目录
	local gg = {}
	if string.match(bookurl, 'm.qreader.me') then  -- qreader
		require("libfox.siteqreader")
		gg = qreader_GetIndex(bookurl)
	else -- 通用站点
		local downTry = 0
		while downTry < 4 do
			html, httpok = gethtml(bookurl) -- 下载目录
			if 200 == httpok then
				if string.len(html) > 2048 then
					break
				end
			end
			downTry = downTry + 1
			print(bookid, "warn: downIndex retry:", downTry, string.len(html))
		end

		-- 判断网页编码并转成utf-8
		if string.match(string.lower(html), '<meta.-charset=([^"]*)[^>]->') ~= "utf-8" then
			require("libfox.utf8gbk")
			html = utf8gbk(html, true)
		end

		if httpok then
			if string.len(html) > 2048 then
				gg = getIndexs(html) -- 分析目录
				html = nil
			end
		end
	end
-- } 不同站点下载目录

-- { 过滤获得新章节数组gg
	if #gg > 0 then  -- 防止下载错误
		local nn = {}
		if string.len(pageListInDB) > 5 then
			local firstline = string.match(pageListInDB, '([^|]-)\|')
			local bFound = false
			if #gg > 50 then
				j = #gg - 50
			else
				j = 1
			end
			for j=j, #gg do  -- 这里的50是如果不是新书时，值显示最后50条章节
				if not bFound then
					if gg[j]["l"] == firstline then
						bFound = true
					end
				else
					if not string.match(pageListInDB, '\n' .. string.gsub(gg[j]["l"], '%?', '%%?') .. '\|') then
						table.insert(nn, gg[j])
					end
				end
			end
			gg = nn
			nn = nil
		end
	end
-- } 过滤获得新章节数组gg

-- { 有新章节，下载
	if #gg > 0 then  -- 有新章节
		allNewCount = allNewCount + #gg
		print(bookid, #gg, 'new in', bookname)

		-- { 逐章下载页面
		for i=1, #gg do
			local pageurl = gg[i]["l"]
			local pagename = gg[i]["n"]
			local realpageurl = getFullURL(pageurl, bookurl)

			-- { 不同站点下载页面
			local text = ""
			if string.match(bookurl, 'm.qreader.me') then
				require("libfox.siteqreader")
				text = qreader_GetContent(bookurl .. pageurl)
			elseif string.match(bookurl, 'msn.qidian.com') then
				require("libfox.siteqidian")
				text = qidian_GetContent(bookurl, pageurl)
			else
				local downTry = 0
				while downTry < 4 do
					html, httpok = gethtml(realpageurl)  -- 下载页面
					if 200 == httpok then
						if string.len(html) > 2048 then
							break
						end
					end
					downTry = downTry + 1
					print(bookid, "warn: downPage retry:", downTry, string.len(html))
				end

				-- 判断网页编码并转成utf-8
				if string.match(string.lower(html), '<meta.-charset=([^"]*)[^>]->') ~= "utf-8" then
					require("libfox.utf8gbk")
					html = utf8gbk(html, true)
				end

				text = getPageText(html)
				html = nil
			end
			-- } 不同站点下载页面
			db3_foxbook_addNewPage(pageurl, pagename, delNouseText(text), bookid)

			if not isLinux then
				require("libfox.utf8gbk")
				pagename = utf8gbk(pagename, false)
			end
			io.write('\t    ', i, " : ", pagename, '  size: ', string.len(text), "\n")
		end -- } 逐章下载页面
	else -- 无新章节
		print(bookid, 0, bookname)
	end
-- } 有新章节，下载
end
-- } 循环要更新的书
db3_exec('update page set charcount=length(Content)') -- 更新charcount，因为lua计算出来的貌似是字节数
db3_foxbook_sortBookDesc(true) -- 倒序排列
db3_close()

print("##########  DONE  Got " .. allNewCount .. " NewPages  " .. dbPath .. "  ##########")


