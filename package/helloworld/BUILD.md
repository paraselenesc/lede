# Helloworld Package Build Guide

本目录包含 OpenWrt/LEDE 代理相关软件包，已集成到 LEDE 源码中。

## 包含的软件包

### LuCI 应用
- **luci-app-ssr-plus** - SSR Plus+ 代理工具（支持多种协议）

### 核心组件
- **shadowsocksr-libev** - SSR 客户端
- **shadowsocks-libev** - SS 客户端
- **shadowsocks-rust** - SS Rust 版本
- **v2ray-core** - V2Ray 核心
- **xray-core** - Xray 核心
- **trojan** - Trojan 代理
- **naiveproxy** - NaïveProxy
- **hysteria** - Hysteria 协议
- **tuic-client** - TUIC 客户端

### DNS 工具
- **chinadns-ng** - 中国大陆域名分流
- **dns2socks** - DNS over SOCKS
- **dns2tcp** - DNS over TCP
- **dnsproxy** - DNS 代理
- **mosdns** - MosDNS 分流

### 辅助工具
- **redsocks2** - 透明代理
- **ipt2socks** - iptables 转 SOCKS
- **microsocks** - 微型 SOCKS 代理
- **tcping** - TCP Ping 工具

## 本地编译方法

### 1. 完整编译固件

```bash
# 进入 LEDE 目录
cd lede

# 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 配置固件
make menuconfig
# 选择目标平台，然后在 LuCI -> Applications 中选择需要的包

# 编译
make download -j$(nproc)
make -j$(nproc) || make -j1 V=s
```

### 2. 单独编译某个包

```bash
# 配置启用该包
echo "CONFIG_PACKAGE_luci-app-ssr-plus=y" >> .config
make defconfig

# 单独编译
make package/helloworld/luci-app-ssr-plus/compile V=s

# 编译结果位于
ls bin/packages/*/helloworld/
```

### 3. 清理并重新编译

```bash
# 清理单个包
make package/helloworld/luci-app-ssr-plus/clean

# 重新编译
make package/helloworld/luci-app-ssr-plus/compile V=s
```

## GitHub Actions 自动编译

本仓库已配置 GitHub Actions 自动编译：

1. 进入 Actions 页面
2. 选择 "Build LEDE Firmware"
3. 点击 "Run workflow"
4. 选择配置（可选）并开始编译
5. 编译完成后在 Artifacts 中下载固件和包

### 默认配置

Actions 默认编译 x86_64 固件，包含：
- luci-app-ssr-plus（含中文语言包）
- v2ray-core, xray-core
- trojan, naiveproxy, hysteria
- chinadns-ng, mosdns
- 其他辅助工具

## 自定义配置

### 创建自定义配置文件

```bash
# 生成配置
make menuconfig
# 选择需要的包后保存

# 保存配置文件
cp .config my-config.txt
```

### 使用自定义配置编译

将配置文件提交到仓库，然后在 Actions 中指定配置文件路径。

## 常见问题

### Q: 编译失败怎么办？

查看详细日志：
```bash
make -j1 V=s
```

### Q: 包找不到？

确保已运行 feeds 更新：
```bash
./scripts/feeds update -a
./scripts/feeds install -a
```

### Q: 如何添加新的代理节点配置？

编译完成后，在路由器 LuCI 界面中配置：
1. 进入 服务 -> ShadowSocksR Plus+
2. 添加服务器节点
3. 配置订阅或手动添加

## 目录结构

```
package/helloworld/
├── luci-app-ssr-plus/     # LuCI 界面
├── shadowsocksr-libev/    # SSR 核心
├── shadowsocks-libev/     # SS 核心
├── shadowsocks-rust/      # SS Rust
├── v2ray-core/           # V2Ray
├── xray-core/            # Xray
├── trojan/               # Trojan
├── naiveproxy/           # NaïveProxy
├── hysteria/             # Hysteria
├── tuic-client/          # TUIC
├── chinadns-ng/          # ChinaDNS-NG
├── mosdns/               # MosDNS
├── dnsproxy/             # DNS Proxy
├── redsocks2/            # Redsocks2
├── ipt2socks/            # ipt2socks
├── microsocks/           # Microsocks
├── tcping/               # TCPing
└── ...                   # 其他依赖包
```

## 更新日志

- 2026-03-13: 合并 helloworld 到 lede/package/helloworld
- 2026-03-13: 添加 LAN IP 排序和主机名显示功能
