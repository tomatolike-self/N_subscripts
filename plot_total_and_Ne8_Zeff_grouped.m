function plot_total_and_Ne8_Zeff_grouped(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames)
% PLOT_TOTAL_AND_NE8_ZEFF_GROUPED 绘制总Zeff和Ne8+ Zeff贡献的分组对比图
%   此函数创建一个2*1的子图布局：
%   上图：总Zeff的分组柱状图
%   下图：Ne8+ Zeff贡献的分组柱状图
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真辐射数据的结构体数组
%     groupDirs - 包含分组目录信息的元胞数组
%     usePresetLegends - 是否使用预设图例名称 (默认: true)
%     showLegendsForDirNames - 当 usePresetLegends 为 false 时，是否显示基于目录名的图例 (默认: false)
%
%   示例:
%     plot_total_and_Ne8_Zeff_grouped(all_radiationData, groupDirs, true, false)

% ================== 参数处理 ==================
if nargin < 3
    % 提供用户选择显示方式的选项
    fprintf('\n=== Total Zeff and Ne8+ Zeff Grouped Comparison Plot ===\n');
    fprintf('请选择X轴标签显示方式:\n');
    fprintf('1. 使用预设图例名称 (fav. B_T, unfav. B_T, w/o drift)\n');
    fprintf('2. 使用目录名称\n');
    choice = input('请输入选择 (1 或 2): ');

    if choice == 2
        usePresetLegends = false;
        showLegendsForDirNames = true;
    else
        usePresetLegends = true;
        showLegendsForDirNames = false;
    end
else
    if nargin < 4
        showLegendsForDirNames = false;
    end
end

fprintf('\n=== Total Zeff and Ne8+ Zeff Grouped Comparison Plot ===\n');

% 检查输入数据
if isempty(all_radiationData)
    error('Input radiation data is empty');
end

numGroups = length(groupDirs);
if numGroups == 0
    fprintf('Warning: No group information provided. Using single group.\n');
    numGroups = 1;
    % 创建单个组包含所有案例
    all_dirs = {};
    for i = 1:length(all_radiationData)
        if isfield(all_radiationData{i}, 'dirName')
            all_dirs{end+1} = all_radiationData{i}.dirName;
        end
    end
    groupDirs = {all_dirs};
end

% ================== 常量定义 ==================
core_edge_radial_index = 2;  % 芯部边缘径向索引
main_ion_species_index = 2;  % D+离子种类索引
impurity_start_index = 3;    % 杂质离子起始索引
ne8_charge_state = 8;        % Ne8+价态
max_ne_charge = 10;          % 最大Ne价态

preset_legend_names = {'fav. B\_T', 'unfav. B\_T', 'w/o drift'}; % 转义下划线用于LaTeX
fontSize = 12;
group_colors_set = lines(max(numGroups, 1));

% ================== 数据收集 ==================
all_dir_names = {};
all_full_paths = {};
all_total_zeff_values = [];
all_ne8_zeff_values = [];

fprintf('Collecting data from %d groups...\n', numGroups);

