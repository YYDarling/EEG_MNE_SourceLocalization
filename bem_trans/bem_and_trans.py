import os

import mne
import nibabel as nib
import numpy as np
# from scipy import linalg
# from mne.io.constants import FIFF
from mne.coreg import Coregistration

# 定义公共变量
subjects_dir = '/Users/duyun530/PycharmProjects/mne/subjects'
subject = "sub101"
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


# 创建 EEG 信息对象
def create_eeg_info():
    try:
        info = mne.create_info(ch_names, sfreq, ch_types)
        easycap_montage = mne.channels.make_standard_montage("easycap-M1")
        info.set_montage(easycap_montage)
        return info
    except Exception as e:
        print(f"创建 EEG 信息对象时出错: {e}")
        return None

# 可视化大脑表面
def visualize_brain_surface():
    try:
        # 创建 brain_surface_pic 文件夹
        pic_dir = os.path.join(subjects_dir, subject, "brain_surface_pic")
        os.makedirs(pic_dir, exist_ok=True)

        Brain = mne.viz.get_brain_class()
        brain = Brain(
            subject=subject,
            hemi="split", #半球显示模式，这里是左右半球分开显示
            surf="pial",  # 显示的脑表面类型，pial 表示软脑膜表面
            subjects_dir=subjects_dir,
            size=(800, 600)
        )
        brain.add_annotation("aparc.a2009s", borders=False)

        # 保存脑表面截图（右侧+俯视）
        brain.save_image(os.path.join(pic_dir, "brain_surface_view1.png"))

        # 设置角度再保存另一视图（左侧+仰视）
        brain.show_view(azimuth=180, elevation=180)
        brain.save_image(os.path.join(pic_dir, "brain_surface_view2.png"))

    except Exception as e:
        print(f"可视化大脑表面时出错: {e}")

# 加载和处理 T1 加权图像
def process_t1w_image():
    try:
        t1w = nib.load(f'{subjects_dir}/{subject}/mri/T1.mgz')
        t1w = nib.Nifti1Image(t1w.dataobj, t1w.affine)
        t1w.header["xyzt_units"] = np.array(10, dtype="uint8")
        t1_mgh = nib.MGHImage(t1w.dataobj, t1w.affine)
        return t1_mgh
    except FileNotFoundError:
        print(f"未找到 T1 加权图像文件: {subjects_dir}/{subject}/mri/T1.mgz")
    except Exception as e:
        print(f"处理 T1 加权图像时出错: {e}")
    return None

# 创建 BEM 模型并可视化
def create_and_visualize_bem():
    try:
        # 创建 bem_pic 文件夹
        pic_dir = os.path.join(subjects_dir, subject, "bem_pic")
        os.makedirs(pic_dir, exist_ok=True)

        # 创建 watershed BEM 模型（只会在第一次运行时生成）
        mne.bem.make_watershed_bem(subject=subject, subjects_dir=subjects_dir)

        plot_bem_kwargs = dict(
            subject=subject,
            subjects_dir=subjects_dir,
            brain_surfaces="white",
            orientation="coronal",
            slices=[50, 100, 150, 200],
        )

        fig = mne.viz.plot_bem(**plot_bem_kwargs)

        # 保存 BEM 可视化图
        fig.savefig(os.path.join(pic_dir, "bem_layers.png"), dpi=300, bbox_inches='tight')

    except Exception as e:
        print(f"创建和可视化 BEM 模型时出错: {e}")

# 进行配准操作
def perform_coregistration(info):
    """
    进行配准操作，包括基准点拟合和迭代最近点（ICP）算法。

    参数:
        info (mne.Info): EEG 信息对象。

    返回:
        mne.coreg.Coregistration: 配准对象。
    """
    if info is None:
        print("由于 EEG 信息对象为空，无法进行配准操作。")
        return None
    try:
        # 创建 pic 文件夹
        pic_dir = os.path.join(subjects_dir, subject, "coregistration_pic")
        os.makedirs(pic_dir, exist_ok=True)

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
        coreg = Coregistration(info, subject, subjects_dir, fiducials=fiducials)

        # 初始配准
        fig = mne.viz.plot_alignment(info, trans=coreg.trans, **plot_kwargs)
        fig.plotter.screenshot(os.path.join(pic_dir, "coreg_initial.png"))

        # 拟合 fiducials 后
        coreg.fit_fiducials(verbose=True)
        fig = mne.viz.plot_alignment(info, trans=coreg.trans, **plot_kwargs)
        fig.plotter.screenshot(os.path.join(pic_dir, "coreg_after_fiducials.png"))

        # 第一次 ICP 拟合
        coreg.fit_icp(n_iterations=6, nasion_weight=2.0, verbose=True)
        fig = mne.viz.plot_alignment(info, trans=coreg.trans, **plot_kwargs)
        fig.plotter.screenshot(os.path.join(pic_dir, "coreg_icp1.png"))

        view_kwargs = dict(azimuth=45, elevation=90, distance=0.6, focalpoint=(0.0, 0.0, 0.0))

        # 第二次 ICP 拟合
        coreg.fit_icp(n_iterations=20, nasion_weight=10.0, verbose=True)
        fig = mne.viz.plot_alignment(info, trans=coreg.trans, **plot_kwargs)
        mne.viz.set_3d_view(fig, **view_kwargs)
        fig.plotter.screenshot(os.path.join(pic_dir, "coreg_icp2_final.png"))

        return coreg
    except Exception as e:
        print(f"配准操作时出错: {e}")
        return None

# 保存转换矩阵和 BEM 解决方案
def save_trans_and_bem(coreg):
    """
    保存配准的转换矩阵和 BEM 解决方案。

    参数:
        coreg (mne.coreg.Coregistration): 配准对象。
    """
    if coreg is None:
        print("由于配准对象为空，无法保存转换矩阵和 BEM 解决方案。")
        return
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
        print(f"保存转换矩阵和 BEM 解决方案时出错: {e}")

def main():
    # 可视化大脑表面
    visualize_brain_surface()

    # 加载和处理 T1 加权图像
    process_t1w_image()

    # 创建并可视化 BEM 模型
    create_and_visualize_bem()

    # 创建 EEG 信息对象
    info = create_eeg_info()

    # 进行配准操作
    coreg = perform_coregistration(info)

    # 保存转换矩阵和 BEM 解决方案
    save_trans_and_bem(coreg)


if __name__ == "__main__":
    main()