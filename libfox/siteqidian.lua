#! /usr/bin/lua

function qidian_GetIndex(json)
	toc = {}
	local bookid = string.match(json, '"BookId":([0-9]+),')
	local urlHead = "http://files.qidian.com/Author" .. ( 1 + math.fmod(tonumber(bookid), 8) ) .. "/" .. bookid .. "/"

	for cc,nn,vv in string.gmatch(json, '"c":([0-9]+),"n":"([^"]+)".-"v":([01]),') do
		local lk = {}
		lk["l"] = urlHead .. cc .. ".txt"
		lk["n"] = nn
		lk["len"] = string.len(lk["l"])
		if '0' == vv then
			table.insert(toc, lk)
		end
	end
	return toc
end

function qidian_GetContent(html) -- _, ReadChapter.aspx?bookid=1003290088&chapterid=306910701
	html = string.gsub(html, "document.write%(%'", '')
	html = string.gsub(html, "%'%);", '')
	html = string.gsub(html, "<p>", '\n')
	html = string.gsub(html, "<a href=http://www.qidian.com>起点中文网 www.qidian.com 欢迎广大书友光临阅读，最新、最快、最火的连载作品尽在起点原创！</a>", '')
	html = string.gsub(html, "<a>手机用户请到m.qidian.com阅读。</a>", '')
	html = string.gsub(html, '　　', '')  -- 删除所有空白
	if '\n' == string.sub(html, 1, 1) then html = string.sub(html, 2) end -- 删除头部多余的换行符
	return html
end

