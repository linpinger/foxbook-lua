#! /usr/bin/lua

-- { 设置 系统中必须存在 kindlegen 和 zip，检测方法就是开命令行，输入这两个命令，如果显示未找到，就要将这两程序放到PATH所在目录，例如C:\windows /usr/bin
-- 添加的网页内容编码必须是UTF-8
-- 在 tmpdir中生成 FoxMake.mobi/epub，执行完后自行移走
ebook = {
	bookname="如是我闻",
	author="佛",
	creator="FoxBookLua",
	format="mobi",
	tmpdir="C:\\etc",
	tmpdirname="FoxEpubTmp",
	tmprootdir= "C:\\etc\\FoxEpubTmp\\",
	htmldirname="html",
	bookuuid="",
	defname="foo",
	chapter = {},
	ostype="win",
	osPathSep="\\",
	deltmpfiles=true
}
-- format:指生成的格式，支持mobi/epub
-- } 设置

-- { 写变量到文件中
function writeto(nr, oFilePath)
	local f = assert(io.open(oFilePath, "w"))
	f:write(nr)
	f:close()
end
-- } 写变量到文件中

-- { 生成guid
function guid()
--	math.randomseed(os.time())
	local seed = {'0', '2', '1', '3', '5', '4', '6', '7', '9', '8', 'a', 'b', 'c', 'd', 'e', 'f'}
	local tb = {}
	for i=1, 32 do
		table.insert(tb, seed[math.random(1,16)])
	end
	local sid = table.concat(tb)
	return string.format('%s-%s-%s-%s-%s',
		string.sub(sid, 1, 8),
		string.sub(sid, 9, 12),
		string.sub(sid, 13, 16),
		string.sub(sid, 17, 20),
		string.sub(sid, 21, 32)
	)
end
-- } 生成guid

-- { 操作系统检测
function osdetect()
	if nil == string.match(package.path, '/') then
		ebook.ostype = "win"
		ebook.osPathSep="\\"
	else
		ebook.ostype = "linux"
		ebook.osPathSep="/"
	end
end
-- } 操作系统检测

-- { init
function ebook_new(bookname)
	if nil ~= bookname then ebook.bookname = bookname end

	math.randomseed(os.time())
	ebook.bookuuid = guid()

	osdetect()
	ebook.tmprootdir = ebook.tmpdir .. ebook.osPathSep .. ebook.tmpdirname .. ebook.osPathSep
	if "win" == ebook.ostype then
		os.execute('mkdir ' .. ebook.tmprootdir .. ebook.htmldirname)
		os.execute('mkdir ' .. ebook.tmprootdir .. "META-INF")
	end
	if "linux" == ebook.ostype then
		os.execute('mkdir -p ' .. ebook.tmprootdir .. ebook.htmldirname)
		os.execute('mkdir -p ' .. ebook.tmprootdir .. "META-INF")
	end
end
-- } init

