#include <iostream>

//#include <stack>
#include <vector>
#include <string>
#include <algorithm>
#include <mutex>
#include <queue>
#include <thread>
#include <list>

#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "stdbool.h"
#include "pthread.h"

#include "lua.h"
#include "lauxlib.h"

extern "C" void stackDump(lua_State* L);
extern "C" int straight_executor_parallel_tasks_execute(lua_State* L);

struct rulestruct {
	std::string rule;
	std::string message;
	bool echo;
	bool noneed;
	bool check;
	bool out;

	void debug_print() {
		std::cout <<
		"rule:" << rule << std::endl <<
		"message:" << message << std::endl <<
		"echo:" << echo << std::endl <<
		"noneed:" << noneed << std::endl <<
		"check:" << check << std::endl <<
		"out:" << out << std::endl;
	}
};

struct task {
	std::string target;
	std::vector<rulestruct> rulevec;
	std::vector<task*> nexts;

	bool noneed;
	int refs = 0;
	int curref = 0;
};

struct LocalContext {
	lua_State* L;

	std::vector<task> tasks;
	std::queue<task*> works;
	std::recursive_mutex works_mtx;

	//std::list<std::thread*> thrlst;
	int threadsMaximum = 0;
	volatile int threadsCount = 0;

	bool ret = false;
};

task* getWork(LocalContext* C);
void startWorkThreads(LocalContext* C);
void finalizeWork(LocalContext* C, task* w);

void* workFunc(LocalContext* C,  task* t, int thrnum) {
	__label__ re;

	re:

	for (auto& r : t->rulevec) {

		//r.debug_print();

		if (r.message != "") printf("w%d: %s\r\n", thrnum, r.message.c_str());

		//r.echo = true;
		if (r.echo) printf("w%d: %s\r\n", thrnum, r.rule.c_str());
		int ret = system(r.rule.c_str());
			
			/*if(ret != 0) {
				pthread_mutex_lock(&wcommon->mutex);
				wcommon->abort = true;	
				goto __exit;
			}*/

			//task = task->next;

	} 

	finalizeWork(C, t);

	//printf("find cont");
	if ((t = getWork(C)) != nullptr) {
		//printf("find second cont");
		startWorkThreads(C);
		goto re;
	}

	C->threadsCount--;

	//printf("exit thread\r\n");
}

void finalizeWork(LocalContext* C, task* w) {
	//printf("finalizeWork %s\r\n", w->target.c_str());
	std::lock_guard<std::recursive_mutex> lock(C->works_mtx);
	for (auto t: w->nexts) { 
		//printf("next: %s\r\n", t->target.c_str());
		
		//C->works_mtx.lock();
		t->curref++;
		if (t->curref == t->refs) {
			//printf("added: %s\r\n", t->target.c_str());
			C->works.push(t);
		} 
		//C->works_mtx.unlock();
	}
	//printf("endfinalizeWork\r\n");
}

task* getWork(LocalContext* C) {
	std::lock_guard<std::recursive_mutex> lock(C->works_mtx);
	//C->works_mtx.lock();
	while (!C->works.empty()) {
		auto w = C->works.front();
		C->works.pop();
		//C->works_mtx.unlock();

		if (w -> noneed == false) {
			return w;
		}
		else {
			finalizeWork(C, w);
			return nullptr;
		}
	}

	return nullptr;
}

void startWorkThreads(LocalContext* C) {
	std::lock_guard<std::recursive_mutex> lock(C->works_mtx);
	task* t;
	while (C->works.size() != 0) {
		if (C->threadsCount < C->threadsMaximum) {
			if ((t = getWork(C)) != nullptr) {
				C->ret = true;
				C->threadsCount++;
				new std::thread(workFunc, C, t, C->threadsCount);
			}
		}
		else {
			break;
		}
	}
}

void start(LocalContext* C) {
	//std::lock_guard<std::recursive_mutex> lock(C->works_mtx);
	startWorkThreads(C);

	while(C->threadsCount != 0) std::this_thread::sleep_for(std::chrono::milliseconds(5));
	//printf("start fin\r\n");
}

std::string getfieldstr (lua_State* L, const char *key) {
	std::string result;
	lua_pushstring(L, key);
	lua_gettable(L, -2);
	if (lua_isstring(L, -1)) result = lua_tostring(L, -1);
	else result = "";
	lua_pop(L, 1);  /* remove number */
	return result;
}

