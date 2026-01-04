function plot_Hzeff_frad_vs_Zeff_split_figures_N(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends, use_auto_axis)
% =========================================================================
% plot_Hzeff_frad_vs_Zeff_split_figures_N - H(Zeff)和frad与Zeff关系分析（N系统）
% =========================================================================
%
% 功能描述：
%   仅输出2个独立figure，便于单栏/PPT排版，所有子图尺寸尽量统一。
%   - Fig1: 2个子图（上：frad vs Zeff_CEI-1；下：H(Zeff) vs Zeff_CEI-1）
%   - Fig2: 3个子图（上：frad,core；中：frad,SOL；下：frad,div）
%
% 输入：
%   - all_radiationData     : 包含所有SOLPS仿真数据的结构体数组
%   - groupDirs             : 包含分组目录信息的元胞数组
%   - usePresetLegends      : 是否使用预设图例名称（默认false）
%   - showLegendsForDirNames: 当使用目录名时是否显示图例（默认true）
%   - useHardcodedLegends   : 是否使用硬编码图例（默认true）
%   - use_auto_axis         : 是否使用自动坐标轴范围（默认false使用固定范围）
%
% 输出：
%   - Hzeff_frad_split_fig1_N_[timestamp].fig - frad与H(Zeff)子图
%   - Hzeff_frad_split_fig2_N_[timestamp].fig - 区域辐射分数子图
%
% 依赖函数/工具箱：
%   - 无必需工具箱
%
% 注意事项：
%   - R2019a 兼容（避免 arguments 块、tiledlayout 等新语法）
%   - N系统价态范围：N0到N7+（共8个价态），species索引3-10
%   - Zeff计算使用电子密度加权平均
%   - 所有子图横轴统一使用 Zeff,CEI - 1
%
% 适配说明（N vs Ne）：
%   - Ne系统：11个价态（Ne0到Ne10+），species索引3-13
%   - N系统：8个价态（N0到N7+），species索引3-10
%   - Zeff计算：sum(n_i * Z_i^2) / n_e，其中 Z_i = charge_state
% =========================================================================

%% 参数默认值设置
if nargin < 6 || isempty(use_auto_axis), use_auto_axis = false; end
if nargin < 5, useHardcodedLegends = true; end
if nargin < 4, showLegendsForDirNames = true; end
if nargin < 3, usePresetLegends = false; end

if use_auto_axis
    fprintf('\n=== Starting H(Zeff) and frad vs (Zeff_{CEI}-1) analysis (N system, AUTO axis) ===\n');
else
    fprintf('\n=== Starting H(Zeff) and frad vs (Zeff_{CEI}-1) analysis (N system, FIXED axis) ===\n');
end

%% 全局绘图属性设置
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultLegendFontName', 'Times New Roman');
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');

fontSize = 24;           % 坐标轴标签字体大小
tickFontSize = 18;       % 刻度字体大小
linewidth = 2;           % 连线宽度（保留参数接口）
markerSize = 120;        % 散点大小

%% Figure尺寸设置
fig_width = 5.8;          % figure宽度（英寸）
axes_height = 2.2;        % 单个子图高度（英寸）
top_margin = 0.55;        % figure顶部留白（英寸）
bottom_margin = 0.85;     % figure底部留白（英寸）
left_margin = 0.85;       % 左侧留白（英寸）
right_margin = 0.35;      % 右侧留白（英寸）
v_gap = 0.35;             % 子图之间的竖向间隔（英寸）

axes_width = fig_width - left_margin - right_margin;
fig_height_2subplot = top_margin + bottom_margin + axes_height * 2 + v_gap;
fig_height_3subplot = top_margin + bottom_margin + axes_height * 3 + 2 * v_gap;

%% 区域边界常量（EAST托卡马克网格）
CORE_INDICES_ORIGINAL = 26:73;
OUTER_DIV_RANGE = 1:24;
INNER_DIV_START = 73;
CORE_POL_RANGE = 25:72;
CORE_RAD_RANGE = 1:12;
SOL_RAD_START = 13;

