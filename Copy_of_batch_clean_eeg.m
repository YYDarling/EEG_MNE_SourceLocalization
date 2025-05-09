%% eeg data clean
clear
clc
close all

%%
% 路径
base_path = '/Users/duyun530/Documents/MATLAB/eeg_data_clean/Data/';
output_base_path = '/Users/duyun530/Documents/MATLAB/eeg_data_clean/output_h';
% subjects = {'Sub101_Active', 'Sub125_Sham', 'Sub125_Active', 'Sub143_Active'}; 
% subjects = {'Sub101_Active', 'Sub125_Active', 'Sub143_Active'};
subjects = {'Sub101_Active'};

%%
% load eeglab
if ~exist('eeglab', 'file')
    addpath('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0');
    eeglab;
end

%%
for i = 1:length(subjects)
    % 
    subject_path = fullfile(base_path, subjects{i});
    subject_output_path = fullfile(output_base_path, subjects{i});

    % 
    if ~exist(subject_output_path, 'dir')
        mkdir(subject_output_path);
    end
    
    % 
    poly5_files = dir(fullfile(subject_path, '*.poly5'));
    
    % 
    for j = 1:length(poly5_files)
        %
        file_path = fullfile(subject_path, poly5_files(j).name);
        [~, filename, ~] = fileparts(file_path);
        file_output_path = fullfile(subject_output_path, filename);
        if ~exist(file_output_path, 'dir')
            mkdir(file_output_path);
        end

        %% init
        % Load Data
        EEG = pop_biosig(file_path);
        if isempty(EEG.data)
            error('Failed to load the .poly5 file');
        end

        % Import event from data channel:66
        EEG = pop_chanevent(EEG, 66, 'edge', 'trailing', 'delchan', 'on', 'delevent', 'on'); % Detect the falling edge
        if isempty(EEG.event) || length(EEG.event) < 3
            warning('⚠️ Insufficient events in %s, skipping.', file_path);
            continue;
        end

        % Event Cleaning
        eventTypes = {EEG.event.type}; % Get all event types
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

        % channel location
        load('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0/chanlocs.mat');
        EEG.chanlocs = chanlocs;

        % delete bad/selected channel
        badChannels = {'UNI 13', 'UNI 14', 'UNI 15', 'UNI 21', 'UNI 22', 'UNI 23', 'UNI 24',
               'UNI 29', 'UNI 30', 'UNI 31', 'UNI 32', 'TRIGGERS', 'STATUS', 'COUNTER'};
        allChannels = {EEG.chanlocs.labels}; 
        keepIdx = ~ismember(allChannels, badChannels);
        keepChannels = allChannels(keepIdx);
        EEG = pop_select(EEG, 'channel', keepChannels);

        % print left channel label
        remainingChannels = {EEG.chanlocs.labels};
        disp('Remaining channels after deletion:');
        disp(remainingChannels);

        % filter
        EEG = pop_eegfiltnew(EEG, 0.1, 180, []); % Bandpass 0.1-180Hz
        EEG = pop_eegfiltnew(EEG, 58, 65, [], 1); % Notch 58-65Hz

        % Remove Bad Segments
        % load('/Users/duyun530/Documents/MATLAB/eeg_data_clean/eeglab2025.0.0/rejectionIntervals.mat')
        % eval(['reject_points = rejectionIntervals.', subjects{i}, '.', filename, ';']);
        % EEG = eeg_eegrej(EEG, reject_points);
        try
            eval(['reject_points = rejectionIntervals.', subjects{i}, '.', filename, ';']);
        catch
            warning('⚠️ Cannot find rejection points for %s/%s, skipping artifact removal.', subjects{i}, filename);
            reject_points = [];
        end

        % 如果找到reject_points再进行删除
        if ~isempty(reject_points)
            EEG = eeg_eegrej(EEG, reject_points);
        end

        % Re-reference
        EEG = pop_reref(EEG, []);

        % ICA + ICLabel (PCA = 35)
        EEG = pop_runica(EEG, 'icatype', 'runica', 'pca', 35, 'extended', 1, 'rndreset', 'yes');
        EEG = iclabel(EEG);

        % Auto Reject Bad ICs
        IC_Val = EEG.etc.ic_classification.ICLabel.classifications;
        IC_Val_Trunc = IC_Val(:, 1:5) ./ sum(IC_Val(:, 1:5), 2);
        Cond1 = (IC_Val(:, 6) ~= max(IC_Val, [], 2));
        Cond2 = IC_Val_Trunc(:, 1) >= 0.5;
        Cond_T = ~and(Cond1, Cond2);
        Cond_T_idx = find(Cond_T);

        fprintf('✅ [%s/%s] ICs marked for removal: %d of %d\n', ...
            subjects{i}, filename, length(Cond_T_idx), size(EEG.icawinv,2));

        if isempty(Cond_T_idx) || length(Cond_T_idx) == size(EEG.icawinv, 2)
            warning('⚠️ No ICs left to retain or all components marked. Skipping pop_subcomp.');
        else
            EEG = pop_subcomp(EEG, Cond_T_idx, 0);
        end

        % Save Final .set and .mat
        final_set_path = fullfile(file_output_path, 'final.set');
        EEG = pop_saveset(EEG, 'filename', 'final.set', 'filepath', file_output_path);

        mat_file_path = fullfile(file_output_path, 'final.mat');
        save(mat_file_path, 'EEG');

        fprintf('Successfully processed and saved: %s\n', mat_file_path)

    end
end 

eeglab redraw;
close all;


disp('EEG data processing completed.'); 

