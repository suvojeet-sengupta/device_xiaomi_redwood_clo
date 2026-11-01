#
# Copyright (C) 2025 The LineageOS Project
#           (C) 2026 Paranoid Android
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq (aospa_redwood,$(TARGET_PRODUCT))

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
TARGET_SUPPORTS_OMX_SERVICE := false
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from the device configuration.
$(call inherit-product, device/xiaomi/redwood/device.mk)

# Inherit from the AOSPA configuration.
$(call inherit-product, vendor/aospa/target/product/aospa-target.mk)

PRODUCT_BRAND := POCO
PRODUCT_DEVICE := redwood
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_MODEL := 22101320G
PRODUCT_NAME := aospa_redwood

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

# Boot animation resolution.
TARGET_BOOT_ANIMATION_RES := 1080
TARGET_USES_BLUR := true

# Override device name for Play Store.
PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="redwood_global-user 14 UKQ1.240624.001 OS2.0.17.0.UMSMIXM release-keys" \
    BuildFingerprint=POCO/redwood_global/redwood:14/UKQ1.240624.001/OS2.0.17.0.UMSMIXM:user/release-keys \
    DeviceName=redwood \
    DeviceProduct=redwood_global \
    SystemDevice=redwood \
    SystemName=redwood_global

# Flags
TARGET_INCLUDES_OEM_App := true
TARGET_INCLUDES_DolbyVision := true
PVT_COS_BUILD := true

endif
