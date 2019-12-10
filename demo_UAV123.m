base_path = 'G:\BaiduYunDownload\UAV123\Dataset_UAV123';
setup_paths();
video = choose_video_uav123(base_path);
[seq, ~] = load_video_info_uav123(base_path, video);
results = run_CRCF(seq);
fprintf('FPS:%.3g\n',results.fps);