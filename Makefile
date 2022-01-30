#############################################
##                                         ##
##    Copyright (C) 2019-2021 Julian Uy    ##
##  https://sites.google.com/site/awertyb  ##
##                                         ##
##   See details of license at "LICENSE"   ##
##                                         ##
#############################################

TOOL_TRIPLET_PREFIX ?= i686-w64-mingw32-
CC := $(TOOL_TRIPLET_PREFIX)gcc
CXX := $(TOOL_TRIPLET_PREFIX)g++
AR := $(TOOL_TRIPLET_PREFIX)ar
WINDRES := $(TOOL_TRIPLET_PREFIX)windres
STRIP := $(TOOL_TRIPLET_PREFIX)strip
GIT_TAG := $(shell git describe --abbrev=0 --tags)
INCFLAGS += -I. -I.. -Iexternal/libwebp -Iexternal/libwebp/src
ALLSRCFLAGS += $(INCFLAGS) -DGIT_TAG=\"$(GIT_TAG)\"
CFLAGS += -O3 -flto
CFLAGS += $(ALLSRCFLAGS) -Wall -Wno-unused-value -Wno-format -DNDEBUG -DWIN32 -D_WIN32 -D_WINDOWS 
CFLAGS += -D_USRDLL -DUNICODE -D_UNICODE 
CFLAGS += -DWEBP_HAVE_SSE2 -DWEBP_HAVE_SSE41
CXXFLAGS += $(CFLAGS) -fpermissive
WINDRESFLAGS += $(ALLSRCFLAGS) --codepage=65001
LDFLAGS += -static -static-libgcc -shared -Wl,--add-stdcall-alias
LDLIBS +=

%.o: %.c
	@printf '\t%s %s\n' CC $<
	$(CC) -c $(CFLAGS) -o $@ $<

%.o: %.cpp
	@printf '\t%s %s\n' CXX $<
	$(CXX) -c $(CXXFLAGS) -o $@ $<

%.o: %.rc
	@printf '\t%s %s\n' WINDRES $<
	$(WINDRES) $(WINDRESFLAGS) $< $@

