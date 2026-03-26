#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：目录不存在"
  exit 1
fi

cd "${OPENWRT_ROOT}" || exit 1

# ========== 清理联发科 ==========
if [ -f ".config" ]; then
  sed -i '/mt76/d' .config
  sed -i '/mediatek/d' .config
fi

rm -rf package/kernel/mt76
./scripts/feeds uninstall -a mt76 2>/dev/null || true

# ========== 锁定平台 ==========
cat > .config << EOF
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq807x=y
CONFIG_TARGET_qualcommax_ipq807x_DEVICE_redmi_ax6=y
CONFIG_TARGET_mediatek=n
CONFIG_TARGET_mediatek_filogic=n
EOF

# ========== 分区大小配置（适配256M Flash） ==========
IPQ807X_MK="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "${IPQ807X_MK}" ]; then
  # 修改rootfs大小为256M
  sed -i '/define Device\/redmi_ax6/a\  IMAGE_SIZE := 262144k' ${IPQ807X_MK}
  sed -i '/define Device\/redmi_ax6/a\  UBINIZE_OPTS := -E 5' ${IPQ807X_MK}
fi

# ========== 修改DTS文件以适配256M分区 ==========
DTS_FILE="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8074-ax6.dts"
if [ -f "${DTS_FILE}" ]; then
  # 修改rootfs分区大小为256M（0x10000000 = 256M）
  sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0x10000000>/' ${DTS_FILE}
  # 添加UBI坏块管理优化
  sed -i '/partition@a00000/a\ \ \ \ \ \ \ \ \ \ \ \ ubi-bad-blocks;' ${DTS_FILE}
fi

# ========== 重新生成配置 ==========
make defconfig 2>/dev/null || true

echo "✅ DIY 脚本执行完成 —— 已适配256M Flash"
