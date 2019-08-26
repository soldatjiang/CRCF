function setup_paths()
[pathstr, ~, ~] = fileparts(mfilename('fullpath'));
addpath(genpath([pathstr '/implementation/']));
addpath(genpath([pathstr '/utility/']));
addpath(genpath([pathstr '/feature_extraction/']));
addpath(genpath([pathstr '/localization/']));
