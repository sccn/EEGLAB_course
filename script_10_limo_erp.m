% Wakeman & Henson Data analysis: LIMO ERP analysis.
%
% Authors: Arnaud Delorme, Ramon Martinez-Cancino, Johanna Wagner, Romain Grandchamp

% to restart the analysis from here - simply reload the STUDY see pop_loadstudy
clear

studyfullname       = fullfile(pwd, 'ds002718/derivatives', 'Face_detection.study');
[root,std_name,ext] = fileparts(studyfullname); cd(root);       
EEG                 = eeglab;
[STUDY, ALLEEG]     = pop_loadstudy('filename', [std_name ext], 'filepath', root);
STUDY               = std_checkset(STUDY, ALLEEG);
[STUDY, ALLEEG]     = std_precomp(STUDY, ALLEEG, {}, 'savetrials','on','interp','on','recompute','on',...
    'erp','on','erpparams', {'rmbase' [-200 0]}, 'spec','off', 'ersp','off','itc','off');
eeglab redraw

%% One way repeated measures ANOVA (Famous, Unfamiliar, Scrambled faces as conditions)
% https://github.com/LIMO-EEG-Toolbox/limo_meeg/wiki/2.-One-way-repeated-measures-ANOVA-(Famous,-Unfamiliar,-Scrambled-faces-as-conditions)
% ---------------------------------------------------------------
% 1st level analysis - specify the design
% We ignore the repetition levels using the variable 'face_type'
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name','ANOVA_Faces','delfiles','off','defaultdesign','off',...
    'variable1','face_type','values1',{'famous','scrambled','unfamiliar'},'vartype1','categorical',...
    'subjselect',{'sub-002','sub-003','sub-004','sub-005','sub-006','sub-007','sub-008','sub-009',...
    'sub-010','sub-011','sub-012','sub-013','sub-014','sub-015','sub-016','sub-017','sub-018','sub-019'});
[STUDY, EEG] = pop_savestudy( STUDY, EEG, 'savemode','resave');

% 1st level analysis - estimate parameters
STUDY  = pop_limo(STUDY, ALLEEG, 'method','WLS','measure','daterp','timelim',[-50 650],'erase','on','splitreg','off','interaction','off');

% 2nd level analysis - ANOVA on Beta parameters 1 2 3
chanlocs = [STUDY.filepath filesep 'limo_gp_level_chanlocs.mat'];
cd(STUDY.filepath); mkdir('1-way-ANOVA'); cd('1-way-ANOVA')
limo_random_select('Repeated Measures ANOVA',chanlocs,'LIMOfiles',...
    {[STUDY.filepath filesep 'LIMO_Face_detection' filesep 'Beta_files_Face_detection_ANOVA_Faces_GLM_Channels_Time_WLS.txt']},...
    'analysis_type','Full scalp analysis','parameters',{[1 2 3]},...
    'factor names',{'face'},'type','Channels','nboot',1000,'tfce',0,'skip design check','yes');

% add contrast famous+unfamiliar>scrambled
limo_contrast(fullfile(pwd,'Yr.mat'),fullfile(pwd,'LIMO.mat'), 3 ,[0.5 -1 0.5]); % compute a new contrast
limo_contrast(fullfile(pwd,'Yr.mat'),fullfile(pwd,'LIMO.mat'), 4);               % do the bootstrap of the last contrast

% figures
limo_display_results(1,'ess_1.mat',pwd,0.05,2,fullfile(pwd,'LIMO.mat'),0); % course plot
saveas(gcf, 'contrast_image.fig'); close(gcf)
limo_display_results(3,'ess_1.mat',pwd,0.05,2,fullfile(pwd,'LIMO.mat'),0,'channels',49); % course plot
saveas(gcf, 'contrast_timecourse.fig'); close(gcf)

%% One way repeated measures ANOVA revised (Famous, Unfamiliar, Scrambled faces as 1st level contrasts)
% https://github.com/LIMO-EEG-Toolbox/limo_meeg/wiki/3.--One-way-repeated-measures-ANOVA-revised-(Famous,-Unfamiliar,-Scrambled-faces-as-1st-level-contrasts)
% Everything is modelled and contrasts are computed to merge repetition levels
% ---------------------------------------------------------------------------------
% 1st level analysis - specify the design
% Note we use the variable 'type' and use cells within a cell array to
% indicate grouping of conditions - this  means contrasts will be computed
% pooling those levels 
STUDY = std_makedesign(STUDY, ALLEEG, 2, 'name','FaceRepAll','delfiles','off','defaultdesign','off',...
    'variable1','type','values1',{{'famous_new','famous_second_early','famous_second_late'},...
    {'scrambled_new','scrambled_second_early','scrambled_second_late'},...
    {'unfamiliar_new','unfamiliar_second_early','unfamiliar_second_late'}},'vartype1','categorical',...
    'subjselect',{'sub-002','sub-003','sub-004','sub-005','sub-006','sub-007','sub-008','sub-009',...
    'sub-010','sub-011','sub-012','sub-013','sub-014','sub-015','sub-016','sub-017','sub-018','sub-019'});
