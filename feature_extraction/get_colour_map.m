function colour_map = get_colour_map(patch, target_model, candidate_model, factor)
    patch = single(patch);
    [h, w, d] = size(patch);
    %bin_width = 256/16;
    %patch_array = reshape(double(patch), w*h, d);
    %bin_indices = floor(patch_array/bin_width)+1;
    %if d==1
    %    hist_indices = bin_indices;
    %else
    %    hist_indices = sub2ind(size(tg_hist),bin_indices(:,1),bin_indices(:,2),bin_indices(:,3));
    %end
     if d==3
         r = patch(:,:,1);
         g = patch(:,:,2);
         b = patch(:,:,3);
         index_im = 1+floor(r(:)/16)+floor(g(:)/16)*16+floor(b(:)/16)*16*16;
     else
         index_im = 1+floor(patch(:)/16);
     end
     %candidate_model(find(candidate_model==0))=1;
     ratio_table = sqrt(target_model./candidate_model);
     ratio_table(find(target_model==0))=0;
     %ratio_table(find(tg_hist==0))=0.5*norm;
     colour_map = reshape(ratio_table(index_im), h, w) / factor;
     %colour_map(find(colour_map>1.0)) = 1.0;
%     tg_map = tg_hist(hist_indices);
%     cxt_map = cxt_hist(hist_indices);
%     colour_map = reshape(sqrt(tg_map./cxt_map), h, w);
%     colour_map = colour_map / max(colour_map(:));
end

