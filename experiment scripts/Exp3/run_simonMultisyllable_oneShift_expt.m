function expt = run_simonMultisyllable_oneShift_expt(expt, testMode)
% RUN_SIMONMULTISYLLABLE_ONESHIFT_EXPT    A pilot experiment for
% simonMultisyllable. For a series of three words, the first syllable is
% the same. In the real simonMultisyllable experiment, we plan to do an F1
% shift up, down or not at all on that first syllable, depending on which
% of 3 words it is.
%
% For this pilot, all 3 words will be shifted the same way, either up or
% down, to see if the person can adapt even given the relatively short
% vowel duration.
%
% testMode can be set to:
%    0 (default) to run the full experiment
%    1 to run a short version of the experiment
%    2 to run only the baseline phase.

% 2021-08. Programmed by Tahseen Shaik and Ben Parrell.
% 2021-11. This oneShift pilot edited by Chris Naber.


if nargin < 1, expt = []; end
if nargin < 2 || isempty(testMode), testMode = 0; end

%% Experiment Setup
expt.name = 'simonMultisyllable'; % this will need to change
if ~isfield(expt,'snum'), expt.snum = get_snum; end
expt.dataPath = get_acoustSavePath(expt.name, expt.snum);
if ~exist(expt.dataPath,'dir')
    mkdir(expt.dataPath)
end
rng('shuffle');

expt.trackingFileLoc = expt.name; 
expt.trackingFileName = 'pedXXX'; %this will need to change
refreshWorkingCopy(expt.trackingFileLoc, expt.trackingFileName, 'both');

% load in existing expt.mat, if there is one
if isfile(fullfile(expt.dataPath, 'expt.mat'))
    bOverwrite = askNChoiceQuestion('This participant already exists. Load in existing expt?', {'y' 'n'});
    if strcmp(bOverwrite,'y')
        load(fullfile(expt.dataPath, 'expt.mat'), 'expt')
    end
end
    
if ~isfield(expt,'gender'), expt.gender = get_height; end

expt.words = {'pedigree', 'pedicure', 'pedestal'}; %%stimulus words. This will need to change!

%% Set up and run first pre-experiment phase to set LPC order

if ~testMode
    bRunLPCcheck = 1;
else
    bRunLPCcheck = askNChoiceQuestion('[Test mode only] Run LPC check pretest phase (1), or skip it (0)? ', [1 0]);
end

if bRunLPCcheck
    exptpre = expt;
    exptpre.dataPath = fullfile(expt.dataPath,'pre');
    
    %Switch to bid/bad/bed for collection of formantmeans
    exptpre.words = {'bid' 'bed' 'bat'};
    nwordspre = length(exptpre.words);
    
    % Set to use default single-syllable, one word Audapter OST file
    exptpre.trackingFileLoc = 'experiment_helpers';
    exptpre.trackingFileName = 'measureFormants';
    
    %Where nblocks is the number of repetitions for each word.
    if testMode
        exptpre.nblocks = 2;
    else
        exptpre.nblocks = 10;
    end
    
    exptpre.ntrials = exptpre.nblocks * nwordspre; % testMode = 6, live = 18;
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
    bSave = savecheck(exptfile);
    if bSave
        save(exptfile, 'expt')
        fprintf('Saved expt file: %s.\n',exptfile);
    end
end

%% Set up and run second pre-experiment phase to check OST tracking
exptost = expt;
nwordsost = length(exptost.words);

if ~testMode
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
    exptost = run_simonMultisyllable_audapter(exptost); % this will need to change!
    
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

% the shiftNames and shift fields are not descriptive (or accurate) and are not
% really relevant for this study. But this code has been retained from the
% "real" run_simonMultisyllable_expt for simplicity's sake.
expt.shiftNames = {'noShift', 'shiftUp', 'shiftDown'};

% custom stuff for the "oneShift" pilot experiment
rng('shuffle')
shiftDirOptions = [-1 1];
shiftDir = shiftDirOptions(randperm(2, 1)); % pick -1 or 1 for all words
expt.shifts = {shiftDir shiftDir shiftDir};

