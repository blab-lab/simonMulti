function [h] = plot_simonMultisyllable()
%PLOT_SIMONMULTISYLLABLE Plotting scripts for the simonMultisyllable experiments.
%   PLOT_SIMONMULTISYLLABLE()

dataPaths.v1 = get_dataPaths_simonMultisyllable;
dataPaths.v2 = get_dataPaths_simonMultisyllable_v2;

expts = fieldnames(dataPaths);
for v = 1:length(expts)
    exptName = expts{v};
    dataPathS1 = dataPaths.(exptName){1};
    exptPath = fileparts(dataPathS1);
    nSubs = length(dataPaths.(exptName));
    filenameTable = sprintf('statTable_%ds',nSubs);
    filenamePlotData = sprintf('plotData_%ds',nSubs);
    tempDataTable = load(fullfile(exptPath,filenameTable));
    try
        dataTable.(exptName) = tempDataTable.dataTable;
    catch
        dataTable.(exptName) = tempDataTable.statTable;
    end
    clear tempDataTable;
    plotData.(exptName) = load(fullfile(exptPath,filenamePlotData));

    load(fullfile(dataPathS1,'expt.mat'),'expt');
    conds = expt.conds;
    for c = 1:length(conds)
        cond = conds{c};
        inds.(exptName)(c) = max(expt.inds.conds.(cond))/length(expt.words)/expt.ntrials_per_block;
    end

    down = dataTable.(exptName).f1In(ismember(dataTable.(exptName).phase,'hold')&ismember(dataTable.(exptName).shift,'shiftDown'));
    up = dataTable.(exptName).f1In(ismember(dataTable.(exptName).phase,'hold')&ismember(dataTable.(exptName).shift,'shiftUp'));
    descStats.(exptName).mean = mean(down-up,'omitnan');
    descStats.(exptName).ste = ste(down(~isnan(down))-up(~isnan(down)));
    [~,descStats.(exptName).p] = ttest(down-up,0,'tail','right');

end

%% plot params

binsize = 10;

shiftColors.v1 = [[5 119 204]/255;...
        0 0 0;...
        .4 .4 .4;...
        0.8 0 0];
shiftMarkers.v1 = {'o', 'x', 'x', 's'};

shiftColors.v2 = [[5 119 204]/255;...
    0 0 0;...
    0.8 0 0];
shiftMarkers.v2 = {'o', 'x', 's'};

%% plot

for v = 1:length(expts)
    exptName = expts{v};
    shifts = fieldnames(plotData.(exptName).f1sIn);

    h = figure;
    hold on
    for s = 1:length(shifts)
        shift = shifts{s};
        dat = plotData.(exptName).f1sIn.(shift);
        for b = 1:length(dat)/binsize
            plotDat(:,b) = mean(dat(:,(b-1)*binsize+1:b*binsize),2,'omitnan');
        end
        xvals = 1:length(plotDat);
        errorbar(xvals,mean(plotDat,'omitnan'),ste(plotDat),...
            strcat(shiftMarkers.(exptName){s},'-'),'Color',shiftColors(s,:),'MarkerFaceColor',shiftColors(s,:),'LineWidth',2);
        clear plotDat
    end
    ylabel('\Delta F1 (mels)')
    ylim([-50 50])
    set(gca,'YTick',-50:50:50)
    set(gca,'XTick',0.5+[inds.(exptName)(1)/2 inds.(exptName)(1)+(inds.(exptName)(2)-inds.(exptName)(1))/2 inds.(exptName)(2)+(inds.(exptName)(3)-inds.(exptName)(2))/2 inds.(exptName)(3)+(inds.(exptName)(4)-inds.(exptName)(3))/2],...
        'XTickLabels',{'baseline','ramp','hold','washout'});
    phaselims = [inds.(exptName)(1:end-1)+0.5];
    nPhaselims = length(phaselims);
    for p = 1:nPhaselims
        vline(phaselims(p),'k','-');
    end
    hline(0,'k',':');
    xtickangle(30)
    t = title(exptName);
    set(t,'Position',t.Position+[0 5 0])
    makeFig4Printing;
end

end
