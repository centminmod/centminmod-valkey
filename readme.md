Centmin Mod installation of Valkey as alternative drop in replacement for Redis server.

Assumption is that Centmin Mod default installed Redis server is in place first.

## Check available Valkey YUM packages in EPEL repo

```bash
yum list valkey* -q | tr -s ' ' | column -t
Available                         Packages     
valkey.x86_64                     8.0.1-3.el9  epel
valkey-compat-redis.noarch        8.0.1-3.el9  epel
valkey-compat-redis-devel.noarch  8.0.1-3.el9  epel
valkey-devel.x86_64               8.0.1-3.el9  epel
valkey-doc.noarch                 8.0.1-3.el9  epel
```

## Install & Setup Valkey Replacing Redis Server (REMI YUM package)

```bash
yum -y install valkey valkey-compat-redis --allowerasing
mkdir -p /etc/systemd/system/valkey.service.d
\cp -af /etc/systemd/system/redis.service.d/limit.conf.rpmsave /etc/systemd/system/valkey.service.d/limit.conf
sed -i 's|\/var\/log\/redis\/redis.log|\/var\/log\/valkey\/valkey.log|g' /etc/valkey/valkey.conf

cat > "/etc/systemd/system/valkey.service.d/user.conf" <<EOF
[Service]
User=valkey
Group=nginx
EOF

cat > "/etc/systemd/system/disable-thp.service" <<EOF
[Unit]
Description=Disable Transparent Huge Pages (THP)
After=network.target

[Service]
Type=simple
ExecStart=/bin/sh -c "/usr/bin/echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled"

[Install]
WantedBy=multi-user.target
EOF

cat > "/etc/systemd/system/valkey.service.d/failure-restart.conf" <<TDG
[Unit]
StartLimitIntervalSec=30
StartLimitBurst=5

[Service]
Restart=on-failure
RestartSec=5s
TDG

systemctl daemon-reload
systemctl restart disable-thp
systemctl enable disable-thp
systemctl start valkey
systemctl enable valkey
systemctl status disable-thp --no-pager -l
systemctl status valkey --no-pager -l
```

## Verifiy Symlinks For valkey-compat-redis YUM Package

```bash
ls -lah $(which redis-cli)
lrwxrwxrwx 1 root root 10 Nov 13 18:16 /usr/bin/redis-cli -> valkey-cli

ls -lah $(which redis-server)
lrwxrwxrwx 1 root root 13 Nov 13 18:16 /usr/bin/redis-server -> valkey-server
```

```bash
repoquery -l valkey-compat-redis
Last metadata expiration check: 0:08:18 ago on Fri 29 Nov 2024 10:06:17 AM UTC.
/usr/bin/redis-benchmark
/usr/bin/redis-check-aof
/usr/bin/redis-check-rdb
/usr/bin/redis-cli
/usr/bin/redis-sentinel
/usr/bin/redis-server
/usr/lib/systemd/system/redis-sentinel.service
/usr/lib/systemd/system/redis.service
/usr/libexec/migrate_redis_to_valkey.sh
```

