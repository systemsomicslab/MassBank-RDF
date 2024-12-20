library(Spectra)
library(MsBackendMassbank)
fls = dir("/home/kozo2/MassBank-data-2024.11/IPB_Halle")
fls = paste0("/home/kozo2/MassBank-data-2024.11/IPB_Halle/", fls)
metaDataBlocks <- data.frame(metadata = c("ac", "ch", "sp", "ms",
                                          "record", "pk", "comment"),
                             read = rep(TRUE, 7))
sps <- Spectra(fls,
               source = MsBackendMassbank(),
               backeend = MsBackendDataFrame(),
               metaBlock = metaDataBlocks)
clmns = spectraVariables(dropNaSpectraVariables(sps))
sd = spectraData(sps, columns = clmns)

enclose_in_quotes <- function(x) {
  return(paste0('"', x, '"'))
}
enclose_in_xsddate <- function(x) {
  return(paste0('"', x, '"^^xsd:date'))
}
enclose_in_xsddouble <- function(x) {
  return(paste0('"', x, '"^^xsd:double'))
}

for (i in 1:dim(sd)[1]){
  row = sd[i,]
  ttl_filepath = gsub(".txt", ".ttl", row$dataOrigin)

  dataset_s = paste0("massbank:", row$accession, "#Dataset")
  writeLines(paste(dataset_s, "rdf:type", "schema:Dataset", "."), ttl_filepath)
  identifier = paste0('massbank:', row$accession)
  write(paste(dataset_s, "dcterms:identifier", identifier, "."), ttl_filepath, append = TRUE)
  write(paste(dataset_s, "skos:definition", enclose_in_quotes(row$title), "."), ttl_filepath, append = TRUE)
  write(paste(dataset_s, "dcterms:date", enclose_in_xsddate(row$date), "."), ttl_filepath, append = TRUE)
  write(paste(dataset_s, "dcterms:creator", enclose_in_quotes(row$authors), "."), ttl_filepath, append = TRUE)
  write(paste(dataset_s, "dcterms:license", enclose_in_quotes(row$license), "."), ttl_filepath, append = TRUE)
  if (is.na(row$copyright) == FALSE){
    write(paste(dataset_s, "dcterms:rights", enclose_in_quotes(row$copyright), "."), ttl_filepath, append = TRUE)
  }
  for (i in strsplit(row$comment$comment, "                 ")){
    write(paste(dataset_s, "rdfs:comment", enclose_in_quotes(i), "."), ttl_filepath, append = TRUE)
    }

  chemical_s = paste0("massbank:", row$accession, "#ChemicalSubstance")
  write(paste(chemical_s, "rdf:type", "schema:chemicalsubstance", "."), ttl_filepath, append = TRUE)
  write(paste(chemical_s, "schema:url", identifier, "."), ttl_filepath, append = TRUE)
  write(paste(chemical_s, "dcterms:identifier", identifier, "."), ttl_filepath, append = TRUE)
  write(paste(chemical_s, "schema:name", enclose_in_quotes(row$name$name[[1]]), "."), ttl_filepath, append = TRUE)
  if (length(row$name$name) > 1){
    write(paste(chemical_s, "schema:alternateName", enclose_in_quotes(row$name$name[[2]]), "."), ttl_filepath, append = TRUE)
  }
  write(paste(chemical_s, "schema:molecularFormula", enclose_in_quotes(row$formula), "."), ttl_filepath, append = TRUE)
  write(paste(chemical_s, "schema:monoisotopicMolecularWeight", enclose_in_xsddouble(row$exactmass), "."), ttl_filepath, append = TRUE)
  write(paste(chemical_s, "schema:smiles", enclose_in_quotes(row$smiles), "."), ttl_filepath, append = TRUE)
  write(paste(chemical_s, "schema:inChI", paste0("inchi:", row$inchi), "."), ttl_filepath, append = TRUE)
  write(paste(chemical_s, "schema:inChIKey", paste0("inchikey:", row$inchikey), "."), ttl_filepath, append = TRUE)

  if (is.na(row$link_pubchem) == FALSE){
    write(paste(chemical_s, "rdfs:seeAlso", paste0("pubchem:", gsub("CID:", "", row$link_pubchem)), "."), ttl_filepath, append = TRUE)
  }
  if (is.na(row$link_kegg) == FALSE){
    write(paste(chemical_s, "rdfs:seeAlso", paste0("kegg:", row$link_kegg), "."), ttl_filepath, append = TRUE)
  }
  if (is.na(row$link_comptox) == FALSE){
    write(paste(chemical_s, "rdfs:seeAlso", paste0("comptox:", row$link_comptox), "."), ttl_filepath, append = TRUE)
  }
}
