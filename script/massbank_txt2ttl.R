library(stringr)
library(dplyr)

# Function to read MassBank text file and parse into a list
read_massbank <- function(file_path) {
  # Read the file
  lines <- readLines(file_path)
  
  # Initialize variables
  current_section <- NULL
  data <- list()
  
  # Process each line
  for (line in lines) {
    if (line == "//") next
    
    # Split line into key and value
    parts <- str_split(line, ": ", n = 2)[[1]]
    if (length(parts) == 2) {
      key <- parts[1]
      value <- parts[2]
      
      # Extract section and subsection from key
      if (str_detect(key, "^AC\\$")) {
        if (is.null(data$analytical_conditions)) data$analytical_conditions <- list()
        section <- str_match(key, "^AC\\$([^:]+)")[2]
        if (!is.null(section)) {
          if (is.null(data$analytical_conditions[[section]])) {
            data$analytical_conditions[[section]] <- value
          } else {
            if (is.character(data$analytical_conditions[[section]])) {
              data$analytical_conditions[[section]] <- c(data$analytical_conditions[[section]], value)
            } else {
              data$analytical_conditions[[section]] <- c(data$analytical_conditions[[section]], value)
            }
          }
        }
      } else if (str_detect(key, "^MS\\$FOCUSED_ION:")) {
        if (is.null(data$focused_ion)) data$focused_ion <- list()
        sub_key <- str_replace(key, "^MS\\$FOCUSED_ION: ", "")
        if (is.null(data$focused_ion[[sub_key]])) {
          data$focused_ion[[sub_key]] <- value
        } else {
          if (is.character(data$focused_ion[[sub_key]])) {
            data$focused_ion[[sub_key]] <- c(data$focused_ion[[sub_key]], value)
          } else {
            data$focused_ion[[sub_key]] <- c(data$focused_ion[[sub_key]], value)
          }
        }
      } else if (str_detect(key, "^MS\\$")) {
        if (is.null(data$mass_spectra)) data$mass_spectra <- list()
        section <- str_match(key, "^MS\\$([^:]+)")[2]
        if (!is.null(section)) {
          if (is.null(data$mass_spectra[[section]])) {
            data$mass_spectra[[section]] <- value
          } else {
            if (is.character(data$mass_spectra[[section]])) {
              data$mass_spectra[[section]] <- c(data$mass_spectra[[section]], value)
            } else {
              data$mass_spectra[[section]] <- c(data$mass_spectra[[section]], value)
            }
          }
        }
      } else if (str_detect(key, "^PK\\$")) {
        if (is.null(data$peak_info)) data$peak_info <- list()
        section <- str_match(key, "^PK\\$([^:]+)")[2]
        if (!is.null(section)) {
          if (is.null(data$peak_info[[section]])) {
            data$peak_info[[section]] <- value
          } else {
            if (is.character(data$peak_info[[section]])) {
              data$peak_info[[section]] <- c(data$peak_info[[section]], value)
            } else {
              data$peak_info[[section]] <- c(data$peak_info[[section]], value)
            }
          }
        }
      } else if (str_detect(key, "^CH\\$")) {
        if (is.null(data$chemical_info)) data$chemical_info <- list()
        if (str_detect(key, "^CH\\$LINK:")) {
          link_type <- str_replace(key, "^CH\\$LINK: ", "")
          if (is.null(data$chemical_info$LINK)) data$chemical_info$LINK <- list()
          data$chemical_info$LINK[[link_type]] <- value
        } else {
          section <- str_replace(key, "^CH\\$", "")
          if (is.null(data$chemical_info[[section]])) {
            data$chemical_info[[section]] <- value
          } else {
            if (is.character(data$chemical_info[[section]])) {
              data$chemical_info[[section]] <- c(data$chemical_info[[section]], value)
            } else {
              data$chemical_info[[section]] <- c(data$chemical_info[[section]], value)
            }
          }
        }
      } else {
        # For handling multiple values with same key (like COMMENT)
        if (key %in% names(data)) {
          if (is.character(data[[key]])) {
            data[[key]] <- c(data[[key]], value)
          } else {
            data[[key]] <- c(data[[key]], value)
          }
        } else {
          data[[key]] <- value
        }
      }
    }
  }
  
  return(data)
}


