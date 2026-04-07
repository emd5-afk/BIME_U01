"""
Shared utilities for AVH (Audio Voice Health) analysis
Contains data dictionaries and utility functions used across notebooks
"""

import pandas as pd

# Data dictionary for decoding variables
data_dictionary = {
    'race': {
        1: 'White',
        2: 'Black',
        4: 'Native American',
        5: 'Asian',
        6: 'More than one race',
        999: 'Unknown'
    },
    'gender': {
        1: 'Female',
        2: 'Male',
        3: 'Transgender (M to F)',
        4: 'Transgender (F to M)',
        5: 'Other'
    },
    'binned_age': {
        0: 'Unknown',
        1: 'Age < 30',
        2: 'Age 30-45',
        3: 'Age 45-65',
        4: 'Age >= 65'
    },
    'sexuality': {
        1: 'Heterosexual',
        2: 'Gay or Lesbian',
        3: 'Bisexual',
        4: 'Other',
        999: 'Unknown'
    },
    'employment_status': {
        1: 'Unemployed',
        2: 'Part-time work',
        3: 'Full-time work',
        999: 'Unknown'
    },
    'employment.status': {
        1: 'Unemployed',
        2: 'Part-time work',
        3: 'Full-time work',
        999: 'Unknown'
    },
    'education': {
        1: 'Grade school to HS',
        2: 'Associates to Bachelors',
        3: 'Masters and above'
    },
    'education_binned': {
        1: 'Grade school to HS',      # Original codes 2.0, 3.0, 4.0
        2: 'Associates to Bachelors',  # Original codes 5.0, 6.0
        3: 'Masters and above'         # Original codes 7.0, 8.0
    },
    'opioids.opiates': {
        1: 'Opioids or Opiates Use'
    },
    'STATEFP': {
        1: 'Alabama', 2: 'Alaska', 4: 'Arizona', 5: 'Arkansas', 6: 'California',
        8: 'Colorado', 9: 'Connecticut', 10: 'Delaware', 11: 'District of Columbia',
        12: 'Florida', 13: 'Georgia', 15: 'Hawaii', 16: 'Idaho', 17: 'Illinois',
        18: 'Indiana', 19: 'Iowa', 20: 'Kansas', 21: 'Kentucky', 22: 'Louisiana',
        23: 'Maine', 24: 'Maryland', 25: 'Massachusetts', 26: 'Michigan', 27: 'Minnesota',
        28: 'Mississippi', 29: 'Missouri', 30: 'Montana', 31: 'Nebraska', 32: 'Nevada',
        33: 'New Hampshire', 34: 'New Jersey', 35: 'New Mexico', 36: 'New York',
        37: 'North Carolina', 38: 'North Dakota', 39: 'Ohio', 40: 'Oklahoma', 41: 'Oregon',
        42: 'Pennsylvania', 44: 'Rhode Island', 45: 'South Carolina', 46: 'South Dakota',
        47: 'Tennessee', 48: 'Texas', 49: 'Utah', 50: 'Vermont', 51: 'Virginia',
        53: 'Washington', 54: 'West Virginia', 55: 'Wisconsin', 56: 'Wyoming'
    },
    'PrimaryRUCA': {
        1: 'Metropolitan Core',
        2: 'Metropolitan High Commuting',
        3: 'Metropolitan Low Commuting',
        4: 'Micropolitan Core',
        5: 'Micropolitan High Commuting',
        6: 'Micropolitan Low Commuting',
        7: 'Small Town Core',
        8: 'Small Town High Commuting',
        9: 'Small Town Low Commuting',
        10: 'Rural'
    },
    'SecondaryRUCA': {
        1: 'Metropolitan Core',
        2: 'Metropolitan High Commuting',
        3: 'Metropolitan Low Commuting',
        4: 'Micropolitan Core',
        5: 'Micropolitan High Commuting',
        6: 'Micropolitan Low Commuting',
        7: 'Small Town Core',
        8: 'Small Town High Commuting',
        9: 'Small Town Low Commuting',
        10: 'Rural'
    }
}

# Mapping of coeftest files to their original data files
coeftest_to_data_mapping = {
    'basic_analysis_coeftest.csv': 'basic_analysis.csv',
    'basic_plus_analysis_coeftest.csv': 'basic_plus_analysis.csv',
    'basic_plus_clinical_analysis_coeftest.csv': 'basic_plus_clinical_analysis.csv',
    'basic_plus_clinical_sdh_analysis_coeftest.csv': 'basic_plus_clinical_sdh_analysis.csv',
    'X_basic_plus_clin_sdh_location_encoded_coeftest.csv': 'X_basic_plus_clin_sdh_location_encoded.csv'
}

