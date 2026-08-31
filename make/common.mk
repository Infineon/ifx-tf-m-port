################################################################################
# \file common.mk
# \version 1.0
#
# \brief
# Trusted Firmware-M (TF-M) helper make file
#
################################################################################
# \copyright
# (c) 2022-2026, Infineon Technologies AG, or an affiliate of Infineon
# Technologies AG. All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

ifeq ($(WHICHFILE),true)
$(info Processing $(lastword $(MAKEFILE_LIST)))
endif

################################################################################
# Help macros
################################################################################

TFM_OS=$(shell uname)

ifneq (,$(findstring CYGWIN,$(TFM_OS)))
# Converts path to shell (Cygwin) path prefixed with /cygdrive/
TFM_PATH_SHELL2=$(shell cygpath -i -u "$1")
TFM_PATH_SHELL=$(call TFM_PATH_SHELL2,"$1")
# Converts path to cmake (Cygwin mixed) path prefixed with C:/abc/file.txt
TFM_PATH_MIXED2=$(shell cygpath -i -m "$1")
TFM_PATH_MIXED=$(call TFM_PATH_MIXED2,"$1")
# Use python executable on Windows/Cygwin
TFM_PYTHON_EXECUTABLE_NAME=python
else
# Keep path as is for other platforms (OS X, Linux)
TFM_PATH_SHELL=$1
TFM_PATH_MIXED=$1
# Use python3 executable on OS X/Linux
TFM_PYTHON_EXECUTABLE_NAME=python3
endif

# Wraps space in target
space:=$(subst ,, )
TFM_WRAP_SPACE=$(subst $(space),\ ,$1)
TFM_UNWRAP_SPACE=$(subst \ ,$(space),$1)
# Wrape double quote
double_quote:=$(subst ,,")
TFM_WRAP_DOUBLE_QUOTE=$(subst $(double_quote),\",$1)

################################################################################
# Configuration
################################################################################

# Directory with current makefile
TFM_MAKE_SRC_DIR:=$(realpath $(join $(dir $(lastword $(MAKEFILE_LIST))),..))

# Temporary directory
TFM_TMP_DIR?=$(call TFM_PATH_MIXED,$(TFM_MAKE_SRC_DIR)/.tmp)
TFM_STAGES_DIR:=$(call TFM_PATH_MIXED,$(TFM_TMP_DIR)/stages)

# Location of TF-M sources
ifneq ($(TFM_GIT_URL),)
# Download TF-M sources from git repository
TFM_GIT_REF?=master
TFM_SRC_DIR?=$(call TFM_PATH_MIXED,$(abspath $(TFM_TMP_DIR)/src))
TFM_DOWNLOAD_SRC=true
else ifneq ($(wildcard $(TFM_SRC_DIR)),)
# Use existing TF-M sources
TFM_SRC_DIR:=$(call TFM_PATH_MIXED,$(abspath $(TFM_SRC_DIR)))
TFM_DOWNLOAD_SRC=false
else
# Use ifx-tf-m library from Library Manager
TFM_SRC_DIR:=$(call TFM_PATH_MIXED,$(abspath $(SEARCH_ifx-tf-m)))
TFM_DOWNLOAD_SRC=false
endif

# Location where non-secure interface is installed - application folder by default
TFM_INSTALL_PATH?=../install
# Location where hex images are installed
TFM_BUILD_PROJECT_HEX_DIR=$(call TFM_PATH_MIXED,$(abspath ../build/project_hex))

ifeq ($(DEVICE_MODE),SECURE)
TFM_DEVICE_CONFIG_DIR?=$(call TFM_PATH_MIXED,$(abspath $(SEARCH_ifx-tf-m-port)/config))
else
TFM_DEVICE_CONFIG_DIR?=$(call TFM_PATH_MIXED,$(abspath $(SEARCH_ifx-tf-m-ns)/config))
endif

# Include device configuration makefile
# Determine platform config file based on TARGET
# TARGET format: APP_KIT_<PLATFORM>_<VARIANT>
# Extract platform part and map to config file

# Detect EPC type from DEVICE features (from bsp.mk) or fall back to TARGET name
# This supports kits like KIT_PSE84_AI where EPC type is not in the TARGET name
TFM_EPC_TYPE:=$(if $(findstring EPC2,$(DEVICE_$(DEVICE)_FEATURES)),EPC2,$(if $(findstring EPC4,$(DEVICE_$(DEVICE)_FEATURES)),EPC4,))
ifeq ($(TFM_EPC_TYPE),)
  # Fall back to parsing TARGET name for backwards compatibility
  TFM_EPC_TYPE:=$(if $(findstring EPC2,$(TARGET)),EPC2,$(if $(findstring EPC4,$(TARGET)),EPC4,))
endif

ifeq ($(findstring PSE84,$(TARGET)),PSE84)
  ifeq ($(TFM_EPC_TYPE),EPC2)
    TFM_DEVICE_CONFIG_MK=$(TFM_DEVICE_CONFIG_DIR)/PSE84.mk $(TFM_DEVICE_CONFIG_DIR)/PSE84-EPC2.mk
  else ifeq ($(TFM_EPC_TYPE),EPC4)
    TFM_DEVICE_CONFIG_MK=$(TFM_DEVICE_CONFIG_DIR)/PSE84.mk $(TFM_DEVICE_CONFIG_DIR)/PSE84-EPC4.mk
  else
    $(error Cannot detect EPC type for $(TARGET). Set DEVICE_$(DEVICE)_FEATURES or use a TARGET with EPC2/EPC4 in the name.)
  endif
else ifeq ($(findstring PSC3M8,$(TARGET)),PSC3M8)
  TFM_DEVICE_CONFIG_MK=$(TFM_DEVICE_CONFIG_DIR)/PSC3P8.mk
else ifeq ($(findstring PSC3P8,$(TARGET)),PSC3P8)
  TFM_DEVICE_CONFIG_MK=$(TFM_DEVICE_CONFIG_DIR)/PSC3P8.mk
else ifeq ($(findstring PSC3M6,$(TARGET)),PSC3M6)
  TFM_DEVICE_CONFIG_MK=$(TFM_DEVICE_CONFIG_DIR)/PSC3M6.mk
else ifeq ($(findstring PSC3,$(TARGET)),PSC3)
  TFM_DEVICE_CONFIG_MK=$(TFM_DEVICE_CONFIG_DIR)/PSC3.mk
else ifeq ($(findstring PSB3,$(TARGET)),PSB3)
  TFM_DEVICE_CONFIG_MK=$(TFM_DEVICE_CONFIG_DIR)/PSB3.mk
else ifeq ($(findstring MERCURY,$(TARGET)),MERCURY)
  ifeq ($(TFM_EPC_TYPE),EPC2)
    TFM_DEVICE_CONFIG_MK=$(TFM_DEVICE_CONFIG_DIR)/PSE8X7.mk $(TFM_DEVICE_CONFIG_DIR)/PSE8X7-EPC2.mk
  else ifeq ($(TFM_EPC_TYPE),EPC4)
    TFM_DEVICE_CONFIG_MK=$(TFM_DEVICE_CONFIG_DIR)/PSE8X7.mk $(TFM_DEVICE_CONFIG_DIR)/PSE8X7-EPC4.mk
  else
    $(error Cannot detect EPC type for $(TARGET). Set DEVICE_$(DEVICE)_FEATURES or use a TARGET with EPC2/EPC4 in the name.)
  endif
endif

include $(TFM_DEVICE_CONFIG_MK)
