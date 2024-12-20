library(Spectra)
library(MsBackendMassbank)
fls = dir("/home/kozo2/MassBank-data-2024.11/CASMI_2016")
fls = paste0("/home/kozo2/MassBank-data-2024.11/CASMI_2016/", fls)
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

  analytical_s = paste0("massbank:", row$accession, "#AnalyticalConditions")
  write(paste(analytical_s, "rdf:type", "mbo:analytical_methods_and_conditions", "."), ttl_filepath, append = TRUE)
  write(paste(analytical_s, "mbo:ac_instrument", enclose_in_quotes(row$instrument), "."), ttl_filepath, append = TRUE)
  write(paste(analytical_s, "mbo:instrument_type", enclose_in_quotes(row$instrument_type), "."), ttl_filepath, append = TRUE)
  write(paste(analytical_s, "mbo:ms_type", enclose_in_quotes(row$ms_ms_type), "."), ttl_filepath, append = TRUE)
  if (row$polarity == 0) {
    write(paste(analytical_s, "mbo:ion_mode", enclose_in_quotes("NEGATIVE"), "."), ttl_filepath, append = TRUE)
  }
  if (row$polarity == 1) {
    write(paste(analytical_s, "mbo:ion_mode", enclose_in_quotes("POSITIVE"), "."), ttl_filepath, append = TRUE)
  }
  write(paste(analytical_s, "mbo:ac_ionization", enclose_in_quotes(row$ms_ionization), "."), ttl_filepath, append = TRUE)
  if (is.na(row$ms_frag_mode) == FALSE){
    write(paste(analytical_s, "mbo:fragmentation_mode", enclose_in_quotes(row$ms_frag_mode), "."), ttl_filepath, append = TRUE)
  }
  write(paste(analytical_s, "mbo:collision_energy", enclose_in_quotes(row$collisionEnergy), "."), ttl_filepath, append = TRUE)
  write(paste(analytical_s, "mbo:resolution", enclose_in_quotes(row$ms_resolution), "."), ttl_filepath, append = TRUE)
  write(paste(analytical_s, "mbo:column_name", enclose_in_quotes(row$chrom_column), "."), ttl_filepath, append = TRUE)
  write(paste(analytical_s, "mbo:flow_gradient", enclose_in_quotes(row$chrom_flow_gradient), "."), ttl_filepath, append = TRUE)
  write(paste(analytical_s, "mbo:flow_rate", enclose_in_quotes(row$chrom_flow_rate), "."), ttl_filepath, append = TRUE)
  write(paste(analytical_s, "mbo:retention_time", enclose_in_quotes(row$rtime), "."), ttl_filepath, append = TRUE)
  for (i in row$chrom_solvent){
    write(paste(analytical_s, "mbo:solvent", enclose_in_quotes(i), "."), ttl_filepath, append = TRUE)
  }

  spectrum_s = paste0("massbank:", row$accession, "#MassSpectra")
  write(paste(spectrum_s, "rdf:type", "mbo:mass_spectral_data", "."), ttl_filepath, append = TRUE)
  write(paste(spectrum_s, "mbo:precursor_mz", enclose_in_xsddouble(row$precursorMz), "."), ttl_filepath, append = TRUE)
  write(paste(spectrum_s, "mbo:precursor_type", enclose_in_xsddouble(row$adduct), "."), ttl_filepath, append = TRUE)
  for (i in row$comment){
    write(paste(spectrum_s, "rdfs:comment", enclose_in_quotes(i), "."), ttl_filepath, append = TRUE)
  }

  peakinfo_s = paste0("massbank:", row$accession, "#PeakInfo")
  write(paste(peakinfo_s, "rdf:type", "mbo:peak_information", "."), ttl_filepath, append = TRUE)
  write(paste(peakinfo_s, "mbo:pk_splash", paste0("splash:", row$splash), "."), ttl_filepath, append = TRUE)
  write(paste(peakinfo_s, "mbo:pk_num_peak", enclose_in_xsddouble(row$pknum), "."), ttl_filepath, append = TRUE)
}
