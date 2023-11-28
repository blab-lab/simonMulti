function [fdata_norm,fdata_norm_flip,statTable] = analyze_simonMultiSyllable_allParticipants(exptName, bSave,bGen)

% Analysis function for simonSingleWord experiment, which ran in May/June
% 2021.
%
% 2021-08 BP init.

dbstop if error

if nargin < 1 || isempty(exptName)
    error('You must provide an experiment name. E.g., "simonMultisyllable"')
end
if nargin < 2 || isempty(bSave)
    bSave = 1;
end
if nargin < 3 || isempty(bGen) 
    bGen = 0; %force script to regenerate dataVals
end

%generate dataPaths
eval(sprintf('dataPaths = get_dataPaths_%s',exptName));
nSubs = length(dataPaths);

phases = {'adapt', 'washout'};
nPhases = size(phases,2);

filenameTable = sprintf('statTable_%ds',nSubs);
filenamePlotData = sprintf('plotData_%ds',nSubs);
if ~bSave && exist(fullfile(get_acoustLoadPath(exptName),filenameTable),'file')
    fprintf('Data for %s participants already exists',bSubs)
else
    stab = cell(1,nSubs);
    for s = 1:nSubs
        fprintf('analyzing particiant %d of %d\n',s,nSubs)
        dp = dataPaths{s};
%         [~,fdata_bins,ix] = analyze_simonMultisyllable_participant(dp,0,bGen);
        [~,fdata_bins,ix] = analyze_simonMultisyllable_participant(dp);
        load(fullfile(dp,'expt.mat')) 
%         fprintf('%s, %s, %s, %s\n', expt.words{1},expt.words{2},expt.words{3},expt.words{4})
%         pause
        wordNames = expt.words;
        
        %record perturbation order
        shiftCat(s) = expt.permIx;
        forms = fieldnames(fdata_bins);
        nForms = length(forms);

        %initialize data structure for normalized data if it doesn't exist
        if ~exist('fdata_norm','var')
            for f = 1:nForms
                form = forms{f};
                nWords = length(wordNames);
                for w = 1:nWords
                    nBins = length(fdata_bins.(form){w});
                    fdata.(form){w} = NaN(nSubs,nBins);
                    fdata_norm.(form){w} = NaN(nSubs,nBins);
                    fdata_norm_flip.(form){w} = NaN(nSubs,nBins);
                end
            end
        end

%         %initialize data structure for projection data if it doesn't exist
%         if ~exist('fdata_norm','var')
%             form = forms{1};
%             nWords = length(fdata_bins.(form));
%             for v = 1:nVows
%                 nBins = length(fdata_bins.(form){w});
%                 fdata_proj{w} = NaN(nSubs,nBins);
%             end
%         end

        %normalize fdata and store it
        nWords = length(wordNames);
        wtab = cell(1,nWords);
        for w = 1:nWords
            wName = wordNames{w};

            ftab = cell(1,nForms+1);
            for f = 1:nForms
                form = forms{f};
                fdata.(form){w}(s,:) = hz2mels(fdata_bins.(form){w});
                fdata_norm.(form){w}(s,:) = hz2mels(fdata_bins.(form){w}) - hz2mels(fdata_bins.(form){w}(ix.baseline));
                %flip sign if shift permiutation order is 2
                if expt.permIx == 2
                    fdata_norm_flip.(form){w}(s,:) = -1 .* fdata_norm.(form){w}(s,:);
                else
                    fdata_norm_flip.(form){w}(s,:) = fdata_norm.(form){w}(s,:);
                end
                ptab = cell(1,nPhases);
                for p = 1:nPhases
                    phase = phases{p};
                    fdata_phase.(form).(phase).(wName) = fdata_norm.(form){w}(s,ix.(phase));
                    dat.fVal = fdata_phase.(form).(phase).(wName);
                    fact.subj = s;
                    fact.word = wName;
                    fact.formant = form;
                    fact.phase = phase;
                    fact.shift = shiftCat(s);
                    ptab{p} = get_datatable(dat,fact);
                    clear dat;
                end
                ftab{f} = vertcat(ptab{:});
            end

%             %calculate vector projection of compensation
%             for b = 1:nBins
%                 f1 =  fdata_norm.f1{w}(s,b);
%                 f2 =  fdata_norm.f2{w}(s,b);
%                 fdata_proj{w}(s,b) = dot([f1 f2],-1.*shifts_proj{s}{w})./125; %hard code 125 mel shift
%             end
%             for p = 1:nPhases
%                 phase = phases{p};
%                 fdata_proj_phase.(phase).(vName) = fdata_proj{w}(s,ix.(phase));
%                 dat.fVal = fdata_proj_phase.(phase).(vName);
%                 fact.subj = s;
%                 fact.vowel = vName;
%                 fact.formant = 'projection';
%                 fact.phase = phase;
%                 fact.shift = shiftCat{s};
%                 ptab{p} = get_datatable(dat,fact);
%                 clear dat;
%             end
%             ftab{3} = vertcat(ptab{:});
            wtab{w} = vertcat(ftab{:});
        end
       stab{s} = vertcat(wtab{:});
    end
    statTable = vertcat(stab{:});
    
%     % BP: not sure what this does anymore?
%     clear fdata_proj_phase
%     phaseNames = {'Adapt','Washout'};
%     for p = 1:2
%         pName = phaseNames{p};
%         phaseLoc = phases{p};
%         for v = 1:nVows
%             vName = vNames{w};
%             phase = strcat(vName,pName);
%             fdata_proj_phase.(phase) = fdata_proj{w}(:,ix.(phaseLoc));
%         end
%     end

    if bSave
        bSave = savecheck(fullfile(get_acoustLoadPath(exptName),filenameTable));
        if bSave
            save(fullfile(get_acoustLoadPath(exptName),strcat(filenameTable,'.mat')),'statTable','-mat');
            save(fullfile(get_acoustLoadPath(exptName),strcat(filenamePlotData,'.mat')),'fdata', 'fdata_norm', 'fdata_norm_flip','ix','shiftCat','-mat');
            writetable(statTable,fullfile(get_acoustLoadPath(exptName),filenameTable));
        end
    end
end




end %EOF