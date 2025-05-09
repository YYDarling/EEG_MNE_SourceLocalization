from pathlib import Path
import mne
from mne.minimum_norm import apply_inverse, make_inverse_operator
# from joblib import Parallel, delayed
import numpy as np
from scipy.io import savemat
# import matplotlib
# matplotlib.use('Agg')  # 可选：禁止窗口弹出

import nibabel as nib
from collections import Counter

def check_thalamic_labels(mgz_path):
    """
    检查 ThalamicNuclei segmentation 中的标签 ID 以及出现频次。
    适用于 FreeSurfer 生成的 ThalamicNuclei.v13.T1.mgz
    """
    print(f"🧠 读取 MRI 文件: {mgz_path}")
    img = nib.load(mgz_path)
    data = img.get_fdata()

    unique_vals, counts = np.unique(data, return_counts=True)
    label_counter = Counter(dict(zip(unique_vals.astype(int), counts)))

    print("📌 MRI 中出现的 label ID 及其体素数量：")
    for label, count in label_counter.items():
        print(f"  Label ID {label}: {count} voxels")

    return label_counter



# input path
subjects_dir = Path("/Users/duyun530/PycharmProjects/mne/subjects")
subject = "sub125"

data_root = Path("/Users/duyun530/PycharmProjects/mne/data_pre_loc")
pre_loc_data_subject = "Sub125_Sham_h"
session_root = data_root / pre_loc_data_subject

# output path
final_output_root = Path("/Users/duyun530/PycharmProjects/mne/final_output_LVPL") / pre_loc_data_subject
final_output_root.mkdir(parents=True, exist_ok=True)

# parameter configure
fname_trans = str(subjects_dir / subject / f"{subject}-trans.fif")
fname_bem = str(subjects_dir / subject / f"{subject}-bem.fif")
fname_aseg = subjects_dir / subject / "mri"  / "ThalamicNuclei.v13.T1.mgz"
check_thalamic_labels(fname_aseg)

labels_vol = {"Left-VPL":8133}






def compute_forward(subject, subjects_dir, raw, fname_trans, fname_aseg, fname_bem):
    """构建 surface + volume 源空间并返回 forward 解和 forward_src"""
    # 读取 BEM 模型
    bem = mne.read_bem_solution(fname_bem, verbose=False)

    # 构建皮层源空间（standard surface）
    surface_src = mne.setup_source_space(
        subject, spacing="oct6", add_dist="patch",
        subjects_dir=subjects_dir, verbose=False
    )

    # 加入体积源空间（例如丘脑）
    volume_src = mne.setup_volume_source_space(
        subject,
        mri=fname_aseg,
        bem=bem,
        volume_label=labels_vol,  # 或多个 label，例如 ["Left-VPL", "Right-VPL"]
        subjects_dir=subjects_dir,
        add_interpolator=True,
        verbose=False
        # n_jobs = 1,
    )

    # 合并 surface + volume 为 forward_src
    forward_src = surface_src + volume_src

    # 创建 forward 解
    fwd = mne.make_forward_solution(
        raw.info,
        trans=fname_trans,
        src=forward_src,
        bem=fname_bem,
        eeg=True,
        meg=False,
        mindist=5.0,
        verbose=False
        # n_jobs=1
    )
    print("📌 forward_src['src'] 类型:", type(forward_src))
    print("📌 forward_src['src'] 内容预览:", forward_src)
    return fwd, forward_src


