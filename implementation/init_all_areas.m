function params = init_all_areas(params)
avg_dim = sum(params.target_sz)/2;
% Size of search window during training and detection
params.window_sz = round(params.target_sz + params.padding*avg_dim);
params.window_sz = params.window_sz - mod(params.window_sz - params.target_sz, 2);
params.norm_resize_factor = sqrt(params.fixed_area / prod(params.window_sz));
params.norm_window_sz = round(params.window_sz * params.norm_resize_factor);
norm_target_sz_w = 0.75*params.norm_window_sz(2) - 0.25*params.norm_window_sz(1);
norm_target_sz_h = 0.75*params.norm_window_sz(1) - 0.25*params.norm_window_sz(2);
params.norm_target_sz = round([norm_target_sz_h norm_target_sz_w]);
norm_pad = floor((params.norm_window_sz - params.norm_target_sz) / 2);
radius = min(norm_pad);
% norm_delta_sz is the number of rectangles that are considered.
% it is the "sampling space" and the dimension of the final merged resposne
% it is squared to not privilege any particular direction
params.norm_delta_sz = (2*radius+1) * [1, 1];
params.norm_likelihood_sz = params.norm_target_sz + params.norm_delta_sz - 1;
params.cf_response_sz = floor(params.norm_window_sz / 4);
end