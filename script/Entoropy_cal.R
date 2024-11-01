#' Entropy Similarity Search (Traditional Method)
#' 
#' @param query_spectrum Data frame (columns: mz, intensity)
#' @param library_spectra List of lists (each element: data frame of mz and intensity)
#' @param tolerance m/z tolerance (default: 20e-6)
#' @return Vector of similarity scores

# Calculation of entropy
calculate_entropy <- function(spectrum) {
  # Use only peaks with non-negative intensity
  valid_intensities <- spectrum$intensity[spectrum$intensity > 0]
  # Calculate entropy: -??(p * log2(p))
  entropy <- -sum(valid_intensities * log2(valid_intensities))
  return(entropy)
}

# Spectrum normalization
normalize_spectrum <- function(spectrum) {
  # Normalize intensity (sum to 1)
  total_intensity <- sum(spectrum$intensity)
  spectrum$intensity <- spectrum$intensity / total_intensity
  return(spectrum)
}

# Create mixed spectrum
create_mixed_spectrum <- function(spec_a, spec_b, tolerance = 20e-6) {
  # Get all unique m/z values
  all_mz <- sort(unique(c(spec_a$mz, spec_b$mz)))
  
  # Calculate mixed intensity for each m/z
  mixed_spectrum <- lapply(all_mz, function(mz) {
    # Search for peaks within the tolerance range
    matches_a <- abs(spec_a$mz - mz) <= tolerance * mz
    matches_b <- abs(spec_b$mz - mz) <= tolerance * mz
    
    # Get intensity of matching peaks (0 if no match)
    int_a <- if(any(matches_a)) spec_a$intensity[which.min(abs(spec_a$mz - mz))] else 0
    int_b <- if(any(matches_b)) spec_b$intensity[which.min(abs(spec_b$mz - mz))] else 0
    
    # Calculate mixed intensity (each contributes half)
    mixed_int <- (int_a/2) + (int_b/2)
    
    c(mz = mz, intensity = mixed_int)
  })
  
  # Convert to data frame
  mixed_df <- as.data.frame(do.call(rbind, mixed_spectrum))
  colnames(mixed_df) <- c("mz", "intensity")
  
  return(mixed_df)
}

# Calculation of entropy similarity
calculate_entropy_similarity <- function(spec_a, spec_b, tolerance = 20e-6) {
  # Calculate entropy for individual spectra (after normalization)
  spec_a_norm <- normalize_spectrum(spec_a)
  spec_b_norm <- normalize_spectrum(spec_b)
  
  S_a <- calculate_entropy(spec_a_norm)
  S_b <- calculate_entropy(spec_b_norm)
  
  # Create mixed spectrum (using original intensities) and calculate entropy
  mixed <- create_mixed_spectrum(spec_a, spec_b, tolerance)
  mixed_norm <- normalize_spectrum(mixed)
  S_ab <- calculate_entropy(mixed_norm)
  
  # Calculate similarity
  similarity <- 1 - (2 * S_ab - S_a - S_b) / 2
  
  return(similarity)
}

# Main function for library search
traditional_entropy_search <- function(query_spectrum, library_spectra, tolerance = 20e-6) {
  # Calculate similarity with each library spectrum
  similarities <- sapply(library_spectra, function(lib_spec) {
    calculate_entropy_similarity(query_spectrum, lib_spec, tolerance)
  })
  
  return(similarities)
}
