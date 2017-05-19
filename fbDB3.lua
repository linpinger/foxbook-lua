#! /usr/bin/lua

	local dbPath = "FoxBook.db3"
	if nil ~= arg[1] then dbPath = arg[1] end -- 命令行分析
	local bGetShelfFirst = true  -- 是否先下载书架比较得到新书？

	local dbName = string.match(dbPath, "([^\\/]*).db3")
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
require("libfox.foxdb3")

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

print("##  " .. dbPath .. "  START")

local upBooksList = {}
if bGetShelfFirst then
	require("libfox.siteshelfDB3")
	upBooksList = compareShelfToGetNew() -- 获取有新章的书列表,　返回的数组元素: -- bookid, bookname, bookurl, dellist
	if nil == upBooksList then
		upBooksList = getAllBooksToUpdate() 
		print('**  ' .. dbName .. ' Have ' .. #upBooksList .. ' Books Update, Maybe shelf isnot suport or no cookie')
	else
		if #upBooksList > 0 then
			print('**  ' .. dbName .. ' Shelf Have ' .. #upBooksList .. ' Books To Update')
		end
	end
	if 0 == #upBooksList then
		db3_close()
		print("##  " .. dbName .. "  Exit  No NewPages")
		os.exit(0)
	end
else
	upBooksList = getAllBooksToUpdate() 
	print('**  ' .. dbName .. ' Have ' .. #upBooksList .. ' Books To Update')
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
	do -- 通用站点
		html = gethtml(bookurl) -- 下载目录
		html = html2utf8(html, bookurl) -- 判断网页编码并转成utf-8
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
			local firstline = string.match(pageListInDB, '([^|]-)\|')
			local bFound = false
			for j=1, #gg do
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
		print('--  ' .. dbName .. " : " .. bookname .. " Have " .. #gg .. " NewPages")

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
				html = gethtml(realpageurl)  -- 下载页面
				html = html2utf8(html, realpageurl) -- 判断网页编码并转成utf-8

				text = getPageText(html)
				html = nil
			end
			-- } 不同站点下载页面
			local contentLen = math.ceil(string.len(text) / 3)
			db3_foxbook_addNewPage(pageurl, pagename, delNouseText(text), contentLen, bookid)

			if not isLinux then
				require("libfox.utf8gbk")
				pagename = utf8gbk(pagename, false)
			end
			print('++  ' .. dbName .. " : " .. i .. " : " .. pagename .. " Size: " .. contentLen)
		end -- } 逐章下载页面
	else -- 无新章节
		print('--  ' .. dbName .. " : " .. bookname .. " Have 0 NewPages")
	end
-- } 有新章节，下载
end
-- } 循环要更新的书
db3_exec('update page set charcount=length(Content)') -- 更新charcount，因为lua计算出来的貌似是字节数
db3_foxbook_sortBookDesc(true) -- 倒序排列
db3_close()

print("##  " .. dbName .. "  DONE  GOT " .. allNewCount .. " NewPages")


