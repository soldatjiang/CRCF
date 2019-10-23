function results = CRCF_tracker(params)
cell_size = params.cell_size;
padding = params.padding;
lambda = params.lambda;
output_sigma_factor = params.output_sigma_factor;
features = params.features;
    
learning_rate_cf = params.learning_rate_cf;
learning_rate_hist = params.learning_rate_hist;
learning_rate_scale = params.learning_rate_scale;

merge_factor = params.merge_factor;

params = init_all_areas(params);
window_sz = params.window_sz;
norm_window_sz = params.norm_window_sz;
norm_resize_factor = params.norm_resize_factor;
norm_target_sz = params.norm_target_sz;
norm_likelihood_sz = params.norm_likelihood_sz;
norm_delta_sz = params.norm_delta_sz;
cf_response_sz = params.cf_response_sz;

s_frames = params.s_frames;
pos = floor(params.init_pos);
old_pos = pos;
target_sz = floor(params.target_sz);
num_frames = params.num_frames;

rect_position = zeros(num_frames, 4);

base_target_sz = target_sz;

output_sigma = sqrt(prod(norm_target_sz)) * output_sigma_factor / cell_size;
y = gaussian_response(cf_response_sz, output_sigma);
yf = fft2(y);

center =(1 + norm_delta_sz) / 2;

cos_window = hann(cf_response_sz(1))*hann(cf_response_sz(2))';
currentScaleFactor = 1.0;

refinement_iteration = 1;

%channel_weights(1) = 0.3850; % Gray Feature
%channel_weights(2:14) = 0.3150; % HOG13 Feature
%channel_weights(15) = 0.3; %  CR Feature
%prior_weights = ones(15,1);
%prior_weights = prior_weights / sum(prior_weights);
%channel_weights = reshape(channel_weights, 1,1,15);

if params.use_scale_filter
    scale_sigma_factor= params.scale_sigma_factor;
    nScales = params.number_of_scales;
    nScalesInterp = params.number_of_interp_scales;
    scale_model_factor = params.scale_model_factor;
    scale_step = params.scale_step;
    scale_model_max_area = params.scale_model_max_area;
    scale_lambda = params.scale_lambda;
    
    scale_sigma = nScalesInterp * scale_sigma_factor;
    
    scale_exp = (-floor((nScales-1)/2):ceil((nScales-1)/2)) * nScalesInterp/nScales;
    scale_exp_shift = circshift(scale_exp, [0 -floor((nScales-1)/2)]);
    
    interp_scale_exp = -floor((nScalesInterp-1)/2):ceil((nScalesInterp-1)/2);
    interp_scale_exp_shift = circshift(interp_scale_exp, [0 -floor((nScalesInterp-1)/2)]);
    
    scaleSizeFactors = scale_step .^ scale_exp;
    interpScaleFactors = scale_step .^ interp_scale_exp_shift;
    
    ys = exp(-0.5 * (scale_exp_shift.^2) /scale_sigma^2);
    ysf = single(fft(ys));
    scale_window = single(hann(size(ysf,2)))';
    
    %make sure the scale model is not to large, to save computation time
    if scale_model_factor^2 * prod(base_target_sz) > scale_model_max_area
        scale_model_factor = sqrt(scale_model_max_area/prod(base_target_sz));
    end
    
    %set the scale model size
    scale_model_sz = floor(base_target_sz * scale_model_factor);
    
    im = imread(s_frames{1});
    
    %force reasonable scale changes
    min_scale_factor = scale_step ^ ceil(log(max(5 ./ window_sz)) / log(scale_step));
    max_scale_factor = scale_step ^ floor(log(min([size(im,1) size(im,2)] ./ base_target_sz)) / log(scale_step));
end

if params.gaussian_merge_sample
    % Distance matrix stores the square of the euclidean distance between each pair of
    % samples. Initialise it to inf
    distance_matrix = inf(params.nSamples, 'single');
    % Kernel matrix, used to update distance matrix
    gram_matrix = inf(params.nSamples, 'single');
    samplesf = zeros(params.nSamples,cf_response_sz(1),cf_response_sz(2),15, 'like', params.data_type_complex);
    params.minimum_sample_weight = params.learning_rate*(1-params.learning_rate)^(2*params.nSamples);
    prior_weights = zeros(params.nSamples,1);
    num_training_samples = 0;
end

time = 0;

