function plot_core_edge_n_density_stacked_bar(all_radiationData, groupDirs)
% =========================================================================
% plot_core_edge_n_density_stacked_bar - 芯部边缘N离子密度堆叠柱状图
% =========================================================================
%
% 功能描述：
%   - 绘制芯部边缘区域N1+到N7+各价态离子密度的堆叠柱状图
%   - 每个算例显示为一根柱子，柱子内部按价态堆叠显示密度贡献
%   - 密度值使用体积加权的极向平均值计算
%
% 输入：
%   - all_radiationData : SOLPS仿真数据cell数组（包含plasma, gmtry, dirName）
%   - groupDirs         : 分组目录cell数组，如 {{case1, case2}, {case3}}
%
% 输出：
%   - 堆叠柱状图figure
%   - 自动保存带时间戳的.fig文件
%
% 依赖函数/工具箱：
%   - 无
%
% 注意事项：
%   - R2019a兼容
%   - N系统：N1+到N7+（共7个带电价态），plasma.na索引4-10
%   - 芯部边缘区域：极向26:73，径向2
%   - 体积加权平均：sum(n_i * V_i) / sum(V_i)
% =========================================================================

fprintf('\n=== Creating Core Edge N Ion Density Stacked Bar Chart ===\n');

%% 区域常量定义（EAST 98x28网格）
CORE_EDGE_RADIAL_INDEX = 2;     % 芯部边缘径向索引
CORE_POL_START = 26;            % 芯部极向起始
CORE_POL_END = 73;              % 芯部极向结束
IMPURITY_START_INDEX = 3;       % N0在plasma.na中的索引（中性N）
MAX_N_CHARGE = 7;               % N系统最高价态（N1+到N7+）

%% 绘图属性常量
FONT_NAME = 'Times New Roman';
TICK_FONT_SIZE = 36;
LABEL_FONT_SIZE = 44;
LEGEND_FONT_SIZE = 32;
BAR_WIDTH = 0.8;
GROUP_GAP = 0.5;

% N1+到N7+各价态颜色
CHARGE_COLORS = [
    0.2, 0.4, 0.8;   % N1+ - 蓝色
    0.2, 0.7, 0.3;   % N2+ - 绿色
    0.9, 0.6, 0.1;   % N3+ - 橙色
    0.8, 0.2, 0.2;   % N4+ - 红色
    0.6, 0.2, 0.8;   % N5+ - 紫色
    0.1, 0.7, 0.7;   % N6+ - 青色
    0.5, 0.3, 0.1    % N7+ - 棕色
    ];

%% 数据收集
num_groups = length(groupDirs);
all_density_data = [];
case_counter = 0;

for g = 1:num_groups
    currentGroup = groupDirs{g};
    num_cases_in_group = length(currentGroup);
    
    fprintf('\nProcessing Group %d (%d cases)...\n', g, num_cases_in_group);
    
    for k = 1:num_cases_in_group
        currentDir = currentGroup{k};
        
        % --- 在数据中查找当前目录 ---
        idx = 0;
        for i = 1:length(all_radiationData)
            if strcmp(all_radiationData{i}.dirName, currentDir)
                idx = i;
                break;
            end
        end
        
        if idx <= 0
            fprintf('  Warning: Directory %s not found. Skipping.\n', currentDir);
            continue;
        end
        
        % --- 获取当前算例数据 ---
        data = all_radiationData{idx};
        fprintf('  Processing Case %d: %s\n', k, data.dirName);
        
        plasma = data.plasma;
        gmtry = data.gmtry;
        
        % --- 网格尺寸检查 ---
        ny = size(plasma.ne, 1);  % 极向网格数
        
        % 确保极向索引不超出网格范围
        core_pol_start_adj = max(1, min(CORE_POL_START, ny));
        core_pol_end_adj = max(core_pol_start_adj, min(CORE_POL_END, ny));
        core_pol_range = core_pol_start_adj:core_pol_end_adj;
        
        % --- 计算各价态N离子的体积加权极向平均密度 ---
        density_by_charge = zeros(MAX_N_CHARGE, 1);
        
        for i_charge = 1:MAX_N_CHARGE
            % N(i)+在plasma.na中的索引 = IMPURITY_START_INDEX + i_charge
            % N0 -> 3, N1+ -> 4, N2+ -> 5, ..., N7+ -> 10
            species_idx = IMPURITY_START_INDEX + i_charge;
            
            if species_idx <= size(plasma.na, 3)
                % 体积加权平均：sum(n * V) / sum(V)
                total_volume = 0;
                weighted_sum = 0;
                
                for i_pol = core_pol_range
                    vol_i = gmtry.vol(i_pol, CORE_EDGE_RADIAL_INDEX);
                    n_i = plasma.na(i_pol, CORE_EDGE_RADIAL_INDEX, species_idx);
                    weighted_sum = weighted_sum + n_i * vol_i;
                    total_volume = total_volume + vol_i;
                end
                
                if total_volume > 0
                    density_by_charge(i_charge) = weighted_sum / total_volume;
                else
                    density_by_charge(i_charge) = 0;
                end
            else
                density_by_charge(i_charge) = 0;
                fprintf('    Warning: N%d+ data not found (index %d out of range)\n', i_charge, species_idx);
            end
        end
        
        % --- 存储数据 ---
        case_counter = case_counter + 1;
        all_density_data(case_counter).density_by_charge = density_by_charge;
        all_density_data(case_counter).group = g;
        all_density_data(case_counter).dir_name = data.dirName;
    end