for g = 1:numGroups
    currentGroup = groupDirs{g};
    fprintf('Processing Group %d with %d cases...\n', g, length(currentGroup));
    
    for k = 1:length(currentGroup)
        currentDir = currentGroup{k};
        
        % 查找对应的数据索引
        idx = findDirIndexInRadiationData(all_radiationData, currentDir);
        if idx <= 0
            fprintf('Warning: Directory %s not found in radiation data. Skipping.\n', currentDir);
            continue;
        end
        
        data = all_radiationData{idx};
        fprintf('  Processing Case %d: %s\n', k, data.dirName);
        
        % 提取等离子体数据
        plasma = data.plasma;
        ny = size(plasma.ne, 1); % 极向网格数
        nx = size(plasma.ne, 2); % 径向网格数
        
        % 安全的电子密度（避免除零）
        safe_ne = max(plasma.ne, 1e-10);
        
        % ============== 计算总Zeff ==============
        % D+离子贡献 (Z^2 = 1)
        nD_plus = plasma.na(:, :, main_ion_species_index);
        Zeff_D = nD_plus * (1^2) ./ safe_ne;
        
        % Ne离子各价态贡献
        impurity_end_index = impurity_start_index + max_ne_charge;
        nNe_all_charges = plasma.na(:, :, impurity_start_index:impurity_end_index);
        
        Zeff_Ne = zeros(ny, nx);
        num_Ne_species = size(nNe_all_charges, 3);
        for i_Z = 2:min(num_Ne_species, max_ne_charge + 1) % 从Ne1+开始
            charge_state = i_Z - 1; % i_Z=2 -> charge_state=1 (Ne1+)
            if charge_state >= 1 && charge_state <= max_ne_charge
                Zeff_Ne = Zeff_Ne + nNe_all_charges(:,:,i_Z) * (charge_state^2) ./ safe_ne;
            end
        end
        
        % 总Zeff
        Zeff_total = Zeff_D + Zeff_Ne;
        
        % ============== 计算Ne8+ Zeff贡献 ==============
        ne8_index = ne8_charge_state + 1; % Ne8+对应的索引
        if ne8_index <= num_Ne_species
            nNe8_plus = nNe_all_charges(:,:,ne8_index);
            Zeff_Ne8 = nNe8_plus * (ne8_charge_state^2) ./ safe_ne;
        else
            Zeff_Ne8 = zeros(ny, nx);
            fprintf('Warning: Ne8+ data not available for case %s\n', data.dirName);
        end
        
        % ============== 提取芯部边缘数据并计算体积加权平均 ==============
        if isfield(data, 'gmtry') && isfield(data.gmtry, 'vol')
            core_vol = data.gmtry.vol(:, core_edge_radial_index);
        else
            fprintf('Warning: Volume data not available for case %s, using uniform weighting\n', data.dirName);
            core_vol = ones(ny, 1);
        end
        
        % 提取芯部边缘的Zeff值
        total_zeff_core_edge = Zeff_total(:, core_edge_radial_index);
        ne8_zeff_core_edge = Zeff_Ne8(:, core_edge_radial_index);
        
        % 计算体积加权平均
        valid_indices = ~isnan(total_zeff_core_edge) & ~isnan(ne8_zeff_core_edge) & core_vol > 0;
        
        if sum(valid_indices) > 0
            total_vol = sum(core_vol(valid_indices));
            total_zeff_avg = sum(total_zeff_core_edge(valid_indices) .* core_vol(valid_indices)) / total_vol;
            ne8_zeff_avg = sum(ne8_zeff_core_edge(valid_indices) .* core_vol(valid_indices)) / total_vol;
        else
            total_zeff_avg = NaN;
            ne8_zeff_avg = NaN;
            fprintf('Warning: No valid data for case %s\n', data.dirName);
        end
        
        % 存储结果
        all_dir_names{end+1} = data.dirName;
        all_full_paths{end+1} = currentDir;
        all_total_zeff_values(end+1) = total_zeff_avg;
        all_ne8_zeff_values(end+1) = ne8_zeff_avg;
        
        fprintf('    Total Zeff: %.4f, Ne8+ Zeff: %.4f\n', total_zeff_avg, ne8_zeff_avg);
    end
end

fprintf('Successfully processed %d cases.\n', length(all_dir_names));

% 调试信息
if ~isempty(all_total_zeff_values)
    fprintf('Total Zeff values: min=%.6f, max=%.6f, mean=%.6f\n', ...
            min(all_total_zeff_values), max(all_total_zeff_values), mean(all_total_zeff_values));
end
if ~isempty(all_ne8_zeff_values)
    fprintf('Ne8+ Zeff values: min=%.6f, max=%.6f, mean=%.6f\n', ...
            min(all_ne8_zeff_values), max(all_ne8_zeff_values), mean(all_ne8_zeff_values));
end

if isempty(all_dir_names)
    fprintf('No valid data found. Exiting.\n');
    return;
end

%% ======================== 绘制2*1子图 ============================

% 创建图形窗口
fig = figure('Name', 'Total Zeff and Ne8+ Zeff Grouped Comparison', 'NumberTitle', 'off', ...
             'Color', 'w', 'Units', 'inches', 'Position', [2, 1, 14, 10]);

