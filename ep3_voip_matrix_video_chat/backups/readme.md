# Backups folder

Back up all the initial configurations before make any change.



## Coturn backup file 

The code will automatically check whether the following file exist or not. If exist, the script will copy it in this directory.
```
/etc/turnserver.conf
```

The back up file will be saved as the following format:

```
+%Y-%m-%d_%H_%M_%S_turnserver.conf
```

If you want to restore the previous setting, just copy the back up to :

```
sudo cp +%Y-%m-%d_%H_%M_%S_turnserver.conf /etc/turnserver.conf
```


## Synapse server back up 

The code will automatically check whether the following file exist or not. If exist, the script will copy it in this directory.
```
${MatrixInstallDir}/homeserver.yaml
```

The back up file will be saved as the following format:

```
+%Y-%m-%d_%H_%M_%S_homeserver.yaml
```

If you want to restore the previous setting, just copy the back up to :

```
cp +%Y-%m-%d_%H_%M_%S_homeserver.yaml ${MatrixInstallDir}/homeserver.yaml
```

And then restart your synapse server with the following command:

```
synctl restart
```