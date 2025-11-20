% Wakeman & Henson Data analysis: Import raw data, rename events and channels, adjust latencies.
%
% Authors: Arnaud Delorme, Ramon Martinez-Cancino, Johanna Wagner, Romain Grandchamp
%
% This script imports raw brain recording data (EEG or MEG) and prepares it for analysis.
% It loads the data file, sets up channel locations, fixes event markers, and saves the result.

% script folder, this must be updated to the files on your enviroment.
clear;                                      % clearing all is recommended to avoid variable not being erased between calls 

% Choose which type of brain recording to process:
% - EEG: electrical activity from the brain (electrodes on scalp)
% - MEG: magnetic activity from the brain (magnetometers)
% Uncomment (remove the %) from ONE of the lines below to process that type
%chantype = { 'megmag' }; % Process MEG magnetometer channels
%chantype = { 'megplanar' }; % Process MEG planar gradiometer channels
chantype = { 'eeg' }; % Process EEG channels (currently selected)

% Set the path to where your data files are located
% The path below points to the data folder. Update this if your files are in a different location.
path2data = fullfile(pwd,'ds000117_pruned', 'derivatives', 'meg_derivatives', 'sub-01', 'ses-meg/', 'meg/'); 
filename = 'sub-01_ses-meg_task-facerecognition_run-01_proc-sss_meg.fif';

% Start EEGLAB - this opens the EEGLAB interface and initializes the workspace
[ALLEEG, EEG, CURRENTSET] = eeglab; 

%% IMPORTING THE DATA

% Step 1: Load the raw data file into EEGLAB
% This reads the brain recording file (in .fif format) and loads it into MATLAB
EEG = pop_fileio(fullfile(path2data, filename));

% Step 2: Set basic information about the dataset
EEG.filename = 'sub-01_ses-meg_task-facerecognition_run-01_proc-sss_meg.fif';
EEG.setname = 'sub-01_ses-meg_task-facerecognition_run-01_proc-sss_meg';
EEG.subject = 'sub-01';

%% SETTING UP CHANNEL LOCATIONS AND TYPES

% Step 3: Add fiducial points (anatomical landmarks) to help locate channels in 3D space
% Fiducials are reference points on the head: LPA (left ear), RPA (right ear), and Nz (nose)
% These coordinates were extracted from the dataset's coordinate system file
% Note: The channel locations from these points were extracted from the sub-01_ses-meg_coordsystem.json
% file and written here because File-IO doesn't automatically import these coordinates.
n = length(EEG.chanlocs)+1;
EEG = pop_chanedit(EEG, 'changefield',{n+0,'labels','LPA'},'changefield',{n+0,'X','0'},  'changefield',{n+0,'Y','7.1'},'changefield',{n+0,'Z','0'},...
                      'changefield',{n+1,'labels','RPA'},'changefield',{n+1,'X','0'}, 'changefield',{n+1,'Y','-7.756'},'changefield',{n+1,'Z','0'},...
                      'changefield',{n+2,'labels','Nz'} ,'changefield',{n+2,'Y','0'},'changefield',{n+2,'X','10.636'},'changefield',{n+2,'Z','0'});
EEG = eeg_checkset(EEG);

% Step 4: Fix incorrect channel types for eye and heart monitoring channels
% These channels record eye movements (HEOG, VEOG) and heart activity (EKG), not brain activity
% The raw data had incorrect labels, so we're correcting them and removing their 3D locations
% (since they're not brain channels, they don't need spatial coordinates)
EEG = pop_chanedit(EEG,'changefield',{367  'type' 'HEOG'  'X'  []  'Y'  []  'Z'  []  'theta'  []  'radius'  []  'sph_theta'  []  'sph_phi'  []  'sph_radius'  []});
EEG = pop_chanedit(EEG,'changefield',{368  'type' 'VEOG'  'X'  []  'Y'  []  'Z'  []  'theta'  []  'radius'  []  'sph_theta'  []  'sph_phi'  []  'sph_radius'  []});
EEG = pop_chanedit(EEG,'changefield',{369  'type' 'EKG'   'X'  []  'Y'  []  'Z'  []  'theta'  []  'radius'  []  'sph_theta'  []  'sph_phi'  []  'sph_radius'  []});
EEG = pop_chanedit(EEG,'changefield',{370  'type' 'EKG'   'X'  []  'Y'  []  'Z'  []  'theta'  []  'radius'  []  'sph_theta'  []  'sph_phi'  []  'sph_radius'  []});

%% FIXING EVENT MARKERS

