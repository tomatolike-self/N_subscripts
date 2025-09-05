function plot_N_zeff_scaling_law_fitting(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends)
% PLOT_N_ZEFF_SCALING_LAW_FITTING 绘制N杂质Zeff标度律拟合分析图
%   拟合公式：Z_eff - 1 = C * (P_rad / n_e^gamma)
%   绘制拟合值与实际值的对比散点图
%   专门针对N杂质（N0到N7+）进行分析

    fprintf('\n=== Starting N impurity Zeff scaling law fitting analysis ===\n');

    % 设置默认参数
    if nargin < 5, useHardcodedLegends = false; end
    if nargin < 4, showLegendsForDirNames = true; end
    if nargin < 3, usePresetLegends = false; end
    
    %%%% 全局字体和绘图属性设置
    fontSize = 42;
    markerSize = 120;
    axisLabelFontSize = 48;  % XY轴标签字体大小
    axisTickFontSize = 36;   % XY轴刻度数字字体大小
    legendFontSize = 36;     % 图例字体大小

    % 设置全局字体为Times New Roman
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', axisTickFontSize);
    set(0, 'DefaultTextFontSize', fontSize);
    set(0, 'DefaultLegendFontSize', legendFontSize);

    % 初始化存储数组
    all_full_paths = cell(length(all_radiationData), 1);
    all_prad_values = zeros(length(all_radiationData), 1);
    all_ne_values = zeros(length(all_radiationData), 1);
    all_zeff_minus_1_values = zeros(length(all_radiationData), 1);

    valid_cases = 0;

    % 初始化异常值记录
    filtered_cases = {};
    filtered_reasons = {};
    filtered_count = 0;

    % 定义芯部区域索引（适用于98*28网格）
    core_indices_original = 26:73;
    
    %% ======================== 数据处理循环 ============================

    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        dirName = radData.dirName;

        fprintf('Processing case for N impurity Zeff fitting analysis: %s\n', dirName);

        %% ============== 计算CEI极向平均电子密度 ==============

        % 计算芯部区域体积
        core_vol = radData.gmtry.vol(core_indices_original, 2);
        total_vol_core_poloidal = sum(core_vol, 'omitnan');

        if total_vol_core_poloidal <= 0 || isnan(total_vol_core_poloidal)
            continue;
        end

        % 计算芯部体积加权平均电子密度
        ne_core = radData.plasma.ne(core_indices_original, 2);
        core_avg_ne = sum(ne_core .* core_vol, 'omitnan') / total_vol_core_poloidal;
        ne_value = core_avg_ne / 1e19; % 转换为10^19 m^-3单位
        
        %% ============== 计算N杂质Zeff（电子密度加权平均）==============

        % 计算Zeff分布
        nD = radData.plasma.na(:,:,1:2);  % D离子密度
        nN = radData.plasma.na(:,:,3:end); % N离子密度

        % 安全的电子密度（避免除零）
        safe_ne = max(radData.plasma.ne, 1e-10);

        % D+离子贡献 (Z^2 = 1)
        Zeff_D = nD(:,:,2) * (1^2) ./ safe_ne;

        % N离子各价态贡献（N0到N7+）
        Zeff_N = zeros(size(safe_ne));
        num_N_species = size(nN, 3);

        % 计算N各价态对Zeff的贡献（从N0开始）
        for i_Z = 1:min(num_N_species, 8)
            charge_state = i_Z - 1; % i_Z=1 -> charge_state=0 (N0), i_Z=2 -> charge_state=1 (N1+)
            if charge_state >= 0 && charge_state <= 7
                Zeff_N = Zeff_N + nN(:,:,i_Z) * (charge_state^2) ./ safe_ne;
            end
        end

        Zeff_total = Zeff_D + Zeff_N;

        % 计算芯部电子密度加权平均Zeff
        core_zeff = Zeff_total(core_indices_original, 2);
        core_ne = safe_ne(core_indices_original, 2);

        valid_mask = ~isnan(core_zeff) & core_vol > 0 & core_ne > 0;
        if sum(valid_mask) == 0
            continue;
        end

        ne_vol_sum = sum(core_ne(valid_mask) .* core_vol(valid_mask));
        zeff_ne_vol_sum = sum(core_zeff(valid_mask) .* core_ne(valid_mask) .* core_vol(valid_mask));
        average_Zeff = zeff_ne_vol_sum / ne_vol_sum;
        
        %% ============== 数据筛选和存储 ==============

        P_rad_total = radData.totrad;
        zeff_minus_1 = average_Zeff - 1;

        % 筛选有效数据 - 增加更严格的数值范围检查
        if zeff_minus_1 > 0.10 && zeff_minus_1 < 10 && ...  % Zeff-1合理范围
           P_rad_total > 0 && P_rad_total < 100 && ...       % 辐射功率合理范围(0-100 MW)
           ne_value > 0 && ne_value < 50 && ...              % 电子密度合理范围(0-50 x 10^19 m^-3)
           isfinite(zeff_minus_1) && isfinite(P_rad_total) && isfinite(ne_value)

            valid_cases = valid_cases + 1;
            all_full_paths{valid_cases} = dirName;
            all_prad_values(valid_cases) = P_rad_total;
            all_ne_values(valid_cases) = ne_value;
            all_zeff_minus_1_values(valid_cases) = zeff_minus_1;

            fprintf('  Valid case: Prad=%.3f MW, ne=%.3f (10^19 m^-3), Zeff-1=%.3f\n', ...
                    P_rad_total, ne_value, zeff_minus_1);
        else
            % 记录被过滤的案例
            filtered_count = filtered_count + 1;
            filtered_cases{filtered_count} = dirName;

            % 确定过滤原因并输出信息
            if P_rad_total > 100
                reason = sprintf('Prad too large (%.3e MW)', P_rad_total);
                fprintf('  Filtered case (Prad too large): Prad=%.3e MW, ne=%.3f, Zeff-1=%.3f\n', ...
                        P_rad_total, ne_value, zeff_minus_1);
            elseif zeff_minus_1 > 10
                reason = sprintf('Zeff-1 too large (%.3f)', zeff_minus_1);
                fprintf('  Filtered case (Zeff-1 too large): Prad=%.3f MW, ne=%.3f, Zeff-1=%.3f\n', ...
                        P_rad_total, ne_value, zeff_minus_1);
            elseif ne_value > 50
                reason = sprintf('ne too large (%.3f x 10^19 m^-3)', ne_value);
                fprintf('  Filtered case (ne too large): Prad=%.3f MW, ne=%.3f, Zeff-1=%.3f\n', ...
                        P_rad_total, ne_value, zeff_minus_1);
            elseif zeff_minus_1 <= 0.10
                reason = sprintf('Zeff-1 too small (%.3f)', zeff_minus_1);
                fprintf('  Filtered case (Zeff-1 too small): Prad=%.3f MW, ne=%.3f, Zeff-1=%.3f\n', ...
                        P_rad_total, ne_value, zeff_minus_1);
            else
                reason = 'Other criteria not met';
                fprintf('  Filtered case (other): Prad=%.3f MW, ne=%.3f, Zeff-1=%.3f\n', ...
                        P_rad_total, ne_value, zeff_minus_1);
            end

            filtered_reasons{filtered_count} = reason;
        end
    end

    % 截取有效数据
    all_full_paths = all_full_paths(1:valid_cases);
    all_prad_values = all_prad_values(1:valid_cases);
    all_ne_values = all_ne_values(1:valid_cases);
    all_zeff_minus_1_values = all_zeff_minus_1_values(1:valid_cases);

    fprintf('\nTotal valid cases for N impurity fitting: %d\n', valid_cases);
    fprintf('Total filtered cases: %d\n', filtered_count);

    % 输出异常值到文件
    if filtered_count > 0
        current_time = datetime('now');
        time_str = char(current_time, 'yyyyMMdd_HHmmss');
        filtered_filename = sprintf('N_Zeff_filtered_cases_%s.txt', time_str);

        fid = fopen(filtered_filename, 'w');
        if fid ~= -1
            fprintf(fid, 'N Impurity Zeff Scaling Law Fitting - Filtered Abnormal Cases\n');
            fprintf(fid, 'Generated Time: %s\n', char(current_time));
            fprintf(fid, 'Total Filtered Cases: %d\n\n', filtered_count);

            for i = 1:filtered_count
                fprintf(fid, 'Case %d:\n', i);
                fprintf(fid, 'Path: %s\n', filtered_cases{i});
                fprintf(fid, 'Filter Reason: %s\n\n', filtered_reasons{i});
            end

            fclose(fid);
            fprintf('Filtered cases saved to: %s\n', filtered_filename);
        else
            fprintf('Warning: Could not create filtered cases file.\n');
        end
    end

    if valid_cases < 2
        fprintf('Error: Not enough valid data points for fitting.\n');
        return;
    end

    %% ======================== 全局拟合 ============================

    fprintf('\n=== Performing global fitting for N impurity ===\n');

    % 定义拟合函数：Z_eff - 1 = C * (P_rad / n_e^gamma)
    zeff_formula = @(params, data) params(1) * (data(:,1) ./ (data(:,2).^params(2)));
    data_matrix = [all_prad_values, all_ne_values];

    % 数据安全性检查和预处理
    safe_prad = max(all_prad_values, 1e-10);
    safe_ne = max(all_ne_values, 1e-10);
    safe_zeff_minus_1 = max(all_zeff_minus_1_values, 1e-10);

    % 检查数据中是否有异常值
    fprintf('Data range check:\n');
    fprintf('  Prad range: %.3e to %.3e MW\n', min(safe_prad), max(safe_prad));
    fprintf('  ne range: %.3e to %.3e (10^19 m^-3)\n', min(safe_ne), max(safe_ne));
    fprintf('  Zeff-1 range: %.3e to %.3e\n', min(safe_zeff_minus_1), max(safe_zeff_minus_1));

    % 进一步检查数据是否包含异常值
    if any(~isfinite(safe_prad)) || any(~isfinite(safe_ne)) || any(~isfinite(safe_zeff_minus_1))
        fprintf('Error: Data contains non-finite values after safety check.\n');
        return;
    end

    try
        %% ============== 直接进行非线性拟合 ==============
        fprintf('Performing direct nonlinear fitting...\n');

        % 初始化拟合成功标志
        fit_successful = false;

        % 使用基于数据特征的合理初始参数
        % 根据数据范围估算初始参数
        mean_prad = mean(safe_prad);
        mean_ne = mean(safe_ne);
        mean_zeff_minus_1 = mean(safe_zeff_minus_1);

        % 初始估计：C ≈ (Zeff-1) * ne^gamma / Prad
        % 假设gamma初始值为1.0
        gamma_initial = 1.0;
        C_initial = mean_zeff_minus_1 * (mean_ne^gamma_initial) / mean_prad;

        % 确保初始参数在合理范围内
        C_initial = max(min(C_initial, 10), 0.01);
        gamma_initial = max(min(gamma_initial, 3), 0.1);

        fprintf('Initial guess based on data: C=%.4f, gamma=%.4f\n', C_initial, gamma_initial);

        % 尝试多组初始参数进行拟合
        initial_guesses = [
            C_initial, gamma_initial;           % 基于数据的估计
            0.1, 1.0;                          % 经验值1
            0.5, 1.5;                          % 经验值2
            1.0, 0.8;                          % 经验值3
            0.2, 2.0                           % 经验值4
        ];

        best_residual_norm = inf;
        best_params = [];
        best_fitted_values = [];

        options = optimset('Display', 'off', 'MaxIter', 10000, 'TolFun', 1e-10, 'TolX', 1e-10);

        for i = 1:size(initial_guesses, 1)
            try
                initial_guess = initial_guesses(i, :);
                fprintf('Trying initial guess %d: C=%.4f, gamma=%.4f\n', i, initial_guess(1), initial_guess(2));

                [fitted_params, residual_norm, residual] = lsqcurvefit(zeff_formula, initial_guess, ...
                                                           data_matrix, all_zeff_minus_1_values, ...
                                                           [1e-6, 0.01], [100, 5], options);

                % 检查拟合结果是否合理
                if all(isfinite(fitted_params)) && residual_norm < best_residual_norm
                    best_residual_norm = residual_norm;
                    best_params = fitted_params;
                    best_fitted_values = zeff_formula(fitted_params, data_matrix);
                    fprintf('  Better fit found: C=%.4f, gamma=%.4f, residual_norm=%.4e\n', ...
                            fitted_params(1), fitted_params(2), residual_norm);
                end

            catch ME
                fprintf('  Initial guess %d failed: %s\n', i, ME.message);
                continue;
            end
        end

        if ~isempty(best_params)
            fitted_params = best_params;
            fitted_values = best_fitted_values;

            fprintf('\nBest nonlinear fit results: C=%.4f, gamma=%.4f\n', fitted_params(1), fitted_params(2));

            % 计算拟合指标
            residual = all_zeff_minus_1_values - fitted_values;
            ss_res = sum(residual.^2);
            ss_tot = sum((all_zeff_minus_1_values - mean(all_zeff_minus_1_values)).^2);
            r_squared = 1 - ss_res/ss_tot;

            fprintf('Nonlinear fit R² = %.4f\n', r_squared);

            % 计算其他拟合指标
            mse = mean(residual.^2);
            mae = mean(abs(residual));
            fprintf('MSE = %.4e, MAE = %.4e\n', mse, mae);

            fit_successful = true;
        else
            fprintf('All fitting attempts failed.\n');
            fitted_values = nan(size(all_zeff_minus_1_values));
        end

    catch ME
        fprintf('Fitting failed: %s\n', ME.message);
        fit_successful = false;
        fitted_values = nan(size(all_zeff_minus_1_values));
    end
    
    %% ======================== 绘图 ============================

    if fit_successful
        fprintf('\n=== Creating N impurity fitting analysis plot ===\n');

        figure('Position', [100, 100, 1000, 800]);

        % 确定分组信息
        num_groups = max(1, length(groupDirs));
        if num_groups == 1 && isempty(groupDirs)
            groupDirs = {all_full_paths};
        end

        % 为每个案例分配分组 - 直接按照输入组进行精确匹配
        % 这与主脚本的分组逻辑保持一致，确保正确的8组分配
        group_assignments = zeros(length(all_full_paths), 1);
        for i_data = 1:length(all_full_paths)
            current_path = all_full_paths{i_data};

            % 直接在每个组中查找完全匹配的路径
            for i_group = 1:num_groups
                if any(strcmp(current_path, groupDirs{i_group}))
                    group_assignments(i_data) = i_group;
                    break;
                end
            end
        end

        hold on;

        if useHardcodedLegends
            % 硬编码绘图方式：前四个为fav. BT，后四个为unfav. BT
            fav_color = [0, 0, 1];    % 蓝色
            unfav_color = [1, 0, 0];  % 红色
            ne_markers = {'o', 's', 'd', '^'}; % 对应0.5, 1.0, 1.5, 2.0

            % 硬编码图例标签 - B为斜体，T为正体
            hardcoded_legends = {
                'fav. $\mathit{B}_{\mathrm{T}}$ 0.5', 'fav. $\mathit{B}_{\mathrm{T}}$ 1.0', 'fav. $\mathit{B}_{\mathrm{T}}$ 1.5', 'fav. $\mathit{B}_{\mathrm{T}}$ 2.0', ...
                'unfav. $\mathit{B}_{\mathrm{T}}$ 0.5', 'unfav. $\mathit{B}_{\mathrm{T}}$ 1.0', 'unfav. $\mathit{B}_{\mathrm{T}}$ 1.5', 'unfav. $\mathit{B}_{\mathrm{T}}$ 2.0'
            };

            % 调试信息：显示分组统计
            fprintf('\n=== Group Assignment Debug Info ===\n');
            fprintf('Total groups: %d\n', num_groups);
            fprintf('Total valid cases loaded: %d\n', length(all_full_paths));

            % 显示groupDirs的结构
            fprintf('\nGroupDirs structure:\n');
            for i_group = 1:min(num_groups, 8)
                if i_group <= length(groupDirs)
                    fprintf('GroupDirs{%d}: %d directories\n', i_group, length(groupDirs{i_group}));
                end
            end

            % 显示分组分配结果
            fprintf('\nGroup assignment results:\n');
            for i_group = 1:num_groups
                group_mask = (group_assignments == i_group);
                group_count = sum(group_mask);

                % 确定组的描述
                if i_group <= 4
                    n_conc = [0.5, 1.0, 1.5, 2.0];
                    group_desc = sprintf('fav BT, N %.1f', n_conc(i_group));
                elseif i_group <= 8
                    n_conc = [0.5, 1.0, 1.5, 2.0];
                    group_desc = sprintf('unfav BT, N %.1f', n_conc(i_group-4));
                else
                    group_desc = sprintf('Group %d', i_group);
                end

                fprintf('Group %d (%s): %d cases\n', i_group, group_desc, group_count);

                if group_count > 0
                    % 显示该组的一些案例路径（用于调试）
                    group_paths = all_full_paths(group_mask);
                    fprintf('  Sample path: %s\n', group_paths{1});

                    % 显示该组的数据范围
                    group_zeff = all_zeff_minus_1_values(group_mask);
                    fprintf('  Zeff-1 range: %.3f - %.3f\n', min(group_zeff), max(group_zeff));
                end
            end
            fprintf('=====================================\n');

            % 预分配图例数组
            max_groups = min(8, num_groups);
            legend_handles = zeros(max_groups + 1, 1); % +1 for identity line
            legend_labels = cell(max_groups + 1, 1);
            legend_count = 0;

            % 绘制前8个组
            for i_group = 1:max_groups
                group_mask = (group_assignments == i_group);
                if sum(group_mask) == 0
                    fprintf('Warning: Group %d has no data, skipping...\n', i_group);
                    continue;
                end

                % 提取当前组的数据
                group_x = all_zeff_minus_1_values(group_mask);
                group_y = fitted_values(group_mask);

                if isempty(group_x)
                    continue;
                end

                % 确定颜色和标记
                if i_group <= 4
                    current_color = fav_color;
                    marker_idx = i_group;
                else
                    current_color = unfav_color;
                    marker_idx = i_group - 4;
                end

                % 绘制散点图
                h = scatter(group_x, group_y, markerSize, current_color, ne_markers{marker_idx}, ...
                           'filled', 'MarkerEdgeColor', 'black', 'LineWidth', 1.0);

                % 添加到图例
                legend_count = legend_count + 1;
                legend_handles(legend_count) = h;
                legend_labels{legend_count} = hardcoded_legends{i_group};
            end

        else
            % 原有的绘图方式
            colors = [0, 0, 1; 1, 0, 0]; % 蓝色和红色

            % 预分配图例数组
            legend_handles = zeros(num_groups + 1, 1); % +1 for identity line
            legend_labels = cell(num_groups + 1, 1);
            legend_count = 0;

            % 按组绘制数据点
            for i_group = 1:num_groups
                group_mask = (group_assignments == i_group);
                if sum(group_mask) == 0
                    continue;
                end

                % 提取当前组的数据
                group_x = all_zeff_minus_1_values(group_mask);
                group_y = fitted_values(group_mask);

                if isempty(group_x)
                    continue;
                end

                % 确定颜色
                color_idx = mod(i_group - 1, size(colors, 1)) + 1;
                current_color = colors(color_idx, :);

                % 绘制散点图
                h = scatter(group_x, group_y, markerSize, current_color, 'o', ...
                           'filled', 'MarkerEdgeColor', 'black', 'LineWidth', 1.0);

                % 添加到图例
                legend_count = legend_count + 1;
                legend_handles(legend_count) = h;

                % 确定图例标签
                if usePresetLegends
                    preset_legend_names = {'fav. $\mathit{B}_{\mathrm{T}}$', 'unfav. $\mathit{B}_{\mathrm{T}}$', 'w/o drift'};
                    if i_group <= length(preset_legend_names)
                        legend_labels{legend_count} = preset_legend_names{i_group};
                    else
                        legend_labels{legend_count} = sprintf('Group %d', i_group);
                    end
                else
                    if showLegendsForDirNames && ~isempty(groupDirs{i_group})
                        first_dir = groupDirs{i_group}{1};
                        [~, short_name, ~] = fileparts(first_dir);
                        legend_labels{legend_count} = short_name;
                    else
                        legend_labels{legend_count} = sprintf('Group %d', i_group);
                    end
                end
            end
        end

        % 绘制理想拟合线 y=x
        identity_line = linspace(0, 1.6, 100);
        h_line = plot(identity_line, identity_line, 'k--', 'LineWidth', 2.5);

        % 添加理想拟合线到图例
        legend_count = legend_count + 1;
        legend_handles(legend_count) = h_line;
        legend_labels{legend_count} = 'Ideal Fit ($y=x$)';

        % 截断实际使用的图例数组
        legend_handles = legend_handles(1:legend_count);
        legend_labels = legend_labels(1:legend_count);

        % 设置坐标轴和标签
        xlabel('$Z_{eff} - 1$ (N impurity)', 'FontSize', axisLabelFontSize, 'Interpreter', 'latex');
        ylabel('$Z_{eff, scaled} - 1$ (N impurity)', 'FontSize', axisLabelFontSize, 'Interpreter', 'latex');

        % 设置坐标轴范围和网格
        xlim([0, 1.6]);
        ylim([0, 1.6]);
        grid on;
        set(gca, 'GridLineStyle', '--', 'GridAlpha', 0.6);
        set(gca, 'FontSize', axisTickFontSize, 'TickDir', 'in');

        % 添加图例
        if showLegendsForDirNames && ~isempty(legend_handles)
            legend(legend_handles, legend_labels, 'FontSize', legendFontSize, 'Location', 'best', ...
                   'Interpreter', 'latex', 'FontName', 'Times New Roman');

            % 调整图例标记大小
            try
                legendmarkeradjust(15);
            catch
                % 忽略错误
            end
        end

        % 调整布局
        box on;
        axis square;

        % 启用数据光标模式，显示算例路径
        dcm_obj = datacursormode(gcf);
        set(dcm_obj, 'Enable', 'on');

        % 使用更简单的方式设置数据光标，避免兼容性问题
        try
            % 尝试使用自定义更新函数
            set(dcm_obj, 'UpdateFcn', {@dataCursorUpdateFcn_simple, ...
                all_zeff_minus_1_values, fitted_values, all_full_paths});
        catch
            % 如果失败，使用默认的数据光标
            fprintf('Warning: Custom data cursor function failed, using default cursor.\n');
        end

        % 添加使用说明
        fprintf('\n=== Data Cursor Usage Instructions ===\n');
        fprintf('Click on data points in the plot to view corresponding case path information\n');
        fprintf('Data cursor mode is automatically enabled. You can:\n');
        fprintf('1. Directly click on data points to view detailed information\n');
        fprintf('2. Use the data cursor tool in the toolbar for more precise selection\n');
        fprintf('=======================================\n');

        % 保存图形
        current_time = datetime('now');
        time_str = char(current_time, 'yyyyMMdd_HHmmss');
        filename = sprintf('N_Zeff_scaling_law_fitting_%s.fig', time_str);
        saveas(gcf, filename);
        fprintf('Figure saved as: %s\n', filename);
        
    else
        fprintf('Skipping plot generation due to fitting failure.\n');
    end
    
    fprintf('\n=== N impurity Zeff scaling law fitting analysis completed ===\n');