%% 数据收集初始化
all_full_paths = {};
all_zeff_values = [];
all_hzeff_values = [];
all_frad_total_values = [];
all_frad_div_values = [];
all_frad_core_values = [];
all_frad_sol_values = [];

valid_cases = 0;

%% 遍历所有算例计算物理量
for i_case = 1:length(all_radiationData)
    radData = all_radiationData{i_case};
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    dirName = radData.dirName;
    
    % 检查数据完整性
    if ~isfield(plasma, 'ne') || ~isfield(plasma, 'na') || ~isfield(gmtry, 'vol') || ...
            ~isfield(plasma, 'fhe_mdf') || ~isfield(plasma, 'fhi_mdf')
        fprintf('Warning: Case %s missing required fields, skipping.\n', dirName);
        continue;
    end
    
    % 计算芯部体积
    core_vol = gmtry.vol(CORE_INDICES_ORIGINAL, 2);
    total_vol_core = sum(core_vol, 'omitnan');
    
    if total_vol_core == 0 || isnan(total_vol_core)
        fprintf('Warning: Case %s has zero core volume, skipping.\n', dirName);
        continue;
    end
    
    % --- 计算Zeff（电子密度加权平均） ---
    % D离子密度（species 1-2: D0, D+）
    nD = plasma.na(:,:,1:2);
    % N离子密度（species 3-10: N0, N1+, ..., N7+）
    nN = plasma.na(:,:,3:end);
    
    % D离子对Zeff的贡献（Z=1）
    Zeff_D = nD(:,:,2) * 1^2 ./ plasma.ne;
    
    % N离子对Zeff的贡献（N0到N7+，共8个价态）
    [nxd, nyd] = size(plasma.ne);
    Zeff_N = zeros(nxd, nyd);
    n_charge_states = min(8, size(nN, 3));
    for i_Z = 1:n_charge_states
        charge_state = i_Z - 1;
        Zeff_N = Zeff_N + nN(:,:,i_Z) * (charge_state^2) ./ plasma.ne;
    end
    
    % 总Zeff（D+ + N系统）
    Zeff_total = Zeff_D + Zeff_N;
    
    % 芯部边缘Zeff（电子密度加权）
    core_Zeff = Zeff_total(CORE_INDICES_ORIGINAL, 2);
    ne_core = plasma.ne(CORE_INDICES_ORIGINAL, 2);
    ne_vol_sum = sum(ne_core .* core_vol, 'omitnan');
    
    if ne_vol_sum == 0 || isnan(ne_vol_sum)
        average_Zeff = NaN;
    else
        Zeff_ne_vol_sum = sum(core_Zeff .* ne_core .* core_vol, 'omitnan');
        average_Zeff = Zeff_ne_vol_sum / ne_vol_sum;
    end
    
    % 计算总辐射功率 P_rad（MW）
    volcell = gmtry.vol(2:end-1, 2:end-1);
    
    % 线辐射功率密度
    linrad_ns = abs(plasma.rqrad(2:end-1, 2:end-1, :)) ./ volcell;
    linrad_D = sum(linrad_ns(:, :, 1:2), 3);
    linrad_N = sum(linrad_ns(:, :, 3:end), 3);
    
    % 韧致辐射功率密度
    brmrad_ns = abs(plasma.rqbrm(2:end-1, 2:end-1, :)) ./ volcell;
    brmrad_D = sum(brmrad_ns(:, :, 1:2), 3);
    brmrad_N = sum(brmrad_ns(:, :, 3:end), 3);
    
    % 中性粒子辐射功率密度
    neut = radData.neut;
    neurad_D = abs(neut.eneutrad(:, :, 1)) ./ volcell;
    neurad_N = abs(neut.eneutrad(:, :, 2)) ./ volcell;
    
    % 分子和离子辐射功率密度（仅D）
    molrad_D = abs(neut.emolrad(:, :)) ./ volcell;
    ionrad_D = abs(neut.eionrad(:, :)) ./ volcell;
    
    % 总辐射功率密度
    totrad_D = linrad_D + brmrad_D + neurad_D + molrad_D + ionrad_D;
    totrad_N = linrad_N + brmrad_N + neurad_N;
    totrad_total = totrad_D + totrad_N;
    
    % 总辐射功率（W -> MW）
    P_rad = sum(sum(totrad_total .* volcell)) * 1e-6;
    
    % --- 计算总输入功率 P_tot（MW） ---
    % 从芯部边界的热流计算
    P_tot = sum(plasma.fhe_mdf(CORE_INDICES_ORIGINAL, 2, 2) + ...
        plasma.fhi_mdf(CORE_INDICES_ORIGINAL, 2, 2), 'omitnan');
    P_tot = P_tot / 1e6;  % W -> MW
    
    % --- 计算辐射效率 H(Zeff) ---
    % H(Zeff) = P_rad / (P_tot * (Zeff - 1))，无量纲
    if average_Zeff > 1 && P_tot > 0 && ~isnan(P_tot)
        hzeff_value = P_rad / (P_tot * (average_Zeff - 1));
    else
        hzeff_value = NaN;
    end
    
    % --- 计算总辐射分数 frad = P_rad / P_tot ---
    if P_tot > 0 && ~isnan(P_tot)
        frad_total = P_rad / P_tot;
    else
        frad_total = NaN;
    end
    
    % --- 计算各区域辐射分数 ---
    [nx_trimmed, ny_trimmed] = size(totrad_total);
    
    % 偏滤器区域辐射功率（外偏滤器 + 内偏滤器）
    index_div = [OUTER_DIV_RANGE, INNER_DIV_START:nx_trimmed];
    if max(index_div) <= nx_trimmed
        P_rad_div = sum(sum(totrad_total(index_div,:) .* volcell(index_div,:))) * 1e-6;
    else
        P_rad_div = NaN;
    end
    
    % 芯部区域辐射功率（极向25-72，径向1-12，分离面内侧）
    if max(CORE_POL_RANGE) <= nx_trimmed && max(CORE_RAD_RANGE) <= ny_trimmed
        P_rad_core = sum(sum(totrad_total(CORE_POL_RANGE, CORE_RAD_RANGE) .* ...
            volcell(CORE_POL_RANGE, CORE_RAD_RANGE))) * 1e-6;
    else
        P_rad_core = NaN;
    end
    
    % SOL区域辐射功率（极向25-72，径向13-26，分离面外侧）
    sol_rad_range = SOL_RAD_START:ny_trimmed;
    if max(CORE_POL_RANGE) <= nx_trimmed && max(sol_rad_range) <= ny_trimmed
        P_rad_sol = sum(sum(totrad_total(CORE_POL_RANGE, sol_rad_range) .* ...
            volcell(CORE_POL_RANGE, sol_rad_range))) * 1e-6;
    else
        P_rad_sol = NaN;
    end
    
    % 各区域辐射分数（相对于总辐射功率）
    frad_div = P_rad_div / P_rad;
    frad_core = P_rad_core / P_rad;
    frad_sol = P_rad_sol / P_rad;
    
    % --- 存储数据 ---
    valid_cases = valid_cases + 1;
    all_full_paths{end+1} = dirName; %#ok<AGROW>
    all_zeff_values(end+1) = average_Zeff; %#ok<AGROW>
    all_hzeff_values(end+1) = hzeff_value; %#ok<AGROW>
    all_frad_total_values(end+1) = frad_total; %#ok<AGROW>
    all_frad_div_values(end+1) = frad_div; %#ok<AGROW>
    all_frad_core_values(end+1) = frad_core; %#ok<AGROW>
    all_frad_sol_values(end+1) = frad_sol; %#ok<AGROW>
    
    fprintf('Processed %s: Zeff=%.2f, H=%.2f, frad=%.2f\n', ...
        dirName, average_Zeff, hzeff_value, frad_total);
