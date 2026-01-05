function plot_core_edge_total_and_N_highcharge_Zeff_comparison(all_radiationData, groupDirs, use_auto_axis)
% =========================================================================
% plot_core_edge_total_and_N_highcharge_Zeff_comparison - 芯部边界Zeff分析
% =========================================================================
%
% 功能描述：
%   - 左子图：总Zeff（电子数加权极向平均，CEI处）
%   - 右子图：各物种对Zeff的贡献（堆叠柱状图：D+ + N1+~N7+）
%   - 两图柱高一致，Y轴范围相同
%
% 输入：
%   - all_radiationData : 仿真数据cell数组
%   - groupDirs         : 分组目录cell数组
%   - use_auto_axis     : 是否使用自动Y轴范围（默认false使用固定范围）
%
% 注意事项：
%   - R2019a兼容
%   - N系统：D+(索引2)，N0(索引3)，N1+~N7+(索引4-10)
%   - Zeff采用电子数加权极向平均：sum(Zeff * ne * vol) / sum(ne * vol)
% =========================================================================

%% 参数默认值
if nargin < 3 || isempty(use_auto_axis), use_auto_axis = false; end

if use_auto_axis
    fprintf('\n=== Core edge Zeff analysis (AUTO axis) ===\n');
else
    fprintf('\n=== Core edge Zeff analysis (FIXED axis) ===\n');
end

%% 全局绘图属性
fontSize = 36;
tickFontSize = 30;
legendFontSize = 20;

%% 区域常量（EAST 98x28网格）
CORE_INDICES = 26:73;           % 芯部极向索引
CORE_EDGE_RADIAL_INDEX = 2;     % 芯部边界径向索引
MAIN_ION_SPECIES_INDEX = 2;     % D+的species索引
IMPURITY_START_INDEX = 3;       % N0的起始species索引
N_CHARGE_STATES = 7;            % N系统带电价态数量（N1+到N7+）
NUM_SPECIES_IN_STACK = 8;       % 堆叠柱中的物种数（D+ + N1+~N7+）

%% 数据收集初始化
all_full_paths = {};
all_total_zeff_values = [];
% Zeff贡献矩阵：行=物种(D+, N1+, N2+, ..., N7+)，列=算例
all_zeff_contributions = [];

valid_cases = 0;

