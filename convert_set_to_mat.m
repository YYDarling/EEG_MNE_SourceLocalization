%% convert .set to .mat
clear;
clc;
close all;

% 定义输出的基础路径（原始 .set 文件所在的文件夹）
output_base_path = '/Users/duyun530/Documents/MATLAB/eeg_data_clean/output_data';

% 定义需要处理的受试者
subjects = {'Sub143_Active','Sub101_Active'}; % 可以添加更多 subject

% 要加载的 .set 文件名称
set_filename = 'label.set';

% 遍历每个 subject
for i = 1:length(subjects)
    subject_output_path = fullfile(output_base_path, subjects{i});

    % 获取该 subject 目录下的所有 session 文件夹（即 .poly5 同名文件夹）
    session_dirs = dir(subject_output_path);
    session_dirs = session_dirs([session_dirs.isdir] & ~startsWith({session_dirs.name}, '.'));

    for j = 1:length(session_dirs)
        session_name = session_dirs(j).name;
        session_path = fullfile(subject_output_path, session_name);

        % 目标 .set 文件的路径
        set_file_path = fullfile(session_path, set_filename);

        % 检查该文件是否存在
        if exist(set_file_path, 'file')
            fprintf('Loading: %s\n', set_file_path);
            EEG = pop_loadset('filename', set_file_path);

            % 保存为 .mat 文件
            mat_file_path = fullfile(session_path, 'final.mat');
            save(mat_file_path,'EEG');
            fprintf('Saved to: %s\n', mat_file_path);
        else
            fprintf('File not found: %s\n', set_file_path);
        end
    end
end

disp('All .set files converted to .mat.');
