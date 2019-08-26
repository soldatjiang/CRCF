function AUC = computeAUCScore(rt, gt)
    %if size(rt,1)>size(gt,1)
    %    rt = rt(1:size(gt,1),:);
    %elseif size(rt,1)<size(gt,1)
    %    gt = gt(1:size(rt,1),:);
    %end

    thresholdSet = 0:0.05:1;
    successRate = zeros(1,numel(thresholdSet));
    rtbb = [rt(:,1:2), rt(:,1:2) + rt(:,3:4) - ones(size(rt,1), 2)];
    gtbb = [gt(:,1:2), gt(:,1:2) + gt(:,3:4) - ones(size(gt,1), 2)];
    rtArea = computeArea(rtbb);
    gtArea = computeArea(gtbb);
    overlapArea = computeOverlap(rtbb, gtbb);
    OP = overlapArea ./ (rtArea + gtArea - overlapArea);
    for k=1:numel(thresholdSet)
        threshold = thresholdSet(k);
        successRate(k) = sum(OP>=threshold)/size(rt,1);
    end
    AUC = mean(successRate);
end

function overlap = computeOverlap(rtbb, gtbb)
    xmin = max(rtbb(:,1),gtbb(:,1));
    xmax = min(rtbb(:,3),gtbb(:,3));
    ymin = max(rtbb(:,2),gtbb(:,2));
    ymax = min(rtbb(:,4),gtbb(:,4));
    overlap = computeArea([xmin, ymin, xmax, ymax]);
end

function area = computeArea(bb)
    area = (bb(:,3) - bb(:,1) + 1) .* (bb(:,4) - bb(:,2) + 1);
    area(area<0) = 0;
end