end

%% 数据检查
if case_counter == 0
    fprintf('\nError: No valid data found. Exiting.\n');
    return;
end

fprintf('\nTotal cases processed: %d\n', case_counter);

%% 准备密度矩阵
% 矩阵格式：行=价态(N1+到N7+)，列=算例
num_cases = case_counter;
density_matrix = zeros(MAX_N_CHARGE, num_cases);

for i = 1:num_cases
    density_matrix(:, i) = all_density_data(i).density_by_charge;
end

% 清理NaN和Inf
density_matrix(~isfinite(density_matrix)) = 0;

%% 计算X轴位置（组间有间隔）
x_positions = zeros(1, num_cases);
case_idx = 0;
current_x = 1;

for g = 1:num_groups
    num_in_group = length(groupDirs{g});
    for k = 1:num_in_group
        case_idx = case_idx + 1;
        x_positions(case_idx) = current_x;
        current_x = current_x + 1;
    end
    if g < num_groups
        current_x = current_x + GROUP_GAP;
    end
end

% 计算组中心位置（用于X轴标签）
group_centers = zeros(num_groups, 1);
case_idx = 0;
for g = 1:num_groups
    num_in_group = length(groupDirs{g});
    group_start = case_idx + 1;
    group_end = case_idx + num_in_group;
    group_centers(g) = mean(x_positions(group_start:group_end));
    case_idx = case_idx + num_in_group;
end

%% 创建Figure
fig = figure('Name', 'Core Edge N Density Stacked Bar Chart', ...
    'NumberTitle', 'off', 'Color', 'w', ...
    'Units', 'inches', 'Position', [1, 1, 18, 10]);

set(fig, 'DefaultTextInterpreter', 'latex', ...
    'DefaultAxesTickLabelInterpreter', 'latex', ...
    'DefaultLegendInterpreter', 'latex');

%% 绘制堆叠柱状图
hold on;

if num_cases == 1
    % 单算例：bar直接使用列向量
    bh = bar(x_positions, density_matrix, BAR_WIDTH, 'stacked');
else
    % 多算例：需要转置，bar期望每行是一个算例
    bh = bar(x_positions, density_matrix', BAR_WIDTH, 'stacked');
end

% 设置每个价态的颜色
for i_charge = 1:MAX_N_CHARGE
    bh(i_charge).FaceColor = CHARGE_COLORS(i_charge, :);
    bh(i_charge).EdgeColor = 'k';
    bh(i_charge).LineWidth = 1.2;
end

hold off;

%% 设置坐标轴
% X轴刻度和标签（N充气速率）
xticks(group_centers);
puff_rate_labels = cell(num_groups, 1);
for g = 1:num_groups
    puff_rate_labels{g} = sprintf('%.1f', 0.5 * g);
end
xticklabels(puff_rate_labels);

% X轴范围
xlim([min(x_positions) - 0.5, max(x_positions) + 0.5]);

% 坐标轴标签
xlabel('$\Gamma_{\mathrm{puff,N}}$ ($\times 10^{20}$ s$^{-1}$)', 'FontSize', LABEL_FONT_SIZE);
ylabel('$n_{\mathrm{N}}$ (m$^{-3}$)', 'FontSize', LABEL_FONT_SIZE);

% 坐标轴属性
ax = gca;
set(ax, 'FontName', FONT_NAME, 'FontSize', TICK_FONT_SIZE);
grid on; box on;
set(ax, 'Layer', 'top');

%% 图例
legend_labels = cell(MAX_N_CHARGE, 1);
for i = 1:MAX_N_CHARGE
    legend_labels{i} = sprintf('$\\mathrm{N}^{%d+}$', i);
end

lg = legend(bh, legend_labels, 'Location', 'best', 'FontSize', LEGEND_FONT_SIZE);
set(lg, 'Box', 'on', 'LineWidth', 1.2);

%% 保存Figure
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
fname = sprintf('Core_Edge_N_Density_Stacked_Bar_%s.fig', timestamp);
savefig(gcf, fname);
fprintf('Figure saved as: %s\n', fname);

fprintf('\n=== Core Edge N Ion Density Stacked Bar Chart Completed ===\n');

end
