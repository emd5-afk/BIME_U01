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

## Models

1. **Basic**: Demographics (age, race, gender)
2. **Basic+**: Basic + audio quality (SNR, MOS, pause proportion)
3. **Basic+ Clinical**: Basic+ + clinical scales (PHQ-9, HPSVQ, SCL)
4. **Basic+ Clinical + SDH**: Basic+ Clinical + social determinants (education, employment, sexuality, substance use)
5. **Location**: Full model + geographic variables (SVI indices, RUCA codes, state)

## Outcomes

- **WER (Word Error Rate)**: log-transformed
- **Coherence**: Sentence coherence using SentBERT cumulative centroid

## SSH Setup (BRAGI Server / VSCode Remote)

If VSCode repeatedly prompts for a password when connecting to BRAGI, follow these steps:

### 1. Generate an SSH key on your local machine (run once)
```bash
ssh-keygen -t ed25519 -C "your_netid@uw.edu"
# Accept the default path (~/.ssh/id_ed25519) and set a passphrase.
```

### 2. Copy your public key to the BRAGI server
```bash
ssh-copy-id your_netid@bragi.uw.edu
# Enter your password once; future logins will use the key.
```

### 3. Configure your local SSH client (`~/.ssh/config`)
Add the following on your **local** machine:
```
Host bragi.uw.edu
    IdentityFile ~/.ssh/id_ed25519
    AddKeysToAgent yes
```

### 4. Why it works
- The `~/.ssh/config` checked into this repo sets `AddKeysToAgent yes` and
  keepalive options **on BRAGI** so that outbound SSH connections from the
  server also stay authenticated.
- The `~/.bashrc` in this repo auto-starts `ssh-agent` on login so that
  `SSH_AUTH_SOCK` is always populated (it was empty before, causing the
  repeated password prompts visible in the VSCode terminal).



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

## Data

Data files are not included in this repository for privacy and size reasons. Contact the project team for access.

## Citation

If you use this code, please cite:
[Citation information to be added]

## License

[License information to be added]

## Contact

[Contact information to be added]
