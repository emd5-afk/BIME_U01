"""
Extract coherence features using coherencecalculator pipelines.
Produces featureDict with 764 features per coherence key.
"""
import pandas as pd
import pickle
from typing import Optional

# Import coherence calculator pipelines
from coherencecalculator.pipelines.timeseries import timeseries
from coherencecalculator.pipelines.features import features
from coherencecalculator.pipelines.tardis import tardis
from coherencecalculator.pipelines.agg import agg
from coherencecalculator.tools.vecloader import VecLoader


def load_transcript_data(file_path: str, dataset: str = 'avh') -> pd.DataFrame:
    """
    Load transcript data from file.
    
    Args:
        file_path: Path to transcript file (csv, pkl, or jsonl)
        dataset: Dataset type ('avh', 'topsy', 'tang')
    
    Returns:
        DataFrame with 'file' and 'transcript' columns
    """
    if file_path.endswith('.pkl'):
        df = pd.read_pickle(file_path)
    elif file_path.endswith('.jsonl'):
        df = pd.read_json(file_path, lines=True)
    else:
        df = pd.read_csv(file_path)
    
    # Handle TOPSY segments if needed
    if dataset == 'topsy' and 'Segment_1_transcript' in df.columns:
        melted_df = df.melt(
            id_vars=["file"],
            value_vars=["Segment_1_transcript", "Segment_2_transcript", "Segment_3_transcript"],
            var_name="segment",
            value_name="transcript"
        )
        melted_df["file_segment"] = melted_df["file"] + "_" + melted_df["segment"].str.replace("_transcript", "")
        df = melted_df[["file_segment", "transcript"]].rename(columns={"file_segment": "file"})
    
    return df


def extract_coherence_features(
    df: pd.DataFrame,
    text_col: str = 'transcript',
    file_col: str = 'file',
    split_type: str = 'nltk',
    vecs: Optional[VecLoader] = None
) -> dict:
    """
    Extract coherence features using coherencecalculator.
    
    Args:
        df: DataFrame with transcript data
        text_col: Column name containing text (use 'text_list' for whisper split)
        file_col: Column name containing file identifiers
        split_type: 'nltk' for sentence split, 'whisper' for whisperx segments
        vecs: VecLoader instance (will create one if None)
    
    Returns:
        featureDict: Dictionary with coherence keys and their feature DataFrames
    """
    if vecs is None:
        print("Loading vectors...")
        vecs = VecLoader()
    
    # For whisper split, use text_list column (list of segments)
    if split_type == 'whisper' and 'text_list' not in df.columns:
        raise ValueError("For whisper split, df must have 'text_list' column with list of segments")
    
    actual_text_col = 'text_list' if split_type == 'whisper' else text_col
    
    # Generate time series
    print(f"Generating time series for {split_type} split...")
    tsDf = timeseries(vecLoader=vecs, inputDf=df, fileCol=file_col, textCol=actual_text_col)
    
    # Generate features (tsfresh-based, 764 features per coherence key)
    print("Extracting tsfresh features...")
    featureDict = features(vecLoader=vecs, inputTimeseries=tsDf)
    
    # Clean up column names and limit to 764 features + file
    for key in featureDict:
        feat_df = featureDict[key].iloc[:, :765]  # 764 features + file column
        feat_df.columns = [col.replace("cos__", "") for col in feat_df.columns]
        featureDict[key] = feat_df
    
    print(f"Extracted features for {len(featureDict)} coherence keys")
    return featureDict


def save_feature_dict(featureDict: dict, output_path: str):
    """Save featureDict to pickle file."""
    with open(output_path, 'wb') as f:
        pickle.dump(featureDict, f)
    print(f"Saved featureDict to {output_path}")


def compute_tardis_scores(featureDict: dict, vecs: Optional[VecLoader] = None) -> pd.DataFrame:
    """Compute final TARDIS coherence scores."""
    if vecs is None:
        vecs = VecLoader()
    
    tardisResult = tardis(vecLoader=vecs, inputFeatures=featureDict)
    return tardisResult