for frame = 1:num_frames
    im = imread(s_frames{frame});
    
    tic();
    if frame>1
        iter = 1;
        while iter<=refinement_iteration
            patch = get_subwindow(im, pos, norm_window_sz, window_sz);
            [xt, colour_map] = extract_features(patch, features);
            %likelihood_map = mexResize(colour_map, cf_response_sz);
            %if (sum(likelihood_map(:))/prod(cf_response_sz)<0.01), likelihood_map = 1; end    
            %cos_window = cos_window_org .* likelihood_map;
            %xt = bsxfun(@times, xt, channel_weights);
            %xt = cellfun(@times, xt, prior_weights, 'uniformoutput', false);
            xt = bsxfun(@times, xt, cos_window); 
            xtf = fft2(xt);
            hf = bsxfun(@rdivide, hf_num, sum(hf_den, 3)+lambda);
            
            %channel_response = hf .* xtf;
            
            %channel_max = max(max(channel_response, [], 1), [], 2);
            %channel_APCE = APCE(channel_response);
            %channel_weight = channel_max .* channel_APCE;
            %channel_weight = channel_weight / sum(channel_weight(:));

            %response_cf = real(ifft2(sum(bsxfun(@times, channel_weight, channel_response), 3)));
            response_cf = real(ifft2(sum(hf .* xtf, 3)));
            weight_cf = max(response_cf(:)) * squeeze(APCE(response_cf));

            colour_map = mexResize(colour_map, norm_likelihood_sz);
            response_color = getCenterLikelihood(colour_map, norm_target_sz);
            
            %response_cf = sum(response_cf, 3);
            response_cf = crop_response(response_cf, floor_odd(norm_delta_sz / cell_size));
            response_cf = mexResize(response_cf, norm_delta_sz, 'auto');
            
            weight_color = max(response_color(:)) * squeeze(APCE(response_color));
            merge_factor = weight_color/(weight_cf + weight_color);
            
            response = (1 - merge_factor) * response_cf + merge_factor * response_color;
            [row, col] = find(response == max(response(:)), 1);
            old_pos = pos;
            pos = pos + ([row, col] - center) / norm_resize_factor;
            
            iter = iter + 1;
        end
        
        if params.use_scale_filter
            %create a new feature projection matrix
            [xs_pca, xs_npca] = get_scale_subwindow(im,pos,base_target_sz,currentScaleFactor*scaleSizeFactors,scale_model_sz);

            xs = feature_projection_scale(xs_npca,xs_pca,scale_basis,scale_window);
            xsf = fft(xs,[],2);

            scale_responsef = sum(sf_num .* xsf, 1) ./ (sf_den + scale_lambda);

            interp_scale_response = ifft( resizeDFT(scale_responsef, nScalesInterp), 'symmetric');

            recovered_scale_index = find(interp_scale_response == max(interp_scale_response(:)), 1);

            %set the scale
            currentScaleFactor = currentScaleFactor * interpScaleFactors(recovered_scale_index);
            %adjust to make sure we are not to large or to small
            if currentScaleFactor < min_scale_factor
                currentScaleFactor = min_scale_factor;
            elseif currentScaleFactor > max_scale_factor
                currentScaleFactor = max_scale_factor;
            end
        end

        target_sz = round(base_target_sz * currentScaleFactor);
        avg_dim = sum(target_sz)/2;
        window_sz = round(target_sz + padding*avg_dim);
        if(window_sz(2)>size(im,2)),  window_sz(2)=size(im,2)-1;    end
        if(window_sz(1)>size(im,1)),  window_sz(1)=size(im,1)-1;    end

        window_sz = window_sz - mod(window_sz - target_sz, 2);

        norm_resize_factor = sqrt(params.fixed_area/prod(window_sz));  
    end
    
    features{3} = update_histogram_model(im, pos, target_sz, learning_rate_hist, features{3});
    patch = get_subwindow(im, pos, norm_window_sz, window_sz);
    [xt,~] = extract_features(patch, features);
    %xt = bsxfun(@times, xt, channel_weights);
    %xt = cellfun(@times, xt, prior_weights, 'uniformoutput', false);
    xt = bsxfun(@times, xt, cos_window); 
    xtf = fft2(xt);
    if params.gaussian_merge_sample
        [merged_sample, new_sample, merged_sample_id, new_sample_id, distance_matrix, gram_matrix, prior_weights] = ...
                update_sample_space_model(samplesf, xtf, distance_matrix, gram_matrix, prior_weights,...
                num_training_samples,params);
            
        if num_training_samples < params.nSamples
            num_training_samples = num_training_samples + 1;
        end
        
        if merged_sample_id > 0
             samplesf(merged_sample_id,:,:,:) = merged_sample;
        end
        if new_sample_id > 0
             samplesf(new_sample_id,:,:,:) = new_sample;
        end
        
        if (frame==1||mod(frame, params.train_gap)==0)
            if num_training_samples < params.nSamples
                model_xf = sum(bsxfun(@times, prior_weights(1:num_training_samples), samplesf(1:num_training_samples,:,:,:)), 1);
                model_xf_den = sum(bsxfun(@times, prior_weights(1:num_training_samples).^2, samplesf(1:num_training_samples,:,:,:).*conj(samplesf(1:num_training_samples,:,:,:))), 1);
                model_xf = squeeze(model_xf);
                model_xf_den = squeeze(model_xf_den);
                hf_num = bsxfun(@times, yf, conj(model_xf));
                hf_den = model_xf_den;
            else
                model_xf = sum(bsxfun(@times, prior_weights, samplesf), 1);
                model_xf = squeeze(model_xf);
                model_xf_den = sum(bsxfun(@times, prior_weights.^2, samplesf.*conj(samplesf)), 1);
                model_xf_den = squeeze(model_xf_den);
                hf_num = bsxfun(@times, yf, conj(model_xf));
                hf_den = model_xf_den;
            end
        end
    else
        new_hf_num = bsxfun(@times, yf, conj(xtf));
        new_hf_den = conj(xtf) .* xtf;

        if frame == 1
             hf_num = new_hf_num;
             hf_den = new_hf_den;
        else
             hf_num = (1 - learning_rate_cf) * hf_num + learning_rate_cf * new_hf_num;
             hf_den = (1 - learning_rate_cf) * hf_den + learning_rate_cf * new_hf_den;
        end
    end
    
    if params.use_scale_filter
        %create a new feature projection matrix
        [xs_pca, xs_npca] = get_scale_subwindow(im, pos, base_target_sz, currentScaleFactor*scaleSizeFactors, scale_model_sz);

        if frame == 1
            s_num = xs_pca;
        else
            s_num = (1 - learning_rate_scale) * s_num + learning_rate_scale * xs_pca;
        end

        bigY = s_num;
        bigY_den = xs_pca;

        [scale_basis, ~] = qr(bigY, 0);
        [scale_basis_den, ~] = qr(bigY_den, 0);
        scale_basis = scale_basis';

        %create the filter update coefficients
        sf_proj = fft(feature_projection_scale([],s_num,scale_basis,scale_window),[],2);
        sf_num = bsxfun(@times,ysf,conj(sf_proj));

        xs = feature_projection_scale(xs_npca,xs_pca,scale_basis_den',scale_window);
        xsf = fft(xs,[],2);
        new_sf_den = sum(xsf .* conj(xsf),1);

        if frame == 1
            sf_den = new_sf_den;
        else
            sf_den = (1 - learning_rate_scale) * sf_den + learning_rate_scale * new_sf_den;
        end;
    end

    %save position and calculate FPS
    rect_position(frame,:) = [pos([2,1]) - floor(target_sz([2,1])/2), target_sz([2,1])];

    time = time + toc();
    
    if params.visualization == 1
        rect_position_vis = [pos([2,1]) - (target_sz([2,1]) - 1)/2, target_sz([2,1])];
        im_to_show = double(im)/255;
        if size(im_to_show,3) == 1
            im_to_show = repmat(im_to_show, [1 1 3]);
        end

        if frame == 1,  %first frame, create GUI
            fig_handle = figure('Name','CRCF tracker');
            imagesc(im_to_show)
            %imshow(uint8(im), 'Border','tight', 'InitialMag', 100 + 100 * (length(im) < 500));
            rectangle('Position',rect_position_vis, 'EdgeColor','g', 'LineWidth',2);
            text(10, 10, int2str(frame), 'color', [0 1 1]);
            hold on;
            resp_sz = round(norm_delta_sz*currentScaleFactor);
            xs = floor(old_pos(2)) + (1:resp_sz(2)) - floor(resp_sz(2)/2);
            ys = floor(old_pos(1)) + (1:resp_sz(1)) - floor(resp_sz(1)/2);
            resp_handle = imagesc(xs, ys, zeros(resp_sz)); colormap hsv;
            alpha(resp_handle, 0.5);
            hold off;
            axis off;axis image;set(gca, 'Units', 'normalized', 'Position', [0 0 1 1])
            if params.visualization_cmap
                cmap_handle = figure('Name', 'Color map')
            end
        else
            try  %subsequent frames, update GUI
                figure(fig_handle)
                %imshow(uint8(im), 'Border','tight', 'InitialMag', 100 + 100 * (length(im) < 500));
                imagesc(im_to_show)
                rectangle('Position',rect_position_vis, 'EdgeColor','g', 'LineWidth',2);
                text(10, 10, int2str(frame), 'color', [0 1 1]);
                hold on;
                resp_sz = round(norm_delta_sz*currentScaleFactor);
                xs = floor(old_pos(2)) + (1:resp_sz(2)) - floor(resp_sz(2)/2);
                ys = floor(old_pos(1)) + (1:resp_sz(1)) - floor(resp_sz(1)/2);
                resp_handle = imagesc(xs, ys, response); colormap hsv;
                alpha(resp_handle, 0.5);
                hold off;
                if params.visualization_cmap
                    figure(cmap_handle)
                    imshow(colour_map)
                end
            catch
                disp("Catch exception")
                return
            end
        end   
    drawnow
%         pause
    end
end 

fps = num_frames / time;
% disp(['fps: ' num2str(fps)])
if params.visualization == 1
    %close(fig_handle);
end

results.type = 'rect';
results.res = rect_position;
results.fps = fps;

end

% We want odd regions so that the central pixel can be exact
function y = floor_odd(x)
    y = 2*floor((x-1) / 2) + 1;
end

function out = APCE(response)
    eps = 1e-4;
    rmax = max(max(response, [], 1), [], 2);
    rmin = min(min(response, [], 1), [], 2);
    out = (rmax-rmin).^2 ./ (mean(mean((response-rmin).^2, 1), 2) + eps);
end