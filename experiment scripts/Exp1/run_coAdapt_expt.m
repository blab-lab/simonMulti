function expt = run_coAdapt_expt(expt, bTestMode)
% This is an adaptation experiment with 3 stimulus words: bed, ted, head.
% The goal is to see if participants can learn multiple shifts on the same
% vowel in different words.
%
% A participant is assigned to have each of those three words be in one of
% three conditions: shiftUp, shiftDown, or noShift. Depending on the
% condition, F1 ONLY is shifted up, down, or neither. This experiment has
% baseline, ramp, hold, and washout phases.

% 2021-02 Lana Hantzsch initial coding
% 2021-08 Chris Naber revisions

if nargin < 1, expt = []; end
if nargin < 2 || isempty(bTestMode), bTestMode = 0; end

%% Experiment Setup
expt.name = 'coAdapt';
if ~isfield(expt,'snum'), expt.snum = get_snum; end
expt.dataPath = get_acoustSavePath(expt.name, expt.snum);
if ~exist(expt.dataPath,'dir')
    mkdir(expt.dataPath)
end
rng('shuffle');

% load in existing expt.mat, if there is one
if isfile(fullfile(expt.dataPath, 'expt.mat'))
    bOverwrite = askNChoiceQuestion('This participant already exists. Load in existing expt?', {'y' 'n'});
    if strcmp(bOverwrite,'y')
        load(fullfile(expt.dataPath, 'expt.mat'), 'expt')
    end
end
    
if ~isfield(expt,'gender'), expt.gender = get_height; end

expt.words = {'bed' 'head' 'ted'}; %%stimulus words

%% Set up and run first pre-experiment phase to set LPC order

if ~bTestMode
    bRunLPCcheck = 1;
else
    bRunLPCcheck = askNChoiceQuestion('[Test mode only] Run LPC check pretest phase (1), or skip it (0)? ', [1 0]);
end

if bRunLPCcheck
    exptpre = expt;
    exptpre.dataPath = fullfile(expt.dataPath,'pre');
    
    %Switch to bid/bed/bat for collection of formantmeans
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

%% Finish setting up expt file
expt.shiftMag = 125; %shift magnitude, in mels
expt.shiftNames = {'noShift', 'shiftUp', 'shiftDown'};
expt.shifts = {0 1 -1};

% counterbalancing shifts
% get shift permutation (to be associated with words in a fixed order)
permsPath = fileparts(get_acoustLoadPath('coAdapt'));
if exist(permsPath,'dir')
    [expt.permIx, expt.permList] = get_cbPermutation(expt.name, permsPath); % get the words and their index
    
    if ~bTestMode && ~any(strfind(expt.snum, 'pilot')) && ~any(strfind(expt.snum,'test')) % if "test" or "pilot" in pp name, not a real pp
        set_cbPermutation(expt.name, expt.permIx, permsPath);
    end
else % If the server is down for some reason
    % Get a random index between 1 and the # of possible permutations
    expt.permIx = randi(factorial(length(expt.words)));
    
    % Then use a local copy of the permutations (counts do not have to be 
    % up to date, you just need order of conditions)
    localPermsPath = fileparts(fileparts(expt.dataPath));
    [~, expt.permList] = get_cbPermutation(expt.name, localPermsPath, [], expt.permIx);

    % save warning.txt file with permIx
    warningFile = fullfile(expt.dataPath,'warning.txt');
    fid = fopen(warningFile, 'w');
    warning('Server did not respond. Using randomly generated permutation index (see warning file)');
    fprintf(fid,'Server did not respond. Random permIx generated: %d', expt.permIx);
    fclose(fid);
end

% timing 
expt.timing.stimdur = 1.4;          % time stim is on screen, in seconds
expt.timing.interstimdur = 1.25;    % minimum time between stims, in seconds
expt.timing.interstimjitter = .25;  % maximum extra time between stims (jitter)

% set up [[CONDITIONS]] and number of trials
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
expt = run_coAdapt_audapter(expt);


end %EOF
