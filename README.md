
Java SpringBoot REST backend demo with Azure SQL Database
Angular2 frontend

SQL Server 2016 LocalDB database, very lightweight local developer setup (namedPipes not TCP), but with same TSQL surface as SQL Azure

Environment Specific configuration in environment variables, for Team Services CI/CD

Docker Build for deployment into Linux App Service,  Container Services or Service Fabric.

https://www.microsoft.com/en-us/sql-server/sql-server-editions-express



Create local env (with LocalDB - SQL Server Express 2016):

### change directory to backend
cd backend
### start the localDB (to get the namePipe)
sqllocaldb s MSSQLLocalDB

### set the environment variables
$env:PORT=5400
$env:INSTANCE="LOCALDB#XXXXXXXXX" 
$env:JDBC_DBNAME="devdb"
$env:JDBC_USERNAME="dev"
$env:JDBC_PASSWORD="xxxxxxxxxxxx"
$env:JDBC_DRIVER="net.sourceforge.jtds.jdbc.Driver"
$env:JDBC_URL="jdbc:jtds:sqlserver://./" + $env:JDBC_DBNAME + ";instance=" + $env:INSTANCE + ";namedPipe=true;useJCIFS=false;user=" + $env:JDBC_USERNAME + ";password=" + $env:JDBC_PASSWORD
$env:PIPE_URL="np:\\.\pipe\" + $env:INSTANCE + "\tsql\query"


## re-create the development database and tables
sqlcmd -S $env:PIPE_URL -v user=$env:JDBC_USERNAME -v dbname=$env:JDBC_DBNAME -v passwd=$env:JDBC_PASSWORD -i env_setup\localdb.sql
## check all good
sqlcmd -S $env:PIPE_URL -U $env:JDBC_USERNAME -P $env:JDBC_PASSWORD -d $env:JDBC_DBNAME
        > select name from sys.tables;
        > go

##To run a project in place without building a jar first you can use the “bootRun” task
> gradle bootRun


## to test 
curl localhost:5400
curl localhost:5400/profiles -H "Content-Type: application/json" -X POST -d '{"firstName": "Jim", "lastName": "Smith"}'
curl localhost:5400/profiles/1



## VSTS build pipeline
#
#
# build jar without tests
> gradle assemble 
# build image with a tag of [dockerhub username/][reponame]:tag-name
> docker build .
# tag the image
> docker tag image_id [registry url]/[repo]:[tag]
# login to registry
> docker login [registry url]
# push the image
> docker push [registry url]/[repo]:[tag]


## List images in private registry 
#
# 
# list all repos
> curl -u username:password https://teambeta-microsoft.azurecr.io/v2/_catalog 
# list all tags under a [repo]
> curl -u username:password https://teambeta-microsoft.azurecr.io/v2/[repo]/tags/list
# get manifest
> curl -u username:password https://teambeta-microsoft.azurecr.io/v2/[repo]/manifests/[tag]

## deployment
# create sql database [teambeta]-[repo-tag] (server [teambeta])
# create webapp linux - with encironment variables [teambeta-[repo-tag]]
JDBC_DRIVER=
JDBC_URL=


## Swarm 1.12 on Azure (with built-in 'Docker Swarm Mode')
# setup local bash
 > install docker cli (1.12.x)
# append group 'docker'
 > sudo usermod -a -G docker `whoami`
 > curl -L https://github.com/docker/machine/releases/download/v0.9.0-rc2/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine && \
  chmod +x /usr/local/bin/docker-machine


## Setup cluster in Azure
# create RG/VNET, gateway subnet, application gateway
> az ....
# docker cluster (hosts managed by Docker Machine)

> docker-machine create --driver azure --azure-ssh-user "kehowli" --azure-subscription-id "95efa97a-9b5d-4f74-9f75-a3396e23344d" --azure-resource-group "TeamBetaVSTSTest" --azure-vnet "TeamBetaVSTSTest-vnet" --azure-subnet "machinecluster" --azure-subnet-prefix "172.18.0.32/28" --azure-location "westeurope" --swarm --swarm-master machinehost01
> docker-machine ls
> docker-machine ssh machinehost01
## point your local docker cli client to the node machinehost01
> eval $(docker-machine env machinehost01)
> docker swarm init  # IMPORTANT take a note of the join cmd!
> docker node ls
## create 2nd docker host, and run the join command


## deploy image to cluster
#  The swarm manager accepts the service description as the desired state for your application

## add VSTS 'Run a Docker comand'
# connect to private registry
# connect to docker host, get the cert information using 
 >  eval $(docker-machine env <manager>)
 > docker-machine config <manager>
#command
>  service create --with-registry-auth --publish 8080:5001 --env JDBC_DRIVER=com.microsoft.sqlserver.jdbc.SQLServerConnection --env JDBC_URL=jdbc:sqlserver://$(RG_NAME).database.windows.net:1433;database=$(Build.Repository.Name)-$(Build.SourceVersion);user=$(sql_username)@$(RG_NAME);password=$(sql_password);encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30; --env PORT=8080 teambeta-microsoft.azurecr.io/$(Build.Repository.Name):8


## to view
> docker service ls
> docker service inspect <serviceid> # this lists environment, and targetports
# swarm ingress network: --publish <PUBLISHED-PORT>:<TARGET-PORT> :  https://docs.docker.com/engine/swarm/ingress/
# service logs
> docker service ps <service>
> docker logs $(docker inspect --format "{{.Status.ContainerStatus.ContainerID}}" ps)