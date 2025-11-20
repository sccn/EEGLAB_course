% Wakeman & Henson Data analysis: Epochs and ERP analysis.
%
% Authors: Arnaud Delorme, Ramon Martinez-Cancino, Johanna Wagner, Romain Grandchamp
%
% This script creates epochs (time windows around events) and computes Event-Related Potentials (ERPs).
% What are epochs? They are time windows (e.g., -1 to +2 seconds) around each event (like when a face was shown).
% What are ERPs? They are the average brain response across many trials. By averaging, we can see
% the brain's consistent response to a stimulus, even though individual trials are noisy.
% This script analyzes brain responses to three types of faces: Famous, Unfamiliar, and Scrambled.

%%
% Clearing all variables is recommended to avoid leftover variables from previous runs
clear;                                      

% Set the path to where your data files are located
% This loads the preprocessed dataset that was created by script_02_preprocess_data.m
path2data = fullfile(pwd,'ds000117_pruned', 'derivatives', 'meg_derivatives', 'sub-01', 'ses-meg/', 'meg/'); 
filename = 'wh_S01_run_01_preprocessing_data_session_1_out.set';

% Start EEGLAB - this opens the EEGLAB interface and initializes the workspace
[ALLEEG, EEG, CURRENTSET] = eeglab; 

% Load the preprocessed dataset
EEG = pop_loadset('filename', filename,'filepath',path2data);

% Add the loaded dataset to the ALLEEG structure (which can hold multiple datasets)
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 1); 

%% CREATING EPOCHS (TIME WINDOWS AROUND EVENTS)

% Extract time windows around each event to create epochs (trials)
% What are epochs? They are segments of data centered on an event (like when a face appeared).
% The time window [-1 2] means: 1 second BEFORE the event to 2 seconds AFTER the event.
% We create separate datasets for each condition (Famous, Unfamiliar, Scrambled) so we can
% compare how the brain responds differently to each type of face.
ALLEEG(2) = pop_epoch( ALLEEG(1), {'Famous'}, [-1  2], 'newname', 'Famous Epoched', 'epochinfo', 'yes');
ALLEEG(3) = pop_epoch( ALLEEG(1), {'Unfamiliar'}, [-1  2], 'newname', 'Unfamiliar Epoched', 'epochinfo', 'yes');
ALLEEG(4) = pop_epoch( ALLEEG(1), {'Scrambled'}, [-1  2], 'newname', 'Scrambled Epoched', 'epochinfo', 'yes');

%% BASELINE CORRECTION

% Remove the baseline (pre-stimulus activity) from each epoch
% What is baseline correction? Before the event happens, there's some baseline brain activity.
% We subtract this baseline from the entire epoch so that time 0 (when the face appears) becomes our reference.
% This makes it easier to see how the brain responds to the stimulus.
% The baseline period is [-1000 0] milliseconds (1 second before the event to the event itself).
ALLEEG(2) = pop_rmbase(ALLEEG(2), [-1000 0]);
ALLEEG(3) = pop_rmbase(ALLEEG(3), [-1000 0]);
ALLEEG(4) = pop_rmbase(ALLEEG(4), [-1000 0]);

%% REJECTING BAD EPOCHS

% Remove epochs (trials) that have too much noise or artifacts
% What are bad epochs? Some trials might have large artifacts (eye blinks, muscle activity, etc.)
% that weren't removed during preprocessing. We detect these by looking for epochs where
% the voltage goes outside a normal range (-400 to +400 microvolts).
% If any channel in an epoch exceeds these limits, the entire epoch is removed.
[ALLEEG(2), rejindx] = pop_eegthresh(ALLEEG(2), 1, 1:ALLEEG(2).nbchan, -400, 400, ALLEEG(2).xmin, ALLEEG(2).xmax, 0, 1);
[ALLEEG(3), rejindx] = pop_eegthresh(ALLEEG(3), 1, 1:ALLEEG(3).nbchan, -400, 400, ALLEEG(3).xmin, ALLEEG(3).xmax, 0, 1);
[ALLEEG(4), rejindx] = pop_eegthresh(ALLEEG(4), 1, 1:ALLEEG(4).nbchan, -400, 400, ALLEEG(4).xmin, ALLEEG(4).xmax, 0, 1);

%% SAVE THE EPOCHED DATASETS

