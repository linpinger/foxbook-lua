#! /usr/bin/lua
	
	-- 更新: lua this.lua data.fml
	-- 显示 书/书的章 列表: lua this.lua data.fml ls [1]
	-- 清空索引为1的书: lua this.lua data.fml cb 1

	local shelfFilePath = "FoxBook.fml"
	local cookiePath = "FoxBook.cookie"

	local bGetBookCaseFirst = true  -- 是否先下载书架比较得到新书？

	local cmdStr = ""
	-- 命令行分析
	if nil ~= arg[2] then cmdStr = arg[2] end
	if nil ~= arg[1] then
		shelfFilePath = arg[1]
		if 'qd' == shelfFilePath then shelfFilePath = 'qidian.fml' end
		if 'fb' == shelfFilePath then shelfFilePath = 'FoxBook.fml' end
		if 'dj' == shelfFilePath then shelfFilePath = 'dajiadu.fml' end
		if 'pt' == shelfFilePath then shelfFilePath = 'piaotian.fml' end
		if '13' == shelfFilePath then shelfFilePath = '13xxs.fml' end
		if 'xq' == shelfFilePath then shelfFilePath = 'xqqxs.fml' end
		if 'xx' == shelfFilePath then shelfFilePath = 'xxbiquge.fml' end
	end

	-- 此语句需在 require 之前
	if nil == string.match(package.path, '/') then  -- windows
		package.path = package.path .. ";C:\\bin\\Lua\\?.lua;D:\\bin\\Lua\\?.lua;"
		isLinux = false
		wDir  = '/bin/sqlite/FoxBook/'
		wDir2 = '/bin/sqlite/more_FML/'
	else -- linux
		package.path = package.path .. ";/aaa/bin/?.lua;/root/bin/?.lua;/home/fox/bin/?.lua;/dev/shm/00/?.lua;"
		isLinux = true
		wDir  = '/aaa/k4/'
		wDir2 = '/dev/shm/00/'
	end

	-- 检测 shelfFilePath 路径
	require("libfox.foxos")
	if not fileexist(shelfFilePath) then
		if isLinux then
			if fileexist(wDir .. shelfFilePath) then
				shelfFilePath = wDir .. shelfFilePath
			elseif fileexist(wDir2 .. shelfFilePath) then
				shelfFilePath = wDir2 .. shelfFilePath
			end
		else
			if fileexist('C:' .. wDir .. shelfFilePath) then
				shelfFilePath = 'C:' .. wDir .. shelfFilePath
			elseif fileexist('D:' .. wDir .. shelfFilePath) then
				shelfFilePath = 'D:' .. wDir .. shelfFilePath
			elseif fileexist('C:' .. wDir2 .. shelfFilePath) then
				shelfFilePath = 'C:' .. wDir2 .. shelfFilePath
			elseif fileexist('D:' .. wDir2 .. shelfFilePath) then
				shelfFilePath = 'D:' .. wDir2 .. shelfFilePath
			end
		end
	end
	local shelfName = string.match(shelfFilePath, "([^\\/]*).fml")

	if bGetBookCaseFirst then -- 检测cookie是否存在，不存在就更新所有
		require("libfox.foxos")
		if not fileexist(cookiePath) then
			if isLinux then
				if fileexist(wDir .. cookiePath) then
					cookiePath = wDir .. cookiePath
				elseif fileexist(wDir2 .. cookiePath) then
					cookiePath = wDir2 .. cookiePath
				else
					bGetBookCaseFirst = false
				end
			else
				if fileexist('C:' .. wDir .. cookiePath) then
					cookiePath = 'C:' .. wDir .. cookiePath
				elseif fileexist('D:' .. wDir .. cookiePath) then
					cookiePath = 'D:' .. wDir .. cookiePath
				else
					bGetBookCaseFirst = false
				end
			end
		end
	end

	require("libfox.fmlStor")
	shelf = loadFML(shelfFilePath)  -- 反序列化fml

function closeAndSaveFML(shelf, savePath)
	os.remove(savePath .. ".old")
	if os.rename(savePath, savePath .. ".old") then
		require("libfox.fmlStor")
		saveFML(shelf, savePath) -- 序列化fml
	end
end

function lsBook(iBookIDX, shelf) -- 列出书列表/书的章节列表
	local oStr = ""
	if nil == iBookIDX then
		oStr = "\nbIDX\tPageC\tBookName\n"
		for i, book in ipairs(shelf) do
			oStr = oStr .. i .. "\t" .. #book.chapters .. "\t" .. book.bookname .. "\n"
		end
	else
		oStr = "\npIDX\tPageName\n"
		for i, page in ipairs(shelf[iBookIDX].chapters) do
			oStr = oStr .. i .. "\t" .. page.pagename .. "\n"
		end
	end
	return oStr
