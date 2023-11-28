function [descStats,dataTable] = plot_simonMultisyllable_allExpts
% setup plotting stuff
fullPageWidth = 17.4+3.0; % 174 mm + margins
figpos_cm = [1 25 fullPageWidth fullPageWidth*0.7];

%load in data
dp.CoAdapt = get_dataPaths_coAdapt;
dp.SMS2 = get_dataPaths_simonMultisyllable_v2;
dp.SMS1 = get_dataPaths_simonMultisyllable;

expts = fieldnames(dp);
for d = 1:length(expts)
    expt = expts{d};
    loadPath = fileparts(dp.(expt){1});
    nSubs = length(dp.(expt));
    filenameTable = sprintf('statTable_%ds',nSubs);
    filenamePlotData = sprintf('plotData_%ds',nSubs);
    tempTable = load(fullfile(loadPath,filenameTable));
    try
        dataTable.(expt) = tempTable.dataTable;
    catch
        dataTable.(expt) = tempTable.statTable;
    end
    clear tempTable;
    tempData = load(fullfile(loadPath,filenamePlotData));
    plotData.(expt) = tempData.plotData;
    clear tempData;
    
    exptDat = load(fullfile(dp.(expt){1},'expt.mat'));
    conds = exptDat.expt.conds;
    for c = 1:length(conds)
        cond = conds{c};
        inds.(expt)(c) = max(exptDat.expt.inds.conds.(cond))/length(exptDat.expt.words)/exptDat.expt.ntrials_per_block;
    end
end

%simonSingleWord data has a different format, so process it separately
expt = 'SW';
dp.(expt) = get_dataPaths_simonSingleWord;
nSubs = length(dp.(expt));
filenamePlotData = sprintf('plotData_%ds',nSubs);
filenameTable = sprintf('statTable_%ds',nSubs);
plotData.SW = load(fullfile(get_acoustLoadPath('simonSingleWord'),strcat(filenamePlotData,'.mat')));
tempTable = load(fullfile(get_acoustLoadPath('simonSingleWord'),strcat(filenameTable,'.mat')));
dataTable.(expt) = tempTable.statTable;
exptDat = load(fullfile(dp.(expt){1},'expt.mat'));
conds = exptDat.expt.conds;
for c = 1:length(conds)
    cond = conds{c};
    inds.(expt)(c) = max(exptDat.expt.inds.conds.(cond))/length(exptDat.expt.words)/exptDat.expt.ntrials_per_block;
end

%% report means and standard deviation of difference between down and up shift conditions
expts = fieldnames(dp); %add in SW experiment to expts
for d = 1:length(expts)
    expt = expts{d};
    if strcmp(expt,'SW')
        down = [dataTable.(expt).fVal(ismember(dataTable.(expt).vowel,'V1')&ismember(dataTable.(expt).formant,'f1')&ismember(dataTable.(expt).phase,'adapt')&ismember(dataTable.(expt).shift,'IH-AE')); ...
            dataTable.(expt).fVal(ismember(dataTable.(expt).vowel,'V2')&ismember(dataTable.(expt).formant,'f1')&ismember(dataTable.(expt).phase,'adapt')&ismember(dataTable.(expt).shift,'AE-IH'))];
        up = [dataTable.(expt).fVal(ismember(dataTable.(expt).vowel,'V2')&ismember(dataTable.(expt).formant,'f1')&ismember(dataTable.(expt).phase,'adapt')&ismember(dataTable.(expt).shift,'IH-AE')); ...
            dataTable.(expt).fVal(ismember(dataTable.(expt).vowel,'V1')&ismember(dataTable.(expt).formant,'f1')&ismember(dataTable.(expt).phase,'adapt')&ismember(dataTable.(expt).shift,'AE-IH'))];
    else
        down = dataTable.(expt).f1In(ismember(dataTable.(expt).phase,'hold')&ismember(dataTable.(expt).shift,'shiftDown'));
        up = dataTable.(expt).f1In(ismember(dataTable.(expt).phase,'hold')&ismember(dataTable.(expt).shift,'shiftUp'));
    end
    descStats.(expt).mean = mean(down-up,'omitnan');
    descStats.(expt).ste = ste(down(~isnan(down))-up(~isnan(down)));
    [~,descStats.(expt).p] = ttest(down-up,0,'tail','right');
end

%% plotting
set(0, 'DefaultFigureRenderer', 'painters');

