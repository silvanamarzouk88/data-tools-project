/* =========================================
   1. LOAD DATA
========================================= */
/* Load dataset from file location */
FILENAME REFFILE '/home/u64506728/Healthcares.csv';

/* Import CSV file into SAS dataset */

PROC IMPORT DATAFILE=REFFILE
    DBMS=CSV
    OUT=WORK.IMPORT
    REPLACE;
    GETNAMES=YES;
RUN;


PROC CONTENTS DATA=WORK.IMPORT;
RUN;


PROC PRINT DATA=WORK.IMPORT (OBS=15);
    TITLE "First 10 Observations";
RUN;


PROC MEANS DATA=WORK.IMPORT 
    N MEAN STD MIN MAX MEDIAN;
    VAR Age "Billing Amount"n "Room Number"n;
    TITLE "Descriptive Statistics - Numeric Variables";
RUN;


PROC FREQ DATA=WORK.IMPORT;
    TABLES Gender 
           "Blood Type"n 
           "Medical Condition"n 
           "Admission Type"n 
           Medication 
           "Test Results"n 
           "Insurance Provider"n;
    TITLE "Frequency Tables - Categorical Variables";
RUN;


/* ====================== VISUALIZATIONS ====================== */

/* Visualization 1: Age Distribution */
PROC SGPLOT DATA=WORK.IMPORT;
    HISTOGRAM Age / BINWIDTH=5 FILLATTRS=(COLOR=CX4E79A7);
    DENSITY Age;
    TITLE "Visualization 1: Distribution of Patient Age";
    XAXIS LABEL="Age (Years)";
    YAXIS LABEL="Frequency";
RUN;

/* Visualization 2: Billing Amount Distribution */
PROC SGPLOT DATA=WORK.IMPORT;
    HISTOGRAM 'Billing Amount'n / BINWIDTH=5000 TRANSPARENCY=0.3;
    TITLE "Visualization 2: Distribution of Billing Amount";
    XAXIS LABEL="Billing Amount (USD)";
    YAXIS LABEL="Frequency";
RUN;

/* Visualization 3: Gender Distribution */
PROC SGPLOT DATA=WORK.IMPORT;
    VBAR Gender / DATALABEL FILLATTRS=(COLOR=CX76B7B2);
    TITLE "Visualization 3: Gender Distribution of Patients";
RUN;

/* Visualization 4: Medical Condition by Gender */
PROC SGPLOT DATA=WORK.IMPORT;
    VBAR 'Medical Condition'n / GROUP=Gender GROUPDISPLAY=CLUSTER DATALABEL;
    TITLE "Visualization 4: Medical Conditions by Gender";
    XAXIS LABEL="Medical Condition" FITPOLICY=ROTATE;
RUN;

/* Visualization 5: Test Results (Target Variable) */
PROC SGPLOT DATA=WORK.IMPORT;
    VBAR 'Test Results'n / DATALABEL FILLATTRS=(COLOR=CXE15759);
    TITLE "Visualization 5: Distribution of Test Results (Target Variable)";
RUN;

/* Visualization 6: Admission Type vs Test Results */
PROC SGPLOT DATA=WORK.IMPORT;
    VBAR 'Admission Type'n / GROUP='Test Results'n GROUPDISPLAY=CLUSTER;
    TITLE "Visualization 6: Admission Type vs Test Results";
RUN;

/* Visualization 7: Average Billing Amount by Medical Condition */
PROC MEANS DATA=WORK.IMPORT NOPRINT;
    CLASS 'Medical Condition'n;
    VAR 'Billing Amount'n;
    OUTPUT OUT=MEAN_BILL MEAN=Avg_Billing;
RUN;

PROC SGPLOT DATA=MEAN_BILL;
    VBAR 'Medical Condition'n / RESPONSE=Avg_Billing DATALABEL;
    TITLE "Visualization 7: Average Billing Amount by Medical Condition";
    XAXIS LABEL="Medical Condition" FITPOLICY=ROTATE;
    YAXIS LABEL="Average Billing Amount (USD)";
RUN;

/* Visualization 8: Billing Amount by Admission Type */
PROC SGPLOT DATA=WORK.IMPORT;
    VBOX 'Billing Amount'n / CATEGORY='Admission Type'n;
    TITLE "Visualization 8: Billing Amount Distribution by Admission Type";
    YAXIS LABEL="Billing Amount (USD)";
RUN;

/* Bonus Visualizations (9 & 10) - Recommended */

