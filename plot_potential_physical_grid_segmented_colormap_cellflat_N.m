function plot_potential_physical_grid_segmented_colormap_cellflat_N(all_radiationData, domain)
% =========================================================================
% plot_potential_physical_grid_segmented_colormap_cellflat_N - 电势分布图（N脚本版）
% =========================================================================
%
% 功能描述：
%   - 绘制物理网格上的电势分布图（cell-flat模式，单元内颜色一致）
%   - 使用分段式colormap突出电势阱位置
%   - 正负值使用完全不同的色系（负值：蓝紫色系，正值：橙红色系）
%   - 特别增强绝对值较小负值（-30V到0V）区域的颜色分辨率
%
% 输入：
%   - all_radiationData : cell数组，包含多个算例数据
%   - domain            : 绘图区域（0=全域，1=上偏滤器，2=下偏滤器）
%
% 输出：
%   - 电势分布figure
%   - 自动保存带时间戳的.fig文件
%
% 依赖函数/工具箱：
%   - plot3sep, plotgrid_new, plotplasmaboundary, plotstructure（SOLPS工具）
%
% 注意事项：
%   - R2019a兼容
%   - colormap范围：[-100, 150] V
%   - 负值到0区域使用更多颜色级别以提高分辨率
% =========================================================================

%% 参数默认值
if nargin < 2 || isempty(domain)
    domain = 0;
end

%% 全局绘图设置（仅设置解释器和字体类型，字体大小在保存前显式设置）
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultLegendFontName', 'Times New Roman');
set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

%% 色阶范围与colormap构建
% 电势范围：[-100, 150] V
CAXIS_MIN = -100;
CAXIS_MAX = 150;
N_COLORS = 256;

% 构建增强分辨率的colormap
% 核心设计：
%   - 负值区域（-100到0）使用蓝紫色系，占据更多颜色级别
%   - 正值区域（0到150）使用橙红黄色系
%   - 在-30V到0V区间使用更密集的颜色过渡以提高分辨率
enhanced_colormap = build_enhanced_potential_colormap(CAXIS_MIN, CAXIS_MAX, N_COLORS);

