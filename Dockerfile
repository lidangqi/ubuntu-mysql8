#FROM centos
FROM ubuntu:latest
LABEL lidangqi mysql8.0
#设置环境变量
ENV HOSTNAME=Mysql8.0
ENV MYSQL_HOME="/usr/local/mysql"
ENV MYSQL_TAR="mysql-8.0.29-linux-glibc2.17-x86_64-minimal.tar.xz"
ENV MYSQL_UNZIP_FILE="mysql-8.0.29-linux-glibc2.17-x86_64-minimal"
COPY mysql-8.0.29-linux-glibc2.17-x86_64-minimal.tar.xz /usr/local/src/
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN apt-get update -y && apt-get install -y xz-utils numactl libaio1 libncurses5 iproute2
RUN tar xvf /usr/local/src/${MYSQL_TAR} -C /usr/local/  \
        && mv /usr/local/${MYSQL_UNZIP_FILE} $MYSQL_HOME \
        && groupadd -r mysql && useradd -r -g mysql mysql
RUN rm -rf /usr/local/src/*gz \
        && apt remove -y --auto-remove curl make gcc xz-utils \
        && apt-get clean all \
        && rm -rf /var/cache/apt/archives/* \
        && rm -rf /var/lib/apt/lists/* 
COPY docker-mysql8.sh /usr/local/bin
COPY my.cnf /etc/
RUN  chmod 777 /usr/local/bin/docker-mysql8.sh
ENTRYPOINT ["docker-mysql8.sh"]
EXPOSE 3306
CMD ["--user=mysql"]