end

function legendmarkeradjust(varargin)
% 图例标记大小调整函数 - 针对MATLAB 2019a优化版本
% 用法: legendmarkeradjust(markersize) 或 legendmarkeradjust(markersize, linewidth)

% 获取当前图例信息
leg = get(legend);
legfontsize = leg.FontSize;
legstrings = leg.String;
legloc = leg.Location;

% 删除原图例并重新创建
delete(legend)
[l1, l2, ~, ~] = legend(legstrings, 'FontName', 'Times New Roman', 'Interpreter', 'latex');

% 调整标记大小
for n = 1:length(l2)
    if sum(strcmp(properties(l2(n)), 'MarkerSize'))
        l2(n).MarkerSize = varargin{1};
    elseif sum(strcmp(properties(l2(n).Children), 'MarkerSize'))
        l2(n).Children.MarkerSize = varargin{1};
    end
end

% 保持原字体大小和设置字体为Times New Roman
for n = 1:length(l2)
    if sum(strcmp(properties(l2(n)), 'FontSize'))
        l2(n).FontSize = legfontsize;
    elseif sum(strcmp(properties(l2(n).Children), 'FontSize'))
        l2(n).Children.FontSize = legfontsize;
    end

    % 设置字体为Times New Roman
    if sum(strcmp(properties(l2(n)), 'FontName'))
        l2(n).FontName = 'Times New Roman';
    elseif sum(strcmp(properties(l2(n).Children), 'FontName'))
        l2(n).Children.FontName = 'Times New Roman';
    end
