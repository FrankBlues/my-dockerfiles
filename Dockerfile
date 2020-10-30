FROM osgeo/gdal:latest

RUN apt-get update -y \
    && apt-get install -y build-essential \
    && apt-get install -y language-pack-en language-pack-zh-hans \
    && locale-gen en_US.UTF-8 \
    && locale-gen zh_CN.UTF-8 \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_ALL=zh_CN.UTF-8