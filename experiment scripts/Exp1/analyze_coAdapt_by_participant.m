function [fVals,phases] = analyze_coAdapt_by_participant(dataPath)
%Analyzes data for coAdapt from a single participant in dataPath. Returns a
%variable 'fVals' which contains f1 and f2 values from both the input and
%output signals for each of three shift conditions: shiftUp, shiftDown,
%noShift. Optionally returns a second arguement 'phases' which contains the
%indexes into each of the four phases of the experiment: baseline, ramp,
%hold, washout.

if nargin < 1
    snum = get_snum;
    exptName = 'coAdapt';
    dataPath = get_acoustLoadPath(exptName,snum);
end


[~,sName] = fileparts(dataPath);
[~,exptName] = fileparts(fileparts(fileparts(dataPath)));
fprintf('Loading data for participant %s.\n',sName)
load(fullfile(dataPath, 'data.mat'));
load(fullfile(dataPath, 'expt.mat'));
if exist(fullfile(dataPath,'dataVals.mat'),'file') %use 'dataVals' generated from wave_viewer if it exists
    dataValsFile = 'dataVals.mat';  
else %otherwise generate it from audapter data directly
    dataValsFile = 'dataVals_audapter.mat';
    if ~isfile(fullfile(dataPath, dataValsFile))
        fprintf('\tGenerating dataVals from audapter for participant %s in expt %s.\n',sName, exptName)
        if contains('simonMultisyllable',exptName)
            gen_dataVals_from_audapterdata(dataPath,[],2)
        else
            gen_dataVals_from_audapterdata(dataPath,[],0)
        end
    end
end
load(fullfile(dataPath, dataValsFile));

phases.baseline = expt.inds.conds.baseline;
phases.hold = expt.inds.conds.hold;
phases.washout = expt.inds.conds.washout;

shifts.shiftUp = find(strcmp(expt.listShiftNames,'shiftUp'));
shifts.shiftDown = find(strcmp(expt.listShiftNames,'shiftDown'));
if strcmp(exptName,'simonMultisyllable')
    shifts.noShift1 = find(strcmp(expt.listShiftNames,'noShift') & strcmp(expt.listWords,'pedestal'));
    shifts.noShift2 = find(strcmp(expt.listShiftNames,'noShift') & strcmp(expt.listWords,'carbonate'));
else
    shifts.noShift = find(strcmp(expt.listShiftNames,'noShift'));
end

shiftNames = fieldnames(shifts);
nShifts = length(shiftNames);

for s = 1:nShifts
    shift = shiftNames{s};
    t = 1; %initate variable to track trials within a condition
    for i = shifts.(shift)
        if isempty(dataVals(i).f1) || isempty(dataVals(i).f2) || dataVals(i).bExcl
            fVals.f1sIn.(shift)(t) = NaN;
            fVals.f2sIn.(shift)(t) = NaN;
            fVals.f1sOut.(shift)(t) = NaN;
            fVals.f2sOut.(shift)(t) = NaN;
        else
            ftrackInSamps1 = find(~isnan(dataVals(i).f1));
            ftrackIn1 = dataVals(i).f1(ftrackInSamps1);
            ftrackInSamps2 = find(~isnan(dataVals(i).f2));
            ftrackIn2 = dataVals(i).f2(ftrackInSamps2);
            ftrackOutSamps1 = find(~isnan(dataVals(i).f2));
            ftrackOut1 = dataVals(i).f1(ftrackOutSamps1);
            ftrackOutSamps2 = find(~isnan(dataVals(i).f2));
            ftrackOut2 = dataVals(i).f2(ftrackOutSamps2);
            ftrackLength = length(ftrackIn1);
            if strcmp(shift,'noShift')&&strcmp(exptName,'simonMultiSyllable_v2') %for noShift condition, use 50-75% of vowel beacuse of initial /l/
                pStart = round(ftrackLength/2);
                pEnd = round(ftrackLength/2+ftrackLength/4);
            else
                pStart = round(ftrackLength/4);
                pEnd = round(ftrackLength/2);
            end
            fVals.f1sIn.(shift)(t) = mean(ftrackIn1(pStart:pEnd));
            fVals.f2sIn.(shift)(t) = mean(ftrackIn2(pStart:pEnd));
            fVals.f1sOut.(shift)(t) = mean(ftrackOut1(pStart:pEnd));
            fVals.f2sOut.(shift)(t) = mean(ftrackOut2(pStart:pEnd));
        end
        t = t + 1; %interate trial within this condition
    end
end


