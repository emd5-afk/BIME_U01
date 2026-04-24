"""
Extract statistical features from pause times.
Produces 6 features: max, min, mean, median, length, pause_proportion
"""
import pandas as pd
import numpy as np
import ast
from typing import List, Union


def extract_time_diffs(parsed_entries: List[dict]) -> List[float]:
    """
    Extract pause times (time differences between utterances).
    
    Args:
        parsed_entries: List of dicts with 'start' and 'end' keys
    
    Returns:
        List of pause durations (start[i] - end[i-1])
    """
    if not parsed_entries or len(parsed_entries) < 2:
        return []
    return [parsed_entries[i]['start'] - parsed_entries[i - 1]['end'] 
            for i in range(1, len(parsed_entries))]


def calculate_pause_proportion(time_diffs: List[float], total_duration: float = None) -> float:
    """
    Calculate proportion of time spent in pauses.
    
    Args:
        time_diffs: List of pause durations
        total_duration: Total speech duration (if None, use sum of pauses + arbitrary speech time)
    
    Returns:
        Pause proportion (0-1)
    """
    if not time_diffs:
        return 0.0
    total_pause = sum(time_diffs)
    if total_duration is None or total_duration == 0:
        return 0.0
    return total_pause / total_duration


def extract_time_stats(
    df: pd.DataFrame,
    time_col: str = 'time',
    file_col: str = 'file',
    parse_time: bool = True,
    dataset: str = 'avh'
) -> pd.DataFrame:
    """
    Extract 6 statistical features from pause times.
    
    Args:
        df: DataFrame with time data
        time_col: Column containing time info (list of dicts or already parsed)
        file_col: Column with file identifiers
        parse_time: Whether to parse time column from string
        dataset: Dataset type for segment handling
    
    Returns:
        DataFrame with columns: max, min, mean_y, median_y, length, pause_proportion, file
    """
    df = df.copy()
    
    # Parse time column if needed
    if parse_time and df[time_col].dtype == object:
        try:
            df['parsed_time'] = df[time_col].apply(ast.literal_eval)
        except:
            df['parsed_time'] = df[time_col]
    else:
        df['parsed_time'] = df[time_col]
    
    # Handle TOPSY segments
    if dataset == 'topsy' and 'Segment_1_pause_times' in df.columns:
        melted_df = df.melt(
            id_vars=["file"],
            value_vars=["Segment_1_pause_times", "Segment_2_pause_times", "Segment_3_pause_times"],
            var_name="segment",
            value_name="time_diffs"
        )
        melted_df["file_segment"] = melted_df["file"] + "_" + melted_df["segment"].str.replace("_pause_times", "")
        df = melted_df[["file_segment", "time_diffs"]].rename(columns={"file_segment": "file"})
    else:
        # Extract time differences
        df['time_diffs'] = df['parsed_time'].apply(extract_time_diffs)
    
    # Calculate statistics
    df_stats = pd.DataFrame({
        'max': df['time_diffs'].apply(lambda x: np.max(x) if len(x) > 0 else np.nan),
        'min': df['time_diffs'].apply(lambda x: np.min(x) if len(x) > 0 else np.nan),
        'mean_y': df['time_diffs'].apply(lambda x: np.mean(x) if len(x) > 0 else np.nan),
        'median_y': df['time_diffs'].apply(lambda x: np.median(x) if len(x) > 0 else np.nan),
        'length': df['time_diffs'].apply(len),
        'file': df[file_col]
    }).fillna(0)
    
    # Calculate pause proportion (sum of pauses / total duration if available)
    if 'duration' in df.columns:
        df_stats['pause_proportion'] = df.apply(
            lambda row: calculate_pause_proportion(row['time_diffs'], row['duration']), axis=1
        )
    else:
        # Approximate: pause_proportion as sum of pauses / (sum of pauses + estimated speech)
        df_stats['pause_proportion'] = df['time_diffs'].apply(
            lambda x: sum(x) / (sum(x) + len(x) * 1.0) if len(x) > 0 else 0
        )
    
    return df_stats


def save_time_stats(df_stats: pd.DataFrame, output_path: str):
    """Save time stats to CSV."""
    df_stats.to_csv(output_path, index=False)
    print(f"Saved time stats ({df_stats.shape}) to {output_path}")