[STUDY, EEG] = pop_savestudy( STUDY, EEG, 'savemode','resave');

% 1st level analysis - estimate parameters
[STUDY]      = pop_limo(STUDY, ALLEEG, 'method','WLS','measure','daterp','timelim',[-50 650],'erase','on','splitreg','off','interaction','off');

% 2nd level analysis - ANOVA on con_1, con_2, con_3
chanlocs   = [STUDY.filepath filesep 'limo_gp_level_chanlocs.mat'];
con1_files = fullfile(STUDY.filepath,[ 'LIMO_' STUDY.filename(1:end-6)],'con_1_files_Face_detection_FaceRepAll_GLM_Channels_Time_WLS.txt');
con2_files = fullfile(STUDY.filepath,[ 'LIMO_' STUDY.filename(1:end-6)],'con_2_files_Face_detection_FaceRepAll_GLM_Channels_Time_WLS.txt');
con3_files = fullfile(STUDY.filepath,[ 'LIMO_' STUDY.filename(1:end-6)],'con_3_files_Face_detection_FaceRepAll_GLM_Channels_Time_WLS.txt');

cd(STUDY.filepath); mkdir('1-way-ANOVA-revised'); cd('1-way-ANOVA-revised')
limo_random_select('Repeated Measures ANOVA',chanlocs,'LIMOfiles', {con1_files,con2_files,con3_files},...
    'analysis_type','Full scalp analysis','parameters',{[1 1 1]},...
    'factor names',{'face'},'type','Channels','nboot',1000,'tfce',0,'skip design check','yes');

% add contrast famous+unfamiliar>scrambled
limo_contrast(fullfile(pwd,'Yr.mat'),fullfile(pwd,'LIMO.mat'), 3 ,[0.5 -1 0.5]); % compute a new contrast
limo_contrast(fullfile(pwd,'Yr.mat'),fullfile(pwd,'LIMO.mat'), 4);               % do the bootstrap of the last contrast

% figures
limo_display_results(1,'ess_1.mat',pwd,0.05,2,fullfile(pwd,'LIMO.mat'),0); % image plot
saveas(gcf, 'contrast_image.fig'); close(gcf)
limo_display_results(3,'ess_1.mat',pwd,0.05,2,fullfile(pwd,'LIMO.mat'),0,'channels',49); % course plot
saveas(gcf, 'contrast_timecourse.fig'); close(gcf)

%% let's check effect sizes
% https://github.com/LIMO-EEG-Toolbox/limo_meeg/wiki/4.-Summary-statistics:-Effects-and-Effect-sizes

% the ANOVA plot shows the mean value differences corresponding to the contrast
% wich is only 2 differences - not that useful
limo_display_results(3,'Rep_ANOVA_Main_effect_1_face.mat',pwd,0.05,2,...
    fullfile(pwd,'LIMO.mat'),0,'channels',49,'sumstats','mean'); % course plot
saveas(gcf, 'Rep_ANOVA_Main_effect_timecourse.fig'); close(gcf)

%% One sample t test (contrasting Full Faces vs Scrambled Faces at the subject level)
% https://github.com/LIMO-EEG-Toolbox/limo_meeg/wiki/5.-One-sample-t-test-(contrasting-Full-Faces-vs-Scrambled-Faces-at-the-subject-level)

% for each subject, we have a model with 9 conditions: famous 1st, 2nd,
% 3rd, scrambled 1st, 2nd, 3rd and unfamiliar 1st, 2nd, 3rd 
% --> we could use a contrast testing the interaction effect
% --> let's use limo_batch to do all the contrasts, creating
%     a contrast strucure to pass as argument in

cd(STUDY.filepath)
[~,~,contrast.LIMO_files] = limo_get_files([],[],[],...
    fullfile(STUDY.filepath,['LIMO_' STUDY.filename(1:end-6)],...
    'LIMO_files_Face_detection_FaceRepAll_GLM_Channels_Time_WLS.txt'));
contrast.mat = [0.5 0.5 0.5 -1 -1 -1 0.5 0.5 0.5];
limo_batch('contrast only',[],contrast);

