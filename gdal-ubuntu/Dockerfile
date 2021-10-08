FROM mellemm/gdal-ubuntu:v0.2.0

COPY ./config ~/.cargo/

RUN cd /opencv/build && make install \
    && apt-get install -y clang
