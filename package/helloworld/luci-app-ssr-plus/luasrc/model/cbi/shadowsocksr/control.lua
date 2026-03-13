require "luci.ip"
require "nixio.fs"
require "luci.sys"
local m, s, o

local function is_finded(e)
	return luci.sys.exec(string.format('type -t -p "%s" 2>/dev/null', e)) ~= ""
end

m = Map("shadowsocksr")

s = m:section(TypedSection, "access_control")
s.anonymous = true

-- Interface control
s:tab("Interface", translate("Interface control"))
o = s:taboption("Interface", DynamicList, "Interface", translate("Interface"))
o.template = "cbi/network_netlist"
o.widget = "checkbox"
o.nocreate = true
o.unspecified = true
o.description = translate("Listen only on the given interface or, if unspecified, on all")

-- Part of WAN
s:tab("wan_ac", translate("WAN IP AC"))

o = s:taboption("wan_ac", DynamicList, "wan_bp_ips", translate("WAN White List IP"))
o.datatype = "ip4addr"

o = s:taboption("wan_ac", DynamicList, "wan_fw_ips", translate("WAN Force Proxy IP"))
o.datatype = "ip4addr"

-- Part of LAN
s:tab("lan_ac", translate("LAN IP AC"))

o = s:taboption("lan_ac", ListValue, "lan_ac_mode", translate("LAN Access Control"))
o:value("0", translate("Disable"))
o:value("w", translate("Allow listed only"))
o:value("b", translate("Allow all except listed"))
o.rmempty = false

-- Collect IP to hostname mapping from DHCP leases and ARP
local ip_hostname = {}
if luci.sys.net and luci.sys.net.host_hints then
	luci.sys.net.host_hints(function(mac, hostname, ip)
		if ip and hostname and hostname ~= "" and not hostname:match("^%d+%.%d+%.%d+%.%d+$") then
			ip_hostname[ip] = hostname
		end
	end)
end
-- Also try reading DHCP leases directly
for line in io.lines("/tmp/dhcp.leases") do
	local ts, mac, ip, hostname = line:match("^(%S+)%s+(%S+)%s+(%S+)%s+(%S+)")
	if ip and hostname and hostname ~= "*" then
		ip_hostname[ip] = hostname
	end
end

-- Collect and sort LAN neighbor IPs
local lan_ips = {}
luci.ip.neighbors({family = 4}, function(entry)
	if entry.reachable then
		table.insert(lan_ips, entry.dest:string())
	end
end)
table.sort(lan_ips, function(a, b)
	local function ip_to_number(ip)
		local n = 0
		for part in ip:gmatch("%d+") do
			n = n * 256 + tonumber(part)
		end
		return n
	end
	return ip_to_number(a) < ip_to_number(b)
end)

-- Helper function to format IP with hostname
local function format_ip_with_hostname(ip)
	local hostname = ip_hostname[ip]
	if hostname and hostname ~= "" then
		return ip, string.format("%s (%s)", ip, hostname)
	else
		return ip, ip
	end
end

o = s:taboption("lan_ac", DynamicList, "lan_ac_ips", translate("LAN Host List"))
o.datatype = "ipaddr"
for _, ip in ipairs(lan_ips) do
	local val, display = format_ip_with_hostname(ip)
	o:value(val, display)
end
o:depends("lan_ac_mode", "w")
o:depends("lan_ac_mode", "b")

o = s:taboption("lan_ac", DynamicList, "lan_bp_ips", translate("LAN Bypassed Host List"))
o.datatype = "ipaddr"
for _, ip in ipairs(lan_ips) do
	local val, display = format_ip_with_hostname(ip)
	o:value(val, display)
end

o = s:taboption("lan_ac", DynamicList, "lan_fp_ips", translate("LAN Force Proxy Host List"))
o.datatype = "ipaddr"
for _, ip in ipairs(lan_ips) do
	local val, display = format_ip_with_hostname(ip)
	o:value(val, display)
end

