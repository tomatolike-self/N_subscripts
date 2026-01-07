function plot_enhanced_radial_flux_components_comparison_N(all_radiationData, groupDirs, use_single_group_mode, use_full_charge_state_mode)
% =========================================================================
% plot_enhanced_radial_flux_components_comparison_N - 分离面径向通量三分量对比图（N体系）
% =========================================================================
%
% 功能描述：
%   - 同时展示总径向通量、径向扩散通量以及ExB径向通量
%   - 突出三种传输机制在Core Influx与Core Outflux时的贡献
%   - 按N离子价态分组进行堆叠显示（N1+ to N7+）
%
% 输入：
%   - all_radiationData : cell数组，包含所有SOLPS仿真数据
%   - groupDirs         : 分组目录信息的cell数组（保留接口，当前未使用）
%   - use_single_group_mode     : 逻辑值，是否使用单组颜色模式（默认false，保留接口）
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
%   - 本文件包含3个辅助函数：assembleChargeGroupMatrix, computeStackData, drawStackedBars
%     拆分理由：数据组装、堆叠计算、柱状图绘制逻辑独立且复杂，拆分提高可读性
%   - 图例使用patch创建句柄，避免bar(NaN,NaN)影响axes范围
% =========================================================================

%% 输入参数处理
if nargin < 3 || isempty(use_single_group_mode)
    use_single_group_mode = false;  %#ok<NASGU>
end
if nargin < 4 || isempty(use_full_charge_state_mode)
    use_full_charge_state_mode = false;
end

%% 常量定义
% N体系价态范围：N1+到N7+（对应plasma.na的第4到10维）
N_SPECIES_START = 4;   % N1+在plasma.na中的索引
MAX_N_CHARGE = 7;      % N系统最高价态（N7+）

% 分离面位置定义（EAST标准网格：98×28，去除guard cell后为96×26）
MAIN_SOL_POL_RANGE = 26:73;  % 主SOL极向网格范围（避开私有通量区）
SEPARATRIX_RAD_POS = 14;     % 分离面径向位置

% 绘图属性
TICK_FONT_SIZE = 32;
LABEL_FONT_SIZE = 36;
LEGEND_FONT_SIZE = 30;

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

% 初始化cell数组存储每个价态的通量
% 每个cell元素为 1×num_cases 行向量
per_charge_total_inward = cell(1, MAX_N_CHARGE);
per_charge_total_outward = cell(1, MAX_N_CHARGE);
per_charge_diff_inward = cell(1, MAX_N_CHARGE);
per_charge_diff_outward = cell(1, MAX_N_CHARGE);
per_charge_exb_inward = cell(1, MAX_N_CHARGE);
per_charge_exb_outward = cell(1, MAX_N_CHARGE);

% 初始化总通量数组（用于计算各价态份额）
total_all_inward = zeros(1, num_cases);
total_all_outward = zeros(1, num_cases);
total_diff_inward = zeros(1, num_cases);
total_diff_outward = zeros(1, num_cases);
total_exb_inward = zeros(1, num_cases);
total_exb_outward = zeros(1, num_cases);

% 预先初始化每个价态的通量数组
for i_charge = 1:MAX_N_CHARGE
    per_charge_total_inward{i_charge} = zeros(1, num_cases);
    per_charge_total_outward{i_charge} = zeros(1, num_cases);
    per_charge_diff_inward{i_charge} = zeros(1, num_cases);
    per_charge_diff_outward{i_charge} = zeros(1, num_cases);
    per_charge_exb_inward{i_charge} = zeros(1, num_cases);
    per_charge_exb_outward{i_charge} = zeros(1, num_cases);
end

