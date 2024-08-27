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

## How to send a SPARQL query from Jupyter to QLever

### Install the Python packages
```
pip install jupyterlab
pip install sparqlwrapper
```

### Running JupyterLab
```
jupyter-lab
```

### Jupyter cell example
```
from SPARQLWrapper import SPARQLWrapper, JSON
URL4SPARQLENDPIOINT = "YOUR_QLEVER_SPARQL_ENDPOINT"
sparql = SPARQLWrapper(URL4SPARQLENDPIOINT)
sparql.setQuery(query)
sparql.setReturnFormat(JSON)
results = sparql.query().convert()
for result in results["results"]["bindings"]:
    print(result)
```

### How to check QLever SPARQL endpoint URL

1. Click `Backend Information` in your QLever UI.
2. Check the red box in the attached image. ![image](https://github.com/user-attachments/assets/82c1b5df-c1a3-4801-b422-305259d8eb26)

