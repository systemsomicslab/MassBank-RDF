# Download MassBank_NIST.msp from
# https://github.com/MassBank/MassBank-data/releases/download/2023.11/MassBank_NIST.msp

library(MsBackendMsp)

sp = Spectra("MassBank_NIST.msp", source = MsBackendMsp())
acs = sp$accession
inchikeys = sp$InChIKey

df = data.frame(accession = acs, InChIKey = inchikeys)
write.csv(df, file = "inchikey4accession.csv", row.names = FALSE)