%% 逐算例收集通量数据
for i_case = 1:num_cases
    radData = all_radiationData{i_case};
    fprintf('Processing case %d/%d: %s\n', i_case, num_cases, radData.dirName);
    
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
        % fna_mdf(:,:,2,:) 为径向通量分量，单位：particles/s
        if size(plasma.fna_mdf, 4) >= species_idx
            total_rad_flux = plasma.fna_mdf(:, SEPARATRIX_RAD_POS, 2, species_idx);
            sep_total = total_rad_flux(MAIN_SOL_POL_RANGE);
            % 负值为进入芯部（influx），正值为离开芯部（outflux）
            inward_val = sum(sep_total(sep_total < 0), 'omitnan');
            outward_val = sum(sep_total(sep_total > 0), 'omitnan');
            per_charge_total_inward{i_charge}(i_case) = inward_val;
            per_charge_total_outward{i_charge}(i_case) = outward_val;
            total_all_inward(i_case) = total_all_inward(i_case) + inward_val;
            total_all_outward(i_case) = total_all_outward(i_case) + outward_val;
        end
        
        % --- ExB通量：Γ_ExB = n × v_ExB × A ---
        % vaecrb(:,:,2,:) 为ExB径向速度分量，gs(:,:,2) 为径向面积
        if size(plasma.vaecrb, 4) >= species_idx
            ion_density = plasma.na(:, :, species_idx);
            exb_rad_velocity = plasma.vaecrb(:, :, 2, species_idx);
            area_rad = gmtry.gs(:, :, 2);
            exb_rad_flux = ion_density .* exb_rad_velocity .* area_rad;
            sep_exb = exb_rad_flux(MAIN_SOL_POL_RANGE, SEPARATRIX_RAD_POS);
            inward_val = sum(sep_exb(sep_exb < 0), 'omitnan');
            outward_val = sum(sep_exb(sep_exb > 0), 'omitnan');
            per_charge_exb_inward{i_charge}(i_case) = inward_val;
            per_charge_exb_outward{i_charge}(i_case) = outward_val;
            total_exb_inward(i_case) = total_exb_inward(i_case) + inward_val;
            total_exb_outward(i_case) = total_exb_outward(i_case) + outward_val;
        end
        
        % --- 扩散通量：Γ_diff = -D × ∇n ---
        % cdna(:,:,2,:) 为径向扩散系数
        if size(plasma.cdna, 4) >= species_idx && size(plasma.na, 2) >= 2
            cdna_rad = plasma.cdna(:, :, 2, species_idx);
            na_full = plasma.na(:, :, species_idx);
            % 用相邻网格的密度差近似梯度
            na_upper = na_full(:, 2:end);
            na_lower = na_full(:, 1:end-1);
            cdna_faces = cdna_rad(:, 2:end);
            gamma_diff = -cdna_faces .* (na_upper - na_lower);
            
            gamma_diff_full = zeros(nx_orig, ny_orig);
            gamma_diff_full(:, 2:end) = gamma_diff;
            
            sep_diff = gamma_diff_full(MAIN_SOL_POL_RANGE, SEPARATRIX_RAD_POS);
            inward_val = sum(sep_diff(sep_diff < 0), 'omitnan');
            outward_val = sum(sep_diff(sep_diff > 0), 'omitnan');
            per_charge_diff_inward{i_charge}(i_case) = inward_val;
            per_charge_diff_outward{i_charge}(i_case) = outward_val;
            total_diff_inward(i_case) = total_diff_inward(i_case) + inward_val;
            total_diff_outward(i_case) = total_diff_outward(i_case) + outward_val;
        end
    end
end

%% 定义价态分组和颜色
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
    % 简化的4组模式：低价态合并以突出主要贡献者
    charge_group_defs = {1:2, 3:4, 5:6, 7};
    legend_labels = {'N$^{1-2+}$', 'N$^{3-4+}$', 'N$^{5-6+}$', 'N$^{7+}$'};
    state_colors = [
        0, 0, 1;      % 蓝色
        0, 0.8, 0;    % 绿色
        1, 0.5, 0;    % 橙色
        0.8, 0, 0.8   % 紫色
        ];
end

nChargeGroups = numel(charge_group_defs);

%% 创建Figure
fig = figure('NumberTitle', 'off', 'Color', 'w', ...
    'Units', 'inches', 'Position', [2, 2, 14, 10]);

