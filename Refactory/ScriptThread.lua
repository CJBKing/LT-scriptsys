
local function _log(id, ...) print(string.format("Thread[%d]: ", id), ...) end
local assert = assert

local _STATUS_SUSPENDED = "suspended"
local _STATUS_DEAD = "dead"

local _co_create = coroutine.create
local _co_resume = coroutine.resume
local _co_yield = coroutine.yield
local _co_status = coroutine.status

--[[
线程封装
--]]
ScriptThread = typesys.ScriptThread {
	__pool_capacity = -1,
	__strong_pool = true,
	_co = typesys.unmanaged,   -- 协程
}

local _SIG_ABORT = "abort"

function ScriptThread:ctor()
end

function ScriptThread:dtor()
	self:abort()
end

------- [代码区段开始] 接口 --------->

function ScriptThread:isRunning()
	return nil ~= self._co
end

-- 通过一个线程过程函数，以及参数启动线程
-- 返回后，如果isRunning为真，那么返回的是被调用sleep传入的参数，否则就是结束或中断了
function ScriptThread:start(proc, ...)
	return self:_startRunning(proc, ...)
end

-- 强制中断
function ScriptThread:abort()
	if not self:isRunning() then
		return
	end

	if self:isActive() then
		error(_SIG_ABORT)
	else
		self:awake(_SIG_ABORT)
	end
end

-- 是否处于激活运行状态
function ScriptThread:isActive()
	return _STATUS_SUSPENDED ~= _co_status(self._co)
end

-- 唤醒为激活状态，返回被调用sleep传入的参数
function ScriptThread:awake( ... )
	assert(not self:isActive())

	-- 返回sleep参数，或执行结束
	return self:_handleResumeResult(_co_resume(self._co, ...))
end

-- 使挂起为非激活状态，返回被调用awake传入的参数
function ScriptThread:sleep( ... )
	assert(self:isActive())

	-- 返回awake参数
	return self:_handleYieldResule(_co_yield(...))
end

------- [代码区段结束] 接口 ---------<

------- [代码区段开始] 私有函数 --------->

function ScriptThread:_startRunning(proc, ...)
	assert(not self:isRunning())

	_log(self._id, "start")
	self._co = _co_create(proc)
	return self:_handleResumeResult(_co_resume(self._co, ...))
end

function ScriptThread:_endRunning()
	assert(self:isRunning())

	self._co = nil
	_log(self._id, "end")
end

function ScriptThread:_handleResumeResult(no_error, ...)
	local status = _co_status(self._co)
	if _STATUS_DEAD ~= status then
		_log(self._id, "sleeped")
	else
		self:_endRunning()
	end
	return ...
end

function ScriptThread:_handleYieldResule( ... )
	if _SIG_ABORT == ... then
		error(...)
	else
		return ...
	end
end

------- [代码区段结束] 关于running状态私有函数 ---------<


