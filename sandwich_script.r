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

# Remove collinear (aliased) variables before model fitting
# ToDo: remove, or handle in /home/NETID/emd5/primary_data_collection_script.ipynb
# ToDo: remove, or handle in /home/NETID/emd5/primary_data_collection_script.ipynb
# Adding a collinearity check before VIF calculation, have to remove this perfectly collinear (aliased) variables first
# gender_5.0, sexuality_999.0, PrimaryRUCA_nan
aliased_vars <- c("gender_5.0", "sexuality_999.0", "PrimaryRUCA_nan")
aliased_vars <- aliased_vars[aliased_vars %in% names(location_encoded_df)]
if (length(aliased_vars) > 0) {
  cat("\nRemoving aliased variables from location_encoded_df:", paste(aliased_vars, collapse=", "), "\n")
  location_encoded_df <- location_encoded_df[ , !(names(location_encoded_df) %in% aliased_vars)]
}

# Adding a collinearity check before VIF calculation, have to remove this perfectly collinear (aliased) variables first
# gender_5.0, sexuality_999.0, PrimaryRUCA_nan
model <- lm(log_wer ~ . - sentCoherenceSentBertCumulativeCentroid - snr - wer, data=location_encoded_df)
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
print(vif(model))
cat("\nVIF > 5 or 10 suggests multicollinearity. Consider removing or combining variables with high VIF.\n")

model <- lm(sentCoherenceSentBertCumulativeCentroid ~ . - wer - log_wer, data=location_encoded_df)
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, location_encoded_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/location_encoded_analysis_coh_coeftest.csv")

# Basic+ Clinical + SDH + Location Stratified model
# This model has a lot of variables. 
location_stratified_df = read.csv("/edata/obdw/sandwich_analysis_data/X_basic_plus_clin_sdh_location_stratified.csv")
location_stratified_df <- subset(location_stratified_df, select = -c(X))

model <- lm(log_wer ~ . - sentCoherenceSentBertCumulativeCentroid - snr - wer, data=location_stratified_df);
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

model <- lm(sentCoherenceSentBertCumulativeCentroid ~ . - wer - log_wer, data=location_stratified_df);
results_coh <- coeftest(model, vcov=vcovCL(model, cluster=~pid))
# results_coh_with_counts <- add_obs_counts(results_coh, location_stratified_df)
# print(results_coh_with_counts)
write.csv(results_coh, "/edata/obdw/sandwich_analysis_data/location_stratified_analysis_coh_coeftest.csv")



# ==============================================================================
# MIXED MODELS WITH CLUSTER AS RANDOM EFFECT
# ==============================================================================
# Load required libraries for mixed models (nlme instead of lme4 due to segfault issues)
if (!require("nlme", quietly = TRUE)) {
  install.packages("nlme", repos = "http://cran.rstudio.com/")
}
library(nlme)

# Load stratified dataset with cluster variable
stratified_df <- read.csv("/edata/obdw/sandwich_analysis_data/X_basic_plus_clin_sdh_location_stratified.csv")
stratified_df <- subset(stratified_df, select = -c(X))

# Remove rows with missing cluster values (can't fit random effects without cluster)
stratified_df <- stratified_df[!is.na(stratified_df$cluster) & stratified_df$cluster != "", ]

# Convert cluster to factor for proper random effects modeling
stratified_df$cluster <- as.factor(stratified_df$cluster)

cat("\n", rep("=", 80), "\n", sep="")
cat("MIXED MODEL ANALYSIS: CLUSTER AS RANDOM EFFECT\n")
cat(rep("=", 80), "\n", sep="")
cat("Dataset shape: ", nrow(stratified_df), " rows, ", ncol(stratified_df), " columns\n")
cat("Number of unique clusters: ", length(unique(stratified_df$cluster)), "\n")
cat("Cluster levels: ", paste(levels(stratified_df$cluster), collapse=", "), "\n")

# Check if demographic variables exist, if not, use available columns
cat("\nChecking for demographic variables...\n")
has_race <- any(grepl("^race_", names(stratified_df)))
has_gender <- any(grepl("^gender_", names(stratified_df)))
has_age <- any(grepl("^binned_age_", names(stratified_df)))

