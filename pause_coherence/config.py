"""
Configuration file for coherence models across different datasets.
"""
from dataclasses import dataclass
from typing import List, Optional

# Feature columns
STATS_FEATURES: List[str] = ['max', 'min', 'mean_y', 'median_y', 'length', 'pause_proportion']
N_COHERENCE_FEATURES: int = 764

# Coherence keys for different embedding methods
COHERENCE_KEYS: List[str] = [
    'sentCoherenceSeq', 'sentCoherenceStaticCentroid', 'sentCoherenceCumulativeCentroid',
    'sentCoherenceWeightedSeq', 'sentCoherenceWeightedStaticCentroid', 'sentCoherenceWeightedCumulativeCentroid',
    'sentCoherenceBertSumSeq', 'sentCoherenceBertSumStaticCentroid', 'sentCoherenceBertSumCumulativeCentroid',
    'sentCoherenceBert2ndLayerSeq', 'sentCoherenceBert2ndLayerStaticCentroid', 'sentCoherenceBert2ndLayerCumulativeCentroid',
    'sentCoherenceBertClsSeq', 'sentCoherenceBertClsStaticCentroid', 'sentCoherenceBertClsCumulativeCentroid',
    'sentCoherenceSentBertSeq', 'sentCoherenceSentBertStaticCentroid', 'sentCoherenceSentBertCumulativeCentroid',
    'sentCoherenceSimCSESeq', 'sentCoherenceSimCSEStaticCentroid', 'sentCoherenceSimCSECumulativeCentroid',
    'sentCoherenceDiffCSESeq', 'sentCoherenceDiffCSEStaticCentroid', 'sentCoherenceDiffCSECumulativeCentroid'
]


@dataclass
class DatasetConfig:
    """Configuration for a specific dataset."""
    name: str
    feature_dict_path: str
    time_stats_path: str
    baseline_path: str
    target_column: str
    auc_threshold: float
    task_filter: Optional[str] = None  # For filtering by task (e.g., 'Dream')
    file_column: str = 'file'
    remove_transcript_suffix: bool = False  # For TOPSY
    

# Dataset configurations
TANG_CONFIG = DatasetConfig(
    name='tang',
    feature_dict_path='/<path_to_tang>/featureDict_nltk_split_whisperx.pkl',
    time_stats_path='/<path_to_tang>/tang_pause_time_stats_with_pause_proportion.csv',
    baseline_path='/<path_to_tang>/tang_baseline.csv',
    target_column='tlc_global',
    auc_threshold=3.0,
    task_filter='Dream'
)

TOPSY_CONFIG = DatasetConfig(
    name='topsy',
    feature_dict_path='/<path_to_topsy>/featureDict_nltk_split_3segments.pkl',
    time_stats_path='/<path_to_topsy>/topsy_time_stats_with_pause_proportion_3segments.csv',
    baseline_path='/<path_to_topsy>/segmented_topsy_baseline.csv',
    target_column='TLIDITGDIT',
    auc_threshold=0.75,
    task_filter=None,
    remove_transcript_suffix=True
)

AVH_CONFIG = DatasetConfig(
    name='avh',
    feature_dict_path='/<path_to_avh>/tald_featureDict_nltk_split_whisperx_310.pkl',
    time_stats_path='/<path_to_avh>/tald_pause_time_stats.csv',
    baseline_path='/<path_to_avh>/avh_tald_310.jsonl',
    target_column='numscores',
    auc_threshold=3.0,
    task_filter=None
)