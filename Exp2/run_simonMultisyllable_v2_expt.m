function expt = run_simonMultisyllable_v2_expt(expt, bTestMode)
% RUN_SIMONSINGLEWORD_EXPT    One part of a series of studies
% using Audapter to alter vowel formants simulataneously ("simon") across a
% set of words. Each word receives a different perturbation--one word
% receives a positive F1 shift, one word receives a negative F1 shift, and
% one word receives no shift.
%
% In this multisyllable variant, the stimulus words are multiple syllables,
% but the first syllable is the same among all words (excl. distractor). This
% first syllable is the only syllable which receives an F1 perturbation.
%
% "Version 2" of simonMultisyllable was initiated in 2022-02. It contains 3
% stimulus words instead of 4; there is now only the two words which start
% the same and are either perturbed up or down, and the unperturbed
% distractor. There is no unperturbed word similar to other words.

% 2021-08. Programmed by Tahseen Shaik and Ben Parrell.
% 2021-10. Shift direction code changed - Chris Naber.
% 2022-01. Updated to add catch trials - Carrie Niziolek.

if nargin < 1, expt = []; end
if nargin < 2 || isempty(bTestMode), bTestMode = 0; end

%% Experiment Setup
expt.name = 'simonMultisyllable_v2';
if ~isfield(expt,'snum'), expt.snum = get_snum; end
expt.dataPath = get_acoustSavePath(expt.name, expt.snum);
if ~exist(expt.dataPath,'dir')
    mkdir(expt.dataPath)
end
rng('shuffle');

expt.trackingFileLoc = expt.name; 
expt.trackingFileName = 'sevXXX';
refreshWorkingCopy(expt.trackingFileLoc, expt.trackingFileName, 'both');

% load in existing expt.mat, if there is one
if isfile(fullfile(expt.dataPath, 'expt.mat'))
    bOverwrite = askNChoiceQuestion('This participant already exists. Load in existing expt?', {'y' 'n'});
    if strcmp(bOverwrite,'y')
        load(fullfile(expt.dataPath, 'expt.mat'), 'expt')
    end
end
    
if ~isfield(expt,'gender'), expt.gender = get_height; end

expt.words = {'seven', 'sever', 'level'}; % distractor (level) always = noShift
expt.stimulusText = {'SEVEN' 'SEVER' 'LEVEL'};

%% Set up and run first pre-experiment phase to set LPC order

if ~bTestMode
    bRunLPCcheck = 1;
else
    bRunLPCcheck = askNChoiceQuestion('[Test mode only] Run LPC check pretest phase (1), or skip it (0)? ', [1 0]);
end

if bRunLPCcheck
    exptpre = expt;
    exptpre.dataPath = fullfile(expt.dataPath,'pre');
    
    %Switch to bid/bed/bat for collection of formant means
    exptpre.words = {'bid' 'bed' 'bat'};
    nwordspre = length(exptpre.words);
    
    % Set to use default single-syllable, one word Audapter OST file
    exptpre.trackingFileLoc = 'experiment_helpers';
    exptpre.trackingFileName = 'measureFormants';
    
    %Where nblocks is the number of repetitions for each word.
    if bTestMode
        exptpre.nblocks = 2;
    else
        exptpre.nblocks = 10;
    end
    
    exptpre.ntrials = exptpre.nblocks * nwordspre;
    exptpre.breakFrequency = exptpre.ntrials;
    exptpre.breakTrials = exptpre.ntrials;
    exptpre.conds = {'noShift'};
    exptpre = set_exptDefaults(exptpre); % set missing expt fields to defaults
    
    %run pre-experiment data collection
    refreshWorkingCopy('experiment_helpers', 'measureFormants', 'both');
    exptpre = run_measureFormants_audapter(exptpre,3);
    
    %check LPC order
    check_audapterLPC(exptpre.dataPath)
    hGui = findobj('Tag','check_LPC');
    waitfor(hGui);
    
    %set lpc order
    load(fullfile(exptpre.dataPath,'nlpc'),'nlpc')
    p.nLPC = nlpc;
    expt.audapterParams = p;
    
    % save expt
    if ~exist(expt.dataPath,'dir')
        mkdir(expt.dataPath)
    end
    exptfile = fullfile(expt.dataPath,'expt.mat');
    save(exptfile, 'expt')
    fprintf('Saved expt file: %s.\n',exptfile);

    input('Press ENTER to continue to OST Check pretest phase', 's');
end

%% Set up and run second pre-experiment phase to check OST tracking
exptost = expt;
nwordsost = length(exptost.words);

if ~bTestMode
    bGoodOSTs = 0;
    exptost.ntrials = 5*nwordsost;
else
    bRunPretest = askNChoiceQuestion('[Test mode only] Run ost pretest phase (1), or skip it (0)?', [1 0]);
    bGoodOSTs = ~bRunPretest;
    exptost.ntrials = 2*nwordsost;
end

