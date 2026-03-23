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

# ========== 原有核心功能（保留不变） ==========
# 1. 删除 mt76 相关配置
if [ -f ".config" ]; then
  sed -i '/mt76/d' .config
fi

# 2. 禁用 mt76 内核模块
cat >> .config << EOF
CONFIG_PACKAGE_kmod-mt76=n
CONFIG_PACKAGE_kmod-mt7601u=n
CONFIG_PACKAGE_kmod-mt7603e=n
CONFIG_PACKAGE_kmod-mt7615e=n
CONFIG_PACKAGE_kmod-mt7620e=n
CONFIG_PACKAGE_kmod-mt7692=n
CONFIG_PACKAGE_kmod-mt7915e=n
CONFIG_PACKAGE_kmod-mt7921e=n
EOF

# 3. 删除 mt76 源码包
rm -rf package/kernel/mt76

# 4. 清理 feeds 中的 mt76
if [ -f "./scripts/feeds" ]; then
  ./scripts/feeds uninstall -a mt76 2>/dev/null
fi

# 5. 禁用联发科平台
if [ -f ".config" ]; then
  sed -i '/mediatek/d' .config
fi
cat >> .config << EOF
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq807x=y
CONFIG_TARGET_qualcommax_ipq807x_DEVICE_redmi_ax6=y
CONFIG_TARGET_mediatek=n
CONFIG_TARGET_mediatek_filogic=n
EOF

# 6. 注册 Redmi AX6 设备
IPQ807X_MK="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "${IPQ807X_MK}" ]; then
  grep -q "TARGET_DEVICES += redmi_ax6" "${IPQ807X_MK}" || echo "TARGET_DEVICES += redmi_ax6" >> "${IPQ807X_MK}"
fi

# 7. 重新生成配置
make defconfig 2>/dev/null || true

echo "✅ DIY 脚本执行完成"