# Mapping of coeftest files to their variable counts files
coeftest_to_counts_mapping = {
    'location_encoded_analysis_coh_coeftest.csv': 'X_location_encoded_variable_counts.csv',
    'X_basic_plus_clin_sdh_location_encoded_coeftest.csv': 'X_location_encoded_variable_counts.csv'
}


def get_variable_counts(var_name, counts_df=None):
    """
    Get counts for a variable from the variable counts dataframe.
    If counts_df is provided, look up the variable name and return the count.
    
    Parameters
    ----------
    var_name : str
        The variable name to look up
    counts_df : pd.DataFrame, optional
        DataFrame with 'Variable' and 'Count' columns
    
    Returns
    -------
    int or None
        The count for the variable, or None if not found
    """
    var_name_str = str(var_name)
    
    # Handle intercept and special cases
    if var_name_str in ['(Intercept)', 'pid']:
        return None
    
    # If no counts dataframe provided, return None
    if counts_df is None:
        return None
    
    # Look up the variable in the counts dataframe
    matching_rows = counts_df[counts_df['Variable'] == var_name_str]
    if not matching_rows.empty:
        # Return the count from the 'Count' column
        count_col = 'Count' if 'Count' in counts_df.columns else 'Non-Null_Count'
        return int(matching_rows.iloc[0][count_col])
    
    return None