% 设置LaTeX解释器
set(fig, 'DefaultTextInterpreter', 'latex', ...
         'DefaultAxesTickLabelInterpreter', 'latex', ...
         'DefaultLegendInterpreter', 'latex');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 上子图：总Zeff
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2, 1, 1);
plot_grouped_bar_chart(all_dir_names, all_full_paths, all_total_zeff_values, ...
                      groupDirs, group_colors_set, ...
                      'Total $Z_{eff}$ (Core-Edge, Volume-Weighted Average)', ...
                      'Total $Z_{eff}$', fontSize, usePresetLegends, showLegendsForDirNames, []);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 下子图：Ne8+ Zeff贡献
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2, 1, 2);
plot_grouped_bar_chart(all_dir_names, all_full_paths, all_ne8_zeff_values, ...
                      groupDirs, group_colors_set, ...
                      '$Ne^{8+}$ $Z_{eff}$ Contribution (Core-Edge, Volume-Weighted Average)', ...
                      '$Ne^{8+}$ $Z_{eff}$ Contribution', fontSize, usePresetLegends, showLegendsForDirNames, []);

% 保存图形
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
savefig(fig, sprintf('Total_and_Ne8_Zeff_Grouped_Comparison_%s.fig', timestamp));

fprintf('\n=== Total Zeff and Ne8+ Zeff grouped comparison plotting completed ===\n');
fprintf('Figure saved as: Total_and_Ne8_Zeff_Grouped_Comparison_%s.fig\n', timestamp);

end

%% =========================================================================
%% 内部函数：绘制分组柱状图
%% =========================================================================
function plot_grouped_bar_chart(dir_names, full_paths, data_values, groupDirs, group_colors_set, ...
                                fig_title, ylabel_text, fontSize, usePresetLegends, showLegendsForDirNames, y_axis_range)

    num_cases = length(dir_names);
    num_groups = length(groupDirs);

    % 准备颜色
    bar_colors = zeros(num_cases, 3);
    legend_handles = [];
    legend_strings = {};

    for i = 1:num_cases
        group_idx = findGroupIndex(full_paths{i}, groupDirs);
        if group_idx > 0
            bar_colors(i, :) = group_colors_set(group_idx, :);
        else
            bar_colors(i, :) = [0.5, 0.5, 0.5]; % 灰色用于未分组的案例
        end
    end

    % 调试信息
    fprintf('Debug: num_cases = %d, data_values length = %d\n', num_cases, length(data_values));
    if ~isempty(data_values)
        fprintf('Debug: data_values range = [%.6f, %.6f]\n', min(data_values), max(data_values));
        fprintf('Debug: NaN count = %d\n', sum(isnan(data_values)));
    end

    % 绘制柱状图
    if ~isempty(data_values) && ~all(isnan(data_values)) && num_cases > 0
        bh = bar(1:num_cases, data_values, 'FaceColor', 'flat');
        bh.CData = bar_colors;

        % 计算每组的案例数量和位置
        group_sizes = zeros(num_groups, 1);
        group_start_indices = zeros(num_groups, 1);
        case_counter = 1;

        for g = 1:num_groups
            group_start_indices(g) = case_counter;
            group_sizes(g) = length(groupDirs{g});
            case_counter = case_counter + group_sizes(g);
        end

        % 设置x轴 - 使用数字组标识符
        group_centers = zeros(num_groups, 1);
        for g = 1:num_groups
            group_centers(g) = group_start_indices(g) + (group_sizes(g) - 1) / 2;
        end

        % 设置x轴刻度为组中心位置
        xticks(group_centers);

        % 设置组标签为数字标识符：0.5, 1, 1.5, 2, ...
        group_labels = {};
        for g = 1:num_groups
            group_labels{end+1} = sprintf('%.1f', g * 0.5);
        end

        xticklabels(group_labels);
        set(gca, 'TickLabelInterpreter', 'none');

        % 添加组标签说明
        addGroupLabels(gca, group_start_indices, group_sizes, usePresetLegends);

        % 设置标签和标题
        xlabel('Simulation Cases (Grouped)');
        ylabel(ylabel_text, 'FontSize', fontSize);
        title(fig_title, 'FontSize', fontSize+2);

        grid('on');
        box('on');
        set(gca, 'TickDir', 'in');

        % 设置Y轴范围（如果指定）
        if ~isempty(y_axis_range) && length(y_axis_range) == 2
            ylim(y_axis_range);
        end

        % 添加分组图例
        if num_groups > 1 && (showLegendsForDirNames || usePresetLegends)
            addGroupLegend(gca, groupDirs, group_colors_set, usePresetLegends);
        end
    else
        % 显示详细的错误信息
        if isempty(data_values)
            error_msg = 'No data values found';
        elseif all(isnan(data_values))
            error_msg = 'All data values are NaN';
        elseif num_cases == 0
            error_msg = 'No cases to plot';
        else
            error_msg = 'Unknown plotting error';
        end

        fprintf('Warning: %s\n', error_msg);
        text(0.5, 0.5, sprintf('No valid data available\n%s', error_msg), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
             'FontSize', fontSize, 'Units', 'normalized');
    end
