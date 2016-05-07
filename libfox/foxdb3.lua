#! /usr/bin/lua

-- 为了方便，将env和conn定义为全局变量，为了避免和别的变量重名，重命名了一下

local tableCursors = {}  -- 全局cursor数组，在关闭数据库时显式的关闭，避免openwrt下无法自动关闭的问题

function db3_open(dbPath)
	local luasql = require "luasql.sqlite3"
	sqlite3_env = assert(luasql.sqlite3())
	sqlite3_conn = sqlite3_env:connect(dbPath)
end

--[[ -- 用法
for ID,NAME,URL in db3_rows("SELECT id,name,url from book") do
	print(ID, URL, NAME)
end
--]]

function db3_rows(sqlStr)
	local cursor = assert(sqlite3_conn:execute(sqlStr))
	table.insert(tableCursors, cursor)
	return function ()
		return cursor:fetch()
	end
end

function db3_exec(sqlStr)
	return sqlite3_conn:execute(sqlStr)
end

--[[
function db3_batcommit(sqlStr)
	sqlite3_conn:setautocommit(false)
	assert(sqlite3_conn:execute(sqlStr))
	sqlite3_conn:commit()
	assert(sqlite3_conn:execute(sqlStr))
	sqlite3_conn:commit()
end
--]]


function db3_close()
	if #tableCursors > 0 then
		for i, cc in ipairs(tableCursors) do
			cc:close()
		end
	end
	sqlite3_conn:close()
	sqlite3_env:close()
end

--[[
xdbPath = "FoxBook.db3"
sqlStr = "select id, name, url from book"

db3_open(xdbPath)

	local cursor = assert(sqlite3_conn:execute(sqlStr))
	local row = {}
	while cursor:fetch(row) do
		print(row[1], row[2], row[3])
--		print(table.concat(row, '--'))
	end
	cursor:close()

print('-----------------')

for ID,NAME,URL in db3_rows("SELECT id,name,url from book") do
	print(ID, URL, NAME)
end

db3_close()
--]]

-- http://www.cnblogs.com/windtail/archive/2012/01/08/2623191.html
-- lastInsertRowID = sqlite3_conn:getlastautoid()
-- tableColName = cursor:getcolnames()
-- tableColType = cursor:getcoltypes()

-- 以下是foxbook专用的数据库相关函数

function db3_foxbook_addNewPage(iURL, iName, iText, iBookID)
	sqlite3_conn:execute(string.format([[ insert into page(url, Name, Mark, Content, BookID, DownTime) values('%s', '%s', 'text', '%s', %d, '%s') ]], iURL, sqlite3_conn:escape(iName), sqlite3_conn:escape(iText), iBookID, os.date('%Y%m%d%H%M%S') ))
end

function ReGenID(bBook, bDesc, NowSQL)
	local tbID = {}
	local cursor = assert(sqlite3_conn:execute(NowSQL))
	local row = {}
	while cursor:fetch(row) do
		table.insert(tbID, row[1])
	end
	cursor:close()

	local StartID = 55555
	if bDesc then
		StartID = 55555
	else
		StartID = 1
	end
	for cc, OldID in ipairs(tbID) do
		local NewID = StartID
		if bBook then
			assert(sqlite3_conn:execute("update Book set ID = " .. NewID .. " where id = " .. OldID .. " ;"))
			assert(sqlite3_conn:execute("update page set bookid = " .. NewID .. " where bookid = " .. OldID .. " ;"))
		else
			assert(sqlite3_conn:execute("update Page set ID = " .. NewID .. " where ID = " .. OldID .. " ;"))
		end
		if bDesc then
			StartID = StartID - 1
		else
			StartID = StartID + 1
		end
	end
end

function db3_foxbook_sortBookDesc(bDesc)
	local order = "desc"
	if bDesc then
		order = "desc"
	else
		order = "asc"
	end
		
	sqlite3_conn:setautocommit(false)

	ReGenID(true, true, "select ID From Book order by ID Desc")
	sqlite3_conn:commit()

	ReGenID(true, false, "select book.ID from Book left join page on book.id=page.bookid group by book.id order by count(page.id) " .. order .. ",book.isEnd,book.ID")
	sqlite3_conn:commit()

	db3_exec("update Book set Disorder=ID")
	sqlite3_conn:commit()

	ReGenID(false, true,  "select ID from Page order by BookID,ID Desc")
	sqlite3_conn:commit()

	ReGenID(false, false, "select ID from Page order by BookID,ID")
	sqlite3_conn:commit()

	sqlite3_conn:setautocommit(true)
end

-- 删除指定书中的所有章节
function db3_foxbook_DeleteBookAllPages(iBookID)
	local bookid, bookname, dellist
	for ID,NAME,DelURL in db3_rows("SELECT id,name,DelURL from book where id = " .. iBookID) do
		bookid = ID
		bookname = NAME
		dellist = DelURL
	end
	for NAME, URL in db3_rows("SELECT name,url from page where bookid = " .. iBookID) do
		dellist = dellist .. URL .. "|" .. NAME .. "\n"
	end
	if nil == dellist then return end
	require "libfox.foxnovel"
	dellist = SimplifyDelList(dellist) -- 精简dellist
	sqlite3_conn:execute(string.format([[ update Book set DelURL='%s' where ID = %d ]], sqlite3_conn:escape(dellist), iBookID ))
	sqlite3_conn:execute("Delete From Page where bookid = " .. iBookID)
end

-- 清空所有有章节的书
function db3_foxbook_DeleteAllBookPages()
	for bookid in db3_rows("select distinct(bookid) from page") do
		db3_foxbook_DeleteBookAllPages(bookid)
	end
end

