function plot_potential_physical_grid_segmented_colormap_cellflat(all_radiationData, domain)
% PLOT_POTENTIAL_PHYSICAL_GRID_SEGMENTED_COLORMAP_CELLFLAT
%   仅绘制电势分布（φ），不再叠加ExB漂移箭头，背景采用“单元块保持颜色一致”的绘制方式。
%   颜色映射参照用户提供的文献图片，使用分段式（piecewise）colormap，将[-100, 50] V范围
%   拆分为多个感兴趣的子区间，以突出电势阱位置。
%
%   输入:
%     all_radiationData : cell array，包含多个算例的 radData 结构
%     domain            : 0 全域、1 EAST上偏滤器、2 EAST下偏滤器（默认0）
%
%   注意:
%     - 逻辑与 plot_potential_ExB_radial_drift_physical_grid_cellflat.m 基本一致，只保留电势背景。
%     - 颜色阶梯设置在本脚本中硬编码，可根据需求进一步调整。

if nargin < 2 || isempty(domain)
    domain = 0;
end

% ------------------------------------------------------------------
% 全局排版设置，便于直接生成论文/汇报级别的图
% ------------------------------------------------------------------
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 16);
set(0, 'DefaultTextFontSize', 16);
set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'DefaultLegendFontName', 'Times New Roman');
set(0, 'DefaultLegendFontSize', 14);
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

% ------------------------------------------------------------------
% 线性色阶设置
% 范围：[-100, 150] V
% ------------------------------------------------------------------
caxis_range = [-100, 150];
linear_colormap = buildLinearPotentialColormap(caxis_range(1), caxis_range(2), 256);

for i_case = 1:numel(all_radiationData)
    radData = all_radiationData{i_case};
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    dirName = radData.dirName;
    
    fprintf('Processing case for segmented potential map (cell-flat) on physical grid: %s\n', dirName);
    
    if ~isfield(gmtry, 'crx') || ~isfield(gmtry, 'cry')
        warning('Case %s: gmtry.crx / gmtry.cry not found. Skipping.', dirName);
        continue;
    end
    
    nx_orig = size(gmtry.crx, 1);
    ny_orig = size(gmtry.crx, 2);
    if nx_orig < 3 || ny_orig < 3
        warning('Case %s: grid too small (nx=%d, ny=%d). Skipping.', dirName, nx_orig, ny_orig);
        continue;
    end
    
    ix_core = 2:nx_orig-1;
    iy_core = 2:ny_orig-1;
    
    if ~isfield(plasma, 'po')
        warning('Case %s: plasma.po (potential) missing. Skipping.', dirName);
        continue;
    end
    
    potential_full = plasma.po;
    potential_core = potential_full(ix_core, iy_core);
    finite_mask = isfinite(potential_core);
    if ~any(finite_mask(:))
        warning('Case %s: no finite potential values after removing guard cells. Skipping.', dirName);
        continue;
    end
    % 对非数值单元使用最低电势，避免 patch 绘制错误
    potential_core(~finite_mask) = caxis_range(1);
    % discrete_idx = discretizePotentialToLevels(potential_core, level_edges); % 不再需要离散化
    
    % 网格几何信息
    rc = mean(gmtry.crx, 3);
    zc = mean(gmtry.cry, 3);
    rc_core = rc(ix_core, iy_core);
    zc_core = zc(ix_core, iy_core);
    crx_core = gmtry.crx(ix_core, iy_core, :);
    cry_core = gmtry.cry(ix_core, iy_core, :);
    % 创建图窗
    fig_title = sprintf('Potential (Linear Colormap, Cell-Flat) - %s', dirName);
    figure('Name', fig_title, ...
        'NumberTitle', 'off', ...
        'Color', 'w', ...
        'Units', 'inches', 'Position', [1, 1, 14, 10]);
    ax = gca;
    hold(ax, 'on');
    % 物理网格色块绘制
    [X_patch, Y_patch, C_patch] = buildCellFlatPatch(crx_core, cry_core, potential_core);
    patch(ax, X_patch, Y_patch, C_patch, ...
        'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceAlpha', 1.0, ...
        'CDataMapping', 'scaled');
    % 线性色阶 + colorbar
    caxis(ax, caxis_range);
    colormap(ax, linear_colormap);
    h_cb = colorbar(ax);
    % set(h_cb, 'Ticks', 1:num_levels, 'TickLabels', level_labels); % 使用默认线性刻度
    ylabel(h_cb, 'Potential $\phi$ (V)', 'Interpreter', 'latex', 'FontSize', 16);
    
    % 网格结构覆盖，便于对照装置几何
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
    
    xlabel(ax, '$R$ (m)', 'Interpreter', 'latex', 'FontSize', 18);
    ylabel(ax, '$Z$ (m)', 'Interpreter', 'latex', 'FontSize', 18);
    axis(ax, 'equal');
    axis(ax, 'tight');
    grid(ax, 'on');
    box(ax, 'on');
    
    % 根据 domain 裁剪 FOV，方便快速定位偏滤器区域
    if domain ~= 0
        switch domain
            case 1
                xlim(ax, [1.30, 2.00]);
                ylim(ax, [0.50, 1.20]);
            case 2
                xlim(ax, [1.30, 2.05]);
                ylim(ax, [-1.15, -0.40]);
        end
        
        if isfield(radData, 'structure')
            plotstructure(radData.structure, 'color', 'k', 'LineWidth', 2, 'HandleVisibility', 'off');
        end
    end
    
    % 数据提示：显示最近单元中心的坐标与电势值，避免光标停在网格脚点
    dcm_obj = datacursormode(gcf);
    if isprop(dcm_obj, 'SnapToDataVertex')
        % 关闭顶点吸附，便于鼠标点击后以单元中心为准
        set(dcm_obj, 'SnapToDataVertex', 'off');
    end
    set(dcm_obj, 'UpdateFcn', {@myDataCursorUpdateFcn_SegmentedPotential, rc_core, zc_core, potential_core});
    % 保存图像，沿用统一命名规范
    saveFigureWithTimestamp(gcf, sprintf('Potential_Linear_Physical_CellFlat_%s', createSafeFilename(dirName)));
    hold(ax, 'off');
