#!/bin/sh

dev=`ip route get 8.8.8.8 | grep dev | awk '{print $5}'`
ip=`ip addr show $dev | grep ^[\ \t]*inet\ | sed -e "s/^[\ \t]*inet //;s/\/.*//;s/\ peer.*//" | sed -n 1p`

bucket="af-consul-config"
bucket_list=`/opt/s3cmd/s3cmd ls s3://af-consul-config/ 2>/dev/null`
s3_avail=$?
if [ $s3_avail -ne 0 ]; then
    echo "S3 Bucket is unavailable (Error $s3_avail)"
    exit $s3_avail
fi

dc=`cat /consul/config/dc.json | jq -r '.datacenter'`
dc_exists=`echo $bucket_list | grep peers-$dc | wc -l`
#cluster_exists=`echo $bucket_list | grep peers | wc -l`
key_generated=`echo $bucket_list | grep key.json | wc -l`
peer=peers-$dc-`hostname -s`

    /opt/s3cmd/s3cmd get s3://af-consul-config/peers*.json /consul/config/

# Consul first run
if [ -f /consul/firstrun ]; then
    echo "{ \"start_join\": [\"$ip\"] }" > /consul/config/$peer.json
    /opt/s3cmd/s3cmd get s3://af-consul-config/main.json /consul/config/main.json
    /opt/s3cmd/s3cmd put /consul/config/$peer.json s3://$bucket/$peer.json
    if [ "$key_generated" -eq "0" ]; then
	echo "{ \"encrypt\": \"`consul keygen`\" }" > /consul/config/key.json
	/opt/s3cmd/s3cmd put /consul/config/key.json s3://$bucket/key.json
    else
	/opt/s3cmd/s3cmd get s3://af-consul-config/key.json /consul/config/key.json
    fi
    if [ "$dc_exists" -eq "0" ]; then
	echo "{ \"bootstrap\": true }" > /consul/config/bootstrap.json
    else
	echo "{ \"bootstrap\": false }" > /consul/config/bootstrap.json
    fi
    rm /consul/firstrun
fi

config_test=`consul configtest -config-dir=/consul/config/`
config_exit=$?

cd /consul/config
for wan_peer in `ls  | grep ^peers | grep -v $dc`
do
    sed -i 's/start_join/start_join_wan/g' $wan_peer
done

if [ "$config_exit" -eq "0" ]; then
    /bin/consul agent -config-dir=/consul/config/ -data-dir=/consul/data -bind=$ip
else
    echo $config_test
    exit $config_exit
fi
