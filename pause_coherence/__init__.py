"""
Coherence Models Package

A reproducible package for coherence-based prediction models
across Tang, TOPSY, and AVH datasets.
"""
from .config import (
    TANG_CONFIG,
    TOPSY_CONFIG,
    AVH_CONFIG,
    COHERENCE_KEYS,
    STATS_FEATURES
)
from .models import BaseCoherenceModel, ModelResults, CrossDatasetModel, CrossDatasetResults

__version__ = '0.1.0'
__all__ = [
    'BaseCoherenceModel',
    'ModelResults',
    'CrossDatasetModel',
    'CrossDatasetResults',
    'TANG_CONFIG',
    'TOPSY_CONFIG',
    'AVH_CONFIG',
    'COHERENCE_KEYS',
    'STATS_FEATURES'
]