function plot_zeff_scaling_law_fitting_old(all_radiationData, groupDirs, usePresetLegends, showLegendsForDirNames, useHardcodedLegends)
% PLOT_ZEFF_SCALING_LAW_FITTING 绘制Zeff标度律拟合分析图
%
%   此函数实现Zeff标度律拟合分析，参考Python代码的实现：
%   拟合公式：Z_eff - 1 = C * (P_rad / n_e^gamma)
%   绘制拟合值与实际值的对比散点图
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组
%     groupDirs         - 包含分组目录信息的元胞数组
%     usePresetLegends  - 是否使用预设图例名称
%     showLegendsForDirNames - 当使用目录名时是否显示图例
%     useHardcodedLegends - 是否使用硬编码图例（fav./unfav. B_T + Ne充杂水平）
%
%   拟合公式定义：
%     Z_eff - 1 = C * (P_rad / n_e^gamma)
%     其中：
%     - P_rad: 总辐射功率 (MW)
%     - n_e: 电子密度 (10^19 m^-3)
%     - C, gamma: 拟合参数
%
%   依赖函数:
%     - saveFigureWithTimestamp (内部函数)
%
%   更新说明:
%     - 基于Python代码的MATLAB实现
%     - 支持MATLAB 2019a
%     - 使用非线性最小二乘拟合

    fprintf('\n=== Starting Zeff scaling law fitting analysis ===\n');

    if useHardcodedLegends
        fprintf('Using hardcoded legends with Ne concentration levels\n');
        fprintf('Expected path patterns: fav/unfav + Ne0.5/Ne1.0/Ne1.5/Ne2.0 or similar\n');
    elseif usePresetLegends
        fprintf('Using preset legends (fav. B_T / unfav. B_T)\n');
    else
        fprintf('Using directory names as legends\n');
    end
    
    % 检查输入参数
    if nargin < 5
        useHardcodedLegends = false;
    end
    if nargin < 4
        showLegendsForDirNames = true;
    end
    if nargin < 3
        usePresetLegends = false;
    end
    
    %%%% 全局字体和绘图属性设置
    fontSize = 42;
    linewidth = 3;
    markerSize = 120;

    % 设置全局字体为Times New Roman（学术规范）
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 16);
    set(0, 'DefaultTextFontSize', fontSize);
    set(0, 'DefaultLegendFontSize', 28);
    
    % 初始化存储数组
    all_dir_names = {};
    all_full_paths = {};
    all_prad_values = [];
    all_ne_values = [];
    all_zeff_minus_1_values = [];
    
    valid_cases = 0;
    
    % 定义芯部区域索引（与主脚本保持一致）
    core_indices_original = 26:73;   % 适用于98*28网格
    
    %% ======================== 数据处理循环 ============================
    
    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry = radData.gmtry;
        plasma = radData.plasma;
        dirName = radData.dirName;
        
        current_full_path = dirName;
        fprintf('Processing case for Zeff fitting analysis: %s\n', dirName);
        
        % 检查数据完整性
        can_process = true;
        if ~isfield(plasma, 'ne') || ~isfield(plasma, 'na') || ~isfield(gmtry, 'vol')
            fprintf('Warning: Missing required data fields for case %s. Skipping.\n', dirName);
            can_process = false;
        end
        
        if ~can_process
            continue;
        end
        
        %% ============== 计算CEI极向平均电子密度 ==============
        
        % 计算芯部区域体积（使用原始网格索引）
        core_vol = gmtry.vol(core_indices_original, 2); % 第二列对应芯部位置
        total_vol_core_poloidal = sum(core_vol, 'omitnan');
        
        if total_vol_core_poloidal == 0 || isnan(total_vol_core_poloidal)
            fprintf('Warning: Core volume sum is zero or NaN for case %s. Skipping.\n', dirName);
            continue;
        end
        
        % 计算芯部体积加权平均电子密度（CEI极向平均值）
        ne_core = plasma.ne(core_indices_original, 2); % 使用原始网格索引
        core_avg_ne = sum(ne_core .* core_vol, 'omitnan') / total_vol_core_poloidal;
        
        % 转换为10^19 m^-3单位
        ne_value = core_avg_ne / 1e19;
        
        %% ============== 计算Zeff（电子密度加权平均）==============
        
        % 计算Zeff分布
        nD = plasma.na(:,:,1:2);  % D离子密度
        nNe = plasma.na(:,:,3:end); % Ne离子密度
        
        % 安全的电子密度（避免除零）
        safe_ne = max(plasma.ne, 1e-10);
        
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
        
        % 总Zeff
        Zeff_total = Zeff_D + Zeff_Ne;
        
        % 提取芯部边缘数据并计算电子密度加权平均
        core_edge_zeff = Zeff_total(core_indices_original, 2);
        core_edge_ne = safe_ne(core_indices_original, 2);
        core_edge_vol = gmtry.vol(core_indices_original, 2);
        
        % 计算电子密度加权平均Zeff
        valid_indices = ~isnan(core_edge_zeff) & core_edge_vol > 0 & core_edge_ne > 0;
        
        if sum(valid_indices) > 0
            ne_vol_sum = sum(core_edge_ne(valid_indices) .* core_edge_vol(valid_indices));
            zeff_ne_vol_sum = sum(core_edge_zeff(valid_indices) .* core_edge_ne(valid_indices) .* core_edge_vol(valid_indices));
            average_Zeff = zeff_ne_vol_sum / ne_vol_sum;
        else
            fprintf('Warning: No valid Zeff data for case %s. Skipping.\n', dirName);
            continue;
        end
        
        %% ============== 获取总辐射功率 ==============
        
        P_rad_total = radData.totrad; % 总辐射功率 (MW)
        
        if isnan(P_rad_total) || P_rad_total <= 0
            fprintf('Warning: Invalid radiation power for case %s. Skipping.\n', dirName);
            continue;
        end
        
        %% ============== 数据筛选 ==============
        
        zeff_minus_1 = average_Zeff - 1;
        
        % 简化筛选条件（参考Python代码）
        if zeff_minus_1 > 0.10 && P_rad_total > 0 && ne_value > 0 && ...
           isfinite(zeff_minus_1) && isfinite(P_rad_total) && isfinite(ne_value)
            
            % 存储有效数据
            valid_cases = valid_cases + 1;
            all_dir_names{end+1} = dirName;
            all_full_paths{end+1} = current_full_path;
            all_prad_values(end+1) = P_rad_total;
            all_ne_values(end+1) = ne_value;
            all_zeff_minus_1_values(end+1) = zeff_minus_1;
            
            fprintf('  Valid case: Prad=%.3f MW, ne=%.3f (10^19 m^-3), Zeff-1=%.3f\n', ...
                    P_rad_total, ne_value, zeff_minus_1);
        else
            fprintf('  Filtered out: Prad=%.3f MW, ne=%.3f (10^19 m^-3), Zeff-1=%.3f\n', ...
                    P_rad_total, ne_value, zeff_minus_1);
        end
    end
    
    fprintf('\nTotal valid cases for fitting: %d\n', valid_cases);
    
    if valid_cases < 2
        fprintf('Error: Not enough valid data points for fitting (need at least 2).\n');
        return;
    end
    
    %% ======================== 全局拟合 ============================
    
    fprintf('\n=== Performing global fitting ===\n');
    
    % 转换为数组
    prad_array = all_prad_values(:);
    ne_array = all_ne_values(:);
    zeff_minus_1_array = all_zeff_minus_1_values(:);
    
    % 定义拟合函数：Z_eff - 1 = C * (P_rad / n_e^gamma)
    zeff_formula = @(params, data) params(1) * (data(:,1) ./ (data(:,2).^params(2)));
    
    % 初始猜测
    initial_guess = [1.0, 1.0];
    
    % 准备数据矩阵
    data_matrix = [prad_array, ne_array];
    
    % 非线性最小二乘拟合 - MATLAB 2019a兼容
    try
        options = optimoptions('lsqcurvefit', 'Display', 'off', 'MaxIterations', 20000);
    catch
        % 如果optimoptions不可用，使用optimset（旧版本兼容）
        options = optimset('Display', 'off', 'MaxIter', 20000);
    end
    
    try
        % 设置参数边界：C > 0, gamma > 0
        lb = [1e-9, 0];
        ub = [Inf, Inf];
        
        [fitted_params, ~, residual, ~, ~, ~, ~] = lsqcurvefit(zeff_formula, initial_guess, data_matrix, zeff_minus_1_array, lb, ub, options);
        
        C_global = fitted_params(1);
        gamma_global = fitted_params(2);
        
        fprintf('Fitting results: C=%.4f, gamma=%.4f\n', C_global, gamma_global);
        
        % 计算拟合指标
        fitted_values = zeff_formula(fitted_params, data_matrix);
        
        % R²计算
        ss_res = sum(residual.^2);
        ss_tot = sum((zeff_minus_1_array - mean(zeff_minus_1_array)).^2);
        r_squared = 1 - ss_res/ss_tot;
        
        % MSE和MAE
        mse = mean(residual.^2);
        mae = mean(abs(residual));
        
        fprintf('R² = %.4f, MSE = %.4e, MAE = %.4e\n', r_squared, mse, mae);
        
        fit_successful = true;
        
    catch ME
        fprintf('Fitting failed: %s\n', ME.message);
        fit_successful = false;
        fitted_values = nan(size(zeff_minus_1_array));
    end
    
    %% ======================== 绘图 ============================

    if fit_successful
        fprintf('\n=== Creating fitting analysis plot ===\n');

        % 创建图形
        figure('Position', [100, 100, 1000, 800]);

        % 确定分组信息（参考plot_frad_imp_vs_zeff_relationship.m的实现）
        num_groups = length(groupDirs);
        if num_groups == 0
            fprintf('Warning: No group information provided. Using single group.\n');
            num_groups = 1;
            groupDirs = {all_full_paths}; % 将所有案例放入一个组
        end

        % 为每个案例分配分组
        num_cases = length(all_full_paths);
        group_assignments = zeros(num_cases, 1);

        for i_data = 1:num_cases
            current_full_path = all_full_paths{i_data};

            % 查找当前案例属于哪个组
            group_index = -1;
            for i_group = 1:num_groups
                current_group_dirs = groupDirs{i_group};
                for j = 1:length(current_group_dirs)
                    if contains(current_full_path, current_group_dirs{j})
                        group_index = i_group;
                        break;
                    end
                end
                if group_index > 0
                    break;
                end
            end

            % 分配分组
            if group_index > 0
                group_assignments(i_data) = group_index;
            else
                group_assignments(i_data) = 0; % 未分组
            end
        end

        hold on;
        legend_handles = [];
        legend_labels = {};

        if useHardcodedLegends
            % 硬编码绘图方式：前四个为fav. BT，后四个为unfav. BT
            % fav组使用蓝色，unfav组使用红色
            % 不同形状区分0.5到2.0的充杂水平

            fav_color = [0, 0, 1];    % 蓝色
            unfav_color = [1, 0, 0];  % 红色

            % 定义不同的标记形状对应不同的Ne充杂水平
            ne_markers = {'o', 's', 'd', '^'}; % 圆形、方形、菱形、三角形对应0.5, 1.0, 1.5, 2.0

            % 硬编码图例标签（使用LaTeX格式确保Times New Roman字体）
            hardcoded_legends = {
                'fav. $B_T$ 0.5', 'fav. $B_T$ 1.0', 'fav. $B_T$ 1.5', 'fav. $B_T$ 2.0', ...
                'unfav. $B_T$ 0.5', 'unfav. $B_T$ 1.0', 'unfav. $B_T$ 1.5', 'unfav. $B_T$ 2.0'
            };

            % 绘制前8个组（假设前4个为fav，后4个为unfav）
            for i_group = 1:min(8, num_groups)
                group_mask = (group_assignments == i_group);

                if sum(group_mask) == 0
                    continue; % 跳过空组
                end

                % 提取当前组的数据
                group_x = zeff_minus_1_array(group_mask);
                group_y = fitted_values(group_mask);

                % 移除NaN值
                valid_mask = ~isnan(group_x) & ~isnan(group_y);
                group_x = group_x(valid_mask);
                group_y = group_y(valid_mask);

                if length(group_x) == 0
                    continue; % 跳过没有有效数据的组
                end

                % 确定颜色和标记
                if i_group <= 4
                    % 前四个为fav. BT
                    current_color = fav_color;
                    marker_idx = i_group;
                else
                    % 后四个为unfav. BT
                    current_color = unfav_color;
                    marker_idx = i_group - 4;
                end

                current_marker = ne_markers{marker_idx};

                % 绘制散点图
                h = scatter(group_x, group_y, markerSize, current_color, current_marker, ...
                           'filled', 'MarkerEdgeColor', 'black', 'LineWidth', 1.0);

                % MATLAB 2019a兼容：尝试设置透明度
                try
                    set(h, 'MarkerFaceAlpha', 0.7);
                catch
                    % 如果不支持透明度，则使用默认设置
                end

                % 添加到图例
                legend_handles(end+1) = h;
                legend_labels{end+1} = hardcoded_legends{i_group};
            end

        else
            % 原有的绘图方式
            % 设置颜色和标记
            colors = [0, 0, 1; 1, 0, 0]; % 蓝色和红色，对应fav. BT和unfav. BT
            markers = {'o', 'o'}; % 都使用圆形标记

            % 按组绘制数据点
            for i_group = 1:num_groups
                group_mask = (group_assignments == i_group);

                if sum(group_mask) == 0
                    continue; % 跳过空组
                end

                % 提取当前组的数据
                group_x = zeff_minus_1_array(group_mask);
                group_y = fitted_values(group_mask);

                % 移除NaN值
                valid_mask = ~isnan(group_x) & ~isnan(group_y);
                group_x = group_x(valid_mask);
                group_y = group_y(valid_mask);

                if isempty(group_x)
                    continue; % 跳过没有有效数据的组
                end

                % 确定颜色和标记
                color_idx = mod(i_group - 1, size(colors, 1)) + 1;
                marker_idx = mod(i_group - 1, length(markers)) + 1;
                current_color = colors(color_idx, :);
                current_marker = markers{marker_idx};

                % 绘制散点图
                h = scatter(group_x, group_y, markerSize, current_color, current_marker, ...
                           'filled', 'MarkerEdgeColor', 'black', 'LineWidth', 1.0);

                % MATLAB 2019a兼容：尝试设置透明度
                try
                    set(h, 'MarkerFaceAlpha', 0.7);
                catch
                    % 如果不支持透明度，则使用默认设置
                end

                % 添加到图例
                legend_handles(end+1) = h;

                % 确定图例标签
                if usePresetLegends
                    preset_legend_names = {'fav. $B_T$', 'unfav. $B_T$', 'w/o drift'};
                    if i_group <= length(preset_legend_names)
                        legend_labels{end+1} = preset_legend_names{i_group};
                    else
                        legend_labels{end+1} = sprintf('Group %d', i_group);
                    end
                else
                    if showLegendsForDirNames && ~isempty(groupDirs{i_group})
                        % 使用第一个目录名作为图例
                        first_dir = groupDirs{i_group}{1};
                        [~, short_name, ~] = fileparts(first_dir);
                        legend_labels{end+1} = short_name;
                    else
                        legend_labels{end+1} = sprintf('Group %d', i_group);
                    end
                end
            end
        end

        % 绘制理想拟合线 y=x
        xlim_vals = xlim;
        ylim_vals = ylim;
        common_min = max(xlim_vals(1), ylim_vals(1));
        common_max = min(xlim_vals(2), ylim_vals(2));

        if common_min < common_max
            identity_line = linspace(common_min, common_max, 100);
            h_line = plot(identity_line, identity_line, 'k--', 'LineWidth', 2.5);
            legend_handles(end+1) = h_line;
            legend_labels{end+1} = 'Ideal Fit (y=x)';
        end

        % 设置坐标轴和标签（使用Times New Roman字体）
        xlabel('$Z_{eff} - 1$', 'FontSize', fontSize, 'Interpreter', 'latex', 'FontName', 'Times New Roman');
        ylabel('$Z_{eff, scaled} - 1$', 'FontSize', fontSize, 'Interpreter', 'latex', 'FontName', 'Times New Roman');

        % 设置坐标轴范围
        xlim([0, 1.6]);
        ylim([0, 1.6]);

        % 添加网格
        grid on;
        set(gca, 'GridLineStyle', '--', 'GridAlpha', 0.6);

        % 设置刻度标签字体大小和字体（Times New Roman）
        set(gca, 'FontSize', 16, 'FontName', 'Times New Roman');
        set(gca, 'TickDir', 'in');

        % 添加图例（使用Times New Roman字体和LaTeX解释器）
        if showLegendsForDirNames && ~isempty(legend_handles)
            hLegend = legend(legend_handles, legend_labels, 'FontSize', 28, 'Location', 'best', ...
                           'FontName', 'Times New Roman', 'Interpreter', 'latex');
            % MATLAB 2019a兼容：使用set方法设置透明度、字体和标记大小
            try
                set(hLegend, 'Color', [1 1 1 0.9]); % 白色背景，90%不透明度
                set(hLegend, 'FontName', 'Times New Roman'); % 确保图例字体为Times New Roman
                set(hLegend, 'Interpreter', 'latex'); % 确保使用LaTeX解释器

                % 增大图例中的标记尺寸 - MATLAB 2019a兼容方法
                legend_children = get(hLegend, 'Children');
                for i = 1:length(legend_children)
                    if strcmp(get(legend_children(i), 'Type'), 'line') && ...
                       ~isempty(get(legend_children(i), 'Marker')) && ...
                       ~strcmp(get(legend_children(i), 'Marker'), 'none')
                        set(legend_children(i), 'MarkerSize', 15);
                    end
                end
            catch
                % 如果不支持透明度，则使用默认设置，但仍设置字体和解释器
                set(hLegend, 'FontName', 'Times New Roman');
                set(hLegend, 'Interpreter', 'latex');

                % 尝试设置标记大小
                try
                    legend_children = get(hLegend, 'Children');
                    for i = 1:length(legend_children)
                        if strcmp(get(legend_children(i), 'Type'), 'line') && ...
                           ~isempty(get(legend_children(i), 'Marker')) && ...
                           ~strcmp(get(legend_children(i), 'Marker'), 'none')
                            set(legend_children(i), 'MarkerSize', 15);
                        end
                    end
                catch
                    % 如果标记大小设置失败，继续执行
                end
            end
        end

        % 调整布局
        box on;
        axis square;
        
        % 保存图形 - MATLAB 2019a兼容
        try
            timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        catch
            % 如果datestr不可用，使用简单的时间戳
            timestamp = sprintf('%d', round(now*86400)); % 转换为秒数
        end
        filename = sprintf('Zeff_scaling_law_fitting_%s.fig', timestamp);
        saveas(gcf, filename);
        fprintf('Figure saved as: %s\n', filename);
        
    else
        fprintf('Skipping plot generation due to fitting failure.\n');
    end
    
    fprintf('\n=== Zeff scaling law fitting analysis completed ===\n');
end


