function plot_zeff_scaling_law_fitting_grouped(all_radiationData, groupDirs)
% PLOT_ZEFF_SCALING_LAW_FITTING_GROUPED 绘制Zeff标度律分组拟合分析图
%   拟合公式：Z_eff - 1 = C * (P_rad / n_e^gamma)
%   按照fav组和unfav组分别进行分组拟合，fav组是前四组，unfav组是后四组
%   绘制拟合值与实际值的对比散点图

    fprintf('\n=== Starting Zeff scaling law grouped fitting analysis ===\n');
    
    %%%% 全局字体和绘图属性设置
    fontSize = 42;
    markerSize = 120;

    % 设置全局字体为Times New Roman
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 16);
    set(0, 'DefaultTextFontSize', fontSize);
    set(0, 'DefaultLegendFontSize', 28);

    % 初始化存储数组
    all_full_paths = cell(length(all_radiationData), 1);
    all_prad_values = zeros(length(all_radiationData), 1);
    all_ne_values = zeros(length(all_radiationData), 1);
    all_zeff_minus_1_values = zeros(length(all_radiationData), 1);

    valid_cases = 0;

    % 定义芯部区域索引（适用于98*28网格）
    core_indices_original = 26:73;
    
    %% ======================== 数据处理循环 ============================

    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        dirName = radData.dirName;

        fprintf('Processing case for Zeff fitting analysis: %s\n', dirName);

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
        
        %% ============== 计算Zeff（电子密度加权平均）==============

        % 计算Zeff分布
        nD = radData.plasma.na(:,:,1:2);  % D离子密度
        nNe = radData.plasma.na(:,:,3:end); % Ne离子密度

        % 安全的电子密度（避免除零）
        safe_ne = max(radData.plasma.ne, 1e-10);

        % D+离子贡献 (Z^2 = 1)
        Zeff_D = nD(:,:,2) * (1^2) ./ safe_ne;

        % Ne离子各价态贡献
        Zeff_Ne = zeros(size(safe_ne));
        num_Ne_species = size(nNe, 3);

        % 计算Ne各价态对Zeff的贡献（从Ne1+开始）
        for i_Z = 2:min(num_Ne_species, 11)
            charge_state = i_Z - 1; % i_Z=2 -> charge_state=1 (Ne1+)
            if charge_state >= 1 && charge_state <= 10
                Zeff_Ne = Zeff_Ne + nNe(:,:,i_Z) * (charge_state^2) ./ safe_ne;
            end
        end

        Zeff_total = Zeff_D + Zeff_Ne;

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

        % 筛选有效数据
        if zeff_minus_1 > 0.10 && P_rad_total > 0 && ne_value > 0 && ...
           isfinite(zeff_minus_1) && isfinite(P_rad_total) && isfinite(ne_value)

            valid_cases = valid_cases + 1;
            all_full_paths{valid_cases} = dirName;
            all_prad_values(valid_cases) = P_rad_total;
            all_ne_values(valid_cases) = ne_value;
            all_zeff_minus_1_values(valid_cases) = zeff_minus_1;

            fprintf('  Valid case: Prad=%.3f MW, ne=%.3f (10^19 m^-3), Zeff-1=%.3f\n', ...
                    P_rad_total, ne_value, zeff_minus_1);
        end
    end

    % 截取有效数据
    all_full_paths = all_full_paths(1:valid_cases);
    all_prad_values = all_prad_values(1:valid_cases);
    all_ne_values = all_ne_values(1:valid_cases);
    all_zeff_minus_1_values = all_zeff_minus_1_values(1:valid_cases);

    fprintf('\nTotal valid cases for fitting: %d\n', valid_cases);

    if valid_cases < 2
        fprintf('Error: Not enough valid data points for fitting.\n');
        return;
    end

    %% ======================== 分组拟合 ============================
    
    % 确定分组信息
    num_groups = max(1, length(groupDirs));
    if num_groups == 1 && isempty(groupDirs)
        groupDirs = {all_full_paths};
    end

    % 为每个案例分配分组
    group_assignments = zeros(length(all_full_paths), 1);
    for i_data = 1:length(all_full_paths)
        for i_group = 1:num_groups
            if any(contains(all_full_paths{i_data}, groupDirs{i_group}))
                group_assignments(i_data) = i_group;
                break;
            end
        end
    end
    
    % 分为fav组和unfav组
    fav_group_mask = group_assignments <= 4;  % 前4组为fav组
    unfav_group_mask = group_assignments > 4 & group_assignments <= 8;  % 后4组为unfav组
    
    % 检查每组是否有足够的数据点
    fav_count = sum(fav_group_mask);
    unfav_count = sum(unfav_group_mask);
    
    fprintf('\n=== Group statistics ===\n');
    fprintf('Favorable B_T group: %d cases\n', fav_count);
    fprintf('Unfavorable B_T group: %d cases\n', unfav_count);
    
    % 定义拟合函数：Z_eff - 1 = C * (P_rad / n_e^gamma)
    zeff_formula = @(params, data) params(1) * (data(:,1) ./ (data(:,2).^params(2)));
    
    % 初始化拟合结果存储
    fit_results = struct();
    fit_results.fav = struct('success', false, 'params', [], 'r_squared', 0, 'fitted_values', []);
    fit_results.unfav = struct('success', false, 'params', [], 'r_squared', 0, 'fitted_values', []);
    
    % 执行fav组拟合
    if fav_count >= 2
        fprintf('\n=== Performing fitting for favorable B_T group ===\n');
        
        % 提取fav组数据
        fav_prad = all_prad_values(fav_group_mask);
        fav_ne = all_ne_values(fav_group_mask);
        fav_zeff_minus_1 = all_zeff_minus_1_values(fav_group_mask);
        fav_data_matrix = [fav_prad, fav_ne];
        
        % 数据安全性检查
        safe_prad = max(fav_prad, 1e-10);
        safe_ne = max(fav_ne, 1e-10);
        safe_zeff_minus_1 = max(fav_zeff_minus_1, 1e-10);
        
        try
            %% ============== 步骤1：对数化线性拟合获得初始解 ==============
            fprintf('Step 1: Linear fitting in log space for initial guess...\n');
            
            log_ne = log(safe_ne);
            log_ratio = log(safe_zeff_minus_1 ./ safe_prad);  % log((Z_eff-1)/P_rad)
            
            % 线性拟合：y = a + b*x，其中 y = log((Z_eff-1)/P_rad), x = log(n_e)
            % a = log(C), b = -gamma
            X_linear = [ones(length(log_ne), 1), log_ne];
            linear_coeffs = X_linear \ log_ratio;
            
            log_C_initial = linear_coeffs(1);
            gamma_initial = -linear_coeffs(2);  % 注意负号
            C_initial = exp(log_C_initial);
            
            % 确保初始参数在合理范围内
            C_initial = max(min(C_initial, 100), 1e-3);
            gamma_initial = max(min(gamma_initial, 5), 0.1);
            
            fprintf('Linear fit initial guess: C=%.4f, gamma=%.4f\n', C_initial, gamma_initial);
            
            % 计算线性拟合的R²
            log_ratio_fitted = log_C_initial - gamma_initial * log_ne;
            ss_res_linear = sum((log_ratio - log_ratio_fitted).^2);
            ss_tot_linear = sum((log_ratio - mean(log_ratio)).^2);
            r_squared_linear = 1 - ss_res_linear/ss_tot_linear;
            fprintf('Linear fit R² = %.4f\n', r_squared_linear);
            
            %% ============== 步骤2：使用初始解进行非线性拟合 ==============
            fprintf('Step 2: Nonlinear fitting with improved initial guess...\n');
            
            initial_guess = [C_initial, gamma_initial];
            options = optimset('Display', 'off', 'MaxIter', 20000, 'TolFun', 1e-12, 'TolX', 1e-12);
            
            [fitted_params, ~, residual] = lsqcurvefit(zeff_formula, initial_guess, ...
                                                       fav_data_matrix, fav_zeff_minus_1, ...
                                                       [1e-9, 0], [Inf, Inf], options);
            
            fprintf('Nonlinear fit results: C=%.4f, gamma=%.4f\n', fitted_params(1), fitted_params(2));
            
            % 计算拟合指标
            fitted_values = zeff_formula(fitted_params, fav_data_matrix);
            ss_res = sum(residual.^2);
            ss_tot = sum((fav_zeff_minus_1 - mean(fav_zeff_minus_1)).^2);
            r_squared = 1 - ss_res/ss_tot;
            
            fprintf('Nonlinear fit R² = %.4f\n', r_squared);
            
            % 存储拟合结果
            fit_results.fav.success = true;
            fit_results.fav.params = fitted_params;
            fit_results.fav.r_squared = r_squared;
            fit_results.fav.fitted_values = fitted_values;
            
        catch ME
            fprintf('Fitting for favorable B_T group failed: %s\n', ME.message);
        end
    else
        fprintf('Not enough data points for favorable B_T group fitting (minimum 2 required).\n');
    end
    
    % 执行unfav组拟合
    if unfav_count >= 2
        fprintf('\n=== Performing fitting for unfavorable B_T group ===\n');
        
        % 提取unfav组数据
        unfav_prad = all_prad_values(unfav_group_mask);
        unfav_ne = all_ne_values(unfav_group_mask);
        unfav_zeff_minus_1 = all_zeff_minus_1_values(unfav_group_mask);
        unfav_data_matrix = [unfav_prad, unfav_ne];
        
        % 数据安全性检查
        safe_prad = max(unfav_prad, 1e-10);
        safe_ne = max(unfav_ne, 1e-10);
        safe_zeff_minus_1 = max(unfav_zeff_minus_1, 1e-10);
        
        try
            %% ============== 步骤1：对数化线性拟合获得初始解 ==============
            fprintf('Step 1: Linear fitting in log space for initial guess...\n');
            
            log_ne = log(safe_ne);
            log_ratio = log(safe_zeff_minus_1 ./ safe_prad);  % log((Z_eff-1)/P_rad)
            
            % 线性拟合：y = a + b*x，其中 y = log((Z_eff-1)/P_rad), x = log(n_e)
            % a = log(C), b = -gamma
            X_linear = [ones(length(log_ne), 1), log_ne];
            linear_coeffs = X_linear \ log_ratio;
            
            log_C_initial = linear_coeffs(1);
            gamma_initial = -linear_coeffs(2);  % 注意负号
            C_initial = exp(log_C_initial);
            
            % 确保初始参数在合理范围内
            C_initial = max(min(C_initial, 100), 1e-3);
            gamma_initial = max(min(gamma_initial, 5), 0.1);
            
            fprintf('Linear fit initial guess: C=%.4f, gamma=%.4f\n', C_initial, gamma_initial);
            
            % 计算线性拟合的R²
            log_ratio_fitted = log_C_initial - gamma_initial * log_ne;
            ss_res_linear = sum((log_ratio - log_ratio_fitted).^2);
            ss_tot_linear = sum((log_ratio - mean(log_ratio)).^2);
            r_squared_linear = 1 - ss_res_linear/ss_tot_linear;
            fprintf('Linear fit R² = %.4f\n', r_squared_linear);
            
            %% ============== 步骤2：使用初始解进行非线性拟合 ==============
            fprintf('Step 2: Nonlinear fitting with improved initial guess...\n');
            
            initial_guess = [C_initial, gamma_initial];
            options = optimset('Display', 'off', 'MaxIter', 20000, 'TolFun', 1e-12, 'TolX', 1e-12);
            
            [fitted_params, ~, residual] = lsqcurvefit(zeff_formula, initial_guess, ...
                                                       unfav_data_matrix, unfav_zeff_minus_1, ...
                                                       [1e-9, 0], [Inf, Inf], options);
            
            fprintf('Nonlinear fit results: C=%.4f, gamma=%.4f\n', fitted_params(1), fitted_params(2));
            
            % 计算拟合指标
            fitted_values = zeff_formula(fitted_params, unfav_data_matrix);
            ss_res = sum(residual.^2);
            ss_tot = sum((unfav_zeff_minus_1 - mean(unfav_zeff_minus_1)).^2);
            r_squared = 1 - ss_res/ss_tot;
            
            fprintf('Nonlinear fit R² = %.4f\n', r_squared);
            
            % 存储拟合结果
            fit_results.unfav.success = true;
            fit_results.unfav.params = fitted_params;
            fit_results.unfav.r_squared = r_squared;
            fit_results.unfav.fitted_values = fitted_values;
            
        catch ME
            fprintf('Fitting for unfavorable B_T group failed: %s\n', ME.message);
        end
    else
        fprintf('Not enough data points for unfavorable B_T group fitting (minimum 2 required).\n');
    end
    
    %% ======================== 绘图 ============================
    
    if fit_results.fav.success || fit_results.unfav.success
        fprintf('\n=== Creating grouped fitting analysis plot ===\n');

        % 在控制台中显示拟合结果
        fprintf('\n=== Fitting Results Summary ===\n');
        if fit_results.fav.success
            fprintf('Favorable B_T group fitting:\n');
            fprintf('  Formula: Z_eff - 1 = %.4f * (P_rad / n_e^%.4f)\n', ...
                fit_results.fav.params(1), fit_results.fav.params(2));
            fprintf('  R² = %.4f\n', fit_results.fav.r_squared);
        end

        if fit_results.unfav.success
            fprintf('Unfavorable B_T group fitting:\n');
            fprintf('  Formula: Z_eff - 1 = %.4f * (P_rad / n_e^%.4f)\n', ...
                fit_results.unfav.params(1), fit_results.unfav.params(2));
            fprintf('  R² = %.4f\n', fit_results.unfav.r_squared);
        end
        
        figure('Position', [100, 100, 1000, 800]);
        hold on;
        
        % 硬编码绘图方式：前四个为fav. BT，后四个为unfav. BT
        fav_color = [0, 0, 1];    % 蓝色
        unfav_color = [1, 0, 0];  % 红色
        ne_markers = {'o', 's', 'd', '^'}; % 对应0.5, 1.0, 1.5, 2.0
        
        % 硬编码图例标签
        hardcoded_legends = {
            'fav. $B_T$ 0.5', 'fav. $B_T$ 1.0', 'fav. $B_T$ 1.5', 'fav. $B_T$ 2.0', ...
            'unfav. $B_T$ 0.5', 'unfav. $B_T$ 1.0', 'unfav. $B_T$ 1.5', 'unfav. $B_T$ 2.0'
        };
        
        % 预分配图例数组
        max_groups = min(8, num_groups);
        legend_handles = zeros(max_groups + 2, 1); % +2 for identity line and fit formula
        legend_labels = cell(max_groups + 2, 1);
        legend_count = 0;
        
        % 绘制前8个组
        for i_group = 1:max_groups
            group_mask = (group_assignments == i_group);
            if sum(group_mask) == 0
                continue;
            end
            
            % 提取当前组的数据
            group_x = all_zeff_minus_1_values(group_mask);
            
            % 根据组别选择拟合值
            if i_group <= 4 && fit_results.fav.success
                % fav组
                group_indices = find(group_mask);
                group_indices_in_fav = find(ismember(find(fav_group_mask), group_indices));
                group_y = fit_results.fav.fitted_values(group_indices_in_fav);
            elseif i_group > 4 && i_group <= 8 && fit_results.unfav.success
                % unfav组
                group_indices = find(group_mask);
                group_indices_in_unfav = find(ismember(find(unfav_group_mask), group_indices));
                group_y = fit_results.unfav.fitted_values(group_indices_in_unfav);
            else
                continue;
            end
            
            if isempty(group_x) || isempty(group_y)
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
        
        % 绘制理想拟合线 y=x
        identity_line = linspace(0, 1.6, 100);
        h_line = plot(identity_line, identity_line, 'k--', 'LineWidth', 2.5);
        
        % 添加理想拟合线到图例
        legend_count = legend_count + 1;
        legend_handles(legend_count) = h_line;
        legend_labels{legend_count} = 'Ideal Fit ($y=x$)';
        
        % 添加拟合公式到图例（暂时屏蔽）
        % if fit_results.fav.success
        %     legend_count = legend_count + 1;
        %     % 使用线条而不是不可见点，这样在图例中能正确显示
        %     legend_handles(legend_count) = plot(NaN, NaN, 'Color', fav_color, 'LineStyle', '-', 'LineWidth', 2.0);
        %     legend_labels{legend_count} = sprintf('fav. $B_T$: $Z_{eff}-1 = %.3f \\cdot \\frac{P_{rad}}{n_e^{%.3f}}$, $R^2=%.3f$', ...
        %         fit_results.fav.params(1), fit_results.fav.params(2), fit_results.fav.r_squared);
        % end
        %
        % if fit_results.unfav.success
        %     legend_count = legend_count + 1;
        %     % 使用线条而不是不可见点，这样在图例中能正确显示
        %     legend_handles(legend_count) = plot(NaN, NaN, 'Color', unfav_color, 'LineStyle', '-', 'LineWidth', 2.0);
        %     legend_labels{legend_count} = sprintf('unfav. $B_T$: $Z_{eff}-1 = %.3f \\cdot \\frac{P_{rad}}{n_e^{%.3f}}$, $R^2=%.3f$', ...
        %         fit_results.unfav.params(1), fit_results.unfav.params(2), fit_results.unfav.r_squared);
        % end
        
        % 截断实际使用的图例数组
        legend_handles = legend_handles(1:legend_count);
        legend_labels = legend_labels(1:legend_count);
        
        % 设置坐标轴和标签
        xlabel('$Z_{eff} - 1$', 'FontSize', fontSize, 'Interpreter', 'latex');
        ylabel('$Z_{eff, scaled} - 1$', 'FontSize', fontSize, 'Interpreter', 'latex');
        
        % 设置坐标轴范围和网格
        xlim([0, 1.6]);
        ylim([0, 1.6]);
        grid on;
        set(gca, 'GridLineStyle', '--', 'GridAlpha', 0.6);
        set(gca, 'FontSize', 16, 'TickDir', 'in');
        
        % 添加图例
        legend(legend_handles, legend_labels, 'FontSize', 28, 'Location', 'best', ...
               'Interpreter', 'latex', 'FontName', 'Times New Roman');
        
        % 调整图例标记大小
        try
            legendmarkeradjust(15, 'vertical');
        catch
            % 忽略错误
        end
        
        % 调整布局
        box on;
        axis square;
        
        % 保存图形
        current_time = datetime('now');
        time_str = char(current_time, 'yyyyMMdd_HHmmss');
        filename = sprintf('Zeff_scaling_law_grouped_fitting_%s.fig', time_str);
        saveas(gcf, filename);
        fprintf('Figure saved as: %s\n', filename);
        
    else
        fprintf('Skipping plot generation due to fitting failure.\n');
    end
    
    fprintf('\n=== Zeff scaling law grouped fitting analysis completed ===\n');
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
