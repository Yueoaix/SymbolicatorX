/**
 * @file libimobiledevice/installation_proxy.h
 * @brief Manage applications on a device.
 * \internal
 *
 * Copyright (c) 2010-2015 Martin Szulecki All Rights Reserved.
 * Copyright (c) 2014 Christophe Fergeau All Rights Reserved.
 * Copyright (c) 2009-2012 Nikias Bassen All Rights Reserved.
 * Copyright (c) 2010 Bryan Forbes All Rights Reserved.
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

#ifndef IINSTALLATION_PROXY_H
#define IINSTALLATION_PROXY_H

#ifdef __cplusplus
extern "C" {
#endif

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/lockdown.h>

#define INSTPROXY_SERVICE_NAME "com.apple.mobile.installation_proxy"

/** Error Codes */
typedef enum {
	/* custom */
	INSTPROXY_E_SUCCESS                                                   =  0,
	INSTPROXY_E_INVALID_ARG                                               = -1,
	INSTPROXY_E_PLIST_ERROR                                               = -2,
	INSTPROXY_E_CONN_FAILED                                               = -3,
	INSTPROXY_E_OP_IN_PROGRESS                                            = -4,
	INSTPROXY_E_OP_FAILED                                                 = -5,
	INSTPROXY_E_RECEIVE_TIMEOUT                                           = -6,
	/* native */
	INSTPROXY_E_ALREADY_ARCHIVED                                          = -7,
	INSTPROXY_E_API_INTERNAL_ERROR                                        = -8,
	INSTPROXY_E_APPLICATION_ALREADY_INSTALLED                             = -9,
	INSTPROXY_E_APPLICATION_MOVE_FAILED                                   = -10,
	INSTPROXY_E_APPLICATION_SINF_CAPTURE_FAILED                           = -11,
	INSTPROXY_E_APPLICATION_SANDBOX_FAILED                                = -12,
	INSTPROXY_E_APPLICATION_VERIFICATION_FAILED                           = -13,
	INSTPROXY_E_ARCHIVE_DESTRUCTION_FAILED                                = -14,
	INSTPROXY_E_BUNDLE_VERIFICATION_FAILED                                = -15,
	INSTPROXY_E_CARRIER_BUNDLE_COPY_FAILED                                = -16,
	INSTPROXY_E_CARRIER_BUNDLE_DIRECTORY_CREATION_FAILED                  = -17,
	INSTPROXY_E_CARRIER_BUNDLE_MISSING_SUPPORTED_SIMS                     = -18,
	INSTPROXY_E_COMM_CENTER_NOTIFICATION_FAILED                           = -19,
	INSTPROXY_E_CONTAINER_CREATION_FAILED                                 = -20,
	INSTPROXY_E_CONTAINER_P0WN_FAILED                                     = -21,
	INSTPROXY_E_CONTAINER_REMOVAL_FAILED                                  = -22,
	INSTPROXY_E_EMBEDDED_PROFILE_INSTALL_FAILED                           = -23,
	INSTPROXY_E_EXECUTABLE_TWIDDLE_FAILED                                 = -24,
	INSTPROXY_E_EXISTENCE_CHECK_FAILED                                    = -25,
	INSTPROXY_E_INSTALL_MAP_UPDATE_FAILED                                 = -26,
	INSTPROXY_E_MANIFEST_CAPTURE_FAILED                                   = -27,
	INSTPROXY_E_MAP_GENERATION_FAILED                                     = -28,
	INSTPROXY_E_MISSING_BUNDLE_EXECUTABLE                                 = -29,
	INSTPROXY_E_MISSING_BUNDLE_IDENTIFIER                                 = -30,
	INSTPROXY_E_MISSING_BUNDLE_PATH                                       = -31,
	INSTPROXY_E_MISSING_CONTAINER                                         = -32,
	INSTPROXY_E_NOTIFICATION_FAILED                                       = -33,
	INSTPROXY_E_PACKAGE_EXTRACTION_FAILED                                 = -34,
	INSTPROXY_E_PACKAGE_INSPECTION_FAILED                                 = -35,
	INSTPROXY_E_PACKAGE_MOVE_FAILED                                       = -36,
	INSTPROXY_E_PATH_CONVERSION_FAILED                                    = -37,
	INSTPROXY_E_RESTORE_CONTAINER_FAILED                                  = -38,
	INSTPROXY_E_SEATBELT_PROFILE_REMOVAL_FAILED                           = -39,
	INSTPROXY_E_STAGE_CREATION_FAILED                                     = -40,
	INSTPROXY_E_SYMLINK_FAILED                                            = -41,
	INSTPROXY_E_UNKNOWN_COMMAND                                           = -42,
	INSTPROXY_E_ITUNES_ARTWORK_CAPTURE_FAILED                             = -43,
	INSTPROXY_E_ITUNES_METADATA_CAPTURE_FAILED                            = -44,
	INSTPROXY_E_DEVICE_OS_VERSION_TOO_LOW                                 = -45,
	INSTPROXY_E_DEVICE_FAMILY_NOT_SUPPORTED                               = -46,
	INSTPROXY_E_PACKAGE_PATCH_FAILED                                      = -47,
	INSTPROXY_E_INCORRECT_ARCHITECTURE                                    = -48,
	INSTPROXY_E_PLUGIN_COPY_FAILED                                        = -49,
	INSTPROXY_E_BREADCRUMB_FAILED                                         = -50,
	INSTPROXY_E_BREADCRUMB_UNLOCK_FAILED                                  = -51,
	INSTPROXY_E_GEOJSON_CAPTURE_FAILED                                    = -52,
	INSTPROXY_E_NEWSSTAND_ARTWORK_CAPTURE_FAILED                          = -53,
	INSTPROXY_E_MISSING_COMMAND                                           = -54,
	INSTPROXY_E_NOT_ENTITLED                                              = -55,
	INSTPROXY_E_MISSING_PACKAGE_PATH                                      = -56,
	INSTPROXY_E_MISSING_CONTAINER_PATH                                    = -57,
	INSTPROXY_E_MISSING_APPLICATION_IDENTIFIER                            = -58,
	INSTPROXY_E_MISSING_ATTRIBUTE_VALUE                                   = -59,
	INSTPROXY_E_LOOKUP_FAILED                                             = -60,
	INSTPROXY_E_DICT_CREATION_FAILED                                      = -61,
	INSTPROXY_E_INSTALL_PROHIBITED                                        = -62,
	INSTPROXY_E_UNINSTALL_PROHIBITED                                      = -63,
	INSTPROXY_E_MISSING_BUNDLE_VERSION                                    = -64,
	INSTPROXY_E_UNKNOWN_ERROR                                             = -256
} instproxy_error_t;

