"""
Base model class for coherence prediction with Leave-One-Subject-Out CV.
Includes all 8 model approaches.

Uses LOSO to prevent data leakage (no transcripts from test subject in training)
while evaluating at transcript level (not averaging predictions per subject).
"""
import numpy as np
import pandas as pd
from sklearn.svm import SVR, LinearSVR
from sklearn.linear_model import Ridge, ElasticNet
from sklearn.ensemble import RandomForestRegressor
from sklearn.cross_decomposition import PLSRegression
from sklearn.model_selection import LeaveOneGroupOut
from sklearn.preprocessing import StandardScaler, MinMaxScaler
from sklearn.metrics import mean_squared_error, roc_auc_score, average_precision_score, mean_absolute_error
from scipy.stats import spearmanr
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from sklearn.feature_selection import SelectKBest, f_regression

from ..config import STATS_FEATURES, N_COHERENCE_FEATURES

MODEL_TYPES = {
    'svr': SVR,
    'linear_svr': LinearSVR,
    'ridge': Ridge,
    'elastic_net': ElasticNet,
    'random_forest': RandomForestRegressor,
    'pls': PLSRegression
}
@dataclass
class ModelResults:
    """Container for model evaluation results."""
    key: str
    model_type: str
    #mse: float
    mae: float
    spearman_corr: float
    p_value: float
    auc: float
    auprc: float
    predictions: np.ndarray
    true_values: np.ndarray
    file_names: List[str]
    subject_ids: np.ndarray


