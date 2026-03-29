include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk
include ./common-ipq807x.mk

DEVICE_VARS += QCOM_SOC_ROM QCOM_DTS_ROM QCOM_ART_ROM

$(eval $(call BuildImage))
