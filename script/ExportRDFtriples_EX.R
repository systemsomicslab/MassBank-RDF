# Creating EX instance
library(stringr)
library(rdflib)
library(dplyr)
library(infun)
library(RMassBank)
namespace <- c(sio = "http://semanticscience.org/resource/", 
               mb = "https://registry.identifiers.org/registry/massbank",
               co = "http://classyfire.wishartlab.com/tax_nodes",
               mbo = "http://www.massbank.jp/ontology/",
               obo = "http://purl.obolibrary.org/obo/" 
               )

generate_rdf_EX <- function(folder_path,folder) {
  rdfdata <- rdf()
setwd(folder_path)
data_list <- list.files()
data_list <- data_list
  entries <- parseMassBank(data_list)
  for (i in 1:length(data_list)) {
    data <- entries@compiled_ok[[i]]
    accession <- paste("https://registry.identifiers.org/registry/massbank",data$ACCESSION,"_EX",sep = "")
    rdf_add(rdfdata, accession, "http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "http://semanticscience.org/resource/SIO_001180")
    rdf_add(rdfdata, accession, predicate="http://semanticscience.org/resource/SIO_000230", paste0("https://registry.identifiers.org/registry/massbank", data$ACCESSION, "_CM"), objectType ="uri")
    rdf_add(rdfdata, accession, "http://semanticscience.org/resource/SIO_000229", paste0("https://registry.identifiers.org/registry/massbank", data$ACCESSION, "_SP"))
    rdf_add(rdfdata, accession, "http://semanticscience.org/resource/SIO_000552", paste0("https://registry.identifiers.org/registry/massbank", data$ACCESSION, "_PR"), objectType ="uri")
    rdf_add(rdfdata, accession, "http://semanticscience.org/resource/SIO_000066", paste0("https://registry.identifiers.org/registry/massbank", data$ACCESSION, "_SB"), objectType ="uri")

  }

   rdf_serialize(rdfdata, paste("output",folder,".ttl",sep=""), format = "turtle",namespace = namespace)
}

generate_rdf_EX("D:/Project_massbank/MassBank-data-main/MassBank-data-only/RIKEN_IMS","RIKEN_IMS")