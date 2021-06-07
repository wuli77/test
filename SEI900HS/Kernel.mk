#if use probuilt kernel or build kernel from source code
KERNEL_ROOTDIR := common
KERNEL_KO_OUT := $(PRODUCT_OUT)/obj/lib_vendor

INSTALLED_KERNEL_TARGET := $(PRODUCT_OUT)/kernel

BOARD_MKBOOTIMG_ARGS := --kernel_offset $(BOARD_KERNEL_OFFSET) --header_version $(BOARD_BOOTIMG_HEADER_VERSION)

INSTALLED_2NDBOOTLOADER_TARGET := $(PRODUCT_OUT)/2ndbootloader
INSTALLED_BOARDDTB_TARGET := $(PRODUCT_OUT)/dt.img
ifeq ($(PRODUCT_BUILD_SECURE_BOOT_IMAGE_DIRECTLY),true)
	INSTALLED_BOARDDTB_TARGET := $(INSTALLED_BOARDDTB_TARGET).encrypt
endif# ifeq ($(PRODUCT_BUILD_SECURE_BOOT_IMAGE_DIRECTLY),true)

INSTALLED_DTBIMAGE_TARGET := $(PRODUCT_OUT)/dtb.img
$(INSTALLED_DTBIMAGE_TARGET): $(INSTALLED_BOARDDTB_TARGET)
	$(transform-prebuilt-to-target)

ifneq ($(TARGET_KERNEL_BUILT_FROM_SOURCE), true)
TARGET_PREBUILT_KERNEL := device/amlogic/$(PRODUCT_DIR)-kernel/Image.gz
LOCAL_DTB := device/amlogic/$(PRODUCT_DIR)-kernel/$(PRODUCT_DIR).dtb