def compute_inverse(evoked, fwd, noise_cov, snr=3.0, method='dSPM'):
    """计算适用于 hybrid source space 的逆解"""

    # 创建 inverse operator
    inverse_operator = make_inverse_operator(
        evoked.info, fwd, noise_cov,
        depth=None,
        loose=dict(surface=0.2, volume=1.0),
        verbose=False
    )

    # 应用 inverse 解
    stc = apply_inverse(
        evoked, inverse_operator,
        lambda2=1.0 / snr ** 2,
        method=method,
        pick_ori=None,
        verbose=False
    )

    if stc is None:
        raise RuntimeError("❌ apply_inverse() 返回 None，可能是数据维度不匹配或无有效信号")

    # 获取 inverse 解使用的 source space
    inverse_src = inverse_operator['src']

    if inverse_operator is None or 'src' not in inverse_operator:
        raise RuntimeError("❌ 无法从 inverse_operator 中提取 src")

    # ✅ 关键检查
    if inverse_src is None:
        raise RuntimeError("❌ inverse_operator['src'] 是 None，不能继续！")
    if not isinstance(inverse_src, mne.SourceSpaces):
        raise TypeError(f"❌ inverse_src 类型错误，应为 SourceSpaces，但得到 {type(inverse_src)}")

    print("📌 inverse_operator['src'] 类型:", type(inverse_src))
    print("📌 inverse_operator['src'] 内容预览:", inverse_src)


    return stc, inverse_src


def extract_left_vpl_timeseries_manual(stc, src, mode='voxel'):
    for i, s in enumerate(src):
        src_type = s['type']
        seg_name = s.get('seg_name', 'N/A')
        n_used = len(s['vertno'])
        print(f"  ▶ Index {i}: type = {src_type}, seg_name = {seg_name}, n_used = {n_used}")

    # 查找 volume source 空间中 seg_name 为 Left-VPL 的那块
    volume_src = [s for s in src if s['type'] == 'vol' and s.get('seg_name') == 'Left-VPL']
    if not volume_src:
        raise ValueError("❌ 未在 source space 中找到 'Left-VPL' volume label")

    vol = volume_src[0]
    vert_indices = vol['vertno']
    print(f"🔍 找到 'Left-VPL' volume 区域，包含 {len(vert_indices)} 个体素点")

    # MixedSourceEstimate 的 data 顺序是 surface + volume
    n_surf = sum(len(s['vertno']) for s in src if s['type'] == 'surf')
    volume_data = stc.data[n_surf:, :]
    assert volume_data.shape[0] == len(vert_indices), "❌ volume 点数不匹配"

    if mode == 'voxel':
        return volume_data  # 所有体素
    elif mode == 'mean':
        return volume_data.mean(axis=0)  # 平均体素值
    else:
        raise ValueError(f"❌ 不支持的 mode: {mode}，请使用 'mean' 或 'voxel'")

def extract_cortex_voxelwise(stc, src):
    cortex_src = [s for s in src if s['type'] == 'surf']
    n_cortex_pts = sum(len(s['vertno']) for s in cortex_src)
    return stc.data[:n_cortex_pts, :]

# def extract_left_vpl_voxelwise(stc, src):
#     volume_src = [s for s in src if s['type'] == 'vol' and s.get('seg_name') == 'Left-VPL']
#     if not volume_src:
#         raise ValueError("未找到 Left-VPL volume 区域")
#     n_surf = sum(len(s['vertno']) for s in src if s['type'] == 'surf')
#     return stc.data[n_surf:, :]

def extract_mixed_voxelwise(stc, src):
    cortex = extract_cortex_voxelwise(stc, src)
    vpl = extract_left_vpl_timeseries_manual(stc, src, mode='voxel')
    return np.vstack([cortex, vpl])

