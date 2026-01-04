function plot_N_ion_density_physical_grid_cellflat(all_radiationData, domain, varargin)
% PLOT_N_ION_DENSITY_PHYSICAL_GRID_CELLFLAT
%   基于物理网格绘制 N 杂质离子密度分布（单元块颜色保持一致，无通量箭头）。
%   背景色图：N离子密度（可选单价态或多价态总和），使用 patch 将每个物理单元作为独立色块。
%   适配N体系（N1+-N7+），基于Ne版本修改。
%
%   可选参数：
%     'use_custom_colormap' (logical) - 是否加载 mycontour.mat 中的 colormap，默认 false。
%     'charge_states' (numeric array) - 要绘制的价态索引（1-7对应N1+到N7+），默认 1:7。
%     'clim_range' (numeric array) - colorbar范围，[min, max]，空数组表示使用默认自动缩放（默认[]）。

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

% 全局字体设置（增大字体以适应A4双栏印刷）
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 20);
set(0, 'DefaultTextFontSize', 20);
set(0, 'DefaultLineLineWidth', 2.0);
set(0, 'DefaultLegendFontName', 'Times New Roman');
set(0, 'DefaultLegendFontSize', 18);
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

% 将价态索引（1-7）转换为species索引（4-10）
% SOLPS粒子索引规则：1=D0, 2=D+, 3=N0中性杂质, 4=N1+, ..., 10=N7+
species_indices = charge_states + 3;  % N1+ = species 4, N7+ = species 10