```bash
yum install valkey-compat-redis --allowerasing
Last metadata expiration check: 0:21:26 ago on Fri 29 Nov 2024 10:06:17 AM UTC.
Dependencies resolved.
==============================================================================================================================================================================================================================================
 Package                                                        Architecture                                      Version                                                      Repository                                                Size
==============================================================================================================================================================================================================================================
Installing:
 valkey-compat-redis                                            noarch                                            8.0.1-3.el9                                                  epel                                                      11 k
Removing dependent packages:
 redis                                                          x86_64                                            7.2.6-1.el9.remi                                             @remi-modular                                            5.9 M

Transaction Summary
==============================================================================================================================================================================================================================================
Install  1 Package
Remove   1 Package

Total download size: 11 k
Is this ok [y/N]: y
Downloading Packages:
valkey-compat-redis-8.0.1-3.el9.noarch.rpm                                                                                                                                                                     22 kB/s |  11 kB     00:00    
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                                          13 kB/s |  11 kB     00:00     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                                                                                                      1/1 
  Installing       : valkey-compat-redis-8.0.1-3.el9.noarch                                                                                                                                                                               1/2 
  Running scriptlet: valkey-compat-redis-8.0.1-3.el9.noarch                                                                                                                                                                               1/2 
/etc/redis/redis.conf has been copied to /etc/valkey/valkey.conf.  Manual review of valkey.conf is strongly suggested especially if you had modified redis.conf.
/etc/redis/sentinel.conf has been copied to /etc/valkey/sentinel.conf.  Manual review of sentinel.conf is strongly suggested especially if you had modified sentinel.conf.
On-disk redis dumps moved from /var/lib/redis/ to /var/lib/valkey

  Running scriptlet: redis-7.2.6-1.el9.remi.x86_64                                                                                                                                                                                        2/2 

Removed "/etc/systemd/system/multi-user.target.wants/redis.service".
Warning: The unit file, source configuration file or drop-ins of redis.service changed on disk. Run 'systemctl daemon-reload' to reload units.

  Erasing          : redis-7.2.6-1.el9.remi.x86_64                                                                                                                                                                                        2/2 
warning: file /var/lib/redis: remove failed: No such file or directory
warning: /etc/systemd/system/redis.service.d/limit.conf saved as /etc/systemd/system/redis.service.d/limit.conf.rpmsave
warning: file /etc/redis/sentinel.conf: remove failed: No such file or directory
warning: file /etc/redis/redis.conf: remove failed: No such file or directory

  Running scriptlet: redis-7.2.6-1.el9.remi.x86_64                                                                                                                                                                                        2/2 
  Verifying        : valkey-compat-redis-8.0.1-3.el9.noarch                                                                                                                                                                               1/2 
  Verifying        : redis-7.2.6-1.el9.remi.x86_64                                                                                                                                                                                        2/2 

Installed:
  valkey-compat-redis-8.0.1-3.el9.noarch                                                                                                                                                                                                      
Removed:
  redis-7.2.6-1.el9.remi.x86_64                                                                                                                                                                                                               

Complete!
```

## Check Valkey VS Redis Differences