hold on;

%% 计算柱状图X轴位置
% Core Influx在左侧，Core Outflux在右侧
% 每个block内有三类柱：总通量、扩散通量、ExB通量
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

%% 组装分组后的堆叠数据
% 将各价态数据按分组合并，然后计算相对份额并转换为堆叠数据
total_in_stack = computeStackData(per_charge_total_inward, charge_group_defs, total_all_inward, num_cases);
total_out_stack = computeStackData(per_charge_total_outward, charge_group_defs, total_all_outward, num_cases);
diff_in_stack = computeStackData(per_charge_diff_inward, charge_group_defs, total_diff_inward, num_cases);
diff_out_stack = computeStackData(per_charge_diff_outward, charge_group_defs, total_diff_outward, num_cases);
exb_in_stack = computeStackData(per_charge_exb_inward, charge_group_defs, total_exb_inward, num_cases);
exb_out_stack = computeStackData(per_charge_exb_outward, charge_group_defs, total_exb_outward, num_cases);

% 三类通量的X位置（左-中-右排列：总通量-扩散-ExB）
x_total_1 = x_block1 - bar_offset;
x_diff_1 = x_block1;
x_exb_1 = x_block1 + bar_offset;
x_total_2 = x_block2 - bar_offset;
x_diff_2 = x_block2;
x_exb_2 = x_block2 + bar_offset;

%% 绘制堆叠柱状图
% Core Influx（左侧block）
drawStackedBars(x_total_1, total_in_stack, bar_width, nChargeGroups, state_colors, num_cases);
drawStackedBars(x_diff_1, diff_in_stack, bar_width, nChargeGroups, state_colors, num_cases);
drawStackedBars(x_exb_1, exb_in_stack, bar_width, nChargeGroups, state_colors, num_cases);

% Core Outflux（右侧block）
drawStackedBars(x_total_2, total_out_stack, bar_width, nChargeGroups, state_colors, num_cases);
drawStackedBars(x_diff_2, diff_out_stack, bar_width, nChargeGroups, state_colors, num_cases);
drawStackedBars(x_exb_2, exb_out_stack, bar_width, nChargeGroups, state_colors, num_cases);

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

% Y轴范围：覆盖典型N离子通量范围
ylim([-6e20, 8e20]);

% Y轴指数格式：手动设置以确保导出时显示
ax.YAxis.Exponent = 20;
ax.YAxis.ExponentMode = 'manual';

ylabel('$\Gamma_{\mathrm{r}}$ (s$^{-1}$)', 'Interpreter', 'latex', ...
    'FontName', 'Times New Roman', 'FontSize', LABEL_FONT_SIZE);

grid on;
ax.GridAlpha = 0.3;
ax.GridLineStyle = '--';
box on;

% 零线：区分进入和离开芯部的通量
line(xlim, [0, 0], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1);

%% 图例
% 使用patch创建图例句柄（避免bar(NaN,NaN)影响axes范围）
try
    legend_handles = gobjects(nChargeGroups, 1);
    for k = 1:nChargeGroups
        legend_handles(k) = patch(NaN, NaN, state_colors(k, :), ...
            'EdgeColor', 'k', 'LineWidth', 1.5);
    end
    lg = legend(legend_handles, legend_labels, 'Location', 'best');
    set(lg, 'Interpreter', 'latex', 'FontName', 'Times New Roman', 'FontSize', LEGEND_FONT_SIZE);
    set(lg, 'Box', 'on', 'LineWidth', 1.5);
catch ME
    fprintf('Warning: Failed to create legend. Error: %s\n', ME.message);
end

% 确保坐标轴范围在图例创建后仍然正确
ylim([-6e20, 8e20]);
xlim([0, 6]);

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
%  辅助函数1：按分组合并数据矩阵
% =========================================================================
function grouped_mat = assembleChargeGroupMatrix(per_charge_cells, charge_group_defs, num_cases)
% 将各价态数据按分组合并
%
% 输入：
%   per_charge_cells  - 1×MAX_N_CHARGE cell数组，每个元素为1×num_cases通量数据
%   charge_group_defs - 1×nGroups cell数组，每个元素定义该组包含的价态索引
%   num_cases         - 算例数量
%
% 输出：
%   grouped_mat       - [num_cases × nGroups] 矩阵