titles = {  'A: different monosyllablic words',...
            'B: same syl., different disyllabic words',...
            'C: same syl., different trisyllabic words',...
            'D: different syl., one disyllabic word'};
            

for d = 1:length(expts)-1 %don't plot SW data here
    expt = expts{d};
    
    if strcmp(expt,'SMS1')
        shiftColors = [[5 119 204]/255;...
            0 0 0;...
            .4 .4 .4;...
            0.8 0 0];
        shiftMarkers = {'o', 'x', 'x', 's'};
    else
        shiftColors = [[5 119 204]/255;...
            0 0 0;...
            0.8 0 0];
        shiftMarkers = {'o', 'x', 's'};
    end
    
    
    shifts = fieldnames(plotData.(expt).f1sIn);
    
    h1(d) = figure;
    hold on
    for s = 1:length(shifts)
        shift = shifts{s};
        dat = plotData.(expt).f1sIn.(shift);
        for b = 1:length(dat)/10
            plotDat(:,b) = mean(dat(:,(b-1)*10+1:b*10),2,'omitnan');
        end
        xvals = 1:length(plotDat);
        errorbar(xvals,mean(plotDat,'omitnan'),ste(plotDat),strcat(shiftMarkers{s},'-'),'Color',shiftColors(s,:),'MarkerFaceColor',shiftColors(s,:),'LineWidth',2);
        clear plotDat
    end
    ylabel('\Delta F1 (mels)')
    ylim([-50 50])
    set(gca,'YTick',-50:50:50)
    set(gca,'XTick',0.5+[inds.(expt)(1)/2 inds.(expt)(1)+(inds.(expt)(2)-inds.(expt)(1))/2 inds.(expt)(2)+(inds.(expt)(3)-inds.(expt)(2))/2 inds.(expt)(3)+(inds.(expt)(4)-inds.(expt)(3))/2],...
        'XTickLabels',{'baseline','ramp','hold','washout'});
    phaselims = [inds.(expt)(1:end-1)+0.5];
    nPhaselims = length(phaselims);
    for p = 1:nPhaselims
        vline(phaselims(p),'k','-');
    end
    hline(0,'k',':');
    xtickangle(30)
    t = title(titles{d});
    set(t,'Position',t.Position+[0 5 0])
    makeFig4Printing;
end

% plot simonSingleWord data
expt = 'SW';
shiftColors = [[5 119 204]/255;...
    0 0 0;...
    0.8 0 0];
shiftMarkers = {'o', 'x', 's'};

h1(4) = figure; hold on;
xvals = 1:length(plotData.SW.fdata_norm_flip.f1{1});
errorbar(xvals,mean(plotData.SW.fdata_norm_flip.f1{1}),ste(plotData.SW.fdata_norm_flip.f1{1}),strcat(shiftMarkers{3},'-'),'Color',shiftColors(3,:),'MarkerFaceColor',shiftColors(3,:),'LineWidth',2);
errorbar(xvals,mean(plotData.SW.fdata_norm_flip.f1{2}),ste(plotData.SW.fdata_norm_flip.f1{2}),strcat(shiftMarkers{1},'-'),'Color',shiftColors(1,:),'MarkerFaceColor',shiftColors(1,:),'LineWidth',2);
ylabel('\Delta F1 (mels)')
ylim([-50 50])
set(gca,'YTick',-50:50:50)
set(gca,'XTick',0.5+[inds.(expt)(1)/2 inds.(expt)(1)+(inds.(expt)(2)-inds.(expt)(1))/2 inds.(expt)(2)+(inds.(expt)(3)-inds.(expt)(2))/2 inds.(expt)(3)+(inds.(expt)(4)-inds.(expt)(3))/2],...
    'XTickLabels',{'baseline','ramp','hold','washout'});
phaselims = [inds.(expt)(1:end-1)+0.5];
nPhaselims = length(phaselims);
for p = 1:nPhaselims
    vline(phaselims(p),'k','-');
end
hline(0,'k',':');
xtickangle(30)
t = title(titles{4});
set(t,'Position',t.Position+[0 2 0])
makeFig4Printing;


h_all = figure('Units','centimeters','Position',figpos_cm);
params.TileSpacing = 'normal';
params.Padding = 'normal';
copy_fig2tiledlayout(h1,h_all,2,2,[],[],1,params);
    