
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
$env:JDBC_DRIVER="net.sourceforge.jtds.jdbc.Driver"
$env:INSTANCE="LOCALDB#XXXXXXXXX" 
$env:JDBC_DBNAME="devdb"
$env:JDBC_USERNAME="dev"
$env:JDBC_PASSWORD="xxxxxxxxxxxx"
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

# build jar without tests
> gradle assemble 

# build image with a tag of [dockerhub username/][reponame]:tag-name
> docker build .

# tag the image
> docker tag image_id [registry url]/[repo]:[tag]

# login to registry
docker login [registry url]

# push the image
> docker push [registry url]/[repo]:[tag]


## deployment
# create sql database [teambeta]-[repo-tag] (server [teambeta])
# create webapp linux - with encironment variables [teambeta-[repo-tag]]
JDBC_DRIVER
JDBC_URL