cat("Race variables found: ", has_race, "\n")
cat("Gender variables found: ", has_gender, "\n")
cat("Age variables found: ", has_age, "\n")

# Build demographic formula component dynamically
demo_vars <- c()
if (has_race) {
  race_vars <- grep("^race_[0-9]+\\.[0-9]+$", names(stratified_df), value=TRUE)
  # Filter out zero-variance variables
  race_sums <- sapply(race_vars, function(v) sum(stratified_df[[v]], na.rm=TRUE))
  race_nonzero <- race_vars[race_sums > 0]
  # Drop first category as reference to avoid perfect collinearity (keep n-1)
  if (length(race_nonzero) > 1) {
    demo_vars <- c(demo_vars, race_nonzero[-1])
  }
}
if (has_gender) {
  gender_vars <- grep("^gender_[0-9]+\\.[0-9]+$", names(stratified_df), value=TRUE)
  gender_sums <- sapply(gender_vars, function(v) sum(stratified_df[[v]], na.rm=TRUE))
  gender_nonzero <- gender_vars[gender_sums > 0]
  # Drop first category as reference (keep n-1)
  if (length(gender_nonzero) > 1) {
    demo_vars <- c(demo_vars, gender_nonzero[-1])
  }
}
if (has_age) {
  age_vars <- grep("^binned_age_[0-9]+\\.[0-9]+$", names(stratified_df), value=TRUE)
  age_sums <- sapply(age_vars, function(v) sum(stratified_df[[v]], na.rm=TRUE))
  age_nonzero <- age_vars[age_sums > 0]
  # Drop first category as reference (keep n-1)
  if (length(age_nonzero) > 1) {
    demo_vars <- c(demo_vars, age_nonzero[-1])
  }
}

if (length(demo_vars) > 0) {
  cat("Using demographic variables (n-1 encoding): ", paste(demo_vars, collapse=", "), "\n\n")
  demo_formula <- paste(demo_vars, collapse=" + ")
} else {
  cat("WARNING: No demographic variables found. Running models without demographics.\n\n")
  demo_formula <- ""
}

# ------------------------------------------------------------------------------
# MODEL 1: Basic Mixed Model - Clinical Predictors + Demographics
# ------------------------------------------------------------------------------
cat("MODEL 1: Clinical Predictors + Demographics with Random Intercept by Cluster\n")
cat(rep("-", 80), "\n", sep="")

# Build formula dynamically (nlme uses separate random= argument)
if (demo_formula != "") {
  formula_wer <- as.formula(paste("log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score +", 
                                   demo_formula))
  formula_coh <- as.formula(paste("sentCoherenceSentBertCumulativeCentroid ~ phq9.total + hpsvq.total.score + scl.avg.global.score +",
                                   demo_formula))
} else {
  formula_wer <- as.formula("log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score")
  formula_coh <- as.formula("sentCoherenceSentBertCumulativeCentroid ~ phq9.total + hpsvq.total.score + scl.avg.global.score")
}

cat("\nFormula (WER): ", deparse(formula_wer), "\n")

model1_wer <- lme(formula_wer, random = ~1|cluster, data = stratified_df, method = "REML")

cat("\nModel 1 Summary (WER):\n")
print(summary(model1_wer))

# Save results
model1_results <- as.data.frame(coef(summary(model1_wer)))
write.csv(model1_results, "/edata/obdw/sandwich_analysis_data/mixed_model1_wer_basic_clinical.csv")

# Coherence outcome
model1_coh <- lme(formula_coh, random = ~1|cluster, data = stratified_df, method = "REML")

model1_coh_results <- as.data.frame(coef(summary(model1_coh)))
write.csv(model1_coh_results, "/edata/obdw/sandwich_analysis_data/mixed_model1_coh_basic_clinical.csv")

# ------------------------------------------------------------------------------
# MODEL 2: Mixed Model with Demographics + Stratification Variables
# ------------------------------------------------------------------------------
cat("\n\nMODEL 2: Clinical + Demographics + Stratification Variables with Random Intercept\n")
cat(rep("-", 80), "\n", sep="")