%% 遍历所有算例计算Zeff
for i_case = 1:numel(all_radiationData)
    radData = all_radiationData{i_case};
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    dirName = radData.dirName;
    
    fprintf('Processing: %s\n', dirName);
    
    % --- 数据完整性检查 ---
    if ~isfield(plasma, 'na') || ~isfield(plasma, 'ne') || ~isfield(gmtry, 'vol')
        fprintf('Warning: Missing data fields. Skipping.\n');
        continue;
    end
    
    % --- 网格尺寸检查 ---
    [nx_orig, ~] = size(gmtry.crx(:,:,1));
    if max(CORE_INDICES) > nx_orig
        fprintf('Warning: Invalid grid indices. Skipping.\n');
        continue;
    end
    
    % --- 避免除零 ---
    safe_ne = max(plasma.ne, 1e-10);
    
    % --- 提取芯部边界数据 ---
    core_vol = gmtry.vol(CORE_INDICES, CORE_EDGE_RADIAL_INDEX);
    core_ne = safe_ne(CORE_INDICES, CORE_EDGE_RADIAL_INDEX);
    
    % 计算电子数加权因子
    ne_vol = core_ne .* core_vol;
    ne_vol_sum = sum(ne_vol, 'omitnan');
    
    if ne_vol_sum <= 0
        fprintf('Warning: Zero electron density sum. Skipping.\n');
        continue;
    end
    
    % --- 各物种对Zeff的贡献（电子数加权极向平均） ---
    % zeff_by_species(1) = D+, zeff_by_species(2:8) = N1+ to N7+
    zeff_by_species = zeros(NUM_SPECIES_IN_STACK, 1);
    
    % D+的贡献（Z=1，所以Z^2=1）
    nD_plus_core = plasma.na(CORE_INDICES, CORE_EDGE_RADIAL_INDEX, MAIN_ION_SPECIES_INDEX);
    Zeff_D_core = nD_plus_core ./ core_ne;  % Z^2 = 1
    zeff_by_species(1) = sum(Zeff_D_core .* ne_vol, 'omitnan') / ne_vol_sum;
    
    % N1+到N7+的贡献
    for i_charge = 1:N_CHARGE_STATES
        % N(i)+对应的species索引 = IMPURITY_START_INDEX + i_charge
        species_idx = IMPURITY_START_INDEX + i_charge;
        
        if species_idx <= size(plasma.na, 3)
            n_ion_core = plasma.na(CORE_INDICES, CORE_EDGE_RADIAL_INDEX, species_idx);
            charge = i_charge;
            
            % Zeff贡献 = n_ion * Z^2 / n_e
            Zeff_contrib_core = n_ion_core * (charge^2) ./ core_ne;
            
            % 电子数加权极向平均
            zeff_by_species(1 + i_charge) = sum(Zeff_contrib_core .* ne_vol, 'omitnan') / ne_vol_sum;
        else
            zeff_by_species(1 + i_charge) = 0;
        end
    end
    
    % --- 总Zeff（所有物种贡献之和） ---
    total_zeff_avg = sum(zeff_by_species);
    
    % --- 存储数据 ---
    valid_cases = valid_cases + 1;
    all_full_paths{end+1} = dirName; %#ok<AGROW>
    all_total_zeff_values(end+1) = total_zeff_avg; %#ok<AGROW>
    all_zeff_contributions(:, end+1) = zeff_by_species; %#ok<AGROW>
    
    fprintf('  Total Zeff: %.4f (D+: %.4f, N ions: %.4f)\n', ...
        total_zeff_avg, zeff_by_species(1), sum(zeff_by_species(2:end)));
end

fprintf('Processed %d cases.\n', valid_cases);

if valid_cases == 0
    warning('plot_core_edge_total_and_N_highcharge_Zeff_comparison:NoCases', ...
        'No valid cases processed. Exiting.');
    return;
end

%% 分组信息
num_groups = length(groupDirs);
if num_groups == 0
    num_groups = 1;
    groupDirs = {all_full_paths};
end

%% 分配算例到组
num_cases = length(all_full_paths);
bar_colors = zeros(num_cases, 3);
group_colors_set = lines(max(num_groups, 1));

for i_data = 1:num_cases
    current_full_path = all_full_paths{i_data};
    group_index = 0;
    for i_group = 1:num_groups
        if any(strcmp(current_full_path, groupDirs{i_group}))
            group_index = i_group;
            break;
        end
    end
    if group_index > 0
        bar_colors(i_data, :) = group_colors_set(group_index, :);
    else
        bar_colors(i_data, :) = [0.5, 0.5, 0.5];
    end
end

%% 计算X轴位置（组间有间隔）
group_gap = 0.5;
x_positions = zeros(1, num_cases);
case_counter = 0;
current_x = 1;

for g = 1:num_groups
    num_cases_in_group = length(groupDirs{g});
    for k = 1:num_cases_in_group
        case_counter = case_counter + 1;
        x_positions(case_counter) = current_x;
        current_x = current_x + 1;
    end
    if g < num_groups
        current_x = current_x + group_gap;
    end
end

% 组中心用于X轴标签
group_centers = zeros(num_groups, 1);
case_counter = 0;
for g = 1:num_groups
    num_cases_in_group = length(groupDirs{g});
    group_start_idx = case_counter + 1;
    group_end_idx = case_counter + num_cases_in_group;
    group_centers(g) = mean(x_positions(group_start_idx:group_end_idx));
    case_counter = case_counter + num_cases_in_group;
end

