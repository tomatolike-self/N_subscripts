function plot_impurity_charge_state_density_and_flow_pattern_log_scale_N(all_radiationData, varargin)
% =========================================================================
% plot_impurity_charge_state_density_and_flow_pattern_log_scale_N - N杂质离子密度分布+流型图
% =========================================================================
%
% 功能描述：
%   - 绘制N各价态离子密度分布（背景色图）和粒子流模式（箭头）
%   - 箭头长度采用分段幂律映射：阈值1e19，高通量幂律，低通量线性
%   - 支持三种绘制模式：总密度/逐个价态/指定价态
%
% 输入：
%   all_radiationData - cell数组，包含SOLPS算例数据（需含dirName/gmtry/plasma字段）
%   varargin - 可选参数（通过inputParser解析）：
%     'mode'                  - 绘制模式：'total'/'all_charge_states'/'specific_charge_state'
%     'charge_state'          - 指定价态（1-7），默认5
%     'selected_charge_states'- 价态范围，默认1:7
%     'use_custom_colormap'   - 是否使用mycontour.mat色表，默认false
%     'clim_range'            - colorbar范围[min,max]，空则自动
%     'flux_scale_position'   - 图例位置，默认'top-right'
%
% 输出：
%   - 每个算例生成figure并保存为.fig文件
%
% 使用示例：
%   plot_impurity_charge_state_density_and_flow_pattern_log_scale_N(all_radiationData)
%   plot_impurity_charge_state_density_and_flow_pattern_log_scale_N(all_radiationData, 'mode', 'total')
%
% 依赖函数/工具箱：
%   - 无必需工具箱
%   - 可选：mycontour.mat（自定义色表）
%
% 注意事项：
%   - R2019a兼容（无arguments块/tiledlayout）
%   - N体系：物种索引4-10对应N1+到N7+（与Ne版本4-13不同）
%   - 本文件包含3个辅助函数：draw_segmented_arrows（绘制分段箭头）、setup_figure_axes
%     （设置坐标轴和区域标签）、compute_colorbar_ticks（计算色标刻度）；
%     拆分的唯一理由：这三处逻辑均超过30行且被多次调用，内联会显著降低可读性
% =========================================================================

%% 解析输入参数
p = inputParser;
% mode：绘制模式
addParameter(p, 'mode', 'all_charge_states', @(x) ismember(x, {'total', 'all_charge_states', 'specific_charge_state'}));
% charge_state：指定某一价态时使用，N体系范围1-7
addParameter(p, 'charge_state', 5, @(x) isnumeric(x) && x >= 1 && x <= 7);
% selected_charge_states：处理的价态范围，默认1-7（N1+到N7+）
addParameter(p, 'selected_charge_states', 1:7, @(x) isnumeric(x));
% use_custom_colormap：是否使用自制colormap
addParameter(p, 'use_custom_colormap', false, @(x) islogical(x));
% clim_range：colorbar范围，空表示使用默认值
addParameter(p, 'clim_range', [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2 && x(1) < x(2)));
% flux_scale_position：通量比例尺图例位置
addParameter(p, 'flux_scale_position', 'top-right', @(x) ischar(x) || isstring(x));
parse(p, varargin{:});

plot_mode = p.Results.mode;
specific_charge_state = p.Results.charge_state;
use_custom_colormap = p.Results.use_custom_colormap;
clim_range = p.Results.clim_range;

% --- 归一化价态列表：限定在1-7范围（N体系）并按升序输出 ---
raw_states = p.Results.selected_charge_states;
selected_charge_states = unique(round(raw_states(:)'));
selected_charge_states = selected_charge_states(selected_charge_states >= 1 & selected_charge_states <= 7);
if isempty(selected_charge_states)
    selected_charge_states = 1:7;  % 默认：N1+到N7+
end

% --- 归一化图例位置输入 ---
flux_pos_input = lower(strtrim(char(p.Results.flux_scale_position)));
flux_pos_input = strrep(strrep(flux_pos_input, '_', '-'), ' ', '-');
valid_positions = {'top-right', 'top-left', 'bottom-left', 'bottom-right', 'none'};
if any(strcmp(flux_pos_input, valid_positions))
    flux_scale_position = flux_pos_input;
else
    flux_scale_position = 'top-right';  % 默认右上角
end

%% 全局字体和绘图属性设置
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 30);
set(0, 'DefaultTextFontSize', 30);
set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'DefaultLegendFontSize', 28);
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

