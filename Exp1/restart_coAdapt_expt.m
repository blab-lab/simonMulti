function expPath = restart_coAdapt_expt(expt)
%RESTART_COADAPT_EXPT  Restart coAdapt experiment after a crash.

% 2021-08 CWN init

if nargin < 1, expt = []; end

% now just wraps around the general simon restart script
expPath = restart_simon_expt(expt);

end
