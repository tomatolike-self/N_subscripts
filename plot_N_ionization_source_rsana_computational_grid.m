function plot_N_ionization_source_rsana_computational_grid(all_radiationData, charge_state_groups)
% =========================================================================
% plot_N_ionization_source_rsana_computational_grid
% =========================================================================
%
% 功能描述：
%   使用 rsana 数据计算 N1+~N7+ 的电离源密度，并在计算网格上以
%   imagesc 单元格方式绘制。支持自由选择价态（单独或组合），去除保护
%   单元后显示。数据游标会展示单元索引、所在区域、体积、源项密度、
%   体积积分值，以及每个价态的贡献。
%
% 输入：
%   all_radiationData - SOLPS 后处理数据元胞数组，需包含 gmtry.vol、
%                       plasma.rsana、plasma.na、neut.dab2。
%   charge_state_groups - 可选，元胞数组，每个元素为需要绘制的价态向量。
%                         若为空，则默认 {1:7}（总和）。
%
% 输出：
%   生成图像窗口并保存 .fig（带时间戳）。
%
% 注意事项：
%   - 兼容 MATLAB R2019a，不使用 tiledlayout/nexttile。
%   - N1+ 电离源采用 rsana 修正：rsana * neut.dab2(:,:,2) / na(:,:,3)。
%   - rsana 单位 s^-1，除以体积得到 m^-3 s^-1。
%
% =========================================================================

%% 输入检查与默认值
if nargin < 2 || isempty(charge_state_groups)
    charge_state_groups = {1:7}; % 默认绘制N1+~N7+总和
end

%% 全局绘图属性
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