%% 遍历所有算例
for i_case = 1:length(all_radiationData)
    radData = all_radiationData{i_case};
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    dirName = radData.dirName;
    
    fprintf('Processing case for N impurity density and flow patterns (log scale): %s\n', dirName);
    
    % --- 获取原始网格维度 ---
    % 优先使用crx，其次cry；两者都不存在则跳过
    if isfield(gmtry, 'crx')
        s = size(gmtry.crx);
        nx_orig = s(1);
        ny_orig = s(2);
    elseif isfield(gmtry, 'cry')
        s = size(gmtry.cry);
        nx_orig = s(1);
        ny_orig = s(2);
    else
        warning('Grid coordinate fields (crx/cry) not found for case %s. Skipping.', dirName);
        continue;
    end
    
    if nx_orig < 3 || ny_orig < 3
        warning('Grid dimensions too small for case %s. Skipping.', dirName);
        continue;
    end
    
    % --- 计算用于绘图的网格维度（去除保护单元）---
    nx_plot = nx_orig - 2;
    ny_plot = ny_orig - 2;
    
    if nx_plot <= 0 || ny_plot <= 0
        warning('Plotting grid dimensions invalid for case %s. Skipping.', dirName);
        continue;
    end
    
    % --- N体系物种索引：4-10对应N1+到N7+ ---
    min_species_idx = 4;
    
    % --- 根据绘制模式确定要处理的价态范围 ---
    switch plot_mode
        case 'total'
            % 模式1：绘制总密度+总通量
            process_total_pattern(radData, nx_orig, ny_orig, nx_plot, ny_plot, min_species_idx, ...
                selected_charge_states, use_custom_colormap, clim_range, flux_scale_position);
            
        case 'all_charge_states'
            % 模式2：逐个绘制选定的各价态
            for charge_state = selected_charge_states
                i_species = min_species_idx + charge_state - 1;
                process_single_pattern(radData, nx_orig, ny_orig, nx_plot, ny_plot, i_species, ...
                    charge_state, use_custom_colormap, clim_range, flux_scale_position);
            end
            
        case 'specific_charge_state'
            % 模式3：指定单一价态
            i_species = min_species_idx + specific_charge_state - 1;
            process_single_pattern(radData, nx_orig, ny_orig, nx_plot, ny_plot, i_species, ...
                specific_charge_state, use_custom_colormap, clim_range, flux_scale_position);
    end
end

end % 主函数结束

%% =========================================================================
%  以下为3个辅助函数，均满足：单一职责、被多次调用、超30行、能显著降低主逻辑复杂度
%% =========================================================================

%% 辅助函数1：处理总密度和通量模式（内部调用，无需单独暴露）
function process_total_pattern(radData, nx_orig, ny_orig, nx_plot, ny_plot, min_species_idx, ...
    selected_charge_states, use_custom_colormap, clim_range, flux_scale_position)
% 绘制所有选定价态的总密度分布+总通量箭头

gmtry = radData.gmtry;
plasma = radData.plasma;
dirName = radData.dirName;

% 检查体积数据
if ~isfield(gmtry, 'vol')
    warning('Case %s: gmtry.vol not found. Skipping.', dirName);
    return;
end

% --- 计算总密度和通量 ---
total_density = zeros(nx_orig, ny_orig);
total_fna_pol = zeros(nx_orig, ny_orig);
total_fna_rad = zeros(nx_orig, ny_orig);

