#! /usr/bin/lua

-- function qidian_GetIndex(dbBookUrl) end

function qidian_GetContent(BkURL, PgURL) -- _, ReadChapter.aspx?bookid=1003290088&chapterid=306910701
	require("libfox.foxhttp")
	require("libfox.gbk2u")
	local bookid, pageid = string.match(PgURL, 'bookid=([0-9]*)&chapterid=([0-9]*)')
	local pageurl = "http://files.qidian.com/Author" .. ( 1 + math.fmod(tonumber(bookid), 8) ) .. "/" .. bookid .. "/" .. pageid .. ".txt"

	local html = ''
	local downTry = 0
	while downTry < 4 do
		html, httpok = gethtml(pageurl) -- 下载章节
		if 200 == httpok then break end
		downTry = downTry + 1
		print("warn: downPage retry:", downTry, string.len(html))
	end
	html = g2u(html)
	html = string.gsub(html, "document.write%(%'", '')
	html = string.gsub(html, "%'%);", '')
	html = string.gsub(html, "<p>", '\n')
	html = string.gsub(html, "<a href=http://www.qidian.com>起点中文网 www.qidian.com 欢迎广大书友光临阅读，最新、最快、最火的连载作品尽在起点原创！</a>", '')
	html = string.gsub(html, "<a>手机用户请到m.qidian.com阅读。</a>", '')
	html = string.gsub(html, '　　', '')  -- 删除所有空白
	if '\n' == string.sub(html, 1, 1) then html = string.sub(html, 2) end -- 删除头部多余的换行符
	return html
end

--[[
bookurl = "http://read.qidian.com/BookReader/aB6G8TfI_5PVl9ByXxZ_TQ2.aspx"
bookurl = "http://msn.qidian.com/ReadBook.aspx?bookid=1003290088"
text = qidian_GetContent(nil, 'ReadChapter.aspx?bookid=1003290088&chapterid=306910701')
--]]