%% Y轴范围（两图使用相同范围）
if use_auto_axis
    [y_lim, ~] = compute_nice_axis_range_nonneg(all_total_zeff_values);
else
    y_lim = [0, 3];
end

%% 创建Figure
fig = figure('Name', 'Core Edge Zeff Analysis (N system)', ...
    'NumberTitle', 'off', 'Color', 'w', ...
    'Units', 'inches', 'Position', [1, 0.5, 18, 8]);

set(fig, 'DefaultTextInterpreter', 'latex', ...
    'DefaultAxesTickLabelInterpreter', 'latex', ...
    'DefaultLegendInterpreter', 'latex');

% X轴标签（N充气速率：0.5, 1.0, 1.5, 2.0...）
puff_rate_labels = cell(num_groups, 1);
for g = 1:num_groups
    puff_rate_labels{g} = sprintf('%.1f', 0.5 * g);
end

%% 左子图：总Zeff（分组柱状图）
ax1 = subplot(1, 2, 1);

if ~isempty(all_total_zeff_values)
    bh1 = bar(x_positions, all_total_zeff_values, 0.8, 'FaceColor', 'flat');
    bh1.CData = bar_colors;
    set(bh1, 'UserData', all_full_paths);
    
    xticks(group_centers);
    xticklabels(puff_rate_labels);
    
    xlabel('$\Gamma_{\mathrm{puff,N}}$ ($\times 10^{20}$ s$^{-1}$)', 'FontSize', fontSize);
    ylabel('$Z_{\mathrm{eff,CEI}}$', 'FontSize', fontSize);
    ylim(y_lim);
    xlim([min(x_positions) - 0.5, max(x_positions) + 0.5]);
    
    grid on; box on;
    set(ax1, 'TickDir', 'in', 'FontSize', tickFontSize, 'FontName', 'Times New Roman');
    
    % --- 左图图例：分组颜色 ---
    if num_groups > 1
        hold on;
        legend_handles_left = gobjects(num_groups, 1);
        legend_labels_left = cell(num_groups, 1);
        for i_group = 1:num_groups
            legend_handles_left(i_group) = patch(NaN, NaN, group_colors_set(i_group, :), ...
                'EdgeColor', 'none');
            legend_labels_left{i_group} = sprintf('Group %d', i_group);
        end
        hold off;
        legend(legend_handles_left, legend_labels_left, 'Location', 'best', 'FontSize', legendFontSize);
    end
end

%% 右子图：各物种Zeff贡献（堆叠柱状图）
ax2 = subplot(1, 2, 2);

% 定义各物种颜色：D+ + N1+~N7+
species_colors = [
    0.3, 0.3, 0.3;  % D+ - 深灰
    0.85, 0.85, 0.85;  % N1+ - 浅灰
    0.7, 0.7, 0.7;  % N2+ - 中灰
    0.4, 0.8, 0.4;  % N3+ - 浅绿
    0.2, 0.6, 0.2;  % N4+ - 深绿
    0.4, 0.6, 0.9;  % N5+ - 浅蓝
    0.2, 0.4, 0.8;  % N6+ - 蓝
    0.8, 0.2, 0.2   % N7+ - 红
    ];