while ~bGoodOSTs
    exptost.dataPath = fullfile(expt.dataPath, 'ost_check');
    
    exptost.conds = {'ost_check'};
    exptost.words = expt.words; 
    
    exptost.trackingFileName = expt.trackingFileName;
    exptost.trackingFileLoc = expt.trackingFileLoc;
    
    exptost = set_exptDefaults(exptost);
    
    % run ost_check phase
    exptost = run_simonMultisyllable_v2_audapter(exptost); 
    
    % view ost_check trials in audapter_viewer
    fprintf('Loading ost_check data... ')
    load(fullfile(exptost.dataPath, 'data.mat'), 'data');
    fprintf('Done\n')

    audapter_viewer(data, exptost);
    hGui = findobj('Tag','audapter_viewer');
    waitfor(hGui);
    
    % Decide to redo or move on
    moveOn_resp = askNChoiceQuestion('Redo OST testing phase, or move on?', {'redo', 'move on'});
    if strcmp(moveOn_resp, 'move on')
        % if moving on, save OST settings to expt
        ostList = get_ost(exptost.trackingFileLoc, exptost.trackingFileName, 'list');
        for o = 1:length(ostList)
            ostStatus = str2double(ostList{o});
            [heur, param1, param2] = get_ost(exptost.trackingFileLoc, exptost.trackingFileName, ostStatus);
            expt.subjOstParams{o} = {ostStatus heur param1 param2};
        end
        bGoodOSTs = 1; % ok to leave while loop
    end
        
end

%% Finish setting up expt file
expt.shiftMag = 125; %shift magnitude, in mels
expt.shiftNames = {'noShift', 'shiftUp', 'shiftDown'};
expt.shifts = {0 1 -1};

% counterbalancing shifts
% get shift permutation (to be associated with words in a fixed order)
permsPath = fileparts(get_acoustLoadPath(expt.name));
if exist(permsPath,'dir')
    [expt.permIx, expt.permList] = get_cbPermutation(expt.name, permsPath); % get the words and their index
    if ~bTestMode && ~any(strfind(expt.snum, 'pilot')) && ~any(strfind(expt.snum,'test')) % if "test" or "pilot" in pp name, not a real pp
        set_cbPermutation(expt.name, expt.permIx, permsPath);
    end
else % If the server is down for some reason
    % Get a random index between 1 and the # of possible permutations
    % (for simonMultisyllable_v2, there's 2 permutations)
    expt.permIx = randi(2);
    
    % Then use a local copy of the permutations (counts do not have to be 
    % up to date, you just need order of conditions)
    localPermsPath = fileparts(fileparts(expt.dataPath)); % get the experiment folder
    [~, expt.permList] = get_cbPermutation(expt.name, localPermsPath, [], expt.permIx);
    
    % save warning.txt file with permIx
    warningFile = fullfile(expt.dataPath,'warning.txt');
    fid = fopen(warningFile, 'w');
    warning('Server did not respond. Using randomly generated permutation index (see warning file)');
    fprintf(fid,'Server did not respond. Random permIx generated: %d', expt.permIx);
    fclose(fid);
end

% timing 
expt.timing.stimdur = 2;          % time stim is on screen, in seconds
expt.timing.interstimdur = 1.25;    % minimum time between stims, in seconds
expt.timing.interstimjitter = .25;  % maximum extra time between stims (jitter)

% set up conditions and number of trials
expt.conds = {'baseline' 'ramp' 'hold' 'washout'};
 
nwords = length(expt.words);
if bTestMode
    testModeReps = 4;
    nBaseline =           testModeReps * nwords;
    nRamp =               testModeReps * nwords;
    nHold =               testModeReps * nwords * 2;
    nWashout =            testModeReps * nwords;
    expt.breakFrequency = testModeReps * nwords;
else
    nBaseline =     20 * nwords;
    nRamp =         30 * nwords;
    nHold =         70 * nwords;
    nWashout =      10 * nwords;
    expt.breakFrequency = 10 * nwords;
end

expt.ntrials = nBaseline + nRamp + nHold + nWashout;

%set up initial shift magnitudes, not accounting for different shifts on
%different words (this is handled below)
expt.shiftMags = [zeros(1,nBaseline)...
    sort(repmat(linspace(0, expt.shiftMag, nRamp/nwords),1,nwords))...
    expt.shiftMag * ones(1,nHold)...
    zeros(1,nWashout)];
  
expt.allConds = [1*ones(1,nBaseline) 2*ones(1,nRamp) 3*ones(1,nHold) 4*ones(1,nWashout)];

% randomize order of allWords
expt.allWords = randomize_wordOrder(nwords, expt.ntrials/nwords);

%set missing parameters to defaults
expt = set_exptDefaults(expt);

% re-assign shift and word assignment based on permutation order
expt.allShifts = zeros(1, expt.ntrials);
expt.allShifts(expt.allWords == 1) = expt.permList{1};
expt.allShifts(expt.allWords == 2) = expt.permList{2};
expt.allShifts(expt.allWords == 3) = 1; % noShift for distractor

expt.listShifts(expt.allWords == 1) = expt.shifts{expt.permList{1}};
expt.listShifts(expt.allWords == 2) = expt.shifts{expt.permList{2}};
expt.listShifts(expt.allWords == 3) = 0; %noShift for distractor

% set shiftNames fields, which align 1-1 with shifts fields
expt.allShiftNames = expt.allShifts;
expt.listShiftNames = expt.shiftNames(expt.allShiftNames);

expt.shiftMags = expt.shiftMags .* expt.listShifts;

%% save experiment file
exptfile = fullfile(expt.dataPath,'expt.mat');
save(exptfile, 'expt')
fprintf('Saved expt file: %s.\n',exptfile);

%% run main experiment
expt = run_simonMultisyllable_v2_audapter(expt);


end %EOF
