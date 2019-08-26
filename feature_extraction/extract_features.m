function [out, colour_map] = extract_features(patch, features)
    out_channels = 0;
    [h, w, ~] = size(patch);
    out_h = floor(h/4);
    out_w = floor(w/4);
    for f = 1:length(features)
        out_channels = out_channels + features{f}.dim;
    end
    out = zeros(out_h, out_w, out_channels);
    colour_map = [];
    
    cur_dim = 0;
    for f = 1:length(features)
        cur_feature = features{f};
        if strcmp(cur_feature.name, 'hog13')
            %tmp = Hog13Feature(single(patch));
            tmp = hog13(single(patch));
        elseif strcmp(cur_feature.name, 'gray')
            if size(patch, 3)>1
                tmp = single(rgb2gray(patch))/255 - 0.5;
            else
                tmp = single(patch)/255 - 0.5;
            end
            tmp = mexResize(tmp, [out_h, out_w]);
        elseif strcmp(cur_feature.name, 'cr')
            colour_map = single(get_colour_map(patch, cur_feature.target_model, cur_feature.candidate_model, 3));
            tmp = mexResize(colour_map, [out_h, out_w]);
        else
            error('feature not implemented!');
        end
        
        out(:,:,cur_dim + (1:cur_feature.dim)) = tmp;
        cur_dim = cur_dim + cur_feature.dim;
    end
end