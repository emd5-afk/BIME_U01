"""
Cross-Dataset Model for training on one/two datasets and testing on another.
Supports all 8 approaches with standardized target normalization.
"""
import numpy as np
import pandas as pd
from sklearn.svm import SVR, LinearSVR
from sklearn.linear_model import Ridge, ElasticNet
from sklearn.ensemble import RandomForestRegressor
from sklearn.cross_decomposition import PLSRegression
from sklearn.preprocessing import StandardScaler, MinMaxScaler
from sklearn.metrics import mean_squared_error, roc_auc_score, average_precision_score, mean_absolute_error
from scipy.stats import spearmanr, zscore
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
class CrossDatasetResults:
    """Container for cross-dataset model evaluation results."""
    approach: str
    train_datasets: List[str]
    test_dataset: str
    model_type: str
    mae: float
    spearman_corr: float
    p_value: float
    auc: float
    auprc: float
    predictions: np.ndarray
    true_values: np.ndarray
    file_names: List[str]
    n_train: int
    n_test: int


class CrossDatasetModel:
    """
    Model for cross-dataset training and testing.
    
    Trains on one or more datasets and tests on a completely separate dataset.
    Uses z-score normalization of targets during training to handle different
    scales across datasets. Evaluation uses Spearman correlation (scale-invariant)
    and quantile-based AUC threshold.
    
    Supports 8 approaches:
    1. time_stats_only - 6 statistical features only
    2. time_featuredict_only - 764 TSFRESH features only
    3. coherence_nltk_only - 764 coherence features (NLTK split)
    4. coherence_whisper_only - 764 coherence features (Whisper split)
    5. early_fusion_stats - concatenate time stats + coherence (770 features)
    6. early_fusion_featuredict - concatenate time featuredict + coherence (1528 features)
    7. late_fusion_stats - average predictions from time stats + coherence models
    8. late_fusion_featuredict - average predictions from time featuredict + coherence models
    """
    
    def __init__(self, model_type: str = 'svr', n_features: Optional[int] = None,
                 auc_quantile: float = 0.75):
        """
        Initialize CrossDatasetModel.
        
        Args:
            model_type: One of 'svr', 'linear_svr', 'ridge', 'elastic_net', 'random_forest', 'pls'
            n_features: Number of features to select (None = use all)
            auc_quantile: Quantile for AUC threshold (default 0.75 = top 25%)
        """
        self.model_type = model_type
        self.n_features = n_features
        self.auc_quantile = auc_quantile
        
        if model_type not in MODEL_TYPES:
            raise ValueError(f"model_type must be one of {list(MODEL_TYPES.keys())}")
    
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
            return X_train, X_test, None
        
        selector = SelectKBest(score_func=f_regression, k=self.n_features)
        X_train_selected = selector.fit_transform(X_train, y_train)
        X_test_selected = selector.transform(X_test)
        return X_train_selected, X_test_selected, selector
    
    def _compute_metrics(self, y_true, y_pred, file_names, approach,
                        train_names, test_name, n_train) -> CrossDatasetResults:
        """Compute evaluation metrics."""
        mae = mean_absolute_error(y_true, y_pred)
        spearman_corr, p_value = spearmanr(y_true, y_pred)
        
        # Use quantile-based threshold for AUC
        auc_threshold = np.quantile(y_true, self.auc_quantile)
        true_binary = (y_true >= auc_threshold).astype(int)
        
        if len(np.unique(true_binary)) < 2:
            auc = np.nan
            auprc = np.nan
        else:
            auc = roc_auc_score(true_binary, y_pred)
            auprc = average_precision_score(true_binary, y_pred)
        
        return CrossDatasetResults(
            approach=approach,
            train_datasets=train_names,
            test_dataset=test_name,
            model_type=self.model_type,
            mae=mae,
            spearman_corr=spearman_corr,
            p_value=p_value,
            auc=auc,
            auprc=auprc,
            predictions=y_pred,
            true_values=y_true,
            file_names=file_names,
            n_train=n_train,
            n_test=len(y_true)
        )
    
    # ========== APPROACH 1: Time Stats Only ==========
    def train_time_stats_only(
        self,
        train_data: List[Dict],
        test_data: Dict
    ) -> CrossDatasetResults:
        """
        Train on time stats from train datasets, test on another.
        
        Args:
            train_data: List of dicts with keys: 'name', 'df' (merged with stats), 'target_column'
            test_data: Dict with same keys
        """
        # Combine training data
        X_train_list = []
        y_train_list = []
        
        for data in train_data:
            X = data['df'][STATS_FEATURES].values
            y = data['df'][data['target_column']].values
            # Z-score normalize targets within each dataset
            y_normalized = zscore(y)
            X_train_list.append(X)
            y_train_list.append(y_normalized)
        
        X_train = np.vstack(X_train_list)
        y_train = np.hstack(y_train_list)
        
        # Test data
        X_test = test_data['df'][STATS_FEATURES].values
        y_test = test_data['df'][test_data['target_column']].values
        file_names = test_data['df']['file'].tolist()
        
        # Scale features
        scaler = MinMaxScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        # Feature selection
        X_train_sel, X_test_sel, _ = self._select_features(X_train_scaled, X_test_scaled, y_train)
        
        # Train and predict
        model = self._get_model()
        model.fit(X_train_sel, y_train)
        y_pred = model.predict(X_test_sel)
        
        train_names = [d['name'] for d in train_data]
        return self._compute_metrics(y_test, y_pred, file_names, 'time_stats_only',
                                    train_names, test_data['name'], len(y_train))
    
    # ========== APPROACH 2: Time FeatureDict Only ==========
    def train_time_featuredict_only(
        self,
        train_data: List[Dict],
        test_data: Dict
    ) -> CrossDatasetResults:
        """Train on time featuredict from train datasets, test on another."""
        X_train_list = []
        y_train_list = []
        
        for data in train_data:
            X = data['time_feat_df'].iloc[:, :N_COHERENCE_FEATURES].values
            y = data['time_feat_df'][data['target_column']].values
            y_normalized = zscore(y)
            X_train_list.append(X)
            y_train_list.append(y_normalized)
        
        X_train = np.vstack(X_train_list)
        y_train = np.hstack(y_train_list)
        
        X_test = test_data['time_feat_df'].iloc[:, :N_COHERENCE_FEATURES].values
        y_test = test_data['time_feat_df'][test_data['target_column']].values
        file_names = test_data['time_feat_df']['file'].tolist()
        
        scaler = MinMaxScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        X_train_sel, X_test_sel, _ = self._select_features(X_train_scaled, X_test_scaled, y_train)
        
        model = self._get_model()
        model.fit(X_train_sel, y_train)
        y_pred = model.predict(X_test_sel)
        
        train_names = [d['name'] for d in train_data]
        return self._compute_metrics(y_test, y_pred, file_names, 'time_featuredict_only',
                                    train_names, test_data['name'], len(y_train))
    
    # ========== APPROACH 3 & 4: Coherence Only ==========
    def train_coherence_only(
        self,
        train_data: List[Dict],
        test_data: Dict,
        split_type: str = 'nltk'
    ) -> CrossDatasetResults:
        """Train on coherence features from train datasets, test on another."""
        df_key = f'coherence_{split_type}_df'
        
        X_train_list = []
        y_train_list = []
        
        for data in train_data:
            X = data[df_key].iloc[:, :N_COHERENCE_FEATURES].values
            y = data[df_key][data['target_column']].values
            y_normalized = zscore(y)
            X_train_list.append(X)
            y_train_list.append(y_normalized)
        
        X_train = np.vstack(X_train_list)
        y_train = np.hstack(y_train_list)
        
        X_test = test_data[df_key].iloc[:, :N_COHERENCE_FEATURES].values
        y_test = test_data[df_key][test_data['target_column']].values
        file_names = test_data[df_key]['file'].tolist()
        
        scaler = MinMaxScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        X_train_sel, X_test_sel, _ = self._select_features(X_train_scaled, X_test_scaled, y_train)
        
        model = self._get_model()
        model.fit(X_train_sel, y_train)
        y_pred = model.predict(X_test_sel)
        
        train_names = [d['name'] for d in train_data]
        return self._compute_metrics(y_test, y_pred, file_names, f'coherence_{split_type}_only',
                                    train_names, test_data['name'], len(y_train))
    
    # ========== APPROACH 5: Early Fusion Stats ==========
    def train_early_fusion_stats(
        self,
        train_data: List[Dict],
        test_data: Dict
    ) -> CrossDatasetResults:
        """Train with concatenated coherence + time stats."""
        X_train_list = []
        y_train_list = []
        
        for data in train_data:
            X_coherence = data['coherence_nltk_df'].iloc[:, :N_COHERENCE_FEATURES].values
            X_stats = data['df'][STATS_FEATURES].values
            X = np.hstack([X_coherence, X_stats])
            y = data['df'][data['target_column']].values
            y_normalized = zscore(y)
            X_train_list.append(X)
            y_train_list.append(y_normalized)
        
        X_train = np.vstack(X_train_list)
        y_train = np.hstack(y_train_list)
        
        X_coherence_test = test_data['coherence_nltk_df'].iloc[:, :N_COHERENCE_FEATURES].values
        X_stats_test = test_data['df'][STATS_FEATURES].values
        X_test = np.hstack([X_coherence_test, X_stats_test])
        y_test = test_data['df'][test_data['target_column']].values
        file_names = test_data['df']['file'].tolist()
        
        scaler = MinMaxScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        X_train_sel, X_test_sel, _ = self._select_features(X_train_scaled, X_test_scaled, y_train)
        
        model = self._get_model()
        model.fit(X_train_sel, y_train)
        y_pred = model.predict(X_test_sel)
        
        train_names = [d['name'] for d in train_data]
        return self._compute_metrics(y_test, y_pred, file_names, 'early_fusion_stats',
                                    train_names, test_data['name'], len(y_train))
    
    # ========== APPROACH 6: Early Fusion FeatureDict ==========
    def train_early_fusion_featuredict(
        self,
        train_data: List[Dict],
        test_data: Dict
    ) -> CrossDatasetResults:
        """Train with concatenated coherence + time featuredict."""
        X_train_list = []
        y_train_list = []
        
        for data in train_data:
            X_coherence = data['coherence_nltk_df'].iloc[:, :N_COHERENCE_FEATURES].values
            X_time = data['time_feat_df'].iloc[:, :N_COHERENCE_FEATURES].values
            X = np.hstack([X_coherence, X_time])
            y = data['coherence_nltk_df'][data['target_column']].values
            y_normalized = zscore(y)
            X_train_list.append(X)
            y_train_list.append(y_normalized)
        
        X_train = np.vstack(X_train_list)
        y_train = np.hstack(y_train_list)
        
        X_coherence_test = test_data['coherence_nltk_df'].iloc[:, :N_COHERENCE_FEATURES].values
        X_time_test = test_data['time_feat_df'].iloc[:, :N_COHERENCE_FEATURES].values
        X_test = np.hstack([X_coherence_test, X_time_test])
        y_test = test_data['coherence_nltk_df'][test_data['target_column']].values
        file_names = test_data['coherence_nltk_df']['file'].tolist()
        
        scaler = MinMaxScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        X_train_sel, X_test_sel, _ = self._select_features(X_train_scaled, X_test_scaled, y_train)
        
        model = self._get_model()
        model.fit(X_train_sel, y_train)
        y_pred = model.predict(X_test_sel)
        
        train_names = [d['name'] for d in train_data]
        return self._compute_metrics(y_test, y_pred, file_names, 'early_fusion_featuredict',
                                    train_names, test_data['name'], len(y_train))
    
    # ========== APPROACH 7: Late Fusion Stats ==========
    def train_late_fusion_stats(
        self,
        train_data: List[Dict],
        test_data: Dict
    ) -> CrossDatasetResults:
        """Train two models (time stats + coherence) and average predictions."""
        # Time stats model
        X1_train_list = []
        y1_train_list = []
        for data in train_data:
            X = data['df'][STATS_FEATURES].values
            y = data['df'][data['target_column']].values
            X1_train_list.append(X)
            y1_train_list.append(zscore(y))
        X1_train = np.vstack(X1_train_list)
        y1_train = np.hstack(y1_train_list)
        
        # Coherence model
        X2_train_list = []
        y2_train_list = []
        for data in train_data:
            X = data['coherence_nltk_df'].iloc[:, :N_COHERENCE_FEATURES].values
            y = data['coherence_nltk_df'][data['target_column']].values
            X2_train_list.append(X)
            y2_train_list.append(zscore(y))
        X2_train = np.vstack(X2_train_list)
        y2_train = np.hstack(y2_train_list)
        
        # Test data
        X1_test = test_data['df'][STATS_FEATURES].values
        X2_test = test_data['coherence_nltk_df'].iloc[:, :N_COHERENCE_FEATURES].values
        y_test = test_data['df'][test_data['target_column']].values
        file_names = test_data['df']['file'].tolist()
        
        # Scale and select features
        scaler1 = MinMaxScaler()
        X1_train_scaled = scaler1.fit_transform(X1_train)
        X1_test_scaled = scaler1.transform(X1_test)
        
        scaler2 = MinMaxScaler()
        X2_train_scaled = scaler2.fit_transform(X2_train)
        X2_test_scaled = scaler2.transform(X2_test)
        
        X1_train_sel, X1_test_sel, _ = self._select_features(X1_train_scaled, X1_test_scaled, y1_train)
        X2_train_sel, X2_test_sel, _ = self._select_features(X2_train_scaled, X2_test_scaled, y2_train)
        
        # Train both models
        model1 = self._get_model()
        model1.fit(X1_train_sel, y1_train)
        
        model2 = self._get_model()
        model2.fit(X2_train_sel, y2_train)
        
        # Average predictions
        y1_pred = model1.predict(X1_test_sel)
        y2_pred = model2.predict(X2_test_sel)
        y_pred = (y1_pred + y2_pred) / 2
        
        train_names = [d['name'] for d in train_data]
        return self._compute_metrics(y_test, y_pred, file_names, 'late_fusion_stats',
                                    train_names, test_data['name'], len(y1_train))
    
    # ========== APPROACH 8: Late Fusion FeatureDict ==========
    def train_late_fusion_featuredict(
        self,
        train_data: List[Dict],
        test_data: Dict
    ) -> CrossDatasetResults:
        """Train two models (time featuredict + coherence) and average predictions."""
        # Time featuredict model
        X1_train_list = []
        y1_train_list = []
        for data in train_data:
            X = data['time_feat_df'].iloc[:, :N_COHERENCE_FEATURES].values
            y = data['time_feat_df'][data['target_column']].values
            X1_train_list.append(X)
            y1_train_list.append(zscore(y))
        X1_train = np.vstack(X1_train_list)
        y1_train = np.hstack(y1_train_list)
        
        # Coherence model
        X2_train_list = []
        y2_train_list = []
        for data in train_data:
            X = data['coherence_nltk_df'].iloc[:, :N_COHERENCE_FEATURES].values
            y = data['coherence_nltk_df'][data['target_column']].values
            X2_train_list.append(X)
            y2_train_list.append(zscore(y))
        X2_train = np.vstack(X2_train_list)
        y2_train = np.hstack(y2_train_list)
        
        # Test data
        X1_test = test_data['time_feat_df'].iloc[:, :N_COHERENCE_FEATURES].values
        X2_test = test_data['coherence_nltk_df'].iloc[:, :N_COHERENCE_FEATURES].values
        y_test = test_data['time_feat_df'][test_data['target_column']].values
        file_names = test_data['time_feat_df']['file'].tolist()
        
        # Scale and select features
        scaler1 = MinMaxScaler()
        X1_train_scaled = scaler1.fit_transform(X1_train)
        X1_test_scaled = scaler1.transform(X1_test)
        
        scaler2 = MinMaxScaler()
        X2_train_scaled = scaler2.fit_transform(X2_train)
        X2_test_scaled = scaler2.transform(X2_test)
        
        X1_train_sel, X1_test_sel, _ = self._select_features(X1_train_scaled, X1_test_scaled, y1_train)
        X2_train_sel, X2_test_sel, _ = self._select_features(X2_train_scaled, X2_test_scaled, y2_train)
        
        # Train both models
        model1 = self._get_model()
        model1.fit(X1_train_sel, y1_train)
        
        model2 = self._get_model()
        model2.fit(X2_train_sel, y2_train)
        
        # Average predictions
        y1_pred = model1.predict(X1_test_sel)
        y2_pred = model2.predict(X2_test_sel)
        y_pred = (y1_pred + y2_pred) / 2
        
        train_names = [d['name'] for d in train_data]
        return self._compute_metrics(y_test, y_pred, file_names, 'late_fusion_featuredict',
                                    train_names, test_data['name'], len(y1_train))
    
    def run_all_approaches(
        self,
        train_data: List[Dict],
        test_data: Dict
    ) -> Dict[str, CrossDatasetResults]:
        """Run all 8 approaches and return results."""
        results = {}
        
        results['time_stats_only'] = self.train_time_stats_only(train_data, test_data)
        results['time_featuredict_only'] = self.train_time_featuredict_only(train_data, test_data)
        results['coherence_nltk_only'] = self.train_coherence_only(train_data, test_data, 'nltk')
        results['coherence_whisper_only'] = self.train_coherence_only(train_data, test_data, 'whisper')
        results['early_fusion_stats'] = self.train_early_fusion_stats(train_data, test_data)
        results['early_fusion_featuredict'] = self.train_early_fusion_featuredict(train_data, test_data)
        results['late_fusion_stats'] = self.train_late_fusion_stats(train_data, test_data)
        results['late_fusion_featuredict'] = self.train_late_fusion_featuredict(train_data, test_data)
        
        return results