nChargeGroups = numel(charge_group_defs);
grouped_mat = zeros(num_cases, nChargeGroups);

for g = 1:nChargeGroups
    charge_list = charge_group_defs{g};
    for idx = 1:length(charge_list)
        cs = charge_list(idx);
        if cs > numel(per_charge_cells)
            continue;
        end
        data = per_charge_cells{cs};
        if isempty(data)
            continue;
        end
        % 确保data为列向量后赋值
        data = data(:);
        fill_len = min(num_cases, length(data));
        grouped_mat(1:fill_len, g) = grouped_mat(1:fill_len, g) + data(1:fill_len);
    end
end
end


%% =========================================================================
%  辅助函数2：计算堆叠数据（合并了份额计算和堆叠转换）
% =========================================================================
function stack_data = computeStackData(per_charge_cells, charge_group_defs, total_flux, num_cases)
% 将各价态通量按分组合并，计算相对份额，并转换为堆叠数据
%
% 输入：
%   per_charge_cells  - 每个价态的通量cell数组
%   charge_group_defs - 价态分组定义
%   total_flux        - 1×num_cases 总通量数组
%   num_cases         - 算例数量
%
% 输出：
%   stack_data        - [num_cases × nGroups] 堆叠数据矩阵

% 步骤1：按分组合并
grouped_mat = assembleChargeGroupMatrix(per_charge_cells, charge_group_defs, num_cases);

% 步骤2：计算份额并转换为堆叠数据
nGroups = size(grouped_mat, 2);
stack_data = zeros(num_cases, nGroups);

for i = 1:num_cases
    flux_val = total_flux(i);
    if ~isnan(flux_val) && flux_val ~= 0
        % 份额 = |分组通量| / |总通量|
        share = abs(grouped_mat(i, :)) / abs(flux_val);
        % 堆叠数据 = 份额 × 总通量（保持符号）
        stack_data(i, :) = share * flux_val;
    end
end
end


%% =========================================================================
%  辅助函数3：绘制堆叠柱状图
% =========================================================================
function drawStackedBars(x_positions, stack_data, bar_width, nChargeGroups, state_colors, num_cases)
% 绘制堆叠柱状图
%
% 输入：
%   x_positions   - 柱状图X轴位置
%   stack_data    - [num_cases × nGroups] 堆叠数据
%   bar_width     - 柱宽
%   nChargeGroups - 价态分组数
%   state_colors  - [nGroups × 3] 颜色矩阵
%   num_cases     - 算例数量

% 数据检查：无有效数据时直接返回
if isempty(stack_data) || ~any(abs(stack_data(:)) > 0)
    return;
end

% 清理非有限值
stack_data_clean = stack_data;
stack_data_clean(~isfinite(stack_data_clean)) = 0;

% 绘制堆叠柱状图
% 单算例时需要转置数据
if num_cases == 1
    b = bar(x_positions, stack_data_clean', bar_width, 'stacked');
else
    b = bar(x_positions, stack_data_clean, bar_width, 'stacked');
end

% 设置颜色
try
    if length(b) == nChargeGroups
        for k = 1:nChargeGroups
            set(b(k), 'FaceColor', state_colors(k, :), 'EdgeColor', 'k', 'LineWidth', 1.5);
        end
    elseif length(b) == 1 && nChargeGroups > 1
        % 某些MATLAB版本的bar返回结构可能不同
        for k = 1:min(nChargeGroups, length(b.Children))
            set(b.Children(k), 'FaceColor', state_colors(nChargeGroups-k+1, :), ...
                'EdgeColor', 'k', 'LineWidth', 1.5);
        end
    end
catch
    % 颜色设置失败不影响主流程
end
end
