function plot_N_ExB_drift_flux_with_stagnation_linear(all_radiationData)
% =========================================================================
% plot_N_ExB_drift_flux_with_stagnation_linear - N离子ExB漂移通量分布图（线性色标）
% =========================================================================
%
% 功能描述：
%   1. 背景：ExB 漂移通量大小（线性色标）
%      - 通量定义：density × ExB velocity × 对应面积
%   2. 箭头：ExB 漂移通量方向（归一化箭头）
%   3. 停滞点：极向速度停滞点（洋红色圆圈）和平行速度停滞点（黑色方块）
%   4. 支持：总通量（N1+ ~ N7+ 总和）或特定价态
%
% 输入：
%   all_radiationData - 结构体cell数组，包含所有SOLPS仿真数据
%                       必须包含字段：
%                       - gmtry: 几何信息结构体（含 crx, gs, qz）
%                       - plasma: 等离子体数据结构体（含 na, vaecrb, ua, fna_mdf）
%                       - dirName: 可选，算例目录名称
%
% 输出：
%   - 每个算例生成一个图形窗口
%   - 自动保存为 .fig 文件
%
% 使用示例：
%   plot_N_ExB_drift_flux_with_stagnation_linear(all_radiationData)
%
% 依赖函数/工具箱：
%   无（mycontour.mat 为可选的自定义colormap文件）
%
% 注意事项：
%   - R2019a 兼容
%   - N体系物种索引：4-10 对应 N1+ 到 N7+（共7个价态）
%   - 与Ne体系区别：Ne为4-13共10个价态，N为4-10共7个价态
%   - 本文件包含2个辅助函数：dataCursorCallback, plotStagnationPoints
%     拆分理由：callback必须独立；停滞点逻辑复杂需封装
% =========================================================================

%% ========== 输入检查 ==========
if nargin < 1 || isempty(all_radiationData)
    error('plot_N_ExB_drift_flux_with_stagnation_linear:MissingData', ...
        'all_radiationData is required.');
end
if ~iscell(all_radiationData)
    error('plot_N_ExB_drift_flux_with_stagnation_linear:InvalidInput', ...
        'all_radiationData must be a cell array of case structures.');
end

%% ========== 全局绘图设置（仅设置解释器和字体类型）==========
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultLegendFontName', 'Times New Roman');
set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

%% ========== N体系常量定义 ==========
% N杂质价态范围：N1+ ~ N7+，对应物种索引 4~10
N_SPECIES_START = 4;   % N1+ 的物种索引
N_SPECIES_END = 10;    % N7+ 的物种索引
N_MAX_CHARGE = 7;      % N 最高价态

%% ========== 网格区域常量定义 ==========
INNER_DIV_END = 24;       % ODE（外偏滤器）末端的极向索引
OUTER_DIV_START = 73;     % IDE（内偏滤器）起始的极向索引
SEPARATRIX_LINE = 12;     % 分离面的径向索引
OMP_IDX = 41;             % OMP（外中平面）的极向索引
IMP_IDX = 58;             % IMP（内中平面）的极向索引

%% ========== 收集用户配置 ==========
fprintf('\n=== N Ion ExB Drift Flux Plotting Options ===\n');
fprintf('0: Total flux (sum of N1+ to N7+)\n');
fprintf('1-7: Specific charge state (N1+ to N7+)\n');

charge_state_choice = input('Select charge state to plot (0 for total, 1-7 for specific): ');

% 验证用户输入
if isempty(charge_state_choice) || charge_state_choice < 0 || ...
        charge_state_choice > N_MAX_CHARGE || mod(charge_state_choice, 1) ~= 0
    fprintf('Invalid input. Using default: total flux (0)\n');
    charge_state_choice = 0;
end

% 设置绘图模式参数
if charge_state_choice == 0
    fprintf('Selected: Total N ExB drift flux (N1+ to N7+)\n');
    plot_mode = 'total';
    plot_title_prefix = 'Total N';
else
    fprintf('Selected: N%d+ ExB drift flux\n', charge_state_choice);
    plot_mode = 'specific';
    plot_title_prefix = sprintf('N%d+', charge_state_choice);
end

