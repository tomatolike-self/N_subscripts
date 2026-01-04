function plot_N_ion_flux_distribution_computational_grid(all_radiationData)
% =========================================================================
% plot_N_ion_flux_distribution_computational_grid - N离子通量分布绘图（计算网格）
% =========================================================================
%
% 功能描述：
%   - 在计算网格上绘制N离子（N1+ - N7+）通量分布
%   - 背景为通量大小（线性色标），箭头仅展示方向（归一化箭头）
%   - 支持三种模式：总和/子集求和/单独绘制各价态
%
% 输入：
%   - all_radiationData : cell数组，包含多个算例的 radData 结构体
%     每个 radData 需包含: gmtry, plasma (含 fna_mdf 字段), dirName
%
% 输出：
%   - 每个算例生成一张或多张 figure，并保存为 .fig 文件
%
% 使用示例：
%   plot_N_ion_flux_distribution_computational_grid(all_radiationData)
%
% 依赖函数/工具箱：
%   - 无必需工具箱
%   - 可选: mycontour.mat (自定义色表文件)
%
% 注意事项：
%   - R2019a 兼容（避免 arguments 块、tiledlayout 等新语法）
%   - fna_mdf 第4维索引: 4 = N1+, ..., 10 = N7+（即 charge_state + 3）
%   - 保护单元（guard cells）在绘图时会被去除（第1行/列、最后一行/列）
% =========================================================================

%% 输入检查
if nargin < 1 || isempty(all_radiationData)
    error('plot_N_ion_flux_distribution_computational_grid:MissingData', ...
        'all_radiationData is required.');
end
if ~iscell(all_radiationData)
    error('plot_N_ion_flux_distribution_computational_grid:InvalidInput', ...
        'all_radiationData must be a cell array of case structures.');
end

%% 设置绘图默认参数
% 统一字体、字号，避免每个 figure 分别设置
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 26);
set(0, 'DefaultTextFontSize', 26);
set(0, 'DefaultLineLineWidth', 1.4);
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');
set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

%% 区域边界常量（EAST 托卡马克网格）
% 这些值为 EAST 标准网格的区域边界索引
INNER_DIV_END   = 24;   % 外偏滤器结束
OUTER_DIV_START = 73;   % 内偏滤器开始
SEPARATRIX_LINE = 12;   % 分离面径向索引
OMP_IDX         = 41;   % 外中平面极向索引
IMP_IDX         = 58;   % 内中平面极向索引

%% 用户交互：收集配置参数
% 默认价态范围为 N1+ 到 N7+
default_states = 1:7;

fprintf('\n=== N Ion Flux Distribution Configuration ===\n');
fprintf('  1: Plot total N ion flux (N1+ to N7+)\n');
fprintf('  2: Plot summed flux for a custom charge-state subset (single figure)\n');
fprintf('  3: Plot specified charge states individually (one figure per state)\n');
mode_choice = input('Select option (1, 2, or 3) [default=1]: ');
if isempty(mode_choice) || ~ismember(mode_choice, [1, 2, 3])
    mode_choice = 1;
end

if mode_choice == 1
    % 模式1：绘制总通量（N1+ - N7+ 求和）
    plot_mode = 'total';
    charge_states = default_states;
    fprintf('Using total N ion flux (N1+ to N7+).\n');
else
    % 模式2或3：需要用户输入价态
    states_input = input('Enter charge states to include (e.g., 1:4 or [1 3 6]) [default=1:7]: ', 's');
    
    % 解析用户输入的价态
    if isempty(states_input)
        charge_states = default_states;
    else
        values = str2num(states_input); %#ok<ST2NM>
        if isempty(values)
            warning('Could not parse charge state input. Using default range 1:7.');
            charge_states = default_states;
        else
            values = unique(round(values));
            values = values(values >= 1 & values <= 7);
            if isempty(values)
                warning('No valid charge states provided. Using default range 1:7.');
                charge_states = default_states;
            else
                charge_states = values;
            end
        end
    end
    
    if mode_choice == 2
        plot_mode = 'subset_sum';
        fprintf('Summed flux for charge states: ');
    else
        plot_mode = 'individual';
        fprintf('Plotting each charge state separately: ');
    end
    
    % 打印选择的价态列表
    state_labels = cell(1, numel(charge_states));
    for k = 1:numel(charge_states)
        state_labels{k} = sprintf('N%d+', charge_states(k));
    end
    fprintf('%s\n', strjoin(state_labels, ', '));
