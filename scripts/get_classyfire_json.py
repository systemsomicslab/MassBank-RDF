import pandas as pd
import requests

df = pd.read_csv("inchikey4accession.csv")

for i in df["InChIKey"].unique():
  if isinstance(i, str):
    r = requests.get('http://classyfire.wishartlab.com/entities/' + i + '.json')  
    with open(i + '.json', 'w') as f:
      print(json.dumps(parsed, indent=4), file=f)
  else:
    print(i)
    
