#/bin/bash

#-------------------------
# Bash script used for install the Matrix Synapse Server
# url   : bakingrpi.com
# author: baking raspberry Pi
#-------------------------

# exit when any command fails
set -e

DATETIME="`date +%Y-%m-%d` `date +%T%z`" # Date format

CurrentDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
## Generate the Path needed
MatrixSynapseFolder=${CurrentDIR}/Matrix/synapse


## get the systematic information 
#MyIP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
mainMyDomain="example.com"

declare -A levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
script_logging_level="INFO"

logThis() {
    local log_message=$1
    local log_priority=$2

    #check if level exists
    [[ ${levels[$log_priority]} ]] || return 1

    #check if level is enough
    (( ${levels[$log_priority]} < ${levels[$script_logging_level]} )) && return 2

    #log here
    echo "${log_priority} : ${log_message}"
}


function hello () {
  cat <<'EOF'
*************************************************************
*      github Repo   :    https://github.com/AnnaMHua/RaspberryPi
*      offical websit: http://bakingrpi.com/
*      
*      📦 Play Raspberry Pi like A Pro
*      🤐 Setup Matrix Synapse Server
*      💻 on your Raspberry Pi
*      💖 by one-line of command
*      
*      author : Baking Raspberry Pi
*      Youtube: https://www.youtube.com/channel/UCFBHlyED8_VZ2yfLXoAXrbg
*************************************************************
EOF

echo 
echo -e "\e[1m \e[33m [Attention]:: \e[0m "
echo 
echo "This script is tested working on Raspberry Pi 4 with Raspberry OS. \
The test  system was fresh installed with the initial enviroment.\
But we can not promise it will work on any other system "
      
read -p "Do you agree to use this script on your own risk[Y/N]:" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Starting install the Server!!"
else
     echo -e " \e[33m  No Package install because  user terminated ! \e[0m "
      cat <<'EOF'
*************************************************************

       You can visit The following site to get more tutorials!
    
*      Youtube       : https://www.youtube.com/channel/UCFBHlyED8_VZ2yfLXoAXrbg

*      github Repo   :    https://github.com/AnnaMHua/RaspberryPi

*      offical websit: http://bakingrpi.com/
        
*************************************************************
EOF
    exit 0
fi
}

function preRequisitesInstaller () {
    # apt installer 
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install -y build-essential python3-dev libffi-dev \
                            python-pip python-setuptools sqlite3 \
                            libssl-dev python-virtualenv libjpeg-dev libxslt1-dev
}

function CreateFolder () {
    logThis "Creating folder $1" "INFO"
    sudo -u $SUDO_USER mkdir -p $1
}

function synapseInstaller () {
    ## start install the synapse server, need python3 and virtual enviroment installed 
    logThis "Start Install Matrix Synapse" "INFO"
    logThis " Matrix Synapse install folder $(MatrixSynapseFolder)" "INFO"

    CreateFolder ${MatrixSynapseFolder}
    cd ${MatrixSynapseFolder}
    virtualenv -p python3 ${MatrixSynapseFolder}/venv
    source ${MatrixSynapseFolder}/venv/bin/activate
    pip install --upgrade pip virtualenv six packaging appdirs
    pip install --upgrade setuptools
    pip install matrix-synapse

    logThis " Matrix Synapse Have been installed to  ${MatrixSynapseFolder}" "INFO"
}

function synapseConfig () {
    cd ${MatrixSynapseFolder}
    source ${MatrixSynapseFolder}/venv/bin/activate
    pythonVersion=$(python --version)
    pipVersion=$(pip --version)
    logThis " Matrix Synapse Env: ${pythonVersion} with ${pipVersion} " "INFO"

    # read in the configure ration domain
    # read in the user input IP and compare with the auto detected IP
    source ${CurrentDIR}/config.cfg
    if [ "${myDomain}" == "exapmle.com" ]; then
        read -p "Your have not set your somain in file config.cfg, Do you want to input by hand[Y/N]:" -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            read -p "Your have not set your somain in file config.cfg, Do you want to input by hand[Y/N]:" -n 1 -r
            echo    # (optional) move to a new line
            myDomain=${REPLY}
            read -p "Please confirm your domain \"${myDomain}\"[Y/N]:" -n 1 -r
            echo    # (optional) move to a new line
            if [[ $REPLY =~ ^[Yy]$ ]]
            then
                echo "Using domain ${myDomain}"
            else:
                synapseInstaller
            fi
        else
            echo -e " \e[33m  Terminated Because of Domain is not set ! \e[0m "
            exit -2
        fi
    fi

    
    logThis "Config Matrix Synapse with Domain ${myDomain}" "INFO"
    mainMyDomain=${myDomain}

    python -m synapse.app.homeserver \
        --server-name ${myDomain} \
        --config-path homeserver.yaml \
        --generate-config \
        --report-stats=yes
    
    # check the output config file, if file does not exist, terminate the code
    # TODO

    ## Modify the homeserver.yaml
    ## with 
}


