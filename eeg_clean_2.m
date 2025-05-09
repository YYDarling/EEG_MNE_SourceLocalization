clear
clc

% ====== 参数配置 ======
base_path = '/Users/duyun530/Documents/MATLAB/eeg_data_clean/data_test';
subjects = {'Sub101_Active'};

for i = 1:length(subjects)
    subject_path = fullfile(base_path, subjects{i});
    sessions = dir(subject_path);
    sessions = sessions([sessions.isdir] & ~startsWith({sessions.name}, '.'));

    for j = 1:length(sessions)
        session_name = sessions(j).name;
        session_path = fullfile(subject_path, session_name);

        fprintf('🔄 处理 session: %s\n', session_name);

        % === 1. 读取 filter.set 文件 ===
        filter_set_path = fullfile(session_path, 'rejected.set');
        EEG = pop_loadset('filename', 'filter.set', 'filepath', session_path);

        % === 2. 重新参考（平均参考）===
        EEG = pop_reref(EEG, []);

        % === 3. ICA 分解 + ICLabel ===
        EEG = pop_runica(EEG, 'icatype', 'runica', 'pca', 35, 'extended', 1, 'rndreset', 'yes');
        EEG = iclabel(EEG);

        % === 保存一版未剔除 ICA 的版本 ===
        unpruned_set_path = fullfile(session_path, 'ica_unpruned.set');
        pop_saveset(EEG, 'filename', 'ica_unpruned.set', 'filepath', session_path);
        save(fullfile(session_path, 'ica_unpruned.mat'), 'EEG');
        fprintf("💾 已保存未剔除 ICA 成分版本: %s\n", unpruned_set_path);

        % === 4. 自动去除 artifact 成分 ===
        IC_Val = EEG.etc.ic_classification.ICLabel.classifications;
        IC_Val_Trunc = IC_Val(:, 1:5) ./ sum(IC_Val(:, 1:5), 2);
        Cond1 = (IC_Val(:, 6) ~= max(IC_Val, [], 2));
        Cond2 = IC_Val_Trunc(:, 1) >= 0.5;
        Cond_T = ~and(Cond1, Cond2);
        Cond_T_idx = find(Cond_T);
        % 
        fprintf('✅ [%s/%s] ICs marked for removal: %d of %d\n', ...
            subjects{i}, session_name, length(Cond_T_idx), size(EEG.icawinv, 2));
        % 
        if isempty(Cond_T_idx) || length(Cond_T_idx) == size(EEG.icawinv, 2)
            warning('⚠️ No ICs left to retain or all components marked. Skipping pop_subcomp.');
        else
            EEG = pop_subcomp(EEG, Cond_T_idx, 0);
        end

        % === 方法 B: 最大概率类别为 "Brain" 的 ICA ===
        % IC_Val = EEG.etc.ic_classification.ICLabel.classifications;
        
        % 检查分类维度
        % if size(IC_Val, 2) < 7
        %     warning("⚠️ ICLabel 分类结果维度异常，跳过 ICA 剔除步骤");
        % else
        %     % 找出 Brain 类最大概率的 ICA 成分
        %     brain_idx = find(max(IC_Val, [], 2) == 1);
        %     rej_idx = setdiff(1:size(IC_Val, 1), brain_idx);
        % 
        %     fprintf("✅ 方法 B: 保留 %d 个 Brain 类 ICA 成分，剔除 %d 个\n", ...
        %         length(brain_idx), length(rej_idx));
        % 
        %     % 健壮性检查：不能全部剔除
        %     if isempty(rej_idx)
        %         warning("⚠️ 没有成分可剔除，跳过 pop_subcomp");
        %     elseif length(rej_idx) == size(IC_Val, 1)
        %         warning("⚠️ 所有 ICA 成分都被标记为 artifact，跳过 pop_subcomp");
        %     else
        %         try
        %             EEG = pop_subcomp(EEG, rej_idx, 0); % 剔除非脑源 ICA 成分
        %         catch ME
        %             warning("❌ pop_subcomp 执行失败: %s", ME.message);
        %         end
        %     end
        % end

        % === 5. 保存 final.set 和 final.mat ===
        final_set_path = fullfile(session_path, 'final_35.set');
        EEG = pop_saveset(EEG, 'filename', 'final.set', 'filepath', session_path);

        mat_file_path = fullfile(session_path, 'final_35.mat');
        save(mat_file_path, 'EEG');

        fprintf('✅ 已保存: %s\n', mat_file_path);
    end
end

disp('ICA处理流程已完成');