end

fprintf('Segmented potential plotting completed.\n');
end

function [X_patch, Y_patch, C_patch] = buildCellFlatPatch(crx_core, cry_core, data_core)
% 将每个单元转换为 patch 所需的四个顶点坐标，数据在单元内保持常数
[nx_core, ny_core, ~] = size(crx_core);
num_cells = nx_core * ny_core;
X_patch = zeros(4, num_cells);
Y_patch = zeros(4, num_cells);
C_patch = zeros(4, num_cells);

cell_idx = 0;
for ix = 1:nx_core
    for iy = 1:ny_core
        cell_idx = cell_idx + 1;
        xv = squeeze(crx_core(ix, iy, [1, 2, 4, 3]));
        yv = squeeze(cry_core(ix, iy, [1, 2, 4, 3]));
        X_patch(:, cell_idx) = xv;
        Y_patch(:, cell_idx) = yv;
        C_patch(:, cell_idx) = data_core(ix, iy);
    end
end
end

function linear_colors = buildLinearPotentialColormap(min_val, max_val, n_points)
% 依据文献配色设置控制点，生成线性插值的色板
key_levels = [-120, -90, -60, -30, -15, -9, -6, -4, -2, 0, 20, 40, 60, 80, 100, 125, 150];
key_colors = [
    0.90 0.90 0.95;  % 极低电势：淡灰紫
    0.84 0.82 0.93;
    0.74 0.63 0.90;
    0.64 0.45 0.82;
    0.55 0.35 0.75;
    0.46 0.30 0.72;
    0.34 0.33 0.74;
    0.26 0.38 0.78;
    0.18 0.48 0.80;  % -2V
    0.00 0.70 0.74;  % 0V 起点：青色
    0.28 0.80 0.52;  % 20V: 绿色
    0.62 0.86 0.32;  % 40V: 黄绿
    0.92 0.89 0.24;  % 60V: 黄色
    0.98 0.74 0.18;  % 80V: 橙黄
    0.94 0.55 0.12;  % 100V: 橙色
    0.85 0.25 0.09;  % 125V: 红橙
    0.70 0.05 0.06   % 150V: 深红 (终点)
    ];

% 生成线性分布的查询点
query_points = linspace(min_val, max_val, n_points);

linear_colors = zeros(n_points, 3);
for c = 1:3
    linear_colors(:, c) = interp1(key_levels, key_colors(:, c), query_points, 'pchip', 'extrap');
end
linear_colors = min(max(linear_colors, 0), 1); % 限制在[0,1]
end

function output_txt = myDataCursorUpdateFcn_SegmentedPotential(~, event_obj, rc_core, zc_core, potential_core)
% 数据光标：定位到最近单元中心，并返回中心坐标与真实电势值
pos = event_obj.Position;
R_clicked = pos(1);
Z_clicked = pos(2);

distance_sq = (rc_core - R_clicked).^2 + (zc_core - Z_clicked).^2;
[~, linear_idx] = min(distance_sq(:));
[ix, iy] = ind2sub(size(distance_sq), linear_idx);

% 单元中心坐标与电势值
R_center = rc_core(ix, iy);
Z_center = zc_core(ix, iy);
potential_val = potential_core(ix, iy);

% 尝试将数据光标位置移动到单元中心（若不支持则忽略）
try
    if numel(pos) >= 3
        event_obj.Position = [R_center, Z_center, pos(3)];
    else
        event_obj.Position = [R_center, Z_center];
    end
catch
end

output_txt = {
    sprintf('R_center = %.4f m', R_center);
    sprintf('Z_center = %.4f m', Z_center);
    sprintf('i_x = %d', ix + 1);
    sprintf('i_y = %d', iy + 1);
    sprintf('\\phi = %.2f V', potential_val)
    };
end

function safeName = createSafeFilename(originalName)
% 将目录名转换为安全的文件名片段
safeName = regexprep(originalName, '[^a-zA-Z0-9_\\-\\.]', '_');
if strlength(safeName) > 100
    safeName = safeName(1:100);
end
end

function saveFigureWithTimestamp(figHandle, baseName)
% 通用的存图函数，与旧脚本保持一致，方便自动化整理
set(figHandle, 'PaperPositionMode', 'auto');
timestampStr = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
figFile = sprintf('%s_%s.fig', baseName, timestampStr);
try
    savefig(figHandle, figFile);
    fprintf('  Figure saved: %s\n', figFile);
catch ME
    fprintf('  Warning: failed to save figure (%s).\n', ME.message);
end
end
