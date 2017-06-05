#! /usr/bin/lua

function qidian_GetIndex(json)
	toc = {}
	local bookid = string.match(json, '"BookId":([0-9]+),')
--	local urlHead = "http://files.qidian.com/Author" .. ( 1 + math.fmod(tonumber(bookid), 8) ) .. "/" .. bookid .. "/"
	local urlHead = "GetContent?BookId=" .. bookid .. "&ChapterId="

	for cc,nn,vv in string.gmatch(json, '"c":([0-9]+),"n":"([^"]+)".-"v":([01]),') do
		local lk = {}
		lk["l"] = urlHead .. cc
		lk["n"] = nn
		lk["len"] = string.len(lk["l"])
		if '0' == vv then
			table.insert(toc, lk)
		end
	end
	return toc
end

function qidian_GetContent(json)
	local content = string.match(json, '"Data":"([^"]+)"')
	content = string.gsub(content, '\\r\\n　　', '\n')
	content = string.gsub(content, '　　', '\n')
	if '\n' == string.sub(content, 1, 1) then content = string.sub(content, 2) end -- 删除头部多余的换行符
	return content
end