end

fprintf('Successfully processed %d cases.\n', valid_cases);

if valid_cases == 0
    warning('plot_Hzeff_frad_vs_Zeff_split_figures_N:NoCases', ...
        'No valid cases processed. Exiting.');
    return;
end

%% 分组分配
num_groups = length(groupDirs);
if num_groups == 0
    num_groups = 1;
    groupDirs = {all_full_paths};
end

group_assignments = assign_groups(all_full_paths, groupDirs, num_groups);

% Zeff-1 作为横轴
zeff_minus_1 = all_zeff_values - 1;

%% 坐标轴范围设置
if use_auto_axis
    % 自动模式：根据数据计算"漂亮"的坐标轴范围
    [x_lim, x_ticks] = compute_nice_axis_range(zeff_minus_1);
    [y_lim_frad, y_ticks_frad] = compute_nice_axis_range(all_frad_total_values);
    [y_lim_H, y_ticks_H] = compute_nice_axis_range(all_hzeff_values);
    [y_lim_frad_core, y_ticks_frad_core] = compute_nice_axis_range(all_frad_core_values);
    [y_lim_frad_sol, y_ticks_frad_sol] = compute_nice_axis_range(all_frad_sol_values);
    [y_lim_frad_div, y_ticks_frad_div] = compute_nice_axis_range(all_frad_div_values);
    
    fprintf('Auto axis mode: X=[%.2f, %.2f], frad=[%.2f, %.2f], H=[%.2f, %.2f]\n', ...
        x_lim(1), x_lim(2), y_lim_frad(1), y_lim_frad(2), y_lim_H(1), y_lim_H(2));