for i_case = 1:numel(all_radiationData)
    radData = all_radiationData{i_case};
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    dirName = radData.dirName;
    
    % 生成价态描述字符串
    if numel(charge_states) == 1
        charge_state_desc = sprintf('N%d+', charge_states(1));
    elseif isequal(charge_states, 1:7)
        charge_state_desc = 'N1+-N7+ (total)';
    else
        charge_state_desc = sprintf('N%d+-N%d+ (selected)', min(charge_states), max(charge_states));
    end
    
    fprintf('Processing case for N ion density (cell-flat color, no arrows) on physical grid: %s\n', dirName);
    fprintf('  Charge states: %s\n', charge_state_desc);
    
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
    
    if ~isfield(plasma, 'na')
        warning('Case %s: plasma.na missing. Skipping.', dirName);
        continue;
    end
    
    total_density_full = zeros(nx_orig, ny_orig);
    
    for i_species = species_indices
        if size(plasma.na, 3) < i_species
            warning('  Species index %d (N%d+) not available in data. Skipping.', i_species, i_species - 3);
            continue;
        end
        total_density_full = total_density_full + plasma.na(:, :, i_species);
    end
    
    density_core = total_density_full(ix_core, iy_core);
    
    finite_mask = isfinite(density_core);
    if ~any(finite_mask(:))
        warning('Case %s: no finite density values after removing guard cells. Skipping.', dirName);
        continue;
    end
    
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
    
    % 设置colorbar范围（使用用户指定的范围或默认自动缩放）
    if ~isempty(clim_range)
        clim_min = clim_range(1);
        clim_max = clim_range(2);
    else
        clim_min = max(min_positive * 0.5, 1e14);
        clim_max = max_density * 1.1;
    end
    
    rc = mean(gmtry.crx, 3);
    zc = mean(gmtry.cry, 3);
    rc_core = rc(ix_core, iy_core);
    zc_core = zc(ix_core, iy_core);
    
    crx_core = gmtry.crx(ix_core, iy_core, :);
    cry_core = gmtry.cry(ix_core, iy_core, :);
    
    fig_title = sprintf('N Ion Density (%s) - %s', charge_state_desc, dirName);
    figure('Name', fig_title, ...
        'NumberTitle', 'off', ...
        'Color', 'w', ...
        'Units', 'inches', 'Position', [1, 1, 14, 10]);
    ax = gca;
    hold(ax, 'on');
    
    % --- 物理网格色块绘制（每个单元统一颜色） ---
    [X_patch, Y_patch, C_patch] = buildCellFlatPatch(crx_core, cry_core, density_for_plot);
    patch(ax, X_patch, Y_patch, C_patch, ...
        'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceAlpha', 1.0, 'CDataMapping', 'scaled');
    
    set(ax, 'ColorScale', 'log');
    caxis(ax, [clim_min, clim_max]);
    
    if use_custom_colormap
        try
            load('mycontour.mat', 'mycontour');
            colormap(ax, mycontour);
            fprintf('  Using custom colormap from mycontour.mat\n');
        catch ME
            fprintf('  Warning: failed to load mycontour.mat (%s). Using default jet colormap.\n', ME.message);
            colormap(ax, 'jet');
        end
    else
        colormap(ax, 'jet');
    end
    
    h_cb = colorbar(ax);
    h_cb.FontSize = 18;  % 增大colorbar刻度标签字体
    
    % 构建colorbar标签（N体系）
    if numel(charge_states) == 1
        cb_label = sprintf('N$^{%d+}$ Density ($\\mathrm{m^{-3}}$)', charge_states(1));
    elseif isequal(charge_states, 1:7)
        cb_label = 'N$^{1+}$-N$^{7+}$ Density ($\\mathrm{m^{-3}}$)';
    else
        cb_label = sprintf('N$^{%d+}$-N$^{%d+}$ Density ($\\mathrm{m^{-3}}$)', min(charge_states), max(charge_states));
    end
    
    ylabel(h_cb, cb_label, 'Interpreter', 'latex', 'FontSize', 20);
    
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
    
    xlabel(ax, '$R$ (m)', 'Interpreter', 'latex', 'FontSize', 22);
    ylabel(ax, '$Z$ (m)', 'Interpreter', 'latex', 'FontSize', 22);
    axis(ax, 'equal');
    axis(ax, 'tight');
    grid(ax, 'on');
    box(ax, 'on');
    
    % 增大坐标轴刻度标签字体
    ax.FontSize = 18;
    
    % 根据 domain 裁剪可视区域
    if domain ~= 0
        switch domain
            case 1
                xlim(ax, [1.40, 1.90]);
                ylim(ax, [0.60, 1.10]);
            case 2
                xlim(ax, [1.30, 2.05]);
                ylim(ax, [-1.15, -0.40]);
        end
        
        if isfield(radData, 'structure')
            plotstructure(radData.structure, 'color', 'k', 'LineWidth', 2, 'HandleVisibility', 'off');
        end
    end
    
    dcm_obj = datacursormode(gcf);
    set(dcm_obj, 'UpdateFcn', {@myDataCursorUpdateFcn_NeDensityPhysical, rc_core, zc_core, density_core});
    
    % 生成文件名后缀（N体系）
    if numel(charge_states) == 1
        charge_suffix = sprintf('N%d', charge_states(1));
    elseif isequal(charge_states, 1:7)
        charge_suffix = 'N1-7';
    else
        charge_suffix = sprintf('N%d-%d', min(charge_states), max(charge_states));
    end
    
    saveFigureWithTimestamp(gcf, sprintf('NIon_Density_Physical_CellFlat_%s_%s', ...
        charge_suffix, createSafeFilename(dirName)));
    hold(ax, 'off');
end

fprintf('N ion density (physical grid, cell-flat, no arrows) plotting completed.\n');
end

function [X_patch, Y_patch, C_patch] = buildCellFlatPatch(crx_core, cry_core, density_core)
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
        C_patch(:, cell_idx) = density_core(ix, iy);
    end
end
end

function output_txt = myDataCursorUpdateFcn_NDensityPhysical(~, event_obj, rc_core, zc_core, density_core)
pos = event_obj.Position;
R = pos(1);
Z = pos(2);

distance_sq = (rc_core - R).^2 + (zc_core - Z).^2;
[~, linear_idx] = min(distance_sq(:));
[ix, iy] = ind2sub(size(distance_sq), linear_idx);

density_val = density_core(ix, iy);

output_txt = {
    sprintf('R = %.4f m', R);
    sprintf('Z = %.4f m', Z);
    sprintf('i_x = %d', ix + 1);
    sprintf('i_y = %d', iy + 1);
    sprintf('n_{N,total} = %.3e m^{-3}', density_val)
    };
end

function safeName = createSafeFilename(originalName)
safeName = regexprep(originalName, '[^a-zA-Z0-9_\-\.]', '_');
if strlength(safeName) > 100
    safeName = safeName(1:100);
end
end

function saveFigureWithTimestamp(figHandle, baseName)
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

