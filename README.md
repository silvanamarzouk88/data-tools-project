# Healthcare Patient Risk Prediction — SAS Pipeline

Classification pipeline for predicting high-risk patients using a healthcare dataset, built entirely in SAS. Covers EDA, preprocessing, feature engineering, and two classification models.

## Dataset

`Healthcares.csv` — patient records with demographic, clinical, and billing information including age, gender, blood type, medical condition, admission type, medication, billing amount, and test results.

## Pipeline

### 1. Exploratory Data Analysis
- Descriptive statistics for Age, Billing Amount, and Room Number
- Frequency tables for all categorical variables (Gender, Blood Type, Medical Condition, Admission Type, Medication, Test Results, Insurance Provider)
- 10 visualizations covering age distribution, billing distribution, gender breakdown, medical conditions by gender, admission type vs test results, and billing by condition
- Correlation matrix for numerical variables
- Chi-square tests: Medical Condition vs Test Results, Gender vs Test Results

### 2. Train / Test Split
Random 70/30 split using `rand("uniform")` before any imputation or transformation to prevent data leakage.

### 3. Missing Value Imputation
Fit on train set only, applied to both train and test using the same stored values.

- Categorical columns (Gender, Blood Type, Medical Condition, Admission Type, Medication, Test Results, Insurance Provider): imputed with mode via a reusable `%get_mode` macro
- Numerical columns (Age, Billing Amount, Room Number): imputed with median
- Name: filled with "Unknown" when blank
- Doctor and Hospital columns dropped as non-predictive identifiers

### 4. Duplicate Removal
`PROC SORT` with `NODUPKEY` applied separately to train and test. Duplicate counts logged via macro variables.

### 5. Outlier Removal
IQR bounds computed on train only (Q1 − 1.5×IQR, Q3 + 1.5×IQR) for Age, Billing Amount, and Room Number. Same bounds applied to test without refitting. Rows outside bounds are deleted.

### 6. Feature Engineering

| Feature | Description |
|---|---|
| `Length_of_Stay` | Discharge Date − Date of Admission (records with ≤0 deleted) |
| `Cost_per_Day` | Billing Amount / Length of Stay |
| `Age_Group` | Child / Young / Middle / Senior |
| `Emergency_Flag` | 1 if Admission Type = Emergency |
| `Chronic_Flag` | 1 if condition is Diabetes, Cancer, or Heart Disease |
| `Bill_Level` | Low / Medium / High based on Q1/Q3 thresholds from train |
| `High_Risk` | Binary target: 1 if ≥2 of (Age > 60, Chronic_Flag, Cost_per_Day > 1000) |

### 7. Modeling

**Logistic Regression** (`PROC LOGISTIC`)  
Predictors: Age, Billing Amount, Cost per Day, Age Group, Gender, Admission Type, Emergency Flag, Chronic Flag. Reference-cell encoding for categorical inputs. Scored directly on test set.

**Decision Tree** (`PROC HPSPLIT`)  
Predictors: Billing Amount, Age Group, Gender, Admission Type, Emergency Flag. Internal 70/30 validation split for evaluation.

### 8. Results

| Model | Accuracy |
|---|---|
| Logistic Regression | 92.75% |
| Decision Tree | 79.9% |

Logistic Regression outperforms the Decision Tree on this dataset.

## Requirements

SAS OnDemand for Academics or any SAS 9.4+ environment with access to:
- `PROC LOGISTIC`
- `PROC HPSPLIT`
- `PROC SGPLOT` / `PROC SGPANEL`
- `PROC GCHART`

## Usage

Update the file path in the `FILENAME REFFILE` statement to point to your local copy of `Healthcares.csv`, then submit the full program. All steps run sequentially with no manual intervention required.