typedef struct instproxy_client_private instproxy_client_private;
typedef instproxy_client_private *instproxy_client_t; /**< The client handle. */

/** Reports the status response of the given command */
typedef void (*instproxy_status_cb_t) (plist_t command, plist_t status, void *user_data);

/* Interface */

/**
 * Connects to the installation_proxy service on the specified device.
 *
 * @param device The device to connect to
 * @param service The service descriptor returned by lockdownd_start_service.
 * @param client Pointer that will be set to a newly allocated
 *        instproxy_client_t upon successful return.
 *
 * @return INSTPROXY_E_SUCCESS on success, or an INSTPROXY_E_* error value
 *         when an error occurred.
 */
instproxy_error_t instproxy_client_new(idevice_t device, lockdownd_service_descriptor_t service, instproxy_client_t *client);

/**
 * Starts a new installation_proxy service on the specified device and connects to it.
 *
 * @param device The device to connect to.
 * @param client Pointer that will point to a newly allocated
 *        instproxy_client_t upon successful return. Must be freed using
 *        instproxy_client_free() after use.
 * @param label The label to use for communication. Usually the program name.
 *        Pass NULL to disable sending the label in requests to lockdownd.
 *
 * @return INSTPROXY_E_SUCCESS on success, or an INSTPROXY_E_* error
 *         code otherwise.
 */
