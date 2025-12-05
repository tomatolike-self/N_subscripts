function groups = predefined_case_groups_N_real()
% ========================================================================
% 基于实际目录结构的N杂质算例组配置函数
% 根据N杂质算例完整路径清单.txt (2025-08-25修正版) 创建
% ========================================================================
%
% 返回值：
%   groups - 包含预定义算例组的结构体
%     .fav_BT   - 有利BT方向的4个N浓度子组 (normal方向)
%     .unfav_BT - 不利BT方向的4个N浓度子组 (reversed方向)
%     .combined - 合并组（包含所有8个子组）
%
% 使用方法：
%   groups = predefined_case_groups_N_real();
%   selected_groups = groups.fav_BT;  % 选择有利BT组
%
% 注意：
%   - 基于修正后的81574_D+N目录结构，从117个原始算例中筛选出61个稳态算例
%   - normal方向对应fav BT (30个算例)，reversed方向对应unfav BT (31个算例)
%   - 根据算例名称中的N浓度标识进行分类 (N0.5/N1.0/N1.5/N2.0)
%   - 已去除drift_off、中间态和重复算例，保留稳态收敛算例
%   - 路径已验证并与实际服务器结构对应
% ========================================================================

% 基础路径 - 完整的服务器路径
base_path = '/home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N';

% 初始化输出结构体
groups = struct();

% ========================================================================
% 有利BT方向组 (fav BT) - normal方向算例
% ========================================================================

% N 0.5 浓度组 (有利BT) - 7个算例
groups.fav_BT{1} = {
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_Flux1p15e22_target1_target1');
    fullfile(base_path, '5p5mw_flux_1p0415e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5');
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5_Flux1p08e22_target1_target1');
    fullfile(base_path, '8mw_flux_1p1541e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5');
    fullfile(base_path, '10mw_flux_1p2882e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N0p5');
};

% N 1.0 浓度组 (有利BT) - 8个算例
groups.fav_BT{2} = {
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_Flux1p15e22_target1_target1');
    fullfile(base_path, '5p5mw_flux_1p0415e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1');
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1_Flux1p08e22_target1');
    fullfile(base_path, '8mw_flux_1p1541e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1');
    fullfile(base_path, '10mw_flux_1p2882e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_2');
};

% N 1.5 浓度组 (有利BT) - 8个算例
groups.fav_BT{3} = {
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_Flux1p15e22_N1p5_target1_target1');
    fullfile(base_path, '5p5mw_flux_1p0415e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1_target1');
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1_target1');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1_N1p5_target1_target1');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N1_Flux1p08e22_N1p5_target1_target1');
    fullfile(base_path, '8mw_flux_1p1541e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1_target1');
    fullfile(base_path, '8mw_flux_1p1541e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_N1p5_target1');
    fullfile(base_path, '10mw_flux_1p2882e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N1_2_N1p5_target1_target1');
};

% N 2.0 浓度组 (有利BT) - 7个算例
groups.fav_BT{4} = {
    fullfile(base_path, '5p5mw_flux_1p0415e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2');
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2_Flux1p15e22_target1_target1');
    fullfile(base_path, '6mw_flux_1p0720e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N2');
    fullfile(base_path, '7mw_flux_1p1230e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N2_Flux1p08e22_target1_target1');
    fullfile(base_path, '8mw_flux_1p1541e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2');
    fullfile(base_path, '10mw_flux_1p2882e22', 'baseline_na2.8e19_target1_normal_changeto_N0_changeto_N0_changeto_N2');
};

% ========================================================================
% 不利BT方向组 (unfav BT) - reversed方向算例
% ========================================================================

% N 0.5 浓度组 (不利BT) - 8个算例
groups.unfav_BT{1} = {
    fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_Flux1p26e22_target1_target1');
    fullfile(base_path, '5p5mw_flux_1p1260e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N0p5');
    fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5');
    fullfile(base_path, '7mw_flux_1p2357e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5');
    fullfile(base_path, '8mw_flux_1p2738e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5');
    fullfile(base_path, '7mw_flux_1p2357e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_Flux1p20e22_target1_target1');
    fullfile(base_path, '10mw_flux_1p3000e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5');
    fullfile(base_path, '10mw_flux_1p3000e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N0p5_target1_target1');
};