end

% 询问是否使用自定义色表
choice = input('Use custom colormap from mycontour.mat? (1=yes, 0=no) [default=1]: ');
if isempty(choice)
    use_custom_colormap = true;
else
    use_custom_colormap = logical(choice);
end
if use_custom_colormap
    fprintf('Custom colormap enabled.\n');
else
    fprintf('Using MATLAB default colormap.\n');
end

% 询问 colorbar 范围设置
fprintf('\nColorbar settings:\n');
fprintf('  - Auto mode adjusts the range for every figure individually.\n');
fprintf('  - Manual mode enforces a uniform range across all figures.\n');
use_manual = input('Fix colorbar range manually? (1=yes, 0=no) [default=0]: ');

if isempty(use_manual) || use_manual == 0
    use_manual_colorbar = false;
    colorbar_range = [];
    fprintf('Auto colorbar is enabled (per figure).\n');
else
    default_manual_range = [0, 2e20];
    range_input_str = input('Enter colorbar range as "[min max]" in s^-1 (press Enter for [0 2e20]): ', 's');
    
    if isempty(range_input_str)
        colorbar_range = default_manual_range;
        fprintf('Using default manual colorbar range: [%.2e, %.2e] s^{-1}\n', ...
            colorbar_range(1), colorbar_range(2));
    else
        range_input = str2num(range_input_str); %#ok<ST2NM>
        if isempty(range_input) || numel(range_input) ~= 2 || any(~isfinite(range_input))
            warning('Invalid input detected. Reverting to default manual range [0, 2e20].');
            colorbar_range = default_manual_range;
        else
            colorbar_range = sort(range_input);
        end
    end
    
    % 验证范围合法性
    if colorbar_range(1) < 0 || colorbar_range(2) <= colorbar_range(1)
        warning('Colorbar range must satisfy 0 <= min < max. Reverting to auto range.');
        use_manual_colorbar = false;
        colorbar_range = [];
    else
        use_manual_colorbar = true;
        fprintf('Manual colorbar range enabled: [%.2e, %.2e] s^{-1}\n', ...
            colorbar_range(1), colorbar_range(2));
    end
end

