LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := ndkprobe
LOCAL_SRC_FILES := probe.cpp
LOCAL_CPPFLAGS := -std=c++17 -fexceptions -frtti
include $(BUILD_SHARED_LIBRARY)
