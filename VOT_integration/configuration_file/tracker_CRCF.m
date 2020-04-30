% Copy this template configuration file to your VOT workspace.
% Enter the full path to the ECO repository root folder.

repo_path = ########

tracker_label = 'CRCF';
tracker_command = generate_matlab_command('benchmark_tracker_wrapper(''CRCF'', ''run_CRCF'', true)', {[repo_path '/VOT_integration/benchmark_wrapper']});
tracker_interpreter = 'matlab';