-- { addchapter
function ebook_addchapter(inTitle, htmlContent)
	table.insert(ebook.chapter, inTitle)

	local html = {'<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh-CN">'}
	table.insert(html, '<head>')
	table.insert(html, '\t<title>' .. inTitle .. '</title>')
	table.insert(html, '\t<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />')
	table.insert(html, '\t<style type="text/css">')
	table.insert(html, '\t\th2,h3,h4{text-align:center;}')
	table.insert(html, '\t\tp { text-indent: 2em; line-height: 0.5em; }')
	table.insert(html, '\t</style>')
	table.insert(html, '</head>')
	table.insert(html, '<body>')
	table.insert(html, '<h4>' .. inTitle .. '</h4>')
	table.insert(html, '<div class="content">')
	table.insert(html, htmlContent)
	table.insert(html, '</div>')
	table.insert(html, '</body>')
	table.insert(html, '</html>\n')
	writeto(table.concat(html, '\n'), ebook.tmprootdir .. ebook.htmldirname .. ebook.osPathSep .. #ebook.chapter .. ".html")
end
-- } addchapter

function local_createMiscFiles()
	writeto("application/epub+zip", ebook.tmprootdir .. "mimetype")
	writeto('<?xml version="1.0"?>\n<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">\n\t<rootfiles>\n\t\t<rootfile full-path="FoxMake.opf" media-type="application/oebps-package+xml"/>\n\t</rootfiles>\n</container>', ebook.tmprootdir .. "META-INF" .. ebook.osPathSep .. "container.xml")
end

function local_createIndexHTM()
	local html = {'<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh-CN">'}
	table.insert(html, '<head>')
	table.insert(html, '\t<title>' .. ebook.bookname .. '</title>')
	table.insert(html, '\t<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />')
	table.insert(html, '\t<style type="text/css">h2,h3,h4{text-align:center;}</style>')
	table.insert(html, '</head>')
	table.insert(html, '<body>')
	table.insert(html, '<h2>' .. ebook.bookname .. '</h2>')
	table.insert(html, '<div class="toc">')
	for i, title in ipairs(ebook.chapter) do
		table.insert(html, '<div><a href="' .. ebook.htmldirname .. '/' .. i .. '.html">' .. title .. '</a></div>')
	end
	table.insert(html, '</div>')
	table.insert(html, '</body>')
	table.insert(html, '</html>\n')
	writeto(table.concat(html, '\n'), ebook.tmprootdir .. "FoxMake.htm")
end

function local_createNCX()
	local html = {'<?xml version="1.0" encoding="UTF-8"?>'}
	table.insert(html, '<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">')
	table.insert(html, '<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="zh-cn">')
	table.insert(html, '<head>')
	table.insert(html, '\t<meta name="dtb:uid" content="' .. ebook.bookuuid .. '"/>')
	table.insert(html, '\t<meta name="dtb:depth" content="1"/>')
	table.insert(html, '\t<meta name="dtb:totalPageCount" content="0"/>')
	table.insert(html, '\t<meta name="dtb:maxPageNumber" content="0"/>')
	table.insert(html, '\t<meta name="dtb:generator" content="' .. ebook.creator .. '"/>')
	table.insert(html, '</head>')
	table.insert(html, '<docTitle><text>' .. ebook.bookname .. '</text></docTitle>')
	table.insert(html, '<docAuthor><text>' .. ebook.author .. '</text></docAuthor>')
	table.insert(html, '<navMap>')
	table.insert(html, '\t<navPoint id="toc" playOrder="1"><navLabel><text>目录:' .. ebook.bookname .. '</text></navLabel><content src="FoxMake.htm"/></navPoint>')
	for i, title in ipairs(ebook.chapter) do
		table.insert(html, '\t<navPoint id="' .. tostring(i) .. '" playOrder="' .. tostring( i + 1 ) .. '"><navLabel><text>' .. title .. '</text></navLabel><content src="' .. ebook.htmldirname .. '/' .. i .. '.html"/></navPoint>')
	end
	table.insert(html, '</navMap>')
	table.insert(html, '</ncx>\n')
	writeto(table.concat(html, '\n'), ebook.tmprootdir .. "FoxMake.ncx")
end

function local_createOPF()
	local html = {'<?xml version="1.0" encoding="UTF-8"?>'}
	table.insert(html, '<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="FoxUUID">')
	table.insert(html, '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">')
	table.insert(html, '\t<dc:title>' .. ebook.bookname .. '</dc:title>')
	table.insert(html, '\t<dc:identifier opf:scheme="uuid" id="FoxUUID">' .. ebook.bookuuid .. '</dc:identifier>')
	table.insert(html, '\t<dc:creator>' .. ebook.creator .. '</dc:creator>')
	table.insert(html, '\t<dc:publisher>' .. ebook.creator .. '</dc:publisher>')
	table.insert(html, '\t<dc:language>zh-cn</dc:language>')
	if ebook.format == "mobi" then
		table.insert(html, '\t<x-metadata><output encoding="utf-8"></output></x-metadata>') -- MobiOnly
	end
	table.insert(html, '</metadata>')
	table.insert(html, '<manifest>')
	table.insert(html, '\t<item id="FoxNCX" media-type="application/x-dtbncx+xml" href="FoxMake.ncx" />')
	table.insert(html, '\t<item id="FoxIDX" media-type="application/xhtml+xml" href="FoxMake.htm" />')
	for i, title in ipairs(ebook.chapter) do
		table.insert(html, '\t<item id="page' .. i .. '" media-type="application/xhtml+xml" href="' .. ebook.htmldirname .. '/' .. i .. '.html" />')
	end
	table.insert(html, '</manifest>')
	table.insert(html, '<spine toc="FoxNCX">')
	table.insert(html, '\t<itemref idref="FoxIDX" />')
	for i, title in ipairs(ebook.chapter) do
		table.insert(html, '\t<itemref idref="page' .. i .. '" />')
	end
	table.insert(html, '</spine>')
	table.insert(html, '<guide>')
	table.insert(html, '\t<reference type="text" title="正文" href="' .. ebook.htmldirname .. '/1.html"/>')
	table.insert(html, '\t<reference type="toc" title="目录" href="FoxMake.htm"/>')
	table.insert(html, '</guide>')
	table.insert(html, '</package>\n')
	writeto(table.concat(html, '\n'), ebook.tmprootdir .. "FoxMake.opf")
end

-- { build
function ebook_build()
	local_createMiscFiles()
	local_createIndexHTM()
	local_createNCX()
	local_createOPF()

	local tmpDrv = "D:"
	if "win" == ebook.ostype then tmpDrv = string.sub(ebook.tmprootdir, 1, 2) end
	-- 调用kindlegen/zip生成mobi/epub
	if ebook.format == "mobi" then
		if "win" == ebook.ostype then
			os.execute(tmpDrv .. ' && cd "' .. ebook.tmprootdir .. '" && kindlegen FoxMake.opf')
			os.execute(tmpDrv .. ' && cd "' .. ebook.tmprootdir .. '" && move /Y FoxMake.mobi ..')
		end
		if "linux" == ebook.ostype then os.execute('cd "' .. ebook.tmprootdir .. '" && kindlegen FoxMake.opf && mv -f FoxMake.mobi ..') end
	end
	if ebook.format == "epub" then
		if "win" == ebook.ostype then
			os.execute(tmpDrv .. ' && cd "' .. ebook.tmprootdir .. '" && zip -0Xq ../FoxMake.epub mimetype && zip -Xr9Dq ../FoxMake.epub *')
		end
		if "linux" == ebook.ostype then
			os.execute('cd "' .. ebook.tmprootdir .. '" && zip -0Xq ../FoxMake.epub mimetype && zip -Xr9Dq ../FoxMake.epub *')
		end
	end

	if ebook.deltmpfiles then
		if "win" == ebook.ostype then os.execute('rmdir /s /q ' .. ebook.tmprootdir) end
		if "linux" == ebook.ostype then os.execute('rm -fr ' .. ebook.tmprootdir) end
	end
	ebook = {}
end
-- } build

--[[ -- { main

ebook.tmpdir = 'c:\\etc'
ebook.format = 'epub'
ebook_new("HelloWorld")

ebook_addchapter("foo", "你好：<br/>\n萌萌哒<br/>\n")
ebook_addchapter("bar", "很好：<br/>\n萌萌哒<br/>\n")

ebook_build()

--]] -- } main

--[[ -- { example:db3toebook
local dbPath = 'FoxBook.db3'
require('libfox.foxdb3')
db3_open(dbPath)

require('libfox.ebook')
ebook.tmpdir = 'D:\\tmp'
-- ebook.format = 'epub'
ebook_new("all_lua")

for tt, cc in db3_rows("SELECT name,content from page order by bookid, id") do
	ebook_addchapter(tt, '　　' .. string.gsub(cc, '\n', '<br/>\n　　') .. '<br/>\n')
end
db3_close()

ebook_build()
--]] -- } example:db3toebook

