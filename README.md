# MassBank-RDF

## Installing Qlever RDF engine + loading MassBank-RDF ttl file

```
# install qlever
pip install qlever
# check qlever command
qlever
# enable bash completion
eval "$(register-python-argcomplete qlever)" && export QLEVER_ARGCOMPLETE_ENABLED=1 #
# create working directory for QLever
mkdir test
cd test
wget https://github.com/systemsomicslab/MassBank-RDF/raw/main/Qleverfile
wget DOWNLOAD_YOUR_TTLFILES.ttl
qlever index
qlever start
qlever ui
```

## If you want to start new QLever service
```
mkdir test2
cd test2
wget https://github.com/systemsomicslab/MassBank-RDF/raw/main/Qleverfile
wget DOWNLOAD_YOUR_TTLFILES.ttl
qlever index
qlever start --kill-existing-with-same-port
qlever ui
```