%% 遍历算例
for i_case = 1:length(all_radiationData)
    radData = all_radiationData{i_case};
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    neut = radData.neut;
    dirName = radData.dirName;
    fprintf('\n=== Processing case (rsana source): %s ===\n', dirName);
    
    % ------------------ 数据有效性检查 ------------------
    [nx_orig, ny_orig] = getGridSize(gmtry);
    if isempty(nx_orig)
        warning('Case %s: Invalid grid size, skip.', dirName);
        continue;
    end
    if ~isfield(plasma, 'rsana') || size(plasma.rsana, 3) < 3
        warning('Case %s: rsana data missing, skip.', dirName);
        continue;
    end
    if ~isfield(plasma, 'na') || size(plasma.na, 3) < 3
        warning('Case %s: na data missing, skip.', dirName);
        continue;
    end
    if ~isfield(gmtry, 'vol')
        warning('Case %s: gmtry.vol missing, skip.', dirName);
        continue;
    end
    
    max_rsana_state = size(plasma.rsana, 3) - 2; % rsana(:,:,3) 对应 N1+
    max_rsana_state = min(max_rsana_state, 7); % 最高到N7+
    if max_rsana_state < 1
        warning('Case %s: No N ion states found in rsana, skip.', dirName);
        continue;
    end
    
    % 去除保护单元
    nx_plot = nx_orig - 2;
    ny_plot = ny_orig - 2;
    vol_plot = gmtry.vol(2:nx_orig-1, 2:ny_orig-1);
    
    % ------------------ 绘制每个价态组合 ------------------
    for ig = 1:length(charge_state_groups)
        states = charge_state_groups{ig};
        states = unique(round(states(:)'));
        states = states(states >= 1 & states <= max_rsana_state);
        if isempty(states)
            warning('Case %s: No valid charge states after filtering, skip this group.', dirName);
            continue;
        end
        
        % 计算当前组合的电离源密度
        source_full = zeros(nx_orig, ny_orig);
        state_source_full = zeros(nx_orig, ny_orig, length(states));
        for k = 1:length(states)
            cs = states(k);
            src_cs = computeIonSourceRsana(plasma, neut, gmtry, cs); % m^-3 s^-1
            state_source_full(:, :, k) = src_cs;
            source_full = source_full + src_cs;
        end
        
        source_plot = source_full(2:nx_orig-1, 2:ny_orig-1);
        state_source_plot = state_source_full(2:nx_orig-1, 2:ny_orig-1, :);
        
        % 处理对数色标的最小值
        pos_vals = source_plot(source_plot > 0);
        if isempty(pos_vals)
            min_pos = 1e-5;
        else
            min_pos = min(pos_vals);
        end
        source_disp = source_plot;
        source_disp(source_disp <= 0) = 0.1 * min_pos;
        
        % ------------------ 绘图 ------------------
        fig_title = buildTitle(states, dirName);
        fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
            'Units', 'inches', 'Position', [1, 1, 11, 8]);
        ax = axes(fig);
        hold(ax, 'on');
        
        imagesc(ax, 1:nx_plot, 1:ny_plot, source_disp');
        set(ax, 'ColorScale', 'log');
        set(ax, 'XLim', [0.5, nx_plot + 0.5], 'YLim', [0.5, ny_plot + 0.5], 'YDir', 'normal');
        shading(ax, 'flat');
        colormap(ax, 'jet');
        
        h_cb = colorbar(ax);
        ylabel(h_cb, 'N Ionization Source (rsana) ($\mathrm{m^{-3}s^{-1}}$)', 'Interpreter', 'latex', 'FontSize', 16);
        title(ax, fig_title, 'Interpreter', 'none', 'FontSize', 18);
        
        % 辅助线与标签
        C = getGridRegionConstants();
        drawRegionGuides(ax, nx_plot, ny_plot, C);
        
        xlabel(ax, '$\mathrm{i_x}$ (Poloidal Cell Index)', 'FontSize', 18);
        ylabel(ax, '$\mathrm{i_y}$ (Radial Cell Index)', 'FontSize', 18);
        xticks_unique = unique([1, C.inner_div_end, C.omp_idx, C.imp_idx, C.outer_div_start, nx_plot]);
        yticks_unique = unique([1, C.separatrix_line, ny_plot]);
        set(ax, 'XTick', xticks_unique, 'YTick', yticks_unique, 'FontSize', 12);
        box(ax, 'on');
        grid(ax, 'off');
        
        % 数据游标
        state_labels = cell(1, length(states));
        for k = 1:length(states)
            state_labels{k} = sprintf('N%d+', states(k));
        end
        dcm = datacursormode(fig);
        set(dcm, 'Enable', 'on');
        set(dcm, 'UpdateFcn', {@dataCursorFn, source_plot, state_source_plot, vol_plot, state_labels, C});
        
        hold(ax, 'off');
        
        % 保存图形
        safe_dir = createSafeFilename(dirName);
        time_tag = datestr(now, 'yyyymmdd_HHMMSS');
        save_name = sprintf('N_IonSource_rsana_compGrid_%s_%s.fig', safe_dir, time_tag);
        try
            set(fig, 'PaperPositionMode', 'auto');
            savefig(fig, save_name);
            fprintf('Figure saved: %s\n', save_name);
        catch ME
            warning('Failed to save figure for case %s: %s', dirName, ME.message);
        end
    end
end
end

%% ======================== 辅助函数 ========================
function [nx, ny] = getGridSize(gmtry)
% 获取网格尺寸，若无效返回空
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

function ionSource = computeIonSourceRsana(plasma, neut, gmtry, chargeState)
% 基于 rsana 计算指定价态的电离源密度 (m^-3 s^-1)
[nx, ny, ~] = size(gmtry.crx);
ionSource = zeros(nx, ny);

rsana_idx = 3 + chargeState - 1;
if ~isfield(plasma, 'rsana') || size(plasma.rsana, 3) < rsana_idx
    return;
end

rsana_full = plasma.rsana(:, :, rsana_idx);

% N1+ 特殊修正
if chargeState == 1 && isfield(neut, 'dab2') && size(neut.dab2, 3) >= 2 ...
        && isfield(plasma, 'na') && size(plasma.na, 3) >= 3
    rsana_corr = zeros(size(rsana_full));
    for iPos = 1:nx
        for jPos = 1:ny
            i_trim = iPos - 1;
            j_trim = jPos - 1;
            if i_trim >= 1 && i_trim <= size(neut.dab2, 1) && ...
                    j_trim >= 1 && j_trim <= size(neut.dab2, 2)
                if plasma.na(iPos, jPos, 3) > 0
                    rsana_corr(iPos, jPos) = rsana_full(iPos, jPos) * ...
                        neut.dab2(i_trim, j_trim, 2) / plasma.na(iPos, jPos, 3);
                else
                    rsana_corr(iPos, jPos) = 0;
                end
            else
                rsana_corr(iPos, jPos) = rsana_full(iPos, jPos);
            end
        end
    end
    rsana_full = rsana_corr;
end

vol = gmtry.vol;
vol(~isfinite(vol) | vol <= 0) = NaN;
ionSource = rsana_full ./ vol;
end

function C = getGridRegionConstants()
% 统一的网格区域常量
C.inner_div_end   = 24;
C.outer_div_start = 73;
C.separatrix_line = 12;
C.omp_idx         = 41;
C.imp_idx         = 58;
end

function drawRegionGuides(ax, nx_plot, ny_plot, C)
% 绘制区域分界线与标签
plot(ax, [C.inner_div_end + 0.5, C.inner_div_end + 0.5], [0.5, C.separatrix_line+0.5], 'k-', 'LineWidth', 1.0);
plot(ax, [C.inner_div_end + 0.5, C.inner_div_end + 0.5], [C.separatrix_line+0.5, ny_plot+0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [C.outer_div_start - 0.5, C.outer_div_start - 0.5], [0.5, C.separatrix_line+0.5], 'k-', 'LineWidth', 1.0);
plot(ax, [C.outer_div_start - 0.5, C.outer_div_start - 0.5], [C.separatrix_line+0.5, ny_plot+0.5], 'k--', 'LineWidth', 1.0);
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
% 将目录名转换为文件安全名
safeName = regexprep(originalName, '[^a-zA-Z0-9_\\-\\.]', '_');
if length(safeName) > 120
    safeName = safeName(1:120);
end
end

function txt = dataCursorFn(~, event_obj, total_data, state_data, vol_data, state_labels, C)
% 数据游标：显示单元索引、区域、体积、总源项及各价态贡献
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

txt = {};
txt{end+1} = sprintf('Cell (ix, iy): (%d, %d)', ix, iy);
txt{end+1} = sprintf('Region: %s', getRegionText(ix, iy, C));
txt{end+1} = sprintf('Volume: %.3e m^{3}', cell_vol);
txt{end+1} = sprintf('Total source: %.3e m^{-3}s^{-1}', total_val);
txt{end+1} = sprintf('Cell-integrated: %.3e s^{-1}', total_cell);
txt{end+1} = sprintf('log_{10}(total): %.2f', log_val);

n_state = size(state_data, 3);
for k = 1:n_state
    val_k = state_data(ix, iy, k);
    if isfinite(cell_vol) && cell_vol > 0 && isfinite(val_k)
        cell_k = val_k * cell_vol;
    else
        cell_k = NaN;
    end
    txt{end+1} = sprintf('%s: S=%.3e m^{-3}s^{-1}, Cell=%.3e s^{-1}', state_labels{k}, val_k, cell_k);
end
end

function region_str = getRegionText(ix, iy, C)
% 根据索引给出区域标签
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

function fig_title = buildTitle(states, dirName)
% 构造标题
if length(states) == 1
    fig_title = sprintf('N%d+ Ionization Source (rsana) - %s', states(1), dirName);
else
    fig_title = sprintf('N%d-%d+ Ionization Source (rsana) - %s', min(states), max(states), dirName);
end
end