% counterbalancing shifts
% get shift permutation (to be associated with words in a fixed order)
permsPath = fileparts(get_acoustLoadPath('simonMultisyllable')); %this will need to change
if exist(permsPath,'dir')
    [expt.permIx, expt.permList] = get_cbPermutation(expt.name, permsPath); % get the words and their index
    if ~testMode && ~any(strfind(expt.snum, 'pilot')) && ~any(strfind(expt.snum,'test')) % if "test" or "pilot" in pp name, not a real pp
        set_cbPermutation(expt.name, expt.permIx, permsPath);
    end
else % If the server is down for some reason
    % Get a random index between 1 and the # of possible permutations
    expt.permIx = randi(factorial(length(expt.words)));
    
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
expt.timing.stimdur = 2;          % time stim is on screen, in seconds -- this will need to change (MAYBE)!
expt.timing.interstimdur = 1.25;    % minimum time between stims, in seconds
expt.timing.interstimjitter = .25;  % maximum extra time between stims (jitter)

% set up conditions and number of trials
expt.conds = {'baseline' 'ramp' 'hold' 'washout'};
 
nwords = length(expt.words);
if testMode == 1
    testModeReps = 4;
    nBaseline =           testModeReps * nwords;
    nRamp =               testModeReps * nwords;
    nHold =               testModeReps * nwords * 2;
    nWashout =            testModeReps * nwords;
    expt.breakFrequency = testModeReps * nwords;
elseif testMode == 2
    testModeReps = 30;
    nBaseline =           testModeReps * nwords;
    nRamp =               0;
    nHold =               0;
    nWashout =            0;
    expt.breakFrequency = 0;
else
    nBaseline =     30 * nwords;
    nRamp =         30 * nwords;
    nHold =         90 * nwords;
    nWashout =      30 * nwords;
    expt.breakFrequency = 10 * nwords;
end

expt.ntrials = nBaseline + nRamp + nHold + nWashout;

%set up initial shift magnitudes, not accounting for different shifts on
%different words (this is handled below)
expt.shiftMags = [zeros(1,nBaseline)...
    sort(repmat(linspace(0, expt.shiftMag, nRamp/3),1,3))...
    expt.shiftMag * ones(1,nHold)...
    zeros(1,nWashout)];
  
%[ Gives us an array of numbers, one for each trial. The value of the
%number is the condition of that trial. So if expt.allConds(40) == 3,
%it tells us that the 40th trial is during the Hold condition.
expt.allConds = [1*ones(1,nBaseline) 2*ones(1,nRamp) 3*ones(1,nHold) 4*ones(1,nWashout)];

% randomize order of allWords
expt.allWords = randomize_wordOrder(nwords, expt.ntrials/nwords);

%set missing parameters to defaults
expt = set_exptDefaults(expt);

% re-assign shift and word assignment based on permutation order
expt.allShifts = zeros(1, expt.ntrials);
expt.allShifts(expt.allWords == 1) = expt.permList{1};
expt.allShifts(expt.allWords == 2) = expt.permList{2};
expt.allShifts(expt.allWords == 3) = expt.permList{3};

expt.listShifts(expt.allWords == 1) = expt.shifts{expt.permList{1}};
expt.listShifts(expt.allWords == 2) = expt.shifts{expt.permList{2}};
expt.listShifts(expt.allWords == 3) = expt.shifts{expt.permList{3}};

% set shiftNames fields, which align 1-1 with shifts fields
expt.allShiftNames = expt.allShifts;
expt.listShiftNames = expt.shiftNames(expt.allShiftNames);

expt.shiftMags = expt.shiftMags .* expt.listShifts;

expt.inds.shiftNames.noShift = find(strcmp(expt.listShiftNames, 'noShift'));
expt.inds.shiftNames.shiftUp = find(strcmp(expt.listShiftNames, 'shiftUp'));
expt.inds.shiftNames.shiftDown = find(strcmp(expt.listShiftNames, 'shiftDown'));

%% save experiment file
exptfile = fullfile(expt.dataPath,'expt.mat');
save(exptfile, 'expt')
fprintf('Saved expt file: %s.\n',exptfile);

%% run main experiment
expt = run_simonMultisyllable_audapter(expt); %this will need to change


end %EOF