else
    % 固定模式：使用预设范围（针对N系统优化）
    x_lim = [0, 2];
    x_ticks = 0:0.5:2;
    y_lim_frad = [0, 0.6];
    y_ticks_frad = 0:0.2:0.6;
    y_lim_H = [0, 6];
    y_ticks_H = 0:2:6;
    y_lim_frad_core = [0, 0.2];
    y_ticks_frad_core = 0:0.05:0.2;
    y_lim_frad_sol = [0, 0.4];
    y_ticks_frad_sol = 0:0.1:0.4;
    y_lim_frad_div = [0.4, 1.0];
    y_ticks_frad_div = 0.4:0.2:1.0;
end

%% 绘制Fig1：frad与H(Zeff)（2个子图）
fig1 = figure('Name', 'frad and H vs Zeff_{CEI}-1 (N system)', 'NumberTitle', 'off', ...
    'Color', 'w', 'Units', 'inches', 'Position', [1, 1, fig_width, fig_height_2subplot]);

ax1_top = axes('Parent', fig1, 'Units', 'inches', ...
    'Position', [left_margin, bottom_margin + axes_height + v_gap, axes_width, axes_height]);
ax1_bottom = axes('Parent', fig1, 'Units', 'inches', ...
    'Position', [left_margin, bottom_margin, axes_width, axes_height]);

% 上子图: frad vs Zeff-1
plot_scatter(ax1_top, zeff_minus_1, all_frad_total_values, group_assignments, num_groups, ...
    '', '$f_{\mathrm{rad}}$', fontSize, tickFontSize, markerSize, linewidth, all_full_paths);
set(ax1_top, 'YLim', y_lim_frad, 'YTick', y_ticks_frad);
set(ax1_top, 'XLim', x_lim, 'XTick', x_ticks, 'XTickLabel', []);

% 下子图: H(Zeff) vs Zeff-1
plot_scatter(ax1_bottom, zeff_minus_1, all_hzeff_values, group_assignments, num_groups, ...
    '$Z_{\mathrm{eff, CEI}} - 1$', '$H$', fontSize, tickFontSize, markerSize, linewidth, all_full_paths);
set(ax1_bottom, 'YLim', y_lim_H, 'YTick', y_ticks_H);
set(ax1_bottom, 'XLim', x_lim, 'XTick', x_ticks);

linkaxes([ax1_top, ax1_bottom], 'x');

save_figure_with_timestamp(fig1, 'Hzeff_frad_split_fig1_N');

