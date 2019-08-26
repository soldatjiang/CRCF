function patch = crop_patch(im, pos, target_sz, factor)
    sz = target_sz * factor;
    %patch = 127 * ones([sz(1) sz(2) size(im,3)],'uint8');
    xs = floor(pos(2)) + (1:sz(2)) - floor(sz(2)/2);
    ys = floor(pos(1)) + (1:sz(1)) - floor(sz(1)/2);
    %px = 1:sz(2);
    %py = 1:sz(1);
    
    %check for out-of-bounds coordinates, and set them to the values at
    %the borders
    xs(xs < 1) = 1;
    %px(xs < 1) = sz(2)-numel(find(~(xs < 1)));
    ys(ys < 1) = 1;
    %py(ys < 1) = sz(2)-numel(find(~(ys < 1)));
    xs(xs > size(im,2)) = size(im,2);
    %px(xs > size(im,2)) = numel(find(~(xs > size(im,2))));
    ys(ys > size(im,1)) = size(im,1);
    %py(ys > size(im,1)) = numel(find(~(ys > size(im,1))));
    
    patch = im(ys, xs, :);
end

