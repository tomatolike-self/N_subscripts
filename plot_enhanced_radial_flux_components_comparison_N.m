function plot_enhanced_radial_flux_components_comparison_N(all_radiationData, groupDirs, use_single_group_mode, use_full_charge_state_mode)
% =========================================================================
% plot_enhanced_radial_flux_components_comparison_N - 分离面径向通量三分量对比图（N体系）
% =========================================================================
%
% 功能描述：
%   - 同时展示总径向通量、径向扩散通量以及ExB径向通量
%   - 突出三种传输机制在进入（Core Influx）与离开（Core Outflux）芯部时的贡献
%   - 按价态分组进行堆叠显示
%
% 输入：
%   - all_radiationData : cell数组，包含所有SOLPS仿真数据
%   - groupDirs         : 分组目录信息的cell数组
%   - use_single_group_mode     : 逻辑值，是否使用单组颜色模式（默认false）
%   - use_full_charge_state_mode: 逻辑值，是否使用全部价态分别展示模式（默认false）
%
% 输出：
%   - 通量对比柱状图figure
%   - 自动保存带时间戳的.fig文件
%
% 依赖函数/工具箱：
%   - 无
%
% 注意事项：
%   - R2019a兼容
%   - N体系：N1+到N7+（共7个带电价态），plasma.na索引4-10
%   - 本文件包含3个辅助函数：collectFluxData, assembleStackData, drawStackedBars
%     拆分理由：通量收集、数据组装、绘图逻辑独立且复杂
% =========================================================================

%% 输入参数处理
if nargin < 3 || isempty(use_single_group_mode)
    use_single_group_mode = false;
end
if nargin < 4 || isempty(use_full_charge_state_mode)
    use_full_charge_state_mode = false;
end

%% 常量定义
% N体系价态范围：N1+到N7+（对应na的第4到10维）
N_SPECIES_START = 4;   % N1+在plasma.na中的索引
N_SPECIES_END = 10;    % N7+在plasma.na中的索引
MAX_N_CHARGE = 7;      % N系统最高价态

% 分离面位置定义（EAST网格）
MAIN_SOL_POL_RANGE = 26:73;  % 主SOL极向网格范围
SEPARATRIX_RAD_POS = 14;     % 分离面径向位置

% 绘图属性
TICK_FONT_SIZE = 32;
LABEL_FONT_SIZE = 36;
LEGEND_FONT_SIZE = 30;
Y_SCALE_FACTOR = 1e20;  % Y轴缩放因子
Y_SCALE_EXPONENT = 20;  % Y轴指数

%% 设置绘图默认属性
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', TICK_FONT_SIZE);
set(0, 'DefaultTextFontSize', TICK_FONT_SIZE);
set(0, 'DefaultLineLineWidth', 2.5);
set(0, 'DefaultTextInterpreter', 'latex');
set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
set(0, 'DefaultLegendInterpreter', 'latex');

fprintf('\n=== Enhanced Radial Flux Components Comparison (N System) ===\n');

%% 收集各价态通量数据
num_cases = length(all_radiationData);

% 初始化存储矩阵 [num_cases x MAX_N_CHARGE]
total_inward_mat = zeros(num_cases, MAX_N_CHARGE);
total_outward_mat = zeros(num_cases, MAX_N_CHARGE);
diff_inward_mat = zeros(num_cases, MAX_N_CHARGE);
diff_outward_mat = zeros(num_cases, MAX_N_CHARGE);
exb_inward_mat = zeros(num_cases, MAX_N_CHARGE);
exb_outward_mat = zeros(num_cases, MAX_N_CHARGE);

