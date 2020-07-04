/**
 * @file libimobiledevice/libimobiledevice.h
 * @brief Device/Connection handling and communication
 * \internal
 *
 * Copyright (c) 2010-2019 Nikias Bassen All Rights Reserved.
 * Copyright (c) 2010-2014 Martin Szulecki All Rights Reserved.
 * Copyright (c) 2014 Christophe Fergeau All Rights Reserved.
 * Copyright (c) 2008 Jonathan Beck All Rights Reserved.
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

#ifndef IMOBILEDEVICE_H
#define IMOBILEDEVICE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <plist/plist.h>

/** Error Codes */
typedef enum {
	IDEVICE_E_SUCCESS         =  0,
	IDEVICE_E_INVALID_ARG     = -1,
	IDEVICE_E_UNKNOWN_ERROR   = -2,
	IDEVICE_E_NO_DEVICE       = -3,
	IDEVICE_E_NOT_ENOUGH_DATA = -4,
	IDEVICE_E_SSL_ERROR       = -6,
	IDEVICE_E_TIMEOUT         = -7
} idevice_error_t;

typedef struct idevice_private idevice_private;
typedef idevice_private *idevice_t; /**< The device handle. */

typedef struct idevice_connection_private idevice_connection_private;
typedef idevice_connection_private *idevice_connection_t; /**< The connection handle. */

/** Options for idevice_new_with_options() */
enum idevice_options {
	IDEVICE_LOOKUP_USBMUX = 1 << 1,  /**< include USBMUX devices during lookup */
	IDEVICE_LOOKUP_NETWORK = 1 << 2, /**< include network devices during lookup */
	IDEVICE_LOOKUP_PREFER_NETWORK = 1 << 3 /**< prefer network connection if device is available via USBMUX *and* network */
};

/** Type of connection a device is available on */
enum idevice_connection_type {
	CONNECTION_USBMUXD = 1,
	CONNECTION_NETWORK
};

struct idevice_info {
	char *udid;
	enum idevice_connection_type conn_type;
	void* conn_data;
};
typedef struct idevice_info* idevice_info_t;

/* discovery (events/asynchronous) */
/** The event type for device add or removal */
enum idevice_event_type {
	IDEVICE_DEVICE_ADD = 1,
	IDEVICE_DEVICE_REMOVE,
	IDEVICE_DEVICE_PAIRED
};

/* event data structure */
/** Provides information about the occurred event. */
typedef struct {
	enum idevice_event_type event; /**< The event type. */
	const char *udid; /**< The device unique id. */
	enum idevice_connection_type conn_type; /**< The connection type. */
} idevice_event_t;

/* event callback function prototype */
/** Callback to notifiy if a device was added or removed. */
typedef void (*idevice_event_cb_t) (const idevice_event_t *event, void *user_data);

/* functions */

/**
 * Set the level of debugging.
 *
 * @param level Set to 0 for no debug output or 1 to enable debug output.
 */
void idevice_set_debug_level(int level);

/**
 * Register a callback function that will be called when device add/remove
 * events occur.
 *
 * @param callback Callback function to call.
 * @param user_data Application-specific data passed as parameter
 *   to the registered callback function.
 *
 * @return IDEVICE_E_SUCCESS on success or an error value when an error occurred.
 */
idevice_error_t idevice_event_subscribe(idevice_event_cb_t callback, void *user_data);

/**
 * Release the event callback function that has been registered with
 *  idevice_event_subscribe().
 *
 * @return IDEVICE_E_SUCCESS on success or an error value when an error occurred.
 */
idevice_error_t idevice_event_unsubscribe(void);

/* discovery (synchronous) */

/**
 * Get a list of UDIDs of currently available devices (USBMUX devices only).
 *
 * @param devices List of UDIDs of devices that are currently available.
 *   This list is terminated by a NULL pointer.
 * @param count Number of devices found.
 *
 * @return IDEVICE_E_SUCCESS on success or an error value when an error occurred.
 *
 * @note This function only returns the UDIDs of USBMUX devices. To also include
 *   network devices in the list, use idevice_get_device_list_extended().
 * @see idevice_get_device_list_extended
 */
