function feature = update_histogram_model(im, pos, target_sz, update_rate, feature)
    im = single(im);
    target_patch = crop_patch(im, pos, target_sz, 1);
    [h, w, d] = size(target_patch);
    tg_weight = 1:h*w;
    w2 = w/2;
    h2 = h/2;
    x = floor(tg_weight/h)+1;
    y = tg_weight-h*(x-1);
    tg_weight = 1-((y-h2)/h2).^2-((x-w2)/w2).^2;
    tg_weight(find(tg_weight<0))=0;
    
    if d==3 % rgb histogram
        r = target_patch(:,:,1);
        g = target_patch(:,:,2);
        b = target_patch(:,:,3);
        index_im = 1+floor(r(:)/16)+floor(g(:)/16)*16+floor(b(:)/16)*16*16;
        target_model_tmp = accumarray(index_im, tg_weight,[16*16*16 1])/sum(tg_weight);
        candidate_patch = crop_patch(im, pos, target_sz, 3);
        r = candidate_patch(:,:,1);
        g = candidate_patch(:,:,2);
        b = candidate_patch(:,:,3);
        index_im = 1+floor(r(:)/16)+floor(g(:)/16)*16+floor(b(:)/16)*16*16;
        candidate_model_tmp = accumarray(index_im, 1,[16*16*16 1])/(9*h*w);
    else % grayscale histogram
        index_im = 1+floor(target_patch(:)/16);
        target_model_tmp = accumarray(index_im, tg_weight,[16 1])/sum(tg_weight);
        candidate_patch = crop_patch(im, pos, target_sz, 3);
        index_im = 1+floor(candidate_patch(:)/16);
        candidate_model_tmp = accumarray(index_im, 1, [16 1])/(9*h*w);
    end
    
    if isempty(feature.target_model)
         feature.target_model = target_model_tmp;
         feature.candidate_model = candidate_model_tmp;
    else
         feature.target_model = (1 - update_rate) * feature.target_model + update_rate * target_model_tmp;  
         feature.candidate_model = (1 - update_rate) * feature.candidate_model + update_rate * candidate_model_tmp;
    end
end