instproxy_error_t instproxy_client_start_service(idevice_t device, instproxy_client_t * client, const char* label);

/**
 * Disconnects an installation_proxy client from the device and frees up the
 * installation_proxy client data.
 *
 * @param client The installation_proxy client to disconnect and free.
 *
 * @return INSTPROXY_E_SUCCESS on success
 *         or INSTPROXY_E_INVALID_ARG if client is NULL.
 */
instproxy_error_t instproxy_client_free(instproxy_client_t client);

/**
 * List installed applications. This function runs synchronously.
 *
 * @param client The connected installation_proxy client
 * @param client_options The client options to use, as PLIST_DICT, or NULL.
 *        Valid client options include:
 *          "ApplicationType" -> "System"
 *          "ApplicationType" -> "User"
 *          "ApplicationType" -> "Internal"
 *          "ApplicationType" -> "Any"
 * @param result Pointer that will be set to a plist that will hold an array
 *        of PLIST_DICT holding information about the applications found.
 *
 * @return INSTPROXY_E_SUCCESS on success or an INSTPROXY_E_* error value if
 *         an error occurred.
 */
instproxy_error_t instproxy_browse(instproxy_client_t client, plist_t client_options, plist_t *result);

/**
*在设备上安装应用程序。
*
* @param客户端已连接的installation_proxy客户端
* @param pkg_path安装包的路径（在AFC监狱内）
* @param client_options要使用的客户端选项，如PLIST_DICT或NULL。
*有效选项包括：
*“ iTunesMetadata”-> PLIST_DATA
*“ ApplicationSINF”-> PLIST_DATA
*“ PackageType”->“开发人员”
*如果指定了PackageType-> Developer，则pkg_path指向
* .app目录而不是安装软件包。
* @param status_cb用于获取进度和状态信息的回调函数。如果
*传递NULL，此函数将同步运行。
* @param user_data回调数据传递给status_cb。
*
*如果成功则返回INSTPROXY_E_SUCCESS，如果错误则返回INSTPROXY_E_ *错误值
*发生错误。
*
* @note如果提供了回调函数（异步模式），则此函数返回
*如果状态更新程序线程已被执行，则立即INSTPROXY_E_SUCCESS
*创建成功；在命令执行期间发生的任何错误都必须
*在指定的回调函数内部处理。
*/
instproxy_error_t instproxy_browse_with_callback(instproxy_client_t client, plist_t client_options, instproxy_status_cb_t status_cb, void *user_data);

/**
 * Lookup information about specific applications from the device.
 *
 * @param client The connected installation_proxy client
 * @param appids An array of bundle identifiers that MUST have a terminating
 *        NULL entry or NULL to lookup all.
 * @param client_options The client options to use, as PLIST_DICT, or NULL.
 *        Currently there are no known client options, so pass NULL here.
 * @param result Pointer that will be set to a plist containing a PLIST_DICT
 *        holding requested information about the application or NULL on errors.
 *
 * @return INSTPROXY_E_SUCCESS on success or an INSTPROXY_E_* error value if
 *         an error occurred.
 */
instproxy_error_t instproxy_lookup(instproxy_client_t client, const char** appids, plist_t client_options, plist_t *result);

/**
 * Install an application on the device.
 *
 * @param client The connected installation_proxy client
 * @param pkg_path Path of the installation package (inside the AFC jail)
 * @param client_options The client options to use, as PLIST_DICT, or NULL.
 *        Valid options include:
 *          "iTunesMetadata" -> PLIST_DATA
 *          "ApplicationSINF" -> PLIST_DATA
 *          "PackageType" -> "Developer"
 *        If PackageType -> Developer is specified, then pkg_path points to
 *        an .app directory instead of an install package.
 * @param status_cb Callback function for progress and status information. If
 *        NULL is passed, this function will run synchronously.
 * @param user_data Callback data passed to status_cb.
 *
 * @return INSTPROXY_E_SUCCESS on success or an INSTPROXY_E_* error value if
 *         an error occurred.
 *
 * @note If a callback function is given (async mode), this function returns
 *       INSTPROXY_E_SUCCESS immediately if the status updater thread has been
 *       created successfully; any error occuring during the command has to be
 *       handled inside the specified callback function.
 */
