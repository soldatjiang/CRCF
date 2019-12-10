base_path = 'D:\JiangShan\data_seq\OTB100-Test';
setup_paths();
video_path = choose_video(base_path);
[seq, ~] = load_video_info(video_path, 1);
results = run_CRCF(seq);
fprintf([video_path '\n'])
fprintf('FPS:%.3g\n',results.fps);