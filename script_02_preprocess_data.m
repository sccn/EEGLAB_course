% Wakeman & Henson Data analysis: Preprocess data.
%
% Authors: Arnaud Delorme, Ramon Martinez-Cancino, Johanna Wagner, Romain Grandchamp
%
% This script preprocesses (cleans and prepares) brain recording data for analysis.
% Preprocessing removes noise, artifacts, and unwanted signals so you can study the brain activity.
% Steps include: re-referencing, filtering, removing bad channels, and separating brain signals
% from artifacts using Independent Component Analysis (ICA).

%%
% Clearing all variables is recommended to avoid leftover variables from previous runs
clear;                                      

% Set the path to where your data files are located
% This loads the dataset that was created by script_01_import_data.m
path2data = fullfile(pwd,'ds000117_pruned', 'derivatives', 'meg_derivatives', 'sub-01', 'ses-meg/', 'meg/'); 
filename = 'wh_S01_run_01.set';

% Start EEGLAB - this opens the EEGLAB interface and initializes the workspace
[ALLEEG, EEG, CURRENTSET] = eeglab; 

%% LOADING THE DATA

% Load the dataset that was prepared in script_01_import_data.m
% You can also do this via the menu: File > Load existing dataset
EEG = pop_loadset('filename', filename,'filepath',path2data);

%% Re-Reference
% use menu item Tools > Re-reference the data
% Apply Common Average Reference
EEG = pop_reref(EEG,[]); % menu item Tools > Rereference (eegh)

%% Resampling
% use menu item Tools > Change sampling rate
% Downsampling to 100 Hz for speed (for real analysis prefer 250 or 500 Hz)
EEG = pop_resample(EEG, 100);

%% Filter
% use menu item Tools > Filter the data > Basic FIR filter
% Filter the data Highpass at 1 Hz Lowpass at 40Hz (to avoid line noise at 100Hz)
EEG = pop_eegfiltnew(EEG, 1, 0);   % High pass at 1Hz
EEG = pop_eegfiltnew(EEG, 0, 40);  % Low pass below 40

% Apply filters to remove unwanted frequency components
% What is filtering? It removes certain frequencies (like very slow drifts or high-frequency noise)
% - High-pass filter at 1 Hz: Removes very slow drifts (like from sweating or breathing)
% - Low-pass filter at 40 Hz: Removes high-frequency noise (like muscle activity, line noise at 50/60 Hz)
% This keeps the brain signals we care about (typically 1-40 Hz for most EEG studies)
% You can also do this via the menu: Tools > Filter the data > Basic FIR filter
EEG = pop_eegfiltnew(EEG, 1, 0);   % High-pass filter: keep frequencies above 1 Hz
EEG = pop_eegfiltnew(EEG, 0, 40);  % Low-pass filter: keep frequencies below 40 Hz

%% AUTOMATICALLY DETECTING AND REMOVING BAD CHANNELS

