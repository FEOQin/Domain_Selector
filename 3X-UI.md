3XUI节点搭建

3X-UI是一个非常流行的代理面板，支持Xray和Hysteria核心，可以让我们通过一个网页界面来轻松管理和创建各种代理节点，而不需要手动去写复杂的配置文件。

安装3X-UI
官方提供了一键安装脚本，我们直接在vps的终端里运行就行。
复制下面的命令，粘贴到你的powershell终端里回车。
>bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

安装过程中，脚本会自动处理所有依赖。
它会问你要不要自定义，输入`n`回车即可。
然后回进入一个英文菜单，我这里给出翻译，可以参考。
核心操作
1. Install: 1. 安装
2. Update: 2. 更新面板
3. Update Menu: 3. 更新此菜单脚本
4. Legacy Version: 4. 安装旧版本
5. Uninstall: 5. 卸载
6. Reset Username & Password: 6. 重置用户名和密码
7. Reset Web Base Path: 7. 重置面板访问路径
8. Reset Settings: 8. 重置所有设置
9.  Change Port: 9. 更改面板端口
10. View Current Settings: 10. 查看当前设置
11.  Start: 11. 启动面板服务
12. Stop: 12. 停止面板服务
13. Restart: 13. 重启面板服务
14. Check Status: 14. 检查运行状态
15. Logs Management: 15. 日志管理
16.  Enable Autostart: 16. 启用开机自启
17. Disable Autostart: 17. 禁用开机自启
18.  SSL Certificate Management: 18. SSL 证书管理
19. Cloudflare SSL Certificate: 19. Cloudflare SSL 证书
20. IP Limit Management: 20. IP 限制管理
21. Firewall Management: 21. 防火墙管理
22. SSH Port Forwarding Management: 22. SSH 端口转发管理
23.  Enable BBR: 23. 启用 BBR (网络加速)
24. Update Geo Files: 24. 更新 GeoIP/GeoSite 数据库文件
25. Speedtest by Ookla: 25. 使用 Ookla 进行速度测试

再次进入菜单的方法：输入 `x-ui`

安装好后会显示你的登录信息。

Username: vVdBnQslcW 账号
Password: 0C3NISs5F1 密码
Port: 4949           访问端口号 
WebBasePath: Y52GmVbxHs33iwQEVo          路径
Access URL: http://123.456.789.1011:4949/Y52GmVbxHs33iwQEVo    登录网址，但先不要登录。

注意看，登录网址是以http://开头的，说明目前是http协议，如果直接登录，账号、密码、网址都将暴露在明文下，任何一个传输你流量的中间人都会知道你访问的内容是什么，尤其是GFW。

因此我们要用一个安全的方法来登录。
常用方法有：
如果有域名，那么可以申请证书开启https，这样流量就会被加密，除了你和你的vps,没人知道你们传输了什么。
或者可以使用tunnel隧道传输，比如大善人cloudflare tunnel，http流量会被cloudflared加密，然后传输到cloudflare骨干网，由cloudflare进行https加密，更加安全。
如果没有域名的话，也可以使用SSH隧道，这也是本教程介绍的方法。

使用SSH隧道加密访问3xui面板
SSH是常用的加密协议，我们之前进行的所有命令行操作，都是经过SSH加密的。
首先，不要在已登录的SSH会话里执行这个命令。请在您的Windows电脑上，打开一个新的PowerShell窗口，然后执行以下命令：

ssh -o ServerAliveInterval=60 -L 本地端口:127.0.0.1:面板端口 用户名@服务器IP -p SSH端口 -i "私钥文件路径"

举例：
ssh -o ServerAliveInterval=60 -L 8080:127.0.0.1:4949 root@123.456.789.1011 -p 12345 -i "C:\Users\ccxkai\.ssh\XXX"

执行命令后，保持这个PowerShell窗口不要关闭。
然后打开你的浏览器，访问：
http://localhost:8080/Y52GmVbxHs33iwQEVo     这里替换为你的路径

看见这个页面，就说明成功了，用账号密码登录即可。
C:\Users\ccxkai\Documents\常用资料\VPS加固及代理搭建教程\images\3xui欢迎界面.png

进入之后，会看到警告：
```
安全警报
此连接不安全。在激活 TLS 进行数据保护之前，请勿输入敏感信息。
```
这是正常现象，3xui不知道我们是通过ssh加密隧道进行连接的，无视即可。
下面我们开始搭建节点。
C:\Users\ccxkai\Documents\常用资料\VPS加固及代理搭建教程\images\面板界面.png
点击`入站列表`
点击`添加入站`
C:\Users\ccxkai\Documents\常用资料\VPS加固及代理搭建教程\images\添加入站.png

作为示例：我们来创建一个vless+reality+vision的节点。
如果你认真看了前面的代理协议科普，那你一定知道，这是目前最推荐的方案之一。不需要购买域名，配置相对简单，性能极高，隐蔽性极强。
你的流量会伪装成访问某个国际知名网站（例如微软、亚马逊）的流量。
当GFW检查你的网络连接时，它看到的不是一个可疑的、未知的加密流量，而是一个完全合法、指向一个高信誉度网站的HTTPS连接请求。由于它无法区分这是你发起的真实访问，还是一个伪装的代理，为了避免误杀正常用户，它大概率会选择放行。

箭头所指的地方就是需要设成跟我一样，或需要点击的按钮。
C:\Users\ccxkai\Documents\常用资料\VPS加固及代理搭建教程\images\节点信息.png
注意：`监听`这里，你可以填你vps上的IP，也可以留空，之后在V2rayN上填写也是一样的。

然后点击ID一列的前面的`＋`号，点击笔一样的图标`编辑客户端`
找到Flow下拉菜单，选择xtls-rprx-vision，然后点击保存修改。
C:\Users\ccxkai\Documents\常用资料\VPS加固及代理搭建教程\images\编辑客户端.png
接下来点击笔旁边的`更多信息`
C:\Users\ccxkai\Documents\常用资料\VPS加固及代理搭建教程\images\节点.png
复制下面的vless开头的连接，就可以导入到V2rayN了。

别忘了在防火墙放行代理端口。
sudo ufw allow 443/tcp

如果你在前面编辑节点时没有将你的ip填入`监听`，那么现在需要多一步。
右键刚刚通过剪切板导入的节点，点击`编辑配置文件`
C:\Users\ccxkai\Documents\常用资料\VPS加固及代理搭建教程\images\V2ryN.png
在地址（address）一栏里，将localhost换成你VPS的IP。
点击确定。
设为活动配置文件后，只要右下角出现延迟，就说明节点已经通了。
至于速度嘛，就看各位的VPS线路是否给力了。
C:\Users\ccxkai\Documents\常用资料\VPS加固及代理搭建教程\images\延迟.png
反正我这台到国内是几乎没有速度，连speedtest都打不开，所以我会再创建一个Tuic V5协议节点。