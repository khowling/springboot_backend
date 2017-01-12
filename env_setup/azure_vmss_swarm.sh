
if [ $# -lt 2 ]
  then
    echo "Incorrect arguments supplied: $0 <resource_group> <swarn_name> [nodes (default=2)]"
    exit 1
fi

NEWRG=$1
export SWARNNAME=$2
export NODES=${3:-2}

## list all subnets
#az network vnet list --query '[].{group:resourceGroup, vnet:name, subnets:subnets[].name}'

export RGNAME="TeamBeta-CoreResources"
export VNET="TeamBetaVnet"
export SUB="cluster"


export HOSTNAME=${SWARNNAME,,}-${NEWRG,,}.uksouth.cloudapp.azure.com
export DOCKER_CERT_PATH=~/.docker/${HOSTNAME}

function gen_docker_certs {

  ## gen docker verts
  DAYS=1460
  PASS=$(openssl rand -hex 16)

  mkdir -p ${DOCKER_CERT_PATH}
  current_dir=$PWD
  cd ${DOCKER_CERT_PATH}
  # remove certificates from previous execution.
  rm -f *.pem *.srl *.csr *.cnf


  # generate CA private and public keys
  echo 01 > ca.srl
  openssl genrsa -des3 -out ca-key.pem -passout pass:$PASS 2048
  openssl req -subj "/CN=${HOSTNAME}/" -new -x509 -days $DAYS -passin pass:$PASS -key ca-key.pem -out ca.pem

  # create a server key and certificate signing request (CSR)
  openssl genrsa -des3 -out server-key.pem -passout pass:$PASS 2048
  openssl req -new -key server-key.pem -out server.csr -passin pass:$PASS -subj "/CN=${HOSTNAME}/"

  # sign the server key with our CA
  openssl x509 -req -days $DAYS -passin pass:$PASS -in server.csr -CA ca.pem -CAkey ca-key.pem -out server-cert.pem

  # create a client key and certificate signing request (CSR)
  openssl genrsa -des3 -out key.pem -passout pass:$PASS 2048
  openssl req -subj '/CN=client' -new -key key.pem -out client.csr -passin pass:$PASS

  # create an extensions config file and sign
  echo extendedKeyUsage = clientAuth > extfile.cnf
  openssl x509 -req -days $DAYS -passin pass:$PASS -in client.csr -CA ca.pem -CAkey ca-key.pem -out cert.pem -extfile extfile.cnf

  # remove the passphrase from the client and server key
  openssl rsa -in server-key.pem -out server-key.pem -passin pass:$PASS
  openssl rsa -in key.pem -out key.pem -passin pass:$PASS

  # remove generated files that are no longer required
  rm -f ca-key.pem ca.srl client.csr extfile.cnf server.csr
  cd $current_dir
}

gen_docker_certs

PARAMS="{\"swarm_name\": { \"value\": \"${SWARNNAME}\"}, \"swarm_nodes\": { \"value\": \"${NODES}\"}, \"adminUsername\": { \"value\": \"$(whoami)\"}, \"ssh_keyData\": { \"value\": \"`cat  ~/.ssh/id_rsa.pub`\" }, \"vnet_resource_group\": { \"value\": \"${RGNAME}\"}, \"vnet_name\": { \"value\": \"${VNET}\"}, \"vnet_subnet_name\": { \"value\": \"${SUB}\"}, \"docker_ca_base64\": { \"value\": \"`base64 -w 0 $DOCKER_CERT_PATH/ca.pem`\"}, \"docker_key_base64\": { \"value\": \"`base64 -w 0 $DOCKER_CERT_PATH/server-key.pem`\"}, \"docker_cert_base64\": { \"value\": \"`base64 -w 0 $DOCKER_CERT_PATH/server-cert.pem`\"}}"

#echo $PARAMS
read -p "Create the Resource Group \"${NEWRG}\" (y/n): " answer
case ${answer:0:1} in
    y|Y )
        echo "creating group....."
        az group create -l uksouth -n $NEWRG
    ;;
esac

echo "creating swarm & loadbalancer....."
az group deployment create -g  $NEWRG -n ${NEWRG}_d1 --template-file ./azure_vmss_swarm.json --parameters "${PARAMS}"

echo "creating swarm (manager ${HOSTNAME})....."
sleep 5
ssh ${HOSTNAME} -oStrictHostKeyChecking=no -p 50000 'docker swarm init'

read -p "Copy and Paste join command from above: " joinans
ssh ${HOSTNAME} -oStrictHostKeyChecking=no -p 50001 "${joinans}"

echo "To point docker cli to the engine, run: 
export DOCKER_TLS_VERIFY=1
export DOCKER_HOST=tcp://${HOSTNAME}:2376
export DOCKER_CERT_PATH=${DOCKER_CERT_PATH}
docker node list
"
# look at cluster
# > docker --tls=true node list