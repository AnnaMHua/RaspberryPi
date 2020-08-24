#!/bin/bash

DATETIME=$(date '+%Y-%m-%d_%H_%M_%S') # Date format
CurrentDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
mydomain=''
myIP='127.0.0.1'  # static IP address
myLocalIP='192.168.0.0'  # my local IP address, if use a router, my local IP maybe different from myIP(static IP address)
MatrixSynapseFolder=''
CoturnPassCode=''  # conturn  encrypt passcode, will generate automaticlly 

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

function autoTestMatrix () {

    if /usr/bin/wget -q "https://${mydomain}" --timeout 30 -O - 2 | grep "Your Synapse server is listening on this port and is ready for messages." > /dev/null; then
        echo "installed successfully"
        return 1
    else
    echo -e " \e[33m  Auto Diagnose Failled! Cannot reach ${mainMyDomain} ! \e[0m "

cat <<'EOF'

      Please Comfirm Matrix installed successfully and started!!!

To help us improve the codem, please report a bug on https://github.com/AnnaMHua/RaspberryPi 

*************************************************************

       You can visit The following site to get more tutorials!
    
*      Youtube       : https://www.youtube.com/channel/UCFBHlyED8_VZ2yfLXoAXrbg

*      github Repo   :    https://github.com/AnnaMHua/RaspberryPi

*      offical websit: http://bakingrpi.com/
        
*************************************************************
EOF
    exit -1
fi
}


function fireWallConfig () {
    if ! IsPackageInstalled ufw; then
        echo -e " \e[33m[Warnning]:: This Line should not appear if you installed the Matrix properly ! \e[0m "
        echo -e " \e[33m  ufw package should have been install when install the Matrix, Please confirm you want to continue your current install process ! \e[0m "
        
        read -p "Can not find ufw, Do you want to install now? But this may affect the current setting[Y/N]:" -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            sudo apt-get install ufw -y
        else
            echo "Terminated!! Please check your fire wall set correctly before continue the installation"
        fi
    else
        sudo ufw allow 5349
        sudo ufw allow 3478    
        sudo ufw allow 49152:65535/udp
        
    fi 

}

function IsPackageInstalled(){
    dpkg -s $1 &> /dev/null
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# generate new passocde for the coturn 
function PasswordGenerator () {
    passcodeLength=$1
    re='^[0-9]+$'
    if ! [[ ${passcodeLength} =~ $re ]] ; then
        passcodeLength=20
    fi
    CoturnPassCode=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c ${passcodeLength} ; echo '')
    echo $CoturnPassCode
}

function ReadSysInfor () {
    if ! IsPackageInstalled dnsutils; then
        sudo apt-get install dnsutils -y
    fi

    # get my static IP address 
    myIP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
    myLocalIP="$(hostname -I | cut -d' ' -f1)"
    
}

function LoadConfig () {
    source config.cfg
    if [ "$myDomain" = "example.com" ]; then
        read -p "Your have not set your somain in file config.cfg, Do you want to input by hand[Y/N]:" -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
            then
                read -p "Please input your domain [example.com]:" -r
                echo    # (optional) move to a new line
                myDomain=${REPLY}
                read -p "Please confirm your domain \"${myDomain}\"[Y/N]:" -r
                echo    # (optional) move to a new line
                    if [[ $REPLY =~ ^[Yy]$ ]]
                        then
                            echo "Using domain ${myDomain}"
                            mydomain=${myDomain}
                        else
                            # TODO add the N process 
                            echo -e " \e[33m  Terminated Because of Domain is not set ! \e[0m "
                            exit -2
                        fi
            else
                echo -e " \e[33m  Terminated Because of Domain is not set ! \e[0m "
                exit -2
        fi
    else
        mydomain=${myDomain}
    fi
    echo $mydomain

    MatrixSynapseFolder=${MatrixInstallDir}
    echo ${MatrixSynapseFolder}
}