idevice_error_t idevice_get_device_list(char ***devices, int *count);

/**
 * Free a list of device UDIDs.
 *
 * @param devices List of UDIDs to free.
 *
 * @return Always returnes IDEVICE_E_SUCCESS.
 */
idevice_error_t idevice_device_list_free(char **devices);

/**
*获取当前可用设备的列表
*
* @param devices带设备信息的idevice_info_t记录列表。
*此列表以NULL指针终止。
* @param count列表中包含的设备数。
*
* @成功返回IDEVICE_E_SUCCESS或发生错误时返回错误值。
*/
idevice_error_t idevice_get_device_list_extended(idevice_info_t **devices, int *count);

/**
 * Free an extended device list retrieved through idevice_get_device_list_extended().
 *
 * @param devices Device list to free.
 *
 * @return IDEVICE_E_SUCCESS on success or an error value when an error occurred.
 */
idevice_error_t idevice_device_list_extended_free(idevice_info_t *devices);

/* device structure creation and destruction */

/**
 * Creates an idevice_t structure for the device specified by UDID,
 *  if the device is available (USBMUX devices only).
 *
 * @note The resulting idevice_t structure has to be freed with
 * idevice_free() if it is no longer used.
 * If you need to connect to a device available via network, use
 * idevice_new_with_options() and include IDEVICE_LOOKUP_NETWORK in options.
 *
 * @see idevice_new_with_options
 *
 * @param device Upon calling this function, a pointer to a location of type
 *  idevice_t. On successful return, this location will be populated.
 * @param udid The UDID to match.
 *
 * @return IDEVICE_E_SUCCESS if ok, otherwise an error code.
 */
idevice_error_t idevice_new(idevice_t *device, const char *udid);

/**
*为UDID指定的设备创建idevice_t结构，
*如果设备可用，则具有给定的查找选项。
*
* @note生成的idevice_t结构必须通过以下方式释放
* idevice_free（）（如果不再使用）。
*
* @param设备调用此函数后，将指向类型为location的指针
* idevice_t。成功返回后，将填充此位置。
* @param udd要匹配的UDID。
* @param选项指定应考虑的连接类型
*查找设备时。接受idevice_options的按位或“ ed”值。
*如果指定0（无选项），则默认为IDEVICE_LOOKUP_USBMUX。
*要同时查找USB和网络连接的设备，请通过
* IDEVICE_LOOKUP_USBMUX | IDEVICE_LOOKUP_NETWORK。如果有设备
*同时通过USBMUX *和*网络，它将选择USB连接。
*可通过添加IDEVICE_LOOKUP_PREFER_NETWORK来更改此行为
*选项，在这种情况下它将选择网络连接。
*
* @返回IDEVICE_E_SUCCESS（如果可以），否则返回错误代码。
*/
idevice_error_t idevice_new_with_options(idevice_t *device, const char *udid, enum idevice_options options);

/**
 * Cleans up an idevice structure, then frees the structure itself.
 *
 * @param device idevice_t to free.
 */
idevice_error_t idevice_free(idevice_t device);

/* connection/disconnection */

/**
*建立与给定设备的连接。
*
* @param device要连接的设备。
* @param port要连接的目标端口。
* @param connection指向将要填充的idevice_connection_t的指针
*带有连接的必要数据。
*
* @返回IDEVICE_E_SUCCESS（如果可以），否则返回错误代码。
*/
idevice_error_t idevice_connect(idevice_t device, uint16_t port, idevice_connection_t *connection);

/**
 * Disconnect from the device and clean up the connection structure.
 *
 * @param connection The connection to close.
 *
 * @return IDEVICE_E_SUCCESS if ok, otherwise an error code.
 */
idevice_error_t idevice_disconnect(idevice_connection_t connection);

/* communication */