# Build formula dynamically (nlme uses separate random= argument)
if (demo_formula != "") {
  formula_wer <- as.formula(paste("log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score +",
                                   demo_formula, "+ urban_rural_category + high_svi + low_healthcare_access + low_resource_access"))
  formula_coh <- as.formula(paste("sentCoherenceSentBertCumulativeCentroid ~ phq9.total + hpsvq.total.score + scl.avg.global.score +",
                                   demo_formula, "+ urban_rural_category + high_svi + low_healthcare_access + low_resource_access"))
} else {
  formula_wer <- as.formula("log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score + urban_rural_category + high_svi + low_healthcare_access + low_resource_access")
  formula_coh <- as.formula("sentCoherenceSentBertCumulativeCentroid ~ phq9.total + hpsvq.total.score + scl.avg.global.score + urban_rural_category + high_svi + low_healthcare_access + low_resource_access")
}

model2_wer <- lme(formula_wer, random = ~1|cluster, data = stratified_df, method = "REML")

cat("\nModel 2 Summary (WER):\n")
print(summary(model2_wer))

model2_results <- as.data.frame(coef(summary(model2_wer)))
write.csv(model2_results, "/edata/obdw/sandwich_analysis_data/mixed_model2_wer_with_stratification.csv")

# Coherence outcome
model2_coh <- lme(formula_coh, random = ~1|cluster, data = stratified_df, method = "REML")

model2_coh_results <- as.data.frame(coef(summary(model2_coh)))
write.csv(model2_coh_results, "/edata/obdw/sandwich_analysis_data/mixed_model2_coh_with_stratification.csv")

# ------------------------------------------------------------------------------
# MODEL 3: Mixed Model with Demographics + Interaction Terms
# ------------------------------------------------------------------------------
cat("\n\nMODEL 3: Clinical Variables with SVI Interaction + Demographics\n")
cat(rep("-", 80), "\n", sep="")

# Build formula dynamically (nlme uses separate random= argument)
if (demo_formula != "") {
  formula_wer <- as.formula(paste("log_wer ~ phq9.total * high_svi + hpsvq.total.score * high_svi + scl.avg.global.score * high_svi +",
                                   demo_formula))
  formula_coh <- as.formula(paste("sentCoherenceSentBertCumulativeCentroid ~ phq9.total * high_svi + hpsvq.total.score * high_svi + scl.avg.global.score * high_svi +",
                                   demo_formula))
} else {
  formula_wer <- as.formula("log_wer ~ phq9.total * high_svi + hpsvq.total.score * high_svi + scl.avg.global.score * high_svi")
  formula_coh <- as.formula("sentCoherenceSentBertCumulativeCentroid ~ phq9.total * high_svi + hpsvq.total.score * high_svi + scl.avg.global.score * high_svi")
}

# Test if clinical effects differ by SVI vulnerability
model3_wer <- lme(formula_wer, random = ~1|cluster, data = stratified_df, method = "REML")

cat("\nModel 3 Summary (WER with interactions):\n")
print(summary(model3_wer))

model3_results <- as.data.frame(coef(summary(model3_wer)))
write.csv(model3_results, "/edata/obdw/sandwich_analysis_data/mixed_model3_wer_interactions.csv")

# Coherence outcome
model3_coh <- lme(formula_coh, random = ~1|cluster, data = stratified_df, method = "REML")

model3_coh_results <- as.data.frame(coef(summary(model3_coh)))
write.csv(model3_coh_results, "/edata/obdw/sandwich_analysis_data/mixed_model3_coh_interactions.csv")

# ------------------------------------------------------------------------------
# MODEL 4: Mixed Model with Random Slopes (Optional - More Complex)
# ------------------------------------------------------------------------------
cat("\n\nMODEL 4: Random Intercept + Random Slope for PHQ-9\n")
cat(rep("-", 80), "\n", sep="")
cat("NOTE: This model allows the effect of PHQ-9 to vary by cluster\n")