end

% 如果提供了第二个参数，调整线宽
if length(varargin) >= 2
    for n = 1:length(l2)
        if sum(strcmp(properties(l2(n)), 'LineWidth'))
            l2(n).LineWidth = varargin{2};
        elseif sum(strcmp(properties(l2(n).Children), 'LineWidth'))
            l2(n).Children.LineWidth = varargin{2};
        end
    end
end

% 恢复原图例位置和字体设置
set(l1, 'location', legloc, 'FontName', 'Times New Roman', 'Interpreter', 'latex')
end

function txt = dataCursorUpdateFcn_simple(~, event_obj, x_data, y_data, path_data)
% 简化的数据光标更新函数，用于显示算例路径信息
% 输入参数：
%   event_obj - 事件对象，包含选中点的位置信息
%   x_data - 所有数据点的X坐标（Zeff-1实际值）
%   y_data - 所有数据点的Y坐标（Zeff-1拟合值）
%   path_data - 所有数据点对应的算例路径

    try
        % 获取选中点的坐标
        pos = get(event_obj, 'Position');
        selected_x = pos(1);
        selected_y = pos(2);

        % 查找最接近的数据点
        distances = sqrt((x_data - selected_x).^2 + (y_data - selected_y).^2);
        [~, closest_idx] = min(distances);

        % 获取对应的路径信息
        if closest_idx <= length(path_data)
            full_path = path_data{closest_idx};

            % 简化路径显示，避免复杂的换行处理
            if length(full_path) > 60
                % 简单截断长路径
                display_path = [full_path(1:30), '...', full_path(end-25:end)];
            else
                display_path = full_path;
            end

            % 创建显示文本
            txt = {
                sprintf('Zeff-1 (actual): %.4f', selected_x);
                sprintf('Zeff-1 (fitted): %.4f', selected_y);
                sprintf('Residual: %.4f', selected_y - selected_x);
                '--- Case Path ---';
                display_path
            };
        else
            txt = {
                sprintf('Zeff-1 (actual): %.4f', selected_x);
                sprintf('Zeff-1 (fitted): %.4f', selected_y);
                sprintf('Residual: %.4f', selected_y - selected_x);
                'Path: Unknown'
            };
        end

    catch ME
        % 如果出错，返回基本信息
        txt = {
            sprintf('X: %.4f', event_obj.Position(1));
            sprintf('Y: %.4f', event_obj.Position(2));
            'Error in custom cursor function'
        };
    end
