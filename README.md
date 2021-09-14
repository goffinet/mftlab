# LAB: MQMFT Agent in Container

## Quick start

This lab requires only Docker and docker-compose, here on a Scaleway instance.

```bash
scw instance server create type=DEV1-M zone=nl-ams-1 image=centos_8 root-volume=l:40G ip=new name=mqftlab
scw instance server list zone=nl-ams-1
```

```bash
dnf -y install git
git clone https://github.com/goffinet/mftlab
cd mftlab
bash -x startup.sh
```

Or launch it with Terraform:

```bash
git clone https://github.com/goffinet/mftlab
cd mftlab
terraform init
terraform apply -auto-approve
```

## 1. Introduction

This lab introduces how to use MQ Managed File Transfer Agent container.

IBM MQ Managed File Transfer transfers files between systems in a managed and auditable way, regardless of file size or the operating systems used. You can use Managed File Transfer to build a customized, scalable, and automated solution that enables you to manage, trust, and secure file transfers. Managed File Transfer eliminates costly redundancies, lowers maintenance costs, and maximizes your existing IT investments.

- IBM MQ Knowledge Centre ([https://www.ibm.com/docs/en/ibm-mq/9.2?topic=overview-managed-file-transfer](https://www.ibm.com/docs/en/ibm-mq/9.2?topic=overview-managed-file-transfer))
- IBM MQ Container ([https://hub.docker.com/r/ibmcom/mq](https://hub.docker.com/r/ibmcom/mq))
- IBM MQ Managed File Transfer Container - ([https://hub.docker.com/r/ibmcom/mqmft](https://hub.docker.com/r/ibmcom/mqmft))

## 2.Basic Requirements

- Linux Operation System. Preferably RHEL 8.1 or Ubuntu 18.x.
- As this lab involves usage of containers, this lab requires Docker Container Runtime and docker-compose to be installed on your machine.

```bash
setup_docker_ce() {
echo $(date -Is) Setup Docker
dnf -y install epel-release
dnf -y install git htop
dnf -y config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce --nobest --allowerasing -y
systemctl enable --now docker
dnf -y install python3
pip3 install docker-compose
echo $(date -Is) Setup Docker OK
}
setup_docker_ce
```

## 3. Analyze the docker-compose file

In this lab, you will create from the [`docker-compose.yml`](https://github.com/goffinet/mftlab/blob/main/docker-compose.yml) file:

- A queue manager `MQMFT` in a Docker container using the Docker image from DockerHub.([https://hub.docker.com/r/ibmcom/mq](https://hub.docker.com/r/ibmcom/mq)) This queue manager will be used as Coordination, Command and Agent queue manager. [We use here custom build](https://github.com/goffinet/mftlab/tree/main/images/qm).
- Two MQ MFT agents, `AGENT10` and `AGENT20` running in separate containers ([https://hub.docker.com/r/ibmcom/mqmft](https://hub.docker.com/r/ibmcom/mqmft)).
- A [DNS server for `mqmftlab.com`](https://github.com/goffinet/mftlab/blob/main/images/bind/lib/mqmftlab.com.hosts) local domain and a [data generator](https://github.com/goffinet/mftlab/tree/main/images/datagen).

On the command line:

- You will create a resource monitor to automatically transfer files from source file system to destination file system.

[`agentconfig.json`](https://github.com/goffinet/mftlab/blob/main/images/mftagent/agentconfig.json) - A JSON file containing the configuration information required for creating agent containers. [Here](https://github.com/ibm-messaging/mft-cloud/tree/master/docs/agentconfig.md) are the details of each attribute in the JSON file.

A datagenerator container will generate fake data to `/mountpath/agent20/flow2/input/new` on AGENT10 agent.

`/mountpath` – Path on the host file system mounted into container as `/mountpath`. This will be the directory where the agent will pick files to transfer in the local `./data/<agent>/<peer>/<flow>` folder with this subfolder structure:

```
.
├── input
│   ├── new
│   ├── old
│   └── tmp
└── output
    ├── new
    ├── old
    └── tmp
```

## 4. Launch the lab

```bash
git clone https://github.com/goffinet/mftlab.git
cd mftlab
docker-compose up --build -d
docker-compose ps
docker-compose logs qm
docker-compose logs agent10
```

Run `dspmq` command inside the container and verify queue manager is running:

```bash
docker exec -it mftlab_qm_1 dspmq
```

## 5. Check if transfer is working

Now that you have configured queue manager and agents, it's time to automate transfers using a resource monitor. Resource monitor is major feature of MQ Managed File Transfer Agent. It helps to automatically trigger transfers at the occurrence of an event, for example arrival of a file with certain pattern name in a directory or MQ Queue. You can read more about [Resource Monitors](https://www.ibm.com/docs/en/ibm-mq/9.2?topic=resources-mft-resource-monitoring-concepts) in Knowledge Center.

Remember you mounted `./data/agent10/agent20/flow1/input/new` of the host file system into `agent10` container as `/mountpath/agent20/flow1/input/new` directory. Similarly, `./data/agent20/agent10/flow1/output/new` was mounted as `/mountpath/agent10/flow1/output/new` of `agent20` container.

Please give all permissions on the data transfer folder on the Docker host before to start any transfer:

```bash
chmod -R 777 data/
```

Run the following command into the source agent container:

```bash
docker exec -it mftlab_agent10_1 ls -lh /mountpath/agent20/flow1/input/new/
ls -lh data/agent10/agent20/flow1/input/new/
```

For your convenience the `/mountpath/agent20/flow1/input/new/` directory already has some ".csv" files.

Run the following command to status of available agents:

```bash
docker exec -it mftlab_agent10_1 fteListAgents
```

The output would list the agents and their status.

Before setting up resource monitor, let's verify transfer works. Submit a transfer request using `fteCreateTransfer` command.

```bash
docker exec -it mftlab_agent10_1 fteCreateTransfer -p MQMFT -t binary -sa AGENT10 -sm MQMFT -da AGENT20 -dm MQMFT -de overwrite -dd "/mountpath/agent10/flow1/output/new/" "/mountpath/agent20/flow1/input/new/*"
```

View the status of transfer by running the `mqfts` utility. This utility displays transfer status by parsing `capture0.log` file located in source agent's log directory.

To view more details of the transfer, run `mqfts -–id=<transfer id>`. For example:

```bash
docker exec -it mftlab_agent10_1 mqfts
docker exec -it mftlab_agent10_1 mqfts --id=414d51204d514d46542020202020202044bfbd60019b0040
ls -lh data/agent20/agent10/flow1/output/new/
```

## 6. Automate transfer with Resource monitor

Now it's time to automate transfers using a resource monitor. You will create a Directory type resource monitor that monitors a directory for certain pattern of files. It will transfer file from that directory when files of matching pattern are placed in the directory.

In the below example you will create a resource monitor on AGENT10 that monitors `/mountpath/agent20/flow2/input/new` directory every 15 seconds for ".csv" files and transfers them to `/mountpath/agent10/flow2/output/new/` folder on the destination agent AGENT20.

The `fteCreateTransfer -gt` option creates a file in the current directory. You may not have access to current directory. Hence task.xml file will be created in /mountpath directory.

Now run the following commands to create transfer definition for the monitor AGENT10_AGENT20_FLOW2.
**Important note: The `$` must be prefixed with escape character `\` on bash shell, otherwise it will be ignored when the command is run.**

```bash
docker exec -it mftlab_agent10_1 fteCreateTransfer -gt /mountpath/task.xml -sa AGENT10 -sm MQMFT -da AGENT20 -dm MQMFT -sd delete -de overwrite -dd "/mountpath/agent10/flow2/output/new/" "\${FilePath}"
```

Then run the following command to create resource monitor:

```bash
docker exec -it mftlab_agent10_1 fteCreateMonitor -p MQMFT -ma AGENT10 -mn AGENT10_AGENT20_FLOW2 -md "/mountpath/agent20/flow2/input/new/" -pi 15 -pu SECONDS -pt wildcard -tr "noSizeChange=2,*.csv" -f -mt /mountpath/task.xml
```

Verify the resource monitor creation by running the following command:

```bash
docker exec -it mftlab_agent10_1 fteListMonitors -v -ma AGENT10 -mn AGENT10_AGENT20_FLOW2
```

Now that resource monitor has been created and started, exit the shell of `agent10` container to come back to host systems shell.

1. For your convenience the `/mountpath/agent20/flow2/input/new/` get fake data generated randomly.

After few seconds, verify that transfer has completed, and files are indeed available in `/mountpath/agent10/flow2/output/new/` output directory on AGENT20 or in the local directory `data/agent20/agent10/flow2/output/new/`.

You can also verify the transfer status by logging into `agent10` container and running mqfts command

```bash
docker exec -it mftlab_agent10_1 mqfts
```

This completes the setting up of automated transfers using resource monitors.

Logout of `agent10` container shell, if you had logged in.

Resource monitor triggers a transfer only if any new files arrive in the monitored directory or any existing files are modified. To verify this, create a new .csv file by running the following command:

```bash
touch data/agent10/agent20/flow2/input/new/newsalary.csv
```

A transfer will be trigged when resource monitor starts the next poll. The polling interval of resource monitor is set to 15 seconds, a transfer will be triggered within 15 seconds. Verify the contents of `data/agent20/agent10/flow2/output/new/` after 15 seconds.

You can also verify the resource monitor transfer triggers transfers only when files of a matching pattern arrive in the monitored folder. Create a file by running the following command

```bash
touch data/agent10/agent20/flow2/input/new/oldperks.xls
```

Verify the contents of `data/agent10/agent20/flow2/input/new/` after 15 seconds, `oldperks.xls` file should not be present.

## 7. Other commands of Managed File Transfer

It's now time to explore other commands of Managed File Transfer

Stop resource monitor using the command:

```bash
docker exec -it mftlab_agent10_1 fteStopMonitor -ma AGENT10 -mn AGENT10_AGENT20_FLOW2
```

Place new files with .csv extension in `data/agent10/agent20/flow2/input/new/` on the host file system and see if the new files are transferred.

Start monitor using the command:

```bash
docker exec -it mftlab_agent10_1 fteStartMonitor -ma AGENT10 -mn AGENT10_AGENT20_FLOW2
```

Verify new csv files you placed are transferred.

Stop agent using the command:

```bash
docker exec -it mftlab_agent10_1 fteStopAgent AGENT10
```

Verify the container is still running.

Restart the agent using the command:

```bash
docker exec -it mftlab_agent10_1 fteStartAgent AGENT10
```

## 8. Backup a monitor

## 9. Delete a monitor

## 10. Import a monitor

## 11. Shutdown the lab

Once you have explored other commands of Managed File Transfer, stop all containers with the commands below

```bash
docker-compose down
```

## 12. Add an agent

If you want add an agent, you must adapt :

1. the `docker-compose.yml` file,
2. the qm image build,
3. the `agentconfig.json` file
4. and the dns zone.

Project: add a bridge agent and a SFTP server

## License

Issued from [IBM MQ Managed File Transfer Container](https://github.com/ibm-messaging/mft-cloud)

The Dockerfiles and associated code and scripts are licensed under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0.html).
Licenses for the products installed within the images are as follows:

- [IBM MQ Advanced for Developers](http://www14.software.ibm.com/cgi-bin/weblap/lap.pl?la_formnum=Z125-3301-14&li_formnum=L-APIG-BMKG5H) (International License Agreement for Non-Warranted Programs). This license may be viewed from an image using the `LICENSE=view` environment variable as described above or by following the link above.
- [IBM MQ Advanced](http://www14.software.ibm.com/cgi-bin/weblap/lap.pl?la_formnum=Z125-3301-14&li_formnum=L-APIG-BMJJBM) (International Program License Agreement). This license may be viewed from an image using the `LICENSE=view` environment variable as described above or by following the link above.

Note: The IBM MQ Advanced for Developers license does not permit further distribution and the terms restrict usage to a developer machine.

## Copyright

© Copyright IBM Corporation 2020, 2021