% let's compute the one-sample t-test on this contrast 
cd(STUDY.filepath); mkdir('one_sample'); cd('one_sample');
limo_random_select('one sample t-test',chanlocs,'LIMOfiles',...
    fullfile(STUDY.filepath,['LIMO_' STUDY.filename(1:end-6)],'con_4_files_Face_detection_FaceRepAll_GLM_Channels_Time_WLS.txt'),...
    'analysis_type','Full scalp analysis', 'type','Channels','nboot',101,'tfce',0);
limo_display_results(1,'one_sample_ttest_parameter_1.mat',pwd,0.05,2,fullfile(pwd,'LIMO.mat'),0,'sumstats','mean'); % image plot
saveas(gcf, 'One_sample_image.fig'); close(gcf)
limo_display_results(3,'one_sample_ttest_parameter_1.mat',pwd,0.05,2,fullfile(pwd,'LIMO.mat'),0,'channels',49,'sumstats','mean'); % course plot
saveas(gcf, 'One_sample_timecourse.fig'); close(gcf)

%% Two-ways Face * Repetition ANOVA
% https://github.com/LIMO-EEG-Toolbox/limo_meeg/wiki/7.-Two-way-ANOVA-(Faces-x-Repetition)

cd(STUDY.filepath); mkdir('Face-Repetition_ANOVA');cd('Face-Repetition_ANOVA')
LIMOPath = limo_random_select('Repeated Measures ANOVA',chanlocs,'LIMOfiles',...
    fullfile(STUDY.filepath,['LIMO_' STUDY.filename(1:end-6)],'Beta_files_Face_detection_FaceRepAll_GLM_Channels_Time_WLS.txt'),...
    'analysis_type','Full scalp analysis','parameters',{[1 2 3],[4 5 6],[7 8 9]},...
    'factor names',{'face','repetition'},'type','Channels','nboot',1000,'tfce',0,'skip design check','yes');

% add contrast famous>unfamiliar
limo_contrast(fullfile(pwd,'Yr.mat'),fullfile(pwd,'LIMO.mat'), 3 ,[1 1 1 0 0 0 -1 -1 -1]); % compute a new contrast
limo_contrast(fullfile(pwd,'Yr.mat'),fullfile(pwd,'LIMO.mat'), 4);                         % do the bootstrap - although here there is no effect anyway

% figures
limo_display_results(1,'Rep_ANOVA_Main_effect_1_face.mat',pwd,0.05,2,fullfile(pwd,'LIMO.mat'),0,'sumstats','mean'); % image plot
saveas(gcf, 'Rep_ANOVA_Main_effect_1_face.fig'); close(gcf)

%% paired t-test famous vs. unfamiliar controling for scrambled
% https://github.com/LIMO-EEG-Toolbox/limo_meeg/wiki/8.-Paired-t-test-(Famous-vs-Unfamiliar)

% let's say the research question is familiar vs unfamiliar and scrambled
% are just a control - doing the ANOVA is a little meaningless because you
% know include scrambled as a condition when in fact it's a control - using
% contrast we can buld that in

cd(STUDY.filepath)
[~,~,contrast.LIMO_files] = limo_get_files([],[],[],...
    fullfile(STUDY.filepath,['LIMO_' STUDY.filename(1:end-6)],...
    'LIMO_files_Face_detection_FaceRepAll_GLM_Channels_Time_WLS.txt'));
contrast.mat = [1 1 1 -1 -1 -1 0 0 0 ; 0 0 0 -1 -1 -1 1 1 1];
limo_batch('contrast only',[],contrast);

% note here con5 and con6 because in previous steps of the tutorial we have
% contrasts 1,2,3 from design and contrast 4 from the interaction effect
cd(STUDY.filepath); mkdir('Paired_ttest'); cd('Paired_ttest');
files = {fullfile(STUDY.filepath,['LIMO_' STUDY.filename(1:end-6)],'con_5_files_Face_detection_FaceRepAll_GLM_Channels_Time_WLS.txt'), ...
    fullfile(STUDY.filepath,['LIMO_' STUDY.filename(1:end-6)],'con_6_files_Face_detection_FaceRepAll_GLM_Channels_Time_WLS.txt')};
limo_random_select('paired t-test',chanlocs,'LIMOfiles',files,...
    'analysis_type','Full scalp analysis', 'type','Channels','nboot',1000,'tfce',0);
limo_display_results(1,'Paired_Samples_Ttest_parameter_5_6.mat',pwd,0.05,2,fullfile(pwd,'LIMO.mat'),0,'sumstats','mean');