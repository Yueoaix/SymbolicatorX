/**
 * @file libimobiledevice/house_arrest.h
 * @brief Access app folders and their contents.
 * \internal
 *
 * Copyright (c) 2013-2014 Martin Szulecki All Rights Reserved.
 * Copyright (c) 2010 Nikias Bassen, All Rights Reserved.
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

#ifndef IHOUSE_ARREST_H
#define IHOUSE_ARREST_H

#ifdef __cplusplus
extern "C" {
#endif

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/lockdown.h>
#include <libimobiledevice/afc.h>

#define HOUSE_ARREST_SERVICE_NAME "com.apple.mobile.house_arrest"

/** Error Codes */
typedef enum {
	HOUSE_ARREST_E_SUCCESS       =  0,
	HOUSE_ARREST_E_INVALID_ARG   = -1,
	HOUSE_ARREST_E_PLIST_ERROR   = -2,
	HOUSE_ARREST_E_CONN_FAILED   = -3,
	HOUSE_ARREST_E_INVALID_MODE  = -4,
	HOUSE_ARREST_E_UNKNOWN_ERROR = -256
} house_arrest_error_t;

typedef struct house_arrest_client_private house_arrest_client_private;
typedef house_arrest_client_private *house_arrest_client_t; /**< The client handle. */

/* Interface */

/**
 * Connects to the house_arrest service on the specified device.
 *
 * @param device The device to connect to.
 * @param service The service descriptor returned by lockdownd_start_service.
 * @param client Pointer that will point to a newly allocated
 *     housearrest_client_t upon successful return.
 *
 * @return HOUSE_ARREST_E_SUCCESS on success, HOUSE_ARREST_E_INVALID_ARG when
 *     client is NULL, or an HOUSE_ARREST_E_* error code otherwise.
 */
house_arrest_error_t house_arrest_client_new(idevice_t device, lockdownd_service_descriptor_t service, house_arrest_client_t *client);

/**
 * Starts a new house_arrest service on the specified device and connects to it.
 *
 * @param device The device to connect to.
 * @param client Pointer that will point to a newly allocated
 *     house_arrest_client_t upon successful return. Must be freed using
 *     house_arrest_client_free() after use.
 * @param label The label to use for communication. Usually the program name.
 *  Pass NULL to disable sending the label in requests to lockdownd.
 *
 * @return HOUSE_ARREST_E_SUCCESS on success, or an HOUSE_ARREST_E_* error
 *     code otherwise.
 */
house_arrest_error_t house_arrest_client_start_service(idevice_t device, house_arrest_client_t* client, const char* label);

/**
 * Disconnects an house_arrest client from the device and frees up the
 * house_arrest client data.
 *
 * @note After using afc_client_new_from_house_arrest_client(), make sure
 *     you call afc_client_free() before calling this function to ensure
 *     a proper cleanup. Do not call this function if you still need to
 *     perform AFC operations since it will close the connection.
 *
 * @param client The house_arrest client to disconnect and free.
 *
 * @return HOUSE_ARREST_E_SUCCESS on success, HOUSE_ARREST_E_INVALID_ARG when
 *     client is NULL, or an HOUSE_ARREST_E_* error code otherwise.
 */
house_arrest_error_t house_arrest_client_free(house_arrest_client_t client);


/**
*向连接的house_arrest服务发送一般请求。
*
* @param client要使用的house_arrest客户端。
* @param dict以PLIST_DICT类型的plist发送的请求。
*
* @note如果此函数返回HOUSE_ARREST_E_SUCCESS，则并不表示
*请求成功。 要检查成功或失败，您
*需要调用house_arrest_get_result（）。
* @see house_arrest_get_result
*
* @返回HOUSE_ARREST_E_SUCCESS，如果请求已成功发送，
* HOUSE_ARREST_E_INVALID_ARG如果客户端或字典无效，
* HOUSE_ARREST_E_PLIST_ERROR，如果dict不是PLIST_DICT类型的plist，
* HOUSE_ARREST_E_INVALID_MODE如果客户端未处于正确模式，
*或HOUSE_ARREST_E_CONN_FAILED（如果发生连接错误）。
*/
house_arrest_error_t house_arrest_send_request(house_arrest_client_t client, plist_t dict);

/**
*向连接的house_arrest服务发送命令。
*内部调用house_arrest_send_request（）。
*
* @param client要使用的house_arrest客户端。
* @param命令发送的命令。 目前，只有VendContainer和
* VendDocuments是已知的。
* @param appid与一起传递的应用程序标识符。
*
* @note如果此函数返回HOUSE_ARREST_E_SUCCESS，则并不表示
*命令成功。 要检查成功或失败，您
*需要调用house_arrest_get_result（）。
* @see house_arrest_get_result
*
* @返回HOUSE_ARREST_E_SUCCESS如果命令已成功发送，
* HOUSE_ARREST_E_INVALID_ARG如果客户端，命令或appid无效，
* HOUSE_ARREST_E_INVALID_MODE如果客户端未处于正确模式，
*或HOUSE_ARREST_E_CONN_FAILED（如果发生连接错误）。
*/
house_arrest_error_t house_arrest_send_command(house_arrest_client_t client, const char *command, const char *appid);

/**
*检索先前发送的house_arrest_request_ *请求的结果。
*
* @param client使用的house_arrest客户端
* @param dict指针，该指针将设置为包含结果的plist
*最后执行的操作。 它具有一个带有值的键“状态”
*成功时为“完成”，或错误说明为键“ Error”为
*值。 调用者负责释放返回的plist。
*
* @返回HOUSE_ARREST_E_SUCCESS，如果已检索到结果plist，
* HOUSE_ARREST_E_INVALID_ARG如果客户端无效，
* HOUSE_ARREST_E_INVALID_MODE如果客户端未处于正确模式，
*或HOUSE_ARREST_E_CONN_FAILED（如果发生连接错误）。
*/
house_arrest_error_t house_arrest_get_result(house_arrest_client_t client, plist_t *dict);


/**
*使用给定的house_arrest客户端连接创建AFC客户端
*允许文件访问由其请求的特定应用程序目录
*函数，例如house_arrest_request_vendor_documents（）。
*
* @param client要使用的house_arrest客户端。
* @param afc_client指针，它将设置为新分配的afc_client_t
*成功返回后。
*
* @note调用此函数后，house_arrest客户端将进入
*仅允许调用house_arrest_client_free（）的AFC模式。
*如果所有AFC操作都具有，则仅调用house_arrest_client_free（）
*已完成，因为它将关闭连接。
*
* @返回AFC_E_SUCCESS如果成功创建了afc客户端，
* AFC_E_INVALID_ARG如果客户端无效或已经用于创建客户端
* AFC客户端，或AFC_E_ *错误代码，返回
* afc_client_new_with_service_client（）。
*/
afc_error_t afc_client_new_from_house_arrest_client(house_arrest_client_t client, afc_client_t *afc_client);

#ifdef __cplusplus
}
#endif

#endif
