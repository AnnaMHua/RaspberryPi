# Easy Coturn
![matrix](https://matrix.org/)

Bash script used install, set up coturn for the Matrix Synapse.


# Usage 

## pre-install 

### Step 1. Install Matrix Synapse

 If you have already installed it with the last episode script, you can ignore this step.

Need to install matrix and setup the matrix first before using this script. Later will merge those two script together and add GUI support.

More about how to setup Matrix, you can refer to [link](../ep2_IMServer/readme.md)

[![](http://img.youtube.com/vi/_3i5tZ3SxSs/0.jpg)](https://www.youtube.com/watch?v=_3i5tZ3SxSs "")


### Step 2. edit the [config file](./config.cfg)


```
# check load the correct 
bashname=Easycoturn.sh # Donot change

# Your own domain
# required
myDomain=example.com  ## change to your domain 

#Using Existing Matrix Server 
UsingExistingSynapseServer=true  ## currently unused

# Matrix installation path /home/pi/RaspberryPi/ep2_IMServer/Matrix/synapse
# where is the synapse installed, it looking for the venv and homeserver.yaml file
MatrixInstallDir=../ep2_IMServer/Matrix/synapse    

```

## Install and config 

As always, this is the most easiest step for us since we have the script to deal with the trivial steps.  One command installation:

```
bash ./Easycoturn.sh
```

In the script it will finish the following steps:

* Searching for the local IP
* Read config and get the Matrix install path
* Check the Matrix installation were successfull
* Generate passcode 
* install coturn
* backup the inital configure files 
  * more information [readme](./backups/readme.md)
* set up coturn 
  * /etc/turnserver.conf
  * /etc/default/coturn
* restart the coturn service 
* search for matrix folder edit homeserver.yaml 
  * homeserver.yaml
* firewall 
  * allow 5349
  * allow 3478    
  * allow 49152:65535/udp

## post install (Optional)

As you may have noticed, if your raspberry Pi is working behind a/several router, you have to properly forward the port to your raspberry Pi.

Port need Matrix :

```
443
```

Port Needed by coturn:

```
3478
5349
49152-65535
```

