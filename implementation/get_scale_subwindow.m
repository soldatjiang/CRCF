function out = get_scale_subwindow(im, pos, base_target_sz, scaleFactors, scale_model_sz, scale_window)

nScales = length(scaleFactors);

for s = 1:nScales
    patch_sz = floor(base_target_sz * scaleFactors(s));
    
    xs = floor(pos(2)) + (1:patch_sz(2)) - floor(patch_sz(2)/2);
    ys = floor(pos(1)) + (1:patch_sz(1)) - floor(patch_sz(1)/2);
    
    %check for out-of-bounds coordinates, and set them to the values at
    %the borders
    xs(xs < 1) = 1;
    ys(ys < 1) = 1;
    xs(xs > size(im,2)) = size(im,2);
    ys(ys > size(im,1)) = size(im,1);
    
    %extract image
    im_patch = im(ys, xs, :);
    
    % resize image to model size
%     im_patch_resized = imresize(im_patch, scale_model_sz, 'bilinear');
    im_patch_resized = mexResize(im_patch, scale_model_sz, 'auto');
    
    % extract scale features
    %temp_hog = hog13(single(im_patch_resized));
    temp_hog = Hog13Feature(single(im_patch_resized));
    
    if s == 1
        dim_scale = size(temp_hog,1)*size(temp_hog,2)*13;
        out = zeros(dim_scale, nScales, 'single');
    end
    
    out(:,s) = reshape(temp_hog(:), dim_scale, 1) * scale_window(s);
end