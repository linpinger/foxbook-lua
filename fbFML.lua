#! /usr/bin/lua
	
	-- 更新: lua this.lua data.fml
	-- 显示 书/书的章 列表: lua this.lua data.fml ls [1]
	-- 清空索引为1的书: lua this.lua data.fml cb 1

	local shelfFilePath = "FoxBook.fml"
	local cookiePath = "FoxBook.cookie"

	local cmdStr = ""
	if nil ~= arg[2] then cmdStr = arg[2] end
	if nil ~= arg[1] then shelfFilePath = arg[1] end -- 命令行分析
	local bGetShelfFirst = true  -- 是否先下载书架比较得到新书？

	local shelfName = string.match(shelfFilePath, "([^\\/]*).fml")
-- 判断是不是Linux环境
if nil == string.match(package.path, '/') then
	isLinux = false
	package.path = package.path .. ";C:\\bin\\Lua\\?.lua;D:\\bin\\Lua\\?.lua;"
else
	isLinux = true
	package.path = package.path .. ";/aaa/bin/?.lua;/root/bin/?.lua;/home/fox/bin/?.lua;/dev/shm/00/?.lua;"
end

-- 各种依赖
require("libfox.foxnovel")

require("libfox.fmlStor")
shelf = loadFML(shelfFilePath)  -- 反序列化fml

-- { -- 命令行处理
if "ls" == cmdStr then -- 列出书列表/书的章节列表
	local cmdBookIDX = tonumber(arg[3])
	local showTB = ""
	if nil == cmdBookIDX then
		showTB = "\nbIDX\tPageC\tBookName\n"
		for i, book in ipairs(shelf) do
			showTB = showTB .. i .. "\t" .. #book.chapters .. "\t" .. book.bookname .. "\n"
		end
	else
		showTB = "\npIDX\tPageName\n"
		for i, page in ipairs(shelf[cmdBookIDX].chapters) do
			showTB = showTB .. i .. "\t" .. page.pagename .. "\n"
		end
	end
	if not isLinux then
		require("libfox.utf8gbk")
		showTB = utf8gbk(showTB, false)
	end
	print(showTB)
	os.exit(0)
elseif "cb" == cmdStr then -- 清空某本书并记录
	local cmdBookIDX = tonumber(arg[3])
	if nil == cmdBookIDX then
		print('ClearBook Usage: xx.lua xx.fml cb 1')
	else
		local newDelList = shelf[cmdBookIDX].delurl
		for i, page in ipairs(shelf[cmdBookIDX].chapters) do
			newDelList = newDelList .. page.pageurl .. "|" .. page.pagename .. "\n"
		end
		newDelList = SimplifyDelList(newDelList) -- 精简dellist
--		print(newDelList)
		shelf[cmdBookIDX].delurl = newDelList
		shelf[cmdBookIDX].chapters = {}

		os.remove(shelfFilePath .. ".old")
		if os.rename(shelfFilePath, shelfFilePath .. ".old") then
			saveFML(shelf, shelfFilePath) -- 序列化fml
		end
	end
	os.exit(0)
end
-- } -- 命令行处理

cookie = loadCookie(cookiePath)

print("##  " .. shelfFilePath .. "  START")

function getAllBooksToUpdate(shelf)
	local nn = {}

	-- 将未读页面追加入pageListInBook
	for i, book in ipairs(shelf) do
		local pageListInBook = book.delurl
		for j, page in ipairs(book.chapters) do
			pageListInBook = pageListInBook .. page.pageurl .. "|" .. page.pagename .. "\n"
		end
		local ll = {bookidx=i, bookname=book.bookname, bookurl=book.bookurl, dellist=pageListInBook}
		table.insert(nn, ll)
	end

	return nn
end

local upBooksList = {}
if bGetShelfFirst then
	require("libfox.siteshelfMain")
	upBooksList = compareShelfToGetNew(shelf, cookie) -- 获取有新章的书列表,　返回的数组元素: -- bookidx, bookname, bookurl, dellist

