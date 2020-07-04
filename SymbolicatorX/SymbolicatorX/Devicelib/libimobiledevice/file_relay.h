/**
 * @file libimobiledevice/file_relay.h
 * @brief Retrieve compressed CPIO archives.
 * \internal
 *
 * Copyright (c) 2010-2014 Martin Szulecki All Rights Reserved.
 * Copyright (c) 2014 Aaron Burghardt All Rights Reserved.
 * Copyright (c) 2010 Nikias Bassen All Rights Reserved.
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

#ifndef IFILE_RELAY_H
#define IFILE_RELAY_H

#ifdef __cplusplus
extern "C" {
#endif

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/lockdown.h>

#define FILE_RELAY_SERVICE_NAME "com.apple.mobile.file_relay"

/** Error Codes */
typedef enum {
	FILE_RELAY_E_SUCCESS           =  0,
	FILE_RELAY_E_INVALID_ARG       = -1,
	FILE_RELAY_E_PLIST_ERROR       = -2,
	FILE_RELAY_E_MUX_ERROR         = -3,
	FILE_RELAY_E_INVALID_SOURCE    = -4,
	FILE_RELAY_E_STAGING_EMPTY     = -5,
	FILE_RELAY_E_PERMISSION_DENIED = -6,
	FILE_RELAY_E_UNKNOWN_ERROR     = -256
} file_relay_error_t;

typedef struct file_relay_client_private file_relay_client_private;
typedef file_relay_client_private *file_relay_client_t; /**< The client handle. */

/**
*连接到指定设备上的file_relay服务。
*
* @param device要连接的设备。
* @param service lockdownd_start_service返回的服务描述符。
* @param client引用将指向新分配的
*成功返回后的file_relay_client_t。
*
* @成功返回FILE_RELAY_E_SUCCESS，
*当其中一个参数无效时，FILE_RELAY_E_INVALID_ARG
*或FILE_RELAY_E_MUX_ERROR，当连接失败时。
*/
file_relay_error_t file_relay_client_new(idevice_t device, lockdownd_service_descriptor_t service, file_relay_client_t *client);


/**
  *在指定的设备上启动新的file_relay服务并连接到它。
  *
  * @param device要连接的设备。
  * @param client指向新分配的客户端的指针
  *成功返回后的file_relay_client_t。 必须使用释放
  * file_relay_client_free（）使用后。
  * @param标签用于通信的标签。 通常是程序名称。
  *传递NULL以禁用将标签发送到lockdownd的请求中。
  *
  * @成功返回FILE_RELAY_E_SUCCESS或FILE_RELAY_E_ *错误
  *否则为代码。
  */
file_relay_error_t file_relay_client_start_service(idevice_t device, file_relay_client_t* client, const char* label);

/**
 * Disconnects a file_relay client from the device and frees up the file_relay
 * client data.
 *
 * @param client The file_relay client to disconnect and free.
 *
 * @return FILE_RELAY_E_SUCCESS on success,
 *     FILE_RELAY_E_INVALID_ARG when one of client or client->parent
 *     is invalid, or FILE_RELAY_E_UNKNOWN_ERROR when the was an error
 *     freeing the parent property_list_service client.
 */
file_relay_error_t file_relay_client_free(file_relay_client_t client);


/**
 *请求给定来源的数据。
 *
 * @param client连接的file_relay客户端。
 * @param sources一个以NULL结尾的源列表。
 *有效来源是：
 *-Apple支持
 *-网络
 *-VPN
 *     - 无线上网
 *-UserDatabases
 *-CrashReporter
 *-tmp
 *     - 系统配置
 * @param connection必须用于接收
 *使用idevice_connection_receive（）的数据。连接将关闭
 *由设备自动执行，但使用file_relay_client_free（）进行清理
 *正确地。
 * @param timeout等待数据的最长时间（以毫秒为单位）。
 *
 * @note警告：请勿在未读取数据的情况下调用此函数。
 *用于创建档案的目录mobile_file_relay.XXXX将
 *否则保留在/ tmp目录中。
 *
 * @成功返回FILE_RELAY_E_SUCCESS，如果返回一个或多个，则返回FILE_RELAY_E_INVALID_ARG
 *更多参数无效，如果进行通信，则FILE_RELAY_E_MUX_ERROR
 *接收到的结果为NULL时发生错误，FILE_RELAY_E_PLIST_ERROR
 *或不是有效的plist，如果一个或多个，则为FILE_RELAY_E_INVALID_SOURCE
 *来源无效，如果没有可用数据，则为FILE_RELAY_E_STAGING_EMPTY
 *为给定的源，否则为FILE_RELAY_E_UNKNOWN_ERROR。
 */
file_relay_error_t file_relay_request_sources(file_relay_client_t client, const char **sources, idevice_connection_t *connection);

/**
 *请求给定来源的数据。用以下命令调用file_relay_request_sources_timeout（）
 * 60000毫秒（60秒）的超时。
 *
 * @param client连接的file_relay客户端。
 * @param sources一个以NULL结尾的源列表。
 *有效来源是：
 *-Apple支持
 *-网络
 *-VPN
 *     - 无线上网
 *-UserDatabases
 *-CrashReporter
 *-tmp
 *     - 系统配置
 * @param connection必须用于接收
 *使用idevice_connection_receive（）的数据。连接将关闭
 *由设备自动执行，但使用file_relay_client_free（）进行清理
 *正确地。
 *
 * @note警告：请勿在未读取数据的情况下调用此函数。
 *用于创建档案的目录mobile_file_relay.XXXX将
 *否则保留在/ tmp目录中。
 *
 * @成功返回FILE_RELAY_E_SUCCESS，如果返回一个或多个，则返回FILE_RELAY_E_INVALID_ARG
 *更多参数无效，如果进行通信，则FILE_RELAY_E_MUX_ERROR
 *接收到的结果为NULL时发生错误，FILE_RELAY_E_PLIST_ERROR
 *或不是有效的plist，如果一个或多个，则为FILE_RELAY_E_INVALID_SOURCE
 *来源无效，如果没有可用数据，则为FILE_RELAY_E_STAGING_EMPTY
 *为给定的源，否则为FILE_RELAY_E_UNKNOWN_ERROR。
 */
file_relay_error_t file_relay_request_sources_timeout(file_relay_client_t client, const char **sources, idevice_connection_t *connection, unsigned int timeout);

#ifdef __cplusplus
}
#endif

#endif