/* Viz 9: Relationship between Age and Billing Amount */
PROC SGPLOT DATA=WORK.IMPORT;
    SCATTER X=Age Y='Billing Amount'n / TRANSPARENCY=0.7;
    REG X=Age Y='Billing Amount'n / NOMARKERS;
    TITLE "Visualization 9: Age vs Billing Amount with Regression Line";
RUN;

/* --- VIZ 10 (BONUS): Panel – Billing Amount Distribution by Condition --- */
PROC SGPANEL DATA=WORK.IMPORT;
    PANELBY "Medical Condition"n / COLUMNS=3 NOVARNAME;
    HISTOGRAM "Billing Amount"n / FILLATTRS=(COLOR=Teal);
    ROWAXIS LABEL="Frequency";
    COLAXIS LABEL="Billing Amount (USD)";
    TITLE "VIZ 10 (Bonus) – Billing Amount Distribution per Medical Condition";
RUN;


/* ====================== RELATIONSHIP ANALYSIS ====================== */

/* Correlation between numerical variables */
PROC CORR DATA=WORK.IMPORT PLOTS=MATRIX;
    VAR Age 'Billing Amount'n 'Room Number'n;
    TITLE "Correlation Analysis - Numerical Variables";
RUN;

/* Chi-Square Test: Is Test Result independent of Medical Condition? */
PROC FREQ DATA=WORK.IMPORT;
    TABLES 'Medical Condition'n * 'Test Results'n / CHISQ;
    TITLE "Chi-Square Test: Medical Condition vs Test Results";
RUN;

PROC FREQ DATA=WORK.IMPORT;
    TABLES Gender * 'Test Results'n / CHISQ;
    TITLE "Chi-Square Test: Gender vs Test Results";
RUN;



/* =========================================
   2. TRAIN / TEST SPLIT (EARLY - CORRECT)
========================================= */
data model_data;
    set work.import;
run;

data train test;
    set model_data;

    rand = rand("uniform");

    if rand < 0.7 then output train;
    else output test;

    drop rand;
run;



/* =========================================
   3. MISSING VALUES IMPUTATION (FIT ON TRAIN ONLY)
========================================= */
/* Check missing values before cleaning */
proc means data=work.train nmiss;
run;

/* MODE for categorical */
%macro get_mode(dsn, var, outmac);

proc freq data=&dsn noprint order=freq;
    tables &var / out=_freq_;
run;

data _freq_clean;
    set _freq_;
    if strip(&var) ne "";
run;

data _null_;
    set _freq_clean(obs=1);
    call symputx("&outmac", strip(&var));
run;

%mend;

/* Apply mode on TRAIN only */
%get_mode(train, Gender, mode_gender);
%get_mode(train, 'Blood Type'n, mode_blood);
%get_mode(train, 'Medical Condition'n, mode_med);
%get_mode(train, 'Admission Type'n, mode_adm);
%get_mode(train, Medication, mode_medication);
%get_mode(train, 'Test Results'n, mode_test);
%get_mode(train, 'Insurance Provider'n, mode_ins);

/* Print one of the macro variables for checking */
%put &=mode_ins;


/* MEDIAN for numeric (TRAIN ONLY) */
proc means data=train noprint;
    var Age "Billing Amount"n "Room Number"n;
    output out=medians
        median(Age)=med_age
        median("Billing Amount"n)=med_bill
        median("Room Number"n)=med_room;
run;

data _null_;
    set medians;
    call symputx('med_age', med_age);
    call symputx('med_bill', med_bill);
    call symputx('med_room', med_room);
run;



/* =========================================
   4. APPLY CLEANING (TRAIN + TEST SAME RULES)
========================================= */
data train;
    set train(drop=Doctor Hospital);
    
	if strip(Name) = "" then Name = "Unknown";
    if Gender = "" then Gender="&mode_gender";
    if 'Blood Type'n = "" then 'Blood Type'n="&mode_blood";
    if 'Medical Condition'n = "" then 'Medical Condition'n="&mode_med";
    if 'Admission Type'n = "" then 'Admission Type'n="&mode_adm";
    if Medication = "" then Medication="&mode_medication";
    if 'Test Results'n = "" then 'Test Results'n="&mode_test";
    if 'Insurance Provider'n = "" then 'Insurance Provider'n="&mode_ins";

    if missing(Age) then Age=&med_age;
    if missing("Billing Amount"n) then "Billing Amount"n=&med_bill;
    if missing("Room Number"n) then "Room Number"n=&med_room;
    if missing('Date of Admission'n) then 'Date of Admission'n = &med_adm_date;
    if missing('Discharge Date'n) then 'Discharge Date'n = &med_dis_date;
