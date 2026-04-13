function [method_id, method_path] = allocate_method_id(root_path, method_note)
if nargin < 2 || strlength(string(method_note)) == 0
    method_note = "default";
end

method_note = char(string(method_note));
safe_note = regexprep(strtrim(method_note), '[\\/:*?"<>|]+', '_');
if isempty(safe_note)
    safe_note = 'default';
end

index_file = fullfile(root_path, 'methindex.mat');
method_dirs = dir(fullfile(root_path, 'Methods*'));
existing_ids = [];
for k = 1:numel(method_dirs)
    if method_dirs(k).isdir
        token = regexp(method_dirs(k).name, '^Methods(\d+)', 'tokens', 'once');
        if ~isempty(token)
            existing_ids(end + 1) = str2double(token{1}); %#ok<AGROW>
        end
    end
end

last_id = 0;
if exist(index_file, 'file')
    s = load(index_file, 'methindex');
    if isfield(s, 'methindex') && ~isempty(s.methindex)
        last_id = max(last_id, double(s.methindex));
    end
end
if ~isempty(existing_ids)
    last_id = max(last_id, max(existing_ids));
end

method_id = last_id + 1;
method_path = fullfile(root_path, sprintf('Methods%d_%s', method_id, safe_note));

methindex = method_id; %#ok<NASGU>
save(index_file, 'methindex');
end