instproxy_error_t instproxy_install(instproxy_client_t client, const char *pkg_path, plist_t client_options, instproxy_status_cb_t status_cb, void *user_data);

/**
*升级设备上的应用程序。该功能几乎与
* instproxy_install;区别在于安装进度
*如果已安装应用程序，则设备速度更快。
*
* @param客户端已连接的installation_proxy客户端
* @param pkg_path安装包的路径（在AFC监狱内）
* @param client_options要使用的客户端选项，如PLIST_DICT或NULL。
*有效选项包括：
*“ iTunesMetadata”-> PLIST_DATA
*“ ApplicationSINF”-> PLIST_DATA
*“ PackageType”->“Developer”
*如果指定了PackageType-> Developer，则pkg_path指向
* .app目录而不是安装软件包。
* @param status_cb用于获取进度和状态信息的回调函数。如果
*传递NULL，此函数将同步运行。
* @param user_data回调数据传递给status_cb。
*
*如果成功则返回INSTPROXY_E_SUCCESS，如果错误则返回INSTPROXY_E_ *错误值
*发生错误。
*
* @note如果提供了回调函数（异步模式），则此函数返回
*如果状态更新程序线程已被执行，则立即INSTPROXY_E_SUCCESS
*创建成功；在命令执行期间发生的任何错误都必须
*在指定的回调函数内部处理。
*/
instproxy_error_t instproxy_upgrade(instproxy_client_t client, const char *pkg_path, plist_t client_options, instproxy_status_cb_t status_cb, void *user_data);

/*
*从设备上卸载应用程序。
*
* @param客户端连接的安装代理客户端
*要卸载的应用程序的@param appid ApplicationIdentifier
* @param client_options要使用的客户端选项，如PLIST_DICT或NULL。
*当前没有已知的客户端选项，因此在此处传递NULL。
* @param status_cb用于获取进度和状态信息的回调函数。 如果
*传递NULL，此函数将同步运行。
* @param user_data回调数据传递给status_cb。
*
*如果成功则返回INSTPROXY_E_SUCCESS，如果错误则返回INSTPROXY_E_ *错误值
*发生错误。
*
* @note如果提供了回调函数（异步模式），则此函数返回
*如果状态更新程序线程已被执行，则立即INSTPROXY_E_SUCCESS
*创建成功； 在命令执行期间发生的任何错误都必须
*在指定的回调函数内部处理。
*/
instproxy_error_t instproxy_uninstall(instproxy_client_t client, const char *appid, plist_t client_options, instproxy_status_cb_t status_cb, void *user_data);

/**
*列出存档的应用程序。 此功能同步运行。
*
* @请参阅instproxy_archive
*
* @param客户端已连接的installation_proxy客户端
* @param client_options要使用的客户端选项，如PLIST_DICT或NULL。
*当前没有已知的客户端选项，因此在此处传递NULL。
* @param结果指针，该指针将设置为包含PLIST_DICT的plist
*保留有关找到的已归档应用程序的信息。
*
*如果成功则返回INSTPROXY_E_SUCCESS，如果错误则返回INSTPROXY_E_ *错误值
*发生错误。
*/
instproxy_error_t instproxy_lookup_archives(instproxy_client_t client, plist_t client_options, plist_t *result);

