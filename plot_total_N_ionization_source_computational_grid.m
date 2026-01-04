function plot_total_N_ionization_source_computational_grid(all_radiationData)
% =========================================================================
% plot_total_N_ionization_source_computational_grid - 计算网格上总N离子源项（sna）分布
% =========================================================================
%
% 功能描述：
%   读取 all_radiationData 中的 plasma.sna 与 plasma.na，计算 N1+ 至 N7+
%   的总电离源强度，并在计算网格上以对数色标绘制。鼠标移动/点击时，数据游标
%   会显示当前单元的完整物理量信息（总源项、单元体积、各价态贡献、对应密度）。
%
% 输入：
%   all_radiationData - SOLPS 后处理得到的元胞数组，要求字段：
%       .plasma.sna (nx, ny, 2, >=13) - sna 系数
%       .plasma.na  (nx, ny, >=13)    - N 离子密度
%       .gmtry.vol  (nx, ny)          - 单元体积
%
% 输出：
%   生成图像窗口，并在当前目录保存 .fig 文件（附时间戳）。
%
% 使用示例：
%   plot_total_N_ionization_source_computational_grid(all_radiationData);
%
% 依赖函数：
%   无（仅使用 MATLAB 内置函数）
%
% 注意事项：
%   - 使用 sna 数据（sna(:,:,1,:) + sna(:,:,2,:).*na）计算，结果单位 m^-3 s^-1。
%   - 去除两层保护单元，仅绘制物理区域。
%   - 兼容 MATLAB R2019a，不使用 tiledlayout 等新特性。
%
% =========================================================================

%% 基本输入检查
if nargin < 1 || isempty(all_radiationData)
    error('Input all_radiationData is empty. Please load SOLPS data first.');
end

%% 设置绘图默认值
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 18);
set(0, 'DefaultTextFontSize', 18);
set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'DefaultLegendFontName', 'Times New Roman');
set(0, 'DefaultLegendFontSize', 16);
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

