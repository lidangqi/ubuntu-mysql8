#!/bin/bash
set -o errexit #运行某一行出错时立即退出。
set -- mysqld_safe $@ #定义启动命令
echo "\$@:$@"
#初始化传值变量
MYSQL_USER=${MYSQL_USER:=""}
MYSQL_PASSWORD=${MYSQL_PASSWORD:=""}
#如果是变量值为root则重新赋值为空
if [ "${MYSQL_USER}" = "root" ]
  then MYSQL_USER=""
fi
echo "MYSQL_USER=$MYSQL_USER"
echo "MYSQL_PASSWORD=$MYSQL_PASSWORD"
 
echo "----开始初始化mysql----------------------"
if [ ! -f /data/mysql/logs/mysql.err ];then
        mkdir -p /data/mysql/{data,logs,conf}
        touch /data/mysql/logs/mysql.err
        chown -R mysql.mysql /data
        /usr/local/mysql/bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql/data
        cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
        chmod 777 /etc/init.d/mysqld
        ln -s /usr/local/mysql/bin/* /usr/bin/
        echo "初始化数据库完毕.数据持目录:/data/mysql"
elif [ ! -f /etc/init.d/mysqld ];then
        cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
        chmod 777 /etc/init.d/mysqld
        ln -s /usr/local/mysql/bin/* /usr/bin/
fi
echo "设置变量"
passwd="$(awk '/localhost/{print $NF}' /data/mysql/logs/mysql.err|head -1)"
mysql="mysql --protocol=socket -uroot -hlocalhost --socket="/tmp/mysql.sock""
dbinit="mysql --connect-expired-password -uroot -p$passwd"
echo "启动数据库"
#启动数据库并判断状态
/etc/init.d/mysqld restart && sleep 3
echo "启动后查看进程"
port=$(ss -lntp|grep "3306"|wc -l)
echo $port
for p in {3..0}; do
  if [ $port -eq 0 ];then
     echo "Mysql启动失败-重新启动"
     /etc/init.d/mysqld restart && sleep 2
  else
       echo "Mysql 已经启动"
       break
  fi
  if [ "$p" = 0 ];then
    echo >&2 'MySQL 启动失败!'
        exit 1
  fi
done
echo $passwd
echo "开始初始化用户密码"
#passinit="alter  user 'root'@'localhost' identified by '';GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '' WITH GRANT OPTION;"
#if [ ! -f /data/mysql/logs/mysql.err ];then
passinit="alter user 'root'@'localhost' identified with mysql_native_password by '';CREATE USER IF NOT EXISTS 'root'@'%';ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password by '';flush privileges;"
echo "$passinit" | $dbinit &> /dev/null && echo "初始化成功"
#fi
#再次重启
echo "再次重启验证密码"
for i in {2..0}; do
     if echo "SELECT 1" | $mysql &> /dev/null; then
        echo 'MySQL 验证空密码成功!'
            break
     else
        sleep 1;echo "重新验证"
    fi
    if [ "$i" = 0 ]; then
    echo >&2 'MySQL 验证空密码失败!'
        exit 1
    fi
done
echo "开始进入匹配..."
if [ "${MYSQL_USER}" != "" -o "${MYSQL_PASSWORD}" != "" ];then
        echo "指定了变量--"
        echo "进入匹配开始"
 
        #用户不为空,密码不为空---创建用户名 密码,默认授权管理员权限
        if [ "${MYSQL_USER}" != "" -a "${MYSQL_PASSWORD}" != "" -a "${db_database}" = "" ];then
                c="CREATE USER IF NOT EXISTS '"${MYSQL_USER}"'@'%'; ALTER USER '"${MYSQL_USER}"'@'%' IDENTIFIED WITH mysql_native_password by '"${MYSQL_PASSWORD}"';flush privileges;"
                echo "$c" | $mysql &> /dev/null && echo "添加成功" || echo "创建用户失败"
 
        #用户名为空,密码不为空,数据库为空-------------修改root密码
        elif [ "${MYSQL_USER}" = "" -a "${MYSQL_PASSWORD}" != "" -a "${db_database}" = "" ];then
                c="ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password by '${MYSQL_PASSWORD}';flush privileges;"
        echo $c
                echo "$c" | $mysql &> /dev/null &&  echo "添加成功" || echo "修改密码失败"
 
        else
                echo "没有匹配项目"
                echo "help:docker xxx image MYSQL_USER=xx MYSQL_PASSWORD=xx db_database=xx"
                exit 1
        fi
else
        echo "没有指定变量:用户root密码为空"
fi
 
/etc/init.d/mysqld stop && sleep 1 && echo "关闭成功"
echo "$@" && exec $@
