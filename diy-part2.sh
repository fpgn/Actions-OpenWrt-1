#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
sed -i 's/192.168.1.1/192.168.11.1/g' package/base-files/files/bin/config_generate



# 添加5.4内核ACC、shortcut-fe补丁
# openwrt21.02 netfilter补丁\
cp -rf $GITHUB_WORKSPACE/patchs/firewall/* package/firmware/
patch -p1 < package/firmware/001-fix-firewall-flock.patch

# nft-fullcone
git clone -b main --single-branch https://github.com/fullcone-nat-nftables/nftables-1.0.5-with-fullcone package/nftables
git clone -b master --single-branch https://github.com/fullcone-nat-nftables/libnftnl-1.2.4-with-fullcone package/libnftnl

# 打补丁
wget -O package/firmware/xt_FULLCONENAT.c https://raw.githubusercontent.com/Chion82/netfilter-full-cone-nat/master/xt_FULLCONENAT.c
cp -rf package/firmware/xt_FULLCONENAT.c package/nftables/include/linux/netfilter/xt_FULLCONENAT.c
cp -rf package/firmware/xt_FULLCONENAT.c package/libnftnl/include/linux/netfilter/xt_FULLCONENAT.c
cp -rf package/firmware/xt_FULLCONENAT.c package/libs/libnetfilter-conntrack/xt_FULLCONENAT.c

# dnsmasq-full升级2.89
rm -rf package/network/services/dnsmasq
cp -rf $GITHUB_WORKSPACE/patchs/5.4/dnsmasq package/network/services/dnsmasq



#升级cmake
rm -rf tools/cmake
mkdir -p tools/cmake/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/tools/cmake/* tools/cmake/

### 后补的

#FullCone Patch
git clone -b master --single-branch https://github.com/QiuSimons/openwrt-fullconenat package/fullconenat
# Patch FireWall for fullcone
mkdir package/network/config/firewall/patches
wget -P package/network/config/firewall/patches/ https://raw.githubusercontent.com/LGA1150/fullconenat-fw3-patch/master/fullconenat.patch

pushd feeds/luci
wget -O- https://raw.githubusercontent.com/LGA1150/fullconenat-fw3-patch/master/luci.patch | git apply
popd

### 后补的
# SFE kernel patch
cp -n $GITHUB_WORKSPACE/patchs/5.4/patches-5.4/102-mt7621-fix-cpu-clk-add-clkdev.patch target/linux/ramips/patches-5.4/
cp -n $GITHUB_WORKSPACE/patchs/5.4/hack-5.4/* target/linux/generic/hack-5.4/
cp -n $GITHUB_WORKSPACE/patchs/5.4/pending-5.4/* target/linux/generic/pending-5.4/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/sfe/* package/yuos/

# 解锁160MHZ
cp -n $GITHUB_WORKSPACE/patchs/5.4/unlock-160mhz/* package/kernel/mac80211/patches/brcm/

# 解决kconfig补丁
wget -P target/linux/generic/backport-5.4/ https://raw.githubusercontent.com/hanwckf/immortalwrt-mt798x/openwrt-21.02/target/linux/generic/backport-5.4/500-v5.15-fs-ntfs3-Add-NTFS3-in-fs-Kconfig-and-fs-Makefile.patch
patch -p1 < target/linux/generic/backport-5.4/500-v5.15-fs-ntfs3-Add-NTFS3-in-fs-Kconfig-and-fs-Makefile.patch

mkdir -p target/linux/generic/files-5.4/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/files-5.4/* target/linux/generic/files-5.4/

# 测试
cp -rf $GITHUB_WORKSPACE/patchs/5.4/netsupport.mk package/kernel/linux/modules/netsupport.mk

# 删除多余组件
rm -rf feeds/small8/fullconenat-nft
rm -rf feeds/small8/fullconenat


# 为保障流畅，针对SSR做特定版本处理
# xray 1.8.9
cp -rf $GITHUB_WORKSPACE/patchs/5.4/xray-core/1.8.9/* feeds/helloworld/xray-core/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/xray-core/1.8.9/* feeds/small/xray-core/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/xray-core/1.8.9/* feeds/small8/xray-core/

# xray-plugin
cp -rf $GITHUB_WORKSPACE/patchs/5.4/xray-plugin/* feeds/helloworld/xray-plugin/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/xray-plugin/* feeds/small/xray-plugin/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/xray-plugin/* feeds/small8/xray-plugin/

# tailscale 1.40.0
cp -rf $GITHUB_WORKSPACE/patchs/5.4/tailscale/* feeds/packages/net/tailscale/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/tailscale/* feeds/small/tailscale/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/tailscale/* feeds/helloworld/tailscale/

# naiveproxy
cp -rf feeds/small8/naiveproxy/* feeds/small/naiveproxy/
cp -rf feeds/small8/naiveproxy/* feeds/small8/naiveproxy/
cp -rf feeds/small8/naiveproxy/* feeds/helloworld/naiveproxy/

# hysteria 1.3.5
cp -rf $GITHUB_WORKSPACE/patchs/5.4/hysteria/* feeds/small/hysteria/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/hysteria/* feeds/packages/net/hysteria/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/hysteria/* feeds/helloworld/hysteria/

#升级golang
find . -type d -name "golang" -exec rm -r {} +
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 20.x feeds/packages/lang/golang

# git clone https://github.com/quic-go/quic-go -b master feeds/packages/lang/golang/quic-go

#设置软件唯一性
find . -type d -name "gn" -exec rm -r {} +
mkdir -p feeds/small8/gn/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/gn/* feeds/small8/gn/
rm -rf feeds/small/brook
rm -rf feeds/helloworld/shadowsocks-rust
rm -rf feeds/small/shadowsocks-rust
rm -rf feeds/helloworld/simple-obfs
rm -rf feeds/helloworld/v2ray-plugin
rm -rf feeds/small/v2ray-plugin
# find . -type d -name "sing-box" -exec rm -r {} +

# vssr
cd package/
git clone https://github.com/jerrykuku/lua-maxminddb.git  
#git lua-maxminddb 依赖
git clone https://github.com/MilesPoupart/luci-app-vssr.git  
