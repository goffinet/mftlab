# Authorize agents to connect with identity context.
setmqaut -m MQMFT -t qmgr -p app +connect +inq +setid

# Authorize agents to publish on SYSTEM.FTE queue and topic.
setmqaut -m MQMFT -n SYSTEM.FTE -t q -p app +all
setmqaut -m MQMFT -n SYSTEM.FTE -t topic -p app +all
setmqaut -m MQMFT -n SYSTEM.DEFAULT.MODEL.QUEUE -t q -p app +put +get +dsp

# Set authorities on AGENT10 agent queues.
setmqaut -m MQMFT -n SYSTEM.FTE.COMMAND.AGENT10 -t q -p app +get +setid +browse +put
setmqaut -m MQMFT -n SYSTEM.FTE.DATA.AGENT10 -t q -p app +put +get
setmqaut -m MQMFT -n SYSTEM.FTE.EVENT.AGENT10 -t q -p app +put +get
setmqaut -m MQMFT -n SYSTEM.FTE.REPLY.AGENT10 -t q -p app +put +get
setmqaut -m MQMFT -n SYSTEM.FTE.STATE.AGENT10 -t q -p app +put +get +inq +browse
setmqaut -m MQMFT -n SYSTEM.FTE.HA.AGENT10 -t q -p app +put +get +inq

# Set authorities on AGENT20 agent queues.
setmqaut -m MQMFT -n SYSTEM.FTE.COMMAND.AGENT20 -t q -p app +get +setid +browse +put
setmqaut -m MQMFT -n SYSTEM.FTE.DATA.AGENT20 -t q -p app +put +get
setmqaut -m MQMFT -n SYSTEM.FTE.EVENT.AGENT20 -t q -p app +put +get
setmqaut -m MQMFT -n SYSTEM.FTE.REPLY.AGENT20 -t q -p app +put +get
setmqaut -m MQMFT -n SYSTEM.FTE.STATE.AGENT20 -t q -p app +put +get +inq +browse
setmqaut -m MQMFT -n SYSTEM.FTE.HA.AGENT20 -t q -p app +put +get