for charge_state = selected_charge_states
    i_species = min_species_idx + charge_state - 1;
    % 检查数据维度是否足够
    if size(plasma.fna_mdf, 4) < i_species || size(plasma.na, 3) < i_species
        continue;
    end
    % 累加密度和通量
    total_density = total_density + plasma.na(:, :, i_species);
    total_fna_pol = total_fna_pol + plasma.fna_mdf(:, :, 1, i_species);
    total_fna_rad = total_fna_rad + plasma.fna_mdf(:, :, 2, i_species);
end

% --- 切片数据（去除保护单元）---
density_plot = total_density(2:nx_orig-1, 2:ny_orig-1);
fna_pol_plot = total_fna_pol(2:nx_orig-1, 2:ny_orig-1);
fna_rad_plot = total_fna_rad(2:nx_orig-1, 2:ny_orig-1);

% --- 生成标签文本 ---
if numel(selected_charge_states) == 1
    range_label = sprintf('N%d+', selected_charge_states(1));
elseif all(diff(selected_charge_states) == 1)
    range_label = sprintf('N%d+ to N%d+', selected_charge_states(1), selected_charge_states(end));
else
    range_label = sprintf('N[%s]+', num2str(selected_charge_states));
end

fprintf('  Processing combined N density (%s) for case: %s\n', range_label, dirName);

% --- 创建图形 ---
fig_title = sprintf('N Density and Flow Pattern (%s) - %s', range_label, dirName);
figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
    'Units', 'inches', 'Position', [0.5, 0.5, 24, 9]);
ax = axes;
hold(ax, 'on');

% --- 绘制密度背景 ---
draw_density_background(ax, density_plot, nx_plot, ny_plot, clim_range, use_custom_colormap, ...
    selected_charge_states, 'total');

% --- 绘制分段箭头 ---
draw_segmented_arrows(ax, nx_plot, ny_plot, fna_pol_plot, fna_rad_plot, flux_scale_position);

% --- 设置坐标轴和区域标签 ---
setup_figure_axes(ax, nx_plot, ny_plot);

% --- 保存图形 ---
save_figure_with_timestamp(gcf, sprintf('TotalNDensityFlowPattern_%s', create_safe_filename(dirName)));

end

%% 辅助函数2：处理单个价态模式
function process_single_pattern(radData, nx_orig, ny_orig, nx_plot, ny_plot, i_species, ...
    charge_state, use_custom_colormap, clim_range, flux_scale_position)
% 绘制单个价态的密度分布+通量箭头

gmtry = radData.gmtry;
plasma = radData.plasma;
dirName = radData.dirName;

% --- 检查数据维度 ---
if size(plasma.fna_mdf, 4) < i_species
    warning('Case %s: Insufficient flux data for N%d+. Skipping.', dirName, charge_state);
    return;
end
if size(plasma.na, 3) < i_species
    warning('Case %s: Insufficient density data for N%d+. Skipping.', dirName, charge_state);
    return;
end

% 检查体积数据
if ~isfield(gmtry, 'vol')
    warning('Case %s: gmtry.vol not found. Skipping.', dirName);
    return;
end

fprintf('  Processing charge state N%d+ for case: %s\n', charge_state, dirName);

% --- 提取单个价态的密度和通量 ---
fna_pol_plot = plasma.fna_mdf(2:nx_orig-1, 2:ny_orig-1, 1, i_species);
fna_rad_plot = plasma.fna_mdf(2:nx_orig-1, 2:ny_orig-1, 2, i_species);
density_plot = plasma.na(2:nx_orig-1, 2:ny_orig-1, i_species);

% --- 创建图形 ---
fig_title = sprintf('N%d+ Density and Flow Pattern - %s', charge_state, dirName);
figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
    'Units', 'inches', 'Position', [0.5, 0.5, 24, 9]);
ax = axes;
hold(ax, 'on');

% --- 绘制密度背景 ---
draw_density_background(ax, density_plot, nx_plot, ny_plot, clim_range, use_custom_colormap, ...
    charge_state, 'single');

% --- 绘制分段箭头 ---
draw_segmented_arrows(ax, nx_plot, ny_plot, fna_pol_plot, fna_rad_plot, flux_scale_position);

