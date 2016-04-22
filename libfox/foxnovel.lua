#! /usr/bin/lua

--- {
-- { 通用函数

-- 读取文件到变量中
function fileread(iFilePath)
	local f = assert(io.open(iFilePath, "r"))
	local nr = f:read("*all")
	f:close()
	return nr
end

-- 写变量到文件中
function filewrite(nr, oFilePath)
	local f = assert(io.open(oFilePath, "w"))
	f:write(nr)
	f:close()
end

-- URL地址的合成
function getFullURL(iNowUrl, iBaseUrl)
	if string.match(iNowUrl, '^http://') then
		return iNowUrl
	end
	if string.match(iNowUrl, '^/')then
		return string.match(iBaseUrl, '(http://[^/]-)/') .. iNowUrl
	else
		return string.match(iBaseUrl, '(http://.*/)[^/]-') .. iNowUrl
	end
end

-- 判断是否是 Linux 环境
--[[
function isLinux()
	-- if nil == string.match(package.path, '/') then
	if nil == string.match(os.getenv('PATH'), ';') then
		return true
	else
		return false
	end
end
--]]

-- 根据客户端判断正文字体大小
function getContentSize()
	if nil == string.match(os.getenv('HTTP_USER_AGENT'), 'Android') then
		return 22  -- Not Android
	else
		return 18  -- Android
	end
end

-- } 通用函数

-- { 小说链接分析: getIndexs(html) 返回数组，元素{"l"=url, "n"=name}

-- 分析链接
function getlink(strstr)
	local linkLenCount = {}
	local ff = {}
	local i=1
	--星号(*)和横线(-)的主要差别是，星号总是试图匹配更多的字符，而横线则总是试图匹配最少的字符
	for l,n in string.gmatch(strstr, '<a[^>]-href=[\"|\']([^\"\']-)[\"|\'][^>]->([^<]*)<') do
		local ll = {}
		local len = string.len(l)
		ll["l"] = l
		ll["n"] = n
		ll["len"] = len
		if nil == linkLenCount[len] then
			linkLenCount[len] = 0
		end
		linkLenCount[len] = linkLenCount[len] + 1

		ff[i]=ll
		i=i+1
	end 
	return ff,linkLenCount
end

-- 获取统计表中的最多链接长度的长度
function getMaxLinkLen(iHash)
	local maxLen = 0
	local maxCount = 0
	for k,v in pairs(iHash) do 
		if v > maxCount then
			maxCount = v
			maxLen = k
		end
	end
	return maxLen, maxCount
end

-- 获取开始到结束要删除的行号范围
function getDelRowNum(iList, maxLinkLen)
	local minLen = maxLinkLen - 2  -- 最小长度值，这个值可以调节
	local maxLen = maxLinkLen + 2  -- 最大长度值，这个值可以调节
	local startDelRowNum = 0         -- 开始删除的行
	local endDelRowNum = 9 + #iList  -- 结束删除的行
	local nowLen = 1
	-- 只找链接的一半，前半是找开始行，后半是找结束行
	local halfLink = #iList / 2
	-- 找开始
	for j=1, halfLink do 
		nowLen = iList[j]["len"]
		if nowLen > maxLen then
			startDelRowNum = j
		elseif nowLen < minLen then
			startDelRowNum = j
		elseif ( iList[j+1]["len"] - nowLen ) > 1 or ( iList[j+1]["len"] - nowLen ) < 0 then
			startDelRowNum = j
		end
	end
	-- 找结束
	for j=#iList, halfLink, -1 do 
		nowLen = iList[j]["len"]
		if nowLen > maxLen then
			endDelRowNum = j
		elseif nowLen < minLen then
			endDelRowNum = j
		elseif ( nowLen - iList[j-1]["len"] ) > 1 or ( nowLen - iList[j-1]["len"] ) < 0 then
			endDelRowNum = j
		end
	end
	return startDelRowNum, endDelRowNum
end

-- 小说链接分析
function getIndexs(html)
	local gg, hh=getlink(html)
	html=nil
	local xkd,slkd = getMaxLinkLen(hh)
	--	print("最多长度:", xkd, "链接数量:", slkd)

	-- 删除头部多余的链接: 规律:长度递增
	local startDelRowNum, endDelRowNum = getDelRowNum(gg, xkd)
	--	print("开始删除行号:", startDelRowNum, "结束删除行号:", endDelRowNum)

	if endDelRowNum < #gg then
		for i=#gg, endDelRowNum, -1 do
			table.remove(gg, i)
		end
	end
	if startDelRowNum > 1 then
		for i=startDelRowNum, 1, -1 do
			table.remove(gg, i)
		end
	end
	return gg
end

-- } 小说链接分析: getIndexs(html) 返回数组，元素{"l"=url, "n"=name}

-- { 通用获取网页文本内容，就是最长的<div>中的内容
function getPageText(html)
	-- 获取 body标签中间的编码，body的大小写怎么处理?
	local c = string.match(html, '<body[^>]->(.*)</body>')
	if nil == c or "" == c then
		c = html
	end

	-- 替换无用标签，可根据需要自行添加
	c = string.gsub(c, '<script[^>]->.-</script>', '')
	c = string.gsub(c,  '<style[^>]->.-</style>' , '')
--	c = string.gsub(c, '<!\-\-[^>]*\-\->', '')

	-- 下面这两个是必需的
	c = string.gsub(c, '[\r\n]*', '')
	c = string.gsub(c, '</div>', '</div>\n')

	-- 获取最长的 <div.*</div>\n 中的内容
	local maxLine = ''
	local maxLen = 0
	local nowLen = 0
--	for field in string.gmatch(c, '<div[^>]->(.-)</div>\n') do
	for field in string.gmatch(c, '([^\n]*)</div>\n') do
		nowLen = string.len(field)
		if nowLen > maxLen then
			maxLine = field
			maxLen = nowLen
		end
	end
	c = maxLine
	maxLine = nil

	if nil == c or "" == c then
		c = html
	end

	-- 替换内容里面的html标签
	c = string.gsub(c, '%c', '')  -- 删除所有控制字符
	c = string.gsub(c, '&nbsp;', ' ')
	c = string.gsub(c, '<a [^>]->.*</a>', '\n')

	c = string.gsub(c, '</p>', '\n')
	c = string.gsub(c, '<br%s-[/]-%s->', '\n')

	c = string.gsub(c, '<[^>]->', '') -- 删除所有标签

	c = string.gsub(c, '^[%s\n]*', '\n')
	c = string.gsub(c, '\n%s*', '\n')
	c = string.gsub(c, '\n\n', '\n')

	-- 删除头部多余的换行符
	if '\n' == string.sub(c, 1, 1) then
		c = string.sub(c, 2)
	end
	return c
end

-- } 通用获取网页文本内容，就是最长的<div>中的内容

-- 删除文本尾部乱七八糟的玩意儿
function delNouseText(text)
	local xx = string.match(text, '([\(（]?未完待续.*)$')
	if ( nil == xx ) then
		return text
	end
	if ( string.len(xx) < 500 ) then
		text = string.gsub(text, '[\(（]?未完待续.*$', '')
	end
	return text
end

--- }

