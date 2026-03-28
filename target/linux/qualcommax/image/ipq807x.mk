include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

# 删掉了不存在的 common-ipq807x.mk
# 删掉了错误的 common.mk
# 完全使用原生结构，无任何警告

DEVICE_VARS += QCOM_SOC_ROM QCOM_DTS_ROM QCOM_ART_ROM

# 保留你原版 Redmi AX6 256M 配置
define Device/redmi_ax6
  $(call Device/xiaomi_ax3600)
  DEVICE_VENDOR := Redmi
  DEVICE_MODEL := AX6
  IMAGE_SIZE := 245760k
  DEVICE_PACKAGES := ipq-wifi-redmi_ax6
endef
TARGET_DEVICES += redmi_ax6

$(eval $(call BuildImage))
