# ==============================
# 目标平台与设备
# ==============================
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq807x=y
CONFIG_TARGET_qualcommax_ipq807x_DEVICE_redmi_ax6=y
CONFIG_TARGET_MULTI_PROFILE=n
CONFIG_TARGET_ALL_PROFILES=n
CONFIG_TARGET_BOARD="qualcommax"
CONFIG_TARGET_SUBTARGET="ipq807x"
CONFIG_TARGET_ARCH_PACKAGES="aarch64_cortex-a53"
CONFIG_CPU_TYPE="cortex-a53"

# ==============================
# 存储与 UBIFS/UBI
# ==============================
CONFIG_TARGET_ROOTFS_UBIFS=y
CONFIG_TARGET_ROOTFS_UBI=y
CONFIG_UBIFS_FS=y
CONFIG_MTD_UBI=y
CONFIG_MTD_UBI_WL_THRESHOLD=4096
CONFIG_UBIFS_GC_PERIOD=100
CONFIG_MTD_UBI_FASTMAP=y
CONFIG_MTD_UBI_BLOCK=y
CONFIG_MTD_NAND=y
CONFIG_MTD_NAND_ECC=y
CONFIG_MTD_NAND_ECC_SW_BCH=y
CONFIG_PACKAGE_ubi-utils=y
CONFIG_PACKAGE_mtd-utils=y
CONFIG_PACKAGE_mtd-utils-ubi-utils=y
CONFIG_PACKAGE_nand-utils=y

# ==============================
# WiFi 驱动 (IPQ8071A 专用)
# ==============================
CONFIG_PACKAGE_kmod-ath11k-ahb=y
CONFIG_PACKAGE_kmod-ath11k-pci=n
CONFIG_PACKAGE_ath11k-firmware-ipq8074=y
CONFIG_PACKAGE_ipq-wifi-redmi_ax6=y
CONFIG_PACKAGE_kmod-qca-wifi=y
CONFIG_PACKAGE_kmod-qca-nss-dp=y
CONFIG_PACKAGE_kmod-qca-ssdk=y

# ==============================
# APK 包管理器（取代 opkg）
# ==============================
CONFIG_USE_APK=y
CONFIG_PACKAGE_apk-tools=y
CONFIG_PACKAGE_libapk=y
CONFIG_PACKAGE_ca-certificates=y
CONFIG_PACKAGE_ca-bundle=y

# ==============================
# 基础系统
# ==============================
CONFIG_PACKAGE_base-files=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_fstools=y
CONFIG_PACKAGE_ubox=y
CONFIG_PACKAGE_ubus=y
CONFIG_PACKAGE_uci=y
CONFIG_PACKAGE_logd=y
CONFIG_PACKAGE_urandom-seed=y
CONFIG_PACKAGE_urngd=y
CONFIG_PACKAGE_rpcd=y
CONFIG_PACKAGE_rpcd-mod-file=y
CONFIG_PACKAGE_rpcd-mod-ucode=y

# ==============================
# 网络基础
# ==============================
CONFIG_PACKAGE_netifd=y
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_firewall4=y
CONFIG_PACKAGE_nftables=y
CONFIG_PACKAGE_odhcpd-ipv6only=y
CONFIG_PACKAGE_odhcp6c=y
CONFIG_PACKAGE_ppp=y
CONFIG_PACKAGE_ppp-mod-pppoe=y
CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_iw=y
CONFIG_PACKAGE_hostapd-common=y
CONFIG_PACKAGE_wpad-openssl=y
CONFIG_PACKAGE_wireless-regdb=y

# ==============================
# LuCI Web 界面
# ==============================
CONFIG_PACKAGE_uhttpd=y
CONFIG_PACKAGE_uhttpd-mod-ubus=y
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_LUCI_LANG="zh-cn"

# ==============================
# LuCI 应用（用户指定）
# ==============================
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-lib-ipkg=y
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Server=y
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-turboacc=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-autoreboot=y
CONFIG_PACKAGE_luci-app-zerotier=y
CONFIG_PACKAGE_luci-app-wol=y
CONFIG_PACKAGE_luci-app-ddns=y

# ==============================
# 必要工具
# ==============================
CONFIG_PACKAGE_coreutils=y
CONFIG_PACKAGE_coreutils-nohup=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_unzip=y
CONFIG_PACKAGE_tar=y
CONFIG_PACKAGE_gzip=y
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_lsblk=y
CONFIG_PACKAGE_openssh-sftp-server=y

# ==============================
# 编译优化
# ==============================
CONFIG_TARGET_IMAGES_GZIP=y
CONFIG_DEBUG=n
CONFIG_KERNEL_DEBUG=n
CONFIG_KERNEL_DEBUG_FS=n
