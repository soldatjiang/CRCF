function test_on_OTB(exp_id)
    base_path = 'D:\JiangShan\data_seq\OTB100-Test';
    setup_paths();
    result_path = 'results';

    if ispc(), base_path = strrep(base_path, '\', '/'); end
    if base_path(end) ~= '/', base_path(end+1) = '/'; end
    if ispc(), result_path = strrep(result_path, '\', '/'); end
    if result_path(end) ~= '/', result_path(end+1) = '/'; end

    % If we don't specify experiment id, we make a new directory to store
    % experimental results
    if nargin<1
        % Make directory to store experimental results
        exp_dirs = dir([result_path 'exp*']);
        exp_names = {};
        for k = 1:numel(exp_dirs),
            name = exp_dirs(k).name;
            if isdir([result_path name]) && ~strcmp(name, '.') && ~strcmp(name, '..'),
                exp_names{end+1} = name;  %#ok
            end
        end
        
        if isempty(exp_names)
            exp_path = [result_path 'exp0'];
            mkdir(exp_path);
        else
            % sort experimental names according to experimental ids in
            % ascending order
            ids = cellfun(@(name) str2num(name(4:end)), exp_names);
            [~, idx] = sort(ids, 'ascend');
            exp_names = exp_names(idx);
            last = exp_names{end};
            id = str2num(last(4:end));
            exp_path = [result_path 'exp' num2str(id+1)];
            mkdir(exp_path);
        end
        
        videos = OTB_videos;
        FPSs = zeros(numel(videos),1);
        results_all = [];
        ground_truth_all = [];
        for vid = 1:numel(videos)
            if strcmp(videos{vid}, 'BlurCar1')
                start_frame = 247;
            elseif strcmp(videos{vid}, 'BlurCar3')
                start_frame = 3;
            elseif strcmp(videos{vid}, 'BlurCar4')
                start_frame = 18;
            elseif strcmp(videos{vid}, 'BlurCar4')
                start_frame = 18;
            else
                start_frame = 1;
            end     
            
            video_path = [base_path '/' videos{vid}];
            [seq, ground_truth] = load_video_info(video_path, start_frame);
            results = run_CRCF(seq);
            rects = results.res;
            dlmwrite([exp_path '/' videos{vid}  '.txt'], rects, 'delimiter', '\t', 'precision', '%.2f');
            Precision = computePrecision(rects, ground_truth, 20);
            AUC = computeAUCScore(rects, ground_truth);
            FPS = results.fps;
            results_all = [results_all; rects];
            ground_truth_all = [ground_truth_all; ground_truth];
            %Pres(vid) = Precision;
            %AUCs(vid) = AUC;
            FPSs(vid) = FPS;
            fprintf("%s\tPrecision(20px): %.3f\tAUC:%.3f\tFPS:%.2f\n",videos{vid}, Precision, AUC, FPS);
        end
        
        Precision_Overall = computePrecision(results_all, ground_truth_all, 20);
        AUC_Overall = computeAUCScore(results_all, ground_truth_all);
        FPS_Overall = mean(FPSs);
        fprintf("Overall\tPrecision(20px): %.3f\tAUC:%.3f\tFPS:%.2f\n",Precision_Overall, AUC_Overall, FPS_Overall);
        
    else
        exp_path = [result_path 'exp' num2str(exp_id)];
        
        videos = OTB_videos;
        FPSs = zeros(numel(videos),1);
        results_all = [];
        ground_truth_all = [];
        for vid = 1:numel(videos)
            if strcmp(videos{vid}, 'BlurCar1')
                start_frame = 247;
            elseif strcmp(videos{vid}, 'BlurCar3')
                start_frame = 3;
            elseif strcmp(videos{vid}, 'BlurCar4')
                start_frame = 18;
            elseif strcmp(videos{vid}, 'BlurCar4')
                start_frame = 18;
            else
                start_frame = 1;
            end     
            
            video_path = [base_path '/' videos{vid}];
            [~, ground_truth] = load_video_info(video_path, start_frame);
            rects = dlmread([exp_path '/' videos{vid} '.txt']);
            Precision = computePrecision(rects, ground_truth, 20);
            AUC = computeAUCScore(rects, ground_truth);
            results_all = [results_all; rects];
            ground_truth_all = [ground_truth_all; ground_truth];
            %Pres(vid) = Precision;
            %AUCs(vid) = AUC;
            fprintf("%s\tPrecision(20px): %.3f\tAUC:%.3f\n",videos{vid}, Precision, AUC);
        end
        
        Precision_Overall = computePrecision(results_all, ground_truth_all, 20);
        AUC_Overall = computeAUCScore(results_all, ground_truth_all);
        fprintf("Overall\tPrecision(20px): %.3f\tAUC:%.3f\n",Precision_Overall, AUC_Overall);
        
    end
end