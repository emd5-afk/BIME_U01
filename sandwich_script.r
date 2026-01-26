
install.packages("lmtest")
install.packages("sandwich")
library("lmtest")
library("sandwich")

# Function to add observation counts to coeftest results
# ToDo: Erin Added, see if it works correctly
# ToDo: this may not be the correct place to add counts, maybe do in primary_data_collection_script.ipbyn
add_obs_counts <- function(coeftest_results, model_data) {
  # Convert coeftest to matrix first, then to data frame with proper column names
  results_matrix <- as.matrix(coeftest_results)
  results_df <- as.data.frame(results_matrix)
  
  # Ensure proper column names
  if (ncol(results_df) == 4) {
    colnames(results_df) <- c("Estimate", "Std. Error", "t value", "Pr(>|t|)")
  }
  
  var_names <- rownames(results_df)
  
  # Calculate counts for each variable
  counts <- sapply(var_names, function(var) {
    if (var == "(Intercept)") {
      return(nrow(model_data))
    }
    
    # Check if variable exists directly in data
    if (var %in% colnames(model_data)) {
      return(sum(!is.na(model_data[[var]])))
    }
    
    # For encoded categorical variables (e.g., race_2.0)
    # Extract base variable name and value
    parts <- strsplit(var, "_")[[1]]
    if (length(parts) >= 2) {
      base_var <- paste(parts[1:(length(parts)-1)], collapse="_")
      value_str <- parts[length(parts)]
      value <- suppressWarnings(as.numeric(value_str))
      
      if (base_var %in% colnames(model_data) && !is.na(value)) {
        return(sum(model_data[[base_var]] == value, na.rm=TRUE))
      }
    }
    
    return(NA)
  })
  
  results_df$Count <- counts
  return(results_df)
}



# Basic analysis model
basic_analysis_df = read.csv("/edata/obdw/sandwich_analysis_data/basic_analysis.csv")
basic_analysis_df <- subset(basic_analysis_df, select = -c(X))

model <- lm(log_wer ~ . - sentCoherenceSentBertCumulativeCentroid - wer, data=basic_analysis_df);
results_wer <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_wer_with_counts <- add_obs_counts(results_wer, basic_analysis_df)
# print(results_wer_with_counts)
write.csv(results_wer, "/edata/obdw/sandwich_analysis_data/basic_analysis_wer_coeftest.csv")

model <- lm(sentCoherenceSentBertCumulativeCentroid ~ . - wer - log_wer, data=basic_analysis_df);
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, basic_analysis_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/basic_analysis_coh_coeftest.csv")


# Basic+ analysis model
basic_plus_analysis_df = read.csv("/edata/obdw/sandwich_analysis_data/basic_plus_analysis.csv")
basic_plus_analysis_df <- subset(basic_plus_analysis_df, select = -c(X))

model <- lm(log_wer ~ . - sentCoherenceSentBertCumulativeCentroid - snr - wer, data=basic_plus_analysis_df);
results_wer <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_wer_with_counts <- add_obs_counts(results_wer, basic_plus_analysis_df)
# print(results_wer_with_counts)
write.csv(results_wer, "/edata/obdw/sandwich_analysis_data/basic_plus_analysis_wer_coeftest.csv")

model <- lm(sentCoherenceSentBertCumulativeCentroid ~ . - wer - log_wer, data=basic_plus_analysis_df);
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, basic_plus_analysis_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/basic_plus_analysis_coh_coeftest.csv")


# Basic+ Clinical model

basic_plus_clinical_analysis_df = read.csv("/edata/obdw/sandwich_analysis_data/basic_plus_clinical_analysis.csv")
basic_plus_clinical_analysis_df <- subset(basic_plus_clinical_analysis_df, select = -c(X))

model <- lm(log_wer ~ . - sentCoherenceSentBertCumulativeCentroid - snr - wer, data=basic_plus_clinical_analysis_df);
results_wer <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_wer_with_counts <- add_obs_counts(results_wer, basic_plus_clinical_analysis_df)
# print(results_wer_with_counts)
write.csv(results_wer, "/edata/obdw/sandwich_analysis_data/basic_plus_clinical_analysis_wer_coeftest.csv")

model <- lm(sentCoherenceSentBertCumulativeCentroid ~ . - wer - log_wer, data=basic_plus_clinical_analysis_df);
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, basic_plus_clinical_analysis_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/basic_plus_clinical_analysis_coh_coeftest.csv")

#  With SDH 
basic_plus_clinical_sdh_analysis_df = read.csv("/edata/obdw/sandwich_analysis_data/basic_plus_clinical_sdh_analysis.csv")
basic_plus_clinical_sdh_analysis_df <- subset(basic_plus_clinical_sdh_analysis_df, select = -c(X))

model <- lm(log_wer ~ . - sentCoherenceSentBertCumulativeCentroid - snr - wer, data=basic_plus_clinical_sdh_analysis_df);
results_wer <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_wer_with_counts <- add_obs_counts(results_wer, basic_plus_clinical_sdh_analysis_df)
# print(results_wer_with_counts)
write.csv(results_wer, "/edata/obdw/sandwich_analysis_data/basic_plus_clinical_sdh_analysis_wer_coeftest.csv")

model <- lm(sentCoherenceSentBertCumulativeCentroid ~ . - wer - log_wer, data=basic_plus_clinical_sdh_analysis_df);
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, basic_plus_clinical_sdh_analysis_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/basic_plus_clinical_sdh_analysis_coh_coeftest.csv")


# Basic+ Clinical + SDH + Location model

location_encoded_df = read.csv("/edata/obdw/sandwich_analysis_data/X_basic_plus_clin_sdh_location_encoded.csv")
location_encoded_df <- subset(location_encoded_df, select = -c(X))

model <- lm(log_wer ~ . - sentCoherenceSentBertCumulativeCentroid - snr - wer, data=location_encoded_df);
results_wer <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_wer_with_counts <- add_obs_counts(results_wer, location_encoded_df)
# print(results_wer_with_counts)
write.csv(results_wer, "/edata/obdw/sandwich_analysis_data/location_encoded_analysis_wer_coeftest.csv")

model <- lm(sentCoherenceSentBertCumulativeCentroid ~ . - wer - log_wer, data=location_encoded_df);
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, location_encoded_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/location_encoded_analysis_coh_coeftest.csv")

