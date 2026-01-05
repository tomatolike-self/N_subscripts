function plot_N_ion_density_physical_grid_cellflat(all_radiationData, domain, varargin)
% =========================================================================
% plot_N_ion_density_physical_grid_cellflat - N杂质离子密度物理网格分布图
% =========================================================================
%
% 功能描述：
%   - 基于物理网格绘制N杂质离子密度分布（单元块颜色一致，无通量箭头）
%   - 支持选择单个或多个价态（N1+到N7+）
%   - 使用patch将每个物理单元作为独立色块绘制
%
% 输入：
%   - all_radiationData : cell数组，包含各算例的辐射数据结构体
%   - domain            : 绘图区域（0=全域，1=上偏滤器，2=下偏滤器）
%
% 可选参数（名称-值对）：
%   'use_custom_colormap' - 是否使用mycontour.mat中的colormap（默认false）
%   'charge_states'       - 要绘制的价态（1-7对应N1+-N7+，默认1:7）
%   'clim_range'          - colorbar范围[min,max]，空表示自动（默认[]）
%
% 输出：
%   - N离子密度分布figure
%   - 自动保存带时间戳的.fig文件
%
% 依赖函数/工具箱：
%   - plot3sep, plotgrid_new, plotplasmaboundary, plotstructure（SOLPS工具）
%
% 注意事项：
%   - R2019a兼容
%   - N系统：plasma.na索引4-10对应N1+-N7+
%   - species_idx = charge_state + 3
% =========================================================================

%% 参数默认值与解析
if nargin < 2 || isempty(domain)
    domain = 0;
end

p = inputParser;
addParameter(p, 'use_custom_colormap', false, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'charge_states', 1:7, @(x) isnumeric(x) && all(x >= 1) && all(x <= 7));
addParameter(p, 'clim_range', [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2 && x(1) < x(2)));
parse(p, varargin{:});

use_custom_colormap = logical(p.Results.use_custom_colormap);
charge_states = unique(round(p.Results.charge_states));
clim_range = p.Results.clim_range;

%% 常量定义
% N系统species索引偏移量（N1+在plasma.na中索引为4）
SPECIES_OFFSET = 3;

% 字体设置
FONT_NAME = 'Times New Roman';
FONT_SIZE_DEFAULT = 20;
FONT_SIZE_LABEL = 22;
FONT_SIZE_COLORBAR = 18;

%% 全局绘图设置
set(0, 'DefaultAxesFontName', FONT_NAME);
set(0, 'DefaultTextFontName', FONT_NAME);
set(0, 'DefaultAxesFontSize', FONT_SIZE_DEFAULT);
set(0, 'DefaultTextFontSize', FONT_SIZE_DEFAULT);
set(0, 'DefaultLineLineWidth', 2.0);
set(0, 'DefaultLegendFontName', FONT_NAME);
set(0, 'DefaultLegendFontSize', 18);
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

%% 将价态索引转换为species索引
% SOLPS粒子索引：1=D0, 2=D+, 3=N0, 4=N1+, ..., 10=N7+
species_indices = charge_states + SPECIES_OFFSET;

%% 加载自定义colormap（如需要）
custom_cmap = [];
if use_custom_colormap
    try
        load('mycontour.mat', 'mycontour');
        custom_cmap = mycontour;
    catch
        warning('Failed to load mycontour.mat. Using default jet colormap.');
        use_custom_colormap = false;
    end
end

