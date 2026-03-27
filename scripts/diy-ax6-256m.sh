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

# ========== 修改 DTS 文件（最小修改）==========
DTS_FILE="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    # 修改 rootfs 分区大小
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0x10000000>/' "$DTS_FILE"
    # 修改 bootargs (root=/dev/ubiblock0_0 改为 root=/dev/ubiblock0_1)
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    echo "✅ DTS 文件已修改"
fi

# ========== 修改 WiFi 配置 ==========
AX6_DTS="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8071-ax6.dts"
if [ -f "$AX6_DTS" ]; then
    # 添加 WiFi 内存模式配置
    if ! grep -q "qcom,ath11k-fw-memory-mode" "$AX6_DTS"; then
        sed -i '/&wifi {/a\	qcom,ath11k-fw-memory-mode = <2>;' "$AX6_DTS"
    fi
    echo "✅ AX6 DTS 已修改"
fi

# ========== 添加 WiFi 固件修复脚本 ==========
mkdir -p files/etc/init.d
cat > files/etc/init.d/fix-wifi << 'EOF'
#!/bin/sh /etc/rc.common

START=98

start() {
    if [ -d /lib/firmware/ath11k/IPQ8074/hw2.0 ] && [ ! -f /lib/firmware/ath11k/IPQ8074/q6_fw.mdt ]; then
        cd /lib/firmware/ath11k/IPQ8074/ && ln -sf hw2.0/* . 2>/dev/null
    fi
}
EOF
chmod +x files/etc/init.d/fix-wifi

echo "✅ DIY 脚本执行完成"
