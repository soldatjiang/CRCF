function hashcode = compute_hashcode(patch, target_sz)
    [h, w, ~] = size(patch);
    center = floor([h/2, w/2]);
    ys = center(1) + (-floor((target_sz(1)-1)/2):ceil((target_sz(1)-1)/2));
    xs = center(2) + (-floor((target_sz(2)-1)/2):ceil((target_sz(2)-1)/2));
    target_patch = patch(ys, xs, :);
    if size(target_patch, 3)>1
        target_patch = rgb2gray(target_patch);
    end
    patchTmp = mexResize(target_patch, [8, 9]);
    cmp1 = patchTmp(:,1:8,:);
    cmp2 = patchTmp(:,2:9,:);
    hashMatrix = cmp1>cmp2;
    hashcode = hashMatrix(:);
end