# Copyright (C) 2011 Amlogic Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# This file is the build configuration for a full Android
# build for Meson reference board.
#
SEI_CHIP_DEVICE := x2

#burn wifi mac
#SEI_BURN_WIFI_MAC_KEY := true
SEI_USE_HBG := true

#dolby vision
TARGET_BUILD_DOLBY_VISION := true

########################################################################
$(call inherit-product, device/amlogic/common/products/sei/product_mbox.mk)
$(call inherit-product, device/amlogic/tai/device.mk)
$(call inherit-product, device/amlogic/tai/vendor_prop.mk)
$(call inherit-product-if-exists, vendor/amlogic/x2/device-vendor.mk)
$(call inherit-product-if-exists, vendor/amlogic/common/gms/google/gms.mk)
#########################################################################
#
#                                               Media extension
#
#########################################################################
TARGET_WITH_MEDIA_EXT_LEVEL := 4

# tai:
PRODUCT_PROPERTY_OVERRIDES += \
    ro.hdmi.device_type=4 \
    ro.hdmi.set_menu_language=false \
    ro.hdmi.volume.passthrough=true \
    persist.sys.hdmi.keep_awake=false

PRODUCT_NAME := SEI500HS
PRODUCT_DEVICE := tai
PRODUCT_BRAND := SecQre
PRODUCT_MODEL := SEI500HS 
PRODUCT_MANUFACTURER := SEI Robotics

TARGET_KERNEL_BUILT_FROM_SOURCE := true

PRODUCT_TYPE := sei

BOARD_AML_VENDOR_PATH := vendor/amlogic/common/
BOARD_WIDEVINE_TA_PATH := vendor/amlogic/

PROCUDT_UBOOT_PARAMS := g12a_u212_v1

OTA_UP_PART_NUM_CHANGED := true

BOARD_AML_TDK_KEY_PATH := device/amlogic/common/tdk_keys/
#AB_OTA_UPDATER :=true
BUILD_WITH_AVB := true
BUILD_WITH_UDC := false

#JUST FOR QA TEST REQUIREMENT
PRODUCT_PACKAGES += \
    Gallery2

PRODUCT_USE_DYNAMIC_PARTITIONS := true
#BOARD_BUILD_SYSTEM_ROOT_IMAGE := true

#########################################################################
#
#                           add sei keymap
#
#########################################################################
PRODUCT_COPY_FILES += \
    app-repo-v2/Nes_KeyMap/keylayout/Vendor_1d5a_Product_c084_B13B.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Vendor_1d5a_Product_c084.kl

#########################################################################
#
#                           sei common macro define
#
#########################################################################
SEI_PRODUCT_MACHINE_TYPE:=SN8BAB
SEI_PRODUCT_CUSTOMER_NAME:=SF001
SEI_PRODUCT_NAME:=$(PRODUCT_NAME)
SEI_PRODUCT_CUSTOMER_ID:=FEF2C4
SEI_PRODUCT_SAMPLE_NUMBER:=tai
SEI_PRODUCT_ORDER_NUMBER:=tai
SEI_PLATFORM:=AMLOGIC_905X2_ATV
BUILD_WITH_BLE_REMOTE_TYPE:=B01A

SEI_RLS_DATE_TIME:=$(shell echo `date +%Y%m%d%H%M%S`)
SEI_RLS_DATE:=$(shell echo `date +%Y%m%d`)
ifeq ($(SEI_TEST_VERSION),)
#Change version here
    ifeq ($(SEI_BUILD_NUMBER),)
        SEI_BUILD_NUMBER:=0
        BUILD_ALLOW_PERMISSIVE:=true
    endif
    SEI_PRODUCT_VERSION:=v10.5.$(SEI_BUILD_NUMBER)
else
SEI_PRODUCT_VERSION:=$(SEI_TEST_VERSION)
endif
include device/amlogic/common/products/sei/common_sei.mk

#########################################################################
#
#                          SECURE BOOT V3
#
#########################################################################
#########Support compiling out encrypted zip/aml_upgrade_package.img directly
BOARD_AML_SECUREBOOT_KEY_DIR := ./app-repo-v2/Nes_Secureboot_v3/SEI500HS
BOARD_AML_SECUREBOOT_SOC_TYPE := sm1

#########################################################################
#
#                          Dm-Verity
#
#########################################################################
#TARGET_USE_SECURITY_DM_VERITY_MODE_WITH_TOOL := true

#########################################################################
#
#                          WiFi
#
#########################################################################

ifeq ($(SEI_BURN_WIFI_MAC_KEY),true)
#bcm or rtk
PRODUCT_PROPERTY_SYSTEM_OVERRIDES += \
    ro.nes.wifi.typemode=bcm