%% 主循环：处理每个算例
for idx = 1:numel(all_radiationData)
    radData = all_radiationData{idx};
    
    %% 验证算例数据
    if ~isstruct(radData)
        warning('Case index %d is not a struct. Skipping.', idx);
        continue;
    end
    if ~isfield(radData, 'gmtry') || ~isfield(radData, 'plasma')
        warning('Case %d: Missing gmtry or plasma field. Skipping.', idx);
        continue;
    end
    
    % 获取算例名称
    if isfield(radData, 'dirName') && ~isempty(radData.dirName)
        dirName = radData.dirName;
    else
        dirName = sprintf('Case_%d', idx);
    end
    
    % 从路径中提取末级文件夹名作为简短标签
    parts = regexp(dirName, '[\\/]', 'split');
    if ~isempty(parts) && ~isempty(parts{end})
        case_label = parts{end};
    else
        case_label = dirName;
    end
    
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    
    % 获取网格尺寸
    if isfield(gmtry, 'crx')
        s = size(gmtry.crx);
        nx_orig = s(1);
        ny_orig = s(2);
    elseif isfield(gmtry, 'cry')
        s = size(gmtry.cry);
        nx_orig = s(1);
        ny_orig = s(2);
    else
        warning('Case %s: gmtry structure missing crx/cry fields. Skipping.', dirName);
        continue;
    end
    
    if nx_orig < 3 || ny_orig < 3
        warning('Case %s: Grid dimensions (%d x %d) too small. Skipping.', ...
            dirName, nx_orig, ny_orig);
        continue;
    end
    
    % 去除保护单元后的绘图网格尺寸
    nx_plot = nx_orig - 2;
    ny_plot = ny_orig - 2;
    
    % 检查 fna_mdf 数据
    if ~isfield(plasma, 'fna_mdf')
        warning('Case %s: plasma.fna_mdf not found. Skipping.', dirName);
        continue;
    end
    if ndims(plasma.fna_mdf) < 4
        warning('Case %s: plasma.fna_mdf does not have species dimension. Skipping.', dirName);
        continue;
    end
    
    %% 根据绘图模式处理
    if strcmp(plot_mode, 'individual')
        % 模式3：每个价态单独绘制一张图
        for i_state = 1:numel(charge_states)
            state = charge_states(i_state);
            
            % 计算单个价态的通量
            [flux_pol_plot, flux_rad_plot, used_states] = compute_flux_for_states(...
                plasma, nx_orig, ny_orig, state, dirName);
            
            if isempty(used_states)
                continue;
            end
            
            % 计算通量大小和归一化方向
            flux_magnitude_plot = hypot(flux_pol_plot, flux_rad_plot);
            [u_norm, v_norm] = normalize_flux_vectors(flux_pol_plot, flux_rad_plot, flux_magnitude_plot);
            
            % 绘图并保存
            render_and_save_figure(case_label, dirName, used_states, ...
                flux_magnitude_plot, flux_pol_plot, flux_rad_plot, u_norm, v_norm, ...
                nx_plot, ny_plot, use_custom_colormap, use_manual_colorbar, colorbar_range, ...
                INNER_DIV_END, OUTER_DIV_START, SEPARATRIX_LINE, OMP_IDX, IMP_IDX);
        end
    else
        % 模式1或2：所有价态求和后绘制一张图
        [flux_pol_plot, flux_rad_plot, used_states] = compute_flux_for_states(...
            plasma, nx_orig, ny_orig, charge_states, dirName);
        
        if isempty(used_states)
            continue;
        end
        
        % 计算通量大小和归一化方向
        flux_magnitude_plot = hypot(flux_pol_plot, flux_rad_plot);
        [u_norm, v_norm] = normalize_flux_vectors(flux_pol_plot, flux_rad_plot, flux_magnitude_plot);
        
        % 绘图并保存
        render_and_save_figure(case_label, dirName, used_states, ...
            flux_magnitude_plot, flux_pol_plot, flux_rad_plot, u_norm, v_norm, ...
            nx_plot, ny_plot, use_custom_colormap, use_manual_colorbar, colorbar_range, ...
            INNER_DIV_END, OUTER_DIV_START, SEPARATRIX_LINE, OMP_IDX, IMP_IDX);
    end
end

fprintf('\nN ion flux distribution plotting completed.\n');

end  % 主函数结束


%% =========================================================================
% 以下为必要的嵌套函数（无法避免，因为数据游标回调需要）
% 以及两个内联辅助函数用于减少重复代码
% =========================================================================

function [flux_pol_plot, flux_rad_plot, used_states] = compute_flux_for_states(plasma, nx_orig, ny_orig, charge_states, dirName)
% 计算指定价态的通量（去除保护单元后）
% 这是一个必要的辅助函数，用于避免主函数中大量重复代码

flux_pol_full = zeros(nx_orig, ny_orig);
flux_rad_full = zeros(nx_orig, ny_orig);
used_states = [];
n_species = size(plasma.fna_mdf, 4);

