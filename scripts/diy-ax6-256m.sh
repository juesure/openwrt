#!/bin/bash
WORK_DIR="/home/runner/work/openwrt/openwrt/workdir"
OPENWRT_DIR="$WORK_DIR/openwrt"
cd "$OPENWRT_DIR" || exit 1

echo "✅ DIY 脚本：检查 DTS 文件..."
if [ -f target/linux/qualcommax/dts/ipq8071-ax3600.dtsi ]; then
    echo "   ipq8071-ax3600.dtsi 存在"
else
    echo "❌ 错误：ipq8071-ax3600.dtsi 不存在"
    exit 1
fi
echo "✅ 准备就绪"
#!/bin/bash

echo "============================================="
echo "  自动复制 ipq8074-512m.dtsi 到 dts 目录"
echo "============================================="

# 源文件路径
SRC_FILE1="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8074-512m.dtsi"

# 目标路径
DST_DIR="target/linux/qualcommax/dts/"

# 复制文件
cp -f "$SRC_FILE1" "$DST_DIR"

# 检查是否成功
if [ -f "${DST_DIR}/ipq8074-512m.dtsi" ]; then
  echo "✅ 复制成功！"
else
  echo "❌ 复制失败！"
  exit 1
fi
# 源文件路径
SRC_FILE2="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8074-ac-cpu.dtsi"

# 目标路径
DST_DIR="target/linux/qualcommax/dts/"

# 复制文件
cp -f "$SRC_FILE2" "$DST_DIR"

# 检查是否成功
if [ -f "${DST_DIR}/ipq8074-512m.dtsi" ]; then
  echo "✅ 复制成功！"
else
  echo "❌ 复制失败！"
  exit 1
fi
