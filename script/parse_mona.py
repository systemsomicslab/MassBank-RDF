# wget https://mona.fiehnlab.ucdavis.edu/rest/downloads/retrieve/19a23fd5-4e06-4122-ae9d-169198ee9794
# mv 19a23fd5-4e06-4122-ae9d-169198ee9794 mona_exp.zip
# unzip mona_exp.zip

import json

f = open('MoNA-export-Experimental_Spectra.json')
data = json.load(f)
with open("data3.json", 'w') as j:
    json.dump(data[3], j, indent=4)
  
