include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

DEVICE_VARS += QCOM_SOC_ROM QCOM_DTS_ROM QCOM_ART_ROM

define Device/redmi_ax6
  SOC := ipq8071
  DEVICE_DTS := ipq8071-ax6
  DEVICE_VENDOR := Redmi
  DEVICE_MODEL := AX6
  IMAGE_SIZE := 245760k
  DEVICE_PACKAGES := ipq-wifi-redmi_ax6
endef
TARGET_DEVICES += redmi_ax6

$(eval $(call BuildImage))