% N 1.0 浓度组 (不利BT) - 7个算例 (修正：移除重复算例)
groups.unfav_BT{2} = {
    fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p26e22_target1_target1');
    fullfile(base_path, '5p5mw_flux_1p1260e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N1_2');
    fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1');
    fullfile(base_path, '7mw_flux_1p2357e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1');
    fullfile(base_path, '7mw_flux_1p2357e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p20e22_target1_target1');
    fullfile(base_path, '8mw_flux_1p2738e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1');
    fullfile(base_path, '10mw_flux_1p3080e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N1');
};

% N 1.5 浓度组 (不利BT) - 6个算例 (修正：移除有数据问题的算例)
% 基于2025-09-04新运行信息，移除了以下有问题的算例：
% 1. /home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N1_N1p5_target1_target1 - b2fplasma文件缺失
groups.unfav_BT{3} = {
    fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p26e22_N1p5_target1_target1');
    fullfile(base_path, '5p5mw_flux_1p1260e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N1_2_N1p5_target1_target1');
    fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N1p5_target1_target1');
    fullfile(base_path, '7mw_flux_1p2357e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N1p5_target1_target1');
    fullfile(base_path, '7mw_flux_1p2357e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p20e22_N1p5_target1_target1');
    fullfile(base_path, '8mw_flux_1p2738e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_N1p5_target1_target1');
};

% N 2.0 浓度组 (不利BT) - 1个算例 (修正：移除有数据问题的算例)
% 基于9.4处理信息分析，移除了以下8个有问题的算例：
% 1. /home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N2 - b2fplasmf文件缺失
% 2. /home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/8mw_flux_1p2738e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_changeto_N2 - b2fstate文件缺失
% 3. /home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N2 - b2fplasmf文件缺失
% 4. /home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/10mw_flux_1p3080e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N1_N2_target1 - 读取错误+b2fplasma缺失
% 5. /home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N2 - b2fplasmf文件缺失
% 6. /home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/7mw_flux_1p2357e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p20e22_N2_target1_target1 - b2fplasma文件缺失
% 7. /home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N1_Flux1p26e22_N2_target1_target1 - b2fplasma文件缺失
% 8. /home/task3/xrqliang/solps/SOLPS-ITER-3.0.7-20201205/runs/EAST/81574_D+N/6mw_flux_1p1747e22/baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N2 - 经检查发现数据问题
% 仅保留数据完整且正常处理的算例
groups.unfav_BT{4} = {
    fullfile(base_path, '5p5mw_flux_1p1260e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_10_changeto_N0_4_changeto_N2_2');  % 正常处理
    % fullfile(base_path, '6mw_flux_1p1747e22', 'baseline_na2.8e19_target1_reversed_changeto_N0_2_changeto_N0_changeto_N2');  % 已移除：经检查发现数据问题
};

% ========================================================================
% 合并组 - 包含所有fav和unfav的子组
% ========================================================================
groups.combined = [groups.fav_BT, groups.unfav_BT];

% ========================================================================
% 统计信息 (基于2025-08-25修正版清单 - 2025-09-04修正数据问题)
% ========================================================================
% FAV BT 组总计: 30个算例
%   - N 0.5: 7个算例
%   - N 1.0: 8个算例 (修正：移除了1个算例)
%   - N 1.5: 8个算例
%   - N 2.0: 7个算例
%
% UNFAV BT 组总计: 22个算例 (修正：移除有数据问题的算例)
%   - N 0.5: 8个算例
%   - N 1.0: 7个算例 (修正：移除了1个重复算例)
%   - N 1.5: 6个算例 (修正：移除1个有数据问题的算例)
%   - N 2.0: 1个算例 (修正：移除8个有数据问题的算例)
%
% 总计: 52个算例 (经过筛选的稳态算例，已修正数据问题)
% 注意: 这是从原始117个算例中筛选出的稳态算例
% 修正说明 (2025-09-04):
%   - 基于9.4处理信息分析，移除了unfav N2.0组中8个有数据问题的算例
%   - 基于新运行信息，移除了unfav N1.5组中1个有数据问题的算例
%   - 问题类型：b2fplasmf/b2fstate/b2fplasma文件缺失，或数据读取错误
%   - 仅保留数据完整且正常处理的算例
% ========================================================================

end
