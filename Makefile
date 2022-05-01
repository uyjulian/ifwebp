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
BUILD_DIR_EXTERNAL_NAME ?= build-$(TARGET_ARCH)
export GIT_TAG := $(shell git describe --abbrev=0 --tags)
INCFLAGS += -I. -I.. -Iexternal/libwebp -Iexternal/libwebp/src
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
LDFLAGS += $(OPTFLAGS) -static -static-libgcc -Wl,--add-stdcall-alias -fPIC
LDFLAGS_LIB += -shared
LDLIBS +=

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

WEBP_DEC_SOURCES += external/libwebp/src/dec/alpha_dec.c external/libwebp/src/dec/buffer_dec.c external/libwebp/src/dec/frame_dec.c external/libwebp/src/dec/idec_dec.c external/libwebp/src/dec/io_dec.c external/libwebp/src/dec/quant_dec.c external/libwebp/src/dec/tree_dec.c external/libwebp/src/dec/vp8_dec.c external/libwebp/src/dec/vp8l_dec.c external/libwebp/src/dec/webp_dec.c external/libwebp/src/dsp/alpha_processing.c external/libwebp/src/dsp/cpu.c external/libwebp/src/dsp/dec.c external/libwebp/src/dsp/dec_clip_tables.c external/libwebp/src/dsp/filters.c external/libwebp/src/dsp/lossless.c external/libwebp/src/dsp/rescaler.c external/libwebp/src/dsp/upsampling.c external/libwebp/src/dsp/yuv.c external/libwebp/src/utils/bit_reader_utils.c external/libwebp/src/utils/color_cache_utils.c external/libwebp/src/utils/filters_utils.c external/libwebp/src/utils/huffman_utils.c external/libwebp/src/utils/quant_levels_dec_utils.c external/libwebp/src/utils/random_utils.c external/libwebp/src/utils/rescaler_utils.c external/libwebp/src/utils/thread_utils.c external/libwebp/src/utils/utils.c
WEBP_ENC_SOURCES += external/libwebp/src/demux/anim_decode.c external/libwebp/src/demux/demux.c external/libwebp/src/dsp/cost.c external/libwebp/src/dsp/enc.c external/libwebp/src/dsp/lossless_enc.c external/libwebp/src/dsp/ssim.c external/libwebp/src/enc/alpha_enc.c external/libwebp/src/enc/analysis_enc.c external/libwebp/src/enc/backward_references_cost_enc.c external/libwebp/src/enc/backward_references_enc.c external/libwebp/src/enc/config_enc.c external/libwebp/src/enc/cost_enc.c external/libwebp/src/enc/filter_enc.c external/libwebp/src/enc/frame_enc.c external/libwebp/src/enc/histogram_enc.c external/libwebp/src/enc/iterator_enc.c external/libwebp/src/enc/near_lossless_enc.c external/libwebp/src/enc/picture_csp_enc.c external/libwebp/src/enc/picture_enc.c external/libwebp/src/enc/picture_psnr_enc.c external/libwebp/src/enc/picture_rescale_enc.c external/libwebp/src/enc/picture_tools_enc.c external/libwebp/src/enc/predictor_enc.c external/libwebp/src/enc/quant_enc.c external/libwebp/src/enc/syntax_enc.c external/libwebp/src/enc/token_enc.c external/libwebp/src/enc/tree_enc.c external/libwebp/src/enc/vp8l_enc.c external/libwebp/src/enc/webp_enc.c external/libwebp/src/mux/anim_encode.c external/libwebp/src/mux/muxedit.c external/libwebp/src/mux/muxinternal.c external/libwebp/src/mux/muxread.c external/libwebp/src/utils/bit_writer_utils.c external/libwebp/src/utils/huffman_encode_utils.c external/libwebp/src/utils/quant_levels_utils.c
WEBP_SSE2_DEC_SOURCES += external/libwebp/src/dsp/alpha_processing_sse2.c external/libwebp/src/dsp/dec_sse2.c external/libwebp/src/dsp/filters_sse2.c external/libwebp/src/dsp/lossless_sse2.c external/libwebp/src/dsp/rescaler_sse2.c external/libwebp/src/dsp/upsampling_sse2.c external/libwebp/src/dsp/yuv_sse2.c
WEBP_SSE2_ENC_SOURCES += external/libwebp/src/dsp/cost_sse2.c external/libwebp/src/dsp/enc_sse2.c external/libwebp/src/dsp/lossless_enc_sse2.c external/libwebp/src/dsp/ssim_sse2.c
WEBP_SSE41_DEC_SOURCES += external/libwebp/src/dsp/alpha_processing_sse41.c external/libwebp/src/dsp/dec_sse41.c external/libwebp/src/dsp/lossless_sse41.c external/libwebp/src/dsp/upsampling_sse41.c external/libwebp/src/dsp/yuv_sse41.c
WEBP_SSE41_ENC_SOURCES += external/libwebp/src/dsp/enc_sse41.c external/libwebp/src/dsp/lossless_enc_sse41.c
SOURCES := extractor.c spi00in.c ifwebp.rc $(WEBP_DEC_SOURCES) $(WEBP_SSE2_DEC_SOURCES) $(WEBP_SSE41_DEC_SOURCES)
OBJECTS := $(SOURCES:.c=$(OBJECT_EXTENSION))
OBJECTS := $(OBJECTS:.cpp=$(OBJECT_EXTENSION))
OBJECTS := $(OBJECTS:.rc=$(OBJECT_EXTENSION))
DEPENDENCIES := $(OBJECTS:%$(OBJECT_EXTENSION)=%$(DEP_EXTENSION))
EXTERNAL_LIBS :=

$(WEBP_SSE2_DEC_SOURCES:.c=.o): CFLAGS += -msse2
$(WEBP_SSE41_DEC_SOURCES:.c=.o): CFLAGS += -msse4.1

.PHONY:: all archive clean

all: $(BINARY_STRIPPED)

archive: $(ARCHIVE)

clean::
	rm -f $(OBJECTS) $(OBJECTS_BIN) $(BINARY) $(BINARY_STRIPPED) $(ARCHIVE) $(DEPENDENCIES)

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
