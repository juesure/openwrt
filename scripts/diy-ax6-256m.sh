#!/bin/bash
# diy-ax6-256m.sh - Redmi AX6 256M 扩容修改脚本
# 1. 从 .config 中删除所有 mt76 相关配置
sed -i '/mt76/d' .config
# 2. 禁用 mt76 内核模块编译
echo "CONFIG_PACKAGE_kmod-mt76=n" >> .config
echo "CONFIG_PACKAGE_kmod-mt7601u=n" >> .config
echo "CONFIG_PACKAGE_kmod-mt7603e=n" >> .config
echo "CONFIG_PACKAGE_kmod-mt7615e=n" >> .config
echo "CONFIG_PACKAGE_kmod-mt7620e=n" >> .config
echo "CONFIG_PACKAGE_kmod-mt7692=n" >> .config
echo "CONFIG_PACKAGE_kmod-mt7915e=n" >> .config
echo "CONFIG_PACKAGE_kmod-mt7921e=n" >> .config
# 3. 删除 mt76 源码包（避免编译系统扫描到）
rm -rf $GITHUB_WORKSPACE/openwrt/package/kernel/mt76
# 4. 清理 feeds 中的 mt76 依赖
./scripts/feeds uninstall -a mt76
# 5. 强制指定高通平台，排除联发科
sed -i 's/CONFIG_TARGET_mediatek.*=y//g' .config
echo "CONFIG_TARGET_qualcommax=y" >> .config
echo "CONFIG_TARGET_qualcommax_ipq807x=y" >> .config
echo "CONFIG_TARGET_qualcommax_ipq807x_DEVICE_redmi_ax6=y" >> .config
# 切换到源码目录
cd $(dirname $0)/openwrt


# 4. 确保设备被正确注册
echo "TARGET_DEVICES += redmi_ax6" >> target/linux/qualcommax/image/ipq807x.mk

# 5. 选择 Redmi AX6 为默认编译机型
sed -i 's/CONFIG_TARGET_MULTI_PROFILE=y/CONFIG_TARGET_MULTI_PROFILE=n/' .config
echo "CONFIG_TARGET_qualcommax_ipq807x_DEVICE_redmi_ax6=y" >> .config
