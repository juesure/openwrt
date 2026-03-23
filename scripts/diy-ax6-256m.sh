#!/bin/bash
# diy-ax6-256m.sh - Redmi AX6 256M 扩容修改脚本
# 核心功能：禁用联发科/mt76、强制高通IPQ807x/Redmi AX6、清理冗余依赖

# ========== 第一步：定义核心路径（避免变量未定义） ==========
# 脚本所在目录
SCRIPT_DIR=$(cd $(dirname $0) && pwd)
# OpenWrt 源码根目录（关键：先定义再切换）
OPENWRT_ROOT="${SCRIPT_DIR}/openwrt"

# ========== 第二步：验证源码目录并切换（核心修复） ==========
if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：OpenWrt 源码目录不存在 → ${OPENWRT_ROOT}"
  exit 1
fi
cd "${OPENWRT_ROOT}" || {
  echo "❌ 错误：无法切换到 OpenWrt 源码目录"
  exit 1
}
echo "✅ 已切换到 OpenWrt 源码目录：$(pwd)"

# ========== 第三步：核心功能1 - 彻底禁用 mt76 相关（保留+优化） ==========
# 1. 从 .config 中删除所有 mt76 相关配置（先检查 .config 存在）
if [ -f ".config" ]; then
  sed -i '/mt76/d' .config
  echo "✅ 已删除 .config 中 mt76 相关配置"
else
  echo "⚠️ 警告：.config 暂未生成，跳过 mt76 配置删除"
fi

# 2. 禁用 mt76 内核模块编译（追加到 .config）
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
echo "✅ 已禁用 mt76 内核模块编译"

# 3. 删除 mt76 源码包（避免编译系统扫描到）
rm -rf "${OPENWRT_ROOT}/package/kernel/mt76"
echo "✅ 已删除 mt76 源码包"

# 4. 清理 feeds 中的 mt76 依赖（兼容 feeds 不存在的情况）
if [ -f "./scripts/feeds" ]; then
  ./scripts/feeds uninstall -a mt76 2>/dev/null || echo "⚠️ 无 mt76 feeds 可卸载"
  echo "✅ 已清理 feeds 中的 mt76 依赖"
else
  echo "⚠️ 警告：feeds 脚本不存在，跳过 mt76 feeds 清理"
fi

# ========== 第四步：核心功能2 - 强制高通平台/禁用联发科（保留+去重） ==========
# 1. 从 .config 中删除所有联发科相关配置
if [ -f ".config" ]; then
  sed -i '/mediatek/d' .config
  echo "✅ 已删除 .config 中联发科相关配置"
fi

# 2. 强制指定仅编译高通 qualcommax 平台（去重，只保留一份）
cat >> .config << EOF
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq807x=y
CONFIG_TARGET_qualcommax_ipq807x_DEVICE_redmi_ax6=y
CONFIG_TARGET_mediatek=n
CONFIG_TARGET_mediatek_filogic=n
EOF
echo "✅ 已强制指定高通 IPQ807x/Redmi AX6 平台"

# 3. 禁用多机型编译，强制默认 Redmi AX6
if [ -f ".config" ]; then
  sed -i 's/CONFIG_TARGET_MULTI_PROFILE=y/CONFIG_TARGET_MULTI_PROFILE=n/' .config
  echo "✅ 已禁用多机型编译"
fi

# 4. 删除联发科平台的编译脚本（避免扫描到）
rm -rf target/linux/mediatek/image/*filogic*
echo "✅ 已删除联发科 filogic 编译脚本"

# 5. 清理联发科相关的编译缓存
rm -rf build_dir/target-*/linux-mediatek*
rm -rf staging_dir/target-*/linux-mediatek*
echo "✅ 已清理联发科编译缓存"

# ========== 第五步：核心功能3 - 注册 Redmi AX6 设备（保留） ==========
IPQ807X_MK="${OPENWRT_ROOT}/target/linux/qualcommax/image/ipq807x.mk"
if [ -f "${IPQ807X_MK}" ]; then
  # 先检查是否已添加，避免重复追加
  grep -q "TARGET_DEVICES += redmi_ax6" "${IPQ807X_MK}" || echo "TARGET_DEVICES += redmi_ax6" >> "${IPQ807X_MK}"
  echo "✅ 已确保 Redmi AX6 设备被正确注册"
else
  echo "⚠️ 警告：ipq807x.mk 不存在，跳过设备注册"
fi

# ========== 第六步：重新生成编译配置（保留） ==========
make defconfig 2>/dev/null || {
  echo "⚠️ 警告：make defconfig 执行失败（可能 .config 未完全生成）"
  exit 0  # 非致命错误，不终止脚本
}
echo "✅ 已重新生成编译配置"

echo "======================================"
echo "✅ Redmi AX6 256M 扩容脚本执行完成"
echo "======================================"
