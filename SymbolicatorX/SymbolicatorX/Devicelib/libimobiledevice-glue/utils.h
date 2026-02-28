/*
 * utils.h
 * Miscellaneous utilities for string manipulation,
 * file I/O, etc.
 *
 * Copyright (c) 2014-2019 Nikias Bassen, All Rights Reserved.
 * Copyright (c) 2013-2014 Martin Szulecki, All Rights Reserved.
 * Copyright (c) 2013 Federico Mena Quintero
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifndef __UTILS_H
#define __UTILS_H

#include <stdio.h>
#include <stdint.h>
#include <libimobiledevice-glue/glue.h>

#define MAC_EPOCH 978307200

#ifdef __cplusplus
extern "C" {
#endif

LIMD_GLUE_API char *string_concat(const char *str, ...);
LIMD_GLUE_API char *string_append(char *str, ...);
LIMD_GLUE_API char *string_build_path(const char *elem, ...);
LIMD_GLUE_API char *string_format_size(uint64_t size);
LIMD_GLUE_API char *string_toupper(char *str);
LIMD_GLUE_API char *generate_uuid(void);

LIMD_GLUE_API int buffer_read_from_filename(const char *filename, char **buffer, uint64_t *length);
LIMD_GLUE_API int buffer_write_to_filename(const char *filename, const char *buffer, uint64_t length);

#ifdef __cplusplus
}
#endif

#endif
