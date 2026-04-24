"""
Utility functions for coherence models.
"""
import numpy as np
import pandas as pd
from pathlib import Path
from typing import Tuple, Optional, List


def split_file_name(file_name: str) -> Tuple[float, str]:
    """
    Splits the file name into 'file' (number) and 'task' (task name).
    Used for Tang dataset.
    
    Args:
        file_name: The file name string to parse
        
    Returns:
        Tuple of (file_number, task_name)
    """
    parts = file_name.split('_')
    file_number = float(parts[1])
    task_name = parts[-2] if len(parts) >= 3 else None
    return file_number, task_name


def load_feature_dict(path: str, key: str) -> pd.DataFrame:
    """
    Load a feature dictionary pickle file and extract a specific key.
    
    Args:
        path: Path to the pickle file
        key: Key to extract from the dictionary
        
    Returns:
        DataFrame with coherence features
    """
    feature_dict = pd.read_pickle(path)
    df = feature_dict.get(key)
    if df is None:
        raise KeyError(f"Key '{key}' not found in feature dictionary")
    df = df.iloc[:, :765].copy()
    df.columns = [col.replace("cos__", "") for col in df.columns]
    return df


def preprocess_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    """
    Handle missing values and infinity values in DataFrame.
    
    Args:
        df: Input DataFrame
        
    Returns:
        Preprocessed DataFrame
    """
    df = df.fillna(0)
    df = df.replace([np.inf], 1)
    df = df.replace([-np.inf], 0)
    return df


def binarize_target(y: np.ndarray, threshold: float) -> np.ndarray:
    """
    Binarize target values based on threshold for AUC calculation.
    
    Args:
        y: Target values
        threshold: Threshold for binary classification
        
    Returns:
        Binary array (1 if value >= threshold, else 0)
    """
    return (y >= threshold).astype(int)

# Add to utils.py after existing functions

def extract_subject_id_avh(file_name: str) -> str:
    """
    Extract subject ID from AVH file name.
    Example: 'u00000509@avh-20180723-1' -> '509'
    
    Args:
        file_name: AVH file name
        
    Returns:
        Subject ID as string
    """
    # Get part before @, remove leading 'u' and leading zeros
    subject_part = file_name.split('@')[0]
    subject_id = subject_part.lstrip('u').lstrip('0')
    return subject_id if subject_id else '0'


def extract_subject_id_topsy(file_name: str) -> str:
    """
    Extract subject ID from TOPSY file name.
    Example: 'TOPSY_001_Segment_1' -> 'TOPSY_001'
    
    Args:
        file_name: TOPSY file name
        
    Returns:
        Subject ID (participant ID without segment)
    """
    # Get parts before _Segment
    parts = file_name.split('_Segment')[0]
    return parts


def extract_subject_id_tang(file_name: float) -> str:
    """
    Extract subject ID from Tang file name.
    For Tang, each file is already one subject for Dream task.
    
    Args:
        file_name: Tang file number (float)
        
    Returns:
        Subject ID as string
    """
    return str(int(file_name))


def get_subject_ids(file_names: List, dataset_name: str) -> np.ndarray:
    """
    Get subject IDs from file names based on dataset.
    
    Args:
        file_names: List of file names
        dataset_name: 'avh', 'topsy', or 'tang'
        
    Returns:
        Array of subject IDs
    """
    if dataset_name == 'avh':
        return np.array([extract_subject_id_avh(f) for f in file_names])
    elif dataset_name == 'topsy':
        return np.array([extract_subject_id_topsy(f) for f in file_names])
    elif dataset_name == 'tang':
        return np.array([extract_subject_id_tang(f) for f in file_names])
    else:
        # Default: treat each file as a subject
        return np.array([str(i) for i in range(len(file_names))])