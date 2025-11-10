% Wakeman & Henson Data analysis: Group analysis preprocessing.
%
% Authors: Arnaud Delorme, Ramon Martinez-Cancino, Johanna Wagner, Romain Grandchamp

%% Import
% start EEGLAB
clear
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
pop_editoptions( 'option_storedisk', 1);
 
% call BIDS tool BIDS
filepath        = fullfile(pwd, 'ds002718'); 
[STUDY, ALLEEG] = pop_importbids(filepath, 'bidsevent','on','bidschanloc','on', 'studyName','Face_detection','outputdir', fullfile(filepath, 'derivatives'), 'eventtype', 'trial_type');
ALLEEG = pop_select( ALLEEG, 'nochannel',{'EEG061','EEG062','EEG063','EEG064'});
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];
eeglab redraw

% Preprocessing
% Remove bad channels
EEG = pop_clean_rawdata( EEG,'FlatlineCriterion',5,'ChannelCriterion',0.8,...
    'LineNoiseCriterion',2.5,'Highpass',[0.25 0.75] ,...
    'BurstCriterion','off','WindowCriterion','off','BurstRejection','off',...
    'Distance','Euclidian','WindowCriterionTolerances','off');;

% Rereference using average reference
EEG = pop_reref( EEG,[],'interpchan',[]);

% Run ICA and flag artifactual components using IClabel
EEG = pop_runica(EEG, 'icatype','runica','concatcond','on','options',{'pca',-1});
EEG = pop_iclabel(EEG,'default');
EEG = pop_icflag(EEG,[NaN NaN;0.8 1;0.8 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
EEG = pop_subcomp(EEG, [], 0); % remove pre-flagged bad components

% clear data using ASR - just the bad epochs
EEG = pop_clean_rawdata( EEG,'FlatlineCriterion','off','ChannelCriterion','off',...
    'LineNoiseCriterion','off','Highpass','off','BurstCriterion',20,...
    'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian',...
    'WindowCriterionTolerances',[-Inf 7] );

% Extract data epochs (no baseline removed)
EEG    = pop_epoch( EEG,{'famous_new','famous_second_early','famous_second_late','scrambled_new','scrambled_second_early','scrambled_second_late','unfamiliar_new','unfamiliar_second_early','unfamiliar_second_late'},...
    [-0.5 1] ,'epochinfo','yes');
EEG    = eeg_checkset(EEG);
EEG    = pop_saveset(EEG, 'savemode', 'resave');
ALLEEG = EEG;

ALLEEG = pop_dipfit_settings( ALLEEG, 'model', 'standardBEM', 'coord_transform', 'warpfiducials');
% % plot allignement (not great on some subjects)
% for iEEG = 1:length(ALLEEG)
%     [~, tmptransf] = coregister(ALLEEG(iEEG).chanlocs, ALLEEG(iEEG).dipfit.chanfile, 'mesh', ALLEEG(iEEG).dipfit.hdmfile, 'transform', ...
%                                 ALLEEG(iEEG).dipfit.coord_transform, 'chaninfo1', ALLEEG(iEEG).chaninfo, 'helpmsg', 'on');
% end
ALLEEG = pop_multifit(ALLEEG, 1:10,'threshold', 100, 'dipplot','off','plotopt',{'normlen' 'on'}); % only 10 fine fit for speed
ALLEEG = pop_saveset(ALLEEG, 'savemode','resave');

% update study & compute single trials
STUDY  = std_checkset(STUDY, ALLEEG);
[STUDY, EEG] = std_precomp(STUDY, EEG, {}, 'savetrials','on','interp','on','recompute','on',...
    'erp','on','erpparams', {'rmbase' [-200 0]}, 'spec','off', 'ersp','off','itc','off');
