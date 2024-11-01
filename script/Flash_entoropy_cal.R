#' Implementation of Flash Entropy Search
#' 
#' @param query_spectrum Data frame (columns: mz, intensity)
#' @param library_spectra List of lists (each element: data frame of mz and intensity)
#' @param tolerance m/z tolerance (default: 20e-6)
#' @return Vector of similarity scores

# Helper function: Calculation of entropy contribution
entropy_contribution <- function(x) {
  if (x <= 0) return(0)
  return(x * log2(x))
}

# Spectrum preprocessing
preprocess_spectrum <- function(spectrum) {
  # Removal of precursor ions and noise filtering are omitted
  
  # Normalization of intensity (sum to 0.5)
  total_intensity <- sum(spectrum$intensity)
  spectrum$intensity <- spectrum$intensity / (2 * total_intensity)
  
  # Sort by m/z
  spectrum <- spectrum[order(spectrum$mz), ]
  
  return(spectrum)
}

# Create library spectrum index
create_library_index <- function(library_spectra) {
  # Preprocess each spectrum
  library_index <- lapply(seq_along(library_spectra), function(spec_id) {
    spectrum <- preprocess_spectrum(library_spectra[[spec_id]])
    data.frame(
      spec_id = spec_id,
      mz = spectrum$mz,
      intensity = spectrum$intensity
    )
  })
  
  # Combine all ions and sort by m/z
  library_index <- do.call(rbind, library_index)
  library_index <- library_index[order(library_index$mz), ]
  
  return(library_index)
}

# Search for matching ions
find_matching_ions <- function(ion_table, query_mz, tolerance) {
  # Search for ions within the tolerance range
  matches <- ion_table[abs(ion_table$mz - query_mz) <= tolerance, ]
  return(matches)
}

# Calculation of Flash Entropy similarity
flash_entropy_search <- function(query_spectrum, library_spectra, tolerance = 0.001) {
  # Preprocess the query spectrum
  query_spectrum <- preprocess_spectrum(query_spectrum)
  
  # Create the library index
  library_index <- create_library_index(library_spectra)
  
  # Array to store similarity for each spectrum
  n_library <- length(library_spectra)
  similarities <- numeric(n_library)
  
  # For each ion in the query spectrum
  for (i in 1:nrow(query_spectrum)) {
    query_mz <- query_spectrum$mz[i]
    query_intensity <- query_spectrum$intensity[i]
    
    # Search for matching ions
    matches <- find_matching_ions(library_index, query_mz, tolerance)
    
    if (nrow(matches) > 0) {
      # Calculate similarity for each matching ion
      for (j in 1:nrow(matches)) {
        spec_id <- matches$spec_id[j]
        lib_intensity <- matches$intensity[j]
        
        # Calculate entropy contribution
        contribution <- entropy_contribution(query_intensity + lib_intensity) - 
          entropy_contribution(query_intensity) - 
          entropy_contribution(lib_intensity)
        
        similarities[spec_id] <- similarities[spec_id] + contribution
      }
    }
  }
  
  return(similarities)
}

# Example usage
# Create test data
# test_query <- data.frame(
#   mz = c(100, 200, 300),
#   intensity = c(1000, 500, 100)
# )
# test_library <- list(
#   data.frame(mz = c(100, 200, 300), intensity = c(1000, 500, 100)),
#   data.frame(mz = c(100, 201, 300), intensity = c(900, 600, 150)),
#   data.frame(mz = c(150, 250, 350), intensity = c(800, 400, 200))
# )
# Execute the search
#results <- flash_entropy_search(test_query, test_library)
#print(results)



