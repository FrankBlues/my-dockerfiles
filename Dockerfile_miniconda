FROM centos:centos7

LABEL authors="mlm"

ENV PATH /opt/miniconda/bin:$PATH

# 设置中文环境 
RUN yum -y update \
    && yum reinstall -y glibc-common \
    && yum install -y telnet net-tools \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8 \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && yum -y install curl bzip2 \
    && curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -bfp /opt/miniconda/ \
    && rm -rf /tmp/miniconda.sh \
    && conda install -y python=3 \
    && conda update conda \
    && conda clean --all --yes \
    && rpm -e --nodeps curl bzip2 \
    && yum clean all \
    && ln -s /opt/miniconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/miniconda/etc/profile.d/conda.sh" >> ~/.bashrc \
    && echo "conda activate base" >> ~/.bashrc

ENV LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_ALL=zh_CN.UTF-8

# 遥感gis相关依赖
# RUN conda install --yes -c conda-forge satpy cartopy arcsi rsgislib libboost scikit-learn scikit-image
# RUN conda install --yes -c conda-forge numpy gdal rasterio geopandas shapely fiona matplotlib \
#     && conda clean --yes -t

# set gdal path
# ENV GDAL_DATA /opt/miniconda/share/gdal

# Add Tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

USER root
WORKDIR /opt

CMD [ "/bin/bash" ]