/**
 * Send data to a device via the given connection.
 *
 * @param connection The connection to send data over.
 * @param data Buffer with data to send.
 * @param len Size of the buffer to send.
 * @param sent_bytes Pointer to an uint32_t that will be filled
 *   with the number of bytes actually sent.
 *
 * @return IDEVICE_E_SUCCESS if ok, otherwise an error code.
 */
idevice_error_t idevice_connection_send(idevice_connection_t connection, const char *data, uint32_t len, uint32_t *sent_bytes);

/**
*通过给定的连接从设备接收数据。
*即使没有数据，此函数也会在给定的超时后返回
*已收到。
*
* @param connection从中接收数据的连接。
* @param data将用接收到的数据填充的缓冲区。
*此缓冲区必须足够大以容纳len个字节。
* @param len缓冲区大小或要接收的字节数。
* @param recv_bytes实际接收的字节数。
* @param timeout超时（以毫秒为单位），此功能应在此之后超时
*即使没有收到数据也返回。
*
* @返回IDEVICE_E_SUCCESS（如果可以），否则返回错误代码。
*/
idevice_error_t idevice_connection_receive_timeout(idevice_connection_t connection, char *data, uint32_t len, uint32_t *recv_bytes, unsigned int timeout);

/**
 * Receive data from a device via the given connection.
 * This function is like idevice_connection_receive_timeout, but with a
 * predefined reasonable timeout.
 *
 * @param connection The connection to receive data from.
 * @param data Buffer that will be filled with the received data.
 *   This buffer has to be large enough to hold len bytes.
 * @param len Buffer size or number of bytes to receive.
 * @param recv_bytes Number of bytes actually received.
 *
 * @return IDEVICE_E_SUCCESS if ok, otherwise an error code.
 */
idevice_error_t idevice_connection_receive(idevice_connection_t connection, char *data, uint32_t len, uint32_t *recv_bytes);

/**
*为给定的连接启用SSL。
*
* @param connection启用SSL的连接。
*
* @成功返回IDEVICE_E_SUCCESS，连接成功则返回IDEVICE_E_INVALID_ARG
*为NULL或connection-> ssl_data为非NULL或IDEVICE_E_SSL_ERROR
* SSL初始化，设置或握手失败。
*/
idevice_error_t idevice_connection_enable_ssl(idevice_connection_t connection);

/**
 * Disable SSL for the given connection.
 *
 * @param connection The connection to disable SSL for.
 *
 * @return IDEVICE_E_SUCCESS on success, IDEVICE_E_INVALID_ARG when connection
 *     is NULL. This function also returns IDEVICE_E_SUCCESS when SSL is not
 *     enabled and does no further error checking on cleanup.
 */
idevice_error_t idevice_connection_disable_ssl(idevice_connection_t connection);

/**
 * Disable bypass SSL for the given connection without sending out terminate messages.
 *
 * @param connection The connection to disable SSL for.
 * @param sslBypass  if true ssl connection will not be terminated but just cleaned up, allowing
 *                   plain text data going on underlying connection
 *
 * @return IDEVICE_E_SUCCESS on success, IDEVICE_E_INVALID_ARG when connection
 *     is NULL. This function also returns IDEVICE_E_SUCCESS when SSL is not
 *     enabled and does no further error checking on cleanup.
 */
idevice_error_t idevice_connection_disable_bypass_ssl(idevice_connection_t connection, uint8_t sslBypass);


/**
*获取连接的基础文件描述符
*
* @param connection获得fd的连接
* @param fd指向存储fd的int的指针
*
* @返回IDEVICE_E_SUCCESS（如果可以），否则返回错误代码。
*/
idevice_error_t idevice_connection_get_fd(idevice_connection_t connection, int *fd);

/*其他*/

/**
  *获取设备的句柄或（usbmux设备ID）。
  */
idevice_error_t idevice_get_handle(idevice_t device, uint32_t *handle);

/**
*获取设备的唯一ID。
*/
idevice_error_t idevice_get_udid(idevice_t device, char **udid);

#ifdef __cplusplus
}
#endif

#endif

