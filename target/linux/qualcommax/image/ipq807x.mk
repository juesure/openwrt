# ===================== 只编译 Redmi AX6，注释所有其他设备 =====================

# 保留基础设备定义（redmi_ax6 依赖）
define Device/xiaomi_ax3600
	$(call Device/FitImage)
	$(call Device/UbiFit)
	DEVICE_VENDOR := Xiaomi
	DEVICE_MODEL := AX3600
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	DEVICE_DTS_CONFIG := config@ac04
	SOC := ipq8071
	KERNEL_SIZE := 36608k
	DEVICE_PACKAGES := ipq-wifi-xiaomi_ax3600
endef
TARGET_DEVICES += xiaomi_ax3600

# Redmi AX6 配置
define Device/redmi_ax6
	$(call Device/xiaomi_ax3600)
	DEVICE_VENDOR := Redmi
	DEVICE_MODEL := AX6
	IMAGE_SIZE := 245760k
	UBINIZE_OPTS := -E 5 -m 2048 -p 128KiB -s 2048 -O 2048
	KERNEL_IN_UBI := 1
	IMAGES += factory.ubi
	IMAGE/factory.ubi := append-ubi | check-size $$$$(IMAGE_SIZE)
	DEVICE_PACKAGES := ipq-wifi-redmi_ax6 \
		kmod-ath11k-ahb \
		ath11k-firmware-ipq8071 \
		ath11k-firmware-ipq8074 \
		uhttpd \
		uhttpd-mod-ubus \
		luci \
		luci-base \
		luci-mod-admin-full \
		luci-theme-argon \
		luci-i18n-base-zh-cn \
		luci-i18n-argon-config-zh-cn \
		luci-app-store \
		luci-lib-store \
		luci-i18n-store-zh-cn \
		store-apps
endef
TARGET_DEVICES += redmi_ax6

# ===================== 以下所有设备全部注释掉 =====================
# define Device/aliyun_ap8220
# 	...
# endef
# TARGET_DEVICES += aliyun_ap8220

# define Device/arcadyan_aw1000
# 	...
# endef
# TARGET_DEVICES += arcadyan_aw1000

# ... 以此类推，注释掉所有其他设备 ...