%% 遍历各算例并绘制
for i_case = 1:length(all_radiationData)
    radData = all_radiationData{i_case};
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    dirName = radData.dirName;
    fprintf('\n=== Processing case (sna source): %s ===\n', dirName);
    
    % ------------------------- 网格与数据检查 -------------------------
    [nx_orig, ny_orig] = getGridSize(gmtry);
    if isempty(nx_orig)
        warning('Case %s: Grid information is invalid, skip.', dirName);
        continue;
    end
    
    if ~isfield(plasma, 'sna') || size(plasma.sna, 3) < 2 || size(plasma.sna, 4) < 4
        warning('Case %s: sna data is missing or incomplete, skip.', dirName);
        continue;
    end
    if ~isfield(plasma, 'na') || size(plasma.na, 3) < 4
        warning('Case %s: na data is missing or incomplete, skip.', dirName);
        continue;
    end
    if ~isfield(gmtry, 'vol')
        warning('Case %s: gmtry.vol is missing, skip.', dirName);
        continue;
    end
    
    % sna 第4维 4~10 对应 N1+~N7+
    max_charge_state = min(7, size(plasma.sna, 4) - 3);
    if max_charge_state < 1
        warning('Case %s: No N charge state found in sna, skip.', dirName);
        continue;
    end
    
    % ------------------------- 计算源项 -------------------------
    vol_full = gmtry.vol;
    vol_full(~isfinite(vol_full) | vol_full <= 0) = NaN; % 体积异常直接置 NaN
    
    total_source_full = zeros(nx_orig, ny_orig);                   % 总源项 (m^-3 s^-1)
    charge_source_full = zeros(nx_orig, ny_orig, max_charge_state);% 各价态源项 (m^-3 s^-1)
    charge_density_full = zeros(nx_orig, ny_orig, max_charge_state);% 各价态密度 (m^-3)
    
    for jPos = 1:ny_orig
        for iPos = 1:nx_orig
            for ic = 1:max_charge_state
                sna_idx = 3 + ic; % sna 第4维索引
                coeff0 = plasma.sna(iPos, jPos, 1, sna_idx);
                coeff1 = plasma.sna(iPos, jPos, 2, sna_idx);
                n_charge = plasma.na(iPos, jPos, sna_idx);
                
                charge_density_full(iPos, jPos, ic) = n_charge;
                
                source_particle = coeff0 + coeff1 * n_charge; % 单元粒子数/秒
                if isfinite(vol_full(iPos, jPos))
                    source_density = source_particle ./ vol_full(iPos, jPos); % m^-3 s^-1
                else
                    source_density = NaN;
                end
                charge_source_full(iPos, jPos, ic) = source_density;
                total_source_full(iPos, jPos) = total_source_full(iPos, jPos) + source_density;
            end
        end
    end
    
    % 去除保护单元（仅显示物理区域）
    nx_plot = nx_orig - 2;
    ny_plot = ny_orig - 2;
    total_source_plot = total_source_full(2:nx_orig-1, 2:ny_orig-1);
    charge_source_plot = charge_source_full(2:nx_orig-1, 2:ny_orig-1, :);
    charge_density_plot = charge_density_full(2:nx_orig-1, 2:ny_orig-1, :);
    vol_plot = vol_full(2:nx_orig-1, 2:ny_orig-1);
    
    % 处理对数色标的最小正值
    positive_vals = total_source_plot(total_source_plot > 0);
    if isempty(positive_vals)
        min_positive = 1e-5; % 极端情况下避免空集
    else
        min_positive = min(positive_vals);
    end
    total_for_display = total_source_plot;
    total_for_display(total_for_display <= 0) = 0.1 * min_positive;
    
    % ------------------------- 绘图 -------------------------
    fig_title = sprintf('Total N Ionization Source (sna) - %s', dirName);
    fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
        'Units', 'inches', 'Position', [1, 1, 11, 8]);
    ax = axes(fig);
    hold(ax, 'on');
    
    imagesc(ax, 1:nx_plot, 1:ny_plot, total_for_display');
    set(ax, 'ColorScale', 'log');
    set(ax, 'XLim', [0.5, nx_plot + 0.5], 'YLim', [0.5, ny_plot + 0.5], 'YDir', 'normal');
    shading(ax, 'flat');
    colormap(ax, 'jet');
    
    h_cb = colorbar(ax);
    ylabel(h_cb, 'Total N Ionization Source ($\mathrm{m^{-3}s^{-1}}$)', 'Interpreter', 'latex', 'FontSize', 16);
    title(ax, fig_title, 'Interpreter', 'none', 'FontSize', 18);
    
    % 区域辅助线与标签
    C = getGridRegionConstants();
    drawRegionGuides(ax, nx_plot, ny_plot, C);
    
    xlabel(ax, '$\mathrm{i_x}$ (Poloidal Cell Index)', 'FontSize', 18);
    ylabel(ax, '$\mathrm{i_y}$ (Radial Cell Index)', 'FontSize', 18);
    xticks_unique = unique([1, C.inner_div_end, C.omp_idx, C.imp_idx, C.outer_div_start, nx_plot]);
    yticks_unique = unique([1, C.separatrix_line, ny_plot]);
    set(ax, 'XTick', xticks_unique, 'YTick', yticks_unique, 'FontSize', 12);
    box(ax, 'on');
    grid(ax, 'off');
    
    % ------------------------- 数据游标 -------------------------
    charge_labels = cell(1, max_charge_state);
    for ic = 1:max_charge_state
        charge_labels{ic} = sprintf('N%d+', ic);
    end
    dcm = datacursormode(fig);
    set(dcm, 'Enable', 'on');
    set(dcm, 'UpdateFcn', {@localDataCursorUpdate, total_source_plot, charge_source_plot, charge_density_plot, vol_plot, charge_labels, C});
    
    hold(ax, 'off');
    
    % ------------------------- 保存图形 -------------------------
    safe_dir = createSafeFilename(dirName);
    time_tag = datestr(now, 'yyyymmdd_HHMMSS');
    fig_name = sprintf('TotalN_IonSource_sna_%s_%s.fig', safe_dir, time_tag);
    try
        set(fig, 'PaperPositionMode', 'auto');
        savefig(fig, fig_name);
        fprintf('Figure saved: %s\n', fig_name);
    catch ME
        warning('Failed to save figure for case %s: %s', dirName, ME.message);
    end
end
end

%% ======================== 辅助函数 ========================
function [nx, ny] = getGridSize(gmtry)
% 获取网格尺寸，优先使用 crx
nx = [];
ny = [];
if isfield(gmtry, 'crx')
    sz = size(gmtry.crx);
    nx = sz(1);
    ny = sz(2);
elseif isfield(gmtry, 'cry')
    sz = size(gmtry.cry);
    nx = sz(1);
    ny = sz(2);
end
if isempty(nx) || nx < 3 || ny < 3
    nx = [];
    ny = [];
end
end

function C = getGridRegionConstants()
% 与其他网格绘图脚本保持一致的常量
C.inner_div_end   = 24;  % ODE 结束索引
C.outer_div_start = 73;  % IDE 起始索引
C.separatrix_line = 12;  % 分离面在 12/13 之间，绘制 12.5
C.omp_idx         = 41;
C.imp_idx         = 58;
end

function drawRegionGuides(ax, nx_plot, ny_plot, C)
% 绘制区域分界线与文字标签
plot(ax, [C.inner_div_end + 0.5, C.inner_div_end + 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [C.outer_div_start - 0.5, C.outer_div_start - 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [C.omp_idx + 0.5, C.omp_idx + 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [C.imp_idx + 0.5, C.imp_idx + 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [0.5, nx_plot + 0.5], [C.separatrix_line + 0.5, C.separatrix_line + 0.5], 'k-', 'LineWidth', 1.5);

label_font_size = 16;
top_y = ny_plot + 1.1;
text(ax, 1, top_y, 'OT', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, C.inner_div_end, top_y, 'ODE', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, C.omp_idx, top_y, 'OMP', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, C.imp_idx, top_y, 'IMP', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, C.outer_div_start, top_y, 'IDE', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, nx_plot, top_y, 'IT', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

center_x = round(nx_plot / 2);
core_y = max(1, round(C.separatrix_line * 0.6));
sol_y = C.separatrix_line + round((ny_plot - C.separatrix_line) * 0.65);
text(ax, center_x, core_y, 'Core/PFR', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, center_x, sol_y, 'SOL', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, center_x, C.separatrix_line + 2, 'Separatrix', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

function safeName = createSafeFilename(originalName)
% 将目录名转换为安全的文件名
safeName = regexprep(originalName, '[^a-zA-Z0-9_\\-\\.]', '_');
if length(safeName) > 120
    safeName = safeName(1:120);
end
end

function region_str = getRegionText(ix, iy, C)
% 根据网格索引给出区域说明（用于数据游标）
if iy <= C.separatrix_line
    radial_part = 'Core/PFR';
else
    radial_part = 'SOL/Divertor';
end

if ix <= C.inner_div_end
    poloidal_part = 'OT-ODE';
elseif ix < C.outer_div_start
    poloidal_part = 'Main SOL';
else
    poloidal_part = 'IDE-IT';
end
region_str = sprintf('%s, %s', radial_part, poloidal_part);
end

function output_txt = localDataCursorUpdate(~, event_obj, total_data, charge_source_data, charge_density_data, vol_data, charge_labels, C)
% 数据游标：展示完整物理量信息
pos = get(event_obj, 'Position');
x_click = pos(1);
y_click = pos(2);

nx_p = size(total_data, 1);
ny_p = size(total_data, 2);
[~, ix] = min(abs((1:nx_p) - x_click));
[~, iy] = min(abs((1:ny_p) - y_click));

total_val = total_data(ix, iy);
cell_vol = vol_data(ix, iy);
if isfinite(cell_vol) && cell_vol > 0 && isfinite(total_val)
    total_cell = total_val * cell_vol;
else
    total_cell = NaN;
end
log_val = log10(max(total_val, eps));

output_txt = {};
output_txt{end+1} = sprintf('Cell (ix, iy): (%d, %d)', ix, iy);
output_txt{end+1} = sprintf('Region: %s', getRegionText(ix, iy, C));
output_txt{end+1} = sprintf('Volume: %.3e m^{3}', cell_vol);
output_txt{end+1} = sprintf('Total source: %.3e m^{-3}s^{-1}', total_val);
output_txt{end+1} = sprintf('Cell-integrated: %.3e s^{-1}', total_cell);
output_txt{end+1} = sprintf('log_{10}(total): %.2f', log_val);

n_charge = size(charge_source_data, 3);
for ic = 1:n_charge
    src_ic = charge_source_data(ix, iy, ic);
    dens_ic = charge_density_data(ix, iy, ic);
    output_txt{end+1} = sprintf('%s: S=%.3e m^{-3}s^{-1}, n=%.3e m^{-3}', ...
        charge_labels{ic}, src_ic, dens_ic);
end
end
