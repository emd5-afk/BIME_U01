# Consolidated Aim 2 analysis pipeline.
#
# Primary analysis:
#   - Linear regression with participant-clustered sandwich SEs
#   - Outcome-specific models with WER (log scale) as primary exposure
#   - Prespecified demographic, clinical, recording-quality, and transcript covariates
#
# Sensitivity analyses:
#   - Mixed-effects model with participant random intercepts
#   - Optional random slope for WER when data support and convergence permit

ensure_packages <- function(pkgs) {
  for (pkg in pkgs) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg, repos = "http://cran.rstudio.com/")
    }
  }
}

choose_existing_path <- function(paths) {
  for (p in paths) {
    if (!is.null(p) && nzchar(p) && file.exists(p)) {
      return(p)
    }
  }
  stop(
    "No usable input data path found. Checked: ",
    paste(paths, collapse = ", "),
    call. = FALSE
  )
}

choose_output_dir <- function(preferred) {
  if (!is.null(preferred) && nzchar(preferred)) {
    dir.create(preferred, recursive = TRUE, showWarnings = FALSE)
    return(preferred)
  }

  candidates <- c(
    "/edata/obdw/sandwich_analysis_data/aim2_outputs",
    "Sandwich_Analysis_Data_Backup/aim2_outputs"
  )

  for (cand in candidates) {
    ok <- tryCatch({
      dir.create(cand, recursive = TRUE, showWarnings = FALSE)
      TRUE
    }, error = function(e) FALSE)
    if (ok && dir.exists(cand)) {
      return(cand)
    }
  }

  stop("Could not create an output directory.", call. = FALSE)
}

sanitize_column_names <- function(df) {
  original <- names(df)
  safe <- make.names(original, unique = TRUE)
  names(df) <- safe
  mapping <- data.frame(original = original, safe = safe, stringsAsFactors = FALSE)
  list(data = df, mapping = mapping)
}

to_safe_name <- function(name, mapping) {
  hit <- mapping$safe[mapping$original == name]
  if (length(hit) == 0) {
    return(NA_character_)
  }
  hit[[1]]
}

to_original_name <- function(name, mapping) {
  hit <- mapping$original[mapping$safe == name]
  if (length(hit) == 0) {
    return(name)
  }
  hit[[1]]
}

detect_cluster_col <- function(colnames_original) {
  candidates <- c("pid", "participant_id", "participant", "cluster")
  hit <- candidates[candidates %in% colnames_original]
  if (length(hit) == 0) {
    stop("No participant/cluster column found (expected one of pid/participant_id/participant/cluster).", call. = FALSE)
  }
  hit[[1]]
}

detect_exposure_col <- function(df_original) {
  cn <- names(df_original)
  if ("log_wer" %in% cn) {
    return(list(data = df_original, exposure = "log_wer", created = FALSE))
  }

  raw_candidates <- c("wer", "WER", "Y_WER")
  raw_hit <- raw_candidates[raw_candidates %in% cn]
  if (length(raw_hit) == 0) {
    stop("No WER column found (expected log_wer, wer, WER, or Y_WER).", call. = FALSE)
  }

  raw_col <- raw_hit[[1]]
  raw_vals <- suppressWarnings(as.numeric(df_original[[raw_col]]))
  df_original$log_wer <- log1p(pmax(raw_vals, 0))
  list(data = df_original, exposure = "log_wer", created = TRUE)
}

detect_default_outcomes <- function(colnames_original) {
  preferred <- c(
    "Y_COH",
    "sentCoherenceSentBertCumulativeCentroid"
  )
  preferred[preferred %in% colnames_original]
}