% --- 询问是否使用自定义colormap ---
cmap_choice = input('Use custom colormap from mycontour.mat? (1=yes, 0=no) [default=1]: ');
if isempty(cmap_choice)
    use_custom_colormap = true;
else
    use_custom_colormap = logical(cmap_choice);
end

% --- 询问colorbar范围设置 ---
fprintf('\nColorbar settings:\n');
fprintf('  - Auto mode adjusts the range for every figure individually.\n');
fprintf('  - Manual mode enforces a uniform range across all figures.\n');
use_manual = input('Fix colorbar range manually? (1=yes, 0=no) [default=0]: ');

if isempty(use_manual) || use_manual == 0
    colorbar_manual = false;
    colorbar_range = [];
    fprintf('Auto colorbar enabled.\n');
else
    default_range = [1e17, 2e20];
    range_str = input('Enter colorbar range as "[min max]" in s^-1 (press Enter for [1e17 2e20]): ', 's');
    
    if isempty(range_str)
        range_input = default_range;
    else
        range_input = str2num(range_str); %#ok<ST2NM>
        if isempty(range_input) || numel(range_input) ~= 2 || any(~isfinite(range_input))
            warning('Invalid input. Using default range [1e17, 2e20].');
            range_input = default_range;
        end
    end
    
    range_input = sort(range_input);
    if range_input(1) < 0 || range_input(2) <= range_input(1)
        warning('Colorbar range invalid. Reverting to auto.');
        colorbar_manual = false;
        colorbar_range = [];
    else
        colorbar_manual = true;
        colorbar_range = range_input;
        fprintf('Manual colorbar range: [%.2e, %.2e] s^{-1}\n', range_input(1), range_input(2));
    end
end

% --- 询问停滞点显示模式 ---
fprintf('\nStagnation point display mode:\n');
fprintf('  0: Original mode (first and last only, max 2 per radial line)\n');
fprintf('  1: Divertor priority (select by physical region)\n');
fprintf('  2: Show all (no filtering)\n');
stagnation_mode = input('Select stagnation mode [default=0]: ');
if isempty(stagnation_mode) || ~ismember(stagnation_mode, [0, 1, 2])
    stagnation_mode = 0;
end

%% ========== 字体大小常量（保存前显式设置，确保跨平台兼容）==========
TICK_FONT_SIZE = 28;
LABEL_FONT_SIZE = 32;
COLORBAR_FONT_SIZE = 26;

