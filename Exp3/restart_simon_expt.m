function expPath = restart_simon_expt(expt)
%RESTART_SIMON_EXPT  Flexible script to restart a simon experiment after a crash.
% Confirmed works for:
%   simonMultisyllable
%   simonMultisyllable_v2
%   coAdapt
%   simonToneLex
%   simonToneMatch
%   simonSingleWord_v2
%
% DOES NOT WORK for:
%   simonSingleWord (use restart_simonSingleWord_expt)
%   simonHomophonePic (use restart_simonHomophonePic_expt)

% 2021-09 CWN init.

if nargin < 1 || isempty(expt)
    error('Load expt file that needs to be restarted and include it as an input argument.')
end

if ~isfield(expt,'snum'), expt.snum = get_snum; end

expFun = get_experiment_function(expt.name); % this function will need to be updated!

% find all temp trial dirs
subjPath = get_acoustSavePath(expt.name,expt.snum);
tempdirs = regexp(genpath(subjPath),'[^;]*temp_trials','match')';
if isempty(tempdirs)
    fprintf('No unfinished experiments to restart.\n')
    expPath = [];
    return;
end

% prompt for restart
for d = 1:length(tempdirs)
    %find last trial saved
    trialnums = get_sortedTrials(tempdirs{d});
    lastTrial = trialnums(end);
    
    %check to see if experiment completed. only prompt to rerun if
    %incomplete.
    dataPath = fileparts(strip(tempdirs{d},'right',filesep));
    load(fullfile(dataPath,'expt.mat'), 'expt') % get expt file 
    if lastTrial ~= expt.ntrials
        q = sprintf('Restart experiment "%s" at trial %d?', expt.name, lastTrial+1);
        response = askNChoiceQuestion(q, {'y' 'n'});
        if strcmp(response,'y')
            % setup expt
            expt.startTrial = lastTrial+1;      % set starting trial
            expt.startBlock = ceil(expt.startTrial/expt.ntrials_per_block); % get starting block
            expt.isRestart = 1;
            expt.crashTrials = [expt.crashTrials expt.startTrial];
            save(fullfile(dataPath,'expt.mat'),'expt')
            
            % run experiment
            expFun(expt)
            break;
        end
    end
    expPath = [];
end



end