for state = charge_states
    species_idx = state + 3;  % N1+ -> species 4, ..., N7+ -> species 10
    if species_idx > n_species
        warning('Case %s: Requested N%d+ (species %d) is unavailable. Skipping.', ...
            dirName, state, species_idx);
        continue;
    end
    
    pol_component = plasma.fna_mdf(:, :, 1, species_idx);
    rad_component = plasma.fna_mdf(:, :, 2, species_idx);
    
    if isempty(pol_component) || isempty(rad_component)
        warning('Case %s: Missing flux data for N%d+. Skipping this state.', ...
            dirName, state);
        continue;
    end
    
    flux_pol_full = flux_pol_full + pol_component;
    flux_rad_full = flux_rad_full + rad_component;
    used_states(end+1) = state; %#ok<AGROW>
end

if isempty(used_states)
    warning('Case %s: None of the requested charge states contained valid data. Skipping.', dirName);
    flux_pol_plot = [];
    flux_rad_plot = [];
    return;
end

% 去除保护单元（第1行/列、最后一行/列）
flux_pol_plot = flux_pol_full(2:nx_orig-1, 2:ny_orig-1);
flux_rad_plot = flux_rad_full(2:nx_orig-1, 2:ny_orig-1);
end


function [u_norm, v_norm] = normalize_flux_vectors(flux_pol, flux_rad, flux_mag)
% 计算归一化箭头方向（避免除零）
u_norm = zeros(size(flux_pol));
v_norm = zeros(size(flux_rad));
nonzero = flux_mag > 1e-15;
u_norm(nonzero) = flux_pol(nonzero) ./ flux_mag(nonzero);
v_norm(nonzero) = flux_rad(nonzero) ./ flux_mag(nonzero);
end


function render_and_save_figure(case_label, dirName, used_states, ...
    flux_magnitude_plot, flux_pol_plot, flux_rad_plot, u_norm, v_norm, ...
    nx_plot, ny_plot, use_custom_colormap, use_manual_colorbar, colorbar_range, ...
    INNER_DIV_END, OUTER_DIV_START, SEPARATRIX_LINE, OMP_IDX, IMP_IDX)
% 绘制并保存单张通量分布图
% 这是一个必要的辅助函数，用于避免主函数中大量重复的绘图代码

%% 生成标题/文件名所需的价态标签
states = sort(unique(used_states));
if isequal(states, 1:7)
    state_label_plain = 'Total N Flux';
elseif numel(states) == 1
    state_label_plain = sprintf('N%d+', states);
elseif numel(states) > 1 && all(diff(states) == 1)
    state_label_plain = sprintf('N%d+ - N%d+', states(1), states(end));
else
    parts = cell(1, numel(states));
    for k = 1:numel(states)
        parts{k} = sprintf('N%d+', states(k));
    end
    state_label_plain = strjoin(parts, ', ');
end

%% 生成 colorbar 标签（LaTeX 格式）
if isequal(states, 1:7)
    colorbar_label = '$\Gamma_{\mathrm{N}}$ (s$^{-1}$)';
elseif numel(states) == 1
    colorbar_label = sprintf('$\\Gamma_{\\mathrm{N}^{%d+}}$ (s$^{-1}$)', states);
elseif numel(states) > 1 && all(diff(states) == 1)
    colorbar_label = sprintf('$\\Gamma_{\\mathrm{N}^{%d+}-\\mathrm{N}^{%d+}}$ (s$^{-1}$)', states(1), states(end));
else
    parts = cell(1, numel(states));
    for k = 1:numel(states)
        parts{k} = sprintf('\\mathrm{N}^{%d+}', states(k));
    end
    colorbar_label = sprintf('$\\Gamma_{%s}$ (s$^{-1}$)', strjoin(parts, ',\\,'));
end

%% 创建 figure
fig_title = sprintf('N Flux Distribution | %s | %s', case_label, state_label_plain);
fig = figure('Name', fig_title, 'NumberTitle', 'off', 'Color', 'w', ...
    'Units', 'inches', 'Position', [1, 1, 16, 10]);

ax = axes(fig);
hold(ax, 'on');