select_prespecified_covariates <- function(colnames_original, cluster_col, exposure_col, outcomes) {
  demo_cols <- grep("^(race_|gender_|binned_age_)", colnames_original, value = TRUE)

  clinical_targets <- c(
    "phq9.total", "phq9-total",
    "hpsvq.total.score", "hpsvq-total-score",
    "scl.avg.global.score", "scl-avg-global-score"
  )
  clinical_cols <- clinical_targets[clinical_targets %in% colnames_original]

  recording_targets <- c("snr", "pred_mos", "AMOS")
  recording_cols <- recording_targets[recording_targets %in% colnames_original]

  transcript_targets <- c(
    "pause_proportion",
    "segment_count",
    "recording_duration",
    "word_count",
    "speech_rate",
    "mean_pause_duration",
    "total_pause_duration",
    "total_words"
  )
  transcript_cols <- transcript_targets[transcript_targets %in% colnames_original]

  covars <- unique(c(demo_cols, clinical_cols, recording_cols, transcript_cols))
  covars <- setdiff(covars, c(cluster_col, exposure_col, outcomes))
  covars
}

build_clustered_table <- function(model, cluster_vec, mapping) {
  ct <- lmtest::coeftest(model, vcov. = sandwich::vcovCL(model, cluster = cluster_vec))
  out <- as.data.frame.matrix(ct)
  colnames(out)[1:4] <- c("Estimate", "Std.Error", "t.value", "p.value")
  out$VariableSafe <- rownames(out)
  out$Variable <- vapply(out$VariableSafe, to_original_name, mapping = mapping, FUN.VALUE = character(1))
  rownames(out) <- NULL

  out$CI.lower <- out$Estimate - 1.96 * out$Std.Error
  out$CI.upper <- out$Estimate + 1.96 * out$Std.Error
  out$q.value <- NA_real_

  non_intercept <- !(out$VariableSafe %in% c("(Intercept)", "Intercept", "const"))
  out$q.value[non_intercept] <- p.adjust(out$p.value[non_intercept], method = "BH")
  out$fdr.significant <- FALSE
  out$fdr.significant[non_intercept] <- out$q.value[non_intercept] < 0.05

  out[, c(
    "Variable", "Estimate", "Std.Error", "CI.lower", "CI.upper",
    "t.value", "p.value", "q.value", "fdr.significant"
  )]
}

extract_lme_table <- function(fit, mapping) {
  tt <- as.data.frame(summary(fit)$tTable)
  tt$VariableSafe <- rownames(tt)
  rownames(tt) <- NULL

  names(tt) <- c("Estimate", "Std.Error", "DF", "t.value", "p.value", "VariableSafe")
  tt$Variable <- vapply(tt$VariableSafe, to_original_name, mapping = mapping, FUN.VALUE = character(1))
  tt$CI.lower <- tt$Estimate - 1.96 * tt$Std.Error
  tt$CI.upper <- tt$Estimate + 1.96 * tt$Std.Error

  tt$q.value <- NA_real_
  non_intercept <- !(tt$VariableSafe %in% c("(Intercept)", "Intercept", "const"))
  tt$q.value[non_intercept] <- p.adjust(tt$p.value[non_intercept], method = "BH")
  tt$fdr.significant <- FALSE
  tt$fdr.significant[non_intercept] <- tt$q.value[non_intercept] < 0.05

  tt[, c(
    "Variable", "Estimate", "Std.Error", "CI.lower", "CI.upper",
    "DF", "t.value", "p.value", "q.value", "fdr.significant"
  )]
}

supports_random_slope <- function(df, cluster_safe, exposure_safe) {
  cl_sizes <- table(df[[cluster_safe]])
  enough_obs_clusters <- sum(cl_sizes >= 3)

  within_sd <- tapply(
    df[[exposure_safe]],
    df[[cluster_safe]],
    function(x) stats::sd(x, na.rm = TRUE)
  )
  variable_clusters <- sum(within_sd > 0, na.rm = TRUE)

  list(
    supported = (enough_obs_clusters >= 10 && variable_clusters >= 10),
    n_clusters_ge3 = enough_obs_clusters,
    n_clusters_exposure_variation = variable_clusters
  )
}

