function results = CRCF_tracker(params)
cell_size = params.cell_size;
padding = params.padding;
lambda = params.lambda;
output_sigma_factor = params.output_sigma_factor;
features = params.features;
    
learning_rate_cf = params.learning_rate_cf;
learning_rate_hist = params.learning_rate_hist;
learning_rate_scale = params.learning_rate_scale;

%im = imread(params.s_frames{1});

%im_sz = size(im);
%if prod(params.target_sz)/prod(im_sz(1:2))>0.05
%    params.padding = 1;
%else
%    params.padding = 1.5;
%end

%padding = params.padding;

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
%cos_window = hann(norm_window_sz(1))*hann(norm_window_sz(2))';
currentScaleFactor = 1.0;

refinement_iteration = 1;

channel_weights(1) = 0.35; % Gray Feature
channel_weights(2:14) = 0.15; % HOG13 Feature
channel_weights(15) = 0.5; %  CR Feature
%prior_weights = ones(15,1);
%prior_weights = prior_weights / sum(prior_weights);
channel_weights = reshape(channel_weights, 1,1,15);

if params.use_scale_filter
    scale_sigma_factor= params.scale_sigma_factor;
    nScales = params.number_of_scales;
    scale_model_factor = params.scale_model_factor;
    scale_step = params.scale_step;
    scale_model_max_area = params.scale_model_max_area;
    scale_lambda = params.scale_lambda;
    
    scale_sigma = sqrt(nScales) * scale_sigma_factor;
    ss = (1:nScales) - ceil(nScales/2);
    ys = exp(-0.5 * (ss.^2) / scale_sigma^2);
    ysf = single(fft(ys));
    
    ss = 1:nScales;
    scaleSizeFactors = scale_step.^(ceil(nScales/2) - ss);
    scale_window = single(hann(size(ysf,2)))';
    
    %make sure the scale model is not to large, to save computation time
    if scale_model_factor^2 * prod(base_target_sz) > scale_model_max_area
        scale_model_factor = sqrt(scale_model_max_area/prod(base_target_sz));
    end
    
    %set the scale model size
    scale_model_sz = floor(base_target_sz * scale_model_factor);
    
    im = imread(params.s_frames{1});
    
    %force reasonable scale changes
    min_scale_factor = scale_step ^ ceil(log(max(5 ./ window_sz)) / log(scale_step));
    max_scale_factor = scale_step ^ floor(log(min([size(im,1) size(im,2)] ./ base_target_sz)) / log(scale_step));
end

time = 0;

for frame = 1:num_frames
    im = imread(s_frames{frame});
    
    tic();
    if frame>1
        iter = 1;
        while iter<=refinement_iteration
            patch = get_subwindow(im, pos, norm_window_sz, window_sz);
            %patch = uint8(bsxfun(@times, single(patch), cos_window));
            [xt, colour_map] = extract_features(patch, features);
            xt = bsxfun(@times, xt, channel_weights);
            xt = bsxfun(@times, xt, cos_window); 
            xtf = fft2(xt);
            hf = bsxfun(@rdivide, hf_num, sum(hf_den, 3)+lambda);

            response_cf = real(ifft2(sum(hf .* xtf, 3)));
            
            %max_cf = max(response_cf(:));
            %apce_cf = APCE(response_cf);
            %psr_cf = PSR(response_cf);

            colour_map = mexResize(colour_map, norm_likelihood_sz);
            response_color = getCenterLikelihood(colour_map, norm_target_sz);
            
            %max_color = max(response_color(:));
            %apce_color = APCE(response_color);
            %psr_color = PSR(response_color);
            
            %response_cf = sum(response_cf, 3);
            response_cf = crop_response(response_cf, floor_odd(norm_delta_sz / cell_size));
            response_cf = mexResize(response_cf, norm_delta_sz, 'auto');
            
            %weight_color = max_color * apce_color;
            %weight_cf = max_cf * apce_cf;
            
            %merge_factor = log(weight_color) / (log(weight_cf) + log(weight_color));
            %merge_factor = weight_color/(weight_cf + weight_color);
            
            %merge_factor = max_color*apce_color/(max_cf*apce_cf + max_color*apce_color);
            %merge_factor = 0.3;
            
            response = (1 - merge_factor) * response_cf + merge_factor * response_color;
            [row, col] = find(response == max(response(:)), 1);
            old_pos = pos;
            pos = pos + ([row, col] - center) / norm_resize_factor;
            
            iter = iter + 1;
        end
        
        if params.use_scale_filter
            %create a new feature projection matrix
            xs = get_scale_subwindow(im, pos, base_target_sz, currentScaleFactor*scaleSizeFactors, scale_model_sz, scale_window);

            xsf = fft(xs,[],2);

            scale_responsef = sum(sf_num .* xsf, 1) ./ (sf_den + scale_lambda);
            scale_response = real(ifft(scale_responsef));

            recovered_scale_index = find(scale_response == max(scale_response(:)), 1);
            %set the scale
            currentScaleFactor = currentScaleFactor * scaleSizeFactors(recovered_scale_index);
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
    %patch = uint8(bsxfun(@times, single(patch), cos_window));
    [xt,~] = extract_features(patch, features);
    xt = bsxfun(@times, xt, channel_weights);
    %xt = cellfun(@times, xt, prior_weights, 'uniformoutput', false);
    xt = bsxfun(@times, xt, cos_window); 
    xtf = fft2(xt);
    new_hf_num = bsxfun(@times, yf, conj(xtf));
    new_hf_den = conj(xtf) .* xtf;
    
    if frame == 1
         hf_num = new_hf_num;
         hf_den = new_hf_den;
    else
         hf_num = (1 - learning_rate_cf) * hf_num + learning_rate_cf * new_hf_num;
         hf_den = (1 - learning_rate_cf) * hf_den + learning_rate_cf * new_hf_den;
    end
    
    if params.use_scale_filter
        %create a new feature projection matrix
        xs = get_scale_subwindow(im, pos, base_target_sz, currentScaleFactor*scaleSizeFactors, scale_model_sz, scale_window);
        xsf = fft(xs,[],2);
        new_sf_num = bsxfun(@times, ysf, conj(xsf));
        new_sf_den = sum(xsf .* conj(xsf), 1);
        
        if frame == 1
            sf_num = new_sf_num;
            sf_den = new_sf_den;
        else
            sf_num = (1 - learning_rate_scale) * sf_num + learning_rate_scale * new_sf_num;
            sf_den = (1 - learning_rate_scale) * sf_den + learning_rate_scale * new_sf_den;
        end      
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

function out=PSR(res)
    eps = 1e-4;
    rmax = max(res(:));
    out = (rmax - mean(res(:)))/std(res(:));
end