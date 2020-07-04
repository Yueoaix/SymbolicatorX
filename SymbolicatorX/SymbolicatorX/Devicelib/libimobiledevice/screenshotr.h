/**
 * @file libimobiledevice/screenshotr.h
 * @brief Retrieve a screenshot from device.
 * @note Requires a mounted developer image.
 * \internal
 *
 * Copyright (c) 2010-2019 Nikias Bassen, All Rights Reserved.
 * Copyright (c) 2010-2014 Martin Szulecki, All Rights Reserved.
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

#ifndef ISCREENSHOTR_H
#define ISCREENSHOTR_H

#ifdef __cplusplus
extern "C" {
#endif

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/lockdown.h>

#define SCREENSHOTR_SERVICE_NAME "com.apple.mobile.screenshotr"

/** Error Codes */
typedef enum {
	SCREENSHOTR_E_SUCCESS         =  0,
	SCREENSHOTR_E_INVALID_ARG     = -1,
	SCREENSHOTR_E_PLIST_ERROR     = -2,
	SCREENSHOTR_E_MUX_ERROR       = -3,
	SCREENSHOTR_E_SSL_ERROR       = -4,
	SCREENSHOTR_E_RECEIVE_TIMEOUT = -5,
	SCREENSHOTR_E_BAD_VERSION     = -6,
	SCREENSHOTR_E_UNKNOWN_ERROR   = -256
} screenshotr_error_t;

typedef struct screenshotr_client_private screenshotr_client_private;
typedef screenshotr_client_private *screenshotr_client_t; /**< The client handle. */


/**
*连接到指定设备上的屏幕快照程序服务。
*
* @param device要连接的设备。
* @param service lockdownd_start_service返回的服务描述符。
* @param客户端指针，它将设置为新分配的
*成功返回后的screenshotr_client_t。
*
* @note仅当开发者磁盘映像已被使用时，此服务才可用
*已安装。
*
* @成功返回SCREENSHOTR_E_SUCCESS，如果返回一个，则返回SCREENSHOTR_E_INVALID ARG
*或更多参数无效，或者如果SCREENSHOTR_E_CONN_FAILED
*无法建立与设备的连接。
*/
screenshotr_error_t screenshotr_client_new(idevice_t device, lockdownd_service_descriptor_t service, screenshotr_client_t * client);

/**
 * Starts a new screenshotr service on the specified device and connects to it.
 *
 * @param device The device to connect to.
 * @param client Pointer that will point to a newly allocated
 *     screenshotr_client_t upon successful return. Must be freed using
 *     screenshotr_client_free() after use.
 * @param label The label to use for communication. Usually the program name.
 *  Pass NULL to disable sending the label in requests to lockdownd.
 *
 * @return SCREENSHOTR_E_SUCCESS on success, or an SCREENSHOTR_E_* error
 *     code otherwise.
 */
screenshotr_error_t screenshotr_client_start_service(idevice_t device, screenshotr_client_t* client, const char* label);

/**
 * Disconnects a screenshotr client from the device and frees up the
 * screenshotr client data.
 *
 * @param client The screenshotr client to disconnect and free.
 *
 * @return SCREENSHOTR_E_SUCCESS on success, or SCREENSHOTR_E_INVALID_ARG
 *     if client is NULL.
 */
screenshotr_error_t screenshotr_client_free(screenshotr_client_t client);


/**
*从连接的设备获取屏幕截图。
*
* @param client连接截图服务客户端。
* @param imgdata指向新分配的缓冲区的指针
*成功返回后包含TIFF图像数据。 这取决于
*调用方释放内存。
* @param imgsize指向uint64_t的指针，该指针将设置为
*缓冲区imgdata成功返回时指向。
*
* @成功返回SCREENSHOTR_E_SUCCESS，如果成功则返回SCREENSHOTR_E_INVALID_ARG
*一个或多个参数无效，如果一个或多个参数无效，则另一个错误代码
*     错误发生。
*/
screenshotr_error_t screenshotr_take_screenshot(screenshotr_client_t client, char **imgdata, uint64_t *imgsize);

#ifdef __cplusplus
}
#endif

#endif