# (1 + phq9.total|cluster) = random intercept + random slope for phq9.total
# This can fail to converge if there's not enough variation
tryCatch({
  model4_wer <- lme(log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score,
                    random = ~1 + phq9.total|cluster,
                    data = stratified_df,
                    method = "REML")
  
  cat("\nModel 4 Summary (WER with random slopes):\n")
  print(summary(model4_wer))
  
  model4_results <- as.data.frame(coef(summary(model4_wer)))
  write.csv(model4_results, "/edata/obdw/sandwich_analysis_data/mixed_model4_wer_random_slopes.csv")
}, error = function(e) {
  cat("\nWARNING: Model 4 failed to converge. This is common with random slopes.\n")
  cat("Error message: ", e$message, "\n")
  cat("Consider using simpler models (random intercept only) instead.\n")
})

# ==============================================================================
# MULTICOLLINEARITY DIAGNOSTICS (VIF ANALYSIS)
# ==============================================================================
cat("\n", rep("=", 80), "\n", sep="")
cat("MULTICOLLINEARITY DIAGNOSTICS: VARIANCE INFLATION FACTOR (VIF)\n")
cat(rep("=", 80), "\n", sep="")
cat("VIF measures how much variance of a coefficient is inflated due to collinearity\n")
cat("Guidelines: VIF < 5 = acceptable, VIF 5-10 = concerning, VIF > 10 = serious problem\n\n")

# Load car package for VIF calculation
if (!require("car", quietly = TRUE)) {
  install.packages("car", repos = "http://cran.rstudio.com/")
}
library(car)

# VIF requires a standard lm object (not lme), so we'll fit OLS versions for diagnostics
# This gives us a sense of multicollinearity in the fixed effects

# VIF for Model 1 (Clinical + Demographics)
cat("MODEL 1: Clinical + Demographics\n")
cat(rep("-", 80), "\n", sep="")
if (demo_formula != "") {
  formula_vif_1 <- as.formula(paste("log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score +",
                                     demo_formula))
} else {
  formula_vif_1 <- as.formula("log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score")
}

tryCatch({
  lm_model1 <- lm(formula_vif_1, data = stratified_df)
  vif_model1 <- vif(lm_model1)
  vif_df1 <- data.frame(Variable = names(vif_model1), VIF = vif_model1)
  vif_df1$Problem <- ifelse(vif_df1$VIF > 10, "SERIOUS", 
                             ifelse(vif_df1$VIF > 5, "Concerning", "OK"))
  print(vif_df1)
  write.csv(vif_df1, "/edata/obdw/sandwich_analysis_data/vif_model1.csv", row.names = FALSE)
  
  max_vif <- max(vif_df1$VIF)
  if (max_vif > 10) {
    cat("\n⚠️  WARNING: Serious multicollinearity detected (VIF > 10)\n")
    cat("Variables with VIF > 10:\n")
    print(vif_df1[vif_df1$VIF > 10, ])
  } else if (max_vif > 5) {
    cat("\n⚠️  Moderate multicollinearity detected (VIF > 5)\n")
    cat("Variables with VIF > 5:\n")
    print(vif_df1[vif_df1$VIF > 5, ])
  } else {
    cat("\n✓ No concerning multicollinearity (all VIF < 5)\n")
  }
}, error = function(e) {
  cat("ERROR calculating VIF for Model 1: ", e$message, "\n")
})

# VIF for Model 2 (Clinical + Demographics + Stratification)
cat("\n\nMODEL 2: Clinical + Demographics + Stratification\n")
cat(rep("-", 80), "\n", sep="")
if (demo_formula != "") {
  formula_vif_2 <- as.formula(paste("log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score +",
                                     demo_formula, 
                                     "+ urban_rural_category + high_svi + low_healthcare_access + low_resource_access"))
} else {
  formula_vif_2 <- as.formula("log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score + urban_rural_category + high_svi + low_healthcare_access + low_resource_access")
}

tryCatch({
  lm_model2 <- lm(formula_vif_2, data = stratified_df)
  vif_model2 <- vif(lm_model2)
  vif_df2 <- data.frame(Variable = names(vif_model2), VIF = vif_model2)
  vif_df2$Problem <- ifelse(vif_df2$VIF > 10, "SERIOUS", 
                             ifelse(vif_df2$VIF > 5, "Concerning", "OK"))
  print(vif_df2)
  write.csv(vif_df2, "/edata/obdw/sandwich_analysis_data/vif_model2.csv", row.names = FALSE)
  
  max_vif <- max(vif_df2$VIF)
  if (max_vif > 10) {
    cat("\n⚠️  WARNING: Serious multicollinearity detected (VIF > 10)\n")
    cat("Variables with VIF > 10:\n")
    print(vif_df2[vif_df2$VIF > 10, ])
  } else if (max_vif > 5) {
    cat("\n⚠️  Moderate multicollinearity detected (VIF > 5)\n")
    cat("Variables with VIF > 5:\n")
    print(vif_df2[vif_df2$VIF > 5, ])
  } else {
    cat("\n✓ No concerning multicollinearity (all VIF < 5)\n")
  }
}, error = function(e) {
  cat("ERROR calculating VIF for Model 2: ", e$message, "\n")
})