for i_case = 1:num_cases
    radData = all_radiationData{i_case};
    fprintf('Processing case %d/%d: %s\n', i_case, num_cases, radData.dirName);
    
    % 获取数据
    gmtry = radData.gmtry;
    plasma = radData.plasma;
    
    % 检查数据完整性
    if ~isfield(plasma, 'fna_mdf') || ~isfield(plasma, 'na') || ...
            ~isfield(plasma, 'vaecrb') || ~isfield(plasma, 'cdna')
        warning('Missing required fields for case: %s. Skipping.', radData.dirName);
        continue;
    end
    
    % 检查网格尺寸
    [nx_orig, ny_orig] = size(gmtry.crx(:,:,1));
    if max(MAIN_SOL_POL_RANGE) > nx_orig || SEPARATRIX_RAD_POS > ny_orig
        warning('Grid size mismatch for case: %s. Skipping.', radData.dirName);
        continue;
    end
    
    % 逐价态收集通量
    for i_charge = 1:MAX_N_CHARGE
        species_idx = N_SPECIES_START + i_charge - 1;  % N1+ -> 4, N7+ -> 10
        
        if species_idx > size(plasma.na, 3)
            continue;
        end
        
        % --- 总通量（所有传输机制）：使用fna_mdf ---
        if size(plasma.fna_mdf, 4) >= species_idx
            total_rad_flux = plasma.fna_mdf(:, SEPARATRIX_RAD_POS, 2, species_idx);
            sep_total_flux = total_rad_flux(MAIN_SOL_POL_RANGE);
            total_inward_mat(i_case, i_charge) = sum(sep_total_flux(sep_total_flux < 0), 'omitnan');
            total_outward_mat(i_case, i_charge) = sum(sep_total_flux(sep_total_flux > 0), 'omitnan');
        end
        
        % --- ExB通量：使用 na × vaecrb × gs ---
        if size(plasma.vaecrb, 4) >= species_idx
            ion_density = plasma.na(:, :, species_idx);
            exb_rad_velocity = plasma.vaecrb(:, :, 2, species_idx);
            area_rad = gmtry.gs(:, :, 2);
            exb_rad_flux = ion_density .* exb_rad_velocity .* area_rad;
            sep_exb_flux = exb_rad_flux(MAIN_SOL_POL_RANGE, SEPARATRIX_RAD_POS);
            exb_inward_mat(i_case, i_charge) = sum(sep_exb_flux(sep_exb_flux < 0), 'omitnan');
            exb_outward_mat(i_case, i_charge) = sum(sep_exb_flux(sep_exb_flux > 0), 'omitnan');
        end
        
        % --- 扩散通量：使用 -cdna × (na_upper - na_lower) ---
        if size(plasma.cdna, 4) >= species_idx && size(plasma.na, 2) >= 2
            cdna_rad = plasma.cdna(:, :, 2, species_idx);
            na_full = plasma.na(:, :, species_idx);
            na_upper = na_full(:, 2:end);
            na_lower = na_full(:, 1:end-1);
            cdna_faces = cdna_rad(:, 2:end);
            gamma_diff = -cdna_faces .* (na_upper - na_lower);
            
            gamma_diff_full = zeros(nx_orig, ny_orig);
            gamma_diff_full(:, 2:end) = gamma_diff;
            
            sep_diff_flux = gamma_diff_full(MAIN_SOL_POL_RANGE, SEPARATRIX_RAD_POS);
            diff_inward_mat(i_case, i_charge) = sum(sep_diff_flux(sep_diff_flux < 0), 'omitnan');
            diff_outward_mat(i_case, i_charge) = sum(sep_diff_flux(sep_diff_flux > 0), 'omitnan');
        end
    end
end

%% 按价态分组
if use_full_charge_state_mode
    % 全部7个价态分别显示
    charge_group_defs = {1, 2, 3, 4, 5, 6, 7};
    legend_labels = {'N$^{1+}$', 'N$^{2+}$', 'N$^{3+}$', 'N$^{4+}$', 'N$^{5+}$', 'N$^{6+}$', 'N$^{7+}$'};
    state_colors = [
        0, 0, 1;      % N1+ - 蓝色
        0, 0.5, 1;    % N2+ - 浅蓝
        0, 0.8, 0.8;  % N3+ - 青色
        0, 0.8, 0;    % N4+ - 绿色
        1, 0.5, 0;    % N5+ - 橙色
        1, 0, 0;      % N6+ - 红色
        0.8, 0, 0.8   % N7+ - 紫色
        ];