endif

WIFI_MODULE := multiwifi
#WIFI_MODULE := BCMWIFI
#WIFI_BUILD_IN := true

WIFI_BUILD_WITH_3ANT := true
include vendor/amlogic/common/wifi_bt/wifi/configs/wifi.mk
#########################################################################
#
# Bluetooth
#
#########################################################################

BOARD_HAVE_BLUETOOTH := true
BLUETOOTH_MODULE := multibt
include vendor/amlogic/common/wifi_bt/bluetooth/configs/bluetooth.mk
#########################################################################

#########################################################################
#
# Audio
#
#########################################################################
BOARD_ALSA_AUDIO=tiny
include device/amlogic/common/audio.mk

#########################################################################

#########################################################################
#
# PlayReady DRM
#
#########################################################################
#export BOARD_PLAYREADY_LEVEL=3 for PlayReady+NOTVP
#export BOARD_PLAYREADY_LEVEL=1 for PlayReady+OPTEE+TVP

#########################################################################
#
# Verimatrix DRM
#
##########################################################################
#verimatrix web
BUILD_WITH_VIEWRIGHT_WEB := false
#verimatrix stb
BUILD_WITH_VIEWRIGHT_STB := false
#########################################################################

#################################################################################
#
# DEFAULT LOWMEMORYKILLER CONFIG
#
#################################################################################
BUILD_WITH_LOWMEM_COMMON_CONFIG := true

BOARD_USES_USB_PM := true
#########################################################################

########################################################################
#
#                          Netflix
#
#########################################################################
TARGET_BUILD_NETFLIX:= true
#TARGET_BUILD_NETFLIX_MGKID := true
TARGET_BUILD_NETFLIX_MODELGROUP:= SEI500HS

#########################################################################
#
# TB detect
#
#########################################################################
$(call inherit-product, device/amlogic/common/tb_detect.mk)

ifeq ($(AB_OTA_UPDATER),true)
PRODUCT_COPY_FILES += \
    device/amlogic/tai/fstab.ab.amlogic:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.amlogic
else
ifeq ($(BUILD_WITH_UDC),true)
PRODUCT_COPY_FILES += \
    device/amlogic/tai/fstab.udc.amlogic:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.amlogic
else
PRODUCT_COPY_FILES += \
    device/amlogic/tai/fstab.system.amlogic:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.amlogic
endif
endif

BOARD_INSTALL_VULKAN:=true

$(call inherit-product, device/amlogic/common/media.mk)

include device/amlogic/common/gpu/dvalin-user-arm64.mk

include device/amlogic/common/products/sei/g12a/g12a.mk

#########################################################################
#
#                                                Languages
#
#########################################################################

PRODUCT_LOCALES := en_US

# For all locales, $(call inherit-product, build/target/product/languages_full.mk)
PRODUCT_LOCALES := en_US en_AU en_IN fr_FR it_IT es_ES et_EE de_DE nl_NL cs_CZ pl_PL ja_JP \
  zh_TW zh_CN zh_HK ru_RU ko_KR nb_NO es_US da_DK el_GR tr_TR pt_PT pt_BR rm_CH sv_SE bg_BG \
  ca_ES en_GB fi_FI hi_IN hr_HR hu_HU in_ID iw_IL lt_LT lv_LV ro_RO sk_SK sl_SI sr_RS uk_UA \
  vi_VN tl_PH ar_EG fa_IR th_TH sw_TZ ms_MY af_ZA zu_ZA am_ET hi_IN en_XA ar_XB fr_CA km_KH \
  lo_LA ne_NP si_LK mn_MN hy_AM az_AZ ka_GE my_MM mr_IN ml_IN is_IS mk_MK ky_KG eu_ES gl_ES \
  bn_BD ta_IN kn_IN te_IN uz_UZ ur_PK kk_KZ
#################################################################################

PRODUCT_PROPERTY_SYSTEM_OVERRIDES += \
    persist.sys.timezone=Europe/Madrid

##########################################################################
#                               device features
##########################################################################
PRODUCT_PROPERTY_OVERRIDES += \
	net.hostname=SEI500HS \
	ro.com.google.clientidbase=android-seirobotics-tv \
	ro.ota.ptoq=false

#########################################################################
#
#                                add rcu settings
#
#########################################################################
PRODUCT_COPY_FILES += \
	$(LOCAL_PATH)/files/sei_rcu_settings.conf:/vendor/etc/config/sei_rcu_settings.conf

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/files/operator_flags.xml:system/etc/sysconfig/operator_flags.xml 

#########################################################################
#
#                                add MS12 Function
#
#########################################################################
PRODUCT_PACKAGES += \
    libdolbyms12
