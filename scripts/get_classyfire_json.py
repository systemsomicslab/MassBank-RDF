import pandas as pd
import requests
import json

df = pd.read_csv("inchikey4accession.csv")

for i in df["InChIKey"].unique():
  if isinstance(i, str):
    #r = requests.get('http://classyfire.wishartlab.com/entities/' + i + '.json')
    r = requests.get('https://cfb.fiehnlab.ucdavis.edu/entities/' + i)
    if i == r.json()['_id']:
      with open(i + '.json', 'w') as f:
        print(json.dumps(r.json(), indent=4), file=f)
  else:
    print(i)
