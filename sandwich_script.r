# Load required packages (install if needed)
if (!require("lmtest", quietly = TRUE)) {
  install.packages("lmtest", repos = "http://cran.rstudio.com/")
}
if (!require("sandwich", quietly = TRUE)) {
  install.packages("sandwich", repos = "http://cran.rstudio.com/")
}
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

# Iteratively drop aliased predictors from the input data.
drop_aliased_predictors <- function(data_df, model_formula, data_name = "data", max_iter = 10) {
  dropped_vars <- character(0)

  for (i in seq_len(max_iter)) {
    model <- lm(model_formula, data = data_df)
    alias_info <- alias(model)
    aliased <- character(0)

    if (!is.null(alias_info$Complete)) {
      aliased <- rownames(alias_info$Complete)
    }

    aliased <- setdiff(aliased, "(Intercept)")
    aliased <- aliased[aliased %in% names(data_df)]

    if (length(aliased) == 0) {
      if (length(dropped_vars) > 0) {
        cat("\nDropped aliased variables from", data_name, ":", paste(dropped_vars, collapse = ", "), "\n")
      }
      return(list(data = data_df, dropped = dropped_vars))
    }

    cat("\nDetected aliased variables in", data_name, "(iteration", i, "):", paste(aliased, collapse = ", "), "\n")
    data_df <- data_df[, !(names(data_df) %in% aliased), drop = FALSE]
    dropped_vars <- unique(c(dropped_vars, aliased))
  }

  warning(paste("Reached max_iter while removing aliased variables in", data_name))
  return(list(data = data_df, dropped = dropped_vars))
}


# Replace sentinel 999 values in continuous clinical columns with NA.
clean_sentinel_values <- function(data_df, data_name = "data", sentinel = 999) {
  sentinel_cols <- c("scl.avg.global.score", "phq9.total", "hpsvq.total.score")
  existing_cols <- sentinel_cols[sentinel_cols %in% names(data_df)]

  for (col_name in existing_cols) {
    col_values <- data_df[[col_name]]
    if (is.numeric(col_values)) {
      sentinel_n <- sum(col_values == sentinel, na.rm = TRUE)
      if (sentinel_n > 0) {
        cat("\nReplacing", sentinel_n, "sentinel", sentinel, "values with NA in", data_name, "column", col_name, "\n")
        data_df[[col_name]][col_values == sentinel] <- NA
      }
    }
  }

  return(data_df)
}

# Shared loader for model dataframes.
prepare_model_df <- function(csv_path, data_name = "data") {
  data_df <- read.csv(csv_path)
  if ("X" %in% names(data_df)) {
    data_df <- subset(data_df, select = -c(X))
  }
  data_df <- clean_sentinel_values(data_df, data_name = data_name)
  return(data_df)
}


# Basic analysis model
basic_analysis_df <- prepare_model_df(
  "/edata/obdw/sandwich_analysis_data/basic_analysis.csv",
  data_name = "basic_analysis_df"
)

model <- lm(Y_WER ~ . - Y_COH, data=basic_analysis_df);
results_wer <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_wer_with_counts <- add_obs_counts(results_wer, basic_analysis_df)
# print(results_wer_with_counts)
write.csv(results_wer, "/edata/obdw/sandwich_analysis_data/basic_analysis_wer_coeftest.csv")

model <- lm(Y_COH ~ . - Y_WER, data=basic_analysis_df);
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, basic_analysis_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/basic_analysis_coh_coeftest.csv")


# Basic+ analysis model
basic_plus_analysis_df <- prepare_model_df(
  "/edata/obdw/sandwich_analysis_data/basic_plus_analysis.csv",
  data_name = "basic_plus_analysis_df"
)

model <- lm(Y_WER ~ . - Y_COH - snr, data=basic_plus_analysis_df);
results_wer <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_wer_with_counts <- add_obs_counts(results_wer, basic_plus_analysis_df)
# print(results_wer_with_counts)
write.csv(results_wer, "/edata/obdw/sandwich_analysis_data/basic_plus_analysis_wer_coeftest.csv")

model <- lm(Y_COH ~ . - Y_WER, data=basic_plus_analysis_df);
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, basic_plus_analysis_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/basic_plus_analysis_coh_coeftest.csv")


# Basic+ Clinical model

basic_plus_clinical_analysis_df <- prepare_model_df(
  "/edata/obdw/sandwich_analysis_data/basic_plus_clinical_analysis.csv",
  data_name = "basic_plus_clinical_analysis_df"
)

