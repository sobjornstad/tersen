local hooks = require 'extend/hooks'

local M = {}

-- Fluent interface for hooks.
HookResult = {}

function HookResult:from_success(hook, ...)
    local new_obj = {
        retval = table.pack(M.invoke(hook, ...)),
        defined = true,
    }
    self.__index = self
    return setmetatable(new_obj, self)
end

function HookResult:from_failure()
    local new_obj = {defined = false}
    self.__index = self
    return setmetatable(new_obj, self)
end

-- If func() returns true when passed the hook's result, ignore the result,
-- making the HookResult act as if the hook didn't exist in the first place.
-- Nothing is done if the hook already didn't exist.
function HookResult:unhook_if(func)
    if self.defined and func(self.retval) then
        self.defined = false
    end
    return self
end

-- If the hook doesn't exist, use the result of /func/ instead.
function HookResult:or_execute(func)
    if self.defined then
        return table.unpack(self.retval)
    else
        return func()
    end
end

-- If the hook doesn't exist, return /retval/ instead.
function HookResult:or_return(retval)
    if self.defined then
        return table.unpack(self.retval)
    else
        return retval
    end
end


-- Is the hook defined?
function M.defined(hook)
    return hooks[hook] ~= nil
end

-- Call a hook if it's defined, or else do nothing at all.
function M.invoke(hook, ...)
    if M.defined(hook) then
        return hooks[hook](...)
    end
end

-- Try to call a hook and return a HookResult object.
-- Chain or_execute() or or_return() after this call.
function M.try_invoke(hook, ...)
    if M.defined(hook) then
        return HookResult:from_success(hook, ...)
    else
        return HookResult:from_failure()
    end
end

return M