class BaseCoherenceModel:
    """
    Base class for coherence prediction models.
    Implements Leave-One-Subject-Out CV with transcript-level evaluation.
    
    LOSO ensures no data leakage: when testing on a subject's transcripts,
    ALL transcripts from that subject are excluded from training.
    Evaluation is done at transcript level (not averaged per subject).
    
    Supports 8 approaches:
    1. time_stats_only - 6 statistical features only
    2. time_featuredict_only - 764 TSFRESH features only
    3. coherence_nltk_only - 764 coherence features (NLTK split)
    4. coherence_whisper_only - 764 coherence features (Whisper split)
    5. early_fusion_stats - concatenate time stats + coherence (770 features)
    6. early_fusion_featuredict - concatenate time featuredict + coherence (1528 features)
    7. late_fusion_stats - average predictions from time stats SVR + coherence SVR
    8. late_fusion_featuredict - average predictions from time featuredict SVR + coherence SVR
    """
    
    def __init__(self, auc_threshold: float, dataset_name: str, model_type: str, n_features: int):
        self.auc_threshold = auc_threshold
        self.dataset_name = dataset_name
        self.model_type = model_type
        self.n_features = n_features
        
        if model_type not in MODEL_TYPES:
            raise ValueError(f"model_type must be one of {list(MODEL_TYPES.keys())}, got '{model_type}'")
    
    def _get_model(self):
        """Return a new instance of the selected model type."""
        model_class = MODEL_TYPES[self.model_type]
        if self.model_type == 'linear_svr':
            return model_class(max_iter=10000, random_state=42)
        elif self.model_type == 'elastic_net':
            return model_class(max_iter=10000, selection="random", random_state=42)
        elif self.model_type == 'random_forest':
            return model_class(n_estimators=100, max_features="sqrt", random_state=42)
        elif self.model_type == 'pls':
            return model_class(n_components=5)
        return model_class()

    def _select_features(self, X_train, X_test, y_train):
        """Apply feature selection if n_features is set."""
        if self.n_features is None or self.n_features >= X_train.shape[1]:
            return X_train, X_test
        
        selector = SelectKBest(score_func=f_regression, k=self.n_features)
        X_train_selected = selector.fit_transform(X_train, y_train)
        X_test_selected = selector.transform(X_test)
        return X_train_selected, X_test_selected

    def _get_subject_ids(self, file_names: List) -> np.ndarray:
        """Extract subject IDs from file names based on dataset."""
        from ..utils import get_subject_ids
        return get_subject_ids(file_names, self.dataset_name)
    
    # ========== APPROACH 1: Time Stats Only ==========
    def train_time_stats_only(
        self,
        merged_df: pd.DataFrame,
        target_column: str
    ) -> ModelResults:
        """Train model using only 6 time statistical features with LOSO CV."""
        X_raw = merged_df[STATS_FEATURES].values
        y = merged_df[target_column].values
        file_names = merged_df['file'].tolist()
        subject_ids = self._get_subject_ids(file_names)
        
        logo = LeaveOneGroupOut()
        predictions = []
        true_values = []
        pred_files = []
        pred_subjects = []
        
        for train_index, test_index in logo.split(X_raw, y, groups=subject_ids):
            X_train, X_test = X_raw[train_index], X_raw[test_index]
            y_train, y_test = y[train_index], y[test_index]
            
            scaler = MinMaxScaler()
            X_train_scaled = scaler.fit_transform(X_train)
            X_test_scaled = scaler.transform(X_test)

            X_train_selected, X_test_selected = self._select_features(
                X_train_scaled, X_test_scaled, y_train
            )
            model = self._get_model()
            model.fit(X_train_selected, y_train)
            y_pred = model.predict(X_test_selected)
            
            # Keep transcript-level predictions (LOSO prevents leakage)
            predictions.extend(y_pred.tolist())
            true_values.extend(y_test.tolist())
            pred_files.extend([file_names[i] for i in test_index])
            pred_subjects.extend([subject_ids[i] for i in test_index])
        
        return self._compute_metrics(predictions, true_values, pred_files, 
                                     np.array(pred_subjects),
                                     key='time_stats', model_type='time_stats_only')
    
    # ========== APPROACH 2: Time FeatureDict Only ==========
    def train_time_featuredict_only(
        self,
        time_df: pd.DataFrame,
        target_column: str
    ) -> ModelResults:
        """Train model using only 764 TSFRESH time features with LOSO CV."""
        X_raw = time_df.iloc[:, :N_COHERENCE_FEATURES].values
        y = time_df[target_column].values
        file_names = time_df['file'].tolist()
        subject_ids = self._get_subject_ids(file_names)
        
        logo = LeaveOneGroupOut()
        predictions = []
        true_values = []
        pred_files = []
        pred_subjects = []
        
        for train_index, test_index in logo.split(X_raw, y, groups=subject_ids):
            X_train, X_test = X_raw[train_index], X_raw[test_index]
            y_train, y_test = y[train_index], y[test_index]
            
            scaler = MinMaxScaler()
            X_train_scaled = scaler.fit_transform(X_train)
            X_test_scaled = scaler.transform(X_test)
                # Step 2: Feature selection (if enabled)
            X_train_selected, X_test_selected = self._select_features(
                X_train_scaled, X_test_scaled, y_train
            )
            
            model = self._get_model()
            model.fit(X_train_selected, y_train)
            y_pred = model.predict(X_test_selected)
            
            # Keep transcript-level predictions (LOSO prevents leakage)
            predictions.extend(y_pred.tolist())
            true_values.extend(y_test.tolist())
            pred_files.extend([file_names[i] for i in test_index])
            pred_subjects.extend([subject_ids[i] for i in test_index])
        
        return self._compute_metrics(predictions, true_values, pred_files,
                                     np.array(pred_subjects),
                                     key='time_featuredict', model_type='time_featuredict_only')
    
    # ========== APPROACH 3 & 4: Coherence Only (NLTK/Whisper) ==========
    def train_coherence_only(
        self,
        merged_df: pd.DataFrame,
        target_column: str,
        split_type: str = 'nltk'
    ) -> ModelResults:
        """Train model using only 764 coherence features with LOSO CV."""
        X_raw = merged_df.iloc[:, :N_COHERENCE_FEATURES].values
        y = merged_df[target_column].values
        file_names = merged_df['file'].tolist()
        subject_ids = self._get_subject_ids(file_names)
        
        logo = LeaveOneGroupOut()
        predictions = []
        true_values = []
        pred_files = []
        pred_subjects = []
        
        for train_index, test_index in logo.split(X_raw, y, groups=subject_ids):
            X_train, X_test = X_raw[train_index], X_raw[test_index]
            y_train, y_test = y[train_index], y[test_index]
            
            scaler = MinMaxScaler()
            X_train_scaled = scaler.fit_transform(X_train)
            X_test_scaled = scaler.transform(X_test)

            X_train_selected, X_test_selected = self._select_features(
                X_train_scaled, X_test_scaled, y_train
            )
            model = self._get_model()
            model.fit(X_train_selected, y_train)
            y_pred = model.predict(X_test_selected)
            
            # Keep transcript-level predictions (LOSO prevents leakage)
            predictions.extend(y_pred.tolist())
            true_values.extend(y_test.tolist())
            pred_files.extend([file_names[i] for i in test_index])
            pred_subjects.extend([subject_ids[i] for i in test_index])
        
        return self._compute_metrics(predictions, true_values, pred_files,
                                     np.array(pred_subjects),
                                     key=f'coherence_{split_type}', 
                                     model_type=f'coherence_{split_type}_only')
    
    # ========== APPROACH 5: Early Fusion - Concatenate Time Stats ==========
    def train_early_fusion_stats(
        self,
        merged_df: pd.DataFrame,
        target_column: str
    ) -> ModelResults:
        """Train model with concatenated coherence + time stats using LOSO CV."""
        X_coherence = merged_df.iloc[:, :N_COHERENCE_FEATURES].values
        X_stats = merged_df[STATS_FEATURES].values
        X_raw = np.hstack([X_coherence, X_stats])
        y = merged_df[target_column].values
        file_names = merged_df['file'].tolist()
        subject_ids = self._get_subject_ids(file_names)
        
        logo = LeaveOneGroupOut()
        predictions = []
        true_values = []
        pred_files = []
        pred_subjects = []
        
        for train_index, test_index in logo.split(X_raw, y, groups=subject_ids):
            X_train, X_test = X_raw[train_index], X_raw[test_index]
            y_train, y_test = y[train_index], y[test_index]
            
            scaler = MinMaxScaler()
            X_train_scaled = scaler.fit_transform(X_train)
            X_test_scaled = scaler.transform(X_test)

            X_train_selected, X_test_selected = self._select_features(
                X_train_scaled, X_test_scaled, y_train
            )
            model = self._get_model()
            model.fit(X_train_selected, y_train)
            y_pred = model.predict(X_test_selected)
            
            # Keep transcript-level predictions (LOSO prevents leakage)
            predictions.extend(y_pred.tolist())
            true_values.extend(y_test.tolist())
            pred_files.extend([file_names[i] for i in test_index])
            pred_subjects.extend([subject_ids[i] for i in test_index])
        
        return self._compute_metrics(predictions, true_values, pred_files,
                                     np.array(pred_subjects),
                                     key='early_fusion_stats', model_type='early_fusion_stats')
    
    # ========== APPROACH 6: Early Fusion - Concatenate Time FeatureDict ==========
    def train_early_fusion_featuredict(
        self,
        coherence_df: pd.DataFrame,
        time_df: pd.DataFrame,
        target_column: str
    ) -> ModelResults:
        """Train model with concatenated coherence + time featuredict using LOSO CV."""
        X_coherence = coherence_df.iloc[:, :N_COHERENCE_FEATURES].values
        X_time = time_df.iloc[:, :N_COHERENCE_FEATURES].values
        X_raw = np.hstack([X_coherence, X_time])
        y = coherence_df[target_column].values
        file_names = coherence_df['file'].tolist()
        subject_ids = self._get_subject_ids(file_names)
        
        logo = LeaveOneGroupOut()
        predictions = []
        true_values = []
        pred_files = []
        pred_subjects = []
        
        for train_index, test_index in logo.split(X_raw, y, groups=subject_ids):
            X_train, X_test = X_raw[train_index], X_raw[test_index]
            y_train, y_test = y[train_index], y[test_index]
            
            scaler = MinMaxScaler()
            X_train_scaled = scaler.fit_transform(X_train)
            X_test_scaled = scaler.transform(X_test)

            X_train_selected, X_test_selected = self._select_features(
                X_train_scaled, X_test_scaled, y_train
            )
            model = self._get_model()
            model.fit(X_train_selected, y_train)
            y_pred = model.predict(X_test_selected)
            
            # Keep transcript-level predictions (LOSO prevents leakage)
            predictions.extend(y_pred.tolist())
            true_values.extend(y_test.tolist())
            pred_files.extend([file_names[i] for i in test_index])
            pred_subjects.extend([subject_ids[i] for i in test_index])
        
        return self._compute_metrics(predictions, true_values, pred_files,
                                     np.array(pred_subjects),
                                     key='early_fusion_featuredict', 
                                     model_type='early_fusion_featuredict')
    
    # ========== APPROACH 7: Late Fusion - Average Time Stats + Coherence ==========
    def train_late_fusion_stats(
        self,
        merged_df: pd.DataFrame,
        target_column: str
    ) -> ModelResults:
        """Train two SVRs and average predictions using LOSO CV."""
        X1_raw = merged_df[STATS_FEATURES].values
        X2_raw = merged_df.iloc[:, :N_COHERENCE_FEATURES].values
        y = merged_df[target_column].values
        file_names = merged_df['file'].tolist()
        subject_ids = self._get_subject_ids(file_names)
        
        logo = LeaveOneGroupOut()
        predictions = []
        true_values = []
        pred_files = []
        pred_subjects = []
        
        for train_index, test_index in logo.split(X1_raw, y, groups=subject_ids):
            X1_train, X1_test = X1_raw[train_index], X1_raw[test_index]
            X2_train, X2_test = X2_raw[train_index], X2_raw[test_index]
            y_train, y_test = y[train_index], y[test_index]
            
            scaler1 = MinMaxScaler()
            X1_train_scaled = scaler1.fit_transform(X1_train)
            X1_test_scaled = scaler1.transform(X1_test)
            
            scaler2 = MinMaxScaler()
            X2_train_scaled = scaler2.fit_transform(X2_train)
            X2_test_scaled = scaler2.transform(X2_test)
            
            X1_train_selected, X1_test_selected = self._select_features(
                X1_train_scaled, X1_test_scaled, y_train
            )
            X2_train_selected, X2_test_selected = self._select_features(
                X2_train_scaled, X2_test_scaled, y_train
            )
            
            model1 = self._get_model()
            model1.fit(X1_train_selected, y_train)
            
            model2 = self._get_model()
            model2.fit(X2_train_selected, y_train)
            
            y1_pred = model1.predict(X1_test_selected)
            y2_pred = model2.predict(X2_test_selected)
            y_pred = (y1_pred + y2_pred) / 2
            
            # Keep transcript-level predictions (LOSO prevents leakage)
            predictions.extend(y_pred.tolist())
            true_values.extend(y_test.tolist())
            pred_files.extend([file_names[i] for i in test_index])
            pred_subjects.extend([subject_ids[i] for i in test_index])
        
        return self._compute_metrics(predictions, true_values, pred_files,
                                     np.array(pred_subjects),
                                     key='late_fusion_stats', model_type='late_fusion_stats')
    
    # ========== APPROACH 8: Late Fusion - Average Time FeatureDict + Coherence ==========
    def train_late_fusion_featuredict(
        self,
        coherence_df: pd.DataFrame,
        time_df: pd.DataFrame,
        target_column: str
    ) -> ModelResults:
        """Train two SVRs and average predictions using LOSO CV."""
        X1_raw = time_df.iloc[:, :N_COHERENCE_FEATURES].values
        X2_raw = coherence_df.iloc[:, :N_COHERENCE_FEATURES].values
        y = coherence_df[target_column].values
        file_names = coherence_df['file'].tolist()
        subject_ids = self._get_subject_ids(file_names)
        
        logo = LeaveOneGroupOut()
        predictions = []
        true_values = []
        pred_files = []
        pred_subjects = []
        
        for train_index, test_index in logo.split(X1_raw, y, groups=subject_ids):
            X1_train, X1_test = X1_raw[train_index], X1_raw[test_index]
            X2_train, X2_test = X2_raw[train_index], X2_raw[test_index]
            y_train, y_test = y[train_index], y[test_index]
            
            scaler1 = MinMaxScaler()
            X1_train_scaled = scaler1.fit_transform(X1_train)
            X1_test_scaled = scaler1.transform(X1_test)
            
            scaler2 = MinMaxScaler()
            X2_train_scaled = scaler2.fit_transform(X2_train)
            X2_test_scaled = scaler2.transform(X2_test)

            X1_train_selected, X1_test_selected = self._select_features(
                X1_train_scaled, X1_test_scaled, y_train
            )
            X2_train_selected, X2_test_selected = self._select_features(
                X2_train_scaled, X2_test_scaled, y_train
            )
            
            model1 = self._get_model()
            model1.fit(X1_train_selected, y_train)
            
            model2 = self._get_model()
            model2.fit(X2_train_selected, y_train)
            
            y1_pred = model1.predict(X1_test_selected)
            y2_pred = model2.predict(X2_test_selected)
            y_pred = (y1_pred + y2_pred) / 2
            
            # Keep transcript-level predictions (LOSO prevents leakage)
            predictions.extend(y_pred.tolist())
            true_values.extend(y_test.tolist())
            pred_files.extend([file_names[i] for i in test_index])
            pred_subjects.extend([subject_ids[i] for i in test_index])
        
        return self._compute_metrics(predictions, true_values, pred_files,
                                     np.array(pred_subjects),
                                     key='late_fusion_featuredict', 
                                     model_type='late_fusion_featuredict')
    
    def _compute_metrics(
        self,
        predictions: List[float],
        true_values: List[float],
        file_names: List[str],
        subject_ids: np.ndarray,
        key: str,
        model_type: str
    ) -> ModelResults:
        """Compute evaluation metrics at transcript level."""
        predictions = np.array(predictions)
        true_values = np.array(true_values)
        
        #mse = mean_squared_error(true_values, predictions)
        mae = mean_absolute_error(true_values, predictions)
        spearman_corr, p_value = spearmanr(true_values, predictions)
        
        true_binary = (true_values >= self.auc_threshold).astype(int)
        
        if len(np.unique(true_binary)) < 2:
            auc = np.nan
            auprc = np.nan
        else:
            auc = roc_auc_score(true_binary, predictions)
            auprc = average_precision_score(true_binary, predictions)
        
        return ModelResults(
            key=key,
            model_type=model_type,
            #mse=mse,
            mae=mae,
            spearman_corr=spearman_corr,
            p_value=p_value,
            auc=auc,
            auprc=auprc,
            predictions=predictions,
            true_values=true_values,
            file_names=file_names,
            subject_ids=subject_ids
        )