FROM docker.io/ibmcom/mq
ENV LICENSE="accept"
ENV MQ_QMGR_NAME="MQMFT"
USER 1001
COPY 01-coordsetup.mqsc /etc/mqm/
COPY 10-agent10.mqsc /etc/mqm/
COPY 20-agent20.mqsc /etc/mqm/
CMD chmod 777 /etc/mqm/
COPY setqmaut.sh /root/setqmaut.sh
COPY startmqserver.sh /root/startmqserver.sh
ENTRYPOINT bash /root/startmqserver.sh
