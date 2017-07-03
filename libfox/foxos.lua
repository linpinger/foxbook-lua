#! /usr/bin/lua

-- 文件是否存在
function fileexist(path)
	local file = io.open(path, "rb")
	if file then file:close() end
	return file ~= nil
end

-- 读取文件到变量中
function fileread(iFilePath)
	local f = assert(io.open(iFilePath, "r"))
	local nr = f:read("*all")
	f:close()
	return nr
end

-- 写变量到文件中
function filewrite(nr, oFilePath)
	local f = assert(io.open(oFilePath, "wb"))
	f:write(nr)
	f:close()
end

-- 判断是否是 Linux 环境
--[[
function islinux()
	if nil == string.find(package.path, '/', 1, true) then  -- windows
		return false
	else -- linux
		return true
	end
end
--]]

function getFileName(filePath) -- 从路径获取文件名
	local fileName = string.match(filePath, '/([^/\\]+)$')
	if nil == fileName then
		fileName = string.match(filePath, '\\([^/\\]+)$')
		if nil == fileName then
			fileName = filePath
		end
	end
	return fileName
end