end

%% =========================================================================
%% 辅助函数
%% =========================================================================

function idx = findDirIndexInRadiationData(all_radiationData, dirName)
% 在辐射数据中查找目录名对应的索引
    idx = -1;
    for i = 1:length(all_radiationData)
        if isfield(all_radiationData{i}, 'dirName') && strcmp(all_radiationData{i}.dirName, dirName)
            idx = i;
            return;
        end
    end
end

function group_idx = findGroupIndex(full_path, groupDirs)
% 查找案例所属的组索引 - 使用精确匹配
    group_idx = 0;
    for g = 1:length(groupDirs)
        if any(strcmp(full_path, groupDirs{g}))
            group_idx = g;
            return;
        end
    end
end

function addGroupLabels(ax, group_start_indices, group_sizes, usePresetLegends)
% 添加组标签说明文本
    preset_legend_names = {'fav. B\_T', 'unfav. B\_T', 'w/o drift'}; % 转义下划线用于LaTeX
    num_groups = length(group_start_indices);

    if num_groups <= 1
        return; % 只有一个组时不需要额外说明
    end

    % 获取当前坐标轴的Y轴范围
    ylims = ylim(ax);
    y_range = ylims(2) - ylims(1);
    y_pos = ylims(1) - 0.1 * y_range; % 在Y轴最小值下方10%的位置

    for g = 1:num_groups
        group_center = group_start_indices(g) + (group_sizes(g) - 1) / 2;
        group_label = sprintf('%.1f', g * 0.5);

        if usePresetLegends && g <= length(preset_legend_names)
            group_desc = strrep(preset_legend_names{g}, '\_', '_'); % 移除LaTeX转义用于显示
            full_label = sprintf('%s\n(%s)', group_label, group_desc);
        else
            full_label = sprintf('%s\n(Group %d)', group_label, g);
        end

        % 添加组说明文本
        text(ax, group_center, y_pos, full_label, ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
             'FontSize', 10, 'Interpreter', 'none');
    end
end

function addGroupLegend(ax, groupDirs, group_colors_set, usePresetLegends)
% 添加分组图例
    num_groups = length(groupDirs);
    preset_legend_names = {'fav. B\_T', 'unfav. B\_T', 'w/o drift'}; % 转义下划线用于LaTeX

    legend_handles = [];
    legend_strings = {};

    for g = 1:num_groups
        % 创建虚拟的柱状图用于图例
        dummy_bar = bar(ax, NaN, NaN, 'FaceColor', group_colors_set(g, :), ...
                       'EdgeColor', 'k', 'LineWidth', 1.0);
        legend_handles(end+1) = dummy_bar;

        if usePresetLegends && g <= length(preset_legend_names)
            legend_strings{end+1} = sprintf('Group %d: %s', g, preset_legend_names{g});
        else
            legend_strings{end+1} = sprintf('Group %d', g);
        end
    end

    if ~isempty(legend_handles)
        % 限制图例条目数量，避免过多图例警告
        max_legend_entries = min(length(legend_handles), 6);
        leg = legend(legend_handles(1:max_legend_entries), legend_strings(1:max_legend_entries), ...
                    'Location', 'bestoutside', 'Interpreter', 'latex');
        set(leg, 'FontSize', 10);
        title(leg, 'Groups');
    end
end
