function video = choose_video(base_path)

% video_path = choose_video(base_path)

%process path to make sure it's uniform
if ispc(), base_path = strrep(base_path, '\', '/'); end
if base_path(end) ~= '/', base_path(end+1) = '/'; end

base_path = [base_path 'data_seq/UAV123/'];

%list all sub-folders
contents = dir(base_path);
names = {};
for k = 1:numel(contents),
    name = contents(k).name;
    if isdir([base_path name]) && ~strcmp(name, '.') && ~strcmp(name, '..'),
        names{end+1} = name;  %#ok
    end
end

%no sub-folders found
if isempty(names), video = []; return; end

%choice GUI
choice = listdlg('ListString',names, 'Name','Choose video', 'SelectionMode','single');

if isempty(choice),  %user cancelled
    video = [];
else
    video = names{choice};
end

end