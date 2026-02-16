# Test nlme package as alternative to lme4
# nlme is older but more stable, uses different syntax

if (!require("nlme", quietly = TRUE)) {
  install.packages("nlme", repos = "http://cran.rstudio.com/")
  library(nlme)
}

cat("Reading data...\n")
stratified_df <- read.csv("/edata/obdw/sandwich_analysis_data/X_basic_plus_clin_sdh_location_stratified.csv")

cat("Filtering empty clusters...\n")
stratified_df <- stratified_df[!is.na(stratified_df$cluster) & stratified_df$cluster != "", ]

cat("Converting cluster to factor...\n")
stratified_df$cluster <- as.factor(stratified_df$cluster)

cat("Cluster levels:", levels(stratified_df$cluster), "\n")
cat("Number of observations:", nrow(stratified_df), "\n")

cat("\nChecking for NAs in key variables...\n")
cat("NAs in log_wer:", sum(is.na(stratified_df$log_wer)), "\n")
cat("NAs in phq9.total:", sum(is.na(stratified_df$phq9.total)), "\n")
cat("NAs in cluster:", sum(is.na(stratified_df$cluster)), "\n")

cat("\nFiltering to complete cases...\n")
stratified_df <- stratified_df[complete.cases(stratified_df[, c("log_wer", "phq9.total", "cluster")]), ]
cat("Complete cases:", nrow(stratified_df), "\n")

cat("\nAttempting nlme::lme model (alternative to lmer)...\n")
tryCatch({
  # nlme syntax: lme(fixed, random = ~1|group, data)
  model_nlme <- lme(log_wer ~ phq9.total, 
                    random = ~1|cluster, 
                    data = stratified_df,
                    method = "REML")
  
  cat("SUCCESS! nlme model fitted.\n")
  print(summary(model_nlme))
  
}, error = function(e) {
  cat("ERROR in nlme model:\n")
  print(e)
})