```bash
ls -lAhrt /etc/valkey
total 124K
-rw-r----- 1 valkey root 106K Nov 29 10:27 valkey.conf
-rw-r----- 1 valkey root  15K Nov 29 10:27 sentinel.conf

ls -lAhrt /etc/redis
total 232K
-rw-r----- 1 redis root  15K Oct  3 06:42 sentinel.conf.rpmsave
-rw-r----- 1 redis root 106K Oct  3 06:42 redis.conf-backup-221124-133217
-rw-r----- 1 redis root 106K Nov 22 13:32 redis.conf.rpmsave
```
```bash
ls -lAhrt /var/lib/redis
ls: cannot access '/var/lib/redis': No such file or directory

ls -lAhrt /var/lib/valkey
total 4.0K
-rw-r--r-- 1 valkey valkey 88 Nov 22 13:32 dump.rdb
```
```bash
cat /etc/systemd/system/redis.service.d/limit.conf.rpmsave
# If you need to change max open file limit
# for example, when you change maxclient in configuration
# you can change the LimitNOFILE value below.
# See "man systemd.exec" for more information.

# Slave nodes on large system may take lot of time to start.
# You may need to uncomment TimeoutStartSec and TimeoutStopSec
# directives below and raise their value.
# See "man systemd.service" for more information.

[Service]
LimitNOFILE=524288
#TimeoutStartSec=90s
#TimeoutStopSec=90s
```
```bash
diff -u /etc/redis/redis.conf.rpmsave /etc/valkey/valkey.conf
```
```diff
--- /etc/redis/redis.conf.rpmsave       2024-11-22 13:32:20.023655176 +0000
+++ /etc/valkey/valkey.conf     2024-11-29 10:27:49.490220175 +0000
@@ -507,7 +507,7 @@
 # The Append Only File will also be created inside this directory.
 #
 # Note that you must specify a directory here, not a file name.
-dir /var/lib/redis
+dir /var/lib/valkey
 
 ################################# REPLICATION #################################
```
```bash
redis-cli info
# Server
redis_version:7.2.4
server_name:valkey
valkey_version:8.0.1
redis_git_sha1:00000000
redis_git_dirty:0
redis_build_id:4ed6032a97b67e84
server_mode:standalone
os:Linux 5.14.0-503.14.1.el9_5.x86_64 x86_64
arch_bits:64
monotonic_clock:POSIX clock_gettime
multiplexing_api:epoll
gcc_version:11.5.0
process_id:1682048
process_supervised:systemd
run_id:7769484dff765d89925a5dd005713fbda9f62d53
tcp_port:6379
server_time_usec:1732878357613568
uptime_in_seconds:97
uptime_in_days:0
hz:10
configured_hz:10
lru_clock:4825109
executable:/usr/bin/valkey-server
config_file:/etc/valkey/valkey.conf
io_threads_active:0
availability_zone:
listener0:name=tcp,bind=127.0.0.1,bind=-::1,port=6379

# Clients
connected_clients:1
cluster_connections:0
maxclients:10000
client_recent_max_input_buffer:0
client_recent_max_output_buffer:0
blocked_clients:0
tracking_clients:0
pubsub_clients:0
watching_clients:0
clients_in_timeout_table:0
total_watched_keys:0
total_blocking_keys:0
total_blocking_keys_on_nokey:0

# Memory
used_memory:932664
used_memory_human:910.80K
used_memory_rss:12058624
used_memory_rss_human:11.50M
used_memory_peak:932664
used_memory_peak_human:910.80K
used_memory_peak_perc:100.29%
used_memory_overhead:912312
used_memory_startup:912128
used_memory_dataset:20352
used_memory_dataset_perc:99.10%
allocator_allocated:1583104
allocator_active:1732608
allocator_resident:5414912
allocator_muzzy:0
total_system_memory:66829012992
total_system_memory_human:62.24G
used_memory_lua:31744
used_memory_vm_eval:31744
used_memory_lua_human:31.00K
used_memory_scripts_eval:0
number_of_cached_scripts:0
number_of_functions:0
number_of_libraries:0
used_memory_vm_functions:33792
used_memory_vm_total:65536
used_memory_vm_total_human:64.00K
used_memory_functions:184
used_memory_scripts:184
used_memory_scripts_human:184B
maxmemory:0
maxmemory_human:0B
maxmemory_policy:noeviction
allocator_frag_ratio:1.09
allocator_frag_bytes:149504
allocator_rss_ratio:3.13
allocator_rss_bytes:3682304
rss_overhead_ratio:2.23
rss_overhead_bytes:6643712
mem_fragmentation_ratio:13.22
mem_fragmentation_bytes:11146352
mem_not_counted_for_evict:0
mem_replication_backlog:0
mem_total_replication_buffers:0
mem_clients_slaves:0
mem_clients_normal:0
mem_cluster_links:0
mem_aof_buffer:0
mem_allocator:jemalloc-5.3.0
mem_overhead_db_hashtable_rehashing:0
active_defrag_running:0
lazyfree_pending_objects:0
lazyfreed_objects:0

# Persistence
loading:0
async_loading:0
current_cow_peak:0
current_cow_size:0
current_cow_size_age:0
current_fork_perc:0.00
current_save_keys_processed:0
current_save_keys_total:0
rdb_changes_since_last_save:0
rdb_bgsave_in_progress:0
rdb_last_save_time:1732878260
rdb_last_bgsave_status:ok
rdb_last_bgsave_time_sec:-1
rdb_current_bgsave_time_sec:-1
rdb_saves:0
rdb_last_cow_size:0
rdb_last_load_keys_expired:0
rdb_last_load_keys_loaded:0
aof_enabled:0
aof_rewrite_in_progress:0
aof_rewrite_scheduled:0
aof_last_rewrite_time_sec:-1
aof_current_rewrite_time_sec:-1
aof_last_bgrewrite_status:ok
aof_rewrites:0
aof_rewrites_consecutive_failures:0
aof_last_write_status:ok
aof_last_cow_size:0
module_fork_in_progress:0
module_fork_last_cow_size:0

# Stats
total_connections_received:1
total_commands_processed:0
instantaneous_ops_per_sec:0
total_net_input_bytes:14
total_net_output_bytes:0
total_net_repl_input_bytes:0
total_net_repl_output_bytes:0
instantaneous_input_kbps:0.00
instantaneous_output_kbps:0.00
instantaneous_input_repl_kbps:0.00
instantaneous_output_repl_kbps:0.00
rejected_connections:0
sync_full:0
sync_partial_ok:0
sync_partial_err:0
expired_keys:0
expired_stale_perc:0.00
expired_time_cap_reached_count:0
expire_cycle_cpu_milliseconds:1
evicted_keys:0
evicted_clients:0
evicted_scripts:0
total_eviction_exceeded_time:0
current_eviction_exceeded_time:0
keyspace_hits:0
keyspace_misses:0
pubsub_channels:0
pubsub_patterns:0
pubsubshard_channels:0
latest_fork_usec:0
total_forks:0
migrate_cached_sockets:0
slave_expires_tracked_keys:0
active_defrag_hits:0
active_defrag_misses:0
active_defrag_key_hits:0
active_defrag_key_misses:0
total_active_defrag_time:0
current_active_defrag_time:0
tracking_total_keys:0
tracking_total_items:0
tracking_total_prefixes:0
unexpected_error_replies:0
total_error_replies:0
dump_payload_sanitizations:0
total_reads_processed:1
total_writes_processed:0
io_threaded_reads_processed:0
io_threaded_writes_processed:0
io_threaded_freed_objects:0
io_threaded_poll_processed:0
io_threaded_total_prefetch_batches:0
io_threaded_total_prefetch_entries:0
client_query_buffer_limit_disconnections:0
client_output_buffer_limit_disconnections:0
reply_buffer_shrinks:0
reply_buffer_expands:0
eventloop_cycles:968
eventloop_duration_sum:123290
eventloop_duration_cmd_sum:0
instantaneous_eventloop_cycles_per_sec:9
instantaneous_eventloop_duration_usec:133
acl_access_denied_auth:0
acl_access_denied_cmd:0
acl_access_denied_key:0
acl_access_denied_channel:0

# Replication
role:master
connected_slaves:0
replicas_waiting_psync:0
master_failover_state:no-failover
master_replid:97096db9bcf142ac3672a8889244121130c6a3a9
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:0
second_repl_offset:-1
repl_backlog_active:0
repl_backlog_size:10485760
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0

# CPU
used_cpu_sys:0.043487
used_cpu_user:0.095520
used_cpu_sys_children:0.000000
used_cpu_user_children:0.000000
used_cpu_sys_main_thread:0.043192
used_cpu_user_main_thread:0.095461

# Modules

# Errorstats

# Cluster
cluster_enabled:0

# Keyspace
```
```bash
valkey-cli info
# Server
redis_version:7.2.4
server_name:valkey
valkey_version:8.0.1
redis_git_sha1:00000000
redis_git_dirty:0
redis_build_id:4ed6032a97b67e84
server_mode:standalone
os:Linux 5.14.0-503.14.1.el9_5.x86_64 x86_64
arch_bits:64
monotonic_clock:POSIX clock_gettime
multiplexing_api:epoll
gcc_version:11.5.0
process_id:1682048
process_supervised:systemd
run_id:7769484dff765d89925a5dd005713fbda9f62d53
tcp_port:6379
server_time_usec:1732878439665773
uptime_in_seconds:179
uptime_in_days:0
hz:10
configured_hz:10
lru_clock:4825191
executable:/usr/bin/valkey-server
config_file:/etc/valkey/valkey.conf
io_threads_active:0
availability_zone:
listener0:name=tcp,bind=127.0.0.1,bind=-::1,port=6379

# Clients
connected_clients:1
cluster_connections:0
maxclients:10000
client_recent_max_input_buffer:0
client_recent_max_output_buffer:0
blocked_clients:0
tracking_clients:0
pubsub_clients:0
watching_clients:0
clients_in_timeout_table:0
total_watched_keys:0
total_blocking_keys:0
total_blocking_keys_on_nokey:0

# Memory
used_memory:957352
used_memory_human:934.91K
used_memory_rss:12189696
used_memory_rss_human:11.62M
used_memory_peak:957352
used_memory_peak_human:934.91K
used_memory_peak_perc:100.21%
used_memory_overhead:912312
used_memory_startup:912128
used_memory_dataset:45040
used_memory_dataset_perc:99.59%
allocator_allocated:1789952
allocator_active:1945600
allocator_resident:5627904
allocator_muzzy:0
total_system_memory:66829012992
total_system_memory_human:62.24G
used_memory_lua:31744
used_memory_vm_eval:31744
used_memory_lua_human:31.00K
used_memory_scripts_eval:0
number_of_cached_scripts:0
number_of_functions:0
number_of_libraries:0
used_memory_vm_functions:33792
used_memory_vm_total:65536
used_memory_vm_total_human:64.00K
used_memory_functions:184
used_memory_scripts:184
used_memory_scripts_human:184B
maxmemory:0
maxmemory_human:0B
maxmemory_policy:noeviction
allocator_frag_ratio:1.09
allocator_frag_bytes:155648
allocator_rss_ratio:2.89
allocator_rss_bytes:3682304
rss_overhead_ratio:2.17
rss_overhead_bytes:6561792
mem_fragmentation_ratio:13.00
mem_fragmentation_bytes:11252128
mem_not_counted_for_evict:0
mem_replication_backlog:0
mem_total_replication_buffers:0
mem_clients_slaves:0
mem_clients_normal:0
mem_cluster_links:0
mem_aof_buffer:0
mem_allocator:jemalloc-5.3.0
mem_overhead_db_hashtable_rehashing:0
active_defrag_running:0
lazyfree_pending_objects:0
lazyfreed_objects:0

# Persistence
loading:0
async_loading:0
current_cow_peak:0
current_cow_size:0
current_cow_size_age:0
current_fork_perc:0.00
current_save_keys_processed:0
current_save_keys_total:0
rdb_changes_since_last_save:0
rdb_bgsave_in_progress:0
rdb_last_save_time:1732878260
rdb_last_bgsave_status:ok
rdb_last_bgsave_time_sec:-1
rdb_current_bgsave_time_sec:-1
rdb_saves:0
rdb_last_cow_size:0
rdb_last_load_keys_expired:0
rdb_last_load_keys_loaded:0
aof_enabled:0
aof_rewrite_in_progress:0
aof_rewrite_scheduled:0
aof_last_rewrite_time_sec:-1
aof_current_rewrite_time_sec:-1
aof_last_bgrewrite_status:ok
aof_rewrites:0
aof_rewrites_consecutive_failures:0
aof_last_write_status:ok
aof_last_cow_size:0
module_fork_in_progress:0
module_fork_last_cow_size:0

# Stats
total_connections_received:2
total_commands_processed:1
instantaneous_ops_per_sec:0
total_net_input_bytes:28
total_net_output_bytes:5738
total_net_repl_input_bytes:0
total_net_repl_output_bytes:0
instantaneous_input_kbps:0.00
instantaneous_output_kbps:0.00
instantaneous_input_repl_kbps:0.00
instantaneous_output_repl_kbps:0.00
rejected_connections:0
sync_full:0
sync_partial_ok:0
sync_partial_err:0
expired_keys:0
expired_stale_perc:0.00
expired_time_cap_reached_count:0
expire_cycle_cpu_milliseconds:2
evicted_keys:0
evicted_clients:0
evicted_scripts:0
total_eviction_exceeded_time:0
current_eviction_exceeded_time:0
keyspace_hits:0
keyspace_misses:0
pubsub_channels:0
pubsub_patterns:0
pubsubshard_channels:0
latest_fork_usec:0
total_forks:0
migrate_cached_sockets:0
slave_expires_tracked_keys:0
active_defrag_hits:0
active_defrag_misses:0
active_defrag_key_hits:0
active_defrag_key_misses:0
total_active_defrag_time:0
current_active_defrag_time:0
tracking_total_keys:0
tracking_total_items:0
tracking_total_prefixes:0
unexpected_error_replies:0
total_error_replies:0
dump_payload_sanitizations:0
total_reads_processed:3
total_writes_processed:1
io_threaded_reads_processed:0
io_threaded_writes_processed:0
io_threaded_freed_objects:0
io_threaded_poll_processed:0
io_threaded_total_prefetch_batches:0
io_threaded_total_prefetch_entries:0
client_query_buffer_limit_disconnections:0
client_output_buffer_limit_disconnections:0
reply_buffer_shrinks:0
reply_buffer_expands:0
eventloop_cycles:1789
eventloop_duration_sum:227280
eventloop_duration_cmd_sum:67
instantaneous_eventloop_cycles_per_sec:9
instantaneous_eventloop_duration_usec:126
acl_access_denied_auth:0
acl_access_denied_cmd:0
acl_access_denied_key:0
acl_access_denied_channel:0

# Replication
role:master
connected_slaves:0
replicas_waiting_psync:0
master_failover_state:no-failover
master_replid:97096db9bcf142ac3672a8889244121130c6a3a9
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:0
second_repl_offset:-1
repl_backlog_active:0
repl_backlog_size:10485760
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0

# CPU
used_cpu_sys:0.075659
used_cpu_user:0.174046
used_cpu_sys_children:0.000000
used_cpu_user_children:0.000000
used_cpu_sys_main_thread:0.075760
used_cpu_user_main_thread:0.173591

# Modules

# Errorstats

# Cluster
cluster_enabled:0

# Keyspace
```