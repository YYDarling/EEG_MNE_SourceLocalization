%% EEG Data Cleaning Pipeline (Updated Version)

clear;
clc;

% 基础路径
base_path = '/Users/duyun530/Documents/MATLAB/eeg_data_clean/Data/';
output_base_path = '/Users/duyun530/Documents/MATLAB/eeg_data_clean/data_test/data_test_h';
subjects = {'Sub125_Sham'};

% EEGLAB setup
if ~exist('eeglab', 'file')
    addpath('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0');
    eeglab;
end

% 初始化跳过文件记录
skipped_bad_segment = {};
skipped_ica_removal = {};

% 主循环处理每个 subject
for i = 1:length(subjects)
    subject_path = fullfile(base_path, subjects{i});
    subject_output_path = fullfile(output_base_path, subjects{i});
    if ~exist(subject_output_path, 'dir'), mkdir(subject_output_path); end
    
    poly5_files = dir(fullfile(subject_path, '*.poly5'));
    
    for j = 1:length(poly5_files)
        file_path = fullfile(subject_path, poly5_files(j).name);
        [~, filename, ~] = fileparts(file_path);
        file_output_path = fullfile(subject_output_path, filename);
        if ~exist(file_output_path, 'dir'), mkdir(file_output_path); end

        %% Step 1: 加载数据
        EEG = pop_biosig(file_path);
        if isempty(EEG.data), error('Failed to load the .poly5 file'); end

        %% Step 2: 从channel 66提取事件
        EEG = pop_chanevent(EEG, 66, 'edge', 'trailing', 'delchan', 'on', 'delevent', 'on');

        %% Step 3: 保留最频繁的event类型
        eventTypes = cellfun(@num2str, {EEG.event.type}, 'UniformOutput', false);
        [uTypes, ~, idx] = unique(eventTypes);
        counts = accumarray(idx, 1);
        maxType = uTypes{counts == max(counts)};
        if iscell(maxType)
            EEG.event = EEG.event(strcmp(eventTypes, maxType{1}));
        else
            EEG.event = EEG.event(strcmp(eventTypes, maxType));
        end

        %% Step 4: 添加通道位置信息并删除坏通道
        load('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0/chanlocs.mat');
        EEG.chanlocs = chanlocs;
        badChannels = {'UNI 13','UNI 14','UNI 15','UNI 21','UNI 22','UNI 23','UNI 24',...
                       'UNI 29','UNI 30','UNI 31','UNI 32','TRIGGERS','STATUS','COUNTER'};
        EEG = pop_select(EEG, 'nochannel', badChannels);

        %% Step 5: 滤波 (0.1–180 Hz, Notch: 58–65 Hz)
        EEG = pop_eegfiltnew(EEG, 0.1, 180, []);
        EEG = pop_eegfiltnew(EEG, 58, 65, [], 1);

        %% Step 6: 剔除坏段 (稳健处理)
        load('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0/rejectionIntervals.mat');
        subj = subjects{i};
        sess = filename;

        if isfield(rejectionIntervals, subj) && isfield(rejectionIntervals.(subj), sess)
            reject_points = rejectionIntervals.(subj).(sess);
            EEG = eeg_eegrej(EEG, reject_points);
        else
            warning('⚠️ Subject "%s"或Session "%s"坏段数据不存在，已跳过！', subj, sess);
            skipped_bad_segment{end+1} = [subj, '/', sess];
        end

        %% Step 7: 平均参考重参考
        EEG = pop_reref(EEG, []);

        %% Step 8: ICA分解及ICLabel分类
        EEG = pop_runica(EEG, 'icatype', 'runica', 'pca', 35, 'extended', 1, 'rndreset', 'yes');
        EEG = iclabel(EEG);

        % 保存ICA未剔除版本
        pop_saveset(EEG, 'filename', 'ica_unpruned.set', 'filepath', file_output_path);
        save(fullfile(file_output_path, 'ica_unpruned.mat'), 'EEG');

        %% Step 9: 自动去除 artifact 成分 (稳健处理)
        IC_Val = EEG.etc.ic_classification.ICLabel.classifications;
        IC_Val_Trunc = IC_Val(:,1:5) ./ sum(IC_Val(:,1:5), 2);
        Cond1 = (IC_Val(:,6) ~= max(IC_Val, [], 2));
        Cond2 = IC_Val_Trunc(:,1) >= 0.5;
        Cond_T = ~and(Cond1, Cond2);
        Cond_T_idx = find(Cond_T);

        fprintf('[%s/%s] ICs marked for removal: %d of %d\n', ...
            subjects{i}, filename, length(Cond_T_idx), size(EEG.icawinv, 2));

        if isempty(Cond_T_idx) || length(Cond_T_idx) == size(EEG.icawinv,2)
            warning('⚠️ 没有可保留的IC成分，已跳过ICA去除步骤！');
            skipped_ica_removal{end+1} = [subj, '/', sess];
        else
            EEG = pop_subcomp(EEG, Cond_T_idx, 0);
        end

        %% Step 10: 保存最终数据
        pop_saveset(EEG, 'filename', 'final.set', 'filepath', file_output_path);
        save(fullfile(file_output_path, 'final.mat'), 'EEG');

        fprintf('✅ 完成并保存: %s\n', fullfile(file_output_path, 'final.mat'));
    end
end   

%% 最终汇总输出
disp('---------------------------------------------------');
disp('✨ EEG数据处理完成，以下是跳过的文件汇总：');

if isempty(skipped_bad_segment)
    disp('✅ 所有文件均成功完成坏段剔除步骤。');
else
    disp('⚠️ 坏段剔除步骤跳过的文件:');
    disp(skipped_bad_segment');
end

if isempty(skipped_ica_removal)
    disp('✅ 所有文件均成功完成ICA成分去除步骤。');
else
    disp('⚠️ ICA成分去除步骤跳过的文件:');
    disp(skipped_ica_removal');
end

disp('---------------------------------------------------');

% 清理环境
eeglab redraw;
eeglab close;
