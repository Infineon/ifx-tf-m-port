################################################################################
# \file PSE84.mk
# \version 1.0
#
# \brief
# Trusted Firmware-M (TF-M) configuration for PSE84 Family
#
################################################################################
# \copyright
# (c) 2023-2026, Infineon Technologies AG, or an affiliate of Infineon
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
# Secure build
################################################################################
ifeq ($(DEVICE_MODE),SECURE)
else # ($(DEVICE_MODE),SECURE)
################################################################################
# Non-secure build
################################################################################

ifeq ($(CORE),CM33) # CM33
# Use TZ interface for CM33
IFX_NS_INTERFACE_TZ=1
else ifeq ($(CORE),CM55) # CM55
# Use MAILBOX interface for CM55
IFX_NS_INTERFACE_MAILBOX=1
endif # ($(CORE),CM33)

INCLUDES+=$(wildcard $(TFM_INSTALL_PATH)/platform/pse84/shared/device/include)

endif # ($(DEVICE_MODE),SECURE)