run_aim2_pipeline <- function(
  data_path = NULL,
  output_dir = NULL,
  outcomes = NULL,
  verbose = TRUE
) {
  ensure_packages(c("lmtest", "sandwich", "nlme"))

  default_inputs <- c(
    data_path,
    "/edata/obdw/sandwich_analysis_data/X_basic_plus_clin_sdh_location_stratified.csv",
    "/edata/obdw/sandwich_analysis_data/basic_plus_clinical_sdh_analysis.csv",
    "Sandwich_Analysis_Data_Backup/basic_plus_clinical_sdh_analysis.csv"
  )
  input_path <- choose_existing_path(default_inputs)

  out_dir <- choose_output_dir(output_dir)
  if (verbose) {
    cat("Input data:", input_path, "\n")
    cat("Output dir:", out_dir, "\n")
  }

  df_original <- read.csv(input_path, check.names = FALSE)
  if (names(df_original)[1] %in% c("", "X")) {
    df_original <- df_original[, -1, drop = FALSE]
  }

  cluster_col <- detect_cluster_col(names(df_original))
  exposure_info <- detect_exposure_col(df_original)
  df_original <- exposure_info$data
  exposure_col <- exposure_info$exposure

  if (is.null(outcomes)) {
    outcomes <- detect_default_outcomes(names(df_original))
  }
  if (length(outcomes) == 0) {
    stop("No outcomes supplied/found. Provide outcomes (e.g., Y_COH).", call. = FALSE)
  }

  covariates <- select_prespecified_covariates(
    colnames_original = names(df_original),
    cluster_col = cluster_col,
    exposure_col = exposure_col,
    outcomes = outcomes
  )
  if (length(covariates) == 0) {
    stop("No prespecified covariates found in data.", call. = FALSE)
  }

  # Remove impossible clinical sentinel values if present.
  sentinel_cols <- intersect(c("phq9.total", "phq9-total", "hpsvq.total.score", "hpsvq-total-score", "scl.avg.global.score", "scl-avg-global-score"), names(df_original))
  for (col in sentinel_cols) {
    if (is.numeric(df_original[[col]])) {
      df_original[[col]][df_original[[col]] == 999] <- NA
    }
  }

  sn <- sanitize_column_names(df_original)
  df <- sn$data
  mapping <- sn$mapping

  cluster_safe <- to_safe_name(cluster_col, mapping)
  exposure_safe <- to_safe_name(exposure_col, mapping)
  outcome_safe <- vapply(outcomes, to_safe_name, mapping = mapping, FUN.VALUE = character(1))
  cov_safe <- vapply(covariates, to_safe_name, mapping = mapping, FUN.VALUE = character(1))

  outcome_safe <- outcome_safe[!is.na(outcome_safe) & nzchar(outcome_safe)]
  cov_safe <- cov_safe[!is.na(cov_safe) & nzchar(cov_safe)]

  meta <- data.frame(
    key = c("input_path", "cluster_col", "exposure_col", "exposure_created_log_transform", "n_prespecified_covariates"),
    value = c(input_path, cluster_col, exposure_col, as.character(exposure_info$created), as.character(length(covariates))),
    stringsAsFactors = FALSE
  )
  write.csv(meta, file.path(out_dir, "aim2_metadata.csv"), row.names = FALSE)

  model_status <- list()

  for (i in seq_along(outcome_safe)) {
    y_safe <- outcome_safe[[i]]
    y_orig <- to_original_name(y_safe, mapping)

    model_terms <- unique(c(exposure_safe, cov_safe))
    model_terms <- setdiff(model_terms, y_safe)

    needed <- unique(c(cluster_safe, y_safe, model_terms))
    work <- df[, needed, drop = FALSE]
    work <- work[is.finite(rowSums(sapply(work, function(x) if (is.numeric(x)) x else 0), na.rm = TRUE)) | TRUE, , drop = FALSE]
    work <- work[complete.cases(work), , drop = FALSE]

    if (nrow(work) < 50) {
      warning(paste("Skipping", y_orig, "because complete-case n < 50"))
      next
    }

    # Primary clustered linear model.
    f_primary <- stats::as.formula(paste(y_safe, "~", paste(model_terms, collapse = " + ")))
    fit_primary <- stats::lm(f_primary, data = work)
    primary_tbl <- build_clustered_table(fit_primary, cluster_vec = work[[cluster_safe]], mapping = mapping)
    write.csv(primary_tbl, file.path(out_dir, paste0("aim2_primary_clustered_", y_orig, ".csv")), row.names = FALSE)

    # Sensitivity mixed model with random intercept.
    fit_ri <- tryCatch(
      nlme::lme(
        fixed = f_primary,
        random = stats::as.formula(paste("~ 1|", cluster_safe)),
        data = work,
        method = "REML",
        na.action = na.omit,
        control = nlme::lmeControl(opt = "optim")
      ),
      error = function(e) e
    )
    if (inherits(fit_ri, "error")) {
      warning(paste("Random intercept model failed for", y_orig, ":", fit_ri$message))
    } else {
      ri_tbl <- extract_lme_table(fit_ri, mapping)
      write.csv(ri_tbl, file.path(out_dir, paste0("aim2_mixed_random_intercept_", y_orig, ".csv")), row.names = FALSE)
    }

    # Optional random-slope model for WER when supported.
    slope_support <- supports_random_slope(work, cluster_safe = cluster_safe, exposure_safe = exposure_safe)
    slope_status <- "not_supported"
    slope_error <- ""

    if (isTRUE(slope_support$supported)) {
      slope_formula <- stats::as.formula(paste("~ 1 +", exposure_safe, "|", cluster_safe))
      fit_rs <- tryCatch(
        nlme::lme(
          fixed = f_primary,
          random = slope_formula,
          data = work,
          method = "REML",
          na.action = na.omit,
          control = nlme::lmeControl(opt = "optim")
        ),
        error = function(e) e
      )

      if (inherits(fit_rs, "error")) {
        slope_status <- "supported_but_failed"
        slope_error <- fit_rs$message
      } else {
        slope_status <- "fit"
        rs_tbl <- extract_lme_table(fit_rs, mapping)
        write.csv(rs_tbl, file.path(out_dir, paste0("aim2_mixed_random_slope_", y_orig, ".csv")), row.names = FALSE)
      }
    }

    model_status[[length(model_status) + 1]] <- data.frame(
      outcome = y_orig,
      n_complete_case = nrow(work),
      n_cluster = length(unique(work[[cluster_safe]])),
      exposure = exposure_col,
      random_intercept_status = if (inherits(fit_ri, "error")) "failed" else "fit",
      random_intercept_error = if (inherits(fit_ri, "error")) fit_ri$message else "",
      random_slope_support = slope_support$supported,
      clusters_ge3 = slope_support$n_clusters_ge3,
      clusters_with_exposure_variation = slope_support$n_clusters_exposure_variation,
      random_slope_status = slope_status,
      random_slope_error = slope_error,
      stringsAsFactors = FALSE
    )

    if (verbose) {
      cat("Completed outcome:", y_orig, "| n =", nrow(work), "| clusters =", length(unique(work[[cluster_safe]])), "\n")
    }
  }

  if (length(model_status) > 0) {
    status_df <- do.call(rbind, model_status)
    write.csv(status_df, file.path(out_dir, "aim2_model_status.csv"), row.names = FALSE)
  }

  invisible(list(
    input_path = input_path,
    output_dir = out_dir,
    outcomes = outcomes,
    exposure_col = exposure_col,
    covariates = covariates
  ))
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)

  data_arg <- NULL
  out_arg <- NULL
  outcome_arg <- NULL

  if (length(args) > 0) {
    for (arg in args) {
      if (grepl("^--data=", arg)) {
        data_arg <- sub("^--data=", "", arg)
      } else if (grepl("^--out=", arg)) {
        out_arg <- sub("^--out=", "", arg)
      } else if (grepl("^--outcomes=", arg)) {
        raw <- sub("^--outcomes=", "", arg)
        outcome_arg <- strsplit(raw, ",", fixed = TRUE)[[1]]
        outcome_arg <- trimws(outcome_arg)
      }
    }
  }

  run_aim2_pipeline(
    data_path = data_arg,
    output_dir = out_arg,
    outcomes = outcome_arg,
    verbose = TRUE
  )
}