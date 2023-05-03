docker build -t host .
docker run -dit --rm --name=client --label=dnslab --net=dnslab-net --dns=172.20.0.2  --ip=172.20.0.3 host
docker exec -it client bash
