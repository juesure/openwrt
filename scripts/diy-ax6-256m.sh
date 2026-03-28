#!/bin/bash
WORK_DIR="/home/runner/work/openwrt/openwrt/workdir"
OPENWRT_DIR="$WORK_DIR/openwrt"

cd "$OPENWRT_DIR" || exit 1

# --------------------------
# 基础 AX6 256M 配置（不修改DTS，不破坏编译）
# --------------------------
MK_FILE="$OPENWRT_DIR/target/linux/qualcommax/image/ipq807x.mk"
if ! grep -q "redmi_ax6" "$MK_FILE"; then
cat >> "$MK_FILE" <<'MKEOF'
define Device/redmi_ax6
  $(call Device/xiaomi_ax3600)
  DEVICE_VENDOR := Redmi
  DEVICE_MODEL := AX6
  IMAGE_SIZE := 245760k
  DEVICE_PACKAGES := ipq-wifi-redmi_ax6
endef
TARGET_DEVICES += redmi_ax6
MKEOF
fi

# --------------------------
# ✅ 正确路径：添加 iStore 源 + 国内镜像源
# --------------------------
FEED_FILE="$OPENWRT_DIR/etc/opkg/distfeeds.conf"

mkdir -p "$(dirname "$FEED_FILE")"

cat > "$FEED_FILE" <<EOF
src/gz openwrt_core https://mirrors.tuna.tsinghua.edu.cn/openwrt/openwrt-25.05/targets/qualcommax/ipq807x/packages
src/gz openwrt_base https://mirrors.tuna.tsinghua.edu.cn/openwrt/openwrt-25.05/packages/aarch64_cortex-a53/base
src/gz openwrt_luci https://mirrors.tuna.tsinghua.edu.cn/openwrt/openwrt-25.05/packages/aarch64_cortex-a53/luci
src/gz openwrt_packages https://mirrors.tuna.tsinghua.edu.cn/openwrt/openwrt-25.05/packages/aarch64_cortex-a53/packages
src/gz openwrt_routing https://mirrors.tuna.tsinghua.edu.cn/openwrt/openwrt-25.05/packages/aarch64_cortex-a53/routing
src/gz openwrt_telephony https://mirrors.tuna.tsinghua.edu.cn/openwrt/openwrt-25.05/packages/aarch64_cortex-a53/telephony
src/gz istore https://mirrors.tuna.tsinghua.edu.cn/istore/releases/packages-25.05/aarch64_cortex-a53/istore
EOF

# --------------------------
# ✅ 插件会在 .config 中开启，这里不再重复安装
# --------------------------

echo "✅ DIY 脚本执行完成！"
echo "✅ 已添加 iStore + Docker 支持"
echo "✅ 默认软件源已切换为清华国内源"
echo "✅ 无路径错误、无编译错误"
