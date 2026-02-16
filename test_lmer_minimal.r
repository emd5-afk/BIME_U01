# Minimal test script for lmer debugging

library(lme4)

# Read only needed columns
cat("Reading data...\n")
stratified_df <- read.csv("/edata/obdw/sandwich_analysis_data/X_basic_plus_clin_sdh_location_stratified.csv")

cat("Original rows:", nrow(stratified_df), "\n")

# Filter empty cluster values
stratified_df <- stratified_df[!is.na(stratified_df$cluster) & stratified_df$cluster != "", ]

cat("After filtering empty clusters:", nrow(stratified_df), "\n")

# Convert cluster to factor
stratified_df$cluster <- as.factor(stratified_df$cluster)

cat("Cluster levels:", levels(stratified_df$cluster), "\n")
cat("Cluster counts:\n")
print(table(stratified_df$cluster))

# Check for NAs in outcome and predictors
cat("\nChecking for NAs:\n")
cat("log_wer NAs:", sum(is.na(stratified_df$log_wer)), "\n")
cat("phq9.total NAs:", sum(is.na(stratified_df$phq9.total)), "\n")
cat("hpsvq.total.score NAs:", sum(is.na(stratified_df$hpsvq.total.score)), "\n")
cat("scl.avg.global.score NAs:", sum(is.na(stratified_df$scl.avg.global.score)), "\n")
cat("cluster NAs:", sum(is.na(stratified_df$cluster)), "\n")

# Remove any rows with NA in these variables
complete_cases <- complete.cases(stratified_df[, c("log_wer", "phq9.total", "hpsvq.total.score", "scl.avg.global.score", "cluster")])
cat("\nComplete cases:", sum(complete_cases), "out of", length(complete_cases), "\n")

stratified_df <- stratified_df[complete_cases, ]

cat("Final dataset size:", nrow(stratified_df), "\n")
cat("Final cluster distribution:\n")
print(table(stratified_df$cluster))

# Try simplest possible mixed model
cat("\nAttempting simplest mixed model: log_wer ~ phq9.total + (1|cluster)\n")
tryCatch({
  model_simple <- lmer(log_wer ~ phq9.total + (1|cluster), data = stratified_df, REML = TRUE)
  cat("SUCCESS! Simple model fitted.\n")
  print(summary(model_simple))
}, error = function(e) {
  cat("ERROR in simple model:\n")
  print(e)
})
