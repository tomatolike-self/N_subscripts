function plot_Zeff_contributions_except_Ne8(all_radiationData, groupDirs, usePresetLegends)
% PLOT_ZEFF_CONTRIBUTIONS_EXCEPT_NE8 绘制除Ne8+外所有离子的Zeff贡献
%   计算并绘制除Ne8+外所有离子（包括D+和其他Ne离子价态）对Zeff的贡献
%   以柱状图形式显示不同算例的对比
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真辐射数据的结构体数组
%     groupDirs - 包含分组目录信息的元胞数组
%     usePresetLegends - 是否使用预设图例名称 (默认: false)
%
%   示例:
%     plot_Zeff_contributions_except_Ne8(all_radiationData, groupDirs, false)

% 参数默认值处理
if nargin < 3
    usePresetLegends = false;
end

fprintf('\n=== Zeff Contributions from All Ions Except Ne8+ Plot ===\n');

% 检查输入数据
if isempty(all_radiationData)
    error('Input radiation data is empty');
end

% 初始化结果存储
num_cases = length(all_radiationData);
total_zeff_contrib = zeros(num_cases, 1);
d_plus_contrib = zeros(num_cases, 1);
other_ne_contrib = zeros(num_cases, 1);
case_names = cell(num_cases, 1);

fprintf('Processing %d cases...\n', num_cases);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 数据处理：计算每个算例的Zeff贡献（除Ne8+外）
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for case_idx = 1:num_cases
    current_data = all_radiationData(case_idx);
    
    % 检查必要的数据字段
    if ~isfield(current_data, 'ne')
        fprintf('Warning: Case %d missing electron density data\n', case_idx);
        continue;
    end
    
    electron_density = current_data.ne;
    
    % 获取体积数据用于加权平均
    if isfield(current_data, 'vol')
        volume = current_data.vol;
    else
        fprintf('Warning: Case %d missing volume data, using unit volume\n', case_idx);
        volume = ones(size(electron_density));
    end
    
    % 初始化贡献值
    local_d_plus_contrib = zeros(size(electron_density));
    local_other_ne_contrib = zeros(size(electron_density));
    
    valid_mask = electron_density > 0;
    
    % 1. 计算D+离子贡献
    if isfield(current_data, 'na')
        d_plus_density = current_data.na;
        local_d_plus_contrib(valid_mask) = (1^2 * d_plus_density(valid_mask)) ./ electron_density(valid_mask);
    end
    
    % 2. 计算其他Ne离子价态贡献（Ne1+ 到 Ne7+, Ne9+, Ne10+）
    ne_charge_states = [1:7, 9:10]; % 排除Ne8+
    
    for charge = ne_charge_states
        field_name = sprintf('nNe%d', charge);
        if isfield(current_data, field_name)
            ne_density = current_data.(field_name);
            local_other_ne_contrib(valid_mask) = local_other_ne_contrib(valid_mask) + ...
                (charge^2 * ne_density(valid_mask)) ./ electron_density(valid_mask);
        end
    end
    
    % 计算体积加权平均
    if sum(valid_mask) > 0
        total_volume = sum(volume(valid_mask));
        if total_volume > 0
            d_plus_contrib(case_idx) = sum(local_d_plus_contrib(valid_mask) .* volume(valid_mask)) / total_volume;
            other_ne_contrib(case_idx) = sum(local_other_ne_contrib(valid_mask) .* volume(valid_mask)) / total_volume;
            total_zeff_contrib(case_idx) = d_plus_contrib(case_idx) + other_ne_contrib(case_idx);
        end
    end
    
    % 生成算例名称
    if exist('groupDirs', 'var') && ~isempty(groupDirs) && case_idx <= length(groupDirs)
        case_names{case_idx} = groupDirs{case_idx};
    else
        case_names{case_idx} = sprintf('Case %d', case_idx);
    end
    
    fprintf('Case %d (%s): Total Zeff contrib (except Ne8+) = %.4f (D+: %.4f, Other Ne: %.4f)\n', ...
            case_idx, case_names{case_idx}, total_zeff_contrib(case_idx), ...
            d_plus_contrib(case_idx), other_ne_contrib(case_idx));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 绘图：创建堆叠柱状图
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 创建图形窗口
figure('Name', 'Zeff Contributions from All Ions Except Ne8+', 'NumberTitle', 'off');
set(gcf, 'Position', [100, 100, 900, 600]);

% 准备堆叠数据
stack_data = [d_plus_contrib'; other_ne_contrib'];

% 使用冷色系颜色区分不同贡献
cool_colors = [0.2, 0.6, 0.8;    % 蓝色 - D+贡献
               0.4, 0.8, 0.6];   % 青绿色 - 其他Ne离子贡献

% 创建堆叠柱状图
bar_handle = bar(1:num_cases, stack_data', 'stacked', 'EdgeColor', 'k', 'LineWidth', 1.0);

% 设置颜色
for i = 1:length(bar_handle)
    bar_handle(i).FaceColor = cool_colors(i, :);
end

% 设置坐标轴
xlabel('Cases', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Zeff Contribution', 'FontSize', 12, 'FontWeight', 'bold');
title('Z_{eff} Contributions from All Ions Except Ne^{8+}', ...
      'FontSize', 14, 'FontWeight', 'bold');

% 设置Y轴范围（0-1.6，根据您的偏好）
ylim([0, 1.6]);

% 设置X轴标签
if usePresetLegends && num_cases == 3
    % 使用预设的图例名称
    preset_names = {'Favorable B_T', 'Unfavorable B_T', 'w/o Drift'};
    set(gca, 'XTickLabel', preset_names);
else
    % 使用目录名称或默认名称
    set(gca, 'XTickLabel', case_names);
end

% 添加图例
legend({'D^+ Contribution', 'Other Ne Ions Contribution'}, ...
       'Location', 'best', 'FontSize', 10);

% 在柱状图上添加总数值标签
for i = 1:num_cases
    if total_zeff_contrib(i) > 0
        text(i, total_zeff_contrib(i) + 0.05, ...
             sprintf('%.3f', total_zeff_contrib(i)), ...
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
    save_filename = 'Zeff_contributions_except_Ne8.fig';
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

if any(total_zeff_contrib > 0)
    valid_indices = total_zeff_contrib > 0;
    fprintf('Valid cases: %d\n', sum(valid_indices));
    fprintf('Mean total Zeff contribution (except Ne8+): %.4f\n', mean(total_zeff_contrib(valid_indices)));
    fprintf('Mean D+ contribution: %.4f\n', mean(d_plus_contrib(valid_indices)));
    fprintf('Mean other Ne ions contribution: %.4f\n', mean(other_ne_contrib(valid_indices)));
    
    fprintf('\nDetailed breakdown:\n');
    for i = 1:num_cases
        if total_zeff_contrib(i) > 0
            d_percent = (d_plus_contrib(i) / total_zeff_contrib(i)) * 100;
            ne_percent = (other_ne_contrib(i) / total_zeff_contrib(i)) * 100;
            fprintf('  %s: D+ %.1f%%, Other Ne %.1f%%\n', ...
                    case_names{i}, d_percent, ne_percent);
        end
    end
else
    fprintf('No valid Zeff contribution data found\n');
end

fprintf('=== Zeff Contributions Plot Complete ===\n');

end
