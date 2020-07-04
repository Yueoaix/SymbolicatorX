/**
 * @file libimobiledevice/syslog_relay.h
 * @brief Capture the syslog output from a device.
 * \internal
 *
 * Copyright (c) 2019-2020 Nikias Bassen, All Rights Reserved.
 * Copyright (c) 2013-2014 Martin Szulecki, All Rights Reserved.
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

#ifndef ISYSLOG_RELAY_H
#define ISYSLOG_RELAY_H

#ifdef __cplusplus
extern "C" {
#endif

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/lockdown.h>

#define SYSLOG_RELAY_SERVICE_NAME "com.apple.syslog_relay"

/** Error Codes */
typedef enum {
	SYSLOG_RELAY_E_SUCCESS         =  0,
	SYSLOG_RELAY_E_INVALID_ARG     = -1,
	SYSLOG_RELAY_E_MUX_ERROR       = -2,
	SYSLOG_RELAY_E_SSL_ERROR       = -3,
	SYSLOG_RELAY_E_NOT_ENOUGH_DATA = -4,
	SYSLOG_RELAY_E_TIMEOUT         = -5,
	SYSLOG_RELAY_E_UNKNOWN_ERROR   = -256
} syslog_relay_error_t;

typedef struct syslog_relay_client_private syslog_relay_client_private;
typedef syslog_relay_client_private *syslog_relay_client_t; /**< The client handle. */

/** Receives each character received from the device. */
typedef void (*syslog_relay_receive_cb_t)(char c, void *user_data);

/* Interface */

/**
*连接到指定设备上的syslog_relay服务。
*
* @param device要连接的设备。
* @param service lockdownd_start_service返回的服务描述符。
* @param client指向新分配的客户端的指针
* syslog_relay_client_t成功返回后。 必须使用释放
*使用后为syslog_relay_client_free（）。
*
* @成功返回SYSLOG_RELAY_E_SUCCESS，当成功时返回SYSLOG_RELAY_E_INVALID_ARG
* client为NULL，否则为SYSLOG_RELAY_E_ *错误代码。
*/
syslog_relay_error_t syslog_relay_client_new(idevice_t device, lockdownd_service_descriptor_t service, syslog_relay_client_t * client);

/**
*在指定的设备上启动新的syslog_relay服务并连接到它。
*
* @param device要连接的设备。
* @param client指向新分配的客户端的指针
* syslog_relay_client_t成功返回后。 必须使用释放
*使用后为syslog_relay_client_free（）。
* @param标签用于通信的标签。 通常是程序名称。
*传递NULL以禁用将标签发送到lockdownd的请求中。
*
* @成功返回SYSLOG_RELAY_E_SUCCESS，否则返回SYSLOG_RELAY_E_ *错误
*否则为代码。
*/
syslog_relay_error_t syslog_relay_client_start_service(idevice_t device, syslog_relay_client_t * client, const char* label);

/**
 * Disconnects a syslog_relay client from the device and frees up the
 * syslog_relay client data.
 *
 * @param client The syslog_relay client to disconnect and free.
 *
 * @return SYSLOG_RELAY_E_SUCCESS on success, SYSLOG_RELAY_E_INVALID_ARG when
 *     client is NULL, or an SYSLOG_RELAY_E_* error code otherwise.
 */
syslog_relay_error_t syslog_relay_client_free(syslog_relay_client_t client);



/**
  *开始使用回调捕获设备的系统日志。
  *
  *使用syslog_relay_stop_capture（）停止接收syslog。
  *
  * @param client要使用的syslog_relay客户端
  * @param callback回调以从syslog接收每个字符。
  * @param user_data传递给回调函数的自定义指针。
  *
  * @成功返回SYSLOG_RELAY_E_SUCCESS，
  *当一个或多个参数为SYSLOG_RELAY_E_INVALID_ARG
  *未指定时无效或SYSLOG_RELAY_E_UNKNOWN_ERROR
  *发生错误或系统日志捕获已开始。
  */
syslog_relay_error_t syslog_relay_start_capture(syslog_relay_client_t client, syslog_relay_receive_cb_t callback, void* user_data);

/**
 * Starts capturing the *raw* syslog of the device using a callback.
 * This function is like syslog_relay_start_capture with the difference that
 * it will neither check nor process the received data before passing it to
 * the callback function.
 *
 * Use syslog_relay_stop_capture() to stop receiving the syslog.
 *
 * @note Use syslog_relay_start_capture for a safer implementation.
 *
 * @param client The syslog_relay client to use
 * @param callback Callback to receive each character from the syslog.
 * @param user_data Custom pointer passed to the callback function.
 *
 * @return SYSLOG_RELAY_E_SUCCESS on success,
 *      SYSLOG_RELAY_E_INVALID_ARG when one or more parameters are
 *      invalid or SYSLOG_RELAY_E_UNKNOWN_ERROR when an unspecified
 *      error occurs or a syslog capture has already been started.
 */
syslog_relay_error_t syslog_relay_start_capture_raw(syslog_relay_client_t client, syslog_relay_receive_cb_t callback, void* user_data);

/**
  *停止捕获设备的系统日志。
  *
  *使用syslog_relay_start_capture（）开始接收系统日志。
  *
  * @param client要使用的syslog_relay客户端
  *
  * @成功返回SYSLOG_RELAY_E_SUCCESS，
  *当一个或多个参数为SYSLOG_RELAY_E_INVALID_ARG
  *未指定时无效或SYSLOG_RELAY_E_UNKNOWN_ERROR
  *发生错误或系统日志捕获已开始。
  */
syslog_relay_error_t syslog_relay_stop_capture(syslog_relay_client_t client);

/* Receiving */

/**
*使用给定的syslog_relay客户端以指定的超时时间接收数据。
*
* @param客户端用于接收的syslog_relay客户端
* @param data缓冲区，将使用接收到的数据填充
* @param size接收的字节数
* @param收到的字节数（可以为NULL忽略）
* @param timeout等待数据的最长时间（以毫秒为单位）。
*
* @成功返回SYSLOG_RELAY_E_SUCCESS，
*当一个或多个参数为SYSLOG_RELAY_E_INVALID_ARG
*无效，发生通信错误时，SYSLOG_RELAY_E_MUX_ERROR
*发生，或者当未指定时发生SYSLOG_RELAY_E_UNKNOWN_ERROR
*发生错误。
*/
syslog_relay_error_t syslog_relay_receive_with_timeout(syslog_relay_client_t client, char *data, uint32_t size, uint32_t *received, unsigned int timeout);

/**
  *从服务接收数据。
  *
  * @param客户端syslog_relay客户端
  * @param data缓冲区，将使用接收到的数据填充
  * @param size接收的字节数
  * @param收到的字节数（可以为NULL忽略）
  * @param timeout等待数据的最长时间（以毫秒为单位）。
  *
  * @成功返回SYSLOG_RELAY_E_SUCCESS，
  *当客户端或plist为NULL时为SYSLOG_RELAY_E_INVALID_ARG
  */
syslog_relay_error_t syslog_relay_receive(syslog_relay_client_t client, char *data, uint32_t size, uint32_t *received);

#ifdef __cplusplus
}
#endif

#endif
