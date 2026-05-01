# BIME U01 - AVH Sandwich Analysis

Analysis of Auditory Verbal Hallucinations (AVH) data using sandwich estimators for clustered regression.

## Project Overview

This repository contains code for analyzing speech and coherence data from participants experiencing auditory verbal hallucinations. The analysis uses:
- Linear mixed models with sandwich estimators (clustered by participant)
- Geographic and social determinant variables
- Multiple model specifications (Basic, Basic+, Basic+ Clinical, Basic+ Clinical + SDH, + Location)

## Files

- **`primary_data_collection_script.ipynb`**: Main Python notebook for data collection, merging, and preprocessing
  - Merges data from multiple sources (WhisperX, SNR, MOS, coherence measures)
  - Feature engineering and one-hot encoding
  - Creates analysis-ready datasets
  - Generates visualization code for regression results

- **`sandwich_script.r`**: R script for regression analysis
  - Fits linear models with sandwich variance estimators
  - Uses `lmtest` and `sandwich` packages
  - Clusters standard errors by participant (pid)
  - Outputs coefficient test results

- **`aim2_analysis_pipeline.R`**: Consolidated Aim 2 analysis pipeline
  - Primary model: multivariable linear regression with participant-clustered sandwich SEs
  - Primary exposure: transcript-level WER on log scale (`log_wer`, created if missing)
  - Prespecified covariates: demographic, clinical, recording-quality, and transcript-level
  - Sensitivity models: mixed-effects random intercept, plus optional random slope for WER when supported
  - Writes per-outcome model outputs and a model-status summary file

## Models

1. **Basic**: Demographics (age, race, gender)
2. **Basic+**: Basic + audio quality (SNR, MOS, pause proportion)
3. **Basic+ Clinical**: Basic+ + clinical scales (PHQ-9, HPSVQ, SCL)
4. **Basic+ Clinical + SDH**: Basic+ Clinical + social determinants (education, employment, sexuality, substance use)
5. **Location**: Full model + geographic variables (SVI indices, RUCA codes, state)

## Outcomes

- **WER (Word Error Rate)**: log-transformed
- **Coherence**: Sentence coherence using SentBERT cumulative centroid

## Requirements

### Python
- pandas
- numpy
- matplotlib
- scikit-learn

### R
- lmtest
- sandwich

## Usage

1. Run `primary_data_collection_script.ipynb` to prepare analysis datasets
2. Execute `sandwich_script.r` to perform regression analyses
3. Use visualization code in the notebook to generate forest plots

### Aim 2 (Checklist-Aligned) Run

Use the consolidated pipeline to run the checklist-complete Aim 2 workflow:

```bash
Rscript aim2_analysis_pipeline.R
```

Optional arguments:

```bash
Rscript aim2_analysis_pipeline.R \
  --data=/edata/obdw/sandwich_analysis_data/X_basic_plus_clin_sdh_location_stratified.csv \
  --out=/edata/obdw/sandwich_analysis_data/aim2_outputs \
  --outcomes=Y_COH,sentCoherenceSentBertCumulativeCentroid
```

## Data

Data files are not included in this repository for privacy and size reasons. Contact the project team for access.

## Citation

If you use this code, please cite:
[Citation information to be added]

## License

[License information to be added]

## Contact

[Contact information to be added]
