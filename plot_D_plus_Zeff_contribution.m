function plot_D_plus_Zeff_contribution(all_radiationData, groupDirs, usePresetLegends)
% PLOT_D_PLUS_ZEFF_CONTRIBUTION 绘制D+离子Zeff贡献子图
%   计算并绘制D+（氘离子）对有效电荷数Zeff的贡献
%   以柱状图形式显示不同算例的对比
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真辐射数据的结构体数组
%     groupDirs - 包含分组目录信息的元胞数组
%     usePresetLegends - 是否使用预设图例名称 (默认: false)
%
%   示例:
%     plot_D_plus_Zeff_contribution(all_radiationData, groupDirs, false)

% 参数默认值处理
if nargin < 3
    usePresetLegends = false;
end

fprintf('\n=== D+ Ion Zeff Contribution Plot ===\n');

% 检查输入数据
if isempty(all_radiationData)
    error('Input radiation data is empty');
end

% 初始化结果存储
num_cases = length(all_radiationData);
d_plus_zeff_contrib = zeros(num_cases, 1);
case_names = cell(num_cases, 1);

fprintf('Processing %d cases...\n', num_cases);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 数据处理：计算每个算例的D+离子Zeff贡献
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for case_idx = 1:num_cases
    current_data = all_radiationData(case_idx);
    
    % 检查必要的数据字段
    if ~isfield(current_data, 'na') || ~isfield(current_data, 'ne')
        fprintf('Warning: Case %d missing D+ or electron density data\n', case_idx);
        d_plus_zeff_contrib(case_idx) = 0;
        continue;
    end
    
    % 获取D+密度和电子密度
    d_plus_density = current_data.na; % D+离子密度
    electron_density = current_data.ne; % 电子密度
    
    % 获取体积数据用于加权平均
    if isfield(current_data, 'vol')
        volume = current_data.vol;
    else
        fprintf('Warning: Case %d missing volume data, using unit volume\n', case_idx);
        volume = ones(size(d_plus_density));
    end
    
    % 计算D+离子对Zeff的贡献
    % Zeff_contrib_D+ = (Z_D+^2 * n_D+) / n_e，其中Z_D+ = 1
    valid_mask = (electron_density > 0) & (d_plus_density >= 0);
    
    if sum(valid_mask) == 0
        fprintf('Warning: Case %d has no valid data points\n', case_idx);
        d_plus_zeff_contrib(case_idx) = 0;
        continue;
    end
    
    % 计算局部Zeff贡献
    local_zeff_contrib = zeros(size(d_plus_density));
    local_zeff_contrib(valid_mask) = (1^2 * d_plus_density(valid_mask)) ./ electron_density(valid_mask);
    
    % 计算体积加权平均的Zeff贡献
    total_volume = sum(volume(valid_mask));
    if total_volume > 0
        d_plus_zeff_contrib(case_idx) = sum(local_zeff_contrib(valid_mask) .* volume(valid_mask)) / total_volume;
    else
        d_plus_zeff_contrib(case_idx) = 0;
    end
    
    % 生成算例名称
    if exist('groupDirs', 'var') && ~isempty(groupDirs) && case_idx <= length(groupDirs)
        case_names{case_idx} = groupDirs{case_idx};
    else
        case_names{case_idx} = sprintf('Case %d', case_idx);
    end
    
    fprintf('Case %d (%s): D+ Zeff contribution = %.4f\n', ...
            case_idx, case_names{case_idx}, d_plus_zeff_contrib(case_idx));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 绘图：创建柱状图
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 创建图形窗口
figure('Name', 'D+ Ion Zeff Contribution', 'NumberTitle', 'off');
set(gcf, 'Position', [100, 100, 800, 600]);

% 使用暖色系颜色
warm_colors = [0.8, 0.4, 0.2]; % 橙红色

% 创建柱状图
bar_handle = bar(1:num_cases, d_plus_zeff_contrib, 'FaceColor', warm_colors, ...
                 'EdgeColor', 'k', 'LineWidth', 1.2);

% 设置坐标轴
xlabel('Cases', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('D^+ Zeff Contribution', 'FontSize', 12, 'FontWeight', 'bold');
title('D^+ Ion Contribution to Effective Charge Number (Z_{eff})', ...
      'FontSize', 14, 'FontWeight', 'bold');

% 设置Y轴范围
if max(d_plus_zeff_contrib) > 0
    ylim([0, max(d_plus_zeff_contrib) * 1.1]);
else
    ylim([0, 1]);
end

% 设置X轴标签
if usePresetLegends && num_cases == 3
    % 使用预设的图例名称
    preset_names = {'Favorable B_T', 'Unfavorable B_T', 'w/o Drift'};
    set(gca, 'XTickLabel', preset_names);
else
    % 使用目录名称或默认名称
    set(gca, 'XTickLabel', case_names);
end

% 在柱状图上添加数值标签
for i = 1:num_cases
    if d_plus_zeff_contrib(i) > 0
        text(i, d_plus_zeff_contrib(i) + max(d_plus_zeff_contrib) * 0.02, ...
             sprintf('%.4f', d_plus_zeff_contrib(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    end
end

% 网格设置
grid on;
set(gca, 'GridAlpha', 0.3);

% 字体设置
set(gca, 'FontSize', 11);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 保存图形
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 保存为.fig格式
try
    save_filename = 'D_plus_Zeff_contribution.fig';
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

if any(d_plus_zeff_contrib > 0)
    valid_values = d_plus_zeff_contrib(d_plus_zeff_contrib > 0);
    fprintf('Valid cases: %d\n', length(valid_values));
    fprintf('Mean D+ Zeff contribution: %.4f\n', mean(valid_values));
    fprintf('Max D+ Zeff contribution: %.4f\n', max(valid_values));
    fprintf('Min D+ Zeff contribution: %.4f\n', min(valid_values));
    
    if length(valid_values) > 1
        fprintf('Standard deviation: %.4f\n', std(valid_values));
    end
else
    fprintf('No valid D+ Zeff contribution data found\n');
end

fprintf('=== D+ Ion Zeff Contribution Plot Complete ===\n');

end
