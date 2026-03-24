#!/bin/bash
# 核心修复：直接使用工作流定义的环境变量作为源码路径
# 若环境变量未传递，使用绝对路径兜底

# 定义 OpenWrt 源码根目录（与工作流的 WORK_DIR 保持一致）
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

# 验证源码目录是否存在（核心修复：指向正确路径）
if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：OpenWrt 源码目录不存在 → ${OPENWRT_ROOT}"
  echo "⚠️  当前脚本目录：$(cd $(dirname $0) && pwd)"
  echo "⚠️  工作目录结构："
  ls -l /home/runner/work/openwrt/openwrt/
  exit 1
fi

# 切换到正确的源码目录
cd "${OPENWRT_ROOT}" || {
  echo "❌ 错误：无法切换到 OpenWrt 源码目录"
  exit 1
}
echo "✅ 已切换到 OpenWrt 源码目录：$(pwd)"

# ========== 彻底清理联发科驱动（保留） ==========
if [ -f ".config" ]; then
  sed -i '/mt76/d' .config
  sed -i '/mediatek/d' .config
fi

rm -rf package/kernel/mt76
if [ -f "./scripts/feeds" ]; then
  ./scripts/feeds uninstall -a mt76 2>/dev/null
fi

# ========== 锁定平台为 IPQ807x Redmi AX6 ==========
cat >> .config << EOF
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq807x=y
CONFIG_TARGET_qualcommax_ipq807x_DEVICE_redmi_ax6=y
CONFIG_TARGET_mediatek=n
CONFIG_TARGET_mediatek_filogic=n
EOF

# ========== 【新增】同步你修改的分区大小：ipq807x.mk ==========
IPQ807X_MK="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "${IPQ807X_MK}" ]; then
    # 给 AX3600 增加分区大小
    sed -i '/define Device\/xiaomi_ax3600/a\  ROOTFS_PARTITION_SIZE := 245760k' ${IPQ807X_MK}
    sed -i '/define Device\/xiaomi_ax3600/a\  IMAGE_SIZE := 262144k' ${IPQ807X_MK}

    # 给 AX6 增加分区大小
    sed -i '/define Device\/redmi_ax6/a\  ROOTFS_PARTITION_SIZE := 245760k' ${IPQ807X_MK}
    sed -i '/define Device\/redmi_ax6/a\  IMAGE_SIZE := 262144k' ${IPQ807X_MK}
fi

# ========== 【新增】同步你修改的 02_network rootfs 挂载 ==========
NETWORK_FILE="target/linux/qualcommax/base-files/etc/board.d/02_network"
if [ -f "${NETWORK_FILE}" ]; then
    # 追加 rootfs 挂载函数
    grep -q "ipq807x_setup_rootfs" ${NETWORK_FILE} || cat >> ${NETWORK_FILE} << 'EOF'

ipq807x_setup_rootfs() {
	local board="$1"

	case "$board" in
	redmi,ax6|\
	xiaomi,ax3600)
		ucidef_set_rootfs "ubi0:rootfs"
		ucidef_set_overlay "ubi0:rootfs"
		;;
	esac
}
EOF
    # 在调用处追加执行
    sed -i '/ipq807x_setup_macs $board/a\ipq807x_setup_rootfs $board' ${NETWORK_FILE}
fi

# ========== 【新增】注入中文 + iStore 配置 ==========
cat >> .config << EOF
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-argon-config-zh-cn=y
CONFIG_PACKAGE_luci-i18n-ddns-zh-cn=y
CONFIG_PACKAGE_luci-i18n-samba4-zh-cn=y
CONFIG_PACKAGE_luci-i18n-smartdns-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
CONFIG_PACKAGE_luci-i18n-upnp-zh-cn=y
CONFIG_PACKAGE_luci-i18n-autoreboot-zh-cn=y
CONFIG_PACKAGE_luci-i18n-filetransfer-zh-cn=y
CONFIG_PACKAGE_luci-i18n-mosquitto-zh-cn=y
CONFIG_LUCI_LANG="zh-cn"

# iStore 应用商店
CONFIG_PACKAGE_luci-app-store=y
CONFIG_PACKAGE_luci-i18n-store-zh-cn=y
CONFIG_PACKAGE_luci-lib-store=y
CONFIG_PACKAGE_store-apps=y
EOF

# ========== 重新生成配置 ==========
make defconfig 2>/dev/null || true

echo "✅ DIY 脚本执行完成，已同步：分区大小 + rootfs挂载 + 中文 + iStore"
