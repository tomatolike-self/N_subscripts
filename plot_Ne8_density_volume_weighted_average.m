function plot_Ne8_density_volume_weighted_average(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames)
% PLOT_NE8_DENSITY_VOLUME_WEIGHTED_AVERAGE 绘制Ne8+离子密度体积加权平均值
%   在芯部边缘区域（径向网格位置2）计算Ne8+离子密度的体积加权平均值
%   并以分组柱状图形式显示不同算例的对比
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真辐射数据的结构体数组
%     groupDirs - 包含分组目录信息的元胞数组
%     usePresetLegends - 是否使用预设图例名称 (默认: false)
%     showLegendsForDirNames - 使用目录名时是否显示图例 (默认: true)
%
%   示例:
%     plot_Ne8_density_volume_weighted_average(all_radiationData, groupDirs, false, true)

% 参数默认值处理
if nargin < 3
    usePresetLegends = false;
end
if nargin < 4
    showLegendsForDirNames = true;
end

fprintf('\n=== Ne8+ Density Volume-Weighted Average Plot ===\n');

% 检查输入数据
if isempty(all_radiationData)
    error('Input radiation data is empty');
end

% 初始化结果存储
num_cases = length(all_radiationData);
ne8_avg_values = zeros(num_cases, 1);
case_names = cell(num_cases, 1);

% 芯部边缘区域定义（径向网格位置2）
core_edge_radial_position = 2;

fprintf('Processing %d cases...\n', num_cases);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 数据处理：计算每个算例的Ne8+密度体积加权平均值
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for case_idx = 1:num_cases
    current_data = all_radiationData(case_idx);
    
    % 检查必要的数据字段
    if ~isfield(current_data, 'nNe8')
        fprintf('Warning: Case %d missing Ne8+ density data, using zero value\n', case_idx);
        ne8_avg_values(case_idx) = 0;
        continue;
    end
    
    % 获取Ne8+密度数据
    ne8_density = current_data.nNe8;
    
    % 获取体积数据
    if isfield(current_data, 'vol')
        volume = current_data.vol;
    else
        fprintf('Warning: Case %d missing volume data, using unit volume\n', case_idx);
        volume = ones(size(ne8_density));
    end
    
    % 获取径向网格索引
    if isfield(current_data, 'ixiy')
        radial_indices = current_data.ixiy(:, 1); % 径向索引
    else
        fprintf('Warning: Case %d missing grid index data, using all points\n', case_idx);
        radial_indices = ones(size(ne8_density));
    end
    
    % 选择芯部边缘区域的数据点
    core_edge_mask = (radial_indices == core_edge_radial_position);
    
    if sum(core_edge_mask) == 0
        fprintf('Warning: Case %d has no data points at radial position %d\n', ...
                case_idx, core_edge_radial_position);
        ne8_avg_values(case_idx) = 0;
        continue;
    end
    
    % 提取芯部边缘区域的数据
    ne8_core_edge = ne8_density(core_edge_mask);
    vol_core_edge = volume(core_edge_mask);
    
    % 计算体积加权平均值
    total_volume = sum(vol_core_edge);
    if total_volume > 0
        ne8_avg_values(case_idx) = sum(ne8_core_edge .* vol_core_edge) / total_volume;
    else
        ne8_avg_values(case_idx) = 0;
    end
    
    % 生成算例名称
    if exist('groupDirs', 'var') && ~isempty(groupDirs) && case_idx <= length(groupDirs)
        case_names{case_idx} = groupDirs{case_idx};
    else
        case_names{case_idx} = sprintf('Case %d', case_idx);
    end
    
    fprintf('Case %d (%s): Ne8+ avg = %.2e m^{-3}\n', ...
            case_idx, case_names{case_idx}, ne8_avg_values(case_idx));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 绘图：创建分组柱状图
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 创建图形窗口
figure('Name', 'Ne8+ Density Volume-Weighted Average', 'NumberTitle', 'off');
set(gcf, 'Position', [100, 100, 800, 600]);

% 创建柱状图
bar_handle = bar(1:num_cases, ne8_avg_values, 'FaceColor', [0.2, 0.6, 0.8], ...
                 'EdgeColor', 'k', 'LineWidth', 1.2);

% 设置坐标轴
xlabel('Cases', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Ne^{8+} Density (m^{-3})', 'FontSize', 12, 'FontWeight', 'bold');
title('Ne^{8+} Ion Density Volume-Weighted Average at Core-Edge Region (Radial Position 2)', ...
      'FontSize', 14, 'FontWeight', 'bold');

% 设置Y轴为科学计数法格式
ax = gca;
ax.YAxis.Exponent = 0;
ytickformat('%.1e');

% 设置Y轴范围
if max(ne8_avg_values) > 0
    ylim([0, max(ne8_avg_values) * 1.1]);
end

% 设置X轴标签
if usePresetLegends && num_cases == 3
    % 使用预设的图例名称
    preset_names = {'Favorable B_T', 'Unfavorable B_T', 'w/o Drift'};
    set(gca, 'XTickLabel', preset_names);
    legend_names = preset_names;
elseif showLegendsForDirNames
    % 使用目录名称
    set(gca, 'XTickLabel', case_names);
    legend_names = case_names;
else
    % 不显示具体名称
    set(gca, 'XTickLabel', arrayfun(@(x) sprintf('Case %d', x), 1:num_cases, 'UniformOutput', false));
    legend_names = {};
end

% 在柱状图上添加数值标签
for i = 1:num_cases
    if ne8_avg_values(i) > 0
        text(i, ne8_avg_values(i) + max(ne8_avg_values) * 0.02, ...
             sprintf('%.2e', ne8_avg_values(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    end
end

% 网格设置
grid on;
set(gca, 'GridAlpha', 0.3);

% 字体设置
set(gca, 'FontSize', 11);

% 图例设置（如果需要）
if ~isempty(legend_names) && showLegendsForDirNames
    legend(legend_names, 'Location', 'best', 'FontSize', 10);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 保存图形
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 保存为.fig格式
try
    save_filename = 'Ne8_density_volume_weighted_average_core_edge.fig';
    savefig(gcf, save_filename);
    fprintf('Figure saved as: %s\n', save_filename);
catch ME
    fprintf('Warning: Failed to save figure: %s\n', ME.message);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 输出统计信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n=== Statistical Summary ===\n');
fprintf('Total cases processed: %d\n', num_cases);
fprintf('Core-edge radial position: %d\n', core_edge_radial_position);

if any(ne8_avg_values > 0)
    valid_values = ne8_avg_values(ne8_avg_values > 0);
    fprintf('Valid cases: %d\n', length(valid_values));
    fprintf('Mean Ne8+ density: %.2e m^{-3}\n', mean(valid_values));
    fprintf('Max Ne8+ density: %.2e m^{-3}\n', max(valid_values));
    fprintf('Min Ne8+ density: %.2e m^{-3}\n', min(valid_values));
    
    if length(valid_values) > 1
        fprintf('Standard deviation: %.2e m^{-3}\n', std(valid_values));
    end
else
    fprintf('No valid Ne8+ density data found\n');
end

fprintf('=== Ne8+ Density Volume-Weighted Average Plot Complete ===\n');

end
