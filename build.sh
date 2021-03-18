# 版本号
VERSION=1.0.3
# -q 输出全部容器ID
# -a 输出所有容器信息，包括未启动的容器
# -f 指定使用过滤器
# ^ 容器名称必须使用此字符串开始
# $ 容器名称必须使用次字符串结束
# 使用$(指令)将指令结果赋值给变量
containerId=$(sudo docker ps -aqf 'name=^emilygateway$')
if [ "$containerId" = "" ]; then
  echo '容器不存在，无需删除'
else
  echo '已存在的容器ID是:'${containerId}
  docker stop ${containerId}
  echo '开始休眠'
  sleep 2
  echo '已休眠2s'
  docker rm -f ${containerId}
  echo '删除容器成功...'
fi

imageId=$(docker images -q emilygateway:${VERSION})
if [ "$imageId" = "" ]; then
   echo '镜像不存在，无需删除'
else
   echo '存在镜像ID是：'${imageId}
   docker rmi ${imageId}
   echo '删除镜像成功'
fi
  # 端口号占用查询
  # lsof -i tcp:port
  echo '开始打包...'
  mvn clean package
  echo '打包完成...'
  # docker build命令用于使用Dockerfile创建镜像
  # 语法：docker build [OPTIONS] PATH | URL | -
  # -f:指定要使用的Dockerfile路径
  # -t:镜像的名字及标签，通常是name:tag或name格式
  # .代表本次执行的上下文路径
  docker build -f ./Dockerfile . -t emilygateway:${VERSION}
  echo '镜像构建完成...'
  localIp=$(/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
  echo '本机Ip地址是：'${localIp}

  httpPort=80
  httpsPort=443
  managementPort=7443
  # 运行构建的镜像
  docker run \
  -e JAVA_ACL_TOKEN=03259e78-848c-3ea8-c0f6-524279d52929 \
  -e JAVA_LOCAL_IP=${localIp} \
  -e JAVA_LOCAL_PORT=80 \
  -e JAVA_LOCAL_MANAGEMENT_PORT=${managementPort} \
  --restart=always \
  --privileged=true \
  -itd --name emilygateway \
  -p ${httpPort}:80 \
  -p ${httpsPort}:443 \
  -p ${managementPort}:7443 \
  -v /Users/yaomingyang/Documents/IDE/workplace-java/logs:/app/logs \
  emilygateway:${VERSION}
  echo '容器创建成功...'