# Function to generate RDF/Turtle content
generate_turtle <- function(massbank_data, accession) {
  # Define prefixes
  prefixes <- c(
    "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .",
    "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .",
    "@prefix schema: <http://schema.org/> .",
    "@prefix dcterms: <http://purl.org/dc/terms/> .",
    "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .",
    "@prefix skos: <http://www.w3.org/2004/02/skos/core#> .",
    "@prefix massbank: <https://identifiers.org/massbank/> .",
    "@prefix cas: <https://identifiers.org/cas/> .",
    "@prefix chebi: <https://identifiers.org/CHEBI/> .",
    "@prefix kegg: <https://identifiers.org/kegg.compound/> .",
    "@prefix pubchem: <https://identifiers.org/pubchem.compound/> .",
    "@prefix inchi: <https://identifiers.org/inchi/> .",
    "@prefix inchikey: <https://identifiers.org/inchikey/> .",
    "@prefix chemspider: <https://identifiers.org/chemspider/> .",
    "@prefix comptox: <https://identifiers.org/comptox/> .",
    "@prefix obo: <http://purl.obolibrary.org/obo/> .",
    "@prefix splash: <https://identifiers.org/splash/> .",
    ""
  )
  
  # Generate Dataset triples
  dataset_triples <- c(
    sprintf("massbank:%s#Dataset rdf:type schema:Dataset .", accession),
    sprintf('massbank:%s#Dataset dcterms:identifier "%s" .', accession, accession),
    sprintf('massbank:%s#Dataset skos:definition "%s" .', accession, massbank_data$RECORD_TITLE),
    sprintf('massbank:%s#Dataset dcterms:date "%s"^^xsd:date .', accession, as.Date(massbank_data$DATE, format =  "%Y-%m-%d")),
    sprintf('massbank:%s#Dataset dcterms:creator "%s" .', accession, massbank_data$AUTHORS),
    sprintf('massbank:%s#Dataset dcterms:license <https://creativecommons.org/licenses/by/4.0/> .', accession),
    sprintf('massbank:%s#Dataset dcterms:rights "%s" .', accession, massbank_data$COPYRIGHT),
    sprintf('massbank:%s#Dataset schema:citation "%s" .', accession, massbank_data$PUBLICATION)
  )
  
  # Add COMMENT entries if they exist
  if (!is.null(massbank_data$COMMENT)) {
    for (comment in massbank_data$COMMENT) {
      dataset_triples <- c(dataset_triples,
                           sprintf('massbank:%s#Dataset rdfs:comment "%s" .', accession, comment))
    }
  }
  
  # Generate ChemicalSubstance triples
  chemical_triples <- c(
    sprintf("massbank:%s#ChemicalSubstance rdf:type schema:ChemicalSubstance .", accession),
    sprintf("massbank:%s#ChemicalSubstance schema:url massbank:%s .", accession, accession),
    sprintf('massbank:%s#ChemicalSubstance dcterms:identifier "%s" .', accession, accession)
  )
  
  # Add chemical names
  if (!is.null(massbank_data$chemical_info$NAME)) {
    # Add primary name
    chemical_triples <- c(chemical_triples,
                          sprintf('massbank:%s#ChemicalSubstance schema:name "%s" .', 
                                  accession, massbank_data$chemical_info$NAME[1]))
    
    # Add alternate names if available
    if (length(massbank_data$chemical_info$NAME) > 1) {
      for (alt_name in massbank_data$chemical_info$NAME[-1]) {
        chemical_triples <- c(chemical_triples,
                              sprintf('massbank:%s#ChemicalSubstance schema:alternateName "%s" .', 
                                      accession, alt_name))
      }
    }
  }
  
  # Add chemical formula
  if (!is.null(massbank_data$chemical_info$FORMULA)) {
    chemical_triples <- c(chemical_triples,
                          sprintf('massbank:%s#ChemicalSubstance schema:molecularFormula "%s" .', 
                                  accession, massbank_data$chemical_info$FORMULA))
  }
  
  # Add molecular weight
  if (!is.null(massbank_data$chemical_info$EXACT_MASS)) {
    chemical_triples <- c(chemical_triples,
                          sprintf('massbank:%s#ChemicalSubstance schema:monoisotopicMolecularWeight "%s"^^xsd:double .', 
                                  accession, massbank_data$chemical_info$EXACT_MASS))
  }
  
  # Add SMILES
  if (!is.null(massbank_data$chemical_info$SMILES)) {
    chemical_triples <- c(chemical_triples,
                          sprintf('massbank:%s#ChemicalSubstance schema:smiles "%s" .', 
                                  accession, massbank_data$chemical_info$SMILES))
  }
  
  # Add InChI
  if (!is.null(massbank_data$chemical_info$IUPAC)) {
    chemical_triples <- c(chemical_triples,
                          sprintf('massbank:%s#ChemicalSubstance schema:inChI inchi:%s .', 
                                  accession, massbank_data$chemical_info$IUPAC))
  }
  
  # Handle InChIKey separately
  if (!is.null(massbank_data$chemical_info$LINK[startsWith(massbank_data$chemical_info$LINK, "INCHIKEY")])) {
    Inchi <- massbank_data$chemical_info$LINK[startsWith(massbank_data$chemical_info$LINK, "INCHIKEY")] %>% sub("^.*?\\s", "", .)
    chemical_triples <- c(chemical_triples,
                          sprintf('massbank:%s#ChemicalSubstance schema:inChIKey inchikey:%s .', 
                                  accession, Inchi))
  }
  
  # Process other CH$LINK entries for seeAlso references
  link_mappings <- list(
    "CAS" = "cas",
    "CHEBI" = "chebi",
    "KEGG" = "kegg",
    "PUBCHEM" = "pubchem",
    "CHEMSPIDER" = "chemspider",
    "COMPTOX" = "comptox"
  )
  
  for (key in massbank_data$chemical_info$LINK) {
    if (any(startsWith(key, names(link_mappings)))) {
        header <- sub("^(\\S+).*", "\\1", key)
      # link_type <- substr(key, 9, nchar(key))  # Remove "CH$LINK: " prefix
      # if (key %in% names(link_mappings)) {
        prefix <- link_mappings[[header]]
        value <- key %>% sub("^.*?\\s", "", .)
        chemical_triples <- c(chemical_triples,
                              sprintf('massbank:%s#ChemicalSubstance rdfs:seeAlso %s:%s .',
                                      accession,prefix,value))
      }
    # }
  }
  
  # Generate analytical conditions triples
  analytical_triples <- c()
  
  if (!is.null(massbank_data$analytical_conditions$INSTRUMENT)) {
    for (value in massbank_data$analytical_conditions$INSTRUMENT) {
      analytical_triples <- c(analytical_triples,
                              sprintf('massbank:%s#AnalyticalConditions obo:MS_1000031 "%s" .', accession, value))
    }
  }
  
  if (!is.null(massbank_data$analytical_conditions$INSTRUMENT_TYPE)) {
    for (value in massbank_data$analytical_conditions$INSTRUMENT_TYPE) {
      analytical_triples <- c(analytical_triples,
                              sprintf('massbank:%s#AnalyticalConditions obo:CHMO_0000751 "%s" .', accession, value))
    }
  }
  # Process MASS_SPECTROMETRY section
  if (!is.null(massbank_data$analytical_conditions$MASS_SPECTROMETRY)) {
    for (value in massbank_data$analytical_conditions$MASS_SPECTROMETRY) {
      analytical_triples <- c(analytical_triples,
                              sprintf('massbank:%s#AnalyticalConditions obo:MS_1001458 "%s" .', accession, value))
    }
  }
  
  # Process CHROMATOGRAPHY section
  if (!is.null(massbank_data$analytical_conditions$CHROMATOGRAPHY)) {
    for (value in massbank_data$analytical_conditions$CHROMATOGRAPHY) {
      analytical_triples <- c(analytical_triples,
                              sprintf('massbank:%s#AnalyticalConditions obo:CHMO_0001000 "%s" .', accession, value))
    }
  }
  
  
  # Generate mass spectra triples
  mass_spectra_triples <- c()
  
  
  # Add focused ion information
  # if (!is.null(massbank_data$mass_spectra$FOCUSED_ION)) {
    focused_ion_fields <- list(
      "BASE_PEAK" = "BASE_PEAK %s",
      "PRECURSOR_M/Z" = "PRECURSOR_M/Z %s",
      "PRECURSOR_TYPE" = "PRECURSOR_TYPE %s"
    )
    
    for (field in names(focused_ion_fields)) {
      if (any(!is.null(massbank_data$mass_spectra$FOCUSED_ION[startsWith(massbank_data$mass_spectra$FOCUSED_ION, names(focused_ion_fields))]))) { 
        # value <- massbank_data$chemical_info$LINK[startsWith(massbank_data$chemical_info$LINK, field)]
        mass_spectra_triples <- c(mass_spectra_triples,
                                  sprintf('massbank:%s#MassSpectra obo:MS_1000499 "%s" .', 
                                          accession,  massbank_data$mass_spectra$FOCUSED_ION[startsWith(massbank_data$mass_spectra$FOCUSED_ION, field)]))
      }
    }
  # }
  
  # Add DATA_PROCESSING information
  if (!is.null(massbank_data$mass_spectra$DATA_PROCESSING)) {
    for (value in massbank_data$mass_spectra$DATA_PROCESSING) {
      mass_spectra_triples <- c(mass_spectra_triples,
                                sprintf('massbank:%s#MassSpectra obo:MS_1001458 "%s" .', accession, value))
    }
  }
  
  # Generate peak info triples
  peak_info_triples <- c()
  if (!is.null(massbank_data$peak_info$SPLASH)) {
    peak_info_triples <- c(peak_info_triples,
                           sprintf('massbank:%s#PeakInfo obo:MS_1002599 splash:%s .', 
                                   accession, massbank_data$peak_info$SPLASH))
  }
  
  # Add PK$ANNOTATION if available
  if (!is.null(massbank_data$peak_info$ANNOTATION)) {
    peak_info_triples <- c(peak_info_triples,
                           sprintf('massbank:%s#PeakInfo obo:MS_1003271 "%s" .', 
                                   accession, massbank_data$peak_info$ANNOTATION))
  }
  
  # Add number of peaks
  if (!is.null(massbank_data$peak_info$NUM_PEAK)) {
    peak_info_triples <- c(peak_info_triples,
                           sprintf('massbank:%s#PeakInfo obo:MS_1003059 "%s"^^xsd:int .', 
                                   accession, massbank_data$peak_info$NUM_PEAK))
  }
  
  # Add peak data
  if (!is.null(massbank_data$peak_info$PEAK)) {
    peak_info_triples <- c(peak_info_triples,
                           sprintf('massbank:%s#PeakInfo obo:MS_1003058 "%s" .', 
                                   accession, massbank_data$peak_info$PEAK))
  }

  # Combine all triples with blank lines between sections
  all_content <- c(
    prefixes,
    "",
    dataset_triples,
    "",
    chemical_triples,
    "",
    analytical_triples,
    "",
    mass_spectra_triples,
    "",
    peak_info_triples
  )
  
  return(paste(all_content, collapse = "\n"))
}

# Main conversion function
convert_massbank_to_turtle <- function(input_file, output_file) {
  # Read MassBank data
  massbank_data <- read_massbank(input_file)
  
  # Extract accession from the input filename
  accession <- str_extract(basename(input_file), "^[^.]+")
  
  # Generate Turtle content
  turtle_content <- generate_turtle(massbank_data, accession)
  
  # Write to output file
  writeLines(turtle_content, output_file)
  
  cat("Conversion completed successfully!\n")
}
# Example usage:
# convert_massbank_to_turtle("MSBNK-CASMI_2016-SM828451.txt", "MSBNK-CASMI_2016-SM828451.ttl")
convert_massbank_to_turtle("D:/project_massbank/IPB-Halle/MSBNK-CASMI_2016-SM828451.txt", "D:/project_massbank/MSBNK-CASMI_2016-SM828451.ttl")
