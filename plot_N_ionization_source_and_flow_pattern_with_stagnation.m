function plot_N_ionization_source_and_flow_pattern_with_stagnation(all_radiationData, colorbar_range, show_flux_scale, stagnation_mode)
% =========================================================================
% plot_N_ionization_source_and_flow_pattern_with_stagnation - N离子电离源与流场可视化
% =========================================================================
%
% 功能描述：
%   - 背景：N0 -> N1+ 电离源分布（对数色标）
%   - 箭头：总N离子通量（N1+到N7+总和）使用分段映射
%   - 标记：停滞点（极向/平行速度过零点）
%
% 输入：
%   - all_radiationData : cell数组，包含多个算例的 radData 结构体
%   - colorbar_range    : 可选，[min, max] colorbar线性范围（单位 m^-3 s^-1），默认 [1e21, 1e23]
%   - show_flux_scale   : 可选，逻辑值，是否显示通量比例尺图例，默认 false
%   - stagnation_mode   : 可选，停滞点显示模式：
%                         0 = 原始逻辑（默认）：所有停滞点都只保留首尾两项，至多2个
%                         1 = 偏滤器优先逻辑：极向停滞点按左右两侧分别筛选，偏滤器区域优先
%                         2 = 显示全部停滞点：不做任何筛选
%
% 输出：
%   - 每个算例生成一张 figure 并保存为 .fig 文件
%
% 使用示例：
%   plot_N_ionization_source_and_flow_pattern_with_stagnation(all_radiationData)
%   plot_N_ionization_source_and_flow_pattern_with_stagnation(all_radiationData, [1e20, 1e24], true, 1)
%
% 依赖函数/工具箱：
%   - 无必需工具箱
%   - 可选: mycontour.mat (自定义色表文件)
%
% 注意事项：
%   - R2019a 兼容（避免 arguments 块、tiledlayout 等新语法）
%   - rsana索引: 3 = N1+, 4 = N2+, ..., 9 = N7+
%   - fna_mdf 第4维索引: 4 = N1+, ..., 10 = N7+
%   - 网格使用 DataAspectRatio = [1 1 1] 确保正方形单元
% =========================================================================

%% 设置绘图默认参数
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 32);
set(0, 'DefaultTextFontSize', 32);
set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'DefaultLegendFontName', 'Times New Roman');
set(0, 'DefaultLegendFontSize', 28);
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

%% 区域边界常量（EAST 托卡马克网格）
INNER_DIV_END   = 24;   % ODE末端 (外偏滤器)
OUTER_DIV_START = 73;   % IDE起始 (内偏滤器)
SEPARATRIX_LINE = 12;   % 分离面径向索引
OMP_IDX         = 41;   % 外中平面极向索引
IMP_IDX         = 58;   % 内中平面极向索引

%% 输入参数处理
default_clim = [1e21, 1e23];

if nargin < 2 || isempty(colorbar_range)
    colorbar_range = default_clim;
else
    if ~isnumeric(colorbar_range) || numel(colorbar_range) ~= 2 || ...
            any(~isfinite(colorbar_range)) || any(colorbar_range <= 0) || ...
            colorbar_range(2) <= colorbar_range(1)
        warning('Invalid colorbar range. Using default [1e21, 1e23].');
        colorbar_range = default_clim;
    end
end

if nargin < 3 || isempty(show_flux_scale)
    show_flux_scale = false;
end

if nargin < 4 || isempty(stagnation_mode)
    stagnation_mode = 1;  % 默认使用偏滤器优先逻辑
end