# VIF for Model 3 (With Interactions)
cat("\n\nMODEL 3: Clinical + Demographics + Stratification + Interactions\n")
cat(rep("-", 80), "\n", sep="")
if (demo_formula != "") {
  formula_vif_3 <- as.formula(paste("log_wer ~ phq9.total * high_svi + hpsvq.total.score * high_svi + scl.avg.global.score * high_svi +",
                                     demo_formula))
} else {
  formula_vif_3 <- as.formula("log_wer ~ phq9.total * high_svi + hpsvq.total.score * high_svi + scl.avg.global.score * high_svi")
}

tryCatch({
  lm_model3 <- lm(formula_vif_3, data = stratified_df)
  vif_model3 <- vif(lm_model3)
  vif_df3 <- data.frame(Variable = names(vif_model3), VIF = vif_model3)
  vif_df3$Problem <- ifelse(vif_df3$VIF > 10, "SERIOUS", 
                             ifelse(vif_df3$VIF > 5, "Concerning", "OK"))
  print(vif_df3)
  write.csv(vif_df3, "/edata/obdw/sandwich_analysis_data/vif_model3.csv", row.names = FALSE)
  
  max_vif <- max(vif_df3$VIF)
  if (max_vif > 10) {
    cat("\n⚠️  WARNING: Serious multicollinearity detected (VIF > 10)\n")
    cat("Variables with VIF > 10:\n")
    print(vif_df3[vif_df3$VIF > 10, ])
    cat("\nNote: Interactions often have high VIF - this may be acceptable if main effects are included\n")
  } else if (max_vif > 5) {
    cat("\n⚠️  Moderate multicollinearity detected (VIF > 5)\n")
    cat("Variables with VIF > 5:\n")
    print(vif_df3[vif_df3$VIF > 5, ])
  } else {
    cat("\n✓ No concerning multicollinearity (all VIF < 5)\n")
  }
}, error = function(e) {
  cat("ERROR calculating VIF for Model 3: ", e$message, "\n")
})

cat("\n", rep("=", 80), "\n", sep="")
cat("VIF ANALYSIS COMPLETE\n")
cat("Saved: vif_model1.csv, vif_model2.csv, vif_model3.csv\n")
cat(rep("=", 80), "\n", sep="")

# ==============================================================================
# MODEL COMPARISON
# ==============================================================================
cat("\n", rep("=", 80), "\n", sep="")
cat("MODEL COMPARISON: LIKELIHOOD RATIO TESTS\n")
cat(rep("=", 80), "\n", sep="")

# Refit models with ML (not REML) for valid likelihood ratio tests
if (demo_formula != "") {
  formula_wer_1 <- as.formula(paste("log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score +",
                                     demo_formula))
  formula_wer_2 <- as.formula(paste("log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score +",
                                     demo_formula, "+ urban_rural_category + high_svi + low_healthcare_access + low_resource_access"))
  formula_wer_3 <- as.formula(paste("log_wer ~ phq9.total * high_svi + hpsvq.total.score * high_svi + scl.avg.global.score * high_svi +",
                                     demo_formula))
} else {
  formula_wer_1 <- as.formula("log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score")
  formula_wer_2 <- as.formula("log_wer ~ phq9.total + hpsvq.total.score + scl.avg.global.score + urban_rural_category + high_svi + low_healthcare_access + low_resource_access")
  formula_wer_3 <- as.formula("log_wer ~ phq9.total * high_svi + hpsvq.total.score * high_svi + scl.avg.global.score * high_svi")
}