% --- 设置坐标轴和区域标签 ---
setup_figure_axes(ax, nx_plot, ny_plot);

% --- 保存图形 ---
save_figure_with_timestamp(gcf, sprintf('DensityFlowPattern_N%d_%s', charge_state, create_safe_filename(dirName)));

end

%% 辅助函数3：绘制分段映射箭头（核心绘图逻辑，约80行，必须拆分）
function draw_segmented_arrows(ax, nx_plot, ny_plot, fna_pol, fna_rad, flux_scale_position)
% 绘制分段缩放的通量箭头
%
% 分段映射原理：
%   - 阈值：flux_threshold = 1e19 s^-1
%   - 高通量（>=阈值）：幂律映射 arrow_length = k * flux^m，其中m=log10(2)
%   - 低通量（<阈值）：线性映射到参考长度

if nx_plot <= 1 || ny_plot <= 1
    return;
end

% --- 分段映射参数 ---
flux_threshold = 1e19;               % 分段阈值
reference_length = sqrt(2) * 0.5;    % 1e19通量对应的箭头长度
m = log10(2);                        % 幂律指数
k = reference_length / (10^(19 * m));% 幂律系数

% --- 计算通量大小 ---
flux_mag = sqrt(fna_pol.^2 + fna_rad.^2);
if all(flux_mag(:) == 0)
    return;
end

% --- 应用分段映射 ---
arrow_lengths = zeros(size(flux_mag));

% 高通量区域：幂律模型
high_idx = flux_mag >= flux_threshold;
arrow_lengths(high_idx) = k .* (flux_mag(high_idx) .^ m);

% 低通量区域：线性映射
low_idx = (flux_mag > 0) & (flux_mag < flux_threshold);
ref_len_at_thresh = k * (flux_threshold^m);
arrow_lengths(low_idx) = ref_len_at_thresh * (flux_mag(low_idx) / flux_threshold);

% --- 计算归一化方向向量 ---
flux_safe = flux_mag;
flux_safe(flux_safe == 0) = 1;  % 避免除零
u_scaled = (fna_pol ./ flux_safe) .* arrow_lengths;
v_scaled = (fna_rad ./ flux_safe) .* arrow_lengths;
u_scaled(flux_mag == 0) = 0;
v_scaled(flux_mag == 0) = 0;

% --- 绘制箭头 ---
[X, Y] = meshgrid(1:nx_plot, 1:ny_plot);
quiver(ax, X, Y, u_scaled', v_scaled', 'Autoscale', 'off', 'Color', 'k', 'LineWidth', 0.8);

% --- 绘制通量比例尺图例 ---
if strcmpi(flux_scale_position, 'none')
    return;
end

% 计算图例位置
is_left = contains(flux_scale_position, 'left');
is_top = contains(flux_scale_position, 'top');

if is_left
    ref_x = nx_plot * 0.08;
    h_sign = 1;  % 箭头向右
    h_align = 'left';
else
    ref_x = nx_plot * 0.95;
    h_sign = -1; % 箭头向左
    h_align = 'right';
end

if is_top
    ref_y = ny_plot * 0.95;
    v_dir = -1;  % 向下排列
else
    ref_y = ny_plot * 0.1;
    v_dir = 1;   % 向上排列
end

% 图例参数
flux_ticks = [1e20, 1e19, 5e18];
legend_spacing = 2.0;
num_ticks = numel(flux_ticks);

% 标题位置
if v_dir < 0
    title_y = ref_y + 2.5;
else
    title_y = ref_y + v_dir * ((num_ticks - 1) * legend_spacing + 2.5);
end
text(ax, ref_x, title_y, 'Flux $(\mathrm{s}^{-1})$:', ...
    'Color', 'r', 'FontSize', 26, 'FontWeight', 'bold', ...
    'Interpreter', 'latex', 'HorizontalAlignment', h_align);

% 计算各刻度的箭头长度
legend_lengths = zeros(size(flux_ticks));
for i = 1:num_ticks
    flux_val = flux_ticks(i);
    if flux_val >= flux_threshold
        legend_lengths(i) = k * (flux_val^m);
    else
        legend_lengths(i) = ref_len_at_thresh * (flux_val / flux_threshold);
    end