% Save the epoched (trial-based) datasets for each condition
% These files contain all the individual trials, ready for computing ERPs
EEG_famous = pop_saveset( ALLEEG(2),'filename', 'wh_S01_run_01_ERP_Analysis_Session_2_famous_out.set','filepath',path2data);
EEG_unfamiliar = pop_saveset( ALLEEG(3),'filename', 'wh_S01_run_01_ERP_Analysis_Session_2_unfamiliar_out.set','filepath',path2data);
EEG_scrambled = pop_saveset( ALLEEG(4),'filename', 'wh_S01_run_01_ERP_Analysis_Session_2_scrambled_out.set','filepath',path2data);

%% ========================================================================
%% BELOW IS VISUALIZATION AND PLOTTING ONLY
%% ========================================================================
%% These sections create various plots to visualize the ERP results.
%% The ERPs are computed automatically when plotting (by averaging all trials).

%% PLOTTING ERP TIME COURSE AND SCALP DISTRIBUTION

% Create plots showing how the ERP changes over time and where on the scalp it's strongest
% These plots show the average brain response (ERP) from -100 to 600 ms after the face appeared
% The scalp maps show the distribution of activity across the head at different time points
figure; pop_timtopo(ALLEEG(2), [-100  600], [NaN], 'ERP data and scalp maps of Famous Epoched');
figure; pop_timtopo(ALLEEG(3), [-100  600], [NaN], 'ERP data and scalp maps of Unfamiliar Epoched');
figure; pop_timtopo(ALLEEG(4), [-100  600], [NaN], 'ERP data and scalp maps of Scrambled Epoched');

%% OPTIONAL: KEEP ONLY BRAIN COMPONENTS (FOR EEG DATA)

% If ICLabel was used during preprocessing, we can keep only the brain components
% This removes any remaining artifacts that might have been missed
% Note: This only works if the original dataset had ICA components classified
if isfield(ALLEEG(1).etc, 'ic_classification')
    % Find which ICA components were classified as "Brain" activity
    [M,I] = max(ALLEEG(1).etc.ic_classification.ICLabel.classifications,[],2);
    Brain_comps = find(I == find(strcmp(ALLEEG(1).etc.ic_classification.ICLabel.classes, 'Brain')));
    
    % Keep only the brain components, removing artifact components
    % This creates cleaner ERPs by removing any remaining eye blinks, muscle activity, etc.
    ALLEEG(2) = pop_subcomp( ALLEEG(2), Brain_comps, 0, 1);
    ALLEEG(3) = pop_subcomp( ALLEEG(3), Brain_comps, 0, 1);
    ALLEEG(4) = pop_subcomp( ALLEEG(4), Brain_comps, 0, 1);
end

%% RENAMING DATASETS FOR CLEARER PLOTS

% Give the datasets shorter, clearer names for the plots
ALLEEG(2) = pop_editset(ALLEEG(2), 'setname', 'Famous', 'run', []);
ALLEEG(3) = pop_editset(ALLEEG(3), 'setname', 'Unfamiliar', 'run', []);
ALLEEG(4) = pop_editset(ALLEEG(4), 'setname', 'Scrambled', 'run', []);

%% PLOTTING ERP SCALP DISTRIBUTION (AFTER CLEANING)

% Plot the ERP time course and scalp distribution again, now with cleaner data
figure; pop_timtopo(ALLEEG(2), [-100  600], [NaN], 'Famous');
figure; pop_timtopo(ALLEEG(3), [-100  600], [NaN], 'Unfamiliar');
figure; pop_timtopo(ALLEEG(4), [-100  600], [NaN], 'Scrambled');

%% PLOTTING ERP SCALP DISTRIBUTION AT SPECIFIC TIME POINTS

% Plot scalp maps at specific time points where ERP peaks typically occur
% The times [120 170 250] milliseconds correspond to common ERP components:
% - 120 ms: P1 (early visual response)
% - 170 ms: N170 (face-selective response)
% - 250 ms: P2 (later processing)
figure; pop_timtopo(ALLEEG(2), [-100  600], [120  170  250], 'Famous');
figure; pop_timtopo(ALLEEG(3), [-100  600], [120  170  250], 'Unfamiliar');
figure; pop_timtopo(ALLEEG(4), [-100  600], [120  170  250], 'Scrambled');

%% PLOTTING TOPOGRAPHIC MAPS AT MULTIPLE TIME POINTS

% Create 2D topographic maps showing activity distribution across the scalp
% These plots show how activity changes over time (every 25 ms from 25 to 300 ms)
pop_topoplot(ALLEEG(2), 1, [25:25:300] ,'Famous',[3 4] ,0,'electrodes','on');
pop_topoplot(ALLEEG(3), 1, [25:25:300] ,'Unfamiliar',[3 4] ,0,'electrodes','on');
pop_topoplot(ALLEEG(4), 1, [25:25:300] ,'Scrambled',[3 4] ,0,'electrodes','on');