function tls_installer () {
    logThis "Set up TLS with Domain ${mainMyDomain}" "INFO"
    sudo apt-get install certbot python-certbot-nginx -y

    sudo apt-get install nginx -y

    #generate certification
    sudo certbot certonly --nginx -d ${mainMyDomain}

    # TODO double check the existance of the generated file
    
}

function ngnix_Prox_config () {
    #domain="test.com"
    #template=$(cat ${CurrentDIR}/template/nginx_matrix_template.conf)
    sed -e "s;%DOMAIN%;$1;g" ${CurrentDIR}/template/nginx_matrix_template.conf > ${CurrentDIR}/generated/matrix.conf
    # TODO double check the existance of the generated file 

    initialngixMatrixConf="/etc/nginx/conf.d/matrix.conf"
    if [ -e ${initialngixMatrixConf} ]
        then sudo cp ${initialngixMatrixConf} ${CurrentDIR}/backups
    else
        echo
        #TODO need to add flag, used for roll back to previous setting 
    fi

    sudo cp ${CurrentDIR}/generated/matrix.conf ${initialngixMatrixConf}

    # restart the ngnix service 
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    #TODO  need to check whether the ngnix, need to check the web load status 
    logThis "End of set ngnix" "INFO"
}

function rpiPortEnable () {
    sudo apt install ufw -y 
    sudo ufw enable
    sudo ufw allow 443
    sudo ufw allow 80
    sudo ufw allow 8448
}

function autoTestMatrix () {
    if /usr/bin/wget "https://synapase.bakingrpi.com" --timeout 30 -O - 2 | grep "Your Synapse server is listening on this port and is ready for messages." > /dev/null; then 
          echo
          echo
          cat <<'EOF'
  💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖💖
                🎊    Success!!!    🎊

          💖 Congratulation!!
          👍 Your Synapse Server install successfully!!
          🎊 You can enjoy chat with your friend with Matrix 
          👍 If you like this scripts, please give us a 👍 on Youtube
          💖 https://www.youtube.com/channel/UCFBHlyED8_VZ2yfLXoAXrbg

     More Raspberry Pi Project on Youtube <Baking Raspberry Pi>
*************************************************************
*      github Repo   :    https://github.com/AnnaMHua/RaspberryPi
*      offical websit: http://bakingrpi.com/
*      
*      📦 Play Raspberry Pi like A Pro
*      🤐 Setup Matrix Synapse Server
*      💻 on your Raspberry Pi
*      💖 by one-line of command
*      
*      author : Baking Raspberry Pi
*      Youtube: https://www.youtube.com/channel/UCFBHlyED8_VZ2yfLXoAXrbg
*************************************************************
EOF

        read -p "Do you want to check more tutorials [Y/N]:" -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            xdg-open https://www.youtube.com/channel/UCFBHlyED8_VZ2yfLXoAXrbg
        fi
    else
    echo -e " \e[33m  Auto Diagnose Failled! Cannot reach ${mainMyDomain} ! \e[0m "

      cat <<'EOF'

    To help us improve the codem, please report a bug on https://github.com/AnnaMHua/RaspberryPi 

*************************************************************

       You can visit The following site to get more tutorials!
    
*      Youtube       : https://www.youtube.com/channel/UCFBHlyED8_VZ2yfLXoAXrbg

*      github Repo   :    https://github.com/AnnaMHua/RaspberryPi

*      offical websit: http://bakingrpi.com/
        
*************************************************************
EOF
    exit 0
fi
}

function main () {
  hello
  preRequisitesInstaller
  rpiPortEnable
  synapseInstaller
  synapseConfig
  tls_installer
  ngnix_Prox_config ${mainMyDomain}
  autoTestMatrix
}


main
#autoTestMatrix
#ngnix_Prox_config test.com
#hello
#main
#synapseConfig
#tls_installer