def extract_features_dual(stc, src, evoked, raw, epochs, h_epochs, subject, subjects_dir):
    if src is None:
        raise RuntimeError("❌ extract_features_dual 收到的 src 是 None！")

    # === 1. 检查 src 和 stc 匹配 ===
    if isinstance(stc, mne.MixedSourceEstimate):
        n_src_pts = sum(len(s['vertno']) for s in src)
        print(f"🔍 STC 点数: {stc.data.shape[0]}, SRC 总点数: {n_src_pts}")
        if stc.data.shape[0] != n_src_pts:
            raise ValueError(f"❌ src 与 stc 不匹配：src 总点数 = {n_src_pts}，但 stc.shape[0] = {stc.data.shape[0]}")

    # === 2. 获取皮层标签 ===
    labels_parc = mne.read_labels_from_annot(
        subject, parc='aparc', subjects_dir=subjects_dir, verbose=False
    )
    label_ts = mne.extract_label_time_course(
        [stc], labels_parc, src, mode="mean", allow_empty=True, verbose=False
    )
    label_ts_filtered = label_ts[0]
    label_names = [lbl.name for lbl in labels_parc]

    # === 3. Left-VPL 标签时间序列 Mixed ===
    left_vpl_ts = extract_left_vpl_timeseries_manual(stc, src)
    print("✅ extract_left_vpl_timeseries 成功返回")

    # === ⚠️ 修正 label_ts 和 label_names 不一致问题 ===
    if label_ts_filtered.shape[0] != len(label_names):
        print(f"⚠️ label_ts 行数: {label_ts_filtered.shape[0]} 与 label_names 数量: {len(label_names)} 不一致，正在修正...")
        min_len = min(label_ts_filtered.shape[0], len(label_names))
        label_ts_filtered = label_ts_filtered[:min_len, :]
        label_names = label_names[:min_len]

    # mixed label = 大脑皮层 + Left-VPL
    label_ts_mixed = np.vstack([label_ts_filtered, left_vpl_ts])
    label_names_mixed = label_names + ["Left-VPL"]

    # === 4. 仅 Left-VPL 特征 ===
    label_ts_vpl = left_vpl_ts[None, :]  # shape: (1, n_times)
    label_names_vpl = ["Left-VPL"]

    # === 5. PSD ===
    def _compute_psd(data): return data.compute_psd(fmax=100, verbose=False).get_data(return_freqs=True)
    psd_raw, frq_raw = _compute_psd(raw)
    psd_epochs, frq_epochs = _compute_psd(epochs)
    psd_h, frq_h = _compute_psd(h_epochs)
    psd_evoked, frq_evoked = _compute_psd(evoked)

    common_psd = {
        'raw': (psd_raw, frq_raw),
        'epochs': (psd_epochs, frq_epochs),
        'h_epochs': (psd_h, frq_h),
        'evoked': (psd_evoked, frq_evoked),
    }

    features_mixed = {
        'label_ts': label_ts_mixed,
        'label_names': label_names_mixed,
        'times': 1e3 * stc.times,
        'psd': common_psd,
    }
    features_vpl = {
        'label_ts': label_ts_vpl,
        'label_names': label_names_vpl,
        'times': 1e3 * stc.times,
        'psd': common_psd,
    }

    return features_mixed, features_vpl

# def save_voxelwise_features(voxel_data, times, label_prefix, output_path):
#     savemat(output_path.with_suffix(".mat"), {
#         f'{label_prefix}_ts': voxel_data,
#         'times': 1e3 * times
#     })
#     np.savez(output_path.with_suffix(".npz"), **{
#         f'{label_prefix}_ts': voxel_data,
#         'times': 1e3 * times
#     })
#     print(f"✅ {label_prefix} voxel-wise 特征已保存至: {output_path}")

# def save_features(features, output_path, meta=None):
#     """
#     保存 features 为 .npz 和 .mat 文件，文件名由 output_path 指定（不含扩展名）
#     e.g. output_path = Path(".../mixed_features")
#     """
#     output_path.parent.mkdir(parents=True, exist_ok=True)
#
#     save_data = {
#         'label_ts': features['label_ts'],
#         'label_names': features['label_names'],
#         'times': features['times'],
#     }
#
#     for key, (psd, freqs) in features['psd'].items():
#         save_data[f'psd_{key}'] = psd
#         save_data[f'freqs_{key}'] = freqs
#
#     if isinstance(meta, dict):
#         for k, v in meta.items():
#             save_data[f'meta_{k}'] = v
#
#     # 保存 .npz
#     npz_path = output_path.with_suffix(".npz")
#     np.savez(npz_path, **save_data)
#     print(f"✅ npz特征已保存至: {npz_path}")
#
#     # 保存 .mat
#     mat_path = output_path.with_suffix(".mat")
#     mat_data = save_data.copy()
#     mat_data['label_names'] = np.array(mat_data['label_names'], dtype=object)
#     savemat(mat_path, mat_data)
#     print(f"✅ mat特征已保存至: {mat_path}")

