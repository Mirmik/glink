List = {}
List.__index = List

function List.new() 
	local list = {  }
	setmetatable(list, List)

	list.head = {}
	list.head.next = list.head
	list.head.prev = list.head

	list.total = 0

	return list
end

function List:push_front(obj) 
	node = {obj = obj}
	node.next = self.head.next
	node.prev = self.head
	self.head.next.prev = node
	self.head.next = node
	self.total = self.total + 1
end

function List:push_back(obj) 
	node = {obj = obj}
	node.next = self.head
	node.prev = self.head.prev
	self.head.prev.next = node
	self.head.prev = node
	self.total = self.total + 1
end

function List:__delete(node)
	node.next.prev = node.prev
	node.prev.next = node.next
end

function List:pop_back() 
	self:__delete(self.head.prev)
end

function List:pop_front() 
	self:__delete(self.head.next)
end

function List:last() 
	return self.head.prev.obj
end

function List:first() 
	return self.head.next.obj
end

function List:empty() 
	return self.head == self.prev
end

function List:foreach()	
	local next = self.head.next
	local cur = self.head

	return function()
		if next == self.head then return nil end
		cur = next
		next = next.next
		return cur.obj
	end
end

function List:foreach_iterator()
	local next = self.head.next
	local cur = self.head

	return function()
		if next == self.head then return nil end
		cur = next
		next = next.next
		return cur
	end
end

function List:remove_if(func)
	for it in self:foreach_iterator() do
		if func(it.obj) then self:__delete(it) end
	end
end

return List