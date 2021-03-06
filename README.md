# FoxBook(狐狸的小说下载阅读及转换工具) Lua 命令行版

**名称:** FoxBook

**功能:** 狐狸的小说下载阅读及转换工具(更新小说站小说)

**作者:** 爱尔兰之狐(linpinger)

**邮箱:** <mailto:linpinger@gmail.com>

**主页:** <http://linpinger.github.io?s=FoxBook-Lua_MD>

**缘起:** 用别人写的工具，总感觉不能随心所欲，于是自己写个下载管理工具，基本能用，基本满意

**原理:** 下载网页，分析网页，文本保存在数据库中

**亮点:** 

- 2017-5-4: linux下只需lua主程序与wget即可，不依赖其他库，另外可使用lua5.1/5.2/5.3运行
- 这个Lua版本，自己写了GBK与UTF-8互转的函数，不需要iconv了，以适应openwrt下iconv无法转换GBK的问题
- 通用小说网站规则能覆盖大部分文字站的目录及正文内容分析，不需要针对每个网站的规则
- 本版本是用Lua脚本语言开发的，所以可以在 win/linux/mac 下运行
- 和之前的[AHK版][foxbook-ahk](win专用/linux下wine)，[Android版][foxbook-android]使用同一个数据库

**提示:** 本版本仅能快速更新数据库，目前不具备其他功能，制作这个版本的目的是为了方便linux下快速更新的需求，ahk版需要wine，java需要jre太庞大，所以搞出这个版本以填补空缺

**源码及下载:**

- [源码工程](https://github.com/linpinger/foxbook-lua)

- [文件下载点1:baidu][pan_baidu]

**安装及使用方法:**
- fbDB3.lua 版本不再维护，请使用 fbFML.lua
- 先到[LuaDist](http://luadist.org/) 下载win版或linux64版或mac版
- 解压压缩文件到 D:\bin\Lua 下，此时Lua文件夹下应有bin include lib share 文件夹
- 下载源码解压到 D:\bin\Lua 下，应多出 libfox文件夹 fbDB3.lua fbFML.lua 文件
- 2016-12-29: 这两个版本是区别 DB3和FML格式的，书架的cookie文件应保存在 FoxBook.cookie文件中，格式: <cookie><sitename>cookieStr</sitename><sitename>another CookieStr</sitename></cookie>
- 命令行下使用以下命令更新

```Lua
D:\bin\lua\bin\lua.exe D:\bin\Lua\fbDB3.lua D:\xxx\FoxBook.db3
D:\bin\lua\bin\lua.exe D:\bin\Lua\fbFML.lua D:\xxx\FoxBook.fml
```
- 2017-5-4: linux/mingw下使用源码编译单文件lua方法，先到官网下载所有源码合计包，进入相对应的版本文件夹，make即可得到lua程序，可以复制出来使用，这个自己编译的依赖最小

**其他小提示:**

- linux32版的luadist版本可能会在[baidu网盘][pan_baidu]提供，其实编译方法已经在[这篇日志](http://linpinger.github.io/usr/2016-03-30_Lua.html)里说明了，如果有小伙伴要可以发邮件找我
- 各小说站(目前只支持13xs,biquge,dajiadu,qreader)，注册账号，然后将自己的小说添加到书架，然后用IE导出cookie，填入数据库的config表中的cookie字段，site字段就是网址类似http://www.biquge.com.tw
- fbDB3.lua默认先比较书架与数据库的差异，可以修改fbDB3.lua关闭这功能，也就是修改 local bGetShelfFirst = true 为 local bGetShelfFirst = false
- 可以使用多开进程更新多个数据库，速度杠杠滴
- win下单cmd多进程运行
```shell
cmd /c start /b D:\bin\lua\bin\lua.exe D:\bin\Lua\fbDb3.lua FoxBook.db3 & start /b D:\bin\lua\bin\lua.exe D:\bin\Lua\fbDb3.lua biquge.db3 & start /b D:\bin\lua\bin\lua.exe D:\bin\Lua\fbDb3.lua dajiadu.db3 & start /b D:\bin\lua\bin\lua.exe D:\bin\Lua\fbDb3.lua qreader.db3
```
- linux下多进程运行
```shell
for iDB in *.db3 ; do
	lua /root/bin/fbDB3.lua $iDB &
done
```


**工程中包含的其他文件:**

- [lunajson](https://github.com/grafi-tt/lunajson) 这个是纯lua写的json解析库


**更新日志:**
- 2017-06-30: 替换string.match为string.find避免特殊字符的转义，foxhttp添加get/post文件函数
- 2017-06-05: 各版本修改起点接口
- 2017-05-19: 大修改，和python版流程大体相同
- 2017-05-04: 添加书架，重写读取cookie函数
- 2017-05-04: 修改bug，添加书架，修改以适配win/linux/openwrt，现fbFML.lua可不依赖第三方库(socket,sqlite3,lfs)，在linux下只需lua及wget可执行文件即可，不需依赖其他
- 2017-01-10: 添加功能: 命令行列出书/章，清空书
- 2017-01-06: 更名xml为fml
- 2017-01-03: 移除无用的标签bookloc,pageloc
- 2016-12-29: 将fb.lua更名为 fbDB3.lua，新增 fbXML.lua 以适应新版采用xml作为存储格式，更好跨平台，现可只依赖socket(亦可使用wget替代，以达到只需要lua主程序即可运行)
- 2016-10-13: http库 设置timeout=5s，发现原来可以直接设置UserAgent，不用拐太多弯，可以先留着
- 2016-06-05: 修复一个无cookie的bug以及提示文字
- 2016-05-19: 添加ebook.lua库，它就是用来制作epub/mobi的，呵呵呵，源码里面有栗子，遗憾的是kindlegen木有openwrt版的，否则就完美了
- 2016-05-09: 重写utf8和gbk互转函数，内存是原来的一半，速度是原来的三倍，在OpenWRT下应该可以同时开几个进程了
- 2016-05-07: 调整require顺序以减少内存使用，尤其是g2u或u2g函数，添加: 删除已读章节的函数
- 2016-04-29: 修复一个url的小bug，添加msn.qidian.com支持
- 2016-04-27: 为适应OpenWRT，现移除curl库，使用socket.http代替实现，移除iconv库（openwrt下的iconv不支持中文转换），使用table来实现gbk与utf-8之间的转换
- 2016-04-22: 第一个发布版本
- ...: 懒得写了，就这样吧


[foxbook-ahk]: https://github.com/linpinger/foxbook-ahk
[foxbook-android]: https://github.com/linpinger/foxbook-android
[pan_baidu]: http://pan.baidu.com/s/1bnqxdjL "百度网盘共享"