%% 绘制背景色块（通量大小）
imagesc(ax, 1:nx_plot, 1:ny_plot, flux_magnitude_plot');
set(ax, 'YDir', 'normal');
shading(ax, 'flat');

% 设置 colorbar 范围
if use_manual_colorbar && numel(colorbar_range) == 2
    set(ax, 'CLim', colorbar_range);
else
    % 自动范围
    finite_vals = flux_magnitude_plot(isfinite(flux_magnitude_plot));
    if isempty(finite_vals)
        warning('Flux magnitude contains no finite values. Using fallback range [0, 1].');
        cmin = 0; cmax = 1;
    else
        cmin = min(finite_vals);
        cmax = max(finite_vals);
        if cmax <= cmin
            if cmax == 0
                cmax = 1;
            else
                padding = max(abs(cmax), 1) * 0.05;
                cmin = cmin - padding;
                cmax = cmax + padding;
            end
        end
    end
    set(ax, 'CLim', [cmin, cmax]);
    fprintf('Auto colorbar range: [%.2e, %.2e] s^{-1}\n', cmin, cmax);
end

%% 应用色表
if use_custom_colormap
    try
        load('mycontour.mat', 'mycontour');
        colormap(ax, mycontour);
        fprintf('Using custom colormap (mycontour.mat).\n');
    catch
        warning('Failed to load mycontour.mat. Falling back to parula.');
        colormap(ax, 'parula');
    end
else
    colormap(ax, 'parula');
end

%% 添加 colorbar
h_cb = colorbar(ax);
ylabel(h_cb, colorbar_label, 'FontSize', 30, 'Interpreter', 'latex');

%% 绘制归一化箭头
if nx_plot > 1 && ny_plot > 1
    [X_quiver, Y_quiver] = meshgrid(1:nx_plot, 1:ny_plot);
    % 转置以匹配 imagesc 的坐标约定
    u_quiver = u_norm';
    v_quiver = v_norm';
    quiver(ax, X_quiver, Y_quiver, u_quiver, v_quiver, 0.4, ...
        'Color', [0.1 0.1 0.1], 'LineWidth', 0.9, 'AutoScale', 'off');
end

%% 添加区域分隔线
plot(ax, [INNER_DIV_END + 0.5, INNER_DIV_END + 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [OUTER_DIV_START - 0.5, OUTER_DIV_START - 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [OMP_IDX + 0.5, OMP_IDX + 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [IMP_IDX + 0.5, IMP_IDX + 0.5], [0.5, ny_plot + 0.5], 'k--', 'LineWidth', 1.0);
plot(ax, [0.5, nx_plot + 0.5], [SEPARATRIX_LINE + 0.5, SEPARATRIX_LINE + 0.5], 'k-', 'LineWidth', 1.5);

%% 添加区域标签
label_font = 26;
top_y = ny_plot + 1.2;
text(ax, 1, top_y, 'OT', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, INNER_DIV_END, top_y, 'ODE', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, OMP_IDX, top_y, 'OMP', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, IMP_IDX, top_y, 'IMP', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, OUTER_DIV_START, top_y, 'IDE', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, nx_plot, top_y, 'IT', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

center_x = round(nx_plot / 2);
core_y = max(2, round(SEPARATRIX_LINE * 0.6));
sol_y = min(ny_plot - 1, SEPARATRIX_LINE + round((ny_plot - SEPARATRIX_LINE) * 0.65));

text(ax, center_x, core_y, 'Core', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, center_x, sol_y, 'SOL', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, round(INNER_DIV_END * 0.5), core_y, 'PFR', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, round(OUTER_DIV_START + (nx_plot - OUTER_DIV_START) * 0.5), core_y, 'PFR', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
text(ax, center_x, SEPARATRIX_LINE + 2, 'Separatrix', 'FontSize', label_font, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');

%% 设置坐标轴
xlabel(ax, '$i_x$', 'FontSize', 30);
ylabel(ax, '$i_y$', 'FontSize', 30);
axis(ax, [0.5, nx_plot + 0.5, 0.5, ny_plot + 0.5]);
% 设置数据宽高比为1:1，使每个网格单元呈正方形
% 这样箭头方向的物理意义不会被网格长宽比影响
daspect(ax, [1 1 1]);
xticks_vals = unique([1, INNER_DIV_END, OMP_IDX, IMP_IDX, OUTER_DIV_START, nx_plot]);
yticks_vals = unique([1, SEPARATRIX_LINE, ny_plot]);
set(ax, 'XTick', xticks_vals, 'YTick', yticks_vals, 'FontSize', 24);
box(ax, 'on');
grid(ax, 'off');

hold(ax, 'off');

%% 设置数据游标
% 注意：数据游标回调需要使用嵌套函数或外部函数，这里使用匿名函数包装
dcm = datacursormode(fig);
set(dcm, 'Enable', 'on');
% 存储数据到 figure 的 UserData 中，供数据游标回调使用
fig.UserData.flux_pol = flux_pol_plot;
fig.UserData.flux_rad = flux_rad_plot;
fig.UserData.flux_mag = flux_magnitude_plot;
fig.UserData.nx_plot = nx_plot;
fig.UserData.ny_plot = ny_plot;
set(dcm, 'UpdateFcn', @local_datacursor_callback);

%% 保存 figure
% 生成安全的文件名
safe_dir = regexprep(dirName, '[^a-zA-Z0-9_\-\.]', '_');
if numel(safe_dir) > 120
    safe_dir = safe_dir(1:120);
end
if isempty(safe_dir)
    safe_dir = 'Case';
end

% 生成价态标签用于文件名
if numel(states) == (states(end) - states(1) + 1) && all(diff(states) == 1)
    file_tag = sprintf('N%dtoN%d', states(1), states(end));
elseif numel(states) == 1
    file_tag = sprintf('N%d', states);
else
    file_tag = ['N', strjoin(arrayfun(@num2str, states, 'UniformOutput', false), '_')];
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
fig_name = sprintf('NFluxDistribution_%s_%s_%s.fig', file_tag, safe_dir, timestamp);

set(fig, 'PaperPositionMode', 'auto');
try
    savefig(fig, fig_name);
    fprintf('Figure saved: %s\n', fig_name);
catch ME
    warning('Failed to save figure %s. Details: %s', fig_name, ME.message);
end

end


function output_txt = local_datacursor_callback(~, event_obj)
% 数据游标回调函数：显示单元格索引和通量值
% 从 figure 的 UserData 中读取数据

fig = ancestor(event_obj.Target, 'figure');
if isempty(fig) || ~isfield(fig.UserData, 'flux_pol')
    output_txt = {'Data unavailable'};
    return;
end

userData = fig.UserData;
nx_p = userData.nx_plot;
ny_p = userData.ny_plot;
flux_pol_plot = userData.flux_pol;
flux_rad_plot = userData.flux_rad;
flux_magnitude_plot = userData.flux_mag;

pos = get(event_obj, 'Position');
x_clicked = pos(1);
y_clicked = pos(2);

if nx_p <= 0 || ny_p <= 0
    output_txt = {'Invalid grid size'};
    return;
end

% 找到最近的网格单元
[~, ix] = min(abs((1:nx_p) - x_clicked));
[~, iy] = min(abs((1:ny_p) - y_clicked));
ix = max(1, min(ix, nx_p));
iy = max(1, min(iy, ny_p));

pol_flux = flux_pol_plot(ix, iy);
rad_flux = flux_rad_plot(ix, iy);
mag_flux = flux_magnitude_plot(ix, iy);

output_txt = {sprintf('Cell (ix, iy): (%d, %d)', ix, iy), ...
    sprintf('Poloidal Flux: %.3e s^{-1}', pol_flux), ...
    sprintf('Radial Flux: %.3e s^{-1}', rad_flux), ...
    sprintf('Flux Magnitude: %.3e s^{-1}', mag_flux)};
end
