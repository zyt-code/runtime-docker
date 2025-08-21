# 使用 Ubuntu 22.04 LTS 作为基础镜像
# ---------- 基础 ----------
FROM docker.1ms.run/ubuntu:22.04

# 避免交互
ENV DEBIAN_FRONTEND=noninteractive

# ---------- 换阿里云源 ----------
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list

# ---------- 安装基础工具 ----------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openssh-server sudo ca-certificates curl wget git vim nano \
    openjdk-8-jdk maven python3 python3-pip nodejs npm && \
    rm -rf /var/lib/apt/lists/*

# ---------- 配置 SSH ----------
RUN echo 'root:root' | chpasswd && \
    mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# ---------- 配置 Maven 阿里云镜像 ----------
RUN mkdir -p /root/.m2 && \
    echo '<?xml version="1.0" encoding="UTF-8"?><settings><mirrors><mirror><id>aliyun</id><mirrorOf>*</mirrorOf><url>https://maven.aliyun.com/repository/public</url></mirror></mirrors></settings>' > /root/.m2/settings.xml

# ---------- 配置 npm 淘宝源 ----------
RUN npm config set registry https://registry.npmmirror.com

# ---------- 工作目录 ----------
WORKDIR /workspace
VOLUME ["/workspace"]

# ---------- 暴露端口 ----------
EXPOSE 22

# ---------- 默认启动 ----------
CMD ["/usr/sbin/sshd", "-D"]
