/*
 * tss.h
 * Definitions for communicating with Apple's TSS server.
 *
 * Copyright (c) 2012-2024 Nikias Bassen, All Rights Reserved.
 * Copyright (c) 2013 Martin Szulecki. All Rights Reserved.
 * Copyright (c) 2010 Joshua Hill. All Rights Reserved.
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

#ifndef LIBTATSU_TSS_H
#define LIBTATSU_TSS_H

#include <libtatsu/tatsu.h>
#include <plist/plist.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* parameters */
LIBTATSU_API int tss_parameters_add_from_manifest(plist_t parameters, plist_t build_identity, bool include_manifest);

/* request */
LIBTATSU_API plist_t tss_request_new(plist_t overrides);

LIBTATSU_API int tss_request_add_local_policy_tags(plist_t request, plist_t parameters);
LIBTATSU_API int tss_request_add_common_tags(plist_t request, plist_t parameters, plist_t overrides);
LIBTATSU_API int tss_request_add_ap_tags(plist_t request, plist_t parameters, plist_t overrides);
LIBTATSU_API int tss_request_add_ap_recovery_tags(plist_t request, plist_t parameters, plist_t overrides);
LIBTATSU_API int tss_request_add_baseband_tags(plist_t request, plist_t parameters, plist_t overrides);
LIBTATSU_API int tss_request_add_se_tags(plist_t request, plist_t parameters, plist_t overrides);
LIBTATSU_API int tss_request_add_savage_tags(plist_t request, plist_t parameters, plist_t overrides, char **component_name);
LIBTATSU_API int tss_request_add_yonkers_tags(plist_t request, plist_t parameters, plist_t overrides, char **component_name);
LIBTATSU_API int tss_request_add_vinyl_tags(plist_t request, plist_t parameters, plist_t overrides);
LIBTATSU_API int tss_request_add_rose_tags(plist_t request, plist_t parameters, plist_t overrides);
LIBTATSU_API int tss_request_add_veridian_tags(plist_t request, plist_t parameters, plist_t overrides);
LIBTATSU_API int tss_request_add_tcon_tags(plist_t request, plist_t parameters, plist_t overrides);
LIBTATSU_API int tss_request_add_timer_tags(plist_t request, plist_t parameters, plist_t overrides);
LIBTATSU_API int tss_request_add_cryptex_tags(plist_t request, plist_t parameters, plist_t overrides);

LIBTATSU_API int tss_request_add_ap_img4_tags(plist_t request, plist_t parameters);
LIBTATSU_API int tss_request_add_ap_img3_tags(plist_t request, plist_t parameters);

/* i/o */
LIBTATSU_API plist_t tss_request_send(plist_t request, const char* server_url_string);

/* response */
LIBTATSU_API int tss_response_get_ap_img4_ticket(plist_t response, unsigned char** ticket, unsigned int* length);
LIBTATSU_API int tss_response_get_ap_ticket(plist_t response, unsigned char** ticket, unsigned int* length);
LIBTATSU_API int tss_response_get_baseband_ticket(plist_t response, unsigned char** ticket, unsigned int* length);
LIBTATSU_API int tss_response_get_path_by_entry(plist_t response, const char* entry, char** path);
LIBTATSU_API int tss_response_get_blob_by_path(plist_t response, const char* path, unsigned char** blob);
LIBTATSU_API int tss_response_get_blob_by_entry(plist_t response, const char* entry, unsigned char** blob);

LIBTATSU_API void tss_set_debug_level(int level);

#ifdef __cplusplus
}
#endif

#endif
