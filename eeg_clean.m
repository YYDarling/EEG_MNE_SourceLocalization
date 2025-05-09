%% eeg data clean
clear;
clc;


%% Load EEGLAB
if ~exist('eeglab', 'file')
    addpath('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0');
    eeglab;
end

%%
% 定义实验对象和文件名
subject = 'Sub125_Sham';
sub_filename = 'pre_1.poly5';

% 组合文件路径
file_path = sprintf('/Users/duyun530/Documents/MATLAB/eeg_data_clean/Data/%s/%s', subject, sub_filename); 
% 检查文件是否存在
if ~exist(file_path, 'file')
    error('指定的文件不存在，请检查文件路径。');
end

%%
% 使用pop_biosig导入.poly5数据
EEG = pop_biosig(file_path);
% EEG = pop_fileio(file_path);
if isempty(EEG.data)
    error('Failed to load poly5 file: %s', file_path);
end

%保存
output_folder = '/Users/duyun530/Documents/MATLAB/eeg_data_clean/data_test_output';

% 根据subject创建文件夹
subject_folder = fullfile(output_folder, subject);
if ~exist(subject_folder, 'dir')
    mkdir(subject_folder);
end

% 根据filename创建文件夹
sub_filename_folder = fullfile(subject_folder, strrep(sub_filename, '.poly5', ''));
if ~exist(sub_filename_folder, 'dir')
    mkdir(sub_filename_folder);
end

%保存数据。进行重新命名
saved_path = sub_filename_folder;
% EEG = pop_saveset(EEG, 'filename', 'init.set', 'filepath', saved_path);

%% import event from data channel
EEG = pop_chanevent(EEG, 66, 'edge', 'trailing', 'delchan', 'on', 'delevent', 'on'); % falling edge
if isempty(EEG.event) || length(EEG.event) < 3
    warning('⚠️ Insufficient events detected. Skipping.');
    return;
end

%% check event value
% Get all event types
eventTypes = {EEG.event.type}; 
% 统一转换为字符串，确保没有数值类型
eventTypes = cellfun(@num2str, eventTypes, 'UniformOutput', false);
% Count frequency of each unique type
[uTypes, ~, idx] = unique(eventTypes);
counts = accumarray(idx, 1);
% Find the most frequent event type
[~, maxIdx] = max(counts);
maxType = uTypes{maxIdx};
% Keep only events of the most frequent type
keepIdx = strcmp(eventTypes, maxType);
newEvent = EEG.event(keepIdx);

% Update EEG structure
EEG.event = newEvent;

%% add channel location
load('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0/chanlocs.mat');
EEG.chanlocs = chanlocs;

%% delete bad/selected channel
badChannels = {'UNI 13', 'UNI 14', 'UNI 15', 'UNI 21', 'UNI 22', 'UNI 23', ...
               'UNI 24', 'UNI 29', 'UNI 30', 'UNI 31', 'UNI 32', 'TRIGGERS', 'STATUS', 'COUNTER'};
allChannels = {EEG.chanlocs.labels};
keepIdx = ~ismember(allChannels, badChannels);
EEG = pop_select(EEG, 'channel', allChannels(keepIdx));

%% Print Remaining Channels
disp('Remaining channels after deletion:');
disp({EEG.chanlocs.labels});

%% 滤波
EEG = pop_eegfiltnew(EEG, 0.1, 180, []); % Bandpass 0.1-180Hz
EEG = pop_eegfiltnew(EEG, 58, 65, [], 1); % Notch 58-65Hz

%% Remove Bad Segments
load('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0/rejectionIntervals.mat')
[~, filename, ~] = fileparts(file_path);
eval(['reject_points = rejectionIntervals.', subject, '.', filename, ';']);
EEG = eeg_eegrej(EEG, reject_points);

%% Re-reference
EEG = pop_reref(EEG, []);

%% ICA + ICLabel
EEG = pop_runica(EEG, 'icatype', 'runica', 'pca', 35, 'extended', 1, 'rndreset', 'yes');
EEG = iclabel(EEG);

%% Auto Reject Bad ICs
IC_Val = EEG.etc.ic_classification.ICLabel.classifications;
IC_Val_Trunc = IC_Val(:, 1:5) ./ sum(IC_Val(:, 1:5), 2);
Cond1 = (IC_Val(:, 6) ~= max(IC_Val, [], 2));
Cond2 = IC_Val_Trunc(:, 1) >= 0.5;
Cond_T = ~and(Cond1, Cond2);
Cond_T_idx = find(Cond_T);
EEG = pop_subcomp(EEG, Cond_T_idx, 0);

%% Save .set and .mat
pop_saveset(EEG, 'filename', 'final.set', 'filepath', saved_path);
save(fullfile(saved_path, 'final.mat'), 'EEG');

fprintf('✅ Successfully processed and saved: %s\n', saved_path);

%% Cleanup
eeglab redraw;
eeglab close;

disp('✅ Single EEG file processing completed.');

