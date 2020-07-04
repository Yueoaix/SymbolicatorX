/**
 * @file libimobiledevice/afc.h
 * @brief Access the filesystem on the device.
 * \internal
 *
 * Copyright (c) 2010-2014 Martin Szulecki All Rights Reserved.
 * Copyright (c) 2009-2010 Nikias Bassen All Rights Reserved.
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

#ifndef IAFC_H
#define IAFC_H

#ifdef __cplusplus
extern "C" {
#endif

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/lockdown.h>

#define AFC_SERVICE_NAME "com.apple.afc"

/** Error Codes */
typedef enum {
	AFC_E_SUCCESS               =  0,
	AFC_E_UNKNOWN_ERROR         =  1,
	AFC_E_OP_HEADER_INVALID     =  2,
	AFC_E_NO_RESOURCES          =  3,
	AFC_E_READ_ERROR            =  4,
	AFC_E_WRITE_ERROR           =  5,
	AFC_E_UNKNOWN_PACKET_TYPE   =  6,
	AFC_E_INVALID_ARG           =  7,
	AFC_E_OBJECT_NOT_FOUND      =  8,
	AFC_E_OBJECT_IS_DIR         =  9,
	AFC_E_PERM_DENIED           = 10,
	AFC_E_SERVICE_NOT_CONNECTED = 11,
	AFC_E_OP_TIMEOUT            = 12,
	AFC_E_TOO_MUCH_DATA         = 13,
	AFC_E_END_OF_DATA           = 14,
	AFC_E_OP_NOT_SUPPORTED      = 15,
	AFC_E_OBJECT_EXISTS         = 16,
	AFC_E_OBJECT_BUSY           = 17,
	AFC_E_NO_SPACE_LEFT         = 18,
	AFC_E_OP_WOULD_BLOCK        = 19,
	AFC_E_IO_ERROR              = 20,
	AFC_E_OP_INTERRUPTED        = 21,
	AFC_E_OP_IN_PROGRESS        = 22,
	AFC_E_INTERNAL_ERROR        = 23,
	AFC_E_MUX_ERROR             = 30,
	AFC_E_NO_MEM                = 31,
	AFC_E_NOT_ENOUGH_DATA       = 32,
	AFC_E_DIR_NOT_EMPTY         = 33,
	AFC_E_FORCE_SIGNED_TYPE     = -1
} afc_error_t;

/** Flags for afc_file_open */
typedef enum {
	AFC_FOPEN_RDONLY   = 0x00000001, /**< r   O_RDONLY */
	AFC_FOPEN_RW       = 0x00000002, /**< r+  O_RDWR   | O_CREAT */
	AFC_FOPEN_WRONLY   = 0x00000003, /**< w   O_WRONLY | O_CREAT  | O_TRUNC */
	AFC_FOPEN_WR       = 0x00000004, /**< w+  O_RDWR   | O_CREAT  | O_TRUNC */
	AFC_FOPEN_APPEND   = 0x00000005, /**< a   O_WRONLY | O_APPEND | O_CREAT */
	AFC_FOPEN_RDAPPEND = 0x00000006  /**< a+  O_RDWR   | O_APPEND | O_CREAT */
} afc_file_mode_t;

/** Type of link for afc_make_link() calls */
typedef enum {
	AFC_HARDLINK = 1,
	AFC_SYMLINK = 2
} afc_link_type_t;

/** Lock operation flags */
typedef enum {
	AFC_LOCK_SH = 1 | 4, /**< shared lock */
	AFC_LOCK_EX = 2 | 4, /**< exclusive lock */
	AFC_LOCK_UN = 8 | 4  /**< unlock */
} afc_lock_op_t;

typedef struct afc_client_private afc_client_private;
typedef afc_client_private *afc_client_t; /**< The client handle. */

/* Interface */

/**
 * Makes a connection to the AFC service on the device.
 *
 * @param device The device to connect to.
 * @param service The service descriptor returned by lockdownd_start_service.
 * @param client Pointer that will be set to a newly allocated afc_client_t
 *        upon successful return.
 *
 * @return AFC_E_SUCCESS on success, AFC_E_INVALID_ARG if device or service is
 *         invalid, AFC_E_MUX_ERROR if the connection cannot be established,
 *         or AFC_E_NO_MEM if there is a memory allocation problem.
 */
afc_error_t afc_client_new(idevice_t device, lockdownd_service_descriptor_t service, afc_client_t *client);