def save_voxelwise_features(voxel_data, times, label_prefix, output_path, meta=None):
    """
    保存 voxel-wise 特征为 .mat 和 .npz 文件，并返回 feature 字典
    - voxel_data: shape = (n_voxels, n_times)
    - times:      shape = (n_times,)
    - label_prefix: str, e.g. 'left_vpl', 'cortex', 'mixed'
    - output_path: Path object, 不含扩展名
    - meta: dict，可选，附加 metadata
    """
    features = {
        'label_ts': voxel_data,
        'label_names': [f"{label_prefix}_{i}" for i in range(voxel_data.shape[0])],
        'times': 1e3 * times  # 转为毫秒
    }

    if isinstance(meta, dict):
        for k, v in meta.items():
            features[f'meta_{k}'] = v

    # 保存为 .mat
    mat_path = output_path.with_suffix(".mat")
    mat_data = features.copy()
    mat_data['label_names'] = np.array(mat_data['label_names'], dtype=object)
    savemat(mat_path, mat_data)
    print(f"✅ mat 特征已保存至: {mat_path}")

    # 保存为 .npz
    npz_path = output_path.with_suffix(".npz")
    np.savez(npz_path, **features)
    print(f"✅ npz 特征已保存至: {npz_path}")

    return features




# ====== main ======
for session_dir in session_root.iterdir():
    if not session_dir.is_dir():
        continue

    print(f"\n🔍 处理 session: {session_dir.name}")

    # try:
    raw_path = session_dir / "raw_with_stim.fif"
    evoked_path = session_dir / "evoked_ave.fif"
    cov_path = session_dir / "noise_cov.fif"
    epochs_path = session_dir / "epochs_epo.fif"

    # === 1. 读取数据 ===
    raw = mne.io.read_raw_fif(raw_path, preload=True)
    raw.set_eeg_reference(projection=True)

    evoked = mne.read_evokeds(evoked_path, condition=0, baseline=(None, 0))
    evoked.set_eeg_reference(projection=True)
    evoked.apply_proj()

    cov = mne.read_cov(cov_path)
    epochs = mne.read_epochs(epochs_path, preload=True)
    epochs.set_eeg_reference(projection=True)
    epochs.apply_proj()  # ✅ 推荐也加上，保持一致性
    h_epochs = epochs["HandStim"] if "HandStim" in epochs.event_id else epochs

    # === 2. 使用你的函数构建 forward 解（包含 MRI）===
    fwd, forward_src = compute_forward(
        subject=subject,
        subjects_dir=str(subjects_dir),
        raw=raw,
        fname_trans=str(fname_trans),
        fname_aseg=str(fname_aseg),
        fname_bem=str(fname_bem)
    )
    print("✅ Forward 解（含 MRI）已完成")

    # === 3. 创建 inverse operator 并计算源定位 ===
    stc, inverse_src_= compute_inverse(
        evoked=evoked,
        fwd=fwd,
        noise_cov=cov,
        snr=3.0,
        method='dSPM'
    )
    # ✅ 打印调试信息
    print("✅ Inverse 解完成")

    print("📌 inverse_src 类型:", type(inverse_src_))
    print("📌 inverse_src 是否 None:", inverse_src_ is None)
    print("📌 stc 类型:", type(stc))
    print("📌 stc shape:", stc.data.shape)

    if inverse_src_ is None:
        raise RuntimeError("❌ inverse_src 是 None，无法用于 extract_features。")
    if not isinstance(inverse_src_, mne.SourceSpaces):
        raise TypeError(f"❌ inverse_src 类型错误，应为 SourceSpaces，但得到 {type(inverse_src_)}")

    print("🚨 调用 extract_features_dual 前 inverse_src 类型:", type(inverse_src_))
    assert inverse_src_ is not None, "❌ inverse_src 是 None，不能传给 extract_features_dual"

    # === 4. 设置每个 session 的输出目录 ===
    session_output = final_output_root / session_dir.name
    session_output.mkdir(parents=True, exist_ok=True)

    # === 5. stc file ===
    stc_path = session_output / "stc"
    stc.save(str(stc_path), overwrite=True)

    # === 6. stc png ===
    try:
        brain = stc.plot(subject=subject, subjects_dir=str(subjects_dir),
                         initial_time=stc.get_peak()[1], time_unit="s",
                         size=(800, 600),surface='pial',src=inverse_src_)
        fig_path = session_output / "stc.png"
        brain.save_image(str(fig_path))
        brain.close()
    except Exception as e:
        print(f"⚠️ stc 可视化失败: {e}")



    # # === 7.save mat & npz ===
    #
    # print("🚨 调用 extract_features_dual 前 inverse_src 类型:", type(inverse_src_))
    # # === 🔍 保存 Left-VPL 所有体素的时序数据（voxel-wise） ===
    # print("💾 正在提取并保存 Left-VPL voxel-wise 时序数据...")
    # left_vpl_voxel_ts = extract_left_vpl_timeseries_manual(stc, inverse_src_,
    #                                                        mode='voxel')  # shape: (n_voxels, n_times)
    # print(f"📐 left_vpl_voxel_ts shape: {left_vpl_voxel_ts.shape}")
    # voxel_ts_output_path = session_output / "left_vpl_voxels.mat"
    # savemat(str(voxel_ts_output_path), {
    #     'left_vpl_voxel_ts': left_vpl_voxel_ts,
    #     'times': 1e3 * stc.times  # 毫秒单位
    # })
    # print(f"✅ voxel-wise 时序数据已保存至: {voxel_ts_output_path}")

    # === 🔍 保存 Left-VPL voxel-wise ===
    print("💾 正在提取并保存 Left-VPL voxel-wise 时序数据...")
    left_vpl_voxel_ts = extract_left_vpl_timeseries_manual(stc, inverse_src_, mode='voxel')
    print(f"📐 left_vpl_voxel_ts shape: {left_vpl_voxel_ts.shape}")
    features_vpl = save_voxelwise_features(left_vpl_voxel_ts, stc.times, 'left_vpl',
                                           session_output / "left_vpl_features", meta={
            'type': 'left_vpl_only', 'subject': subject, 'session': session_dir.name
        })

    # === 🔍 保存 Cortex voxel-wise ===
    print("💾 正在提取并保存Cortex voxel-wise 时序数据...")
    n_cortex_pts = sum(len(s['vertno']) for s in inverse_src_ if s['type'] == 'surf')
    cortex_voxel_ts = stc.data[:n_cortex_pts, :]
    print(f"📐 cortex_voxel_ts shape: {cortex_voxel_ts.shape}")
    features_cortex = save_voxelwise_features(cortex_voxel_ts, stc.times, 'cortex', session_output / "cortex_features",
                                              meta={
                                                  'type': 'cortex_only', 'subject': subject, 'session': session_dir.name
                                              })

    # === 🔍 保存 Mixed voxel-wise ===
    print("💾 正在提取并保存 Mixed voxel-wise 时序数据...")
    mixed_voxel_ts = np.vstack([cortex_voxel_ts, left_vpl_voxel_ts])
    print(f"📐 mixed_voxel_ts shape: {mixed_voxel_ts.shape}")
    features_mixed = save_voxelwise_features(mixed_voxel_ts, stc.times, 'mixed', session_output / "mixed_features",
                                             meta={
                                                 'type': 'mixed', 'subject': subject, 'session': session_dir.name
                                             })












