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
    lsb-release && \
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

# ========= 配置 SSH =========
# 设置 root 密码 (示例为 'rootpassword'，请在生产中更改)
RUN echo 'root:rootpassword' | chpasswd
# 允许 root 通过 SSH 登录 (生产环境建议创建新用户)
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# (可选) 允许密码认证 (如果使用密钥认证可禁用)
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 创建 SSH 目录并生成主机密钥 (如果需要)
RUN mkdir -p /var/run/sshd

# 创建工作目录
WORKDIR /home/coder
RUN mkdir -p /home/coder && chmod 755 /home/coder

# 暴露 SSH 端口
EXPOSE 22

# ========= 设置默认启动命令 =========
# 启动 SSH 服务
CMD ["/usr/sbin/sshd", "-D"]