%% PLOTTING ALL CHANNELS IN A TOPOGRAPHIC ARRAY

% Plot ERPs from all channels arranged in a topographic layout
% This shows the ERP waveform at each electrode position on the head
figure; pop_plottopo(ALLEEG(2), [1:EEG.nbchan] , 'Famous', 0, 'ydir',1);
figure; pop_plottopo(ALLEEG(3), [1:EEG.nbchan] , 'Unfamiliar', 0, 'ydir',1);
figure; pop_plottopo(ALLEEG(4), [1:EEG.nbchan] , 'Scrambled', 0, 'ydir',1);

%% PLOTTING AVERAGE ERPs WITH ERROR BARS (STANDARD DEVIATION)

% Plot the average ERP for each condition with shaded error bars showing variability
% This helps visualize both the average response and how consistent it is across trials

% Find which channel to plot (looking for channel 'EEG065', or use first channel if not found)
Chanind = find(strcmp({ALLEEG(2).chanlocs.labels},'EEG065'));
if isempty(Chanind)
    Chanind = 1;  % Use first channel if EEG065 doesn't exist
end

% Create a time vector for plotting (from -200 ms to 800 ms after the event)
% This focuses on the time window where most ERP activity occurs
[val, indL] = min(abs(ALLEEG(2).times+200));  % Find time point closest to -200 ms
[val, indU] = min(abs(ALLEEG(2).times-800));   % Find time point closest to 800 ms
timevec = ALLEEG(2).times(indL:indU);          % Extract time vector for this range

% Calculate the average ERP and standard deviation for Famous faces
% The mean is computed across all trials (dimension 3) to get the average ERP
% The standard deviation shows how much individual trials vary from the average
av_datavecF = mean(ALLEEG(2).data(Chanind,indL:indU,:),3);  % Average across trials
std_datavecF = std(ALLEEG(2).data(Chanind,indL:indU,:),1,3); % Standard deviation across trials

% Plot Famous faces ERP with shaded error region
figure;
% Create coordinates for filled area (error bars): go forward in time, then backward
X2 = [[timevec],fliplr([timevec])];  % X coordinates: time forward, then time backward
Y2 = [av_datavecF-std_datavecF,fliplr(av_datavecF+std_datavecF)];  % Y: mean - std, then mean + std
fill(X2,Y2,[153/255 204/255 255/255]);  % Fill the area with light blue (shows ±1 standard deviation)
hold on
plot(timevec,av_datavecF, 'b', 'LineWidth',2)  % Plot the average ERP line
xline(0, 'LineWidth',2)  % Vertical line at time 0 (when face appeared)
yline(0, 'LineWidth',2)  % Horizontal line at 0 voltage
xlabel('Time (milliseconds)')
ylabel('Amplitude (microvolts)')
title([ 'Famous faces - Channel ' EEG.chanlocs(Chanind).labels ]);
set(gca, 'FontSize', 15)

% Calculate average ERP and standard deviation for Unfamiliar faces
av_datavecU = mean(ALLEEG(3).data(Chanind,indL:indU,:),3);
std_datavecU = std(ALLEEG(3).data(Chanind,indL:indU,:),1,3);

% Plot Unfamiliar faces ERP with shaded error region
figure;
X2 = [[timevec],fliplr([timevec])];                %#create continuous x value array for plotting
Y2 = [av_datavecU-std_datavecU,fliplr(av_datavecU+std_datavecU)];              %#create y values for out and then back
fill(X2,Y2,[153/255 204/255 255/255]);
hold on
plot(timevec,av_datavecU, 'b', 'LineWidth',2)
xline(0, 'LineWidth',2)
yline(0, 'LineWidth',2)
xlabel('Time (milliseconds)')
ylabel('Amplitude (microvolts)')
title([ 'Unfamiliar faces - Channel ' EEG.chanlocs(Chanind).labels ]);
set(gca, 'FontSize', 15)

% Calculate average ERP and standard deviation for Scrambled faces
av_datavecS = mean(ALLEEG(4).data(Chanind,indL:indU,:),3);
std_datavecS = std(ALLEEG(4).data(Chanind,indL:indU,:),1,3);

% Plot Scrambled faces ERP with shaded error region
figure;
X2 = [[timevec],fliplr([timevec])];
Y2 = [av_datavecS-std_datavecS,fliplr(av_datavecS+std_datavecS)];
fill(X2,Y2,[153/255 204/255 255/255]);
hold on
plot(timevec,av_datavecS, 'b', 'LineWidth',2)
xline(0, 'LineWidth',2)
yline(0, 'LineWidth',2)
xlabel('Time (milliseconds)')
ylabel('Amplitude (microvolts)')
title([ 'Scrambled faces - Channel ' EEG.chanlocs(Chanind).labels ]);
set(gca, 'FontSize', 15)