%% 遍历每个算例
for i_case = 1:numel(all_radiationData)
    
    radData = all_radiationData{i_case};
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    dirName = radData.dirName;
    
    %% 生成价态描述字符串
    if numel(charge_states) == 1
        charge_state_desc = sprintf('N%d+', charge_states(1));
    elseif isequal(charge_states, 1:7)
        charge_state_desc = 'N1+-N7+ (total)';
    else
        charge_state_desc = sprintf('N%d+-N%d+ (selected)', min(charge_states), max(charge_states));
    end
    
    fprintf('Processing case: %s\n', dirName);
    fprintf('  Charge states: %s\n', charge_state_desc);
    
    %% 数据完整性检查
    if ~isfield(gmtry, 'crx') || ~isfield(gmtry, 'cry')
        warning('Case %s: gmtry.crx/cry not found. Skipping.', dirName);
        continue;
    end
    
    nx_orig = size(gmtry.crx, 1);
    ny_orig = size(gmtry.crx, 2);
    
    if nx_orig < 3 || ny_orig < 3
        warning('Case %s: grid too small (nx=%d, ny=%d). Skipping.', dirName, nx_orig, ny_orig);
        continue;
    end
    
    if ~isfield(plasma, 'na')
        warning('Case %s: plasma.na missing. Skipping.', dirName);
        continue;
    end
    
    %% 提取核心网格（去除guard cells）
    ix_core = 2:nx_orig-1;
    iy_core = 2:ny_orig-1;
    
    %% 计算选定价态的总密度
    total_density_full = zeros(nx_orig, ny_orig);
    
    for i_species = species_indices
        if size(plasma.na, 3) < i_species
            warning('  Species index %d (N%d+) not available. Skipping.', i_species, i_species - SPECIES_OFFSET);
            continue;
        end
        total_density_full = total_density_full + plasma.na(:, :, i_species);
    end
    
    density_core = total_density_full(ix_core, iy_core);
    
    %% 有效性检查
    finite_mask = isfinite(density_core);
    if ~any(finite_mask(:))
        warning('Case %s: no finite density values. Skipping.', dirName);
        continue;
    end
    
    %% 处理非正值（对数坐标需要正值）
    density_for_plot = density_core;
    positive_mask = density_for_plot > 0;
    if any(positive_mask(:))
        min_positive = min(density_for_plot(positive_mask));
        density_for_plot(~positive_mask) = min_positive * 0.1;
    else
        min_positive = 1e10;
        density_for_plot(~positive_mask) = min_positive;
    end
    max_density = max(density_for_plot(:));
    
    %% 设置colorbar范围
    if ~isempty(clim_range)
        clim_min = clim_range(1);
        clim_max = clim_range(2);
    else
        clim_min = max(min_positive * 0.5, 1e14);
        clim_max = max_density * 1.1;
    end
    
    %% 网格几何信息
    rc = mean(gmtry.crx, 3);
    zc = mean(gmtry.cry, 3);
    rc_core = rc(ix_core, iy_core);
    zc_core = zc(ix_core, iy_core);
    crx_core = gmtry.crx(ix_core, iy_core, :);
    cry_core = gmtry.cry(ix_core, iy_core, :);
    
    %% 创建Figure
    fig_title = sprintf('N Ion Density (%s) - %s', charge_state_desc, dirName);
    fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
        'Units', 'inches', 'Position', [1, 1, 14, 10]);
    ax = gca;
    hold(ax, 'on');
    
    %% 构建cell-flat patch数据
    % 将每个网格单元转换为四边形patch
    [nx_core_size, ny_core_size, ~] = size(crx_core);
    num_cells = nx_core_size * ny_core_size;
    X_patch = zeros(4, num_cells);
    Y_patch = zeros(4, num_cells);
    C_patch = zeros(4, num_cells);
    
    cell_idx = 0;
    for ix = 1:nx_core_size
        for iy = 1:ny_core_size
            cell_idx = cell_idx + 1;
            % 四个顶点坐标（顺序：左下、右下、右上、左上）
            xv = squeeze(crx_core(ix, iy, [1, 2, 4, 3]));
            yv = squeeze(cry_core(ix, iy, [1, 2, 4, 3]));
            X_patch(:, cell_idx) = xv;
            Y_patch(:, cell_idx) = yv;
            C_patch(:, cell_idx) = density_for_plot(ix, iy);
        end
    end
    
    %% 绘制patch
    patch(ax, X_patch, Y_patch, C_patch, ...
        'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceAlpha', 1.0, 'CDataMapping', 'scaled');
    
    %% 设置对数坐标和颜色范围
    set(ax, 'ColorScale', 'log');
    caxis(ax, [clim_min, clim_max]);
    
    %% 设置colormap
    if use_custom_colormap && ~isempty(custom_cmap)
        colormap(ax, custom_cmap);
        fprintf('  Using custom colormap from mycontour.mat\n');
    else
        colormap(ax, 'jet');
    end
    
    %% 设置colorbar
    h_cb = colorbar(ax);
    h_cb.FontSize = FONT_SIZE_COLORBAR;
    
    % 构建colorbar标签
    if numel(charge_states) == 1
        cb_label = sprintf('N$^{%d+}$ Density (m$^{-3}$)', charge_states(1));
    elseif isequal(charge_states, 1:7)
        cb_label = 'N$^{1+}$-N$^{7+}$ Density (m$^{-3}$)';
    else
        cb_label = sprintf('N$^{%d+}$-N$^{%d+}$ Density (m$^{-3}$)', min(charge_states), max(charge_states));
    end
    ylabel(h_cb, cb_label, 'Interpreter', 'latex', 'FontSize', FONT_SIZE_DEFAULT);
    
    %% 绘制网格结构覆盖
    try
        plot3sep(gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
    catch
    end
    try
        plotgrid_new(gmtry, 'all3', 'color', [0.3 0.3 0.3], 'LineWidth', 0.2, 'HandleVisibility', 'off');
    catch
    end
    try
        plotplasmaboundary(gmtry, 'color', 'k', 'LineStyle', '-', 'LineWidth', 1.0, 'HandleVisibility', 'off');
    catch
    end
    
    %% 设置坐标轴
    xlabel(ax, '$R$ (m)', 'Interpreter', 'latex', 'FontSize', FONT_SIZE_LABEL);
    ylabel(ax, '$Z$ (m)', 'Interpreter', 'latex', 'FontSize', FONT_SIZE_LABEL);
    axis(ax, 'equal');
    axis(ax, 'tight');
    grid(ax, 'on');
    box(ax, 'on');
    ax.FontSize = FONT_SIZE_COLORBAR;
    
    %% 区域缩放
    if domain == 1
        xlim(ax, [1.40, 1.90]);
        ylim(ax, [0.60, 1.10]);
        if isfield(radData, 'structure')
            plotstructure(radData.structure, 'color', 'k', 'LineWidth', 2, 'HandleVisibility', 'off');
        end
    elseif domain == 2
        xlim(ax, [1.30, 2.05]);
        ylim(ax, [-1.15, -0.40]);
        if isfield(radData, 'structure')
            plotstructure(radData.structure, 'color', 'k', 'LineWidth', 2, 'HandleVisibility', 'off');
        end
    end
    
    %% 数据游标
    dcm_obj = datacursormode(gcf);
    set(dcm_obj, 'UpdateFcn', @(src, evt) datacursor_n_density(src, evt, rc_core, zc_core, density_core));
    
    %% 保存Figure
    % 生成安全文件名
    safe_name = regexprep(dirName, '[^a-zA-Z0-9_\-\.]', '_');
    if length(safe_name) > 100
        safe_name = safe_name(1:100);
    end
    
    % 生成价态后缀
    if numel(charge_states) == 1
        charge_suffix = sprintf('N%d', charge_states(1));
    elseif isequal(charge_states, 1:7)
        charge_suffix = 'N1-7';
    else
        charge_suffix = sprintf('N%d-%d', min(charge_states), max(charge_states));
    end
    
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    fname = sprintf('NIon_Density_Physical_CellFlat_%s_%s_%s.fig', charge_suffix, safe_name, timestamp);
    
    set(fig, 'PaperPositionMode', 'auto');
    try
        savefig(fig, fname);
        fprintf('  Figure saved: %s\n', fname);
    catch ME
        fprintf('  Warning: failed to save figure (%s)\n', ME.message);
    end
    
    hold(ax, 'off');
end

fprintf('N ion density plotting completed.\n');

end


%% =========================================================================
% 辅助函数：数据游标回调
% =========================================================================
function output_txt = datacursor_n_density(~, event_obj, rc_core, zc_core, density_core)
% 定位到最近单元中心，显示坐标与密度值

pos = event_obj.Position;
R = pos(1);
Z = pos(2);

distance_sq = (rc_core - R).^2 + (zc_core - Z).^2;
[~, linear_idx] = min(distance_sq(:));
[ix, iy] = ind2sub(size(distance_sq), linear_idx);

density_val = density_core(ix, iy);

output_txt = {...
    sprintf('R = %.4f m', R), ...
    sprintf('Z = %.4f m', Z), ...
    sprintf('ix = %d', ix + 1), ...
    sprintf('iy = %d', iy + 1), ...
    sprintf('n_N = %.3e m^-3', density_val)};
end
