-- MIT License

-- Copyright (c) 2018 Ivan

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- check debug enabled
if arg[1] == "dbg" then
        dbgEn = 1
end

-- connect to lua socket
local socket = require "socket"

-- encode non literal/numeric characters
function serialize(data)
    return "'"..data:gsub("[^a-z0-9-]", function(chr) return ("\\x%02X"):format(chr:byte()) end).."'"
end

-- parse packet for domain name
function read_domain(packet)
        local pos = 14
        local dlen = packet:byte(13)		                                        -- check prefix size
        local domain = {}
        while (dlen > 0) do					                        -- with dlen = 0 domain name ends
											-- read part of domain name
                table.insert(domain, packet:sub(pos, pos + dlen - 1))
                pos = pos + dlen + 1
                dlen = packet:byte(pos - 1) -- claculate next domain name part size
        end
        return table.concat(domain, ".")
end

-- UDP to TCP encoding
function udp_to_tcp_coroutine_function(udp_in, tcp_out, clients)
    repeat
        coroutine.yield()       			                                -- return control to main routine
											-- get UDP packet
        packet, err_ip, port = udp_in:receivefrom()
        if packet then
											-- > - big endian
											-- I - unsigned integer
											-- 2 - 2 bytes size
											-- add packet size and relay to TCP
            tcp_out:send(((">I2"):pack(#packet))..packet)
											-- read packet ID
            local id = (">I2"):unpack(packet:sub(1,2))
                        if not clients[id] then
                                clients[id] = {}
                        end
											-- record sender address
                        table.insert(clients[id] ,{ip=err_ip, port=port, packet=packet})
											-- print packet to console
            if dbgEn ==  1 then print(os.date("%c", os.time()) ,err_ip, port, ">", read_domain(packet), serialize(packet)) end
        end
    until false
end

-- TCP to UDP packet relay
function tcp_to_udp_coroutine_function(tcp_in, udp_out, clients)
    repeat
        coroutine.yield()       			                                -- return control to main routine
											-- > - big endian
											-- I - unsigned integer
											-- 2 - 2 bytes size
											-- get TCP packet
        local packet = tcp_in:receive((">I2"):unpack(tcp_in:receive(2)), nil)
        local id = (">I2"):unpack(packet:sub(1,2))

        if clients[id] then
                        for key, client in pairs(clients[id]) do
											-- compare sender and reciever query and find destination client
                                if packet:find(client.packet:sub(13, -1), 13, true) == 13 then
                                        udp_out:sendto(packet, client.ip, client.port)
                                        clients[id][key] = nil
                                        if dbgEn == 1 then print(os.date("%c", os.time()) ,client.ip, client.port, "<", read_domain(packet), serialize(packet)) end
                                        break
                                end
                        end
                        if not next(clients[id]) then
                                clients[id] = nil
                        end
        end
    until false
end

-- main control routine
function main()
    if dbgEn == 1 then print("[ Ergo proxy started ]") end
    local tcp_dns_socket = socket.tcp()
    local udp_dns_socket = socket.udp()

        local proxyPorts = { "1053" }

        for _, pPort in ipairs(proxyPorts) do
                if dbgEn == 1 then io.write("Connecting TCP port ", pPort, " ") end
											-- connect to TCP tunnel
                local tcp_connected, err = tcp_dns_socket:connect("127.0.0.1", pPort)
                assert(tcp_connected, err)
                if dbgEn == 1 then print("[ OK ]") end

                if dbgEn ==1 then io.write("Connecting UDP port ", pPort, " ") end
											-- open UDP port
                local udp_open, err = udp_dns_socket:setsockname("127.0.0.1", pPort)
                assert(udp_open, err)
                if dbgEn == 1 then print("[ OK ]") end
        end

    -- Use socket names as key to point to subroutine
	local coroutines = {
        [tcp_dns_socket] = coroutine.create(tcp_to_udp_coroutine_function),
        [udp_dns_socket] = coroutine.create(udp_to_tcp_coroutine_function)
    }

	-- Array with packet receivers
    local clients = {}

    coroutine.resume(coroutines[tcp_dns_socket], tcp_dns_socket, udp_dns_socket, clients)
    coroutine.resume(coroutines[udp_dns_socket], udp_dns_socket, tcp_dns_socket, clients)

	-- Array with ready sockets
    local socket_list = {tcp_dns_socket, udp_dns_socket}

    repeat
        for _, in_socket in ipairs(socket.select(socket_list)) do
            local ok, err = coroutine.resume(coroutines[in_socket])
            if not ok then
                udp_dns_socket:close()
                tcp_dns_socket:close()
                if dbgEn == 1 then print(err) end
                return
            end
        end
    until false
end

repeat
    local ok, err = coroutine.resume(coroutine.create(main))                             -- start main routine
        if not ok then
                if dbgEn == 1 then print(err) end
        end
    socket.sleep(1)             			                                 -- 1 second delay
until false
