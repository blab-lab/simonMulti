function [dataTable, plotData] = analyze_coAdapt(dataPaths)
%analyze data from the coAdapt experiment. Returns a table for running
%stats ('statTable') as well as a matrix for plotting data ('plotData').

if nargin < 1; dataPaths = get_dataPaths_coAdapt; end

loadPath = fileparts(dataPaths{1});
[~,exptName] = fileparts(fileparts(fileparts(dataPaths{1})));

nSubs = length(dataPaths);
filenameTable = sprintf('statTable_%ds.mat',nSubs);
filenamePlotData = sprintf('plotData_%ds.mat',nSubs);

if isfile(fullfile(loadPath,filenameTable))
    load(fullfile(loadPath,filenameTable))
    load(fullfile(loadPath,filenamePlotData))
else
    if strcmp(exptName,'simonMultisyllable')
        shiftNames = {'shiftUp','noShift1','noShift2','shiftDown'};
    else
        shiftNames = {'shiftUp','noShift','shiftDown'};
    end
    nShifts = length(shiftNames);
    nSubs = length(dataPaths);
    
    stab = cell(1,nSubs);
    for s = 1:nSubs
        dataPath = dataPaths{s};
        [fVals,phases] = analyze_coAdapt_by_participant(dataPath);
        phaseNames = fieldnames(phases);
        nPhases = length(phaseNames);
        ptab = cell(1,nPhases);
        for p = 1:nPhases
            phase = phaseNames{p};
            if strcmp(phase,'washout')
                phaseBeg = (phases.(phase)(1)-1)./nShifts;
                phaseI = phaseBeg+1:phaseBeg+10;
            else
                phaseEnd = phases.(phase)(end)./nShifts;
                phaseI = phaseEnd-9:phaseEnd;
            end
            
            baseEnd = phases.baseline(end)./nShifts;
            baseI = baseEnd-9:baseEnd;
            htab = cell(1,nShifts);
            for h = 1:nShifts
                shift = shiftNames{h};
                
                if p == 1 %aggregate all trials into a big matrix for potting
                    plotData.f1sIn.(shift)(s,:) = fVals.f1sIn.(shift)-mean(fVals.f1sIn.(shift)(baseI));
                    plotData.f2sIn.(shift)(s,:) = fVals.f2sIn.(shift)-mean(fVals.f2sIn.(shift)(baseI));
                    plotData.f1sOut.(shift)(s,:) = fVals.f1sOut.(shift)-mean(fVals.f1sOut.(shift)(baseI));
                    plotData.f2sOut.(shift)(s,:) = fVals.f2sOut.(shift)-mean(fVals.f2sOut.(shift)(baseI));
                    plotData.f1sShift.(shift)(s,:) = fVals.f1sOut.(shift)-fVals.f1sIn.(shift);
                    plotData.f2sShift.(shift)(s,:) = fVals.f2sOut.(shift)-fVals.f2sIn.(shift);
                end
                
                %get means in phase for stats
                dat.f1In = mean(fVals.f1sIn.(shift)(phaseI))-mean(fVals.f1sIn.(shift)(baseI));
                dat.f2In = mean(fVals.f2sIn.(shift)(phaseI))-mean(fVals.f2sIn.(shift)(baseI));
                dat.f1Out = mean(fVals.f1sOut.(shift)(phaseI))-mean(fVals.f1sOut.(shift)(baseI));
                dat.f2Out = mean(fVals.f2sOut.(shift)(phaseI))-mean(fVals.f2sOut.(shift)(baseI));
                dat.f1Shift = mean(fVals.f1sOut.(shift)(phaseI)-fVals.f1sIn.(shift)(phaseI),'omitnan');
                dat.f2Shift = mean(fVals.f2sOut.(shift)(phaseI)-fVals.f2sIn.(shift)(phaseI),'omitnan');
                
                %create paired plot data structure
                plotData.paired.f1.(phase).(shift)(s) = dat.f1In;
                plotData.paired.f2.(phase).(shift)(s) = dat.f2In;
                plotData.paired.f1Shift.(phase).(shift)(s) = dat.f1Shift;
                plotData.paired.f2Shift.(phase).(shift)(s) = dat.f2Shift;
                fact.shift = shift;
                fact.phase = phase;
                fact.subj = s;
                htab{h} = get_datatable(dat,fact);
            end
            ptab{p} = vertcat(htab{:});
        end
        stab{s} = vertcat(ptab{:});
    end
    dataTable = vertcat(stab{:});
    
    [savePath] = fileparts(dataPaths{1});
    save(fullfile(savePath,strcat(filenameTable,'.mat')),'dataTable');
    writetable(dataTable,fullfile(savePath,'dataTable'))
    save(fullfile(savePath,strcat(filenamePlotData,'.mat')),'plotData');
