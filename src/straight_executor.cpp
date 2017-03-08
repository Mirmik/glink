#include <stack>
#include <iostream>
#include <vector>
#include <string>
#include <algorithm>

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
		rule << std::endl <<
		message << std::endl <<
		echo << std::endl <<
		noneed << std::endl <<
		check << std::endl <<
		out << std::endl;
	}
};

struct task {
	std::string target;
	std::vector<rulestruct> rulevec;
	std::vector<task*> nexts;

	int ref = 0;
	int curref = 0;
};

struct LocalContext {
	lua_State* L;
	std::vector<task> tasks;
};

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
				
				std::cout << next << std::endl;
				auto it = std::find_if(C->tasks.begin(), C->tasks.end(), [&next](const task& t){
					return t.target == next;
				});
				if (it == C->tasks.end()) luaL_error(C->L, "AnyThingWrong");
				C->tasks[i].nexts.push_back(&*it);
				it->ref++;

				lua_pop(C->L, 1);
			}
		}
		lua_pop(C->L, 1);
		lua_pop(C->L, 1);
	}

	for (auto& t : C->tasks) {
	//	std::cout << t.nexts.size() << t.ref << std::endl;
	}
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

	if (nthreads <= 0)  
		luaL_error(C->L, "nthreads shouldn't be 0 or less");

	
	int tlen = luaL_len(C->L, -1);
	//std::cout << tlen << std::endl;

	//stackDump(C->L);

	form_task_vector(C, tlen);
	//if (ntasks < nthreads) nthreads = ntasks;

	//printf("threads %d size %d\r\n", nthreads, ntasks);
	//lua_pushboolean(C->L, __glink_parallel_tasks_execute(C->L, nthreads, ntasks));
	//stackDump(C->L);
	return 1;
}