def decode_variable_name(var_name):
    """
    Decode variable names using the data dictionary for human-readable output.
    Handles categorical variables (e.g., 'race_2.0' -> 'Race: Black'),
    continuous variables (e.g., 'RPL_THEMES' -> 'Overall SVI Percentile'),
    and special cases (e.g., '(Intercept)' -> 'Intercept').
    
    Parameters
    ----------
    var_name : str or int
        The variable name to decode
    
    Returns
    -------
    str
        The decoded variable name
    """
    # Handle special variables
    if var_name == '(Intercept)':
        return 'Intercept'
    if var_name == 'pid':
        return 'Participant ID'
    if var_name == 'snr':
        return 'Signal-to-Noise Ratio (SNR)'
    if var_name == 'pred_mos':
        return 'Predicted MOS'
    if var_name == 'pause_proportion':
        return 'Pause Proportion'
    
    
    # Handle response variables
    if isinstance(var_name, str):
        if var_name == 'wer':
            return 'Word Error Rate (WER)'
        if var_name == 'log_wer':
            return 'Log Word Error Rate'
        if var_name == 'sentCoherenceSentBertCumulativeCentroid':
            return 'Sentence Coherence (SentBERT)'
        
        # Handle SVI/RPL_THEME variables (continuous percentile ranks)
        if var_name == 'RPL_THEMES':
            return 'Overall SVI Percentile'
        if var_name == 'RPL_THEME1':
            return 'SVI: Socioeconomic Status'
        if var_name == 'RPL_THEME2':
            return 'SVI: Household Composition'
        if var_name == 'RPL_THEME3':
            return 'SVI: Minority Status/Language'
        if var_name == 'RPL_THEME4':
            return 'SVI: Housing/Transportation'

        # Handle the boolean SVI high vulnerability flags per RLP_THEME
        if var_name == 'svi_theme1_high':
            return 'High SVI: Socioeconomic Status'
        if var_name == 'svi_theme2_high':
            return 'High SVI: Household Composition'
        if var_name == 'svi_theme3_high':
            return 'High SVI: Minority Status/Language'
        if var_name == 'svi_theme4_high':
            return 'High SVI: Housing/Transportation'

        # Handle SVI category variables
        if var_name == 'svi_categoryLow Vulnerability':
            return 'SVI Overall: Low Vulnerability'
        if var_name == 'svi_categoryMedium Vulnerability':
            return 'SVI Overall: Medium Vulnerability'

        # Handle healthcare access
        if var_name == 'healthcare_access_categoryLow Healthcare Access':
            return 'Low Healthcare Access'
        if var_name == 'healthcare_access_categoryMedium Healthcare Access':
            return 'Medium Healthcare Access'
        if var_name == 'healthcare_access_score':
            return 'Healthcare Access Score'

        # Handle resource access
        if var_name == 'resource_access_categoryLow Resource Access':
            return 'Low Resource Access'
        if var_name == 'resource_access_categoryMedium Resource Access':
            return 'Medium Resource Access'
        if var_name == 'resource_access_score':
            return 'Resource Access Score'
        if var_name == 'low_resource_access':
            return 'Low Resource Access'
        if var_name == 'low_healthcare_access':
            return 'Low Healthcare Access'

        # Handle urban/rural categories
        if var_name == 'urban_rural_LargeRuralTrue':
            return 'Large Rural'
        if var_name == 'urban_rural_SmallTownRuralTrue':
            return 'Small Town Rural'
        if var_name == 'urban_rural_SuburbanTrue':
            return 'Suburban'
        if var_name == 'is_urban':
            return 'is_urban'
        if var_name == 'urban_rural_categorySmallTownRural':
            return 'Small Town Rural'
        if var_name == 'urban_rural_categorySuburban':
            return 'Suburban'
        if var_name == 'urban_rural_categoryUnknown':
            return 'Unknown Urban/Rural Category'
        if var_name == 'urban_rural_categoryUrbanCore':
            return 'Urban Core'

        # Handle cluster
        if var_name == 'cluster':
            return 'cluster'
        
        # Handle clinical measures
        if 'phq9_high' in var_name.lower():
            return 'PHQ-9 Total High'
        if 'phq9_9_suicidal.thoughts' in var_name.lower() or 'phq9-9_suicidal.thoughts' in var_name.lower() or 'phq9_9-suicidal.thoughts' in var_name.lower():
            return 'PHQ-9 Suicidal Thoughts'
        if 'phq9-total' in var_name.lower() or 'phq9.total' in var_name.lower():
            return 'PHQ-9 Total'

        if 'hpsvq' in var_name.lower():
            return 'HPSVQ Total'
        if 'scl9_moderate' in var_name.lower() or 'scl9-moderate' in var_name.lower():
            return 'SCL-9 Moderate Distress (≥1.0)'
        if 'scl9_high' in var_name.lower() or 'scl9-high' in var_name.lower():
            return 'SCL-9 High Distress (≥1.7)'
        if 'scl' in var_name.lower():
            return 'SCL-9 Global Score'
        if 'sds_high' in var_name.lower() or 'sds-high' in var_name.lower() or 'sds.high' in var_name.lower():
            return 'Sheehan Disability Scale High > 21'
        
        if 'dx_group_smi' in var_name.lower() or 'dx.group.smi' in var_name.lower():
            return 'Serious Mental Illness (SMI) Diagnosis'
        if 'dx_group_substance' in var_name.lower() or 'dx.group.substance' in var_name.lower():
            return 'Substance Use Disorder Diagnosis'
        if 'dx_group_ptsd' in var_name.lower() or 'dx.group.ptsd' in var_name.lower():
            return 'Post-Traumatic Stress Disorder (PTSD) Diagnosis'
        if 'dx_group_neuro_med' in var_name.lower() or 'dx.group.neuro_med' in var_name.lower():
            return 'Neurological Diagnosis'
        
        # Handle substance use
        if 'opioids-opiates' in var_name.lower() or 'opioids_opiates_1.0' in var_name.lower() or 'opioids.opiates' in var_name.lower():
            return 'Opioids or Opiates Use'
        if var_name == 'all_types_drug_use':
            return 'Any Types of Drug Use (non-Rx)'
        if var_name == 'all_types_drug_use_1.0':
            return 'Any Types of Drug Use (non-Rx)'
        if var_name == 'marijuana':
            return 'Marijuana Use'
        if var_name == 'alcohol':
            return 'Alcohol Use'
        if var_name == 'cocaine':
            return 'Cocaine Use'
        if var_name == 'nicotine':
            return 'Nicotine Use'
        if var_name == 'meth':
            return 'Methamphetamine Use'
        if var_name == 'ketamine':
            return 'Ketamine Use'
        if var_name == 'steroids':
            return 'Steroids Use'
        if var_name == 'acid':
            return 'LSD Use'
        if 'bath-salts' in var_name or 'bath_salts' in var_name:
            return 'Bath Salts Use'
        
        # Handle POI (Point of Interest) counts
        if '_count' in var_name:
            base_name = var_name.replace('_count', '').replace('_', ' ').title()
            return f'{base_name} Count'
        
        # Handle cluster_id
        if var_name == 'cluster_id':
            return 'Geographic Cluster ID'

    # Parse categorical variables (e.g., 'race_2.0' -> 'race', 2; 'binned_age_3.0' -> 'binned_age', 3)
    # Convert to a string for robustness, some variable names were coming through as int which can't take a .split
    var_name = str(var_name)
    parts = var_name.split('_')
    if len(parts) >= 2:
        # Join all but the last part for the category (handles binned_age, etc.)
        category = '_'.join(parts[:-1]).replace('-', '_')
        try:
            value = float(parts[-1])
            if category in data_dictionary:
                decoded = data_dictionary[category].get(int(value), var_name)
                return f"{category.replace('_', ' ').title()}: {decoded}"
        except:
            pass

    return var_name