% Automatically find and remove channels that are recording poorly
% What are bad channels? These are electrodes that have:
% - Poor contact with the scalp (loose electrodes)
% - Too much noise or artifacts
% - Unusual signals compared to other channels
% The algorithm compares each channel to others - if it's too different, it's marked as bad
% Different thresholds are used for MEG (0.4) vs EEG (0.9) because they have different signal characteristics
% You can also do this via the menu: Tools > Reject data using Clean_rawdata and ASR
if contains(EEG.chanlocs(1).type, 'meg')
    minChanCorr = 0.4;  % MEG channels need lower correlation threshold (they're naturally more variable)
else
    minChanCorr = 0.9;  % EEG channels should be highly correlated with neighbors
end
EEG = clean_artifacts(EEG, 'Highpass', 'off',...              % Don't apply high-pass filter (we already did)
                           'ChannelCriterion', minChanCorr,... % Threshold for detecting bad channels
                           'ChannelCriterionMaxBadTime', 0.4,... % Max fraction of time a channel can be bad
                           'LineNoiseCriterion', 4,...         % Threshold for detecting line noise (50/60 Hz)
                           'BurstCriterion', 'off',...         % Don't detect burst artifacts yet
                           'WindowCriterion','off' );           % Don't detect bad time windows yet

%% RE-REFERENCING AGAIN (AFTER REMOVING BAD CHANNELS)

% Re-reference again because removing bad channels changes the average
% When we remove bad channels, the average of all channels changes, so we need to recalculate
EEG = pop_reref(EEG,[]);

%% REMOVING BAD TIME PERIODS AND BURST ARTIFACTS

% Now detect and remove bad time periods (when artifacts occurred)
% What are burst artifacts? These are sudden, large-amplitude events like:
% - Eye blinks
% - Muscle movements
% - Head movements
% - Electrical interference
% The algorithm finds time periods where the signal is too different from normal
% and marks them for removal. We'll remove them after ICA (next step)
EEG = clean_artifacts( EEG, 'Highpass', 'off',...              % Don't apply high-pass filter
                            'ChannelCriterion', 'off',...       % Don't detect more bad channels
                            'LineNoiseCriterion', 'off',...     % Don't detect line noise
                            'BurstCriterion', 30,...           % Threshold for detecting burst artifacts
                            'WindowCriterion',0.3);             % Threshold for detecting bad time windows

%% RUNNING INDEPENDENT COMPONENT ANALYSIS (ICA)

% Separate the brain signals into independent components
% What is ICA? It's a mathematical technique that separates mixed signals into their sources.
% Think of it like separating voices in a crowded room - each component represents a different source:
% - Some components = brain activity (what we want to keep)
% - Some components = eye blinks, muscle activity, heart beats, line noise (what we want to remove)
% The '-1' accounts for the fact that re-referencing reduces the number of independent signals by 1
% You can also do this via the menu: Tools > Decompose by ICA
if exist('picard') % Check if Picard plugin is installed (faster algorithm)
    EEG = pop_runica( EEG , 'picard', 'maxiter', 500, 'pca', -1); % Use Picard if available (faster)
else
    EEG = pop_runica( EEG , 'runica', 'extended',1, 'pca', -1);   % Use standard ICA algorithm
end

%% AUTOMATICALLY IDENTIFYING AND REMOVING ARTIFACT COMPONENTS

% Use ICLabel to automatically classify each ICA component
% What is ICLabel? It's a machine learning tool that looks at each component and classifies it as:
% - Brain activity (keep this!)
% - Eye blinks (remove)
% - Muscle activity (remove)
% - Heart activity (remove)
% - Line noise (remove)
% - Channel noise (remove)
% - Other artifacts (remove)
% Note: This only works for EEG data. For MEG, you would need to manually inspect components.
% You can also do this via the menu: Tools > Classify components using ICLabel > Label components
if ~contains(EEG.chanlocs(1).type, 'meg') % Only for EEG (not MEG)
    % Classify each component using machine learning
    EEG = iclabel(EEG);
    
    % Set thresholds for automatic removal:
    % [Brain threshold; Eye threshold; Muscle threshold; Heart threshold; Line noise; Channel noise; Other]
    % 0.9 means: if component is 90% likely to be that type, flag it for removal
    % NaN means: don't automatically remove based on that category
    EEG = pop_icflag( EEG,[NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
    
    % Remove the components that were flagged as artifacts (eye, muscle, etc.)
    % This subtracts the artifact components from the data, leaving clean brain signals
    EEG = pop_subcomp(EEG, [], 0);
end

%% SAVE THE PREPROCESSED DATASET

% Save the cleaned and preprocessed dataset
% Now that we've removed bad channels, filtered noise, and removed artifacts,
% we save the clean data for further analysis (like creating epochs and computing ERPs)
% You can also do this via the menu: File > Save current dataset as
EEG = pop_saveset( EEG,'filename', 'wh_S01_run_01_preprocessing_data_session_1_out.set','filepath',path2data);
