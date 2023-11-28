function [dataPaths] = get_dataPaths_simonMultisyllable(bPilot)
%GET_DATAPATHS_SIMONMULTISYLLABLE  Get datapaths for v1 of the simonMultisyllable experiment.

if nargin < 1, bPilot = 0; end

if bPilot
    svec = {'test-ben-1129-01' 'rpk_20211207' 'test-addie-1208-1' ...
        'test-chris-1208-1' 'test-kathryn-1208-1'};
else    
    %svec = [318 338 449 455 457 459 460 463 504 400 329 469];
    svec = [318 338 455 457 459 460 504 400 329 469 524 529]; % removed sp449 and sp463 for mispronunciations -- see notes in Data Analysis Tracker
end

dataPaths = get_acoustLoadPaths('simonMultisyllable',svec);