PREBUILT_KERNEL_PATH := device/amlogic/tai-kernel
SOURCE_FILES := $(wildcard $(PREBUILT_KERNEL_PATH)/lib/*.ko)
SOURCE_FILES += $(wildcard $(PREBUILT_KERNEL_PATH)/lib/egl/*.so)
SOURCE_FILES += $(wildcard $(PREBUILT_KERNEL_PATH)/lib/firmware/video/*.bin)
SOURCE_FILES += $(wildcard $(PREBUILT_KERNEL_PATH)/lib/modules/*.ko)

$(INSTALLED_KERNEL_TARGET):: $(INSTALLED_BOARDDTB_TARGET) $(TARGET_PREBUILT_KERNEL) $(SOURCE_FILES)
	@echo "cp kernel modules"
	mkdir -p $(PRODUCT_OUT)/root/boot
	mkdir -p $(PRODUCT_OUT)/vendor/lib/firmware/video
	mkdir -p $(PRODUCT_OUT)/obj/lib
	mkdir -p $(PRODUCT_OUT)/obj/KERNEL_OBJ/
	mkdir -p $(PRODUCT_OUT)/recovery/root/boot
	mkdir -p $(KERNEL_KO_OUT)
	cp device/amlogic/$(PRODUCT_DIR)-kernel/lib/modules/* $(KERNEL_KO_OUT)/
	cp device/amlogic/$(PRODUCT_DIR)-kernel/lib/optee_armtz.ko $(PRODUCT_OUT)/vendor/lib/
	cp device/amlogic/$(PRODUCT_DIR)-kernel/lib/optee.ko $(PRODUCT_OUT)/vendor/lib/
	cp device/amlogic/$(PRODUCT_DIR)-kernel/lib/firmware/video/* $(PRODUCT_OUT)/vendor/lib/firmware/video/
	-cp device/amlogic/$(PRODUCT_DIR)-kernel/obj/KERNEL_OBJ/vmlinux $(PRODUCT_OUT)/obj/KERNEL_OBJ/
	mkdir -p $(PRODUCT_OUT)/$(TARGET_COPY_OUT_VENDOR)/lib/modules/
	cp $(KERNEL_KO_OUT)/* $(PRODUCT_OUT)/$(TARGET_COPY_OUT_VENDOR)/lib/modules/
	mkdir -p $(PRODUCT_OUT)/vendor/lib/egl
	cp device/amlogic/$(PRODUCT_DIR)-kernel/lib/egl/* $(PRODUCT_OUT)/vendor/lib/egl/
	# previous INSTALLED_KERNEL_TARGET module doing this, copy to target.
	rm -f $(INSTALLED_KERNEL_TARGET)
	cp $(TARGET_PREBUILT_KERNEL) $(INSTALLED_KERNEL_TARGET)

# cannot use in Q, directly expand in the module above, see the comment above.
#$(INSTALLED_KERNEL_TARGET): $(TARGET_PREBUILT_KERNEL) | $(ACP)
#	@echo "Kernel installed"
#	$(transform-prebuilt-to-target)

$(INSTALLED_BOARDDTB_TARGET): $(LOCAL_DTB) | $(ACP)
	@echo "dtb installed"
	$(transform-prebuilt-to-target)

$(INSTALLED_2NDBOOTLOADER_TARGET): $(INSTALLED_BOARDDTB_TARGET) $(BOARD_PREBUILT_DTBOIMAGE) | $(ACP)
	@echo "2ndbootloader installed"
	$(transform-prebuilt-to-target)

else
#
#  Modules related mk must include here(like the c inlude and java import), do not insert in the middle!!!!
#
-include device/amlogic/common/gpu/dvalin-kernel.mk
-include device/amlogic/common/media_modules.mk
-include vendor/amlogic/common/wifi_bt/wifi/configs/wifi_modules.mk
-include vendor/amlogic/common/wifi_bt/bluetooth/configs/bluetooth_modules.mk
-include device/amlogic/common/tb_modules.mk
-include device/amlogic/common/tuner/tuner_modules.mk
-include device/amlogic/common/soft_afbc/soft_afbc_modules.mk

$(DEFAULT_WIFI_KERNEL_MODULES):$(INTERMEDIATES_KERNEL)

####
####  Build Kernel From Source
####

KERNEL_DEVICETREE := g12a_s905x2_u212_SEI500

KERNEL_DEFCONFIG := meson64_defconfig
KERNEL_ARCH := arm64

DTBO_DEVICETREE := android_p_overlay_dt


KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ

ifndef KERNEL_A32_SUPPORT
KERNEL_A32_SUPPORT := false
endif

ifeq ($(KERNEL_A32_SUPPORT), true)
KERNEL_DEFCONFIG := meson64_a32_defconfig
KERNEL_ARCH := arm
INTERMEDIATES_KERNEL := $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/uImage
PREFIX_CROSS_COMPILE=/opt/gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
BUILD_CONFIG := $(KERNEL_DEFCONFIG)
else
KERNEL_DEFCONFIG := meson64_defconfig
KERNEL_ARCH := arm64
INTERMEDIATES_KERNEL := $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/Image.gz
PREFIX_CROSS_COMPILE=/opt/gcc-linaro-6.3.1-2017.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
# COMPILE CHECK FOR KASAN
ifeq ($(ENABLE_KASAN), true)
CONFIG_DIR := $(KERNEL_ROOTDIR)/arch/$(KERNEL_ARCH)/configs/
KASAN_DEFCONFIG := kasan_defconfig
BUILD_CONFIG := $(KASAN_DEFCONFIG)
else
BUILD_CONFIG := $(KERNEL_DEFCONFIG)
endif
endif

KERNEL_CONFIG := $(KERNEL_OUT)/.config
TARGET_AMLOGIC_INT_KERNEL := $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/uImage
TARGET_AMLOGIC_INT_RECOVERY_KERNEL := $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/Image_recovery

$(warning BOARD_VENDOR_KERNEL_MODULES:$(BOARD_VENDOR_KERNEL_MODULES))

# force to set to Empty, let modules modify this may introduce module duplication, which
# caused the system build failure in Q. module should only define locally and add here
# to build.
BOARD_VENDOR_KERNEL_MODULES := $(DEFAULT_GPU_KERNEL_MODULES) \
                               $(DEFAULT_MEDIA_KERNEL_MODULES) \
                               $(DEFAULT_WIFI_KERNEL_MODULES) \
                               $(DEFAULT_TB_DETECT_KERNEL_MODULES) \
                               $(DEFAULT_SOFTAFBC_KERNEL_MODULES)

WIFI_OUT  := $(TARGET_OUT_INTERMEDIATES)/hardware/wifi

define cp-modules
	mkdir -p $(PRODUCT_OUT)/root/boot
	mkdir -p $(KERNEL_KO_OUT)
	# need revise the below modules, why they not keep the same as other modules??
	-cp $(KERNEL_OUT)/drivers/usb/dwc3/dwc3.ko $(KERNEL_KO_OUT)/
	-cp $(KERNEL_OUT)/drivers/amlogic/usb/dwc_otg/310/dwc_otg.ko $(KERNEL_KO_OUT)/
#	cp $(WIFI_OUT)/broadcom/drivers/ap6xxx/broadcm_40181/dhd.ko $(TARGET_OUT)/lib/
#	cp $(KERNEL_OUT)/../hardware/amlogic/pmu/aml_pmu_dev.ko $(TARGET_OUT)/lib/
#	cp $(shell pwd)/hardware/amlogic/thermal/aml_thermal.ko $(TARGET_OUT)/lib/
#	cp $(KERNEL_OUT)/../hardware/amlogic/nand/amlnf/aml_nftl_dev.ko $(PRODUCT_OUT)/root/boot/
endef

##----------------------------------------------------------------------------------
##   build kernel, common build proc
##
##   $1: the kernel build module defined in it's makefile
##----------------------------------------------------------------------------------
define build_kernel
	PATH=$$(cd ./$(TARGET_HOST_TOOL_PATH); pwd):$$PATH \
		$(MAKE) -C $(KERNEL_ROOTDIR) \
		O=$(realpath $(KERNEL_OUT)) \
		ARCH=$(KERNEL_ARCH) \
		CROSS_COMPILE=$(PREFIX_CROSS_COMPILE) \
		$(1)
endef

##----------------------------------------------------------------------------------
##   build kernel module source, outside of kernel tree
##
##   $1: the moudle's unique makefile
##   $2: the module
##
## Note: additional KERNEL_ARCH is used, because some module makefile look at this
##       config but ARCH, add it for more compatible
##       The varible defined here cannot directly effect to the module makefile.
##----------------------------------------------------------------------------------
define build_module_path
	PATH=$$(cd ./$(TARGET_HOST_TOOL_PATH); pwd):$$PATH \
		$(MAKE) ARCH=$(KERNEL_ARCH) \
		KERNEL_ARCH=$(KERNEL_ARCH) \
		CROSS_COMPILE=$(PREFIX_CROSS_COMPILE) \
		-f $(1) \
		$(2)
endef


$(KERNEL_OUT):
	mkdir -p $(KERNEL_OUT)
ifeq ($(ENABLE_KASAN), true)
	@echo "KASAN enabled, generate new config"
	cat $(CONFIG_DIR)/$(KERNEL_DEFCONFIG) > $(CONFIG_DIR)/$(KASAN_DEFCONFIG)
	cat device/amlogic/common/kasan.cfg >> $(CONFIG_DIR)/$(KASAN_DEFCONFIG)
endif

$(warning BOARD_VENDOR_KERNEL_MODULES:$(BOARD_VENDOR_KERNEL_MODULES))
$(KERNEL_CONFIG): $(KERNEL_OUT)
	$(call build_kernel, $(BUILD_CONFIG))

$(INTERMEDIATES_KERNEL): $(KERNEL_OUT) $(KERNEL_CONFIG) $(INSTALLED_BOARDDTB_TARGET)
	@echo "make Image"
ifeq ($(KERNEL_A32_SUPPORT), true)
	$(call build_kernel, modules uImage)
else
	$(call build_kernel, modules Image.gz)
endif
	#$(gpu-modules)
	$(call build_module_path, vendor/amlogic/common/wifi_bt/wifi/configs/wifi_driver.mk, $(WIFI_MODULE))
	$(call build_module_path, vendor/amlogic/common/wifi_bt/bluetooth/configs/bluetooth_driver.mk, BLUETOOTH_INF=$(BLUETOOTH_INF) $(BLUETOOTH_MODULE))
	$(tb-modules)
	$(cp-modules)
	$(media-modules)
	mkdir -p $(PRODUCT_OUT)/$(TARGET_COPY_OUT_VENDOR)/lib/modules/
	cp $(KERNEL_KO_OUT)/* $(PRODUCT_OUT)/$(TARGET_COPY_OUT_VENDOR)/lib/modules/

.PHONY: kerneltags
kerneltags: $(KERNEL_OUT)
	$(call build_kernel, tags)


.PHONY: kernelconfig
kernelconfig: $(KERNEL_OUT) $(KERNEL_CONFIG)
	env KCONFIG_NOTIMESTAMP=true \
		$(call build_kernel, menuconfig)

.PHONY: savekernelconfig
savekernelconfig: $(KERNEL_OUT) $(KERNEL_CONFIG)
	env KCONFIG_NOTIMESTAMP=true \
		$(call build_kernel, savedefconfig)
	@echo
	@echo Saved to $(KERNEL_OUT)/defconfig
	@echo
	@echo handly merge to "$(KERNEL_ROOTDIR)/arch/$(KERNEL_ARCH)/configs/$(KERNEL_DEFCONFIG)" if need
	@echo

.PHONY: build-modules-quick
build-modules-quick:
	$(media-modules)

$(INSTALLED_2NDBOOTLOADER_TARGET): $(INSTALLED_BOARDDTB_TARGET) $(BOARD_PREBUILT_DTBOIMAGE) | $(ACP)
	@echo "2ndbootloader installed"
	$(transform-prebuilt-to-target)

$(INSTALLED_KERNEL_TARGET): $(INTERMEDIATES_KERNEL) | $(ACP)
	@echo "Kernel installed"
	$(transform-prebuilt-to-target)

# useless here, vendor modules should defined in it's makefile, in Q, it does not support duplicate define
#$(BOARD_VENDOR_KERNEL_MODULES): $(INSTALLED_KERNEL_TARGET)
#	@echo "BOARD_VENDOR_KERNEL_MODULES: $(BOARD_VENDOR_KERNEL_MODULES)"


.PHONY: bootimage-quick
bootimage-quick: $(INTERMEDIATES_KERNEL)
	cp -v $(INTERMEDIATES_KERNEL) $(INSTALLED_KERNEL_TARGET)
	out/host/linux-x86/bin/mkbootfs $(PRODUCT_OUT)/root | \
	out/host/linux-x86/bin/minigzip > $(PRODUCT_OUT)/ramdisk.img
	out/host/linux-x86/bin/mkbootimg  --kernel $(INTERMEDIATES_KERNEL) \
		--base 0x0 \
		--kernel_offset 0x1080000 \
		--ramdisk $(PRODUCT_OUT)/ramdisk.img \
		$(BOARD_MKBOOTIMG_ARGS) \
		--output $(PRODUCT_OUT)/boot.img
	ls -l $(PRODUCT_OUT)/boot.img
	echo "Done building boot.img"

.PHONY: recoveryimage-quick
recoveryimage-quick: $(INTERMEDIATES_KERNEL)
	cp -v $(INTERMEDIATES_KERNEL) $(INSTALLED_KERNEL_TARGET)
	out/host/linux-x86/bin/mkbootfs $(PRODUCT_OUT)/recovery/root | \
	out/host/linux-x86/bin/minigzip > $(PRODUCT_OUT)/ramdisk-recovery.img
	out/host/linux-x86/bin/mkbootimg  --kernel $(INTERMEDIATES_KERNEL) \
		--base 0x0 \
		--kernel_offset 0x1080000 \
		--ramdisk $(PRODUCT_OUT)/ramdisk-recovery.img \
		$(BOARD_MKBOOTIMG_ARGS) \
		--output $(PRODUCT_OUT)/recovery.img
	ls -l $(PRODUCT_OUT)/recovery.img
	echo "Done building recovery.img"

endif

####  Modules depends for build kernel ####
$(PRODUCT_OUT)/ramdisk.img: $(INSTALLED_KERNEL_TARGET)
$(PRODUCT_OUT)/system.img: $(INSTALLED_KERNEL_TARGET)
# The ko is copied to vendor, must depends on kernel modules
$(PRODUCT_OUT)/vendor.img: $(INSTALLED_KERNEL_TARGET)
