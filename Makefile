#############################################
##                                         ##
##    Copyright (C) 2019-2022 Julian Uy    ##
##  https://sites.google.com/site/awertyb  ##
##                                         ##
##   See details of license at "LICENSE"   ##
##                                         ##
#############################################

TARGET_ARCH ?= intel32
USE_STABS_DEBUG ?= 0
USE_POSITION_INDEPENDENT_CODE ?= 0
USE_ARCHIVE_HAS_GIT_TAG ?= 0
ifeq (x$(TARGET_ARCH),xarm32)
TOOL_TRIPLET_PREFIX ?= armv7-w64-mingw32-
endif
ifeq (x$(TARGET_ARCH),xarm64)
TOOL_TRIPLET_PREFIX ?= aarch64-w64-mingw32-
endif
ifeq (x$(TARGET_ARCH),xintel64)
TOOL_TRIPLET_PREFIX ?= x86_64-w64-mingw32-
endif
TOOL_TRIPLET_PREFIX ?= i686-w64-mingw32-
ifeq (x$(TARGET_ARCH),xarm32)
TARGET_CMAKE_SYSTEM_PROCESSOR ?= arm
endif
ifeq (x$(TARGET_ARCH),xarm64)
TARGET_CMAKE_SYSTEM_PROCESSOR ?= arm64
endif
ifeq (x$(TARGET_ARCH),xintel64)
TARGET_CMAKE_SYSTEM_PROCESSOR ?= amd64
endif
TARGET_CMAKE_SYSTEM_PROCESSOR ?= i686
CC := $(TOOL_TRIPLET_PREFIX)gcc
CXX := $(TOOL_TRIPLET_PREFIX)g++
AR := $(TOOL_TRIPLET_PREFIX)ar
WINDRES := $(TOOL_TRIPLET_PREFIX)windres
STRIP := $(TOOL_TRIPLET_PREFIX)strip
7Z := 7z
ifeq (x$(TARGET_ARCH),xintel32)
OBJECT_EXTENSION ?= .o
endif
OBJECT_EXTENSION ?= .$(TARGET_ARCH).o
DEP_EXTENSION ?= .dep.make
export GIT_TAG := $(shell git describe --abbrev=0 --tags)
INCFLAGS += -I. -I..
ALLSRCFLAGS += $(INCFLAGS) -DGIT_TAG=\"$(GIT_TAG)\"
OPTFLAGS := -O3
ifeq (x$(TARGET_ARCH),xintel32)
OPTFLAGS += -march=pentium4 -mfpmath=sse
endif
ifeq (x$(TARGET_ARCH),xintel32)
ifneq (x$(USE_STABS_DEBUG),x0)
CFLAGS += -gstabs
else
CFLAGS += -gdwarf-2
endif
else
CFLAGS += -gdwarf-2
endif

ifneq (x$(USE_POSITION_INDEPENDENT_CODE),x0)
CFLAGS += -fPIC
endif
CFLAGS += -flto
CFLAGS += $(ALLSRCFLAGS) -Wall -Wno-unused-value -Wno-format -DNDEBUG -DWIN32 -D_WIN32 -D_WINDOWS 
CFLAGS += -D_USRDLL -DMINGW_HAS_SECURE_API -DUNICODE -D_UNICODE -DNO_STRICT
CFLAGS += -MMD -MF $(patsubst %$(OBJECT_EXTENSION),%$(DEP_EXTENSION),$@)
ifeq (x$(TARGET_ARCH),xintel32)
CFLAGS += -DWEBP_HAVE_SSE2 -DWEBP_HAVE_SSE41
endif
ifeq (x$(TARGET_ARCH),xintel64)
CFLAGS += -DWEBP_HAVE_SSE2 -DWEBP_HAVE_SSE41
endif
CXXFLAGS += $(CFLAGS) -fpermissive
WINDRESFLAGS += $(ALLSRCFLAGS) --codepage=65001
LDFLAGS += $(OPTFLAGS) -static -static-libgcc -Wl,--kill-at -fPIC
LDFLAGS_LIB += -shared
LDLIBS +=

DEPENDENCY_SOURCE_DIRECTORY := $(abspath build-source)
DEPENDENCY_BUILD_DIRECTORY := $(abspath build-$(TARGET_ARCH))
DEPENDENCY_OUTPUT_DIRECTORY := $(abspath build-libraries)-$(TARGET_ARCH)

INCFLAGS += -I$(DEPENDENCY_OUTPUT_DIRECTORY)/include

%$(OBJECT_EXTENSION): %.c
	@printf '\t%s %s\n' CC $<
	$(CC) -c $(CFLAGS) $(OPTFLAGS) -o $@ $<

%$(OBJECT_EXTENSION): %.cpp
	@printf '\t%s %s\n' CXX $<
	$(CXX) -c $(CXXFLAGS) $(OPTFLAGS) -o $@ $<

%$(OBJECT_EXTENSION): %.rc
	@printf '\t%s %s\n' WINDRES $<
	$(WINDRES) $(WINDRESFLAGS) $< $@