if ~isempty(all_zeff_contributions)
    % 堆叠柱状图：行=物种，列=算例 → 需转置
    bh2 = bar(x_positions, all_zeff_contributions', 0.8, 'stacked');
    
    % 设置每个物种的颜色
    for i_species = 1:NUM_SPECIES_IN_STACK
        bh2(i_species).FaceColor = species_colors(i_species, :);
        bh2(i_species).EdgeColor = 'k';
        bh2(i_species).LineWidth = 0.5;
    end
    
    % 存储路径供数据游标使用
    set(bh2(1), 'UserData', all_full_paths);
    
    xticks(group_centers);
    xticklabels(puff_rate_labels);
    
    xlabel('$\Gamma_{\mathrm{puff,N}}$ ($\times 10^{20}$ s$^{-1}$)', 'FontSize', fontSize);
    ylabel('$Z_{\mathrm{eff,CEI}}$ by Species', 'FontSize', fontSize);
    ylim(y_lim);
    xlim([min(x_positions) - 0.5, max(x_positions) + 0.5]);
    
    grid on; box on;
    set(ax2, 'TickDir', 'in', 'FontSize', tickFontSize, 'FontName', 'Times New Roman');
    
    % --- 图例：各物种 ---
    species_labels = {'$D^+$', '$N^{1+}$', '$N^{2+}$', '$N^{3+}$', '$N^{4+}$', '$N^{5+}$', '$N^{6+}$', '$N^{7+}$'};
    legend(bh2, species_labels, 'Location', 'best', 'FontSize', legendFontSize);
end

%% 设置数据游标回调
dcm = datacursormode(fig);
set(dcm, 'Enable', 'on');
set(dcm, 'UpdateFcn', @bar_datacursor_callback);

%% 保存Figure
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
fname = sprintf('CoreEdge_Zeff_Breakdown_%s.fig', timestamp);
try
    savefig(fname);
    fprintf('Figure saved as %s\n', fname);
catch ME
    warning('SaveFigureFail:IO', 'Failed to save: %s', ME.message);
end

fprintf('\n=== Zeff analysis completed ===\n');

end


%% =========================================================================
% 辅助函数：计算非负范围的坐标轴
% =========================================================================
function [axis_lim, axis_ticks] = compute_nice_axis_range_nonneg(data)
valid_data = data(isfinite(data));
if isempty(valid_data) || max(valid_data) <= 0
    axis_lim = [0, 1];
    axis_ticks = 0:0.2:1;
    return;
end

data_max = max(valid_data);
raw_interval = data_max / 4;
magnitude = 10^floor(log10(raw_interval));
normalized = raw_interval / magnitude;

if normalized <= 1
    nice_interval = 1 * magnitude;
elseif normalized <= 2
    nice_interval = 2 * magnitude;
elseif normalized <= 5
    nice_interval = 5 * magnitude;
else
    nice_interval = 10 * magnitude;
end

nice_max = ceil(data_max / nice_interval) * nice_interval;
if nice_max < data_max * 1.05
    nice_max = nice_max + nice_interval;
end

axis_lim = [0, nice_max];
axis_ticks = 0:nice_interval:nice_max;

if length(axis_ticks) > 8
    new_interval = nice_interval * 2;
    axis_ticks = 0:new_interval:nice_max;
end
end


%% =========================================================================
% 辅助函数：数据游标回调
% =========================================================================
function txt = bar_datacursor_callback(~, event_obj)
pos = get(event_obj, 'Position');
x_val = pos(1);
y_val = pos(2);

target = get(event_obj, 'Target');
all_paths = get(target, 'UserData');

txt = {sprintf('X: %.1f', x_val), sprintf('Value: %.4f', y_val)};

if ~isempty(all_paths) && iscell(all_paths)
    bar_index = round(x_val);
    if bar_index >= 1 && bar_index <= length(all_paths)
        case_path = all_paths{bar_index};
        txt{end+1} = '---Path---';
        
        max_chars = 50;
        if ispc
            sep = '\';
        else
            sep = '/';
        end
        parts = strsplit(case_path, sep);
        
        current_line = '';
        for i = 1:length(parts)
            if isempty(parts{i}), continue; end
            if isempty(current_line)
                current_line = parts{i};
            else
                next_line = [current_line, sep, parts{i}];
                if length(next_line) > max_chars
                    txt{end+1} = strrep(current_line, '_', '\_'); %#ok<AGROW>
                    current_line = parts{i};
                else
                    current_line = next_line;
                end
            end
        end
        if ~isempty(current_line)
            txt{end+1} = strrep(current_line, '_', '\_');
        end
    end
end
end
