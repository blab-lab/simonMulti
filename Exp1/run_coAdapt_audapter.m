function [expt] = run_coAdapt_audapter(expt)
% 
%                   outputdir: directory where data is saved
%                   expt: expt params set up in wrapper function
%                   h_fig: figure handles for display

if nargin < 1, error('Need expt file to run this function'); end

% assign folder for saving trial data
% create output directory if it doesn't exist
trialdirname = 'temp_trials';
outputdir = expt.dataPath;
trialdir = fullfile(outputdir, trialdirname);
if ~exist(trialdir, 'dir')
    mkdir(trialdir)
end

% set experiment-specific fields (or pass them in as 'expt')
stimtxtsize = 200;
%set RMS threshold for deciding if a trial is good or not
rmsThresh = 0.04;

% set missing expt fields to defaults
expt = set_exptDefaults(expt);
save(fullfile(outputdir,'expt.mat'), 'expt');

firstTrial = expt.startTrial; % defaults to 1
lastTrial = expt.ntrials;

%% set up audapter
audioInterfaceName = 'Focusrite USB'; %SMNG default for Windows 10
Audapter('deviceName', audioInterfaceName);

%instead of using OST and PCF for coAdapt, we use pertPhi and pertMag.
  %pertPhi (aka pertAngles) is always 0, and pertMag is either -1, 0, or 1
Audapter('ost', '', 0);     % nullify online status tracking/
Audapter('pcf', '', 0);     % pert config files (use pert field instead)
    
%other settings
audioInterfaceName = 'Focusrite USB'; %SMNG default for Windows 10
sRate = 48000;  % Hardware sampling rate (before downsampling)
downFact = 3; % For most studies, we will sample downsample the data by 3 for a final sampling rate of 16 kHz.
frameLen = 96/downFact;  % Before downsampling

Audapter('deviceName', audioInterfaceName);
Audapter('setParam', 'sRate', sRate / downFact, 0);
Audapter('setParam', 'downFact', downFact, 0);
Audapter('setParam', 'frameLen', frameLen, 0);

% set audapter params
p = getAudapterDefaultParams(expt.gender); % get default params
% overwrite selected params with experiment-specific values:
if isfield(expt, 'audapterParams')
    p = add2struct(p, expt.audapterParams);
end
p.bPitchShift = 0; % Set to 1 if using time warping or a pitch perturbation
p.downFact = downFact;
p.sr = sRate / downFact;
p.frameLen = frameLen;
p.bShift = 1;
p.bRatioShift = 0;
p.bMelShift = 1;
p.bShift2D = 0; %flag for 2D experiment

% set noise
w = get_noiseSource(p);
Audapter('setParam', 'datapb', w, 1);
p.fb = 3;          % set feedback mode to 3: speech + noise
p.fb3Gain = 0.02;   % gain for noise waveform

%% initialize Audapter 
AudapterIO('init', p);

%% run experiment
% setup figures
h_fig = setup_exptFigs;
get_figinds_audapter; % names figs: stim = 1, ctrl = 2, dup = 3;
h_sub = get_subfigs_audapter(h_fig(ctrl),1);

% give instructions and wait for keypress
h_ready = draw_exptText(h_fig,.5,.5,expt.instruct.introtxt,expt.instruct.txtparams);
pause
delete_exptText(h_fig,h_ready)

% run trials
pause(1)
for itrial = firstTrial:lastTrial  % for each trial
    bGoodTrial = 0;
    while ~bGoodTrial
        % pause if 'p' is pressed
        if get_pause_state(h_fig,'p')
            pause_trial(h_fig);
        end

        % set trial index
        trial_index = itrial;

        % plot trial number in experimenter view
        cla(h_sub(1))
        ctrltxt = sprintf('trial: %d/%d, cond: %s',trial_index,expt.ntrials,expt.listConds{trial_index});
        h_trialn = text(h_sub(1),0,0.5,ctrltxt,'Color','black', 'FontSize',30, 'HorizontalAlignment','center');

        % set text
        txt2display = expt.listStimulusText{trial_index};
        color2display = expt.colorvals{expt.allColors(trial_index)};

        % set new perturbation
        %p.pertPhi is always zeros(1, 257)
        p.pertAmp = expt.shiftMags(trial_index) * ones(1, 257);
        Audapter('setParam','pertAmp',p.pertAmp)
        
        % run trial in Audapter
        Audapter('reset'); %reset Audapter
        fprintf('starting trial %d\n',trial_index)
        Audapter('start'); %start trial

        fprintf('Audapter started for trial %d\n',trial_index)
        % display stimulus
        h_text(1) = draw_exptText(h_fig,.5,.5,txt2display, 'Color',color2display, 'FontSize',stimtxtsize, 'HorizontalAlignment','center');
        pause(expt.timing.stimdur);

        % stop trial in Audapter
        Audapter('stop');
        fprintf('Audapter ended for trial %d\n',trial_index)
        % get data
        data = AudapterIO('getData');

        % plot shifted spectrogram
        subplot_expt_spectrogram(data, p, h_fig, h_sub)
        
        %check if good trial
        bGoodTrial = check_rmsThresh(data,rmsThresh,h_sub(3));
        
        % clear screen
        delete_exptText(h_fig,h_text)
        clear h_text

        if ~bGoodTrial
            h_text = draw_exptText(h_fig,.5,.2,'Please speak a little louder','FontSize',40,'HorizontalAlignment','center','Color','y');
            pause(1)
            delete_exptText(h_fig,h_text)
            clear h_text
        end
        
        % add intertrial interval + jitter
        pause(expt.timing.interstimdur + rand*expt.timing.interstimjitter);

        % save trial
        trialfile = fullfile(trialdir,sprintf('%d.mat',trial_index));
        save(trialfile,'data')

        % clean up data
        clear data
    end
    % display break text
    if itrial == lastTrial
        breaktext = sprintf('Thank you!\n\nPlease wait.');
        draw_exptText(h_fig,.5,.5,breaktext,expt.instruct.txtparams);
        pause(3);
    elseif any(expt.breakTrials == trial_index)
        breaktext = sprintf('Time for a break!\n%d of %d trials done.\n\nPress the space bar to continue.',itrial,lastTrial);
        h_break = draw_exptText(h_fig,.5,.5,breaktext,expt.instruct.txtparams);
        pause
        delete_exptText(h_fig,h_break)
        pause(1);
    end
    
end

%% compile trials into data.mat. Save metadata.
alldata = struct;
fprintf('Processing data\n')
for i = 1:expt.ntrials
    trialfile = fullfile(trialdir,sprintf('%d.mat',i));
    if exist(trialfile,'file')
        load(trialfile,'data')
        names = fieldnames(data);
        for j = 1:length(names)
            alldata(i).(names{j}) = data.(names{j});
        end
    else
        warning('Trial %d not found.',i)
    end
end

fprintf('Saving data... ')
clear data
data = alldata;
save(fullfile(outputdir,'data.mat'), 'data')
fprintf('saved.\n')

fprintf('Saving expt... ')
save(fullfile(outputdir,'expt.mat'), 'expt')
fprintf('saved.\n')

fprintf('Removing temp directory... ')
rmdir(trialdir,'s');
fprintf('done.\n')

%% close figures
close(h_fig)


end %EOF