%% 绘制Fig2：区域辐射分数（3个子图）
fig2 = figure('Name', 'frad regional vs Zeff_{CEI}-1 (N system)', 'NumberTitle', 'off', ...
    'Color', 'w', 'Units', 'inches', 'Position', [1, 1, fig_width, fig_height_3subplot]);

ax2_top = axes('Parent', fig2, 'Units', 'inches', ...
    'Position', [left_margin, bottom_margin + 2 * (axes_height + v_gap), axes_width, axes_height]);
ax2_mid = axes('Parent', fig2, 'Units', 'inches', ...
    'Position', [left_margin, bottom_margin + axes_height + v_gap, axes_width, axes_height]);
ax2_bottom = axes('Parent', fig2, 'Units', 'inches', ...
    'Position', [left_margin, bottom_margin, axes_width, axes_height]);

% 上：frad,core
plot_scatter(ax2_top, zeff_minus_1, all_frad_core_values, group_assignments, num_groups, ...
    '', '$f_{\mathrm{rad,core}}$', fontSize, tickFontSize, markerSize, linewidth, all_full_paths);
set(ax2_top, 'YLim', y_lim_frad_core, 'YTick', y_ticks_frad_core);
set(ax2_top, 'XLim', x_lim, 'XTick', x_ticks, 'XTickLabel', []);

% 中：frad,SOL
plot_scatter(ax2_mid, zeff_minus_1, all_frad_sol_values, group_assignments, num_groups, ...
    '', '$f_{\mathrm{rad,SOL}}$', fontSize, tickFontSize, markerSize, linewidth, all_full_paths);
set(ax2_mid, 'YLim', y_lim_frad_sol, 'YTick', y_ticks_frad_sol);
set(ax2_mid, 'XLim', x_lim, 'XTick', x_ticks, 'XTickLabel', []);

% 下：frad,div
plot_scatter(ax2_bottom, zeff_minus_1, all_frad_div_values, group_assignments, num_groups, ...
    '$Z_{\mathrm{eff, CEI}} - 1$', '$f_{\mathrm{rad,div}}$', fontSize, tickFontSize, markerSize, linewidth, all_full_paths);
set(ax2_bottom, 'YLim', y_lim_frad_div, 'YTick', y_ticks_frad_div);
set(ax2_bottom, 'XLim', x_lim, 'XTick', x_ticks);

linkaxes([ax2_top, ax2_mid, ax2_bottom], 'x');

save_figure_with_timestamp(fig2, 'Hzeff_frad_split_fig2_N');

%% 完成提示
fprintf('\n=== Analysis completed (N system) ===\n');
fprintf('Generated figures:\n');
fprintf('  - Fig1: frad and H(Zeff) vs Zeff_{CEI}-1\n');
fprintf('  - Fig2: frad,core / frad,SOL / frad,div vs Zeff_{CEI}-1\n');
if use_auto_axis
    fprintf('  (Auto axis mode enabled)\n');
else
    fprintf('  (Fixed axis mode)\n');
end

end


%% =========================================================================
% 辅助函数
% =========================================================================

function [axis_lim, axis_ticks] = compute_nice_axis_range(data)
% 计算"漂亮"的坐标轴范围，确保首尾有明确数值
%
% 输入：data - 数据向量
% 输出：axis_lim - [min, max] 坐标轴范围
%       axis_ticks - 刻度值向量

% 过滤NaN和Inf
valid_data = data(isfinite(data));
if isempty(valid_data)
    axis_lim = [0, 1];
    axis_ticks = 0:0.2:1;
    return;
end

data_min = min(valid_data);
data_max = max(valid_data);
data_range = data_max - data_min;

if data_range == 0
    % 数据无变化，扩展范围
    data_range = abs(data_min) * 0.2;
    if data_range == 0
        data_range = 1;
    end
end

% 计算"漂亮"的刻度间隔（1, 2, 5序列的倍数）
raw_interval = data_range / 4;  % 目标约4-6个刻度
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

% 计算边界（向外扩展到"漂亮"的值）
nice_min = floor(data_min / nice_interval) * nice_interval;
nice_max = ceil(data_max / nice_interval) * nice_interval;