PROJECT_BASENAME ?= ifwebp
ifeq (x$(TARGET_ARCH),xintel32)
BINARY ?= $(PROJECT_BASENAME)_unstripped.spi
endif
ifeq (x$(TARGET_ARCH),xintel64)
BINARY ?= $(PROJECT_BASENAME)_unstripped.sph
endif
BINARY ?= $(PROJECT_BASENAME)_$(TARGET_ARCH)_unstripped.spi
ifeq (x$(TARGET_ARCH),xintel32)
BINARY_STRIPPED ?= $(PROJECT_BASENAME).spi
endif
ifeq (x$(TARGET_ARCH),xintel64)
BINARY_STRIPPED ?= $(PROJECT_BASENAME).sph
endif
BINARY_STRIPPED ?= $(PROJECT_BASENAME)_$(TARGET_ARCH).spi
ifneq (x$(USE_ARCHIVE_HAS_GIT_TAG),x0)
ARCHIVE ?= $(PROJECT_BASENAME).$(TARGET_ARCH).$(GIT_TAG).7z
endif
ARCHIVE ?= $(PROJECT_BASENAME).$(TARGET_ARCH).7z

LIBWEBP_LIBS += $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libwebp.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libwebpdemux.a
SOURCES := extractor.c spi00in.c ifwebp.rc
OBJECTS := $(SOURCES:.c=$(OBJECT_EXTENSION))
OBJECTS := $(OBJECTS:.cpp=$(OBJECT_EXTENSION))
OBJECTS := $(OBJECTS:.rc=$(OBJECT_EXTENSION))
DEPENDENCIES := $(OBJECTS:%$(OBJECT_EXTENSION)=%$(DEP_EXTENSION))
EXTERNAL_LIBS := $(LIBWEBP_LIBS)

.PHONY:: all archive clean

all: $(BINARY_STRIPPED)

archive: $(ARCHIVE)

clean::
	rm -f $(OBJECTS) $(OBJECTS_BIN) $(BINARY) $(BINARY_STRIPPED) $(ARCHIVE) $(DEPENDENCIES)
	rm -rf $(DEPENDENCY_SOURCE_DIRECTORY) $(DEPENDENCY_BUILD_DIRECTORY) $(DEPENDENCY_OUTPUT_DIRECTORY)

$(DEPENDENCY_SOURCE_DIRECTORY):
	mkdir -p $@

$(DEPENDENCY_OUTPUT_DIRECTORY):
	mkdir -p $@

$(ARCHIVE): $(BINARY_STRIPPED) $(EXTRA_DIST)
	@printf '\t%s %s\n' 7Z $@
	rm -f $(ARCHIVE)
	$(7Z) a $@ $^

$(BINARY_STRIPPED): $(BINARY)
	@printf '\t%s %s\n' STRIP $@
	$(STRIP) -o $@ $^

$(BINARY): $(OBJECTS) $(EXTERNAL_LIBS)
	@printf '\t%s %s\n' LNK $@
	$(CC) $(CFLAGS) $(LDFLAGS) $(LDFLAGS_LIB) -o $@ $^ $(LDLIBS)

-include $(DEPENDENCIES)

extractor$(OBJECT_EXTENSION): $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libwebp.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libwebpdemux.a

DEPENDENCY_SOURCE_DIRECTORY_LIBWEBP := $(DEPENDENCY_SOURCE_DIRECTORY)/libwebp

DEPENDENCY_SOURCE_FILE_LIBWEBP := $(DEPENDENCY_SOURCE_DIRECTORY)/libwebp.tar.xz

DEPENDENCY_SOURCE_URL_LIBWEBP := https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.3.2.tar.gz

$(DEPENDENCY_SOURCE_FILE_LIBWEBP): | $(DEPENDENCY_SOURCE_DIRECTORY)
	curl --location --output $@ $(DEPENDENCY_SOURCE_URL_LIBWEBP)

$(DEPENDENCY_SOURCE_DIRECTORY_LIBWEBP): $(DEPENDENCY_SOURCE_FILE_LIBWEBP)
	mkdir -p $@
	tar -x -f $< -C $@ --strip-components 1

DEPENDENCY_BUILD_DIRECTORY_LIBWEBP := $(DEPENDENCY_BUILD_DIRECTORY)/libwebp

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libwebpdemux.a: $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libwebp.a

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libwebp.a: | $(DEPENDENCY_SOURCE_DIRECTORY_LIBWEBP) $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_LIBWEBP) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_LIBWEBP) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	CPPFLAGS="-I$(DEPENDENCY_OUTPUT_DIRECTORY)/include" \
	LDFLAGS="-L$(DEPENDENCY_OUTPUT_DIRECTORY)/lib" \
	$(DEPENDENCY_SOURCE_DIRECTORY_LIBWEBP)/configure \
		CFLAGS="-O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--host=$(patsubst %-,%,$(TOOL_TRIPLET_PREFIX)) \
		--enable-static \
		--disable-shared \
	&& \
	$(MAKE) && \
	$(MAKE) install
