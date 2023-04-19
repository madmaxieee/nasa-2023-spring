FROM ubuntu:22.04

EXPOSE 80

RUN apt update && apt install -y nginx
COPY index.html /var/www/html/index.html
CMD ["nginx", "-g", "daemon off;"]