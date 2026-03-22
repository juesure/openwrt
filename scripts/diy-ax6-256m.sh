#!/bin/bash
# diy-ax6-256m.sh - Redmi AX6 256M 扩容修改脚本

# 切换到源码目录
cd $(dirname $0)/openwrt


# 4. 确保设备被正确注册
echo "TARGET_DEVICES += redmi_ax6" >> target/linux/qualcommax/image/ipq807x.mk

# 5. 选择 Redmi AX6 为默认编译机型
sed -i 's/CONFIG_TARGET_MULTI_PROFILE=y/CONFIG_TARGET_MULTI_PROFILE=n/' .config
echo "CONFIG_TARGET_qualcommax_ipq807x_DEVICE_redmi_ax6=y" >> .config