run;

data test;
    set test(drop=Doctor Hospital);
	if strip(Name) = "" then Name = "Unknown";
    if Gender = "" then Gender="&mode_gender";
    if 'Blood Type'n = "" then 'Blood Type'n="&mode_blood";
    if 'Medical Condition'n = "" then 'Medical Condition'n="&mode_med";
    if 'Admission Type'n = "" then 'Admission Type'n="&mode_adm";
    if Medication = "" then Medication="&mode_medication";
    if 'Test Results'n = "" then 'Test Results'n="&mode_test";
    if 'Insurance Provider'n = "" then 'Insurance Provider'n="&mode_ins";

    if missing(Age) then Age=&med_age;
    if missing("Billing Amount"n) then "Billing Amount"n=&med_bill;
    if missing("Room Number"n) then "Room Number"n=&med_room;
    if missing('Date of Admission'n) then 'Date of Admission'n = &med_adm_date;
    if missing('Discharge Date'n) then 'Discharge Date'n = &med_dis_date;
run;


/* Check missing values after cleaning */
proc means data=work.train nmiss;
run;

proc means data=work.test nmiss;
run;
 
 /*  Admission Type vs Test Results */
PROC SGPLOT DATA=WORK.train;
    VBAR 'Admission Type'n / GROUP='Test Results'n GROUPDISPLAY=CLUSTER;
    TITLE "Visualization 6: Admission Type vs Test Results";
RUN;

/* =========================================
   Remove duplicate rows from dataset
   - dupout: stores duplicated rows
   - nodupkey: keeps only unique rows
   - by _all_: considers all columns for duplication
========================================= */

/* === TRAIN === */
proc sort data=train out=train_clean dupout=train_dup nodupkey;
  by _all_;
run;

data _null_;
  if 0 then set train_dup nobs=n;
  call symputx('train_dup_count', n);
  stop;
run;

%put NOTE: Number of duplicate rows removed from TRAIN = &train_dup_count;
/* === TEST === */
proc sort data=test out=test_clean dupout=test_dup nodupkey;
  by _all_;
run;

data _null_;
  if 0 then set test_dup nobs=n;
  call symputx('test_dup_count', n);
  stop;
run;

%put NOTE: Number of duplicate rows removed from TEST = &test_dup_count;
/* =========================================
   6. OUTLIERS REMOVAL (TRAIN ONLY FIT)
========================================= */
proc univariate data=train noprint;
    var Age "Billing Amount"n "Room Number"n;
    output out=iqr_stats
        p25=q1_age q1_bill q1_room
        p75=q3_age q3_bill q3_room;
run;

data _null_;
    set iqr_stats;

    call symputx('lo_age', q1_age - 1.5*(q3_age-q1_age));
    call symputx('hi_age', q3_age + 1.5*(q3_age-q1_age));

    call symputx('lo_bill', q1_bill - 1.5*(q3_bill-q1_bill));
    call symputx('hi_bill', q3_bill + 1.5*(q3_bill-q1_bill));

    call symputx('lo_room', q1_room - 1.5*(q3_room-q1_room));
    call symputx('hi_room', q3_room + 1.5*(q3_room-q1_room));
run;



data train;
    set train;

    if Age < &lo_age or Age > &hi_age then delete;
    if "Billing Amount"n < &lo_bill or "Billing Amount"n > &hi_bill then delete;
    if "Room Number"n < &lo_room or "Room Number"n > &hi_room then delete;
run;



/* Apply SAME limits to test (NO refitting) */
data test;
    set test;

    if Age < &lo_age or Age > &hi_age then delete;
    if "Billing Amount"n < &lo_bill or "Billing Amount"n > &hi_bill then delete;
    if "Room Number"n < &lo_room or "Room Number"n > &hi_room then delete;
run;

title "Boxplots for Key Numerical Variables";

proc sgplot data=train;
    vbox Age / fillattrs=(color="#C73865");
run;

proc sgplot data=train;
    vbox "Billing Amount"n / fillattrs=(color="#C73865");
run;

proc sgplot data=train;
    vbox "Room Number"n / fillattrs=(color="#C73865");
