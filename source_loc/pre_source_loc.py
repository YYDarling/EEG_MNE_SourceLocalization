# import os
from pathlib import Path
import numpy as np
from scipy.io import loadmat
import mne

# ========== 配置 ==========
mat_base_path = Path('/Users/duyun530/PycharmProjects/mne/data_test_output')
output_base_path = Path('/Users/duyun530/PycharmProjects/mne/data_pre_loc')
subjects = ['Sub125_Sham_h']
mat_filename = 'final.mat'

def pre_source_localization():
    for subject in subjects:
        subject_path = mat_base_path / subject
        output_subject_path = output_base_path / subject

        for session_dir in subject_path.iterdir():
            if session_dir.is_dir() and not session_dir.name.startswith('.'):
                session_name = session_dir.name
                input_mat_path = session_dir / mat_filename
                output_session_path = output_subject_path / session_name

                if not input_mat_path.exists():
                    print(f"跳过不存在的 {input_mat_path}")
                    continue

                try:
                    # === 1. Load .mat file ===
                    mat = loadmat(str(input_mat_path), struct_as_record=False, squeeze_me=True)
                    EEG = mat['EEG']
                    sfreq = float(EEG.srate)
                    data = np.array(EEG.data)
                    n_channels, n_times = data.shape

                    # === 2. Channel names ===
                    ch_names = ['Cz', 'O1', 'P1', 'CP1', 'C1', 'FC1', 'F1', 'Fp1',
                                'CPz', 'PO3', 'P3', 'CP3', 'AF3',
                                'Pz', 'PO7', 'P5', 'CP5',
                                'POz', 'Iz', 'P7', 'TP7',
                                'Fpz', 'O2', 'P2', 'CP2', 'C2', 'FC2', 'F2', 'Fp2',
                                'AFz', 'PO4', 'P4', 'CP4', 'C4', 'FC4', 'F4', 'AF4',
                                'Fz', 'PO8', 'P6', 'CP6', 'C6', 'FC6', 'F6', 'AF8',
                                'FCz', 'Oz', 'P8', 'TP8', 'T8', 'FT8', 'F8', 'TP10']
                    if n_channels != len(ch_names):
                        print(f"⚠️ 通道数不匹配: 数据 {n_channels} vs 名称 {len(ch_names)}，跳过该 session。")
                        continue

                    ch_types = ['eeg'] * n_channels #53


                    # === 3. Construct Raw obeject ===
                    info = mne.create_info(ch_names=ch_names, sfreq=sfreq, ch_types=ch_types)
                    raw = mne.io.RawArray(data * 1e-6, info)
                    raw.info['bads'] = [] # 初始化 bad channels
                    # ✅ 设置 EEG 通道的头壳空间位置
                    raw.set_montage(mne.channels.make_standard_montage("easycap-M1"))

                    # === 4. Epochs ===
                    events = []
                    if hasattr(EEG, 'event'):
                        for ev in EEG.event:
                            # 只保留目标事件 1056
                            if hasattr(ev, 'type') and str(ev.type) == '1056':
                                latency = int(ev.latency)
                                events.append([latency, 0, 1])

                    if len(events) == 0:
                        print(f"⚠️ No events found for {subject}/{session_name}, skipping.")
                        continue

                    # === 5. Construct stim channel ===
                    stim = np.zeros(n_times, dtype=int)
                    for e in events:
                        if 0 <= e[0] <= n_times - 1:
                            stim[e[0]] = e[2]
                    stim_info = mne.create_info(['stim'], sfreq, ['stim'])
                    stim_raw = mne.io.RawArray(stim[np.newaxis, :], stim_info)
                    raw.add_channels([stim_raw]) #54

                    # === 6. Detect events from stim channel ===
                    events_array = mne.find_events(raw, stim_channel='stim')
                    print(f"✅ Found {len(events_array)} events in {subject}/{session_name}")

                    # === 7. Construct Epochs ===
                    epochs = mne.Epochs(raw, events_array, event_id={'HandStim': 1}, tmin=-0.05, tmax=0.1,
                                        preload=True) # event_id already set as 1
                    # === 8. Envoke ===
                    if 'HandStim' in epochs.event_id:
                        evoked = epochs['HandStim'].average()
                    else:
                        print(f"⚠️ No 'HandStim' label found in {subject}/{session_name}, skipping evoked.")
                        continue

                    # === 9. Compute noisy convariance ===
                    noise_cov = mne.compute_covariance(
                        epochs, tmin=None, tmax=0.0,
                        method=['shrunk', 'empirical'],
                        rank=None
                    )

                    # === 10. 保存处理结果 ===
                    output_session_path.mkdir(parents=True, exist_ok=True)

                    # 保存含 stim 的 Raw 数据
                    raw_output_path = output_session_path / 'raw_with_stim.fif'
                    raw.save(str(raw_output_path), overwrite=True)
                    # print(f"💾 Raw saved to: {raw_output_path}")

                    # 保存完整 Epochs 数据（所有 trial）
                    epochs_output_path = output_session_path / 'epochs_epo.fif'
                    epochs.save(str(epochs_output_path), overwrite=True)
                    # print(f"💾 Epochs saved to: {epochs_output_path}")

                    # 保存 Evoked 数据（平均脑响应）
                    evoked_output_path = output_session_path / 'evoked_ave.fif'
                    evoked.save(str(evoked_output_path), overwrite=True)
                    # print(f"💾 Evoked saved to: {evoked_output_path}")

                    # 保存噪声协方差矩阵
                    noise_cov_output_path = output_session_path / 'noise_cov.fif'
                    mne.write_cov(str(noise_cov_output_path), noise_cov)
                    # print(f"💾 Noise covariance saved to: {noise_cov_output_path}")

                except Exception as e:
                    print(f"❌ 处理错误: {input_mat_path}\n原因: {e}")


if __name__ == "__main__":
    pre_source_localization()

