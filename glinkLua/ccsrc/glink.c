#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "stdbool.h"
#include "pthread.h"

#include "lua.h"
#include "lauxlib.h"

static void stackDump(lua_State* L) {
	int i;
	printf("stack dump: ");
	int top = lua_gettop(L);
	for(i = 1; i <= top; i++) {
		int t = lua_type(L,i);
		switch (t) {
			case LUA_TSTRING: {
				printf("%s", lua_tostring(L,i));
				break;
			}
			case LUA_TBOOLEAN: {
				printf(lua_toboolean(L, i) ? "true" : "false");
				break;								
			}
			case LUA_TNUMBER: {
				printf("%g", lua_tonumber(L,i));
				break;				
			}
			default: {
				printf("t:%s", lua_typename(L,t));
				break;
			}
		}
		printf(" ");
	}
	printf("\n");
}

struct task_s {
	char* rule;
	char* message;
	struct task_s* next;
};

struct worker_args_common {
	struct task_s * array;
	int abort;
	size_t index;
	size_t total;
	pthread_mutex_t mutex;
};

struct worker_s {
	struct worker_args_common* common;
	pthread_t thread;
	int num;
};

void* __worker_thread(void* arg) {
	struct task_s * task;
	struct worker_s * worker = (struct worker_s *) arg;
	struct worker_args_common* wcommon = worker->common;
	//printf("WORKER_START\n\r");
	
	while(1) {
		//common operation
		pthread_mutex_lock(&wcommon->mutex);
		if (wcommon->total == wcommon->index || wcommon->abort) {
			pthread_mutex_unlock(&wcommon->mutex);
			goto __exit;
		}

		task = &wcommon->array[wcommon->index]; 
		wcommon->index++;
		
		pthread_mutex_unlock(&wcommon->mutex);

		//unprotected operation
		while(task) {
			if (task->message) printf("w%d: %s\r\n", worker->num, task->message);
			int ret = system(task->rule);
			
			if(ret != 0) {
				pthread_mutex_lock(&wcommon->mutex);
				wcommon->abort = true;
				pthread_mutex_unlock(&wcommon->mutex);	
				goto __exit;
			}

			task = task->next;
		}
	};	

	__exit: 
	//printf("WORKER_FINISH\n\r");
	return (void*) 0;
}

int __set_task(lua_State* L, struct task_s* ittask) {
	lua_getfield(L, -1, "rule");
	const char* rule = lua_tostring(L, -1);
	ittask->rule = strdup(rule);
	lua_pop(L, 1);

	lua_getfield(L, -1, "message");
	if (lua_isstring(L, -1)) {
		const char* message = lua_tostring(L, -1);
		ittask->message = strdup(message);
	} else ittask->message = NULL;
	lua_pop(L, 1);

	lua_getfield(L, -1, "next");
	if (lua_istable(L, -1)) {
		ittask->next = malloc(sizeof(struct task_s));
		ittask = ittask->next;
		__set_task(L, ittask);
	} 
	else 
		ittask->next = NULL;
	lua_pop(L, 1);
}

int finalize_task(struct task_s* task) {
	free(task->rule);
	free(task->message);
	if (task->next) { 
		finalize_task(task->next);
		free(task->next);
	};	
}

int __glink_parallel_tasks_execute(lua_State* L, size_t nthreads, size_t ntasks) {
	struct worker_s workers[nthreads];
	struct worker_args_common wargs;
	
	struct task_s tasks[ntasks], *ittask;
	
	//stackDump(L);

	for (int i = 0; i < ntasks; i++) {
		lua_rawgeti(L, -1, i + 1);
		__set_task(L, tasks + i);
		lua_pop(L, 1);
	}	
	lua_pop(L, 1);


	wargs.array = tasks;
	wargs.index = 0;
	wargs.abort = false;
	wargs.total = ntasks;
	pthread_mutex_init(&wargs.mutex, NULL);

	for (int i = 0; i < nthreads; i++) {
		workers[i].common = &wargs;
		workers[i].num = i;
		pthread_create(&workers[i].thread, NULL, __worker_thread, (void*)&workers[i]);
	}	

	for (int i = 0; i < nthreads; i++) {
		void* retval;
		pthread_join(workers[i].thread, &retval);
	}	
	
	for (int i = 0; i < ntasks; i++) {
		finalize_task(&tasks[i]);
	};

	pthread_mutex_destroy(&wargs.mutex);
	if (wargs.abort) {
		exit(1);
	};

	return true;
}

int glink_parallel_tasks_execute(lua_State* L) {
	int ntasks, nthreads;

	luaL_checktype(L, 1, LUA_TTABLE);
	ntasks = luaL_len(L, 1);
	luaL_checktype(L, 2, LUA_TNUMBER);
	nthreads = lua_tointeger(L, 2);
	lua_pop(L, 1);

	if (ntasks == 0) { 
		lua_pushboolean(L, 1); 
		return LUA_OK; 
	}
	
	if (nthreads == 0)  
		luaL_error(L, "nthreads shouldn't be 0");
	
	if (ntasks < nthreads) nthreads = ntasks;

	//printf("threads %d size %d\r\n", nthreads, ntasks);
	lua_pushboolean(L, __glink_parallel_tasks_execute(L, nthreads, ntasks));
	//stackDump(L);
	return 1;
}

static const struct luaL_Reg mirmik[] = {
	{"parallel_tasks_execute", glink_parallel_tasks_execute},
	{NULL, NULL}
};

int luaopen_glinkLib(lua_State* L) {
	luaL_newlib(L, mirmik);
	return 1;
}