WEBP_DEC_SOURCES += external/libwebp/src/dec/alpha_dec.c external/libwebp/src/dec/buffer_dec.c external/libwebp/src/dec/frame_dec.c external/libwebp/src/dec/idec_dec.c external/libwebp/src/dec/io_dec.c external/libwebp/src/dec/quant_dec.c external/libwebp/src/dec/tree_dec.c external/libwebp/src/dec/vp8_dec.c external/libwebp/src/dec/vp8l_dec.c external/libwebp/src/dec/webp_dec.c external/libwebp/src/dsp/alpha_processing.c external/libwebp/src/dsp/cpu.c external/libwebp/src/dsp/dec.c external/libwebp/src/dsp/dec_clip_tables.c external/libwebp/src/dsp/filters.c external/libwebp/src/dsp/lossless.c external/libwebp/src/dsp/rescaler.c external/libwebp/src/dsp/upsampling.c external/libwebp/src/dsp/yuv.c external/libwebp/src/utils/bit_reader_utils.c external/libwebp/src/utils/color_cache_utils.c external/libwebp/src/utils/filters_utils.c external/libwebp/src/utils/huffman_utils.c external/libwebp/src/utils/quant_levels_dec_utils.c external/libwebp/src/utils/random_utils.c external/libwebp/src/utils/rescaler_utils.c external/libwebp/src/utils/thread_utils.c external/libwebp/src/utils/utils.c
WEBP_ENC_SOURCES += external/libwebp/src/demux/anim_decode.c external/libwebp/src/demux/demux.c external/libwebp/src/dsp/cost.c external/libwebp/src/dsp/enc.c external/libwebp/src/dsp/lossless_enc.c external/libwebp/src/dsp/ssim.c external/libwebp/src/enc/alpha_enc.c external/libwebp/src/enc/analysis_enc.c external/libwebp/src/enc/backward_references_cost_enc.c external/libwebp/src/enc/backward_references_enc.c external/libwebp/src/enc/config_enc.c external/libwebp/src/enc/cost_enc.c external/libwebp/src/enc/filter_enc.c external/libwebp/src/enc/frame_enc.c external/libwebp/src/enc/histogram_enc.c external/libwebp/src/enc/iterator_enc.c external/libwebp/src/enc/near_lossless_enc.c external/libwebp/src/enc/picture_csp_enc.c external/libwebp/src/enc/picture_enc.c external/libwebp/src/enc/picture_psnr_enc.c external/libwebp/src/enc/picture_rescale_enc.c external/libwebp/src/enc/picture_tools_enc.c external/libwebp/src/enc/predictor_enc.c external/libwebp/src/enc/quant_enc.c external/libwebp/src/enc/syntax_enc.c external/libwebp/src/enc/token_enc.c external/libwebp/src/enc/tree_enc.c external/libwebp/src/enc/vp8l_enc.c external/libwebp/src/enc/webp_enc.c external/libwebp/src/mux/anim_encode.c external/libwebp/src/mux/muxedit.c external/libwebp/src/mux/muxinternal.c external/libwebp/src/mux/muxread.c external/libwebp/src/utils/bit_writer_utils.c external/libwebp/src/utils/huffman_encode_utils.c external/libwebp/src/utils/quant_levels_utils.c
WEBP_SSE2_DEC_SOURCES += external/libwebp/src/dsp/alpha_processing_sse2.c external/libwebp/src/dsp/dec_sse2.c external/libwebp/src/dsp/filters_sse2.c external/libwebp/src/dsp/lossless_sse2.c external/libwebp/src/dsp/rescaler_sse2.c external/libwebp/src/dsp/upsampling_sse2.c external/libwebp/src/dsp/yuv_sse2.c
WEBP_SSE2_ENC_SOURCES += external/libwebp/src/dsp/cost_sse2.c external/libwebp/src/dsp/enc_sse2.c external/libwebp/src/dsp/lossless_enc_sse2.c external/libwebp/src/dsp/ssim_sse2.c
WEBP_SSE41_DEC_SOURCES += external/libwebp/src/dsp/alpha_processing_sse41.c external/libwebp/src/dsp/dec_sse41.c external/libwebp/src/dsp/lossless_sse41.c external/libwebp/src/dsp/upsampling_sse41.c external/libwebp/src/dsp/yuv_sse41.c
WEBP_SSE41_ENC_SOURCES += external/libwebp/src/dsp/enc_sse41.c external/libwebp/src/dsp/lossless_enc_sse41.c
SOURCES := extractor.c spi00in.c ifwebp.rc $(WEBP_DEC_SOURCES) $(WEBP_SSE2_DEC_SOURCES) $(WEBP_SSE41_DEC_SOURCES)
OBJECTS := $(SOURCES:.c=.o)
OBJECTS := $(OBJECTS:.cpp=.o)
OBJECTS := $(OBJECTS:.rc=.o)

$(WEBP_SSE2_DEC_SOURCES:.c=.o): CFLAGS += -msse2
$(WEBP_SSE41_DEC_SOURCES:.c=.o): CFLAGS += -msse4.1

BINARY ?= ifwebp_unstripped.spi
BINARY_STRIPPED ?= ifwebp.spi
ARCHIVE ?= ifwebp.7z

all: $(BINARY_STRIPPED)

archive: $(ARCHIVE)

clean:
	rm -f $(OBJECTS) $(BINARY) $(BINARY_STRIPPED) $(ARCHIVE)

$(ARCHIVE): $(BINARY_STRIPPED)
	rm -f $(ARCHIVE)
	7z a $@ $^

$(BINARY_STRIPPED): $(BINARY)
	@printf '\t%s %s\n' STRIP $@
	$(STRIP) -o $@ $^

$(BINARY): $(OBJECTS) 
	@printf '\t%s %s\n' LNK $@
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)