-- print("new book count = " .. #upBooksList)
-- os.exit(0)

	if nil == upBooksList then
		upBooksList = getAllBooksToUpdate(shelf) 
		print('**  ' .. shelfName .. ' Have ' .. #upBooksList .. ' Books Update, Maybe shelf isnot suport or no cookie')
	else
		if #upBooksList > 0 then
			print('**  ' .. shelfName .. ' Shelf Have ' .. #upBooksList .. ' Books To Update')
		end
	end
	if 0 == #upBooksList then
		print("##  " .. shelfName .. "  Exit  No NewPages")
		os.exit(0)
	end
else
	upBooksList = getAllBooksToUpdate(shelf) 
	print('**  ' .. shelfName .. ' Have ' .. #upBooksList .. ' Books To Update')
end


-- { 循环要更新的书
	require("libfox.foxhttp")
	local allNewCount = 0

for i, t in ipairs(upBooksList) do
	local bookidx = t.bookidx
	local bookname = t.bookname
	local bookurl = t.bookurl
	local pageListInDB = t.dellist
	if not isLinux then
		require("libfox.utf8gbk")
		bookname = utf8gbk(bookname, false)
	end
-- { 不同站点下载目录 -- 通用站点
	local gg = {}
	local downTry = 0
	while downTry < 4 do
		html, httpok = gethtml(bookurl) -- 下载目录
		if 200 == httpok then
			if string.len(html) > 2048 then
				break
			end
		end
		downTry = downTry + 1
		print("    Download: retry: " .. downTry .. "  bid: " .. bookidx .. "  len(html): " .. string.len(html))
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
-- } 不同站点下载目录

-- { 过滤获得新章节数组gg
	if #gg > 0 then  -- 防止下载错误
		local nn = {}
		if string.len(pageListInDB) > 5 then
			local firstline = string.match(pageListInDB, '([^|]-)%|')
			local bFound = false
			for j=1, #gg do
				if not bFound then
					if gg[j]["l"] == firstline then
						bFound = true
					end
				else
					if not string.match(pageListInDB, '\n' .. string.gsub(gg[j]["l"], '%?', '%%?') .. '%|') then
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
		print('--  ' .. shelfName .. " : " .. bookname .. " Have " .. #gg .. " NewPages")

		-- { 逐章下载页面
		for i=1, #gg do
			local pageurl = gg[i]["l"]
			local pagename = gg[i]["n"]
			local realpageurl = getFullURL(pageurl, bookurl)

			-- { 不同站点下载页面
			local text = ""
			if string.match(bookurl, 'msn.qidian.com') then
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
					print("    Download: retry: " .. downTry .. "  bid: " .. bookidx .. "  len(html): " .. string.len(html))
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
			local contentLen = math.ceil(string.len(text) / 3)
			-- 添加新章节到bookidx
			newPage = {}
			newPage.pagename = pagename
			newPage.pageurl = pageurl
			newPage.content = delNouseText(text)
			newPage.size = contentLen  -- lua计算出来的是字节数，不过问题不大
			table.insert(shelf[bookidx].chapters, newPage)

			if not isLinux then
				require("libfox.utf8gbk")
				pagename = utf8gbk(pagename, false)
			end
			print('++  ' .. shelfName .. " : " .. i .. " : " .. pagename .. " Size: " .. contentLen)
		end -- } 逐章下载页面
	else -- 无新章节
		print('--  ' .. shelfName .. " : " .. bookname .. " Have 0 NewPages")
	end
-- } 有新章节，下载
end
-- } 循环要更新的书

function sortDescByPagesCount(bookL, bookR)
	if bookL == nil then return false end
	if bookR == nil then return false end

	if #bookL.chapters > #bookR.chapters then
		return true
	elseif #bookL.chapters == #bookR.chapters then
		local qdidL, qdidR = tonumber(bookL.qidianBookID), tonumber(bookR.qidianBookID)
		if qdidL < qdidR then
			return true
		else
			return false
		end
		return true
	else
		return false
	end
end
table.sort(shelf, sortDescByPagesCount) -- 倒序排列，比较的因素必须是唯一的，不能重复，所以如果没有QDID就会呵呵

os.remove(shelfFilePath .. ".old")
if os.rename(shelfFilePath, shelfFilePath .. ".old") then
	saveFML(shelf, shelfFilePath) -- 序列化fml
end

print("##  " .. shelfName .. "  DONE  GOT " .. allNewCount .. " NewPages")


