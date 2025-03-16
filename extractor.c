/* SPDX-License-Identifier: MIT */
/* Copyright (c) ifwebp developers */

#include "extractor.h"
#include <stdio.h>
#include <string.h>
#include <webp/decode.h>

const char *plugin_info[4] = {
    "00IN",
    "WebP Plugin for Susie Image Viewer",
    "*.webp",
    "WebP file (*.webp)",
};

const int header_size = 64;

int getBMPFromWebP(const uint8_t *input_data, size_t file_size,
				   HANDLE* h_bitmap_info,
				   HANDLE* h_bitmap_data) {
	BITMAPINFOHEADER* bitmap_info_header = NULL;
	uint8_t *bitmap_data = NULL;

	int ret_result = -1;

	int width = 0;
	int height = 0;
	int bit_width = 0, bit_length = 0;
    size_t bitmap_size = 0;
	WebPDecoderConfig config;

	if (WebPInitDecoderConfig(&config) == FALSE) {
		goto cleanup;
	}
	if (WebPGetFeatures(input_data, file_size, &config.input) != VP8_STATUS_OK){
		goto cleanup;
	}

	width = config.input.width;
	height = config.input.height;
	bit_width = width * 4;
	bit_length = bit_width;
    bitmap_size = (size_t)bit_length * height;

	*h_bitmap_data = LocalAlloc(LMEM_MOVEABLE, bitmap_size);
	if (!*h_bitmap_data)
	{
		goto cleanup;
	}
	bitmap_data = (uint8_t*)LocalLock(*h_bitmap_data);
	if (!bitmap_data)
	{
		LocalFree(*h_bitmap_data);
		*h_bitmap_data = NULL;
		goto cleanup;
	}

	config.options.flip = 1;
	config.options.use_threads = 1;
	config.output.colorspace = MODE_BGRA;
	config.output.u.RGBA.rgba = bitmap_data;
	config.output.u.RGBA.stride = bit_length;
	config.output.u.RGBA.size = bitmap_size;
	config.output.is_external_memory = 1;

	if (WebPDecode(input_data, file_size, &config) != VP8_STATUS_OK) {
		goto cleanup;
	}

	*h_bitmap_info = LocalAlloc(LMEM_MOVEABLE | LMEM_ZEROINIT, sizeof(BITMAPINFO));
	if (NULL == *h_bitmap_info)
	{
		goto cleanup;
	}
	bitmap_info_header = (BITMAPINFOHEADER*)LocalLock(*h_bitmap_info);
	if (NULL == bitmap_info_header)
	{
		LocalFree(*h_bitmap_info);
		*h_bitmap_info = NULL;
		goto cleanup;
	}

	bitmap_info_header->biSize = sizeof(BITMAPINFOHEADER);
	bitmap_info_header->biWidth = width;
	bitmap_info_header->biHeight = height;
	bitmap_info_header->biPlanes = 1;
	bitmap_info_header->biBitCount = 32;
	bitmap_info_header->biCompression = BI_RGB;
	bitmap_info_header->biSizeImage = bitmap_size;

	LocalUnlock(*h_bitmap_data);
	LocalUnlock(*h_bitmap_info);

	ret_result = 0;

cleanup:
	if (ret_result && bitmap_data)
	{
		LocalUnlock(*h_bitmap_data);
		LocalFree(*h_bitmap_data);
		*h_bitmap_data = NULL;
	}
	if (ret_result && bitmap_info_header)
	{
		LocalUnlock(*h_bitmap_info);
		LocalFree(*h_bitmap_info);
		*h_bitmap_info = NULL;
	}

	return ret_result;
}

BOOL IsSupportedEx(const char *data) {
	if(strncmp(data, "RIFF", 4) == 0 && strncmp(data + 8, "WEBP", 4) == 0)
	{
		return TRUE;
	}

	return FALSE;
}

int GetPictureInfoEx(size_t data_size, const char *data,
                     SusiePictureInfo *picture_info) {
	int width, height;
	WebPGetInfo((const uint8_t *)data, data_size, &width, &height);

	picture_info->left = 0;
	picture_info->top = 0;
	picture_info->width = width;
	picture_info->height = height;
	picture_info->x_density = 0;
	picture_info->y_density = 0;
	picture_info->colorDepth = 32;
	picture_info->hInfo = NULL;

	return SPI_ALL_RIGHT;
}

int GetPictureEx(size_t data_size, HANDLE *bitmap_info, HANDLE *bitmap_data,
                 SPI_PROGRESS progress_callback, intptr_t user_data, const char *data) {
	if (progress_callback != NULL)
		if (progress_callback(1, 1, user_data))
			return SPI_ABORT;

	if (getBMPFromWebP((const uint8_t*)data, data_size, bitmap_info, bitmap_data))
		return SPI_MEMORY_ERROR;

	if (progress_callback != NULL)
		if (progress_callback(1, 1, user_data))
			return SPI_ABORT;

	return SPI_ALL_RIGHT;
}
