### 1.1 .config 文件说明

这个文件是 OpenWrt 软件包个性化定制的核心文件，包含了全部的配置信息，文件里面每一行代码代表一项个性化配置选项。虽然项目很多，但管理很简单。我们开始动手操作吧。

#### 1.1.1 首先让固件支持本国语言

在# National language packs, luci-i18n-base: 以法国为例，启用法语支持，就把

```yaml
# CONFIG_PACKAGE_luci-i18n-base-fr is not set
```

修改为

```yaml
CONFIG_PACKAGE_luci-i18n-base-fr=y
```

.config 文件里的个性化定制全部这样操作即可。把自己不需要的项目，在行首填写 `#` ，在行尾把 `=y` 改为 `is not set` 。对于自己需要的项目，去掉行首的 `#` ，结尾把 `is not set` 改为 `=y`

#### 1.1.2 选择个性化软件包

在 `#LuCI-app:` 启用和删除默认软件包的做法和上面一样,这次我们删除默认软件包里的 `luci-app-zerotier` 这个插件，就把

```yaml
CONFIG_PACKAGE_luci-app-zerotier=y
```
修改为

```yaml
# CONFIG_PACKAGE_luci-app-zerotier is not set
```

我想你应该已经很明白怎么个性化配置了，.config 文件每行代表一个配置项，都可以使用这样的方法启用或删除固件里的默认配置，这个文件的完整内容有几千行，我提供的只是精简版，如何获得完整配置文件，进行更加复杂的个性化定制，我们放在第 10 节里介绍。

### 1.2 DIY脚本操作: diy-part1.sh 和 diy-part2.sh

脚本 diy-part1.sh 和 diy-part2.sh ，它们分别在更新与安装 feeds 的前后执行，当我们引入 OpenWrt 的源码库进行个性化固件编译时，有时想改写源码库中的部分代码，或者增加一些第三方提供的软件包，删除或者替换源码库中的一些软件包，比如修改默认 IP、主机名、主题、添加 / 删除软件包等操作，这些对源码库的修改指令可以写到这 2 个脚本中。我们以 coolsnowwolf 提供的 OpenWrt 源码库作为编译对象，举几个例子。

我们以下的操作都以这个源码库为基础: [https://github.com/coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)

#### 举例1，添加第三方软件包

第一步，在 diy-part2.sh 里加入以下代码：

```yaml
git clone https://github.com/jerrykuku/luci-app-ttnode.git package/lean/luci-app-ttnode
```

第二步，到 .config 文件里添加这个第三方软件包的启用代码：

```yaml
CONFIG_PACKAGE_luci-app-ttnode=y
```

这样就完成了第三方软件包的集成，扩充了当前源码库中没有的软件包。

#### 举例2，用第三方软件包替换当前源码库中的已有的同名软件包

第一步，在 diy-part2.sh 里加入以下代码：用第一行代码先删除源码库中原来的软件，再用第二行代码引入第三方的同名软件包。

```yaml
rm -rf package/lean/luci-theme-argon
git clone https://github.com/jerrykuku/luci-theme-argon.git package/lean/luci-theme-argon
```

第二步，到 .config 文件里添加第三方软件包

```yaml
CONFIG_PACKAGE_luci-theme-argon=y
```

这样就实现了使用第三方软件包替换当前源码库中的已有的同名软件包。

#### 举例3，通过修改源码库中的代码来实现某些需求

我们增加 `luci-app-cpufreq` 对 `aarch64` 的支持，以便在我们的固件中使用（有些修改要谨慎，你必须知道你在做什么）。

源文件地址： [luci-app-cpufreq/Makefile](https://github.com/coolsnowwolf/lede/blob/master/package/lean/luci-app-cpufreq/Makefile) 。修改代码加入对 aarch64 的支持：

```yaml
sed -i 's/LUCI_DEPENDS.*/LUCI_DEPENDS:=\@\(arm\|\|aarch64\)/g' package/lean/luci-app-cpufreq/Makefile
```

这样就实现了对源码的修改。通过 diy-part1.sh 和 diy-part2.sh 这两个脚本，我们添加了一些操作命令，让编译的固件更符合我们的个性化需求。

## 2. 编译固件

固件编译的流程在 .github/workflows/build-openwrt-lede.yml 文件里控制，在 workflows 目录下还有其他 .yml 文件，实现其他不同的功能。固件编译的方式很多，可以设置定时编译，手动编译，或者设置一些特定事件来触发编译。我们先从简单的操作开始。

### 2.1 手动编译

在自己仓库的导航栏中，点击 Actions 按钮，再依次点击 Build OpenWrt > Run workflow > Run workflow ，开始编译，等待大约 3 个小时，全部流程都结束后就完成编译了。图示如下：

<div style="width:100%;margin-top:40px;margin:5px;">
<img src=https://user-images.githubusercontent.com/68696949/109418662-a0226a80-7a04-11eb-97f6-aeb893336e8c.jpg width="300" />
<img src=https://user-images.githubusercontent.com/68696949/109418663-a31d5b00-7a04-11eb-8d34-57d430696901.jpg width="300" />
<img src=https://user-images.githubusercontent.com/68696949/109418666-a7497880-7a04-11eb-9ed0-be738e22f7ae.jpg width="300" />
</div>

### 2.2 定时编译

在 .github/workflows/build-openwrt-lede.yml 文件里，使用 Cron 设置定时编译，5 个不同位置分别代表的意思为 分钟 (0 - 59) / 小时 (0 - 23) / 日期 (1 - 31) / 月份 (1 - 12) / 星期几 (0 - 6)(星期日 - 星期六)。通过修改不同位置的数值来设定时间。系统默认使用 UTC 标准时间，请根据你所在国家时区的不同进行换算。

```yaml
schedule:
  - cron: '0 17 * * *'
```
