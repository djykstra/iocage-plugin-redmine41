# iocage-plugin-redmine41
freenas redmine41 plugin


download file redmine41.json 
put to iocage/.plugin_index/

run as root
iocage fetch -P -n redmine41 -dhcp=on vnet=on bpf=yes 
or
iocage fetch -P -n redmine41 ip4_addr="interface|ip_address"

OR

download file redmine41.json 
put to /tmp/

run as root
iocage fetch -P -dhcp=on vnet=on bpf=yes -n /tmp/redmine41.json
or 
iocage fetch -P ip4_addr="interface|ip_address" -n /tmp/redmine41.json