% Step 5: Re-extract event markers from the STI101 channel
% Events mark when things happened during the experiment (like when a face was shown)
% The original events in the file were incorrect, so we're reading them from a special channel
% that recorded the actual event codes. We extract the first 5 bits of the signal.
edgelenval = 1;
EEG = pop_chanevent(EEG, 381,'edge','leading','edgelen',edgelenval,'delevent','on','delchan','off','oper','double(bitand(int32(X),31))');

%% SELECTING CHANNEL TYPE

% Step 6: Keep only the channels we want to analyze (EEG or MEG)
% This removes all other channel types, keeping only the ones specified in 'chantype' above
EEG = pop_select(EEG, 'chantype', chantype);
EEG.chaninfo = rmfield(EEG.chaninfo, 'topoplot');
EEG.chaninfo = rmfield(EEG.chaninfo, 'originalnosedir');

%% VISUALIZING CHANNEL LOCATIONS

% Step 7: Recalculate the center of the head (for visualization purposes only)
% This helps display the channel locations correctly on a head diagram
% Optional: This step is just for making nice plots, not required for analysis
EEG = pop_chanedit(EEG, 'eval','chans = pop_chancenter( chans, [],[])');
figure; topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);

%% CLEANING AND RENAMING EVENTS

% Step 8: Remove invalid event markers
% Keep only the event codes that represent actual experimental events
% The numbers [5 6 7 13 14 15 17 18 19] are the valid event codes for this experiment
% Note: This step may not be necessary for all datasets - it depends on your data quality
EEG = pop_selectevent( EEG, 'type',[5 6 7 13 14 15 17 18 19] ,'deleteevents','on');

% Step 9: Fix a specific event that had overlapping codes
% One event (event #74) had two codes mixed together (256 and 4096), so we fix it manually
EEG.event(74).type = 256; % This event was an artifact where two codes overlapped

% Step 10: Rename button press events to meaningful names
% The participant pressed buttons during the experiment. We rename the numeric codes
% to descriptive names so we can understand what happened later.
EEG = pop_selectevent( EEG, 'type',256, 'renametype', 'left_nonsym','deleteevents','off');  % Left button press for non-symmetric faces
EEG = pop_selectevent( EEG, 'type',4096,'renametype', 'right_sym','deleteevents','off');    % Right button press for symmetric faces

% Step 11: Rename face presentation events to meaningful names
% During the experiment, different types of faces were shown. The original data just had
% numbers (5, 6, 7, etc.), but we rename them to describe what was shown:
% - Famous: faces of famous people
% - Unfamiliar: faces of people the participant didn't know
% - Scrambled: scrambled/distorted face images
% Each type has three variants: new (first time shown), second_early, second_late (shown again)
EEG = pop_selectevent( EEG, 'type',5,'renametype','Famous','deleteevents','off');           % Famous face - first presentation
EEG = pop_selectevent( EEG, 'type',6,'renametype','Famous','deleteevents','off');           % Famous face - second presentation (early)
EEG = pop_selectevent( EEG, 'type',7,'renametype','Famous','deleteevents','off');           % Famous face - second presentation (late)

EEG = pop_selectevent( EEG, 'type',13,'renametype','Unfamiliar','deleteevents','off');     % Unfamiliar face - first presentation
EEG = pop_selectevent( EEG, 'type',14,'renametype','Unfamiliar','deleteevents','off');      % Unfamiliar face - second presentation (early)
EEG = pop_selectevent( EEG, 'type',15,'renametype','Unfamiliar','deleteevents','off');      % Unfamiliar face - second presentation (late)

EEG = pop_selectevent( EEG, 'type',17,'renametype','Scrambled','deleteevents','off');       % Scrambled face - first presentation
EEG = pop_selectevent( EEG, 'type',18,'renametype','Scrambled','deleteevents','off');       % Scrambled face - second presentation (early)
EEG = pop_selectevent( EEG, 'type',19,'renametype','Scrambled','deleteevents','off');       % Scrambled face - second presentation (late)

%% CORRECTING EVENT TIMING

% Step 12: Fix the timing of events (they were shifted by 34 milliseconds)
% Sometimes event markers are recorded slightly off from when things actually happened
% The authors of this dataset found that all events need to be shifted forward by 34 ms
% to align with when the faces actually appeared on screen
EEG = pop_adjustevents(EEG,'addms',34);

%% SAVE THE PREPARED DATASET

% Step 13: Save the imported and cleaned dataset
% Now that we've loaded the data, fixed the channels, and corrected the events,
% we save it as a .set file (EEGLAB's standard format) for use in later analysis steps
% You can also do this via the menu: File > Save current dataset as
% The folder will be created automatically if it doesn't exist
EEG = pop_saveset( EEG,'filename',['wh_S01'  '_run_01' '.set'],'filepath',path2data);

% Display a summary of all event types in the dataset (for verification)
eeg_eventtypes(EEG)
