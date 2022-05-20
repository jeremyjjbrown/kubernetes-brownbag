FROM ubuntu:20.04

#RUN yum -y update && yum -y install epel-release && \
#    yum -y install python-pip
RUN apt -y update && apt -y install python3 python3-pip
RUN pip install --upgrade pip && \
    pip install flask
COPY app.py app.py

ENTRYPOINT ["python3", "app.py"]
