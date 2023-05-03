docker network create --subnet=172.20.0.0/16 dnslab-net
docker build -t bind9 .
docker run -dit --rm --name=dns-server --label=dnslab --net=dnslab-net --ip=172.20.0.2 bind9
docker exec -d dns-server /etc/init.d/bind9 start
docker attach dns-server

