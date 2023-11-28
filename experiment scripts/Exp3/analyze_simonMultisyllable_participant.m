function [fdata,fdata_bins,ix] = analyze_simonMultisyllable_participant(dataPath, bPlots,bGen)
% Analysis function for pilot data for simonMultisyllable experiment, which
% ran in May/June 2021.
%
% 2021-11 BP init, based on similar file for simonSingleWord

dbstop if error

if nargin < 1 || isempty(dataPath)
    dataPath = pwd;
end
if nargin < 2 || isempty(bPlots)
    bPlots = 0;
end
if nargin < 3 || isempty(bGen) 
    bGen = 0; %force script to regenerate dataVals
end

if ~isfile(fullfile(dataPath, 'dataVals_audapter.mat')) || bGen == 1
    gen_dataVals_from_audapterdata(dataPath,[],2)
end
load(fullfile(dataPath, 'dataVals_audapter.mat'), 'dataVals')
load(fullfile(dataPath, 'expt.mat'), 'expt')

%% collect data
fdata = get_fdataByTrial(dataVals);
for w = 1:length(expt.words)
    fdata_byword.f1{w} = fdata.f1(expt.allWords == w);
    fdata_byword.f2{w} = fdata.f2(expt.allWords == w);
end

for w = 1:length(expt.words)
    for t = 10:10:expt.ntrials/length(expt.words) % For pre-piloting data, there were 3 words. In final experiment, there are 4.
        fdata_bins.f1{w}(t/10) = mean(fdata_byword.f1{w}(t-9:t), 'omitnan');
        fdata_bins.f2{w}(t/10) = mean(fdata_byword.f2{w}(t-9:t), 'omitnan');
    end
end


ix.baseline = max(expt.inds.conds.baseline)/(10*length(expt.words));
ix.ramp = max(expt.inds.conds.ramp)/(10*length(expt.words));
ix.adapt = max(expt.inds.conds.hold)/(10*length(expt.words));
ix.washout = ix.adapt + 1;
% 
% stats.baseline = [fdata_bins.f1{1}(ix.baseline), fdata_bins.f1{2}(ix.baseline); ...
%     fdata_bins.f2{1}(ix.baseline), fdata_bins.f2{2}(ix.baseline)];
% stats.adapt = [fdata_bins.f1{1}(ix.adapt), fdata_bins.f1{2}(ix.adapt); ...
%     fdata_bins.f2{1}(ix.adapt), fdata_bins.f2{2}(ix.adapt)];
% stats.washout = [fdata_bins.f1{1}(ix.washout), fdata_bins.f1{2}(ix.washout); ...
%     fdata_bins.f2{1}(ix.washout), fdata_bins.f2{2}(ix.washout)];


%% plot it
if bPlots
%     figure; hold on;
%     colors = {'r','b','k'};
%     for w = 1:length(expt.words)
%         plot(fdata_byword.f1{w},'-*','Color',colors{w})
%     end
%     hline(mean(fdata.f1(expt.allConds==1)),'k','--');
%     blockBounds = find(diff(expt.allConds)>0);
%     for b = 1:length(blockBounds)
%         vline(blockBounds(b)/3,'k',':');
%     end
%     legend(expt.words)
    
    
    colors = {[1 0 0] [0 0 1] [0 0 0] [.5 .5 .5]};
    forms = {'f1' 'f2'};
    for f = 1:length(forms)
        figure; hold on;
        form = forms{f};
        for w = 1:length(expt.words)
            plot(fdata_bins.(form){w},'-*','Color',colors{w},'LineWidth',2)
        end
        hline(mean(fdata.(form)(expt.allConds==1)),'k','--');
        blockBounds = find(diff(expt.allConds)>0);
        for b = 1:length(blockBounds)
            vline(blockBounds(b)/(length(expt.words)*10),'k',':');
        end
        legend(expt.words)
        title(form)
    end
end


end %EOF
