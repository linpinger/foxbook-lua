
function getValue(inStr, inKey)
	local ret = string.match(inStr, "<" .. inKey .. ">(.-)</" .. inKey .. ">")
	if nil == ret then ret = "" end
	return ret
end

function loadCookie(cookiePath)
	require "libfox.foxnovel"
	local xml = fileread(cookiePath)
	local cookie = {}
	cookie.site13xs = getValue(xml, "13xs")
	cookie.sitebiquge = getValue(xml, "biquge")
	cookie.sitedajiadu = getValue(xml, "dajiadu")
	return cookie
end

function loadXML(xmlPath)
	require "libfox.foxnovel"
	local xml = fileread(xmlPath)
	local shelf = {}
	for bookStr in string.gmatch(xml, "<novel>(.-)</novel>") do
		local book = {}
		book.bookname   = getValue(bookStr, "bookname")
		book.bookurl    = getValue(bookStr, "bookurl")
		book.delurl = getValue(bookStr, "delurl")
		book.statu = getValue(bookStr, "statu")
		book.qidianBookID   = getValue(bookStr, "qidianBookID")
		book.author = getValue(bookStr, "author")

		local pages = {}
		for pageStr in string.gmatch(bookStr, "<page>(.-)</page>") do
			local page = {}
			page.pagename    = getValue(pageStr, "pagename")
			page.pageurl     = getValue(pageStr, "pageurl")
			page.size    = getValue(pageStr, "size")
			page.content = getValue(pageStr, "content")
			table.insert(pages, page)
		end -- pageStr
		book.chapters = pages
		table.insert(shelf, book)
	end -- bookstr
	return shelf
end

function saveXML(shelf, savePath)
	local xml = {}
	table.insert(xml, '<?xml version="1.0" encoding="utf-8"?>\n\n<shelf>\n')
	for i, book in ipairs(shelf) do
		table.insert(xml, '<novel>')
		table.insert(xml, '\t<bookname>' .. book.bookname .. '</bookname>')
		table.insert(xml, '\t<bookurl>' .. book.bookurl .. '</bookurl>')
		table.insert(xml, '\t<delurl>' .. book.delurl .. '</delurl>')
		table.insert(xml, '\t<statu>' .. book.statu .. '</statu>')
		table.insert(xml, '\t<qidianBookID>' .. book.qidianBookID .. '</qidianBookID>')
		table.insert(xml, '\t<author>' .. book.author .. '</author>')
		table.insert(xml, '<chapters>')
		for j, page in ipairs(book.chapters) do
			table.insert(xml, '<page>')
			table.insert(xml, '\t<pagename>' .. page.pagename .. '</pagename>')
			table.insert(xml, '\t<pageurl>' .. page.pageurl .. '</pageurl>')
			table.insert(xml, '\t<content>' .. page.content .. '</content>')
			table.insert(xml, '\t<size>' .. page.size .. '</size>')
			table.insert(xml, '</page>')
		end
		table.insert(xml, '</chapters>')
		table.insert(xml, '</novel>\n')
	end
	table.insert(xml, '</shelf>\n')
	require "libfox.foxnovel"
	filewriteB(table.concat(xml, '\n'), savePath)
end


-- shelf = loadXML("FoxBook.xml")
-- print("Book Count=" .. #shelf)
-- saveXML(shelf, "new.xml")

