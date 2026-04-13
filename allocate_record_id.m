function [record_id, record_path] = allocate_record_id(method_path, timestamp_text)
if nargin < 2 || strlength(string(timestamp_text)) == 0
    timestamp_text = string(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss'));
end

timestamp_text = char(string(timestamp_text));
safe_time = regexprep(timestamp_text, '[\\/:*?"<>|]+', '-');

if ~exist(method_path, 'dir')
    mkdir(method_path);
end

index_file = fullfile(method_path, 'recindex.mat');
record_dirs = dir(fullfile(method_path, 'Rec*'));
existing_ids = [];
for k = 1:numel(record_dirs)
    if record_dirs(k).isdir
        token = regexp(record_dirs(k).name, '^Rec(\d+)', 'tokens', 'once');
        if ~isempty(token)
            existing_ids(end + 1) = str2double(token{1}); %#ok<AGROW>
        end
    end
end

last_id = 0;
if exist(index_file, 'file')
    s = load(index_file, 'recindex');
    if isfield(s, 'recindex') && ~isempty(s.recindex)
        last_id = max(last_id, double(s.recindex));
    end
end
if ~isempty(existing_ids)
    last_id = max(last_id, max(existing_ids));
end

record_id = last_id + 1;
record_path = fullfile(method_path, sprintf('Rec%d_%s', record_id, safe_time));

recindex = record_id; %#ok<NASGU>
save(index_file, 'recindex');
end
