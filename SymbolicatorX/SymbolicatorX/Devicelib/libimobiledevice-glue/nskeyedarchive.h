/*
 * nskeyedarchive.h
 * Helper code to work with plist files containing NSKeyedArchiver data.
 *
 * Copyright (c) 2019 Nikias Bassen, All Rights Reserved.
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
#ifndef __NSKEYEDARCHIVE_H
#define __NSKEYEDARCHIVE_H

#include <stdint.h>
#include <libimobiledevice-glue/glue.h>
#include <plist/plist.h>

enum nskeyedarchive_class_type_t {
	NSTYPE_INTEGER = 1,
	NSTYPE_BOOLEAN,
	NSTYPE_CHARS,
	NSTYPE_STRING,
	NSTYPE_REAL,
	NSTYPE_ARRAY,
	NSTYPE_DATA,
	NSTYPE_INTREF,
	NSTYPE_NSMUTABLESTRING,
	NSTYPE_NSSTRING,
	NSTYPE_NSMUTABLEARRAY,
	NSTYPE_NSARRAY,
	NSTYPE_NSMUTABLEDICTIONARY,
	NSTYPE_NSDICTIONARY,
	NSTYPE_NSDATE,
	NSTYPE_NSURL,
	NSTYPE_NSMUTABLEDATA,
	NSTYPE_NSDATA,
	NSTYPE_NSKEYEDARCHIVE,
	NSTYPE_FROM_PLIST
};

typedef struct nskeyedarchive_st *nskeyedarchive_t;

#ifdef __cplusplus
extern "C" {
#endif

LIMD_GLUE_API nskeyedarchive_t nskeyedarchive_new(void);
LIMD_GLUE_API nskeyedarchive_t nskeyedarchive_new_from_plist(plist_t plist);
LIMD_GLUE_API nskeyedarchive_t nskeyedarchive_new_from_data(const void* data, uint32_t size);
LIMD_GLUE_API void nskeyedarchive_free(nskeyedarchive_t ka);

LIMD_GLUE_API void nskeyedarchive_set_top_ref_key_name(nskeyedarchive_t ka, const char* keyname);

LIMD_GLUE_API uint64_t nskeyedarchive_add_top_class(nskeyedarchive_t ka, const char* classname, ...);
LIMD_GLUE_API void nskeyedarchive_add_top_class_uid(nskeyedarchive_t ka, uint64_t uid);
LIMD_GLUE_API void nskeyedarchive_append_class(nskeyedarchive_t ka, const char* classname, ...);
LIMD_GLUE_API void nskeyedarchive_append_object(nskeyedarchive_t ka, plist_t object);

LIMD_GLUE_API void nskeyedarchive_nsarray_append_item(nskeyedarchive_t ka, uint64_t uid, enum nskeyedarchive_class_type_t type, ...);
LIMD_GLUE_API void nskeyedarchive_nsdictionary_add_item(nskeyedarchive_t ka, uint64_t uid, const char* key, enum nskeyedarchive_class_type_t type, ...);

LIMD_GLUE_API void nskeyedarchive_append_class_type_v(nskeyedarchive_t ka, enum nskeyedarchive_class_type_t type, va_list* va);
LIMD_GLUE_API void nskeyedarchive_append_class_type(nskeyedarchive_t ka, enum nskeyedarchive_class_type_t type, ...);

LIMD_GLUE_API void nskeyedarchive_merge_object(nskeyedarchive_t ka, nskeyedarchive_t pka, plist_t object);

LIMD_GLUE_API void nskeyedarchive_print(nskeyedarchive_t ka);
LIMD_GLUE_API plist_t nskeyedarchive_get_plist_ref(nskeyedarchive_t ka);
LIMD_GLUE_API plist_t nskeyedarchive_get_object_by_uid(nskeyedarchive_t ka, uint64_t uid);
LIMD_GLUE_API plist_t nskeyedarchive_get_class_by_uid(nskeyedarchive_t ka, uint64_t uid);
LIMD_GLUE_API plist_t nskeyedarchive_get_objects(nskeyedarchive_t ka);

LIMD_GLUE_API uint64_t nskeyedarchive_get_class_uid(nskeyedarchive_t ka, const char* classref);
LIMD_GLUE_API const char* nskeyedarchive_get_classname(nskeyedarchive_t ka, uint64_t uid);

LIMD_GLUE_API void nskeyedarchive_set_class_property(nskeyedarchive_t ka, uint64_t uid, const char* propname, enum nskeyedarchive_class_type_t proptype, ...);
LIMD_GLUE_API int nskeyedarchive_get_class_uint64_property(nskeyedarchive_t ka, uint64_t uid, const char* propname, uint64_t* value);
LIMD_GLUE_API int nskeyedarchive_get_class_int_property(nskeyedarchive_t ka, uint64_t uid, const char* propname, int* value);
LIMD_GLUE_API int nskeyedarchive_get_class_string_property(nskeyedarchive_t ka, uint64_t uid, const char* propname, char** value);
LIMD_GLUE_API int nskeyedarchive_get_class_property(nskeyedarchive_t ka, uint64_t uid, const char* propname, plist_t* value);

LIMD_GLUE_API plist_t nskeyedarchive_to_plist(nskeyedarchive_t ka);

#ifdef __cplusplus
}
#endif

#endif
