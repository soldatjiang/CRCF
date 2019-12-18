function results = run_CRCF_Continuous(seq, res_path, bSaveImage, parameters)
params.cell_size = 4;
params.padding = 1;
params.lambda = 1e-3;
params.output_sigma_factor = 1/16;
    
params.learning_rate_cf = 0.013;
params.learning_rate_hist = 0.04;
params.learning_rate_scale = 0.025;
params.learning_rate = 0.01;
params.fixed_area = 150^2;

params.gaussian_merge_sample = true;
params.nSamples = 31;
params.data_type = zeros(1, 'single');
params.data_type_complex = complex(params.data_type);
params.train_gap = 5;

params.merge_factor = 0.3;

params.features{1} = struct('name', 'gray', 'dim', 1);
params.features{2} = struct('name', 'hog13', 'dim', 13);
params.features{3} = struct('name', 'cr', 'dim', 1, 'target_model', [], 'candidate_model', []);

params.features_large{1} = struct('name', 'hog13', 'dim', 13);
params.features_large{2} = struct('name', 'gray', 'dim', 1);

params.use_scale_filter = true;
params.scale_sigma_factor = 1/16;       % Scale label function sigma
params.scale_learning_rate = 0.025;		% Scale filter learning rate
params.number_of_scales = 17;    % Number of scales
params.number_of_interp_scales = 33;    % Number of interpolated scales
params.scale_model_factor = 1.0;        % Scaling of the scale model
params.scale_step = 1.02;        % The scale factor for the scale filter
params.scale_model_max_area = 32*16;    % Maximume area for the scale sample patch
params.scale_lambda = 1e-2;					% Scale filter regularization
params.do_poly_interp = true;           % Do 2nd order polynomial interpolation to obtain more accurate scale

params.form2 = false;
params.search_area_scale = 5;
params.det_scales = [1, 0.9, 1.1, 0.8, 1.2, 1.3];
%params.det_scales = [1];
params.admm_lambda = 1e-2;
params.skip_check_beginning = 25;
params.redetect_frames = 5;
params.set_size = 100;
params.debug = false;

params.ratio_cf_threshold = 0.6;
params.ratio_color_threshold = 0.7;
params.ratio_response_threshold = 0.6;

params.ratio_cf_threshold_recover = 0.7;
params.ratio_color_threshold_recover = 0.8;
params.ratio_response_threshold_recover = 0.7;

params.threshold_lost = 1.2;
params.threshold_recover = 1.5;

params.target_sz    = [seq.init_rect(1,4), seq.init_rect(1,3)];
params.init_pos = [seq.init_rect(1,2), seq.init_rect(1,1)] + floor(params.target_sz/2);
params.s_frames = seq.s_frames;
params.num_frames  = numel(seq.s_frames);

params.visualization = 1;
params.visualization_cmap = 0;
results = CRCF_tracker(params);
end