/**
 * Starts a new AFC service on the specified device and connects to it.
 *
 * @param device The device to connect to.
 * @param client Pointer that will point to a newly allocated afc_client_t upon
 *        successful return. Must be freed using afc_client_free() after use.
 * @param label The label to use for communication. Usually the program name.
 *        Pass NULL to disable sending the label in requests to lockdownd.
 *
 * @return AFC_E_SUCCESS on success, or an AFC_E_* error code otherwise.
 */
afc_error_t afc_client_start_service(idevice_t device, afc_client_t* client, const char* label);

/**
 * Frees up an AFC client. If the connection was created by the client itself,
 * the connection will be closed.
 *
 * @param client The client to free.
 */
afc_error_t afc_client_free(afc_client_t client);

/**
*获取已连接客户端的设备信息。 设备信息
*返回的是设备型号以及可用空间，总容量
*并在访问的磁盘分区上块化。
*
* @param client为其获取设备信息的客户端。
* @param device_information设备信息的字符列表，以空字符串或NULL（如果有错误）终止。 免费与
* afc_dictionary_free（）。
*
* @成功返回AFC_E_SUCCESS或错误值AFC_E_ *。
*/
afc_error_t afc_get_device_info(afc_client_t client, char ***device_information);

/**
*获取所请求目录的目录列表。
*
* @param client从中获取目录列表的客户端。
* @param path列出目录。 （必须是完全合格的路径）
* @param directory_information目录中文件的字符列表
*以空字符串终止，如果有错误，则以NULL终止。 免费与
* afc_dictionary_free（）。
*
* @成功返回AFC_E_SUCCESS或错误值AFC_E_ *。
*/
afc_error_t afc_read_directory(afc_client_t client, const char *path, char ***directory_information);

/**
*获取有关特定文件的信息。
*
* @param client用于获取文件信息的客户端。
* @param path文件的标准路径。
* @param file_information指向将被填充的缓冲区的指针
*以NULL终止的带有文件信息的字符串列表。 设为NULL
*在调用此函数之前。 使用afc_dictionary_free（）免费。
*
* @成功返回AFC_E_SUCCESS或错误值AFC_E_ *。
*/
afc_error_t afc_get_file_info(afc_client_t client, const char *path, char ***file_information);

/**
*在设备上打开文件。
*
* @param client用于打开文件的客户端。
* @param filename要打开的文件。 （必须是完全合格的路径）
* @param file_mode用于打开文件的模式。
* @param handle指向将保存文件句柄的uint64_t的指针
*
* @成功返回AFC_E_SUCCESS或错误值AFC_E_ *。
*/
afc_error_t afc_file_open(afc_client_t client, const char *filename, afc_file_mode_t file_mode, uint64_t *handle);

/**
*关闭设备上的文件。
*
* @param client客户端用来关闭文件的客户端。
* @param handle先前打开的文件的文件句柄。
*/
afc_error_t afc_file_close(afc_client_t client, uint64_t handle);

/**
*锁定或解锁设备上的文件。
*
*利用设备上的群集。
* @请参阅http://developer.apple.com/documentation/Darwin/Reference/ManPages/man2/flock.2.html
*
* @param client用来锁定文件的客户端。
* @param handle先前打开的文件的文件句柄。
* @param操作执行锁定或解锁操作，这是其中之一
* AFC_LOCK_SH（共享锁），AFC_LOCK_EX（排他锁）或
* AFC_LOCK_UN（解锁）。
*/
afc_error_t afc_file_lock(afc_client_t client, uint64_t handle, afc_lock_op_t operation);

/**
*尝试从给定文件中读取给定数目的字节。
*
* @param客户相关的AFC客户
* @param handle先前打开的文件的文件句柄
* @param data指向存储读取数据的存储区域的指针
* @param length要读取的字节数
* @param bytes_read实际读取的字节数。
*
* @成功返回AFC_E_SUCCESS或错误值AFC_E_ *。
*/
afc_error_t afc_file_read(afc_client_t client, uint64_t handle, char *data, uint32_t length, uint32_t *bytes_read);

/**
*将给定数量的字节写入文件。
*
* @param client用于写入文件的客户端。
* @param handle先前打开的文件的文件句柄。
* @param data要写入文件的数据。
* @param length要写入多少数据。
* @param bytes_write实际写入文件的字节数。
*
* @成功返回AFC_E_SUCCESS或错误值AFC_E_ *。
*/
afc_error_t afc_file_write(afc_client_t client, uint64_t handle, const char *data, uint32_t length, uint32_t *bytes_written);

/**
*寻找设备上预打开文件的给定位置。
*
* @param client客户用来寻找职位的客户。
* @param handle先前打开的文件句柄。
* @param offset寻找偏移量。
* @param wherece寻求方向，SEEK_SET，SEEK_CUR或SEEK_END之一。
*
* @成功返回AFC_E_SUCCESS或错误值AFC_E_ *。
*/
afc_error_t afc_file_seek(afc_client_t client, uint64_t handle, int64_t offset, int whence);