function preCheck (){
    # check the installation folder
    if ! test -d ${MatrixSynapseFolder}; then
         echo -e " \e[33m  Terminated Because of Cannot find Matrix install path [${MatrixSynapseFolder}] ! \e[0m "
         echo -e " \e[33m  Please check whether you have set the config.cfg righr  or  \e[0m "
         echo -e " \e[33m  Or prabaly you have not install the matrix \e[0m "
    fi 
    echo 
}


function coturnInstaller () {
    # TODO need to check wether the coturn installed or not
    if ! IsPackageInstalled coturn; then
        sudo apt-get update -y
        sudo apt-get install -y coturn
    else
        echo "System detect coturn have been installed. Do you want to resinatall it?"
    fi  
}

function coturnConfig () {
    # step 1, backup the initial configuration if exist 
    if [ -f /etc/turnserver.conf ]; then
        cp /etc/turnserver.conf ${CurrentDIR}/backups/${DATETIME}_turnserver.conf
    fi

    if [ -f ${MatrixSynapseFolder}/homeserver.yaml ]; then
        cp ${MatrixSynapseFolder}/homeserver.yaml ${CurrentDIR}/backups/${DATETIME}_homeserver.yaml
    else
        echo -e " \e[33m This is a critical warning, you may did not set Matrix install path correctly!!!! \e[0m "
    fi

    # load the template file 
    logThis "Creating Coturn config with template" "INFO"

    sed -e "s;%LISTENING_IP%;${myLocalIP};g" -e  "s;%AUTHENTICATION_PASSCODE%;${CoturnPassCode};g" -e \
    "s;%DOMAIN%;${mydomain};g" ${CurrentDIR}/template/turnserver_template.conf > ${CurrentDIR}/turnserver.conf

    sudo cp ${CurrentDIR}/turnserver.conf /etc/
    sudo cp ${CurrentDIR}/template/coturn /etc/default/coturn

    sudo systemctl stop coturn
    sudo systemctl start coturn
    
    # change the config of the Matrix server
    cp ${MatrixSynapseFolder}/homeserver.yaml ${CurrentDIR}/homeserver_Initial.yaml
    #append the configuration to the end of the file
    sed '/###### Easycoturn Server configuration/,$d' ${CurrentDIR}/homeserver_Initial.yaml > ${CurrentDIR}/homeserver.yaml 

    echo "" >> ${CurrentDIR}/homeserver.yaml
    echo "###### Easycoturn Server configuration" >> ${CurrentDIR}/homeserver.yaml
    echo "###### Those are key Lines DO NOT CHANGE!!!" >> ${CurrentDIR}/homeserver.yaml
    echo "turn_uris: [ \"turn:${mydomain}:3478?transport=tcp\" , \"turn:${mydomain}:3478?transport=udp\" ]" >> ${CurrentDIR}/homeserver.yaml
    echo "turn_shared_secret: \"${CoturnPassCode}\"" >> ${CurrentDIR}/homeserver.yaml
    echo "turn_user_lifetime: 86400000" >>  ${CurrentDIR}/homeserver.yaml
    echo "turn_allow_guests: True"  >>  ${CurrentDIR}/homeserver.yaml
    
    cp  ${CurrentDIR}/homeserver.yaml ${MatrixSynapseFolder}/homeserver.yaml
}

function restartSynapse () {
    cd ${MatrixSynapseFolder}
    source ./venv/bin/activate
    pythonVersion=$(python --version)
    pipVersion=$(pip --version)
    logThis " Matrix Synapse Env: ${pythonVersion} with ${pipVersion} " "INFO"
    synctl stop
    synctl start
}

function Header () {
    echo 
}
function trailer () {
    echo 
}

function main () {
    fireWallConfig
    sudo apt-get update -y
    LoadConfig
    ReadSysInfor
    autoTestMatrix
    PasswordGenerator 50

    preCheck
    coturnInstaller
    coturnConfig

    # restartSynapse

}

main