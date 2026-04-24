"""
Extract tsfresh features from pause times.
Produces 764 features after removing length-related features.
"""
import pandas as pd
import numpy as np
from tsfresh import extract_features
from typing import List

# Features to remove (related to length, duplicates, counts)
RMLIST = [
    'sum_of_reoccurring_values', 
    'value_count__value_0', 
    'number_peaks__n_3', 
    'number_peaks__n_1', 
    'length', 
    'has_duplicate', 
    'range_count__max_1000000000000.0__min_0', 
    'number_peaks__n_5', 
    'number_cwt_peaks__n_5', 
    'sum_values', 
    'abs_energy', 
    'value_count__value_1', 
    'range_count__max_1__min_-1', 
    'has_duplicate_min', 
    'ratio_value_number_to_time_series_length', 
    'count_above_mean', 
    'number_cwt_peaks__n_1', 
    'count_below_mean', 
    'has_duplicate_max', 
    'number_peaks__n_10', 
    'sum_of_reoccurring_data_points', 
    'range_count__max_0__min_-1000000000000.0', 
    'value_count__value_-1', 
    'number_peaks__n_50', 
    'absolute_sum_of_changes'
]


def extract_time_tsfresh(
    df: pd.DataFrame,
    time_diffs_col: str = 'time_diffs',
    file_col: str = 'file'
) -> pd.DataFrame:
    """
    Extract tsfresh features from pause time sequences.
    
    Args:
        df: DataFrame with time_diffs column (list of pause durations per file)
        time_diffs_col: Column containing list of pause times
        file_col: Column with file identifiers
    
    Returns:
        DataFrame with 764 tsfresh features + file column
    """
    # Explode time_diffs to long format for tsfresh
    exploded_df = df.explode(time_diffs_col).reset_index()
    exploded_df['id'] = exploded_df[file_col]
    exploded_df['time'] = exploded_df.groupby(file_col).cumcount()
    
    # Convert to numeric, drop NaN
    exploded_df[time_diffs_col] = pd.to_numeric(exploded_df[time_diffs_col], errors='coerce')
    exploded_df = exploded_df.dropna(subset=[time_diffs_col])
    
    # Extract tsfresh features
    print("Extracting tsfresh features for pause times...")
    extracted_features = extract_features(
        exploded_df[['id', 'time', time_diffs_col]],
        column_id='id',
        column_sort='time',
        disable_progressbar=False
    )
    
    # Reset index to get file column
    extracted_features = extracted_features.reset_index()
    extracted_features = extracted_features.rename(columns={'index': file_col})
    
    # Remove length-related features
    cols_to_drop = [col for col in RMLIST if col in extracted_features.columns]
    filtered_features = extracted_features.drop(columns=cols_to_drop, errors='ignore')
    
    # Handle NaN and inf
    filtered_features = filtered_features.fillna(0)
    filtered_features = filtered_features.replace([np.inf, -np.inf], 0)
    
    print(f"Extracted {filtered_features.shape[1] - 1} features (after removing {len(cols_to_drop)} length-related features)")
    
    return filtered_features


def save_time_tsfresh(df: pd.DataFrame, output_path: str):
    """Save tsfresh features to CSV."""
    df.to_csv(output_path, index=False)
    print(f"Saved time tsfresh features ({df.shape}) to {output_path}")