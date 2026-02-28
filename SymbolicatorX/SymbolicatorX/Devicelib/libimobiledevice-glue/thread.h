/*
 * thread.h
 *
 * Copyright (c) 2012-2019 Nikias Bassen, All Rights Reserved.
 * Copyright (c) 2012 Martin Szulecki, All Rights Reserved.
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

#ifndef __THREAD_H
#define __THREAD_H

#include <stddef.h>
#include <libimobiledevice-glue/glue.h>

#ifdef _WIN32
typedef void* HANDLE;
typedef HANDLE THREAD_T;
#pragma pack(push, 8)
struct _CRITICAL_SECTION_ST {
	void* DebugInfo;
	long LockCount;
	long RecursionCount;
	HANDLE OwningThread;
	HANDLE LockSemaphore;
#if defined(_WIN64)
	unsigned __int64 SpinCount;
#else
	unsigned long SpinCount;
#endif
};
#pragma pack(pop)
typedef struct _CRITICAL_SECTION_ST mutex_t;
typedef struct {
	HANDLE sem;
} cond_t;
typedef volatile struct {
	long lock;
	int state;
} thread_once_t;
#define THREAD_ONCE_INIT {0, 0}
#define THREAD_ID GetCurrentThreadId()
#define THREAD_T_NULL (THREAD_T)NULL
#else
#include <pthread.h>
#include <signal.h>
#include <sys/time.h>
typedef pthread_t THREAD_T;
typedef pthread_mutex_t mutex_t;
typedef pthread_cond_t cond_t;
typedef pthread_once_t thread_once_t;
#define THREAD_ONCE_INIT PTHREAD_ONCE_INIT
#define THREAD_ID pthread_self()
#define THREAD_T_NULL (THREAD_T)NULL
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef void* (*thread_func_t)(void* data);

LIMD_GLUE_API int thread_new(THREAD_T* thread, thread_func_t thread_func, void* data);
LIMD_GLUE_API void thread_detach(THREAD_T thread);
LIMD_GLUE_API void thread_free(THREAD_T thread);
LIMD_GLUE_API int thread_join(THREAD_T thread);
LIMD_GLUE_API int thread_alive(THREAD_T thread);

LIMD_GLUE_API int thread_cancel(THREAD_T thread);

#ifdef _WIN32
#undef HAVE_THREAD_CLEANUP
#else
#ifdef HAVE_PTHREAD_CANCEL
#define HAVE_THREAD_CLEANUP 1
#define thread_cleanup_push(routine, arg) pthread_cleanup_push(routine, arg)
#define thread_cleanup_pop(execute) pthread_cleanup_pop(execute)
#endif
#endif

LIMD_GLUE_API void mutex_init(mutex_t* mutex);
LIMD_GLUE_API void mutex_destroy(mutex_t* mutex);
LIMD_GLUE_API void mutex_lock(mutex_t* mutex);
LIMD_GLUE_API void mutex_unlock(mutex_t* mutex);

LIMD_GLUE_API void thread_once(thread_once_t *once_control, void (*init_routine)(void));

LIMD_GLUE_API void cond_init(cond_t* cond);
LIMD_GLUE_API void cond_destroy(cond_t* cond);
LIMD_GLUE_API int cond_signal(cond_t* cond);
LIMD_GLUE_API int cond_wait(cond_t* cond, mutex_t* mutex);
LIMD_GLUE_API int cond_wait_timeout(cond_t* cond, mutex_t* mutex, unsigned int timeout_ms);

#ifdef __cplusplus
}
#endif

#endif