end

function wrapped_lines = wrapPathForDisplay(path_str, max_chars_per_line)
% 智能换行函数，处理过长的路径名
% 输入参数：
%   path_str - 原始路径字符串
%   max_chars_per_line - 每行最大字符数
% 输出：
%   wrapped_lines - 换行后的字符串元胞数组

    if length(path_str) <= max_chars_per_line
        wrapped_lines = {path_str};
        return;
    end

    % 预分配结果数组（估算最大可能的行数）
    max_possible_lines = ceil(length(path_str) / max_chars_per_line) + 5;
    wrapped_lines = cell(max_possible_lines, 1);
    line_count = 0;
    current_line = '';

    % 将路径按分隔符分割
    parts = split(path_str, filesep);

    for i = 1:length(parts)
        part = parts{i};

        % 如果当前部分加上分隔符后超过限制
        if ~isempty(current_line)
            test_line = [current_line, filesep, part];
        else
            test_line = part;
        end

        if length(test_line) <= max_chars_per_line
            current_line = test_line;
        else
            % 当前行已满，开始新行
            if ~isempty(current_line)
                line_count = line_count + 1;
                wrapped_lines{line_count} = current_line;
            end

            % 如果单个部分就超过限制，强制断行
            if length(part) > max_chars_per_line
                while length(part) > max_chars_per_line
                    line_count = line_count + 1;
                    wrapped_lines{line_count} = part(1:max_chars_per_line);
                    part = part(max_chars_per_line+1:end);
                end
                current_line = part;
            else
                current_line = part;
            end
        end
    end

    % 添加最后一行
    if ~isempty(current_line)
        line_count = line_count + 1;
        wrapped_lines{line_count} = current_line;
    end

    % 截取实际使用的部分
    wrapped_lines = wrapped_lines(1:line_count);

    % 如果没有成功换行，使用简单的字符截断方法
    if isempty(wrapped_lines)
        line_count = 0;
        for i = 1:max_chars_per_line:length(path_str)
            end_idx = min(i + max_chars_per_line - 1, length(path_str));
            line_count = line_count + 1;
            wrapped_lines{line_count} = path_str(i:end_idx);
        end
    end
end
