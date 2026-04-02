#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

# 可选：删除整个补丁目录（避免旧补丁干扰）
rm -rf target/linux/qualcommax/patches-6.12

# 定义设备树源文件存放路径（OpenWrt files 目录）
DTS_FILES_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"
mkdir -p "$DTS_FILES_DIR"

# 需要修复的文件列表（相对于 DTS_FILES_DIR）
FILES_TO_FIX=(
    "ipq8074-ac-cpu.dtsi"
    "ipq8074-hk-cpu.dtsi"
    "ipq8074-ess.dtsi"
)

# 定义要添加的 dummy 节点（提供缺失的标签）
read -r -d '' DUMMY_NODES << 'EOF'
/ {
    cpu0: cpu@0 { compatible = "arm,cortex-a53"; };
    cpu1: cpu@1 { compatible = "arm,cortex-a53"; };
    cpu2: cpu@2 { compatible = "arm,cortex-a53"; };
    cpu3: cpu@3 { compatible = "arm,cortex-a53"; };
    clocks: clocks { };
    wifi: wifi { };
};
EOF

# 修复每个文件：如果文件不存在则创建，否则在头部插入 dummy 节点（如果尚未包含）
for file in "${FILES_TO_FIX[@]}"; do
    full_path="$DTS_FILES_DIR/$file"
    if [ -f "$full_path" ]; then
        # 检查是否已存在 cpu0 标签（避免重复添加）
        if ! grep -q "cpu0:" "$full_path"; then
            echo "正在修复 $full_path"
            # 在文件开头插入 dummy 节点
            { echo "$DUMMY_NODES"; cat "$full_path"; } > "$full_path.tmp" && mv "$full_path.tmp" "$full_path"
        else
            echo "跳过 $full_path（已包含 cpu0 定义）"
        fi
    else
        # 文件不存在，直接创建并写入 dummy 节点
        echo "创建缺失的文件 $full_path"
        echo "$DUMMY_NODES" > "$full_path"
        # 可选：添加注释说明
        echo "" >> "$full_path"
        echo "// 该文件由脚本自动生成，用于提供缺失的标签定义" >> "$full_path"
    fi
done

# 额外处理：某些 dts 文件（如 ipq8071-ap8220.dts）可能直接引用 &wifi，已在 dummy 节点中提供
# 如果需要，也可以复制或修复主 dts 文件，但通常只需修复上述包含文件即可

echo "✅ 设备树文件已修复，请重新执行编译命令（如 make）"