/**
*在设备上存档应用程序。
*此功能告诉设备将指定的文件存档
*应用程序。这导致设备在
*'ApplicationArchives'目录并卸载应用程序。
*
* @param客户端连接的安装代理客户端
* @param appid要存档的应用程序的ApplicationIdentifier。
* @param client_options要使用的客户端选项，如PLIST_DICT或NULL。
*有效选项包括：
*“ SkipUninstall”->布尔值
*“ ArchiveType”->“ ApplicationOnly”
* @param status_cb用于获取进度和状态信息的回调函数。如果
*传递NULL，此函数将同步运行。
* @param user_data回调数据传递给status_cb。
*
*如果成功则返回INSTPROXY_E_SUCCESS，如果错误则返回INSTPROXY_E_ *错误值
*发生错误。
*
* @note如果提供了回调函数（异步模式），则此函数返回
*如果状态更新程序线程已被执行，则立即INSTPROXY_E_SUCCESS
*创建成功；在命令执行期间发生的任何错误都必须
*在指定的回调函数内部处理。
*/
instproxy_error_t instproxy_archive(instproxy_client_t client, const char *appid, plist_t client_options, instproxy_status_cb_t status_cb, void *user_data);


/**
 *在设备上还原以前存档的应用程序。
 *此函数是instproxy_archive的对应函数。
 * @请参阅instproxy_archive
 *
 * @param客户端连接的安装代理客户端
 * @param appid要还原的应用程序的ApplicationIdentifier。
 * @param client_options要使用的客户端选项，如PLIST_DICT或NULL。
 *有效选项包括：
 *“ ArchiveType”->“仅文档”
 * @param status_cb用于获取进度和状态信息的回调函数。如果
 *传递NULL，此函数将同步运行。
 * @param user_data回调数据传递给status_cb。
 *
 *如果成功则返回INSTPROXY_E_SUCCESS，如果错误则返回INSTPROXY_E_ *错误值
 *发生错误。
 *
 * @note如果提供了回调函数（异步模式），则此函数返回
 *如果状态更新程序线程已被执行，则立即INSTPROXY_E_SUCCESS
 *创建成功；在命令执行期间发生的任何错误都必须
 *在指定的回调函数内部处理。
 */
instproxy_error_t instproxy_restore(instproxy_client_t client, const char *appid, plist_t client_options, instproxy_status_cb_t status_cb, void *user_data);


/**
 *从设备中删除以前存档的应用程序。
 *此功能从“ ApplicationArchives”中删除ZIP存档
 * 目录。
 *
 * @param客户端连接的安装代理客户端
 * @param appid要删除的已存档应用的ApplicationIdentifier。
 * @param client_options要使用的客户端选项，如PLIST_DICT或NULL。
 *当前没有已知的客户端选项，因此传递NULL即可。
 * @param status_cb用于获取进度和状态信息的回调函数。如果
 *传递NULL，此函数将同步运行。
 * @param user_data回调数据传递给status_cb。
 *
 *如果成功则返回INSTPROXY_E_SUCCESS，如果错误则返回INSTPROXY_E_ *错误值
 *发生错误。
 *
 * @note如果提供了回调函数（异步模式），则此函数返回
 *如果状态更新程序线程已被执行，则立即INSTPROXY_E_SUCCESS
 *创建成功；在命令执行期间发生的任何错误都必须
 *在指定的回调函数内部处理。
 */
instproxy_error_t instproxy_remove_archive(instproxy_client_t client, const char *appid, plist_t client_options, instproxy_status_cb_t status_cb, void *user_data);



/**
  *检查设备的某些功能。
  *
  * @param客户端已连接的installation_proxy客户端
  * @param功能由功能名称必须具有一个
  *终止NULL条目。
  * @param client_options要使用的客户端选项，如PLIST_DICT或NULL。
  *当前没有已知的客户端选项，因此在此处传递NULL。
  * @param结果指针，该指针将设置为包含PLIST_DICT的plist
  *保存信息，如果功能匹配或错误为NULL。
  *
  *如果成功则返回INSTPROXY_E_SUCCESS，如果错误则返回INSTPROXY_E_ *错误值
  *发生错误。
  */