end

function clearBook(iBookIDX, shelf) -- 清空某本书并记录
	if nil == iBookIDX then
		print('ClearBook Usage: xx.lua xx.fml cb 1')
	else
		local newDelList = shelf[iBookIDX].delurl
		for i, page in ipairs(shelf[iBookIDX].chapters) do
			newDelList = newDelList .. page.pageurl .. "|" .. page.pagename .. "\n"
		end
		require("libfox.foxnovel")
		newDelList = SimplifyDelList(newDelList) -- 精简dellist
		shelf[iBookIDX].delurl = newDelList
		shelf[iBookIDX].chapters = {}
	end
end

-- { -- 命令行处理
if "ls" == cmdStr then -- 列出书列表/书的章节列表
	local cmdBookIDX = tonumber(arg[3])
	oStr = lsBook(cmdBookIDX, shelf)
	if not isLinux then
		require("libfox.utf8gbk")
		oStr = utf8gbk(oStr, false)
	end
	print(oStr)
	os.exit(0)
elseif "cb" == cmdStr then -- 清空某本书并记录
	local cmdBookIDX = tonumber(arg[3])
	clearBook(cmdBookIDX, shelf)
	closeAndSaveFML(shelf, shelfFilePath)
	os.exit(0)
end
-- } -- 命令行处理


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

-- 过滤获得新章节数组gg
function compareBook2GetNewPages(bookList, bookAllPageStr)
	if #bookList > 0 then  -- 防止下载错误
		local nn = {}
		if string.len(bookAllPageStr) > 5 then
			local firstline = string.match(bookAllPageStr, '([^|]-)%|')
			local bFound = false
			for j=1, #bookList do
				if not bFound then
					if bookList[j]["l"] == firstline then
						bFound = true
					end
				else
					if not string.match(bookAllPageStr, '\n' .. string.gsub(bookList[j]["l"], '%?', '%%?') .. '%|') then
						table.insert(nn, bookList[j])
					end
				end
			end
			bookList = nn
			nn = nil
		end
	end
	return bookList
end


-- main
print("##  " .. shelfFilePath .. "  START")

local upBooksList = {}
if bGetBookCaseFirst then
	require("libfox.fmlStor")
	local cookie = loadCookie(cookiePath)
	require("libfox.siteshelfFML")
	upBooksList = compareShelfToGetNew(shelf, cookie) -- 获取有新章的书列表,　返回的数组元素: -- bookidx, bookname, bookurl, dellist

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
-- { 不同站点下载目录
	html = gethtml(bookurl) -- 下载目录
	html = html2utf8(html, bookurl) -- 判断网页编码并转成utf-8
	local gg = {}
	if string.match(bookurl, "druid%.if%.qidian%.com/Atom%.axd/Api/Book/GetChapterList") then
		require("libfox.siteqidian")
		gg = qidian_GetIndex(html)
	else -- 通用站点
		if string.len(html) > 2048 then
			require("libfox.foxnovel")
			gg = getIndexs(html)
		end
	end
	html = nil
-- } 不同站点下载目录

	gg = compareBook2GetNewPages(gg, pageListInDB) -- 过滤获得新章节数组gg

-- { 有新章节，下载
	if #gg > 0 then  -- 有新章节
		allNewCount = allNewCount + #gg
		print('--  ' .. shelfName .. " : " .. bookname .. " Have " .. #gg .. " NewPages")

		-- { 逐章下载页面
		for i=1, #gg do
			local pageurl = gg[i]["l"]
			local pagename = gg[i]["n"]
			require("libfox.foxnovel")
			local realpageurl = getFullURL(pageurl, bookurl)

			-- { 不同站点下载页面
			local text = ""
			require("libfox.foxhttp")
			html = gethtml(realpageurl)  -- 下载页面
			html = html2utf8(html, realpageurl) -- 判断网页编码并转成utf-8
			if string.match(realpageurl, '%.qidian%.com/') then
				require("libfox.siteqidian")
				text = qidian_GetContent(html)
			else
				require("libfox.foxnovel")
				text = getPageText(html)
			end
			html = nil
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

	closeAndSaveFML(shelf, shelfFilePath)
print("##  " .. shelfName .. "  DONE  GOT " .. allNewCount .. " NewPages")