end
max_arrow_len = max(legend_lengths);

% 绘制图例箭头
for i = 1:num_ticks
    y_pos = ref_y + (i-1) * v_dir * legend_spacing;
    len_tick = legend_lengths(i);
    
    quiver(ax, ref_x, y_pos, h_sign * len_tick, 0, ...
        'Autoscale', 'off', 'Color', 'r', 'LineWidth', 2, 'MaxHeadSize', 5);
    
    label_x = ref_x + h_sign * (max_arrow_len + 0.5);
    text(ax, label_x, y_pos, sprintf('%.0e', flux_ticks(i)), ...
        'Color', 'r', 'FontSize', 24, 'VerticalAlignment', 'middle', ...
        'Interpreter', 'latex', 'HorizontalAlignment', h_align);
end

end

%% =========================================================================
%  以下为内联的简短辅助逻辑（不单独成函数，直接作为局部子函数）
%% =========================================================================

%% 绘制密度背景
function draw_density_background(ax, density_plot, nx_plot, ny_plot, clim_range, use_custom_colormap, ...
    charge_states, mode_type)
% 绘制密度分布背景色图（log色标）

% 避免log(0)：将非正值替换为最小正值的10%
min_positive = min(density_plot(density_plot > 0), [], 'all');
if isempty(min_positive)
    min_positive = 1e10;
end
density_display = density_plot;
density_display(density_display <= 0) = 0.1 * min_positive;

