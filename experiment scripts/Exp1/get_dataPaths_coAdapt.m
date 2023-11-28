function [dataPaths] = get_dataPaths_coAdapt
% Get data paths for coAdapt expt.

svec = [327 345 394 396 397 399 400 401 402 403 405 410 411 412 414];
dataPaths = get_acoustLoadPaths('coAdapt',svec);

