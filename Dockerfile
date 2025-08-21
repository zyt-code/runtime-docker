# 使用 Ubuntu 22.04 LTS 作为基础镜像
FROM ubuntu:22.04

# 避免在安装过程中出现交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 更新包列表并安装基础工具
RUN apt-get update && \
    apt-get install -y \
        curl \
        wget \
        git \
        vim \
        nano \
        openssh-server \
        sudo \
        ca-certificates \
        gnupg \
        lsb-release \
        # 安装 MySQL 服务器
        mysql-server \
        # 安装 Redis 服务器
        redis-server && \
    # 清理 apt 缓存以减小镜像体积
    rm -rf /var/lib/apt/lists/*

# ========= 安装 Java 8 =========
# 导入 Adoptium GPG 密钥
RUN wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor > /etc/apt/trusted.gpg.d/adoptium.gpg
# 添加 Adoptium APT 仓库
RUN echo "deb https://packages.adoptium.net/artifactory/deb $(lsb_release -cs) main" > /etc/apt/sources.list.d/adoptium.list
# 更新包列表并安装 Temurin 8 JDK
RUN apt-get update && \
    apt-get install -y temurin-8-jdk && \
    rm -rf /var/lib/apt/lists/*

# 设置 JAVA_HOME 环境变量
ENV JAVA_HOME=/usr/lib/jvm/temurin-8-jdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# ========= 安装 Python 3 (Ubuntu 22.04 默认包含) =========
# 确保安装了 pip
RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# (可选) 创建 python 和 pip 的符号链接，方便使用
RUN ln -s /usr/bin/python3 /usr/local/bin/python && \
    ln -s /usr/bin/pip3 /usr/local/bin/pip

# ========= 安装 Node.js 22 =========
# 导入 NodeSource GPG 密钥
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource-keyring.gpg
# 添加 NodeSource APT 仓库
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource-keyring.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
# 更新包列表并安装 Node.js
RUN apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# ========= 配置 MySQL =========
# 设置 MySQL root 用户的默认密码 (示例为 'mysqlrootpassword'，请在生产中更改)
# 使用 debconf-set-selections 预先设置密码，避免交互
RUN echo "mysql-server mysql-server/root_password password mysqlrootpassword" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password mysqlrootpassword" | debconf-set-selections
# 重新配置 mysql-server 以应用密码
# RUN dpkg-reconfigure -f noninteractive mysql-server

# 允许 MySQL 通过 TCP/IP 连接，并绑定到所有接口 (开发环境)
RUN sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
RUN sed -i 's/mysqlx-bind-address.*/mysqlx-bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# ========= 配置 Redis =========
# 允许 Redis 绑定到所有接口 (开发环境)
RUN sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
# (可选) 禁用 Redis 保护模式 (如果 bind 0.0.0.0 则通常需要)
RUN echo "protected-mode no" >> /etc/redis/redis.conf

# ========= 配置 SSH =========
# 设置 root 密码 (示例为 'rootpassword'，请在生产中更改)
RUN echo 'root:rootpassword' | chpasswd
# 允许 root 通过 SSH 登录 (生产环境建议创建新用户)
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# (可选) 允许密码认证 (如果使用密钥认证可禁用)
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 创建 SSH 目录
RUN mkdir -p /var/run/sshd

# 创建工作目录
WORKDIR /home/coder
RUN mkdir -p /home/coder && chmod 755 /home/coder

# 暴露端口: SSH, MySQL, Redis
EXPOSE 22 3306 6379

# ========= 设置默认启动命令 =========
# 使用一个启动脚本启动所有服务
RUN echo '#!/bin/bash\n\
echo "Starting MySQL..."\n\
service mysql start\n\
echo "Starting Redis..."\n\
redis-server /etc/redis/redis.conf --daemonize yes\n\
echo "Starting SSH..."\n\
/usr/sbin/sshd -D\n'\
> /start.sh && chmod +x /start.sh

CMD ["/start.sh"]