end

%% stats
miniTable = dataTable(~ismember(dataTable.phase,'baseline'),:);
[p,tbl,stats] = anovan(miniTable.f1In,...
    {miniTable.shift miniTable.phase miniTable.subj},...
    'model','interaction',...
    'random',3,...
    'varnames',{'shift','phase','subj'});

%% plotting

if strcmp(exptName,'simonMultisyllable')
     shiftColors = [ .9 0 0;...
                0 0 0;...
                .4 .4 .4;...
                0 0 .9];
else
    shiftColors = [ .9 0 0;...
                0 0 0;...
                0 0 .9];
end

params.markerSize = 150;
params.averageMarkerSize = 8;

shifts = fieldnames(plotData.f1sIn);
h1(1) = figure;
hold on
for s = 1:length(shifts)
    shift = shifts{s};
    dat = plotData.f1sIn.(shift);
    clear plotDat
    for b = 1:length(dat)/10
        plotDat(:,b) = mean(dat(:,(b-1)*10+1:b*10),2,'omitnan');
    end
    xvals = 1:length(plotDat);
%     plot(xvals,mean(plotDat,'omitnan'),'Color',shiftColors(s,:),'LineWidth',2)
%     plot_filled_err(xvals,mean(plotDat,'omitnan'),ste(plotDat),shiftColors(s,:));
    errorbar(xvals,mean(plotDat,'omitnan'),ste(plotDat),'o-','Color',shiftColors(s,:),'MarkerFaceColor',shiftColors(s,:),'LineWidth',2);
end
ylabel('normalized F1')
ylim([-70 70])
set(gca,'YTick',-50:50:50)
set(gca,'XTick',[1.5 4.5 9.0 16.5],'XTickLabels',{'baseline','ramp','hold','washout'});
phaselims = [3.5 6.5 15.5];
nPhaselims = length(phaselims);
for p = 1:nPhaselims
    vline(phaselims(p),'k','-');
end
hline(0,'k',':');

makeFig4Printing;

h1(2) = plot_pairedData(plotData.paired.f1.hold,shiftColors,params);
ylim([-150 150])
set(gca,'YTick',-150:50:150)
hline(0,'k',':');
title('End of hold')
xtickangle(30)
makeFig4Printing;

h1(3) = plot_pairedData(plotData.paired.f1.washout,shiftColors,params);
ylim([-150 150])
set(gca,'YTick',-150:50:150)
hline(0,'k',':');
title('Washout')
xtickangle(30)
makeFig4Printing;

corrParams.Markercolor = 'k';
corrParams.MarkerFaceColor = 'k';
corrParams.MarkerFaceAlpha = .2;
corrParams.markersize = 80;
h1(4) = plot_corr(plotData.paired.f1.hold.shiftDown,plotData.paired.f1.hold.shiftUp,corrParams);
xlim([-150 150])
ylim([-150 150])
set(gca,'YTick',[-150 0 150],'XTick',[-150 0 150])
hline(0,'k',':');
vline(0,'k',':');
title('Down v Up')
xlabel('shiftDown')
h_yLab = ylabel('shiftUp');
h_yLab.Position(1) = h_yLab.Position(1)-10;
set(h1(4).Children,'XColor',shiftColors(2,:))
set(h1(4).Children,'YColor',shiftColors(1,:))
makeFig4Printing;

h_all = figure();
copy_fig2subplot(h1,h_all,2,3,{[1 2 3] 4 5 6},1);

