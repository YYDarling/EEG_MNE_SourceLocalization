import mne
import numpy as np

def create_eeg_info():
    """
    创建 EEG 信息对象，包括通道名称、采样频率和通道类型，并设置电极蒙太奇。

    Returns:
        mne.Info: EEG 信息对象。
    """
    ch_names = ['Cz', 'O1', 'P1', 'CP1', 'C1', 'FC1', 'F1', 'Fp1',
                'CPz', 'PO3', 'P3', 'CP3', 'C3', 'FC3', 'F3', 'AF3',
                'Pz', 'PO7', 'P5', 'CP5', 'C5', 'FC5', 'F5', 'AF7',
                'POz', 'Iz', 'P7', 'TP7', 'T7', 'FT7', 'F7', 'TP9',
                'Fpz', 'O2', 'P2', 'CP2', 'C2', 'FC2', 'F2', 'Fp2',
                'AFz', 'PO4', 'P4', 'CP4', 'C4', 'FC4', 'F4', 'AF4',
                'Fz', 'PO8', 'P6', 'CP6', 'C6', 'FC6', 'F6', 'AF8',
                'FCz', 'Oz', 'P8', 'TP8', 'T8', 'FT8', 'F8', 'TP10',
                'STI 1']
    sfreq = 4096
    ch_types = ['eeg'] * 64 + ['stim']
    info = mne.create_info(ch_names, sfreq, ch_types)
    easycap_montage = mne.channels.make_standard_montage("easycap-M1")
    info.set_montage(easycap_montage)
    return info

def perform_coregistration(info, subject, subjects_dir):
    """
    执行配准操作，包括基准点拟合和迭代最近点（ICP）算法。

    Args:
        info (mne.Info): EEG 信息对象。
        subject (str): 被试名称。
        subjects_dir (str): 被试数据目录。

    Returns:
        mne.coreg.Coregistration: 配准对象。
    """
    plot_kwargs = dict(
        subject=subject,
        subjects_dir=subjects_dir,
        surfaces=['head', 'outer_skull', 'white'],
        eeg=['original', 'projected'],
        dig=True,
        coord_frame="mri",
        show_axes=True,
    )
    fiducials = "estimated"  # get fiducials from fsaverage
    coreg = mne.coreg.Coregistration(info, subject, subjects_dir, fiducials=fiducials)

    # 可视化初始配准
    fig = mne.viz.plot_alignment(info, trans=coreg.trans, **plot_kwargs)

    # 基准点拟合
    coreg.fit_fiducials(verbose=True)
    fig = mne.viz.plot_alignment(info, trans=coreg.trans, **plot_kwargs)

    # 第一次 ICP 拟合
    coreg.fit_icp(n_iterations=6, nasion_weight=2.0, verbose=True)
    fig = mne.viz.plot_alignment(info, trans=coreg.trans, **plot_kwargs)

    view_kwargs = dict(azimuth=45, elevation=90, distance=0.6, focalpoint=(0.0, 0.0, 0.0))

    # 第二次 ICP 拟合
    coreg.fit_icp(n_iterations=20, nasion_weight=10.0, verbose=True)
    fig = mne.viz.plot_alignment(info, trans=coreg.trans, **plot_kwargs)
    mne.viz.set_3d_view(fig, **view_kwargs)

    return coreg

def save_trans_and_bem(coreg, subject, subjects_dir):
    """
    保存配准的转换矩阵和 BEM 解决方案。

    Args:
        coreg (mne.coreg.Coregistration): 配准对象。
        subject (str): 被试名称。
        subjects_dir (str): 被试数据目录。
    """
    try:
        trans_path = f'{subjects_dir}/{subject}/{subject}-trans.fif'
        mne.write_trans(trans_path, coreg.trans, overwrite=True)
        print(f"转换矩阵已保存到 {trans_path}")

        conductivity = (0.3, 0.006, 0.3)  # for three layers
        model = mne.make_bem_model(
            subject=subject, ico=4, conductivity=conductivity, subjects_dir=subjects_dir
        )
        bem = mne.make_bem_solution(model)
        bem_path = f'{subjects_dir}/{subject}/{subject}-bem.fif'
        mne.write_bem_solution(bem_path, bem, overwrite=True)
        print(f"BEM 解决方案已保存到 {bem_path}")
    except Exception as e:
        print(f"保存文件时出现错误: {e}")

def main():
    """
    主函数，调用上述函数完成整个流程。
    """
    subjects_dir = '/home/hosseinpc/Desktop/FreeSurfer2/freesurfer/subjects'
    subject = "fsaverage"

    # 创建 EEG 信息
    info = create_eeg_info()

    # 执行配准
    coreg = perform_coregistration(info, subject, subjects_dir)

    # 保存转换矩阵和 BEM 解决方案
    save_trans_and_bem(coreg, subject, subjects_dir)

    input("Press Enter to continue...")

if __name__ == "__main__":
    main()
