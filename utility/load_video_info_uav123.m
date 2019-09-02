function [seq, ground_truth] = load_video_info_uav123(base_path, video)
    if ispc(), base_path = strrep(base_path, '\', '/'); end
    if base_path(end) ~= '/', base_path(end+1) = '/'; end

    ground_truth = dlmread([base_path 'anno/UAV123/' video '.txt']);
    seq.len = size(ground_truth, 1);
    seq.init_rect = ground_truth(1,:);
    img_path = [base_path '/data_seq/UAV123/' video '/'];
    
    if exist([img_path num2str(1, '%06i.png')], 'file'),
        img_files = num2str((1:seq.len)', [img_path '%06i.png']);
    elseif exist([img_path num2str(1, '%06i.jpg')], 'file'),
        img_files = num2str((1:seq.len)', [img_path '%06i.jpg']);
    elseif exist([img_path num2str(1, '%06i.bmp')], 'file'),
        img_files = num2str((1:seq.len)', [img_path '%06i.bmp']);
    elseif exist([img_path num2str(1, '%06i.jpg')], 'file'),
        img_files = num2str((1:seq.len)', [img_path '%06i.jpg']);
    else
        error('No image files to load.')
    end

seq.s_frames = cellstr(img_files);
end