else
    % 简化的4组模式（N1-2+合并，N3-4+合并，N5-6+合并，N7+单独）
    charge_group_defs = {1:2, 3:4, 5:6, 7};
    legend_labels = {'N$^{1+}$ to N$^{2+}$', 'N$^{3+}$ to N$^{4+}$', 'N$^{5+}$ to N$^{6+}$', 'N$^{7+}$'};
    state_colors = [
        0, 0, 1;      % 蓝色
        0, 0.8, 0;    % 绿色
        1, 0.5, 0;    % 橙色
        0.8, 0, 0.8   % 紫色
        ];
end

nChargeGroups = numel(charge_group_defs);

%% 组装分组后的堆叠数据
% 将各价态数据按分组合并
total_in_grouped = assembleGroupedData(total_inward_mat, charge_group_defs, num_cases);
total_out_grouped = assembleGroupedData(total_outward_mat, charge_group_defs, num_cases);
diff_in_grouped = assembleGroupedData(diff_inward_mat, charge_group_defs, num_cases);
diff_out_grouped = assembleGroupedData(diff_outward_mat, charge_group_defs, num_cases);
exb_in_grouped = assembleGroupedData(exb_inward_mat, charge_group_defs, num_cases);
exb_out_grouped = assembleGroupedData(exb_outward_mat, charge_group_defs, num_cases);

% 缩放数据（除以Y_SCALE_FACTOR）
total_in_scaled = total_in_grouped / Y_SCALE_FACTOR;
total_out_scaled = total_out_grouped / Y_SCALE_FACTOR;
diff_in_scaled = diff_in_grouped / Y_SCALE_FACTOR;
diff_out_scaled = diff_out_grouped / Y_SCALE_FACTOR;
exb_in_scaled = exb_in_grouped / Y_SCALE_FACTOR;
exb_out_scaled = exb_out_grouped / Y_SCALE_FACTOR;

%% 创建Figure
fig = figure('NumberTitle', 'off', 'Color', 'w', ...
    'Units', 'inches', 'Position', [2, 2, 14, 10]);

hold on;

%% 计算柱状图X轴位置
if num_cases == 1
    block_spacing = 2.0;
    x_block1 = 1;
    x_block2 = 1 + block_spacing;
    bar_width = 0.7;
    bar_offset = bar_width * 0.8;
else
    block_width = num_cases;
    block_spacing = 0.6;
    x_block1 = 1:num_cases;
    x_block2 = (block_width + block_spacing + 1):(block_width + block_spacing + num_cases);
    bar_width = 0.3;
    bar_offset = bar_width;
end

% 三类通量的X位置（每个块内左中右排列）
x_total_1 = x_block1 - bar_offset;
x_diff_1 = x_block1;
x_exb_1 = x_block1 + bar_offset;
x_total_2 = x_block2 - bar_offset;
x_diff_2 = x_block2;
x_exb_2 = x_block2 + bar_offset;

%% 绘制堆叠柱状图
drawStackedBars(x_total_1, total_in_scaled, bar_width, nChargeGroups, state_colors, num_cases);
drawStackedBars(x_diff_1, diff_in_scaled, bar_width, nChargeGroups, state_colors, num_cases);
drawStackedBars(x_exb_1, exb_in_scaled, bar_width, nChargeGroups, state_colors, num_cases);

drawStackedBars(x_total_2, total_out_scaled, bar_width, nChargeGroups, state_colors, num_cases);
drawStackedBars(x_diff_2, diff_out_scaled, bar_width, nChargeGroups, state_colors, num_cases);
drawStackedBars(x_exb_2, exb_out_scaled, bar_width, nChargeGroups, state_colors, num_cases);

hold off;

%% 设置坐标轴
if num_cases == 1
    block1_center = x_block1;
    block2_center = x_block2;
else
    block1_center = mean(x_block1);
    block2_center = mean(x_block2);
end

