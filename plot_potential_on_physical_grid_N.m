function plot_potential_on_physical_grid_N(all_radiationData, domain, radial_ylim, overlay_lines, colormap_option)
% =========================================================================
% plot_potential_on_physical_grid_N - 物理网格电势分布绘图（N脚本版）
% =========================================================================
%
% 功能描述：
%   - 绘制2D物理网格上的电势分布图
%   - 可选叠加内/外偏滤器特定极向位置的线条
%   - 可选生成径向电势分布剖面图（双子图：内/外偏滤器）
%
% 输入：
%   - all_radiationData : cell数组，包含多个算例数据（需包含gmtry和plasma.po）
%   - domain            : 绘图区域（0=全域，1=上偏滤器，2=下偏滤器）
%   - radial_ylim       : 径向剖面图Y轴范围[min,max]，空则自动
%   - overlay_lines     : 是否叠加偏滤器线条（默认true）
%   - colormap_option   : 色图选择（'jet'或'custom_bwr'）
%
% 输出：
%   - 保存.fig格式图形文件
%
% 依赖函数/工具箱：
%   - surfplot, plot3sep, custom_bwr（SOLPS绘图工具）
%
% 注意事项：
%   - R2019a兼容
%   - 电势分布与杂质类型无关（N/Ne通用物理量）
%   - 极向索引基于EAST 98x28网格
% =========================================================================

%% 参数默认值设置
if nargin < 2 || isempty(domain), domain = 0; end
if nargin < 3, radial_ylim = []; end
if nargin < 4 || isempty(overlay_lines), overlay_lines = true; end
if nargin < 5 || isempty(colormap_option), colormap_option = 'jet'; end

