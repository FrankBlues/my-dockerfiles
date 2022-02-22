FROM mellemm/miniconda-centos7-rs:v0.1
#RUN pip install pillow
COPY ./rstools /opt/

WORKDIR /opt/

RUN yum install -y epel-release && \
    yum install -y jq && \
		yum clean all