o = s:taboption("lan_ac", DynamicList, "lan_gm_ips", translate("Game Mode Host List"))
o.datatype = "ipaddr"
for _, ip in ipairs(lan_ips) do
	local val, display = format_ip_with_hostname(ip)
	o:value(val, display)
end

-- Part of Self
-- s:tab("self_ac", translate("Router Self AC"))
-- o = s:taboption("self_ac",ListValue, "router_proxy", translate("Router Self Proxy"))
-- o:value("1", translatef("Normal Proxy"))
-- o:value("0", translatef("Bypassed Proxy"))
-- o:value("2", translatef("Forwarded Proxy"))
-- o.rmempty = false

s:tab("esc", translate("Bypass Domain List"))
local escconf = "/etc/ssrplus/white.list"
o = s:taboption("esc", TextValue, "escconf")
o.rows = 13
o.wrap = "off"
o.rmempty = true
o.cfgvalue = function(self, section)
	return nixio.fs.readfile(escconf) or ""
end
o.write = function(self, section, value)
	nixio.fs.writefile(escconf, value:gsub("\r\n", "\n"))
end
o.remove = function(self, section, value)
	nixio.fs.writefile(escconf, "")
end

s:tab("block", translate("Black Domain List"))
local blockconf = "/etc/ssrplus/black.list"
o = s:taboption("block", TextValue, "blockconf")
o.rows = 13
o.wrap = "off"
o.rmempty = true
o.cfgvalue = function(self, section)
	return nixio.fs.readfile(blockconf) or " "
end
o.write = function(self, section, value)
	nixio.fs.writefile(blockconf, value:gsub("\r\n", "\n"))
end
o.remove = function(self, section, value)
	nixio.fs.writefile(blockconf, "")
end

s:tab("denydomain", translate("Deny Domain List"))
local denydomainconf = "/etc/ssrplus/deny.list"
o = s:taboption("denydomain", TextValue, "denydomainconf")
o.rows = 13
o.wrap = "off"
o.rmempty = true
o.cfgvalue = function(self, section)
	return nixio.fs.readfile(denydomainconf) or " "
end
o.write = function(self, section, value)
	nixio.fs.writefile(denydomainconf, value:gsub("\r\n", "\n"))
end
o.remove = function(self, section, value)
	nixio.fs.writefile(denydomainconf, "")
end

s:tab("netflix", translate("Netflix Domain List"))
local netflixconf = "/etc/ssrplus/netflix.list"
o = s:taboption("netflix", TextValue, "netflixconf")
o.rows = 13
o.wrap = "off"
o.rmempty = true
o.cfgvalue = function(self, section)
	return nixio.fs.readfile(netflixconf) or " "
end
o.write = function(self, section, value)
	nixio.fs.writefile(netflixconf, value:gsub("\r\n", "\n"))
end
o.remove = function(self, section, value)
	nixio.fs.writefile(netflixconf, "")
end

if is_finded("dnsproxy") then
	s:tab("dnsproxy", translate("Dnsproxy Parse List"))
	local dnsproxyconf = "/etc/ssrplus/dnsproxy_dns.list"
	o = s:taboption("dnsproxy", TextValue, "dnsproxyconf", "", "<font style=color:red>" .. translate("Specifically for edit dnsproxy DNS parse files.") .. "</font>")
	o.rows = 13
	o.wrap = "off"
	o.rmempty = true
	o.cfgvalue = function(self, section)
		return nixio.fs.readfile(dnsproxyconf) or " "
	end
	o.write = function(self, section, value)
		nixio.fs.writefile(dnsproxyconf, value:gsub("\r\n", "\n"))
	end
	o.remove = function(self, section, value)
		nixio.fs.writefile(dnsproxyconf, "")
	end
end

if luci.sys.call('[ -f "/www/luci-static/resources/uci.js" ]') == 0 then
	m.apply_on_parse = true
	function m.on_apply(self)
		luci.sys.call("/etc/init.d/shadowsocksr reload > /dev/null 2>&1 &")
	end
end

return m
