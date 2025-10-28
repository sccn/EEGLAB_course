# Introduction

This repository is for the EEGLAB sessions of the [practical MEEG 2025 workshop](https://cuttingeeg.org/practicalmeeg2025/).

Word document
https://docs.google.com/document/d/1ZTAThzt1QemsTDz7Fl2ZCMVdU5sR7ExTkCLmn7gYJmE/edit?tab=t.0#heading=h.86k8by9oib0y

Presentations in the presentation folder

Posts at [https://forum.cuttingeeg.org/](https://forum.cuttingeeg.org/tag/eeglab)

# Sessions

- Session 1, Tue Oct 28, 10:30–12:30 — Preprocessing, segmentation and artefacts
- Session 2, Tue Oct 28, 15:10–17:10 — Tune in to your frequency space analysis
- Session 3, Wed Oct 29, 10:30–12:30 — Source level analysis I: Getting to source level maps
- Session 4, Wed Oct 29, 15:10–17:10 — Source level analysis II: Analysing source time-series
- Session 5, Thu Oct 30, 10:30–12:30 — Get and report results with confidence I: Univariate approach
- Session 6, Fri Oct 31, 10:30–12:30 — Get and report results with confidence II: Multivariate approach

# Data

We will use data from the multimodal face recognition dat. BIDS dataset containing a pruned version of the OpenNeuro dataset ds000117. It is available [here](https://zenodo.org/record/7410278).

The dataset above only contains one subject. For group level analysis, please use the following BIDS repository [here](https://openneuro.org/datasets/ds002718/versions/1.0.5).

The scripts using the single subject data assume the datafiles are located in the folder (Data/sub-01) located in the parent folder of this repository in your file system. See below the code used in the scripts to locate the file:

	RootFolder = fileparts(pwd); % Getting root folder
	path2data = fullfile(RootFolder,'Data', 'sub-01'); % Path to data 

For Session 5, copy the data folder (please rename to 'ds002718') containing the ds002718 in the same 'Data' folder. These files will be distributed later on.

# Preprocessing

For this presentation, we will first import the data with the [PracticalMEEG_Session_1_Import_Data.m](PracticalMEEG_Session_1_Import_Data.m) script. This script has 11 steps. 

* Step 1: Importing MEG data files with FileIO
* Step 2: Adding fiducials and rotating montage
* Step 3: Recomputing head center (for display only)
* Step 4: Re-import events from STI101 channel (the original ones are incorect)
* Step 5: Selecting EEG or MEG data 
* Step 6: Cleaning artefactual events (keep only valid event codes)
* Step 7: Fix button press info
* Step 8: Renaming button press events
* Step 9: Correcting event latencies (events have a shift of 34 ms as per the authors)
* Step 10: Replacing original imported channels
* Step 11: Creating folder to save data if does not exist yet

After importing the data, it is preprocessed using the [PracticalMEEG_Session_1_Preprocess_Data.m](PracticalMEEG_Session_1_Preprocess_Data.m) script. This script itself has several steps.

* Re-Reference the data
* Resampling the data (for speed)
* Filter the data
* Automatic rejection of bad channels
* Re-Reference again
* Repair bursts and reject bad portions of data
* run ICA to detect brain and artifactual components
* automatically classify Independent Components using IC Label
* Save dataset


# Single sensor analysis (ERP/ERF)

For this presentation, we will use different vizualization techniques using the [PracticalMEEG_Session_1_ERP_Analysis.m](PracticalMEEG_Session_1_ERP_Analysis.m) script. The script first further process the data as follow.

* Extract data epochs for the famous, scrambled, and unfamiliar face stimuli
* Remove the baseline from -1000 ms to 0 pre-stimulus
* Apply a threshold methods to remove spurious epochs
* Resave the data

Then it plots the data using the following methods:

* Plot ERP butterfly plot and scalp distribution at different latencies
* Remove ICA artifactual components and replot
* Plot series of scalp topography at different latencies
* Plot conditions overlaid on each other
* Plot ERPimages

# Time-frequency decomposition

For this presentation, we will the script [PracticalMEEG_Session_2_Time_Frequency_Analysis.m](PracticalMEEG_Session_2_Time_Frequency_Analysis.m). It performs the following steps.

* Spectral analysis for each of the conditions
* Time-frequency analysis for each of the conditions

# Single and distributed sources

For this presentation, we will the script [PracticalMEEG_Session_3_Source_Reconstruction.m](PracticalMEEG_Session_3_Source_Reconstruction.m). It performs the following steps.

* Definition of head model and source model
* Localization of ICA components
* Plotting of ICA components overlaid on 3-D template MRI

# Group-level analysis

The script [PracticalMEEG_ERP_Analysis_GroupAnalysis_support.m](PracticalMEEG_ERP_Analysis_GroupAnalysis_support.m) perform group analysis on a group of subjects.

* Removing components flagged for rejection using ICLabel
* Plotting grand average ERPs