%% PLOTTING ALL CONDITIONS TOGETHER (COMPARISON PLOT)

% Plot all three conditions on the same graph to compare them
% This makes it easy to see differences between how the brain responds to different face types
figure;
plot(timevec,av_datavecF, 'LineWidth',2, 'color', 'r'); hold on  % Famous = red
plot(timevec,av_datavecU, 'LineWidth',2, 'color', 'b')           % Unfamiliar = blue
plot(timevec,av_datavecS, 'LineWidth',2, 'color', 'g')           % Scrambled = green
% Add shaded error regions for each condition (semi-transparent)
fillcurves(timevec,av_datavecF-std_datavecF,av_datavecF+std_datavecF, 'r', 0.2);
fillcurves(timevec,av_datavecU-std_datavecU,av_datavecU+std_datavecU, 'b', 0.2);
fillcurves(timevec,av_datavecS-std_datavecS,av_datavecS+std_datavecS, 'g', 0.2);
xline(0, 'LineWidth',2)  % Vertical line at time 0
yline(0, 'LineWidth',2)  % Horizontal line at 0 voltage
xlabel('Time (milliseconds)')
ylabel('Amplitude (microvolts)')
legend('Famous', 'Unfamiliar', 'Scrambled')
set(gca, 'FontSize', 15)
title([ 'Comparison of face types - Channel ' EEG.chanlocs(Chanind).labels ]);

%% CREATING ERPIMAGE PLOTS

% ERPimage shows each individual trial as a row, sorted by some criterion
% What is an ERPimage? It's a visualization where:
% - Each row = one trial (epoch)
% - Color = voltage amplitude (red = positive, blue = negative)
% - Time = horizontal axis
% - The average ERP is shown at the bottom
% This helps you see trial-by-trial variability and whether the ERP is consistent
figure; pop_erpimage(ALLEEG(2),1, [Chanind],[[]],EEG.chanlocs(Chanind).labels,3,1,{},[],'' ,'yerplabel','\muV','erp','on','limits',[-100 1200 NaN NaN NaN NaN NaN NaN] ,'cbar','on','topo', { [Chanind] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(ALLEEG(3),1, [Chanind],[[]],EEG.chanlocs(Chanind).labels,3,1,{},[],'' ,'yerplabel','\muV','erp','on','limits',[-100 1200 NaN NaN NaN NaN NaN NaN] ,'cbar','on','topo', { [Chanind] EEG.chanlocs EEG.chaninfo } );
figure; pop_erpimage(ALLEEG(4),1, [Chanind],[[]],EEG.chanlocs(Chanind).labels,3,1,{},[],'' ,'yerplabel','\muV','erp','on','limits',[-100 1200 NaN NaN NaN NaN NaN NaN] ,'cbar','on','topo', { [Chanind] EEG.chanlocs EEG.chaninfo } );

% Optional: Sort trials by button press latency (how quickly the participant responded)
% This can reveal if faster responses are associated with different brain activity
% Uncomment these lines if you want to see trials sorted by response time:
% figure; pop_erpimage(ALLEEG(2),1, [Chanind],[[]],EEG.chanlocs(Chanind).labels,3,1,{ 'left_nonsym' 'right_sym'},[],'latency' ,'yerplabel','\muV','erp','on','limits',[-100 1200 NaN NaN NaN NaN NaN NaN] ,'cbar','on','topo', { [Chanind] EEG.chanlocs EEG.chaninfo } );
% figure; pop_erpimage(ALLEEG(3),1, [Chanind],[[]],EEG.chanlocs(Chanind).labels,3,1,{ 'left_nonsym' 'right_sym'},[],'latency' ,'yerplabel','\muV','erp','on','limits',[-100 1200 NaN NaN NaN NaN NaN NaN] ,'cbar','on','topo', { [Chanind] EEG.chanlocs EEG.chaninfo } );
% figure; pop_erpimage(ALLEEG(4),1, [Chanind],[[]],EEG.chanlocs(Chanind).labels,3,1,{ 'left_nonsym' 'right_sym'},[],'latency' ,'yerplabel','\muV','erp','on','limits',[-100 1200 NaN NaN NaN NaN NaN NaN] ,'cbar','on','topo', { [Chanind] EEG.chanlocs EEG.chaninfo } );