/**
*返回设备上预打开文件中的当前位置。
*
* @param client要使用的客户端。
* @param handle先前打开的文件的文件句柄。
* @param position指标的位置（以字节为单位）
*
* @成功返回AFC_E_SUCCESS或错误值AFC_E_ *。
*/
afc_error_t afc_file_tell(afc_client_t client, uint64_t handle, uint64_t *position);

/**
*设置设备上文件的大小。
*
* @param client用于设置文件大小的客户端。
* @param handle先前打开的文件的文件句柄。
* @param newsize设置文件的大小。
*
* @成功返回AFC_E_SUCCESS或错误值AFC_E_ *。
*
* @note此函数类似于ftruncate而不是truncate和truncate
*可悲的是，调用之前必须先打开文件。
*/
afc_error_t afc_file_truncate(afc_client_t client, uint64_t handle, uint64_t newsize);

/**
 * Deletes a file or directory.
 *
 * @param client The client to use.
 * @param path The path to delete. (must be a fully-qualified path)
 *
 * @return AFC_E_SUCCESS on success or an AFC_E_* error value.
 */
afc_error_t afc_remove_path(afc_client_t client, const char *path);

/**
 * Renames a file or directory on the device.
 *
 * @param client The client to have rename.
 * @param from The name to rename from. (must be a fully-qualified path)
 * @param to The new name. (must also be a fully-qualified path)
 *
 * @return AFC_E_SUCCESS on success or an AFC_E_* error value.
 */
afc_error_t afc_rename_path(afc_client_t client, const char *from, const char *to);

/**
 * Creates a directory on the device.
 *
 * @param client The client to use to make a directory.
 * @param path The directory's path. (must be a fully-qualified path, I assume
 *        all other mkdir restrictions apply as well)
 *
 * @return AFC_E_SUCCESS on success or an AFC_E_* error value.
 */
afc_error_t afc_make_directory(afc_client_t client, const char *path);

/**
*设置设备上文件的大小，而无需先打开它。
*
* @param client用于设置文件大小的客户端。
* @param path要截断的文件的路径。
* @param newsize设置文件的大小。
*
* @成功返回AFC_E_SUCCESS或错误值AFC_E_ *。
*/
afc_error_t afc_truncate(afc_client_t client, const char *path, uint64_t newsize);

/**
*在设备上创建硬链接或符号链接。
*
* @param client用来建立链接的客户端
* @param链接类型1 =硬链接，2 =符号链接
* @param target要链接的文件。
* @param linkname链接的名称。
*
* @成功返回AFC_E_SUCCESS或错误值AFC_E_ *。
*/
afc_error_t afc_make_link(afc_client_t client, afc_link_type_t linktype, const char *target, const char *linkname);

/**
*设置设备上文件的修改时间。
*
* @param client用于设置文件大小的客户端。
* @param path应该设置修改时间的文件的路径。
* @param mtime修改时间，自纪元以来以纳秒为单位设置。
*
* @成功返回AFC_E_SUCCESS或错误值AFC_E_ *。
*/
afc_error_t afc_set_file_time(afc_client_t client, const char *path, uint64_t mtime);

/**
 * Deletes a file or directory including possible contents.
 *
 * @param client The client to use.
 * @param path The path to delete. (must be a fully-qualified path)
 * @since libimobiledevice 1.1.7
 * @note Only available in iOS 6 and later.
 *
 * @return AFC_E_SUCCESS on success or an AFC_E_* error value.
 */
afc_error_t afc_remove_path_and_contents(afc_client_t client, const char *path);

/* Helper functions */

/**
 * Get a specific key of the device info list for a client connection.
 * Known key values are: Model, FSTotalBytes, FSFreeBytes and FSBlockSize.
 * This is a helper function for afc_get_device_info().
 *
 * @param client The client to get device info for.
 * @param key The key to get the value of.
 * @param value The value for the key if successful or NULL otherwise.
 *
 * @return AFC_E_SUCCESS on success or an AFC_E_* error value.
 */
afc_error_t afc_get_device_info_key(afc_client_t client, const char *key, char **value);

/**
 * Frees up a char dictionary as returned by some AFC functions.
 *
 * @param dictionary The char array terminated by an empty string.
 *
 * @return AFC_E_SUCCESS on success or an AFC_E_* error value.
 */
afc_error_t afc_dictionary_free(char **dictionary);

#ifdef __cplusplus
}
#endif

#endif
