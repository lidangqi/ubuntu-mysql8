# ubuntu-mysql8

docker实战之基于ubuntu镜像制作mysql镜像

Ubuntu:latest + Mysql8.0.29

build image
$ docker build -t ubuntu-mysql .
run a container with new User and Password
$ docker run --name mysql -v /var/docker_data/mysql/data/:/data/mysql/data -d -p 3306:3306 -e MYSQL_PASSWORD=123 -e MYSQL_USER=dev ubuntu-mysql