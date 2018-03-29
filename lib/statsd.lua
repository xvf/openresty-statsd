local Statsd = {}

local namespace = os.getenv("STATS_NAMESPACE") or "openresty"

Statsd.time  = function (metric, time)
   metric_name = namespace .. ".timer." .. metric
   Statsd.register(metric_name , time .. "|ms")
end

Statsd.count = function (metric, n)
   metric_name = namespace .. ".count." .. metric
   Statsd.register(metric_name,  n .. "|c")
end

Statsd.incr  = function (metric)
   metric_name = namespace .. ".counter." .. metric
   Statsd.count(metric_name, 1 .. "|c")
end

Statsd.buffer = {} -- this table will be shared per worker process
                   -- if lua_code_cache is off, it will be cleared every request

Statsd.flush = function(sock, host, port)
   if sock then -- send buffer
      pcall(function()
               local udp = sock()
               udp:setpeername(host, port)
               udp:send(Statsd.buffer)
               udp:close()
            end)
   end

   -- empty buffer
   for k in pairs(Statsd.buffer) do Statsd.buffer[k] = nil end
end

Statsd.register = function (metric, suffix)
   local _metric = metric  .. ":" .. suffix .. "\n"
   table.insert(Statsd.buffer, _metric)

end

return Statsd