%% ========== 主循环：处理每个算例 ==========
for idx = 1:numel(all_radiationData)
    radData = all_radiationData{idx};
    
    %% --- 检查数据有效性 ---
    if ~isstruct(radData)
        warning('Case index %d is not a struct. Skipping.', idx);
        continue;
    end
    if ~isfield(radData, 'gmtry') || ~isfield(radData, 'plasma')
        warning('Case %d: Missing gmtry or plasma field. Skipping.', idx);
        continue;
    end
    
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    
    % 获取目录名
    if isfield(radData, 'dirName') && ~isempty(radData.dirName)
        dirName = radData.dirName;
    else
        dirName = sprintf('Case_%d', idx);
    end
    
    [~, shortName, ~] = fileparts(dirName);
    if isempty(shortName)
        shortName = dirName;
    end
    
    fprintf('\n=== Processing case: %s ===\n', dirName);
    
    %% --- 获取网格尺寸 ---
    if ~isfield(gmtry, 'crx')
        warning('Case %s: gmtry.crx not found. Skipping.', dirName);
        continue;
    end
    
    s = size(gmtry.crx);
    nx_orig = s(1);
    ny_orig = s(2);
    
    if nx_orig < 3 || ny_orig < 3
        warning('Case %s: Grid dimensions (%d x %d) too small. Skipping.', dirName, nx_orig, ny_orig);
        continue;
    end
    
    nx_plot = nx_orig - 2;
    ny_plot = ny_orig - 2;
    fprintf('Grid size (no guard): %d x %d\n', nx_plot, ny_plot);
    
    %% ========== 获取面积数据 ==========
    area_pol_full = ones(nx_orig, ny_orig);
    area_rad_full = ones(nx_orig, ny_orig);
    
    if isfield(gmtry, 'gs') && ndims(gmtry.gs) >= 3
        gs_size = size(gmtry.gs);
        if gs_size(1) == nx_orig && gs_size(2) == ny_orig
            if gs_size(3) >= 1
                area_pol_full = gmtry.gs(:, :, 1);
            end
            if gs_size(3) >= 2
                area_rad_full = gmtry.gs(:, :, 2);
            end
        end
    end
    
    if isfield(gmtry, 'qz') && ndims(gmtry.qz) >= 3 && size(gmtry.qz, 3) >= 2
        qz_component = gmtry.qz(:, :, 2);
        if size(qz_component, 1) == nx_orig && size(qz_component, 2) == ny_orig
            area_pol_full = area_pol_full .* qz_component;
        end
    end
    
    %% ========== 计算 ExB 通量 ==========
    flux_pol_full = zeros(nx_orig, ny_orig);
    flux_rad_full = zeros(nx_orig, ny_orig);
    
    if ~isfield(plasma, 'vaecrb')
        warning('Case %s: plasma.vaecrb not found. Skipping.', dirName);
        continue;
    end
    if ~isfield(plasma, 'na')
        warning('Case %s: plasma.na not found. Skipping.', dirName);
        continue;
    end
    
    if strcmp(plot_mode, 'total')
        % --- 总通量模式：累加所有 N 价态（N1+ 到 N7+）---
        max_species = min([N_SPECIES_END, size(plasma.vaecrb, 4), size(plasma.na, 3)]);
        if max_species < N_SPECIES_START
            warning('Case %s: Not enough N charge state data. Skipping.', dirName);
            continue;
        end
        
        for isp = N_SPECIES_START:max_species
            vexb_pol = plasma.vaecrb(:, :, 1, isp);
            vexb_rad = plasma.vaecrb(:, :, 2, isp);
            density = plasma.na(:, :, isp);
            
            if isempty(vexb_pol) || isempty(density)
                continue;
            end
            
            flux_pol_full = flux_pol_full + density .* vexb_pol .* area_pol_full;
            flux_rad_full = flux_rad_full + density .* vexb_rad .* area_rad_full;
        end
        fprintf('Calculated total ExB flux (N1+ to N%d+)\n', max_species - 3);
    else
        % --- 特定价态模式 ---
        species_idx = charge_state_choice + 3;  % N1+ -> index 4
        
        if size(plasma.na, 3) < species_idx || size(plasma.vaecrb, 4) < species_idx
            warning('Case %s: N%d+ data not available. Skipping.', dirName, charge_state_choice);
            continue;
        end
        
        density = plasma.na(:, :, species_idx);
        vexb_pol = plasma.vaecrb(:, :, 1, species_idx);
        vexb_rad = plasma.vaecrb(:, :, 2, species_idx);
        
        flux_pol_full = density .* vexb_pol .* area_pol_full;
        flux_rad_full = density .* vexb_rad .* area_rad_full;
        fprintf('Calculated ExB flux for N%d+\n', charge_state_choice);
    end
    
    % 去除保护单元
    flux_pol_plot = flux_pol_full(2:nx_orig-1, 2:ny_orig-1);
    flux_rad_plot = flux_rad_full(2:nx_orig-1, 2:ny_orig-1);
    flux_magnitude_plot = hypot(flux_pol_plot, flux_rad_plot);
    
    %% ========== 创建图形 ==========
    fig_title = sprintf('%s ExB Drift Flux - %s', plot_title_prefix, shortName);
    fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
        'Units', 'inches', 'Position', [1, 1, 18, 7]);
    ax = axes(fig);
    hold(ax, 'on');
    
    %% ========== 绘制背景（通量大小色图）==========
    h_img = imagesc(ax, 1:nx_plot, 1:ny_plot, flux_magnitude_plot');
    set(h_img, 'HandleVisibility', 'off');
    set(ax, 'YDir', 'normal');
    shading(ax, 'flat');
    
    % --- 设置 colorbar 范围 ---
    if colorbar_manual && numel(colorbar_range) == 2
        set(ax, 'CLim', colorbar_range);
    else
        finite_vals = flux_magnitude_plot(isfinite(flux_magnitude_plot));
        if isempty(finite_vals)
            cmin = 0; cmax = 1;
        else
            cmin = min(finite_vals);
            cmax = max(finite_vals);
            if cmax <= cmin
                cmax = cmin + 1;
            end
        end
        set(ax, 'CLim', [cmin, cmax]);
        fprintf('Auto colorbar range: [%.2e, %.2e] s^{-1}\n', cmin, cmax);
    end
    
    % --- 设置 colormap ---
    if use_custom_colormap
        try
            load('mycontour.mat', 'mycontour');
            colormap(ax, mycontour);
        catch
            colormap(ax, 'jet');
        end
    else
        colormap(ax, 'jet');
    end
    
    % --- 添加 colorbar ---
    h_cb = colorbar(ax);
    % 使用 N 杂质的 colorbar 标签
    ylabel(h_cb, '$\Gamma_{\mathrm{N}, E \times B}$ (s$^{-1}$)', ...
        'FontSize', COLORBAR_FONT_SIZE, 'Interpreter', 'latex', 'FontWeight', 'bold');
    h_cb.FontName = 'Times New Roman';
    h_cb.FontSize = COLORBAR_FONT_SIZE;
    h_cb.LineWidth = 1.5;
    
    %% ========== 绘制归一化箭头 ==========
    u_norm = zeros(size(flux_pol_plot));
    v_norm = zeros(size(flux_rad_plot));
    nonzero = flux_magnitude_plot > 1e-15;
    u_norm(nonzero) = flux_pol_plot(nonzero) ./ flux_magnitude_plot(nonzero);
    v_norm(nonzero) = flux_rad_plot(nonzero) ./ flux_magnitude_plot(nonzero);
    
    [X, Y] = meshgrid(1:nx_plot, 1:ny_plot);
    quiver(ax, X, Y, u_norm', v_norm', 0.4, ...
        'Color', 'k', 'LineWidth', 0.8, 'AutoScale', 'off', 'HandleVisibility', 'off');
    
    %% ========== 计算并绘制停滞点 ==========
    plotStagnationPoints(ax, plasma, nx_plot, ny_plot, plot_mode, ...
        charge_state_choice, stagnation_mode, SEPARATRIX_LINE, ...
        N_SPECIES_START, N_SPECIES_END);
    
    %% ========== 绘制分隔线 ==========
    h1 = plot(ax, [INNER_DIV_END+0.5, INNER_DIV_END+0.5], [0.5, SEPARATRIX_LINE+0.5], 'k-', 'LineWidth', 1.0, 'HandleVisibility', 'off');
    h1 = plot(ax, [INNER_DIV_END+0.5, INNER_DIV_END+0.5], [SEPARATRIX_LINE+0.5, ny_plot+0.5], 'k--', 'LineWidth', 1.0);
    h2 = plot(ax, [OUTER_DIV_START-0.5, OUTER_DIV_START-0.5], [0.5, SEPARATRIX_LINE+0.5], 'k-', 'LineWidth', 1.0, 'HandleVisibility', 'off');
    h2 = plot(ax, [OUTER_DIV_START-0.5, OUTER_DIV_START-0.5], [SEPARATRIX_LINE+0.5, ny_plot+0.5], 'k--', 'LineWidth', 1.0);
    h3 = plot(ax, [OMP_IDX+0.5, OMP_IDX+0.5], [0.5, ny_plot+0.5], 'k--', 'LineWidth', 1.0);
    h4 = plot(ax, [IMP_IDX+0.5, IMP_IDX+0.5], [0.5, ny_plot+0.5], 'k--', 'LineWidth', 1.0);
    h5 = plot(ax, [0.5, nx_plot+0.5], [SEPARATRIX_LINE+0.5, SEPARATRIX_LINE+0.5], 'k-', 'LineWidth', 1.5);
    set([h1, h2, h3, h4, h5], 'HandleVisibility', 'off');
    
    %% ========== 添加顶部区域标签 ==========
    top_y = ny_plot + 2.0;
    text(ax, 1, top_y, 'OT', 'FontSize', LABEL_FONT_SIZE, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, INNER_DIV_END, top_y, 'ODE', 'FontSize', LABEL_FONT_SIZE, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, OMP_IDX, top_y, 'OMP', 'FontSize', LABEL_FONT_SIZE, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, IMP_IDX, top_y, 'IMP', 'FontSize', LABEL_FONT_SIZE, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, OUTER_DIV_START, top_y, 'IDE', 'FontSize', LABEL_FONT_SIZE, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(ax, nx_plot, top_y, 'IT', 'FontSize', LABEL_FONT_SIZE, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    
    %% ========== 设置坐标轴 ==========
    xlabel(ax, '$i_x$', 'FontSize', LABEL_FONT_SIZE, 'Interpreter', 'latex');
    ylabel(ax, '$i_y$', 'FontSize', LABEL_FONT_SIZE, 'Interpreter', 'latex');
    axis(ax, [0.5, nx_plot+0.5, 0.5, ny_plot+0.5]);
    
    xticks_arr = unique([1, INNER_DIV_END, OMP_IDX, IMP_IDX, OUTER_DIV_START, nx_plot]);
    yticks_arr = unique([1, SEPARATRIX_LINE, ny_plot]);
    set(ax, 'XTick', xticks_arr, 'YTick', yticks_arr, 'FontSize', TICK_FONT_SIZE);
    set(ax, 'TickLength', [0, 0]);
    set(ax, 'XMinorTick', 'off', 'YMinorTick', 'off');
    set(ax, 'DataAspectRatio', [1, 1, 1]);
    set(ax, 'Position', [0.08, 0.15, 0.85, 0.78]);
    
    box(ax, 'on');
    grid(ax, 'off');
    
    %% ========== 设置数据游标 ==========
    dcm = datacursormode(fig);
    set(dcm, 'Enable', 'on');
    set(dcm, 'UpdateFcn', {@dataCursorCallback, nx_plot, ny_plot, ...
        flux_pol_plot, flux_rad_plot, flux_magnitude_plot});
    
    %% ========== 保存图形 ==========
    safe_name = regexprep(shortName, '[^a-zA-Z0-9_]', '_');
    if length(safe_name) > 80
        safe_name = safe_name(1:80);
    end
    
    if strcmp(plot_mode, 'total')
        fname = sprintf('ExB_Drift_TotalFlux_N_Stagnation_%s', safe_name);
    else
        fname = sprintf('ExB_Drift_Flux_N%d_Stagnation_%s', charge_state_choice, safe_name);
    end
    
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    try
        savefig(fig, [fname, '_', timestamp, '.fig']);
        fprintf('Saved figure: %s_%s.fig\n', fname, timestamp);
    catch ME
        fprintf('Warning: Failed to save figure: %s\n', ME.message);
    end
    
    hold(ax, 'off');
end

fprintf('\nN ion ExB drift flux plotting completed.\n');

end


%% =========================================================================
%  辅助函数1：数据游标回调
%  拆分理由：MATLAB callback 机制要求 callback 必须是独立函数
% =========================================================================
function output_txt = dataCursorCallback(~, event_obj, nx_p, ny_p, flux_pol_plot, flux_rad_plot, flux_magnitude_plot)
% 数据游标更新回调函数

pos = get(event_obj, 'Position');
ix = max(1, min(nx_p, round(pos(1))));
iy = max(1, min(ny_p, round(pos(2))));

pol_flux = flux_pol_plot(ix, iy);
rad_flux = flux_rad_plot(ix, iy);
mag_flux = flux_magnitude_plot(ix, iy);

output_txt = {
    sprintf('Cell (ix, iy): (%d, %d)', ix, iy), ...
    sprintf('Poloidal Flux: %.3e s^{-1}', pol_flux), ...
    sprintf('Radial Flux: %.3e s^{-1}', rad_flux), ...
    sprintf('Flux Magnitude: %.3e s^{-1}', mag_flux)
    };
end


%% =========================================================================
%  辅助函数2：停滞点计算和绘制
%  拆分理由：逻辑复杂（速度场计算、过零点检测、筛选模式、标记绘制）
% =========================================================================
function plotStagnationPoints(ax, plasma, nx_plot, ny_plot, plot_mode, ...
    charge_state_choice, stagnation_mode, SEPARATRIX_LINE, ...
    N_SPECIES_START, N_SPECIES_END)
% 计算并绘制停滞点

try
    %% --- 计算速度场 ---
    u_pol = zeros(nx_plot, ny_plot);
    u_par = zeros(nx_plot, ny_plot);
    
    for i = 1:nx_plot
        for j = 1:ny_plot
            i_orig = i + 1;
            j_orig = j + 1;
            
            if strcmp(plot_mode, 'total')
                % 总通量模式：累加所有N价态
                max_sp = min(N_SPECIES_END, size(plasma.fna_mdf, 4));
                flux_pol_sum = sum(plasma.fna_mdf(i_orig, j_orig, 1, N_SPECIES_START:max_sp));
                density_sum = sum(plasma.na(i_orig, j_orig, N_SPECIES_START:max_sp));
                if density_sum > 0
                    u_pol(i, j) = flux_pol_sum / density_sum;
                end
                
                % 平行速度：按 Z² 加权平均
                w_sum = 0;
                w_tot = 0;
                for sp = N_SPECIES_START:max_sp
                    Z = sp - 3;  % N1+ -> Z=1, N7+ -> Z=7
                    n = plasma.na(i_orig, j_orig, sp);
                    u = plasma.ua(i_orig, j_orig, sp);
                    w_sum = w_sum + Z^2 * n * u;
                    w_tot = w_tot + Z^2 * n;
                end
                if w_tot > 0
                    u_par(i, j) = w_sum / w_tot;
                end
            else
                % 特定价态模式
                species_idx = charge_state_choice + 3;
                flux_pol_val = plasma.fna_mdf(i_orig, j_orig, 1, species_idx);
                density_val = plasma.na(i_orig, j_orig, species_idx);
                if density_val > 0
                    u_pol(i, j) = flux_pol_val / density_val;
                end
                u_par(i, j) = plasma.ua(i_orig, j_orig, species_idx);
            end
        end
    end
    
    %% --- 检测停滞点 ---
    pol_stag_points = cell(ny_plot, 1);
    par_stag_points = cell(ny_plot, 1);
    
    for j = 1:ny_plot
        % 检测极向速度过零点
        pol_all = [];
        for i = 1:(nx_plot-1)
            if u_pol(i, j) * u_pol(i+1, j) < 0
                pol_all = [pol_all; i, j]; %#ok<AGROW>
            end
        end
        
        % 检测平行速度过零点
        par_all = [];
        for i = 1:(nx_plot-1)
            if u_par(i, j) * u_par(i+1, j) < 0
                par_all = [par_all; i, j]; %#ok<AGROW>
            end
        end
        
        %% --- 根据模式筛选停滞点 ---
        if stagnation_mode == 2
            % 模式2：显示全部
            pol_stag_points{j} = pol_all;
            par_stag_points{j} = par_all;
            
        elseif stagnation_mode == 1
            % 模式1：偏滤器优先（与Ne 187和N 187一致）
            % 平行停滞点：仅保留首尾两个
            if size(par_all, 1) > 2
                par_stag_points{j} = [par_all(1,:); par_all(end,:)];
            else
                par_stag_points{j} = par_all;
            end
            
            % 极向停滞点：使用偏滤器优先筛选
            pol_stag_points{j} = selectPoloidalStagnationMode1(...
                pol_all, par_stag_points{j}, u_pol(:, j), nx_plot);
            
        else
            % 模式0：原始逻辑（首尾各一个）
            if size(pol_all, 1) > 2
                pol_stag_points{j} = [pol_all(1,:); pol_all(end,:)];
            else
                pol_stag_points{j} = pol_all;
            end
            if size(par_all, 1) > 2
                par_stag_points{j} = [par_all(1,:); par_all(end,:)];
            else
                par_stag_points{j} = par_all;
            end
        end
    end
    
    %% --- 绘制停滞点标记 ---
    j_min = SEPARATRIX_LINE + 1;
    j_max = min(26, ny_plot);
    
    real_marker_size = 160;
    legend_marker_size = 24;
    
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
    
    % 绘制真实停滞点
    if ~isempty(pol_pts)
        scatter(ax, pol_pts(:,1), pol_pts(:,2), real_marker_size, 'm', 'o', 'filled', ...
            'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
    end
    if ~isempty(par_pts)
        scatter(ax, par_pts(:,1), par_pts(:,2), real_marker_size, 'k', 's', 'filled', ...
            'MarkerEdgeColor', 'w', 'HandleVisibility', 'off');
    end
    
    % 创建图例
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
    
catch ME
    warning(ME.identifier, '%s', ME.message);
end
end


%% =========================================================================
%  辅助函数3：模式1偏滤器优先筛选极向停滞点
% =========================================================================
function selected_pts = selectPoloidalStagnationMode1(pol_pts, par_pts, u_pol_vec, nx)
% 模式1：偏滤器优先 + 左右两侧分别筛选（与Ne 187和N 187一致）

if isempty(pol_pts)
    selected_pts = [];
    return;
end

% 区域边界常量
OUTER_SIDE_END = 48;
INNER_SIDE_START = 49;
OUTER_DIV_END_EXT = 25;
INNER_DIV_START_EXT = 72;

% 分类停滞点到四个区域
outer_div_pts = [];
outer_sol_pts = [];
inner_sol_pts = [];
inner_div_pts = [];

for k = 1:size(pol_pts, 1)
    ix = pol_pts(k, 1);
    if ix <= OUTER_DIV_END_EXT
        outer_div_pts = [outer_div_pts; pol_pts(k, :)]; %#ok<AGROW>
    elseif ix <= OUTER_SIDE_END
        outer_sol_pts = [outer_sol_pts; pol_pts(k, :)]; %#ok<AGROW>
    elseif ix < INNER_DIV_START_EXT
        inner_sol_pts = [inner_sol_pts; pol_pts(k, :)]; %#ok<AGROW>
    else
        inner_div_pts = [inner_div_pts; pol_pts(k, :)]; %#ok<AGROW>
    end
end

% 获取平行停滞点位置
if ~isempty(par_pts)
    par_ix = par_pts(:, 1);
else
    par_ix = 48;
end

% 外侧筛选（偏滤器优先）
outer_selected = selectWithDivPriority(outer_div_pts, outer_sol_pts, par_ix, u_pol_vec, 'outer', nx);
% 内侧筛选（偏滤器优先）
inner_selected = selectWithDivPriority(inner_div_pts, inner_sol_pts, par_ix, u_pol_vec, 'inner', nx);

selected_pts = [outer_selected; inner_selected];
end


function selected = selectWithDivPriority(div_pts, sol_pts, par_ix, u_pol_vec, side, nx)
% 偏滤器优先选择

selected = selectValidPoint(div_pts, par_ix, u_pol_vec, side, nx);
if isempty(selected)
    selected = selectValidPoint(sol_pts, par_ix, u_pol_vec, side, nx);
end
end


function selected = selectValidPoint(side_pts, par_ix, u_pol_vec, side, nx)
% 从候选点中选择满足上游速度条件的停滞点

if isempty(side_pts)
    selected = [];
    return;
end

OUTER_SIDE_END = 48;
INNER_SIDE_START = 49;

% 筛选满足上游速度条件的点
valid_pts = [];
for k = 1:size(side_pts, 1)
    ix = side_pts(k, 1);
    is_valid = false;
    
    if strcmp(side, 'outer')
        if ix < OUTER_SIDE_END
            check_idx = ix + 1;
            if check_idx >= 1 && check_idx <= nx && u_pol_vec(check_idx) > 0
                is_valid = true;
            end
        end
    elseif strcmp(side, 'inner')
        if ix > INNER_SIDE_START
            check_idx = ix - 1;
            if check_idx >= 1 && check_idx <= nx && u_pol_vec(check_idx) < 0
                is_valid = true;
            end
        end
    end
    
    if is_valid
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

% 选择最靠近平行停滞点的
min_dist = inf;
best_idx = 1;
for k = 1:size(valid_pts, 1)
    d = min(abs(valid_pts(k, 1) - par_ix));
    if d < min_dist
        min_dist = d;
        best_idx = k;
    end
end
selected = valid_pts(best_idx, :);
end
