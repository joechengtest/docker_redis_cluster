#!/bin/sh
if [ "$1" = 'redis-cluster' ]; then
    # Allow passing in cluster IP by argument or environmental variable
    IP="${2:-$IP}"
    mkdir -p /data/redis_conf
    mkdir -p /data/redis_data
    mkdir -p /data/redis_nodes
    mkdir -p /data/redis_log
    mkdir -p /data/redis_pid
    chown -R redis:redis /data
   
    echo "32867" > /proc/sys/net/core/somaxconn
    echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
    echo "never" > /sys/kernel/mm/transparent_hugepage/defrag


    for port in `seq 7000 7005`; do

      if [ -e /data/redis_nodes/nodes${port}.conf ]; then
        rm -rf /data/redis_nodes/nodes${port}.conf
      fi

      if [ -e /data/redis_data/dump${port}.rdb ]; then
        rm -rf /data/redis_data/dump${port}.rdb
      fi

      if [ -e /data/redis_data/appendonly.aof${port}.rdb ]; then
        rm -rf /data/redis_data/appendonly.aof${port}.rdb
      fi

      sed "s/\${PORT}/${port}/g" /opt/redis-cluster.tmpl > /data/redis_conf/redis${port}.conf

      redis-server /data/redis_conf/redis${port}.conf

    done

    if [ -z "$IP" ]; then # If IP is unset then discover it
        IP=$(hostname -i)
    fi
    IP=$(echo ${IP}) # trim whitespaces

    echo "yes"|redis-cli --cluster create --cluster-replicas 1 ${IP}:7000 ${IP}:7001 ${IP}:7002 ${IP}:7003 ${IP}:7004 ${IP}:7005
    
    tail -f /dev/null

else
  exec "$@"
fi