model1_wer_ml <- lme(formula_wer_1, random = ~1|cluster, data = stratified_df, method = "ML")
model2_wer_ml <- lme(formula_wer_2, random = ~1|cluster, data = stratified_df, method = "ML")
model3_wer_ml <- lme(formula_wer_3, random = ~1|cluster, data = stratified_df, method = "ML")

# Likelihood ratio test: Does Model 2 improve over Model 1?
cat("\n1. Model 1 vs Model 2 (Adding stratification variables):\n")
cat(rep("-", 80), "\n", sep="")
anova_1v2 <- anova(model1_wer_ml, model2_wer_ml)
print(anova_1v2)
# nlme anova() returns p-value in different column than lme4
p_value_1v2 <- anova_1v2$"p-value"[2]
if (!is.na(p_value_1v2) && p_value_1v2 < 0.05) {
  cat("\nResult: Model 2 significantly improves fit (p < 0.05)\n")
} else {
  cat("\nResult: Model 2 does not significantly improve fit (p >= 0.05)\n")
}

# Likelihood ratio test: Does Model 3 improve over Model 2?
cat("\n2. Model 2 vs Model 3 (Adding interaction terms):\n")
cat(rep("-", 80), "\n", sep="")
anova_2v3 <- anova(model2_wer_ml, model3_wer_ml)
print(anova_2v3)
p_value_2v3 <- anova_2v3$"p-value"[2]
if (!is.na(p_value_2v3) && p_value_2v3 < 0.05) {
  cat("\nResult: Model 3 significantly improves fit (p < 0.05)\n")
} else {
  cat("\nResult: Model 3 does not significantly improve fit (p >= 0.05)\n")
}

# AIC/BIC comparison (lower is better)
cat("\n3. Information Criteria Comparison (AIC/BIC):\n")
cat(rep("-", 80), "\n", sep="")
cat("Lower values indicate better model fit, penalized for complexity\n\n")

ic_comparison <- data.frame(
  Model = c("Model 1", "Model 2", "Model 3"),
  AIC = c(AIC(model1_wer_ml), AIC(model2_wer_ml), AIC(model3_wer_ml)),
  BIC = c(BIC(model1_wer_ml), BIC(model2_wer_ml), BIC(model3_wer_ml))
)
print(ic_comparison)

best_aic <- which.min(ic_comparison$AIC)
best_bic <- which.min(ic_comparison$BIC)
cat("\nBest model by AIC: ", ic_comparison$Model[best_aic], "\n")
cat("Best model by BIC: ", ic_comparison$Model[best_bic], "\n")

# Save comparison results
write.csv(ic_comparison, "/edata/obdw/sandwich_analysis_data/mixed_models_comparison.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# INTRACLASS CORRELATION (ICC)
# ------------------------------------------------------------------------------
cat("\n", rep("=", 80), "\n", sep="")
cat("INTRACLASS CORRELATION COEFFICIENT (ICC)\n")
cat(rep("=", 80), "\n", sep="")
cat("ICC shows the proportion of variance explained by clustering\n\n")

# Calculate ICC for Model 1 (nlme syntax)
# VarCorr returns variance components for nlme objects
vc <- VarCorr(model1_wer)
# Extract variances: nlme stores them as strings in a matrix
cluster_var <- as.numeric(vc[1, "Variance"])  # Between-cluster variance (Intercept)
residual_var <- as.numeric(vc[2, "Variance"])  # Within-cluster variance (Residual)
icc <- cluster_var / (cluster_var + residual_var)

cat("Model 1 ICC: ", round(icc, 4), "\n")
cat("Interpretation: ", round(icc*100, 2), "% of variance in log_wer is due to cluster differences\n")

if (icc > 0.1) {
  cat("\nConclusion: Substantial clustering effect - mixed models are necessary\n")
} else if (icc > 0.05) {
  cat("\nConclusion: Moderate clustering effect - mixed models are recommended\n")
} else {
  cat("\nConclusion: Minimal clustering effect - but still good to account for it\n")
}

cat("\n", rep("=", 80), "\n", sep="")
cat("MIXED MODEL ANALYSIS COMPLETE\n")
cat("Results saved to /edata/obdw/sandwich_analysis_data/\n")
cat(rep("=", 80), "\n", sep="")