% 确保不会过度收缩
if nice_min > data_min - nice_interval * 0.1
    nice_min = nice_min - nice_interval;
end
if nice_max < data_max + nice_interval * 0.1
    nice_max = nice_max + nice_interval;
end

% 如果最小值接近0且为正，则从0开始
if nice_min > 0 && nice_min < nice_interval
    nice_min = 0;
end

axis_lim = [nice_min, nice_max];
axis_ticks = nice_min:nice_interval:nice_max;

% 确保刻度数量合理（4-8个）
if length(axis_ticks) > 8
    new_interval = nice_interval * 2;
    axis_ticks = nice_min:new_interval:nice_max;
elseif length(axis_ticks) < 4
    new_interval = nice_interval / 2;
    axis_ticks = nice_min:new_interval:nice_max;
end
end


function group_assignments = assign_groups(full_paths, groupDirs, num_groups)
% 将算例分配到对应的组

num_cases = length(full_paths);
group_assignments = zeros(num_cases, 1);

for i_data = 1:num_cases
    current_path = full_paths{i_data};
    for i_group = 1:num_groups
        if any(strcmp(current_path, groupDirs{i_group}))
            group_assignments(i_data) = i_group;
            break;
        end
    end
end
end


function plot_scatter(ax, x_values, y_values, group_assignments, num_groups, ...
    xlabel_text, ylabel_text, fontSize, tickFontSize, markerSize, ~, full_paths)
% 绘制散点子图

axes(ax);
hold on;

fav_color = [0, 0, 1];
unfav_color = [1, 0, 0];
markers = {'o', 's', 'd', '^'};

for i_group = 1:min(8, num_groups)
    mask = (group_assignments == i_group);
    if ~any(mask)
        continue;
    end
    
    g_x = x_values(mask);
    g_y = y_values(mask);
    
    if i_group <= 4
        col = fav_color;
        mk_idx = i_group;
    else
        col = unfav_color;
        mk_idx = i_group - 4;
    end
    
    if nargin >= 12 && ~isempty(full_paths)
        group_paths = full_paths(mask);
    else
        group_paths = {};
    end
    
    for i_pt = 1:length(g_x)
        h_scatter = scatter(g_x(i_pt), g_y(i_pt), markerSize, col, markers{mk_idx}, ...
            'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1.0);
        if ~isempty(group_paths) && i_pt <= length(group_paths)
            set(h_scatter, 'UserData', group_paths{i_pt});
        end
    end
end

if ~isempty(xlabel_text)
    xlabel(xlabel_text, 'FontSize', fontSize, 'Interpreter', 'latex');
end
ylabel(ylabel_text, 'FontSize', fontSize, 'Interpreter', 'latex');

grid on;
box on;
set(ax, 'FontSize', tickFontSize, 'LineWidth', 1.5, 'TickDir', 'in', ...
    'GridLineStyle', '--', 'GridAlpha', 0.5);

fig = ancestor(ax, 'figure');
dcm = datacursormode(fig);
set(dcm, 'Enable', 'on');
set(dcm, 'UpdateFcn', @local_datacursor_callback);
end


function save_figure_with_timestamp(fig, baseName)
% 保存图形文件并添加时间戳

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
filename = sprintf('%s_%s.fig', baseName, timestamp);

try
    savefig(fig, filename);
    fprintf('Figure saved: %s\n', filename);
catch ME
    warning('plot_Hzeff_frad_vs_Zeff_split_figures_N:SaveFigureFail', ...
        'Failed to save figure: %s', ME.message);
end
end


function txt = local_datacursor_callback(~, event_obj)
% 数据游标回调函数

pos = get(event_obj, 'Position');
x_val = pos(1);
y_val = pos(2);

target = get(event_obj, 'Target');
case_path = get(target, 'UserData');

txt = {sprintf('X: %.4f', x_val), sprintf('Y: %.4f', y_val)};

if ~isempty(case_path) && ischar(case_path)
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
