# PACE Strategy Document — Melbourne Rainfall Prediction

The PACE framework (**P**lan → **A**nalyze → **C**onstruct → **E**xecute) guided this project. This document records the decisions and reasoning behind each stage of [`Melbourne_Rainfall_Prediction.ipynb`](../Melbourne_Rainfall_Prediction.ipynb).

---

## 1. Project at a glance

| | |
|---|---|
| **Business problem** | Help people decide, for example, whether to cycle to work or hold an outdoor activity, by predicting whether it will rain **today** in Melbourne. |
| **Data** | `weatherAUS.csv`: daily observations from the Australian Bureau of Meteorology, 145,460 rows × 23 columns, 49 locations, Nov 2007 – Jun 2017. |
| **Target** | `RainToday` (Yes / No), defined as at least 1 mm of rain. Reframed from the original `RainTomorrow` to avoid leakage (see Plan). |
| **Modelling scope** | Three nearby stations (Melbourne, Melbourne Airport, Watsonia); **7,557** complete observations. |
| **Approach** | Leak-free scikit-learn pipelines, stratified 5-fold `GridSearchCV`, Random Forest vs. Logistic Regression. |

### Executive summary

- It rains on **23.7%** of days (about 87 per year), so "always predict no rain" already scores **76.3%** accuracy. Accuracy alone is a misleading metric here.
- The tuned **Random Forest** reached **84.5%** test accuracy (precision 0.75, recall 0.51, F1 0.61), ahead of **Logistic Regression** at 83.0% (precision 0.69, recall 0.51, F1 0.59).
- Both models **miss about half of the rainy days**. The Random Forest raises fewer false alarms (60 vs. 83).
- **Afternoon humidity** is the most important feature, followed by pressure, sunshine and wind gust speed.
- Recommended next steps: time-based validation, optimising for recall or F1, imputing missing values and adding lag features.

---

## 2. Plan

**What is the problem and who benefits?** Anyone making everyday weather-dependent decisions. A useful model needs to be realistic: it may only use information that is available when the prediction is made.

**Key planning decision: avoid data leakage.** The dataset's original target, `RainTomorrow`, is a next-day forecast, but many columns (`Rainfall`, `Sunshine`, `Evaporation`, `MaxTemp`, `RainToday` and others) summarise the *whole day* and are only known once that day has ended. Using them to predict tomorrow would be unrealistic. The problem was therefore reframed as **"will it rain today, using data up to and including yesterday?"** The columns were renamed to match: `RainToday` → `RainYesterday` (feature) and `RainTomorrow` → `RainToday` (target).

**Scope decision.** Rain patterns differ strongly between Australian climate zones, so the project focuses on one region: Melbourne, Melbourne Airport (about 18 km away) and Watsonia (about 15 km away). `Location` stays as a categorical feature.

**Success criteria.** Beat the naive baseline, and judge models on precision, recall and F1 for the rain class, not accuracy only.

---

## 3. Analyze

- **Missing values:** `Sunshine`, `Evaporation` and the cloud-cover columns are missing for a large share of rows. For a transparent first version, rows with any missing value were dropped (56,420 of 145,460 rows remain nationally), which is still plenty of data.
- **Granularity:** filtering to the three Melbourne-area stations leaves **7,557** records.
- **Feature engineering:** a `Season` feature (southern-hemisphere seasons) was derived from the date, and `Date` was dropped afterwards.
- **Class balance:** 23.7% rainy days, so the target is imbalanced. Rain occurs on roughly 29% of winter days versus 16% of summer days.
- **Baseline:** always predicting "no rain" gives 76.3% accuracy, the benchmark any model must beat.

---

## 4. Construct

- **Split:** 80/20 train/test, **stratified** on the target (6,045 training and 1,512 test rows).
- **Preprocessing inside a `Pipeline`:** `StandardScaler` for numeric features and `OneHotEncoder(handle_unknown="ignore")` for categorical ones, combined with a `ColumnTransformer`. Preprocessing is learned only from training folds, which prevents leakage into validation and test data.
- **Model 1: Random Forest** tuned with stratified 5-fold `GridSearchCV` over `n_estimators`, `max_depth` and `min_samples_split`. Best: `max_depth=20`, `min_samples_split=2`, `n_estimators=100` (cross-validated accuracy 0.8524).
- **Model 2: Logistic Regression** tuned over regularisation type (`l1` / `l2`) and class weighting. Best: `l2`, `class_weight=None`, solver `liblinear` (cross-validated accuracy 0.8372). The same preprocessing, folds and test set were reused so the comparison is like-for-like.

---

## 5. Execute

| Model | Test accuracy | Precision (rain) | Recall (rain) | F1 (rain) |
|---|--:|--:|--:|--:|
| Baseline: "always no rain" | 0.7630 | n/a | 0.0000 | n/a |
| Random Forest | 0.8446 | 0.7531 | 0.5112 | 0.6090 |
| Logistic Regression | 0.8300 | 0.6891 | 0.5140 | 0.5888 |

- **Random Forest confusion matrix (test):** 183 true positives, 175 false negatives, 60 false positives, 1,094 true negatives.
- **Preferred model:** the Random Forest. At almost identical recall it gives fewer false alarms and higher precision and F1. Logistic Regression remains a competitive, far more interpretable baseline.
- **Interpretation:** the top features are `Humidity3pm` (importance 0.121), `Pressure3pm`, `Pressure9am`, `Sunshine` and `WindGustSpeed`, which is physically sensible. The `Season` dummies did not rank in the top 20, so humidity, pressure and sunshine appear to carry most of the seasonal signal.
- **Class weighting did not help** under accuracy scoring, because accuracy favours the majority class.

### Limitations

- Dropping rows with missing values may bias the sample toward stations and days with complete instrumentation.
- Neighbouring days are correlated, so a random stratified split can be slightly optimistic compared with a chronological split.
- Only three nearby stations are modelled, so results may not transfer to other climate zones.
- Grids were deliberately small and models were selected on accuracy.

### Next steps

1. Evaluate with a **time-based split** (train on earlier years, test on the latest).
2. Optimise for **recall or F1**, tune the decision threshold and calibrate probabilities.
3. **Impute** missing values to recover dropped rows, including `Sunshine` and `Cloud*`.
4. Add **lag features** (rolling rainfall, pressure change) and try gradient-boosted models such as `HistGradientBoostingClassifier`.
5. Expand to more stations or a larger region with a location-aware model.

---

## 6. Reflections and lessons learned

1. **Define the target carefully.** Reframing the problem removed leakage and made the model realistic.
2. **Accuracy needs a baseline.** An 84% model sounds strong until you know that "never rain" scores 76%.
3. **Pipelines protect against leakage.** Putting scaling and encoding inside cross-validation keeps validation honest.
4. **Simple models are good benchmarks.** Logistic Regression came close to the Random Forest while being far easier to explain.