% 使用imagesc绘制
imagesc(ax, 1:nx_plot, 1:ny_plot, density_display');
set(ax, 'XLim', [0.5, nx_plot + 0.5]);
set(ax, 'YLim', [0.5, ny_plot + 0.5]);
shading(ax, 'flat');

% colorbar设置
h_cb = colorbar(ax);
set(ax, 'ColorScale', 'log');

% 设置CLim
if ~isempty(clim_range)
    set(ax, 'CLim', clim_range);
else
    if strcmp(mode_type, 'total')
        set(ax, 'CLim', [1e17, 1e19]);  % 总密度默认范围
    else
        set(ax, 'CLim', [1e16, 1e19]);  % 单价态默认范围
    end
end

% 计算色标刻度
current_clim = get(ax, 'CLim');
[tick_vals, tick_labels, baseExp] = compute_colorbar_ticks(current_clim);
if ~isempty(tick_vals)
    h_cb.Ticks = tick_vals;
    h_cb.TickLabels = tick_labels;
end

% 生成色标标签
if strcmp(mode_type, 'total')
    if numel(charge_states) == 7 && isequal(charge_states, 1:7)
        subscript = '\mathrm{N}';
    else
        subscript = sprintf('\\mathrm{N}^{%d+}-\\mathrm{N}^{%d+}', charge_states(1), charge_states(end));
    end
else
    subscript = sprintf('\\mathrm{N}^{%d+}', charge_states);
end
colorbar_label = sprintf('$n_{%s}$ ($10^{%d}$ m$^{-3}$)', subscript, baseExp);
set(h_cb.Label, 'String', colorbar_label, 'FontSize', 28, 'Interpreter', 'latex');

% 设置colormap
if use_custom_colormap
    try
        load('mycontour.mat', 'mycontour');
        colormap(ax, mycontour);
        fprintf('Using custom colormap from mycontour.mat\n');
    catch
        fprintf('Warning: Failed to load custom colormap, using jet\n');
        colormap(ax, 'jet');
    end
else
    colormap(ax, 'jet');
end

set(ax, 'YDir', 'normal');

end

%% 设置图形坐标轴和区域标签
function setup_figure_axes(ax, nx_plot, ny_plot)
% 设置坐标轴属性和区域分隔标签

% 固定的网格区域常量
inner_div_end = 24;    % 内偏滤器边界
outer_div_start = 73;  % 外偏滤器边界
separatrix_line = 12;  % 分离面
omp_idx = 41;          % OMP位置
imp_idx = 58;          % IMP位置

% 绘制分隔线
plot(ax, [inner_div_end + 0.5, inner_div_end + 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [outer_div_start - 0.5, outer_div_start - 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [omp_idx + 0.5, omp_idx + 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [imp_idx + 0.5, imp_idx + 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [0.5, nx_plot + 0.5], [separatrix_line + 0.5, separatrix_line + 0.5], 'k-', 'LineWidth', 1.5);

% 顶部区域标签
label_font = 32;
top_y = ny_plot + 2.0;
text(ax, 1, top_y, 'OT', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, inner_div_end, top_y, 'ODE', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, omp_idx, top_y, 'OMP', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, imp_idx, top_y, 'IMP', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, outer_div_start, top_y, 'IDE', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, nx_plot, top_y, 'IT', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

% 坐标轴设置
set(ax, 'DataAspectRatio', [1 1 1]);
set(ax, 'Units', 'normalized');
set(ax, 'Position', [0.08 0.15 0.85 0.78]);

xlabel(ax, '$i_x$', 'FontSize', 32);
ylabel(ax, '$i_y$', 'FontSize', 32);
axis(ax, [0.5, nx_plot + 0.5, 0.5, ny_plot + 0.5]);

% 设置刻度
xticks_val = unique([1, inner_div_end, omp_idx, imp_idx, outer_div_start, nx_plot]);
yticks_val = unique([1, separatrix_line, ny_plot]);
set(ax, 'XTick', xticks_val, 'YTick', yticks_val);
set(ax, 'FontSize', 28);
set(ax, 'TickLength', [0 0]);  % 隐藏刻度线（避免矢量图角落出现刻度十字）
set(ax, 'XMinorTick', 'off', 'YMinorTick', 'off');

box(ax, 'on');
grid(ax, 'off');
hold(ax, 'off');

end

%% 计算色标刻度
function [tick_vals, tick_labels, baseExp] = compute_colorbar_ticks(clim_range)
% 根据colorbar范围自动生成对数刻度

tick_vals = [];
tick_labels = {};
baseExp = 0;

if ~isnumeric(clim_range) || numel(clim_range) ~= 2 || any(~isfinite(clim_range))
    return;
end

cmin = min(clim_range(:));
cmax = max(clim_range(:));
if cmin <= 0 || cmax <= 0 || cmax <= cmin
    return;
end

exp_min = floor(log10(cmin));
exp_max = ceil(log10(cmax));
mantissas = [1, 2, 5];

% 生成候选刻度值
candidates = [];
for exp_val = exp_min:exp_max
    for k_idx = 1:length(mantissas)
        candidate = mantissas(k_idx) * 10^exp_val;
        if candidate >= cmin && candidate <= cmax
            candidates = [candidates; candidate]; %#ok<AGROW>
        end
    end
end

% 确保包含边界
tick_vals = unique([cmin; cmax; candidates]);
tick_vals = sort(tick_vals);

% 生成标签（除以基底指数）
baseExp = floor(log10(cmin));
tick_labels = cell(length(tick_vals), 1);
for i = 1:length(tick_vals)
    tick_labels{i} = sprintf('%.3g', tick_vals(i) / (10^baseExp));
end

end

%% 保存图形
function save_figure_with_timestamp(figHandle, baseName)
% 保存图形为.fig格式，文件名包含时间戳

set(figHandle, 'PaperPositionMode', 'auto');
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
figFile = sprintf('%s_%s.fig', baseName, timestamp);

try
    savefig(figHandle, figFile);
    fprintf('Figure saved: %s\n', figFile);
catch ME
    fprintf('Warning: Failed to save figure - %s\n', ME.message);
end

end

%% 创建安全文件名
function safeName = create_safe_filename(originalName)
% 将目录名转换为安全的文件名（仅保留字母数字下划线）

safeName = regexprep(originalName, '[^a-zA-Z0-9_\-\.]', '_');
if length(safeName) > 100
    safeName = safeName(1:100);
end

end