instproxy_error_t instproxy_check_capabilities_match(instproxy_client_t client, const char** capabilities, plist_t client_options, plist_t *result);

/* Helper */

/**
 * Gets the name from a command dictionary.
 *
 * @param command The dictionary describing the command.
 * @param name Pointer to store the name of the command.
 */
void instproxy_command_get_name(plist_t command, char** name);

/**
 * Gets the name of a status.
 *
 * @param status The dictionary status response to use.
 * @param name Pointer to store the name of the status.
 */
void instproxy_status_get_name(plist_t status, char **name);

/**
 * Gets error name, code and description from a response if available.
 *
 * @param status The dictionary status response to use.
 * @param name Pointer to store the name of an error.
 * @param description Pointer to store error description text if available.
 *        The caller is reponsible for freeing the allocated buffer after use.
 *        If NULL is passed no description will be returned.
 * @param code Pointer to store the returned error code if available.
 *        If NULL is passed no error code will be returned.
 *
 * @return INSTPROXY_E_SUCCESS if no error is found or an INSTPROXY_E_* error
 *   value matching the error that ẃas found in the status.
 */
instproxy_error_t instproxy_status_get_error(plist_t status, char **name, char** description, uint64_t* code);

/**
 * Gets total and current item information from a browse response if available.
 *
 * @param status The dictionary status response to use.
 * @param total Pointer to store the total number of items.
 * @param current_index Pointer to store the current index of all browsed items.
 * @param current_amount Pointer to store the amount of items in the
 *        current list.
 * @param list Pointer to store a newly allocated plist with items.
 *        The caller is reponsible for freeing the list after use.
 *        If NULL is passed no list will be returned. If NULL is returned no
 *        list was found in the status.
 */
void instproxy_status_get_current_list(plist_t status, uint64_t* total, uint64_t* current_index, uint64_t* current_amount, plist_t* list);


/**
 * Gets progress in percentage from a status if available.
 *
 * @param status The dictionary status response to use.
 * @param name Pointer to store the progress in percent (0-100) or -1 if not
 *        progress was found in the status.
 */
void instproxy_status_get_percent_complete(plist_t status, int *percent);

/**
 * Creates a new client_options plist.
 *
 * @return A new plist_t of type PLIST_DICT.
 */
plist_t instproxy_client_options_new(void);

/**
 * Adds one or more new key:value pairs to the given client_options.
 *
 * @param client_options The client options to modify.
 * @param ... KEY, VALUE, [KEY, VALUE], NULL
 *
 * @note The keys and values passed are expected to be strings, except for the
 *       keys "ApplicationSINF", "iTunesMetadata", "ReturnAttributes" which are
 *       expecting a plist_t node as value and "SkipUninstall" expects int.
 */
void instproxy_client_options_add(plist_t client_options, ...);

/**
 * Adds attributes to the given client_options to filter browse results.
 *
 * @param client_options The client options to modify.
 * @param ... VALUE, VALUE, [VALUE], NULL
 *
 * @note The values passed are expected to be strings.
 */
void instproxy_client_options_set_return_attributes(plist_t client_options, ...);

/**
 * Frees client_options plist.
 *
 * @param client_options The client options plist to free. Does nothing if NULL
 *        is passed.
 */
void instproxy_client_options_free(plist_t client_options);

/**
*查询设备的应用程序路径。
*
* @param客户端连接的安装代理客户端。
* @param appid要检索其路径的应用程序的ApplicationIdentifier。
* @param path指针，用于存储应用程序的设备路径
*如果无法确定，则设置为NULL。
*
* @成功返回INSTPROXY_E_SUCCESS，如果成功则返回INSTPROXY_E_OP_FAILED
*无法确定路径或INSTPROXY_E_ *错误
*值，如果发生错误。
*/
instproxy_error_t instproxy_client_get_path_for_bundle_identifier(instproxy_client_t client, const char* bundle_id, char** path);

#ifdef __cplusplus
}
#endif

#endif
