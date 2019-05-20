FROM golang:1.12-alpine
MAINTAINER vishwanath.kulkarni@sap.com
WORKDIR /go/src
EXPOSE 8000
#for git (no need to mention why)
RUN apk add --no-cache git
#for gcc executable(because Brrow need to run)
RUN apk add --no-cache git curl gcc libc-dev
#add jq
RUN apk add --no-cache jq
#add python3 and toml
RUN echo $PATH
RUN apk add --no-cache python3 && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    rm -r /root/.cache
RUN pip3 install toml
RUN echo $PATH
RUN go get -u github.com/golang/dep/cmd/dep
RUN go get -u github.com/vishwakulkarni/Burrow
RUN cd $GOPATH/src/github.com/vishwakulkarni/Burrow && \
	dep ensure && \
	go build
RUN cd $GOPATH/src/github.com/vishwakulkarni/Burrow && \
    mv Burrow $GOPATH/src/
RUN cd $GOPATH/src/github.com/vishwakulkarni/Burrow && \
    mv kafka-config/burrow.toml $GOPATH/src/
RUN cd $GOPATH/src/github.com/vishwakulkarni/Burrow && \
    mv kafka-config/setup.sh $GOPATH/src/
RUN cd $GOPATH/src/github.com/vishwakulkarni/Burrow && \
    mv kafka-config/setup.py $GOPATH/src/
RUN mkdir logs && \
    touch logs/burrow.log
RUN chmod u+x /go/src/setup.sh
RUN chmod u+x /go/src/setup.py
ENV VCAP_SERVICES='{"kafka":[{"label":"kafka","provider":null,"plan":"dedicated","name":"test_kafka","tags":["kafka"],"instance_name":"test_kafka","binding_name":null,"credentials":{"username":"sbss_9rjwy-anhzeepowwv3elib5bnexa53ixfkn9hwgtu25szzj2u32xdycg1chevfbmu2q=","password":"aa_gzwnmonQR7xNJLBt6fg321Bv4MI=","urls":{"ca_cert":"https://kafka-service-broker.cf.sap.hana.ondemand.com/certs/rootCA.crt","token":"https://kafka-service-oauth.cf.sap.hana.ondemand.com/v1/39976793-dd2d-411a-bdf8-5504188dd84b/token","token_key":"https://kafka-service-oauth.cf.sap.hana.ondemand.com/v1/token_key","service":"https://kafka-service.cf.sap.hana.ondemand.com/v1/39976793-dd2d-411a-bdf8-5504188dd84b"},"cluster":{"zk":"10.254.20.10:2181,10.254.20.11:2181,10.254.20.12:2181","brokers":"10.254.20.21:9093,10.254.20.22:9093,10.254.20.23:9093","brokers.auth_ssl":"10.254.20.21:9093,10.254.20.22:9093,10.254.20.23:9093"},"tenant":"39976793-dd2d-411a-bdf8-5504188dd84b"},"syslog_drain_url":null,"volume_mounts":[]}]}'
RUN echo "source /go/src/setup.sh" > /root/.bashrc
RUN echo "python3 /go/src/setup.py" > /root/.bashrc
RUN . $GOPATH/src/setup.sh
#RUN echo "source /go/src/setup.sh" > /go/src/.bashrc
#RUN python3 $GOPATH/src/setup.py

CMD source /go/src/setup.sh && python3 /go/src/setup.py && ./Burrow --config-dir .