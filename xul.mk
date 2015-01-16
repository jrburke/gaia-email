# This is copied from the gaia Makefile, may need periodic refreshes

# Force bash for all shell commands since we depend on bash-specific syntax
SHELL := /bin/bash

GAIA_DIR := $(CURDIR)

# what OS are we on?
SYS=$(shell uname -s)
ARCH?=$(shell uname -m)
MSYS_FIX=
ifeq (${SYS}/${ARCH},Darwin/i386)
ARCH=x86_64
endif
SEP=/
SEP_FOR_SED=/
ifneq (,$(findstring MINGW32_,$(SYS)))
GAIA_DIR:=$(shell pwd -W | sed -e 's|/|\\\\|g')
SEP=\\
SEP_FOR_SED=\\\\
# Mingw mangle path and append c:\mozilla-build\msys\data in front of paths
MSYS_FIX=/
endif

ifeq ($(SYS),Darwin)
MD5SUM = md5 -r
SED_INPLACE_NO_SUFFIX = /usr/bin/sed -i ''
DOWNLOAD_CMD = /usr/bin/curl -OLsS
TAR_WILDCARDS = tar
else
MD5SUM = md5sum -b
SED_INPLACE_NO_SUFFIX = sed -i
DOWNLOAD_CMD = wget $(WGET_OPTS)
TAR_WILDCARDS = tar --wildcards
endif


# The b2g_sdk target arranges to get b2g desktop downloaded and set up.
# This is platform dependent code, so a mite complicated.
# Note: this used to be just xulrunner, hence the use of that name throughout,
# but xulrunner doesn't include everything we need

# Configuration for pre-built or already downloaded b2g (or alternative)
ifdef USE_LOCAL_XULRUNNER_SDK

ifndef XULRUNNER_DIRECTORY
$(error XULRUNNER_DIRECTORY must be set if USE_LOCAL_XULRUNNER_SDK is set)
endif

# Some guesswork to figure out where the xpcshell binary really is
# Most of this is to accommodate the variety of setups used
# by different platforms, build systems and TBPL configurations
# including Firefox, xulrunner and other builds
XPCSHELL_GUESS = $(firstword $(wildcard \
    $(XULRUNNER_DIRECTORY)/B2G.app/Contents/MacOS/xpcshell \
    $(XULRUNNER_DIRECTORY)/bin/XUL.framework/Versions/Current/xpcshell \
    $(XULRUNNER_DIRECTORY)/bin/xpcshell* \
    $(XULRUNNER_DIRECTORY)/b2g/xpcshell* \
  ))
ifneq (,$(XPCSHELL_GUESS))
XPCSHELLSDK := $(abspath $(XPCSHELL_GUESS))
XULRUNNERSDK := $(wildcard $(XPCSHELLSDK)/run-mozilla.sh)
endif

# Configuration for a downloaded b2g desktop
else

# Determine the host-dependent bundle to download
B2G_SDK_VERSION := 34.0a1
B2G_SDK_DATE := 2014/08/2014-08-12-04-02-01

XULRUNNER_BASE_DIR ?= b2g_sdk
XULRUNNER_DIRECTORY ?= $(XULRUNNER_BASE_DIR)/$(B2G_SDK_VERSION)-$(notdir $(B2G_SDK_DATE))
XULRUNNER_DIRECTORY := $(abspath $(XULRUNNER_DIRECTORY))

ifeq ($(SYS),Darwin)
B2G_SDK_EXT := dmg
B2G_SDK_OS := mac64
XPCSHELLSDK := $(abspath $(XULRUNNER_DIRECTORY)/B2G.app/Contents/MacOS/xpcshell)

else ifeq ($(findstring MINGW32,$(SYS)), MINGW32)
B2G_SDK_EXT := zip
B2G_SDK_OS := win32
XPCSHELLSDK := $(abspath $(XULRUNNER_DIRECTORY)/b2g/xpcshell.exe)

# Otherwise, assume linux
else
B2G_SDK_EXT := tar.bz2
ifeq ($(ARCH),x86_64)
B2G_SDK_OS := linux-x86_64
else
B2G_SDK_OS := linux-i686
endif
XPCSHELLSDK := $(abspath $(XULRUNNER_DIRECTORY)/b2g/xpcshell)
endif

B2G_SDK_URL_BASE := http://ftp.mozilla.org/pub/mozilla.org/b2g/nightly/$(B2G_SDK_DATE)-mozilla-central
B2G_SDK_FILE_NAME := b2g-$(B2G_SDK_VERSION).multi.$(B2G_SDK_OS).$(B2G_SDK_EXT)
B2G_SDK_URL := $(B2G_SDK_URL_BASE)/$(B2G_SDK_FILE_NAME)
B2G_SDK_URL_FILE := $(XULRUNNER_DIRECTORY)/.b2g.url

endif # Firefox build workaround

# XULRUNNERSDK used to be run-mozilla.sh, but some builds don't include it
# Without that, Linux needs to reference the directory containing libxul.so
ifeq (,$(XULRUNNERSDK)$(findstring Darwin,$(SYS))$(findstring MINGW32_,$(SYS)))
XULRUNNERSDK := LD_LIBRARY_PATH="$(dir $(XPCSHELLSDK))"
endif

# It's difficult to figure out XULRUNNERSDK in subprocesses; it's complex and
# some builders may want to override our find logic (ex: TBPL).
# So let's export these variables to external processes.
export XULRUNNER_DIRECTORY XULRUNNERSDK XPCSHELLSDK
export SYS
export GAIA_DIR
export SEP
export SEP_FOR_SED

# END gaia Makefile copy

