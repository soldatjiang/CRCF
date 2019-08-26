function precision = computePrecision(rt, gt, threshold)
    %if size(rt,1)>size(gt,1)
    %    rt = rt(1:size(gt,1),:);
    %elseif size(rt,1)<size(gt,1)
    %    gt = gt(1:size(rt,1),:);
    %end
    c_rt = rt(:,[1,2]) + rt(:,[3,4])/2;
    c_gt = gt(:,[1,2]) + gt(:,[3,4])/2;
    error = sqrt(sum((c_rt - c_gt).^2, 2));
    precision = sum(error<=threshold) / size(gt, 1);
end