xticks([block1_center, block2_center]);
xticklabels({'Core Influx', 'Core Outflux'});

ax = gca;
set(ax, 'FontName', 'Times New Roman', 'FontSize', TICK_FONT_SIZE);
set(ax, 'TickLabelInterpreter', 'latex');
set(ax, 'LineWidth', 2.5);

% Y轴标签：显式写明指数项
ylabel_str = sprintf('$\\Gamma_{\\mathrm{r}}$ ($\\times 10^{%d}$ s$^{-1}$)', Y_SCALE_EXPONENT);
ylabel(ylabel_str, 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', LABEL_FONT_SIZE);

grid on;
ax.GridAlpha = 0.3;
ax.GridLineStyle = '--';
box on;

% 零线
line(xlim, [0, 0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1);

%% 图例
legend_handles = gobjects(nChargeGroups, 1);
for k = 1:nChargeGroups
    legend_handles(k) = bar(NaN, NaN, 'FaceColor', state_colors(k, :), ...
        'EdgeColor', 'k', 'LineWidth', 1.5);
end
lg = legend(legend_handles, legend_labels, 'Location', 'best');
set(lg, 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', LEGEND_FONT_SIZE);
set(lg, 'Box', 'on', 'LineWidth', 1.5);

%% 保存Figure
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
if use_full_charge_state_mode
    fname = sprintf('Enhanced_Radial_Flux_Components_N_Full_%s.fig', timestamp);
else
    fname = sprintf('Enhanced_Radial_Flux_Components_N_Simplified_%s.fig', timestamp);
end
savefig(fig, fname);
fprintf('Figure saved: %s\n', fname);

fprintf('\n=== Enhanced Radial Flux Components Comparison (N System) Completed ===\n');

end


%% =========================================================================
%  辅助函数1：按分组合并数据
% =========================================================================
function grouped_mat = assembleGroupedData(per_charge_mat, charge_group_defs, num_cases)
% 将各价态数据按分组合并
%
% 输入：
%   per_charge_mat    - [num_cases x MAX_N_CHARGE] 各价态数据矩阵
%   charge_group_defs - cell数组，每个元素定义一个组包含的价态索引
%   num_cases         - 算例数量
%
% 输出：
%   grouped_mat       - [num_cases x nChargeGroups] 分组后的数据矩阵

nChargeGroups = numel(charge_group_defs);
grouped_mat = zeros(num_cases, nChargeGroups);

for g = 1:nChargeGroups
    charge_list = charge_group_defs{g};
    for cs = charge_list
        if cs <= size(per_charge_mat, 2)
            grouped_mat(:, g) = grouped_mat(:, g) + per_charge_mat(:, cs);
        end
    end
end

% 清理NaN和Inf
grouped_mat(~isfinite(grouped_mat)) = 0;
end


%% =========================================================================
%  辅助函数2：绘制堆叠柱状图
% =========================================================================
function drawStackedBars(x_positions, stack_data, bar_width, nChargeGroups, state_colors, num_cases)
% 绘制堆叠柱状图
%
% 输入：
%   x_positions   - X轴位置
%   stack_data    - [num_cases x nChargeGroups] 堆叠数据
%   bar_width     - 柱宽
%   nChargeGroups - 价态分组数
%   state_colors  - [nChargeGroups x 3] 颜色矩阵
%   num_cases     - 算例数量

if isempty(stack_data) || ~any(abs(stack_data(:)) > 0)
    return;
end

stack_data_clean = stack_data;
stack_data_clean(~isfinite(stack_data_clean)) = 0;

if num_cases == 1
    % 单算例：转置后绘制
    b = bar(x_positions, stack_data_clean', bar_width, 'stacked');
else
    % 多算例：直接绘制
    b = bar(x_positions, stack_data_clean, bar_width, 'stacked');
end

% 设置颜色
if length(b) == nChargeGroups
    for k = 1:nChargeGroups
        set(b(k), 'FaceColor', state_colors(k, :), 'EdgeColor', 'k', 'LineWidth', 1.5);
    end
end
end