run;
/* =========================================
   7. FEATURE ENGINEERING
========================================= */


   data train test;
    set train test;

    /* Length of Stay */
    Length_of_Stay = "Discharge Date"n - "Date of Admission"n;

    if Length_of_Stay <= 0 then delete;

    /* Cost per Day */
    Cost_per_Day = "Billing Amount"n / Length_of_Stay;

    /* Age Group */
    if Age < 18 then Age_Group = "Child";
    else if Age < 40 then Age_Group = "Young";
    else if Age < 60 then Age_Group = "Middle";
    else Age_Group = "Senior";

    /* Emergency */
    Emergency_Flag = ("Admission Type"n = "Emergency");

    /* Chronic */
    Chronic_Flag = ("Medical Condition"n in ("Diabetes","Cancer","Heart Disease"));

    /* =========================
       FIXED TARGET (IMPORTANT)
       NOT DIRECT RULE FROM LENGTH_OF_STAY
    ========================== */

    High_Risk =
        (Age > 60) +
        (Chronic_Flag = 1) +
        (Cost_per_Day > 1000);

    if High_Risk >= 2 then High_Risk = 1;
    else High_Risk = 0;

run;
/* 7. Bill Level */
proc means data=train noprint;
    var "Billing Amount"n;
    output out=bill_stats p25=Q1 p75=Q3;
run;

data _null_;
    set bill_stats;
    call symputx('Q1', Q1);
    call symputx('Q3', Q3);
run;

data train test;
    set train test;

    if "Billing Amount"n < &Q1 then Bill_Level = "Low";
    else if "Billing Amount"n < &Q3 then Bill_Level = "Medium";
    else Bill_Level = "High";
run;


/* Show Results */
proc print data=train (obs=5);
    var Length_of_Stay Cost_per_Day Age_Group Emergency_Flag Bill_Level High_Risk Chronic_Flag;
run;

proc print data=test (obs=5);
    var Length_of_Stay Cost_per_Day Age_Group Emergency_Flag Bill_Level High_Risk Chronic_Flag;
run;

data train_pie;
    set train;

    length Risk_Level $10;

    if High_Risk = 1 then Risk_Level = "High Risk";
    else Risk_Level = "Low Risk";
run;
proc gchart data=train_pie;
    pie Risk_Level / value=inside percent=outside
                    fill=solid
                    slice=outside
                    value=none;

    title "Pie Chart of Patient Risk Levels";
run;
quit;

/* Age Distribution */
PROC SGPLOT DATA=WORK.train;
    VBAR Age_Group / DATALABEL FILLATTRS=(COLOR="#E17AB4");
    TITLE "Visualization 3: Age Distribution of Patients";
RUN;


/* =========================================
   8. FINAL MODEL DATA
========================================= */
data train test;
    set train test;
   drop 
        "Date of Admission"n
        "Discharge Date"n
        Name
        Room_Number
        Doctor
        Hospital;
run;

/* =========================================
   1. LOGISTIC REGRESSION MODEL
========================================= */

proc logistic data=train outmodel=log_model;

    class Age_Group Gender "Admission Type"n / param=ref;

    model High_Risk(event='1') =
        Age
        "Billing Amount"n
        Cost_per_Day
        Age_Group
        Gender
        "Admission Type"n
        Emergency_Flag
        Chronic_Flag;

    /* Score the test dataset */
    score data=test out=log_pred;

run;



/* =========================================
   2. DECISION TREE MODEL (HPSPLIT)
========================================= */

proc hpsplit data=train seed=123;

    class High_Risk Age_Group Gender "Admission Type"n;

    model High_Risk(event='1') =
        "Billing Amount"n
        Age_Group
        Gender
        "Admission Type"n
        Emergency_Flag;

    /* Validation split for evaluation */
    partition fraction(validate=0.3);

run;



/* =========================================
   3. LOGISTIC MODEL EVALUATION
========================================= */

proc freq data=log_pred;
    tables High_Risk * I_High_Risk / nocol nopercent;
run;



/* =========================================
   4. DECISION TREE ACCURACY
   (Calculated from validation output)
========================================= */

/* Replace values with your actual results */
data tree_accuracy;
    Accuracy_Tree = 1 - ((0.1142 + 0.3272) / 2);
run;

proc print data=tree_accuracy;
    title "Decision Tree Accuracy";
run;

/* =========================================
   FINAL MODEL COMPARISON (CORRECTED)
========================================= */

data comparison;
    Model = "Logistic";
    Accuracy = 17632 / 19008;   /* = 0.9275 */
    output;

    Model = "Decision Tree";
    Accuracy = (2824 + 1706) / (2824 + 401 + 733 + 1706);  /* = 0.799 */
    output;
run;



/* =========================================
   DISPLAY RESULTS
========================================= */

proc print data=comparison;
    title "Model Comparison: Logistic vs Decision Tree (Corrected)";
run;