%% 主循环：处理每个算例
for i_case = 1:length(all_radiationData)
    radData = all_radiationData{i_case};
    fprintf('\n=== Processing case: %s ===\n', radData.dirName);
    
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    neut = radData.neut;
    dirName = radData.dirName;
    
    s = size(gmtry.crx);
    nx_orig = s(1);
    ny_orig = s(2);
    nx_plot = nx_orig - 2;
    ny_plot = ny_orig - 2;
    
    if ~isfield(plasma, 'rsana')
        warning('Case %s: No rsana data found, skipping...', dirName);
        continue;
    end
    
    %% 计算背景：N0 -> N1+ 电离源
    ionSource2D = compute_ionization_source_for_N1plus(plasma, neut, gmtry, nx_orig, ny_orig);
    ionSource2D_log = log10(max(ionSource2D, 1e10));
    ionSource_plot = ionSource2D_log(2:nx_orig-1, 2:ny_orig-1);
    
    %% 计算流场：总N离子通量
    [flux_pol_plot, flux_rad_plot] = calculate_total_N_flux(plasma, gmtry, nx_orig, ny_orig, dirName);
    
    %% 创建图形
    fig_title = sprintf('N Ionization Source & Flow Pattern - %s', dirName);
    fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
        'Units', 'inches', 'Position', [0.5, 0.5, 24, 9]);
    
    ax = axes(fig);
    hold(ax, 'on');
    
    %% 绘制背景
    h_img = imagesc(ax, 1:nx_plot, 1:ny_plot, ionSource_plot');
    set(h_img, 'HandleVisibility', 'off');
    set(ax, 'YDir', 'normal');
    shading(ax, 'flat');
    
    try
        load('mycontour.mat', 'mycontour');
        colormap(ax, mycontour);
    catch
        colormap(ax, 'jet');
    end
    
    h_cb = colorbar(ax);
    c_min = log10(colorbar_range(1));
    c_max = log10(colorbar_range(2));
    caxis(ax, [c_min, c_max]);
    
    [tick_vals, tick_labels, baseExp] = compute_colorbar_ticks(colorbar_range);
    if ~isempty(tick_vals)
        h_cb.Ticks = log10(tick_vals);
        h_cb.TickLabels = tick_labels;
    end
    
    ylabel_str = sprintf('$S_{\\mathrm{ion, N^+}}$ ($10^{%d}$ m$^{-3}$s$^{-1}$)', baseExp);
    ylabel(h_cb, ylabel_str, 'Interpreter', 'latex', 'FontSize', 28, 'FontWeight', 'bold');
    h_cb.FontName = 'Times New Roman';
    h_cb.FontSize = 26;
    h_cb.LineWidth = 1.5;
    
    %% 绘制箭头
    plot_flux_arrows_segmented(ax, nx_plot, ny_plot, flux_pol_plot, flux_rad_plot, show_flux_scale);
    
    %% 绘制停滞点
    plot_stagnation_points(ax, plasma, nx_orig, ny_orig, nx_plot, ny_plot, stagnation_mode);
    
    %% 添加区域标签和分隔线
    h1 = plot(ax, [INNER_DIV_END+0.5, INNER_DIV_END+0.5], [0.5, ny_plot+0.5], 'k--', 'LineWidth', 1.0);
    h2 = plot(ax, [OUTER_DIV_START-0.5, OUTER_DIV_START-0.5], [0.5, ny_plot+0.5], 'k--', 'LineWidth', 1.0);
    h3 = plot(ax, [OMP_IDX+0.5, OMP_IDX+0.5], [0.5, ny_plot+0.5], 'k--', 'LineWidth', 1.0);
    h4 = plot(ax, [IMP_IDX+0.5, IMP_IDX+0.5], [0.5, ny_plot+0.5], 'k--', 'LineWidth', 1.0);
    h5 = plot(ax, [0.5, nx_plot+0.5], [SEPARATRIX_LINE+0.5, SEPARATRIX_LINE+0.5], 'k-', 'LineWidth', 1.5);
    set([h1, h2, h3, h4, h5], 'HandleVisibility', 'off');
    
    label_font_size = 32;
    top_y = ny_plot + 2.0;
    text(ax, 1, top_y, 'OT', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, INNER_DIV_END, top_y, 'ODE', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, OMP_IDX, top_y, 'OMP', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, IMP_IDX, top_y, 'IMP', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, OUTER_DIV_START, top_y, 'IDE', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, nx_plot, top_y, 'IT', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    
    %% 设置坐标轴
    xlabel(ax, '$i_x$', 'FontSize', 32, 'Interpreter', 'latex');
    ylabel(ax, '$i_y$', 'FontSize', 32, 'Interpreter', 'latex');
    axis(ax, [0.5, nx_plot+0.5, 0.5, ny_plot+0.5]);
    
    xticks_vals = unique([1, INNER_DIV_END, OMP_IDX, IMP_IDX, OUTER_DIV_START, nx_plot]);
    yticks_vals = unique([1, SEPARATRIX_LINE, ny_plot]);
    set(ax, 'XTick', xticks_vals, 'YTick', yticks_vals, 'FontSize', 28);
    
    % 去除刻度线
    set(ax, 'TickLength', [0 0]);
    set(ax, 'XMinorTick', 'off', 'YMinorTick', 'off');
    
    % 设置正方形网格单元
    set(ax, 'DataAspectRatio', [1 1 1]);
    
    % 固定坐标轴位置（锁定布局）
    set(ax, 'Units', 'normalized');
    set(ax, 'ActivePositionProperty', 'position');
    set(ax, 'LooseInset', [0.12, 0.12, 0.05, 0.05]);
    set(ax, 'Position', [0.08, 0.15, 0.85, 0.78]);
    
    %% 导出对齐占位（确保不同图导出为矢量图后白边一致）
    % 说明：\phantom{...} 占据宽度/高度但不绘制字符，避免"白色字符遮挡"问题
    export_pad_fontsize = 32;
    % 右侧留白（覆盖色条刻度差异）
    text(ax, 1.05, 0.02, '$\phantom{00000}$', 'Units', 'normalized', 'HandleVisibility', 'off', ...
        'Interpreter', 'latex', 'FontSize', export_pad_fontsize, 'Clipping', 'off', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
    % 底部留白
    text(ax, 0.02, -0.22, '$\phantom{0}$', 'Units', 'normalized', 'HandleVisibility', 'off', ...
        'Interpreter', 'latex', 'FontSize', export_pad_fontsize, 'Clipping', 'off', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    % 顶部留白
    text(ax, 0.02, 1.12, '$\phantom{0}$', 'Units', 'normalized', 'HandleVisibility', 'off', ...
        'Interpreter', 'latex', 'FontSize', export_pad_fontsize, 'Clipping', 'off', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
    
    box(ax, 'on');
    grid(ax, 'off');
    
    hold(ax, 'off');
    
    %% 设置数据游标
    setup_data_cursor(fig, nx_plot, ny_plot, ionSource_plot, flux_pol_plot, flux_rad_plot);
    
    %% 保存图形
    fname = sprintf('N_IonSource_Flow_Stagnation_%s', regexprep(dirName, '[^a-zA-Z0-9]', '_'));
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    try
        savefig(fig, [fname, '_', timestamp, '.fig']);
        fprintf('Saved figure: %s_%s.fig\n', fname, timestamp);
    catch ME
        warning('plot_N_ionization_source:SaveFigureFail', ...
            'Failed to save figure: %s', ME.message);
    end
end

fprintf('\nN ionization source & flow pattern plotting completed.\n');

end


%% =========================================================================
% 辅助函数
% =========================================================================

function ionSource2D = compute_ionization_source_for_N1plus(plasma, neut, gmtry, nx, ny)
% 计算 N0 -> N1+ 电离源密度（单位: m^-3 s^-1）

ionSource2D = zeros(nx, ny);
rsana_idx = 3;

if ~isfield(plasma, 'rsana') || size(plasma.rsana, 3) < rsana_idx
    return;
end

rsana_full = plasma.rsana(:, :, rsana_idx);

% N1+ 特殊修正
if isfield(neut, 'dab2') && size(neut.dab2, 3) >= 2
    rsana_corrected = zeros(size(rsana_full));
    for i = 1:nx
        for j = 1:ny
            i_trim = i - 1;
            j_trim = j - 1;
            if i_trim >= 1 && i_trim <= size(neut.dab2, 1) && ...
                    j_trim >= 1 && j_trim <= size(neut.dab2, 2)
                if isfield(plasma, 'na') && size(plasma.na, 3) >= 3 && plasma.na(i,j,3) > 0
                    rsana_corrected(i,j) = rsana_full(i,j) * neut.dab2(i_trim, j_trim, 2) / plasma.na(i,j,3);
                end
            else
                rsana_corrected(i,j) = rsana_full(i,j);
            end
        end
    end
    rsana_full = rsana_corrected;
end

% 转换为密度
for i = 1:nx
    for j = 1:ny
        if isfield(gmtry, 'vol') && gmtry.vol(i,j) > 0
            ionSource2D(i,j) = rsana_full(i,j) / gmtry.vol(i,j);
        end
    end
end
end


function [flux_pol_plot, flux_rad_plot] = calculate_total_N_flux(plasma, gmtry, nx_orig, ny_orig, dirName)
% 计算 N1+ 到 N7+ 的总通量

flux_pol_full = zeros(nx_orig, ny_orig);
flux_rad_full = zeros(nx_orig, ny_orig);

if ~(isfield(gmtry, 'gs') && size(gmtry.gs, 3) >= 2)
    warning('Case %s: Missing geometry area data.', dirName);
end

max_sp = min([10, size(plasma.fna_mdf, 4)]);
for sp = 4:max_sp
    if ~isempty(plasma.fna_mdf(:,:,1,sp))
        flux_pol_full = flux_pol_full + plasma.fna_mdf(:,:,1,sp);
        flux_rad_full = flux_rad_full + plasma.fna_mdf(:,:,2,sp);
    end
end

flux_pol_plot = flux_pol_full(2:nx_orig-1, 2:ny_orig-1);
flux_rad_plot = flux_rad_full(2:nx_orig-1, 2:ny_orig-1);
end


function [tick_vals, tick_labels, baseExp] = compute_colorbar_ticks(colorbar_range)
% 生成1/2/5序列的colorbar刻度

exp_min = floor(log10(colorbar_range(1)));
exp_max = ceil(log10(colorbar_range(2)));
mantissas = [1, 2, 5];

tick_vals = [];
for exp_val = exp_min:exp_max
    for k = 1:length(mantissas)
        candidate = mantissas(k) * 10^exp_val;
        if candidate >= colorbar_range(1) && candidate <= colorbar_range(2)
            tick_vals = [tick_vals; candidate]; %#ok<AGROW>
        end
    end
end

tick_vals = [colorbar_range(:); tick_vals];
tick_vals = unique(tick_vals);
tick_vals = sort(tick_vals);

baseExp = floor(log10(colorbar_range(1)));

tick_labels = cell(length(tick_vals), 1);
for i = 1:length(tick_vals)
    tick_labels{i} = sprintf('%.3g', tick_vals(i) / (10^baseExp));
end
end


function plot_flux_arrows_segmented(ax, nx_plot, ny_plot, flux_pol, flux_rad, show_flux_scale)
% 绘制分段映射的通量箭头

flux_threshold = 1e19;
reference_length = sqrt(2) * 0.5;
m = log10(2);
k = reference_length / (10^(19 * m));

flux_mag = sqrt(flux_pol.^2 + flux_rad.^2);
if all(flux_mag(:) == 0)
    return;
end

arrow_lens = zeros(size(flux_mag));

high_idx = flux_mag >= flux_threshold;
arrow_lens(high_idx) = k .* (flux_mag(high_idx) .^ m);

low_idx = (flux_mag > 0) & (flux_mag < flux_threshold);
ref_len_at_thresh = k * (flux_threshold^m);
arrow_lens(low_idx) = ref_len_at_thresh * (flux_mag(low_idx) / flux_threshold);

flux_mag_safe = flux_mag;
flux_mag_safe(flux_mag_safe == 0) = 1;
u_scaled = (flux_pol ./ flux_mag_safe) .* arrow_lens;
v_scaled = (flux_rad ./ flux_mag_safe) .* arrow_lens;
u_scaled(flux_mag == 0) = 0;
v_scaled(flux_mag == 0) = 0;

[X, Y] = meshgrid(1:nx_plot, 1:ny_plot);
quiver(ax, X, Y, u_scaled', v_scaled', 'Autoscale', 'off', 'Color', 'k', ...
    'LineWidth', 0.8, 'HandleVisibility', 'off');

if show_flux_scale
    y_pos = -3.5;
    current_x = 1;
    
    text(ax, current_x, y_pos, 'Flux (s$^{-1}$):', 'Color', 'r', ...
        'FontSize', 32, 'FontWeight', 'bold', 'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', 'Clipping', 'off');
    current_x = current_x + 25;
    
    flux_vals = [1e20, 1e19, 5e18];
    for val = flux_vals
        if val >= flux_threshold
            len = k * (val^m);
        else
            len = ref_len_at_thresh * (val / flux_threshold);
        end
        
        quiver(ax, current_x, y_pos, len, 0, 'Autoscale', 'off', 'Color', 'r', ...
            'LineWidth', 2, 'MaxHeadSize', 5, 'HandleVisibility', 'off', 'Clipping', 'off');
        text(ax, current_x + len + 1, y_pos, sprintf('%.0e', val), 'Color', 'r', ...
            'FontSize', 28, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'Clipping', 'off');
        current_x = current_x + len + 18;
    end
end
end


function plot_stagnation_points(ax, plasma, nx_orig, ny_orig, nx_plot, ny_plot, stagnation_mode)
% 绘制停滞点

try
    % 计算速度场
    u_pol = zeros(nx_plot, ny_plot);
    u_par = zeros(nx_plot, ny_plot);
    
    for i = 1:nx_plot
        for j = 1:ny_plot
            i_orig = i + 1;
            j_orig = j + 1;
            
            flux_pol = sum(plasma.fna_mdf(i_orig, j_orig, 1, 4:10));
            density = sum(plasma.na(i_orig, j_orig, 4:10));
            if density > 0
                u_pol(i,j) = flux_pol / density;
            end
            
            w_sum = 0;
            w_tot = 0;
            for sp = 4:10
                Z = sp - 3;
                n = plasma.na(i_orig, j_orig, sp);
                u = plasma.ua(i_orig, j_orig, sp);
                w_sum = w_sum + Z^2 * n * u;
                w_tot = w_tot + Z^2 * n;
            end
            if w_tot > 0
                u_par(i,j) = w_sum / w_tot;
            end
        end
    end
    
    % 检测停滞点
    [pol_stag_points, par_stag_points] = detect_stagnation_points(u_pol, u_par, stagnation_mode);
    
    % 绘制标记
    draw_stagnation_markers(ax, pol_stag_points, par_stag_points, ny_plot);
    
catch ME
    warning('plot_N_ionization_source:StagnationPointFail', ...
        'Failed to plot stagnation points: %s', ME.message);
end
end


function [pol_stag_points, par_stag_points] = detect_stagnation_points(u_pol, u_par, stagnation_mode)
% 检测极向和平行速度停滞点
% stagnation_mode: 0=原始逻辑, 1=偏滤器优先, 2=全部显示

[nx, ny] = size(u_pol);
pol_stag_points = cell(ny, 1);
par_stag_points = cell(ny, 1);

for j = 1:ny
    % 找所有过零点
    par_all = find_all_zero_crossings(u_par(:, j), j);
    pol_all = find_all_zero_crossings(u_pol(:, j), j);
    
    if stagnation_mode == 2
        % 模式2：显示全部
        par_stag_points{j} = par_all;
        pol_stag_points{j} = pol_all;
        
    elseif stagnation_mode == 1
        % 模式1：偏滤器优先逻辑
        % 平行停滞点：仅保留首尾两个
        if size(par_all, 1) > 2
            par_stag_points{j} = [par_all(1,:); par_all(end,:)];
        else
            par_stag_points{j} = par_all;
        end
        
        % 极向停滞点：按左右两侧分别筛选，偏滤器区域优先
        pol_stag_points{j} = select_poloidal_stagnation_points_mode1(...
            pol_all, par_stag_points{j}, u_pol(:, j), nx);
        
    else
        % 模式0（默认）：原始逻辑，所有停滞点都只保留首尾两项
        if size(par_all, 1) > 2
            par_stag_points{j} = [par_all(1,:); par_all(end,:)];
        else
            par_stag_points{j} = par_all;
        end
        if size(pol_all, 1) > 2
            pol_stag_points{j} = [pol_all(1,:); pol_all(end,:)];
        else
            pol_stag_points{j} = pol_all;
        end
    end
end
end


function points = find_all_zero_crossings(vec, j_idx)
% 找到向量中所有的过零点位置

points = [];
for i = 1:length(vec)-1
    if vec(i) * vec(i+1) < 0
        points = [points; i, j_idx]; %#ok<AGROW>
    end
end
end


function selected_pts = select_poloidal_stagnation_points_mode1(pol_pts, par_pts, u_pol_vec, nx)
% 模式1：偏滤器优先 + 左右两侧分别筛选
%
% 逻辑说明:
%   1. 将极向网格分为两侧：
%      - 外侧 (ix = 1-48): 偏滤器ODE扩展版 (ix <= 25) + 主SOL (ix = 26-48)
%      - 内侧 (ix = 49-96): 主SOL (ix = 49-71) + 偏滤器IDE扩展版 (ix >= 72)
%   2. 筛选优先级（偏滤器优先）：
%      a) 首先在偏滤器区域内寻找满足上游速度条件的停滞点
%      b) 如果偏滤器有多个满足条件的，选择最靠近平行停滞点的
%      c) 只有偏滤器区域没有符合条件的停滞点时，才考虑主SOL区域

if isempty(pol_pts)
    selected_pts = [];
    return;
end

OUTER_SIDE_END = 48;
INNER_SIDE_START = 49;
OUTER_DIV_END_EXTENDED = 25;
INNER_DIV_START_EXTENDED = 72;

outer_div_pts = [];
outer_sol_pts = [];
inner_sol_pts = [];
inner_div_pts = [];

for k = 1:size(pol_pts, 1)
    ix = pol_pts(k, 1);
    if ix <= OUTER_DIV_END_EXTENDED
        outer_div_pts = [outer_div_pts; pol_pts(k, :)]; %#ok<AGROW>
    elseif ix <= OUTER_SIDE_END
        outer_sol_pts = [outer_sol_pts; pol_pts(k, :)]; %#ok<AGROW>
    elseif ix < INNER_DIV_START_EXTENDED
        inner_sol_pts = [inner_sol_pts; pol_pts(k, :)]; %#ok<AGROW>
    else
        inner_div_pts = [inner_div_pts; pol_pts(k, :)]; %#ok<AGROW>
    end
end

if ~isempty(par_pts)
    par_ix = par_pts(:, 1);
else
    par_ix = 48;
end

outer_selected = select_with_divertor_priority(outer_div_pts, outer_sol_pts, par_ix, u_pol_vec, 'outer');
inner_selected = select_with_divertor_priority(inner_div_pts, inner_sol_pts, par_ix, u_pol_vec, 'inner');

selected_pts = [outer_selected; inner_selected];
end


function selected = select_with_divertor_priority(div_pts, sol_pts, par_ix, u_pol_vec, side)
% 偏滤器优先选择停滞点

selected = select_valid_stagnation_point(div_pts, par_ix, u_pol_vec, side);

if isempty(selected)
    selected = select_valid_stagnation_point(sol_pts, par_ix, u_pol_vec, side);
end
end


function selected = select_valid_stagnation_point(side_pts, par_ix, u_pol_vec, side)
% 从一侧的停滞点中选择有效的那个

if isempty(side_pts)
    selected = [];
    return;
end

if size(side_pts, 1) == 1
    ix = side_pts(1, 1);
    if validate_upstream_velocity(ix, side, u_pol_vec)
        selected = side_pts;
    else
        selected = [];
    end
    return;
end

valid_pts = [];
for k = 1:size(side_pts, 1)
    ix = side_pts(k, 1);
    if validate_upstream_velocity(ix, side, u_pol_vec)
        valid_pts = [valid_pts; side_pts(k, :)]; %#ok<AGROW>
    end
end

if isempty(valid_pts)
    selected = [];
    return;
end

if size(valid_pts, 1) == 1
    selected = valid_pts;
    return;
end

min_distances = zeros(size(valid_pts, 1), 1);
for k = 1:size(valid_pts, 1)
    pol_ix = valid_pts(k, 1);
    distances = abs(pol_ix - par_ix);
    min_distances(k) = min(distances);
end

[~, closest_idx] = min(min_distances);
selected = valid_pts(closest_idx, :);
end


function is_valid = validate_upstream_velocity(ix, side, u_pol_vec)
% 验证候选停滞点的上游速度条件
%
% - 外侧 (outer): 检查 ix+1 位置的速度是否 > 0
% - 内侧 (inner): 检查 ix-1 位置的速度是否 < 0

OUTER_SIDE_END = 48;
INNER_SIDE_START = 49;

is_valid = false;
nx = length(u_pol_vec);

if strcmp(side, 'outer')
    if ix >= OUTER_SIDE_END
        is_valid = false;
        return;
    end
    
    check_idx = ix + 1;
    if check_idx < 1 || check_idx > nx
        is_valid = false;
        return;
    end
    
    if u_pol_vec(check_idx) > 0
        is_valid = true;
    end
    
elseif strcmp(side, 'inner')
    if ix <= INNER_SIDE_START
        is_valid = false;
        return;
    end
    
    check_idx = ix - 1;
    if check_idx < 1 || check_idx > nx
        is_valid = false;
        return;
    end
    
    if u_pol_vec(check_idx) < 0
        is_valid = true;
    end
end
end


function draw_stagnation_markers(ax, pol_stag_points, par_stag_points, ny_plot)
% 绘制停滞点标记

real_marker_size = 160;
legend_marker_size = 24;
j_min = 13;
j_max = min(26, ny_plot);

pol_pts = [];
par_pts = [];
for j = j_min:j_max
    if ~isempty(pol_stag_points{j})
        pol_pts = [pol_pts; pol_stag_points{j}]; %#ok<AGROW>
    end
    if ~isempty(par_stag_points{j})
        par_pts = [par_pts; par_stag_points{j}]; %#ok<AGROW>
    end
end

if ~isempty(pol_pts)
    scatter(ax, pol_pts(:,1), pol_pts(:,2), real_marker_size, 'm', 'o', 'filled', ...
        'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
end
if ~isempty(par_pts)
    scatter(ax, par_pts(:,1), par_pts(:,2), real_marker_size, 'k', 's', 'filled', ...
        'MarkerEdgeColor', 'w', 'HandleVisibility', 'off');
end

dummy_handles = [];
dummy_labels = {};
if ~isempty(pol_pts)
    h_pol = plot(ax, NaN, NaN, 'o', 'MarkerSize', legend_marker_size, ...
        'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'k', 'LineStyle', 'none');
    dummy_handles = [dummy_handles, h_pol];
    dummy_labels{end+1} = 'Poloidal stagnation';
end
if ~isempty(par_pts)
    h_par = plot(ax, NaN, NaN, 's', 'MarkerSize', legend_marker_size, ...
        'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'w', 'LineStyle', 'none');
    dummy_handles = [dummy_handles, h_par];
    dummy_labels{end+1} = 'Parallel stagnation';
end

if ~isempty(dummy_handles)
    lgd = legend(ax, dummy_handles, dummy_labels, 'Location', 'southwest');
    set(lgd, 'FontName', 'Times New Roman', 'FontSize', 28, 'Interpreter', 'latex');
end
end


function setup_data_cursor(fig, nx_plot, ny_plot, ionSource_plot, flux_pol_plot, flux_rad_plot)
% 设置数据游标

dcm = datacursormode(fig);
set(dcm, 'Enable', 'on');

fig.UserData.ionSource = ionSource_plot;
fig.UserData.flux_pol = flux_pol_plot;
fig.UserData.flux_rad = flux_rad_plot;
fig.UserData.nx_plot = nx_plot;
fig.UserData.ny_plot = ny_plot;

set(dcm, 'UpdateFcn', @local_datacursor_callback);
end


function output_txt = local_datacursor_callback(~, event_obj)
% 数据游标回调函数

fig = ancestor(event_obj.Target, 'figure');
if isempty(fig) || ~isfield(fig.UserData, 'ionSource')
    output_txt = {'Data unavailable'};
    return;
end

userData = fig.UserData;
nx_p = userData.nx_plot;
ny_p = userData.ny_plot;

pos = get(event_obj, 'Position');
ix = round(pos(1));
iy = round(pos(2));
ix = max(1, min(nx_p, ix));
iy = max(1, min(ny_p, iy));

if ix <= size(userData.ionSource, 1) && iy <= size(userData.ionSource, 2)
    source_val_log = userData.ionSource(ix, iy);
    source_val = 10^source_val_log;
else
    source_val = NaN;
end

if ix <= size(userData.flux_pol, 1) && iy <= size(userData.flux_pol, 2)
    pol_val = userData.flux_pol(ix, iy);
    rad_val = userData.flux_rad(ix, iy);
    mag_val = sqrt(pol_val^2 + rad_val^2);
else
    pol_val = NaN; rad_val = NaN; mag_val = NaN;
end

output_txt = {
    sprintf('Grid: (%d, %d)', ix, iy), ...
    sprintf('S_{ion}: %.2e m^{-3}s^{-1}', source_val), ...
    sprintf('Flux_{pol}: %.2e s^{-1}', pol_val), ...
    sprintf('Flux_{rad}: %.2e s^{-1}', rad_val), ...
    sprintf('|Flux|: %.2e s^{-1}', mag_val)
    };
end
