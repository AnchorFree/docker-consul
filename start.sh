#!/bin/sh

dev=`ip route get 8.8.8.8 | grep dev | awk '{print $5}'`
ip=`ip addr show $dev | grep ^[\ \t]*inet\ | sed -e "s/^[\ \t]*inet //;s/\/.*//;s/\ peer.*//" | sed -n 1p`

bucket="af-consul-config"
bucket_list=`/bin/s3cmd ls s3://$bucket/ 2>/dev/null`
s3_avail=$?
if [ $s3_avail -ne 0 ]; then
	echo "S3 Bucket is unavailable (Error $s3_avail)"
	exit $s3_avail
fi

peer=`hostname -s`
dc=`echo $peer | cut -f2 -d'-'`
dc_exists=`echo $bucket_list | grep peers- | wc -l`
key_generated=`echo $bucket_list | grep key.json | wc -l`

# Peers already exists
if [ $dc_exists -ne "0" ]; then
	echo Getting peers information
	/bin/s3cmd get s3://$bucket/peers*.json /consul/config/
fi

# Consul first run
if [ -f /consul/firstrun ]; then
	echo "{ \"datacenter\": \"$dc\" }"  > /consul/config/dc.json
	echo "{ \"start_join\": [\"$ip\"] }" > /consul/config/peers-$peer.json
	/bin/s3cmd get s3://$bucket/main.json /consul/config/main.json
	/bin/s3cmd put /consul/config/peers-$peer.json s3://$bucket/peers-$peer.json
	if [ "$key_generated" -eq "0" ]; then
		echo "{ \"encrypt\": \"`consul keygen`\" }" > /consul/config/key.json
		/bin/s3cmd put /consul/config/key.json s3://$bucket/key.json
	else
		/bin/s3cmd get s3://$bucket/key.json /consul/config/key.json
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
	sed -i 's/\"start_join\"/\"start_join_wan\"/g' $wan_peer
done

if [ "$config_exit" -eq "0" ]; then
	/bin/consul agent -config-dir=/consul/config/ -data-dir=/consul/data -bind=$ip
else
	echo $config_test
	exit $config_exit
fi