% 验证radial_ylim
use_manual_ylim = false;
if ~isempty(radial_ylim)
    radial_ylim = sort(double(radial_ylim(:)).');
    if numel(radial_ylim) == 2 && all(isfinite(radial_ylim))
        use_manual_ylim = true;
    else
        radial_ylim = [];
    end
end

%% 全局绘图配置常量
FONT_NAME = 'Times New Roman';
FONT_SIZE_2D = 28;          % 2D图字体
FONT_SIZE_PROFILE = 48;     % 剖面图字体
LINE_WIDTH = 2.0;
OVERLAY_LINE_WIDTH = 3.0;
SEPARATRIX_WIDTH = 1.5;

% 极向网格索引配置（EAST 98x28网格）
INDICES_INNER = [74, 77, 82, 97];  % 内偏滤器关注位置
INDICES_OUTER = [2, 19, 24, 25];   % 外偏滤器关注位置

% 配色方案
COLORS_OUTER = [0.05, 0.35, 0.90; 0.00, 0.55, 0.75; 0.00, 0.72, 0.50; 0.00, 0.85, 0.30];
COLORS_INNER = [0.60, 0.05, 0.00; 0.80, 0.20, 0.00; 0.93, 0.40, 0.00; 0.98, 0.65, 0.15];

%% 设置默认字体
set(0, 'DefaultAxesFontName', FONT_NAME);
set(0, 'DefaultTextFontName', FONT_NAME);

%% 遍历所有算例
totalDirs = length(all_radiationData);
fprintf('Starting potential distribution plotting for %d cases...\n', totalDirs);

for iDir = 1:totalDirs
    dataStruct = all_radiationData{iDir};
    currentLabel = dataStruct.dirName;
    
    % --- 检查电势数据是否存在 ---
    if ~isfield(dataStruct.plasma, 'po')
        fprintf('[Warning] Potential data (po) not found in case: %s. Skipping.\n', currentLabel);
        continue;
    end
    
    fprintf('Processing case: %s...\n', currentLabel);
    
    gmtry = dataStruct.gmtry;
    potential = dataStruct.plasma.po;
    
    %% ===== 绘制2D电势分布图 =====
    figName = sprintf('Potential Distribution: %s', currentLabel);
    fig1 = figure('Name', figName, 'NumberTitle', 'off', 'Color', 'w', ...
        'Units', 'inches', 'Position', [1 1 9 9], 'PaperPositionMode', 'auto');
    
    % 设置字体
    set(fig1, 'DefaultAxesFontName', FONT_NAME, ...
        'DefaultTextFontName', FONT_NAME, ...
        'DefaultAxesFontSize', FONT_SIZE_2D, ...
        'DefaultTextFontSize', FONT_SIZE_2D);
    
    hold on;
    
    % 绘制云图
    surfplot(gmtry, potential);
    shading interp;
    view(2);
    
    % 设置Colormap
    if strcmpi(colormap_option, 'jet')
        colormap(jet);
    else
        colormap(custom_bwr(256));
    end
    caxis([-150, 150]);  % 固定电势范围
    
    % 设置Colorbar
    cb = colorbar;
    set(cb, 'FontSize', FONT_SIZE_2D - 2, 'LineWidth', LINE_WIDTH, 'TickLabelInterpreter', 'tex');
    
    % 绘制分离面
    plot3sep(gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', SEPARATRIX_WIDTH);
    
    % 设置坐标轴
    xlabel('$R$ (m)', 'FontSize', FONT_SIZE_2D, 'Interpreter', 'latex');
    ylabel('$Z$ (m)', 'FontSize', FONT_SIZE_2D, 'Interpreter', 'latex');
    title('$\phi$ (V)', 'FontSize', FONT_SIZE_2D, 'Interpreter', 'latex');
    axis equal;
    box on; grid on;
    set(gca, 'FontSize', FONT_SIZE_2D, 'LineWidth', LINE_WIDTH, 'TickLabelInterpreter', 'latex');
    
    % 数据游标
    dcm = datacursormode(gcf);
    set(dcm, 'UpdateFcn', @(src, evt) datacursor_callback(src, evt, gmtry, potential));
    
    % 区域缩放
    if domain == 1
        xlim([1.30, 1.90]); ylim([0.60, 1.20]);
        set(gca, 'XTick', 1.3:0.2:1.9, 'YTick', 0.6:0.2:1.2);
    elseif domain == 2
        xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
        set(gca, 'XTick', 1.3:0.15:2.05, 'YTick', -1.15:0.15:-0.40);
    end
    
    % 绘制结构（如果有结构数据）
    if domain ~= 0 && isfield(dataStruct, 'structure')
        plotstructure(dataStruct.structure, 'color', 'k', 'LineWidth', 2);
    end
    
    % 叠加偏滤器线条
    if overlay_lines
        [rCenter, zCenter] = compute_cell_centers(gmtry.crx, gmtry.cry);
        [nxd, ~] = size(gmtry.crx);
        
        % 内偏滤器（实线，暖色）
        for k = 1:length(INDICES_INNER)
            ix = INDICES_INNER(k);
            if ix <= nxd
                color = COLORS_INNER(min(k, size(COLORS_INNER, 1)), :);
                plot(rCenter(ix, :), zCenter(ix, :), 'Color', color, ...
                    'LineWidth', OVERLAY_LINE_WIDTH, 'LineStyle', '-');
            end
        end
        
        % 外偏滤器（虚线，冷色）
        for k = 1:length(INDICES_OUTER)
            ix = INDICES_OUTER(k);
            if ix <= nxd
                color = COLORS_OUTER(min(k, size(COLORS_OUTER, 1)), :);
                plot(rCenter(ix, :), zCenter(ix, :), 'Color', color, ...
                    'LineWidth', OVERLAY_LINE_WIDTH, 'LineStyle', '--');
            end
        end
    end
    
    % 固定axes和colorbar位置
    ax = gca;
    set(ax, 'Units', 'normalized', 'Position', [0.20 0.18 0.60 0.60]);
    set(ax, 'TickLength', [0 0]);
    set(cb, 'Units', 'normalized', 'Position', [0.84 0.18 0.04 0.60]);
    
    % colorbar刻度格式化
    phi_ticks = -150:50:150;
    phi_tick_labels = cell(size(phi_ticks));
    for k = 1:numel(phi_ticks)
        phi_tick_labels{k} = sprintf('%d', phi_ticks(k));
    end
    set(cb, 'Ticks', phi_ticks, 'TickLabels', phi_tick_labels);
    
    % 保存2D图
    save_figure_with_timestamp('Potential_Distribution_2D');
    hold off;
    
    %% ===== 绘制径向电势剖面图（如果启用叠加线条） =====
    if overlay_lines
        % 计算剖面数据
        [inner_profiles, inner_y] = compute_radial_profiles(gmtry, potential, INDICES_INNER);
        [outer_profiles, outer_y] = compute_radial_profiles(gmtry, potential, INDICES_OUTER);
        
        if ~isempty(inner_profiles) || ~isempty(outer_profiles)
            % 确定X轴范围
            all_y = [inner_y{:}, outer_y{:}];
            x_range = [floor(min(all_y)), ceil(max(all_y))];
            
            % 创建剖面图
            figName2 = sprintf('Radial Potential Profiles: %s', currentLabel);
            fig2 = figure('Name', figName2, 'NumberTitle', 'off', 'Color', 'w', ...
                'Units', 'pixels', 'Position', [200 100 1600 1200]);
            
            set(fig2, 'DefaultAxesFontName', FONT_NAME, ...
                'DefaultTextFontName', FONT_NAME, ...
                'DefaultAxesFontSize', FONT_SIZE_PROFILE, ...
                'DefaultTextFontSize', FONT_SIZE_PROFILE);
            
            % 子图1：外偏滤器
            subplot(2, 1, 1);
            hold on;
            for k = 1:length(outer_profiles)
                color = COLORS_OUTER(min(k, size(COLORS_OUTER, 1)), :);
                plot(outer_y{k}, outer_profiles{k}, 'Color', color, ...
                    'LineWidth', 2.5, 'LineStyle', '--', ...
                    'DisplayName', sprintf('ix=%d', INDICES_OUTER(k)));
            end
            curr_ylim_out = ylim;
            if use_manual_ylim, curr_ylim_out = radial_ylim; end
            plot([0, 0], curr_ylim_out, 'k--', 'LineWidth', 2, 'DisplayName', 'Separatrix');
            xlim(x_range);
            if use_manual_ylim, ylim(radial_ylim); end
            grid on; box on;
            set(gca, 'FontSize', FONT_SIZE_PROFILE + 4, 'LineWidth', LINE_WIDTH, ...
                'TickLabelInterpreter', 'latex', 'XTickLabel', []);
            pbaspect([2, 1, 1]);
            hold off;
            
            % 子图2：内偏滤器
            subplot(2, 1, 2);
            hold on;
            for k = 1:length(inner_profiles)
                color = COLORS_INNER(min(k, size(COLORS_INNER, 1)), :);
                plot(inner_y{k}, inner_profiles{k}, 'Color', color, ...
                    'LineWidth', 2.5, 'LineStyle', '-', ...
                    'DisplayName', sprintf('ix=%d', INDICES_INNER(k)));
            end
            curr_ylim_in = ylim;
            if use_manual_ylim, curr_ylim_in = radial_ylim; end
            plot([0, 0], curr_ylim_in, 'k--', 'LineWidth', 2, 'DisplayName', 'Separatrix');
            xlim(x_range);
            if use_manual_ylim, ylim(radial_ylim); end
            grid on; box on;
            set(gca, 'FontSize', FONT_SIZE_PROFILE + 4, 'LineWidth', LINE_WIDTH, ...
                'TickLabelInterpreter', 'latex');
            xlabel('$r - r_{\mathrm{sep}}$ (cm)', 'FontSize', FONT_SIZE_PROFILE + 8, 'Interpreter', 'latex');
            pbaspect([2, 1, 1]);
            hold off;
            
            % 保存剖面图
            save_figure_with_timestamp('Radial_Potential_Profiles');
        end
    end
end

fprintf('>>> Completed: Potential distribution plotting finished for all cases.\n');

end


%% =========================================================================
% 辅助函数：计算网格中心坐标
% =========================================================================
function [rCenter, zCenter] = compute_cell_centers(crx, cry)
rCenter = mean(crx, 3);
zCenter = mean(cry, 3);
end


%% =========================================================================
% 辅助函数：计算径向电势剖面
% =========================================================================
function [profiles, y_coords] = compute_radial_profiles(gmtry, potential, indices)
profiles = {};
y_coords = {};
[nxd, ~] = size(gmtry.crx);

for k = 1:length(indices)
    ix = indices(k);
    if ix <= nxd
        % 计算径向坐标
        hy = gmtry.hy(ix, :);
        y_edge = [0, cumsum(hy)];
        y_center = 0.5 * (y_edge(1:end-1) + y_edge(2:end));
        
        % 确定分离面位置（通常在网格13和14之间）
        if length(y_center) >= 14
            y_sep = y_center(13) + 0.5 * hy(13);
        else
            y_sep = y_center(1);
        end
        
        % 转换为相对分离面的距离（cm）
        y_rel = (y_center - y_sep) * 100;
        
        profiles{end+1} = potential(ix, :); %#ok<AGROW>
        y_coords{end+1} = y_rel; %#ok<AGROW>
    end
end
end


%% =========================================================================
% 辅助函数：保存图形
% =========================================================================
function save_figure_with_timestamp(baseName)
set(gcf, 'PaperPositionMode', 'auto');
timestampStr = datestr(now, 'yyyymmdd_HHMMSS_FFF');
figFile = sprintf('%s_%s.fig', baseName, timestampStr);
savefig(figFile);
fprintf('Figure saved: %s\n', figFile);
end


%% =========================================================================
% 辅助函数：数据游标回调
% =========================================================================
function txt = datacursor_callback(~, event_obj, gmtry, potential_data)
pos = get(event_obj, 'Position');
R_click = pos(1); Z_click = pos(2);

[rCenter, zCenter] = compute_cell_centers(gmtry.crx, gmtry.cry);
dists = (rCenter - R_click).^2 + (zCenter - Z_click).^2;
[~, min_idx] = min(dists(:));
[ix, iy] = ind2sub(size(dists), min_idx);

val = potential_data(ix, iy);
txt = {sprintf('R: %.4f m', R_click), ...
    sprintf('Z: %.4f m', Z_click), ...
    sprintf('phi: %.2f V', val), ...
    sprintf('ix: %d, iy: %d', ix, iy)};
end