%% 遍历所有算例
for i_case = 1:numel(all_radiationData)
    radData = all_radiationData{i_case};
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    dirName = radData.dirName;
    
    fprintf('Processing case: %s\n', dirName);
    
    % --- 数据完整性检查 ---
    if ~isfield(gmtry, 'crx') || ~isfield(gmtry, 'cry')
        warning('plot_potential:MissingGeometry', ...
            'Case %s: gmtry.crx/cry not found. Skipping.', dirName);
        continue;
    end
    
    nx_orig = size(gmtry.crx, 1);
    ny_orig = size(gmtry.crx, 2);
    if nx_orig < 3 || ny_orig < 3
        warning('plot_potential:SmallGrid', ...
            'Case %s: grid too small (nx=%d, ny=%d). Skipping.', dirName, nx_orig, ny_orig);
        continue;
    end
    
    if ~isfield(plasma, 'po')
        warning('plot_potential:MissingPotential', ...
            'Case %s: plasma.po not found. Skipping.', dirName);
        continue;
    end
    
    % --- 提取核心网格（去除guard cells） ---
    ix_core = 2:nx_orig-1;
    iy_core = 2:ny_orig-1;
    
    potential_full = plasma.po;
    potential_core = potential_full(ix_core, iy_core);
    
    % 处理非有限值
    finite_mask = isfinite(potential_core);
    if ~any(finite_mask(:))
        warning('plot_potential:NoFiniteData', ...
            'Case %s: no finite potential values. Skipping.', dirName);
        continue;
    end
    potential_core(~finite_mask) = CAXIS_MIN;  % 非有限值设为最低电势
    
    % --- 网格几何信息 ---
    rc = mean(gmtry.crx, 3);  % 网格中心R坐标
    zc = mean(gmtry.cry, 3);  % 网格中心Z坐标
    rc_core = rc(ix_core, iy_core);
    zc_core = zc(ix_core, iy_core);
    crx_core = gmtry.crx(ix_core, iy_core, :);
    cry_core = gmtry.cry(ix_core, iy_core, :);
    
    %% 创建Figure
    fig_title = sprintf('Potential Distribution (Enhanced Colormap) - %s', dirName);
    fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
        'Units', 'inches', 'Position', [1, 1, 14, 10]);
    ax = gca;
    hold(ax, 'on');
    
    %% 绘制cell-flat色块
    % 将每个网格单元转换为四边形patch
    [nx_core, ny_core, ~] = size(crx_core);
    num_cells = nx_core * ny_core;
    X_patch = zeros(4, num_cells);
    Y_patch = zeros(4, num_cells);
    C_patch = zeros(4, num_cells);
    
    cell_idx = 0;
    for ix = 1:nx_core
        for iy = 1:ny_core
            cell_idx = cell_idx + 1;
            % 四个顶点坐标（顺序：左下、右下、右上、左上）
            xv = squeeze(crx_core(ix, iy, [1, 2, 4, 3]));
            yv = squeeze(cry_core(ix, iy, [1, 2, 4, 3]));
            X_patch(:, cell_idx) = xv;
            Y_patch(:, cell_idx) = yv;
            C_patch(:, cell_idx) = potential_core(ix, iy);  % 单元内颜色一致
        end
    end
    
    % 绘制patch
    patch(ax, X_patch, Y_patch, C_patch, ...
        'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceAlpha', 1.0, ...
        'CDataMapping', 'scaled');
    
    %% 设置colormap和colorbar
    caxis(ax, [CAXIS_MIN, CAXIS_MAX]);
    colormap(ax, enhanced_colormap);
    
    h_cb = colorbar(ax);
    % colorbar不设置ylabel，标题放在子图上方
    
    %% 绘制网格结构覆盖
    % 分离面
    try
        plot3sep(gmtry, 'color', 'k', 'LineStyle', '--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
    catch
    end
    
    % 网格线
    try
        plotgrid_new(gmtry, 'all3', 'color', [0.3 0.3 0.3], 'LineWidth', 0.2, 'HandleVisibility', 'off');
    catch
    end
    
    % 等离子体边界
    try
        plotplasmaboundary(gmtry, 'color', 'k', 'LineStyle', '-', 'LineWidth', 1.0, 'HandleVisibility', 'off');
    catch
    end
    
    %% 设置坐标轴
    xlabel(ax, '$R$ (m)', 'Interpreter', 'latex', 'FontSize', 32);
    ylabel(ax, '$Z$ (m)', 'Interpreter', 'latex', 'FontSize', 32);
    title(ax, '$\phi$ (V)', 'Interpreter', 'latex', 'FontSize', 32);
    axis(ax, 'equal');
    axis(ax, 'tight');
    grid(ax, 'on');
    box(ax, 'on');
    
    %% 区域缩放
    if domain == 1
        % 上偏滤器区域（参考参考图片范围）
        xlim(ax, [1.30, 1.90]);
        ylim(ax, [0.60, 1.20]);
        % 显式设置刻度，确保首尾显示明确数值
        set(ax, 'XTick', 1.3:0.2:1.9, 'YTick', 0.6:0.2:1.2);
        if isfield(radData, 'structure')
            plotstructure(radData.structure, 'color', 'k', 'LineWidth', 2, 'HandleVisibility', 'off');
        end
    elseif domain == 2
        % 下偏滤器区域
        xlim(ax, [1.30, 1.90]);
        ylim(ax, [-1.10, -0.50]);
        % 显式设置刻度，确保首尾显示明确数值
        set(ax, 'XTick', 1.3:0.2:1.9, 'YTick', -1.1:0.2:-0.5);
        if isfield(radData, 'structure')
            plotstructure(radData.structure, 'color', 'k', 'LineWidth', 2, 'HandleVisibility', 'off');
        end
    end
    
    %% 数据游标
    dcm_obj = datacursormode(gcf);
    if isprop(dcm_obj, 'SnapToDataVertex')
        set(dcm_obj, 'SnapToDataVertex', 'off');
    end
    set(dcm_obj, 'UpdateFcn', @(src, evt) datacursor_potential(src, evt, rc_core, zc_core, potential_core));
    
    %% 保存Figure前：显式设置字体大小（确保跨平台兼容性）
    % 问题：全局默认设置在跨MATLAB版本/平台时可能失效
    % 解决：直接在坐标轴对象上设置字体属性
    TICK_FONT_SIZE = 28;     % 坐标轴刻度数字字体大小
    LABEL_FONT_SIZE = 32;    % 坐标轴标签字体大小
    COLORBAR_FONT_SIZE = 24; % colorbar刻度字体大小
    
    set(ax, 'FontSize', TICK_FONT_SIZE, 'FontName', 'Times New Roman');
    set(h_cb, 'FontSize', COLORBAR_FONT_SIZE, 'FontName', 'Times New Roman');
    
    % 重新设置标签字体（确保不被覆盖）
    xlabel(ax, '$R$ (m)', 'Interpreter', 'latex', 'FontSize', LABEL_FONT_SIZE);
    ylabel(ax, '$Z$ (m)', 'Interpreter', 'latex', 'FontSize', LABEL_FONT_SIZE);
    title(ax, '$\phi$ (V)', 'Interpreter', 'latex', 'FontSize', LABEL_FONT_SIZE);
    
    %% 保存Figure
    safe_name = regexprep(dirName, '[^a-zA-Z0-9_\-\.]', '_');
    if length(safe_name) > 100
        safe_name = safe_name(1:100);
    end
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    fname = sprintf('Potential_Enhanced_CellFlat_%s_%s.fig', safe_name, timestamp);
    
    set(fig, 'PaperPositionMode', 'auto');
    try
        savefig(fig, fname);
        fprintf('  Figure saved: %s\n', fname);
    catch ME
        fprintf('  Warning: failed to save figure (%s)\n', ME.message);
    end
    
    hold(ax, 'off');
end

fprintf('Potential plotting completed.\n');

end


%% =========================================================================
% 辅助函数：构建增强分辨率的电势colormap
% =========================================================================
function cmap = build_enhanced_potential_colormap(min_val, max_val, n_points)
% 设计理念：
%   - 负值区域使用冷色系（蓝紫青），正值区域使用暖色系（黄橙红）
%   - 在-30V到0V区间使用更密集的颜色级别以提高分辨率
%   - 0V处使用浅黄色作为暖色系起点，与负值冷色系形成明显对比

% 关键电势值控制点及对应颜色
% 负值区域：蓝紫色系（深紫→蓝→青）
% 正值区域：暖色系（浅黄→黄→橙→红）
key_levels = [...
    -120, ...   % 极低电势（深紫）
    -100, ...   % 最低显示值
    -70, ...    % 中等负电势
    -50, ...    %
    -30, ...    % 开始增强分辨率区域
    -20, ...    %
    -15, ...    %
    -10, ...    %
    -5, ...     %
    -2, ...     %
    0, ...      % 零点（浅黄，暖色系起点）
    10, ...     % 低正电势
    30, ...     %
    50, ...     %
    80, ...     %
    100, ...    %
    125, ...    %
    150, ...    % 最高显示值
    180         % 超出范围（深红）
    ];

% 对应颜色定义
% 负值：深紫→紫→蓝→青（冷色系）
% 正值：浅黄→黄→橙→红（暖色系，从0V开始）
key_colors = [...
    0.20, 0.05, 0.40;   % -120V: 极深紫
    0.30, 0.10, 0.55;   % -100V: 深紫
    0.40, 0.20, 0.70;   % -70V: 紫色
    0.45, 0.30, 0.80;   % -50V: 蓝紫
    0.35, 0.45, 0.85;   % -30V: 蓝色
    0.25, 0.55, 0.88;   % -20V: 中蓝
    0.20, 0.65, 0.90;   % -15V: 浅蓝
    0.20, 0.75, 0.90;   % -10V: 青蓝
    0.30, 0.85, 0.85;   % -5V: 青色
    0.50, 0.92, 0.80;   % -2V: 浅青
    0.98, 0.98, 0.70;   % 0V: 浅黄（暖色系起点，与负值形成明显对比）
    0.95, 0.92, 0.45;   % +10V: 黄色
    0.95, 0.85, 0.25;   % +30V: 金黄
    0.98, 0.70, 0.18;   % +50V: 橙黄
    0.95, 0.50, 0.12;   % +80V: 橙色
    0.90, 0.35, 0.10;   % +100V: 红橙
    0.80, 0.20, 0.08;   % +125V: 红色
    0.65, 0.10, 0.05;   % +150V: 深红
    0.50, 0.05, 0.02    % +180V: 极深红
    ];

% 生成线性分布的查询点
query_points = linspace(min_val, max_val, n_points);

% 对每个颜色通道进行插值
cmap = zeros(n_points, 3);
for c = 1:3
    cmap(:, c) = interp1(key_levels, key_colors(:, c), query_points, 'pchip', 'extrap');
end

% 限制在[0, 1]范围内
cmap = min(max(cmap, 0), 1);

end


%% =========================================================================
% 辅助函数：数据游标回调
% =========================================================================
function output_txt = datacursor_potential(~, event_obj, rc_core, zc_core, potential_core)
% 定位到最近单元中心，显示坐标与电势值

pos = event_obj.Position;
R_clicked = pos(1);
Z_clicked = pos(2);

% 找到最近的网格中心
distance_sq = (rc_core - R_clicked).^2 + (zc_core - Z_clicked).^2;
[~, linear_idx] = min(distance_sq(:));
[ix, iy] = ind2sub(size(distance_sq), linear_idx);

R_center = rc_core(ix, iy);
Z_center = zc_core(ix, iy);
potential_val = potential_core(ix, iy);

% 尝试移动光标到单元中心
try
    if numel(pos) >= 3
        event_obj.Position = [R_center, Z_center, pos(3)];
    else
        event_obj.Position = [R_center, Z_center];
    end
catch
end

output_txt = {...
    sprintf('R = %.4f m', R_center), ...
    sprintf('Z = %.4f m', Z_center), ...
    sprintf('ix = %d', ix + 1), ...
    sprintf('iy = %d', iy + 1), ...
    sprintf('phi = %.2f V', potential_val)};
end
