
function getValue(inStr, inKey)
	local ret = string.match(inStr, "<" .. inKey .. ">(.-)</" .. inKey .. ">")
	if nil == ret then ret = "" end
	return ret
end

function loadCookie(cookiePath)
	local xml = fileread(cookiePath)
	local cookie = {}
	for tag in string.gmatch(xml, '<([^</>"]*)>') do
		if tag ~= 'cookies' then
			cookie[tag] = getValue(xml, tag)
		end
	end
	return cookie
end

function loadFML(fmlPath)
	require "libfox.foxnovel"
	local fml = fileread(fmlPath)
	local shelf = {}
	for bookStr in string.gmatch(fml, "<novel>(.-)</novel>") do
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

function saveFML(shelf, savePath)
	local fml = {}
	table.insert(fml, '<?xml version="1.0" encoding="utf-8"?>\n\n<shelf>\n')
	for i, book in ipairs(shelf) do
		table.insert(fml, '<novel>')
		table.insert(fml, '\t<bookname>' .. book.bookname .. '</bookname>')
		table.insert(fml, '\t<bookurl>' .. book.bookurl .. '</bookurl>')
		table.insert(fml, '\t<delurl>' .. book.delurl .. '</delurl>')
		table.insert(fml, '\t<statu>' .. book.statu .. '</statu>')
		table.insert(fml, '\t<qidianBookID>' .. book.qidianBookID .. '</qidianBookID>')
		table.insert(fml, '\t<author>' .. book.author .. '</author>')
		table.insert(fml, '<chapters>')
		for j, page in ipairs(book.chapters) do
			table.insert(fml, '<page>')
			table.insert(fml, '\t<pagename>' .. page.pagename .. '</pagename>')
			table.insert(fml, '\t<pageurl>' .. page.pageurl .. '</pageurl>')
			table.insert(fml, '\t<content>' .. page.content .. '</content>')
			table.insert(fml, '\t<size>' .. page.size .. '</size>')
			table.insert(fml, '</page>')
		end
		table.insert(fml, '</chapters>')
		table.insert(fml, '</novel>\n')
	end
	table.insert(fml, '</shelf>\n')
	require "libfox.foxnovel"
	filewrite(table.concat(fml, '\n'), savePath)
end


-- shelf = loadFML("FoxBook.fml")
-- print("Book Count=" .. #shelf)
-- saveFML(shelf, "new.fml")