model <- lm(Y_WER ~ . - Y_COH - snr, data=basic_plus_clinical_analysis_df);
results_wer <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_wer_with_counts <- add_obs_counts(results_wer, basic_plus_clinical_analysis_df)
# print(results_wer_with_counts)
write.csv(results_wer, "/edata/obdw/sandwich_analysis_data/basic_plus_clinical_analysis_wer_coeftest.csv")

model <- lm(Y_COH ~ . - Y_WER, data=basic_plus_clinical_analysis_df);
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, basic_plus_clinical_analysis_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/basic_plus_clinical_analysis_coh_coeftest.csv")

#  With SDH 
basic_plus_clinical_sdh_analysis_df <- prepare_model_df(
  "/edata/obdw/sandwich_analysis_data/basic_plus_clinical_sdh_analysis.csv",
  data_name = "basic_plus_clinical_sdh_analysis_df"
)

model <- lm(Y_WER ~ . - Y_COH - snr, data=basic_plus_clinical_sdh_analysis_df);
results_wer <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_wer_with_counts <- add_obs_counts(results_wer, basic_plus_clinical_sdh_analysis_df)
# print(results_wer_with_counts)
write.csv(results_wer, "/edata/obdw/sandwich_analysis_data/basic_plus_clinical_sdh_analysis_wer_coeftest.csv")

model <- lm(Y_COH ~ . - Y_WER, data=basic_plus_clinical_sdh_analysis_df);
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, basic_plus_clinical_sdh_analysis_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/basic_plus_clinical_sdh_analysis_coh_coeftest.csv")


# Basic+ Clinical + SDH + Location model
location_encoded_df <- prepare_model_df(
  "/edata/obdw/sandwich_analysis_data/X_basic_plus_clin_sdh_location_encoded.csv",
  data_name = "location_encoded_df"
)

# Auto-remove aliased variables before VIF calculation to avoid hard failures.
location_encoded_model <- drop_aliased_predictors(
  data_df = location_encoded_df,
  model_formula = Y_WER ~ . - Y_COH - snr,
  data_name = "location_encoded_df"
)
location_encoded_df <- location_encoded_model$data
model <- lm(Y_WER ~ . - Y_COH - snr, data=location_encoded_df)
results_wer <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_wer_with_counts <- add_obs_counts(results_wer, location_encoded_df)
# print(results_wer_with_counts)
write.csv(results_wer, "/edata/obdw/sandwich_analysis_data/location_encoded_analysis_wer_coeftest.csv")

# Check for aliased coefficients before VIF
cat("\nChecking for aliased (collinear) coefficients in location_encoded_df model:\n")
alias_info <- alias(model)
print(alias_info)

# Check for multicollinearity using VIF
if (!require(car)) install.packages("car")
library(car)
cat("\nVIF for predictors in location_encoded_df model:\n")
vif_results <- tryCatch(
  vif(model),
  error = function(e) {
    cat("VIF could not be computed:", conditionMessage(e), "\n")
    NULL
  }
)
if (!is.null(vif_results)) {
  print(vif_results)
}
cat("\nVIF > 5 or 10 suggests multicollinearity. Consider removing or combining variables with high VIF.\n")

model <- lm(Y_COH ~ . - Y_WER, data=location_encoded_df)
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, location_encoded_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/location_encoded_analysis_coh_coeftest.csv")

# Basic+ Clinical + SDH + Location Stratified model
# This model has a lot of variables. 
location_stratified_df <- prepare_model_df(
  "/edata/obdw/sandwich_analysis_data/X_basic_plus_clin_sdh_location_stratified.csv",
  data_name = "location_stratified_df"
)

model <- lm(Y_WER ~ . - Y_COH, data=location_stratified_df);
results_wer <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_wer_with_counts <- add_obs_counts(results_wer, location_stratified_df)
# print(results_wer_with_counts)
write.csv(results_wer, "/edata/obdw/sandwich_analysis_data/location_stratified_analysis_wer_coeftest.csv")

# # Check for aliased coefficients before VIF
# cat("\nChecking for aliased (collinear) coefficients in location_stratified_df model:\n")
# alias_info <- alias(model)
# print(alias_info)

# # Check for multicollinearity using VIF for location_stratified_df
# if (!require(car)) install.packages("car")
# library(car)
# cat("\nVIF for predictors in location_stratified_df model:\n")
# print(vif(model))
# cat("\nVIF > 5 or 10 suggests multicollinearity. Consider removing or combining variables with high VIF.\n")

model <- lm(Y_COH ~ . - Y_WER, data=location_stratified_df);
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, location_stratified_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/location_stratified_analysis_coh_coeftest.csv")