bool getfieldbool (lua_State* L, const char *key, bool def) {
	bool result;
	lua_pushstring(L, key);
	lua_gettable(L, -2);
	if (lua_isboolean(L, -1)) result = lua_toboolean(L, -1);
	else result = def;
	lua_pop(L, 1);  /* remove number */
	return result;
}

void form_task_vector(LocalContext* C, int taskssize) {
	//std::cout <<  "tasks->size:" << taskssize << std::endl;

	C->tasks.reserve(taskssize);

	for (int i = 0; i < taskssize; i++) {
		lua_pushnumber(C->L, i + 1);
		lua_gettable(C->L, -2);

		task* t = new task;
		t->target = getfieldstr(C->L, "target");

		lua_pushstring(C->L, "rulelist");
		lua_gettable(C->L, -2);
		int totalrules = luaL_len(C->L, -1);
		t->rulevec.reserve(totalrules);
		t->noneed = true;
		for (int j = 0; j < totalrules; j++) {
			lua_pushnumber(C->L, j + 1);
			lua_gettable(C->L, -2);

			rulestruct* rs = new rulestruct;
			rs->rule = getfieldstr(C->L, "rule");
			rs->message = getfieldstr(C->L, "message");
			rs->echo = getfieldbool(C->L, "echo", true);
			rs->noneed = getfieldbool(C->L, "noneed", false);
			rs->out = getfieldbool(C->L, "out", true);
			rs->check = getfieldbool(C->L, "check", true);

			//std::cout << "noneed: " << rs->noneed << std::endl;

			if (rs->noneed == false) t->noneed = false;
			t->rulevec.push_back(*rs);

			lua_pop(C->L, 1);
		}
		lua_pop(C->L, 1);

		C->tasks.push_back(*t);

		lua_pop(C->L, 1);
	}

	for (int i = 0; i < taskssize; i++) {
		lua_pushnumber(C->L, i + 1);
		lua_gettable(C->L, -2);

		lua_pushstring(C->L, "next");
		lua_gettable(C->L, -2);

		if (!lua_isnil(C->L, -1)) {
			int totalnexts = luaL_len(C->L, -1);
			for (int j = 0; j < totalnexts; j++) {
				lua_pushnumber(C->L, j + 1);
				lua_gettable(C->L, -2);
				std::string next = lua_tostring(C->L, -1);
				
				//std::cout << next << std::endl;
				auto it = std::find_if(C->tasks.begin(), C->tasks.end(), [&next](const task& t){
					return t.target == next;
				});
				if (it == C->tasks.end()) luaL_error(C->L, "AnyThingWrong");
				C->tasks[i].nexts.push_back(&*it);
				it->refs++;

				lua_pop(C->L, 1);
			}
		}
		lua_pop(C->L, 1);
		lua_pop(C->L, 1);
	}


	for (auto& t : C->tasks) {
		if (t.refs == 0) C->works.push(&t);
	}

	/*for (auto& t : C->tasks) {
		//std::cout <<  t.nexts.size() << t.ref << std::endl;
		std::cout << "target:" << t.target << std::endl;
		std::cout << "\trulevec:" << t.rulevec.size() << std::endl;
		for (auto r : t.rulevec) {
			std::cout << "\t\trule:" << r.rule << std::endl;
		}
		std::cout << "\tnexts:" << std::endl;
		for (auto n : t.nexts) {
			std::cout << "\t\t" << n->target << std::endl;
		}
		std::cout << "\trefs:" << t.refs << std::endl;
	}*/
} 

int straight_executor_parallel_tasks_execute(lua_State* L) {
	LocalContext* C = new LocalContext;
	C->L = L;

	int nthreads;

	lua_settop(C->L, 2);
	luaL_checktype(C->L, 1, LUA_TTABLE);
	luaL_checktype(C->L, 2, LUA_TNUMBER);
	nthreads = lua_tointeger(C->L, 2);
	lua_pop(C->L, 1);

	C->threadsMaximum = nthreads;

	if (nthreads <= 0)  
		luaL_error(C->L, "nthreads shouldn't be 0 or less");

	
	int tlen = luaL_len(C->L, -1);
	//std::cout << tlen << std::endl;

	//stackDump(C->L);

	form_task_vector(C, tlen);
	start(C);

	lua_pushboolean(L, C->ret);

	//printf("EXIT\r\n");

	delete C;

	//if (ntasks < nthreads) nthreads = ntasks;

	//printf("threads %d size %d\r\n", nthreads, ntasks);
	//lua_pushboolean(C->L, __glink_parallel_tasks_execute(C->L, nthreads, ntasks));
	//stackDump(C->L);
	return 1;
}