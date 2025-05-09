%% eeg data clean
clear
clc
% close all

%%
% 基础路径
base_path = '/Users/duyun530/Documents/MATLAB/eeg_data_clean/Data/';

% 定义保存输出文件的基础路径
output_base_path = '/Users/duyun530/Documents/MATLAB/eeg_data_clean/data_test/data_test_h';

% 定义实验对象数组
% subjects = {'Sub125_Active', 'Sub125_Sham'}; 
subjects = {'Sub101_Active'};


%%
% 确保EEGLAB已经正确加载
if ~exist('eeglab', 'file')
    addpath('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0');
    eeglab;
end

%%
% 循环处理每个实验对象
for i = 1:length(subjects)
    % 构建当前实验对象的文件夹路径
    subject_path = fullfile(base_path, subjects{i});

    % 构建当前实验对象对应的输出文件夹路径
    subject_output_path = fullfile(output_base_path, subjects{i});

    % 创建实验对象输出文件夹
    if ~exist(subject_output_path, 'dir')
        mkdir(subject_output_path);
    end
    
    % 获取当前实验对象文件夹下所有.poly5文件
    poly5_files = dir(fullfile(subject_path, '*.poly5'));
    
    % 循环处理每个.poly5文件
    for j = 1:length(poly5_files)
        %%
        % 构建当前.poly5文件的完整路径
        file_path = fullfile(subject_path, poly5_files(j).name);

        % 获取当前.poly5文件名（不含扩展名）
        [~, filename, ~] = fileparts(file_path);

        % 构建当前.poly5文件对应的输出文件夹路径
        file_output_path = fullfile(subject_output_path, filename);

        % 创建.poly5文件输出文件夹，如果不存在的话
        if ~exist(file_output_path, 'dir')
            mkdir(file_output_path);
        end

        %% init
        % 加载数据
        EEG = pop_biosig(file_path);
        % EEG = pop_loadset('filename', file_path);还没试过

        if isempty(EEG.data)
            error('Failed to load the .poly5 file');
        end

        % 检查EEG的结构体是否完整
        % EEG = eeg_checkset(EEG);

        % init设置名字和保存
        % init_output_file = fullfile(file_output_path, 'init.set');
        % EEG = pop_saveset(EEG, 'filename', init_output_file);

        %% import event from data channel
        % Extract events from channel 66 using default settings
        EEG = pop_chanevent(EEG, 66, ...
            'edge', 'trailing', ... % Detect the rising edge (up transition)
            'delchan', 'on', ...   % Delete the event channel after extraction
            'delevent', 'on');     % Delete old events if any
        
        % Redraw EEGLAB to reflect changes
        % eeglab redraw;

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
        % EEG = eeg_checkset(EEG);
        
        % 保存此次处理结果为event_check.set
        % event_check_output_file = fullfile(file_output_path, 'event_check.set');
        % EEG = pop_saveset(EEG, 'filename', event_check_output_file);
        
        % Refresh EEGLAB GUI
        % eeglab redraw;

        %% channel location
        % add channel location
        % ced_file_path = '/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0/sample_locs/V3Standard-10-20-Cap81.ced';
        % EEG = pop_chanedit(EEG, 'lookup',ced_file_path);
        load('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0/chanlocs.mat');
        EEG.chanlocs = chanlocs;


        % delete bad/selected channel
        % 定义要删除的通道名称
        badChannels = {'UNI 13', 'UNI 14', 'UNI 15', 'UNI 21', 'UNI 22', 'UNI 23', 'UNI 24', 'UNI 29', 'UNI 30', 'UNI 31', 'UNI 32', 'TRIGGERS', 'STATUS', 'COUNTER'};

        % 获取所有通道名称
        allChannels = {EEG.chanlocs.labels}; % 确保 allChannels 是单元格数组

        % 找出要保留的通道索引
        keepIdx = ~ismember(allChannels, badChannels);
        keepChannels = allChannels(keepIdx);

        % 更新EEG数据结构体中的通道信息
        EEG = pop_select(EEG, 'channel', keepChannels);

        % 获取并打印剩余的通道名称
        remainingChannels = {EEG.chanlocs.labels};
        disp('Remaining channels after deletion:');
        disp(remainingChannels);

        % 保存处理后的数据
        % channel_loc_output_file = fullfile(file_output_path, 'channel_loc.set');
        % EEG = pop_saveset(EEG, 'filename', channel_loc_output_file);
        
        % eeglab redraw;

        %% filter
        % 高通滤波 0.1 Hz
        % EEG = pop_eegfiltnew(EEG, 0.1, []);  
        
        % 低通滤波 180 Hz
        % EEG = pop_eegfiltnew(EEG, [], 180);  
        EEG = pop_eegfiltnew(EEG, 0.1, 180, []);
        
        % Notch 滤波 58-65 Hz
        EEG = pop_eegfiltnew(EEG, 58, 65, [], 1);  
        
        % EEG = eeg_checkset(EEG);

        % 保存滤波后的数据为filter.set
        filter_output_file = fullfile(file_output_path, 'filter.set');
        EEG = pop_saveset(EEG, 'filename', filter_output_file);

        %% Remove Bad Segments
        % load('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0/rejectionIntervals.mat')
        % [~, filename, ~] = fileparts(file_path);
        % eval(['reject_points = rejectionIntervals.', subjects{i}, '.', filename, ';']);
        % EEG = eeg_eegrej(EEG, reject_points);
        load('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0/rejectionIntervals.mat')

        subj = subjects{i};
        sess = filename;
        
        % 先检查 subject 是否存在
        if isfield(rejectionIntervals, subj)
            subjStruct = rejectionIntervals.(subj);
            
            % 检查 subjStruct 是否为结构数组
            if isstruct(subjStruct)
                % 结构数组或单个结构
                if numel(subjStruct) == 1
                    % 单个结构，直接检查字段
                    if isfield(subjStruct, sess)
                        reject_points = subjStruct.(sess);
                        EEG = eeg_eegrej(EEG, reject_points);
                    else
                        disp(fieldnames(subjStruct));
                        warning('Subject存在，但session "%s" 不存在！', sess);
                    end
                else
                    % 如果是结构数组，则遍历检查
                    found = false;
                    for k = 1:numel(subjStruct)
                        if isfield(subjStruct(k), sess)
                            reject_points = subjStruct(k).(sess);
                            EEG = eeg_eegrej(EEG, reject_points);
                            found = true;
                            break;
                        end
                    end
                    if ~found
                        disp(fieldnames(subjStruct(1)));
                        warning('Subject结构数组存在，但未找到session "%s"!', sess);
                    end
                end
                
            else
                warning('Subj字段存在但不是结构体！请检查.mat文件结构！');
            end
            
        else
            disp(fieldnames(rejectionIntervals));
            warning('不存在名为 "%s" 的subject!', subj);
        end

        %%

        % === 2. 重新参考（平均参考）===
        EEG = pop_reref(EEG, []);

        % === 3. ICA 分解 + ICLabel ===
        EEG = pop_runica(EEG, 'icatype', 'runica', 'pca', 35, 'extended', 1, 'rndreset', 'yes');
        EEG = iclabel(EEG);

        % === 保存一版未剔除 ICA 的版本 ===
        unpruned_set_path = fullfile(file_output_path, 'ica_unpruned.set');
        pop_saveset(EEG, 'filename', 'ica_unpruned.set', 'filepath', file_output_path);
        save(fullfile(file_output_path, 'ica_unpruned.mat'), 'EEG');
        fprintf("已保存未剔除 ICA 成分版本: %s\n", unpruned_set_path);

        % === 4. 自动去除 artifact 成分 ===
        IC_Val = EEG.etc.ic_classification.ICLabel.classifications;
        IC_Val_Trunc = IC_Val(:, 1:5) ./ sum(IC_Val(:, 1:5), 2);
        Cond1 = (IC_Val(:, 6) ~= max(IC_Val, [], 2));
        Cond2 = IC_Val_Trunc(:, 1) >= 0.5;
        Cond_T = ~and(Cond1, Cond2);
        Cond_T_idx = find(Cond_T);
        % 
        fprintf('[%s/%s] ICs marked for removal: %d of %d\n', ...
            subjects{i}, filename, length(Cond_T_idx), size(EEG.icawinv, 2));
        % 
        if isempty(Cond_T_idx) || length(Cond_T_idx) == size(EEG.icawinv, 2)
            warning('⚠️ No ICs left to retain or all components marked. Skipping pop_subcomp.');
        else
            EEG = pop_subcomp(EEG, Cond_T_idx, 0);
        end

        % === 5. 保存 final.set 和 final.mat ===
        final_set_path = fullfile(file_output_path, 'final.set');
        EEG = pop_saveset(EEG, 'filename', 'final.set', 'filepath', file_output_path);
        
        mat_file_path = fullfile(file_output_path, 'final.mat');
        save(mat_file_path, 'EEG');

        fprintf('已保存: %s\n', mat_file_path);

    end
end   

% eeglab quit;
% 结束进程提示
disp('EEG data processing completed.'); 

eeglab redraw;
eeglab close;

