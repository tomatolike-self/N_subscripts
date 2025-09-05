function plot_ExB_drift_on_physical_grid(all_radiationData)
% PLOT_EXB_DRIFT_ON_PHYSICAL_GRID 绘制ExB漂移速度在物理网格中的分布图
%
%   此函数为每个提供的SOLPS算例数据，在物理网格上绘制ExB漂移速度的分布。
%   背景色图表示ExB漂移速度的大小 (sqrt(v_pol^2 + v_rad^2))。
%   在每个物理网格单元中心叠加箭头以指示速度的方向。
%   箭头R分量来自径向速度，Z分量来自极向速度。
%
%   基于 plot_impurity_flow_on_physical_grid.m 修改。
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组，
%                         每个结构体至少需要包含 'dirName', 'gmtry', 'plasma' 字段。

    % --- 全局字体和绘图属性设置 ---
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 18);
    set(0, 'DefaultTextFontSize', 18);
    set(0, 'DefaultLineLineWidth', 1.5);
    set(0, 'DefaultUicontrolFontName', 'Times New Roman');
    set(0, 'DefaultUitableFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontSize', 16);
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
    set(0, 'DefaultLegendInterpreter', 'latex');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry = radData.gmtry;
        plasma = radData.plasma;
        dirName = radData.dirName;

        fprintf('Processing case for ExB drift on physical grid: %s\n', dirName);

        % --- 获取原始网格维度 ---
        nx_orig = 0;
        ny_orig = 0;
        if isfield(gmtry, 'crx') && ~isempty(gmtry.crx)
            s = size(gmtry.crx);
            nx_orig = s(1); % 第一个维度是极向网格数
            ny_orig = s(2); % 第二个维度是径向网格数
        elseif isfield(gmtry, 'cry') && ~isempty(gmtry.cry)
            s = size(gmtry.cry);
            nx_orig = s(1);
            ny_orig = s(2);
        else
            warning('Grid coordinate fields (crx or cry) not found or empty in gmtry structure for case %s. Skipping this case.', dirName);
            continue;
        end
        
        if nx_orig < 3 || ny_orig < 3
            warning('Original grid dimensions (nx_orig=%d, ny_orig=%d) are too small for case %s. Skipping this case.', nx_orig, ny_orig, dirName);
            continue;
        end

        % --- 计算用于绘图的网格维度 (去除保护单元) ---
        nx_plot = nx_orig - 2;
        ny_plot = ny_orig - 2;
        
        if nx_plot <= 0 || ny_plot <= 0
            warning('Plotting grid dimensions are non-positive after removing guard cells for case %s (nx_plot=%d, ny_plot=%d). Skipping this case.', dirName, nx_plot, ny_plot);
            continue;
        end
        
        % --- 计算密度加权的ExB漂移速度 (根据用户需求修改) ---
        % 假设氖离子(Ne1+ to Ne10+)的物种索引是 4 到 13
        ne_ion_indices = 4:13; 

        fprintf('  Calculating density-weighted average ExB drift for Ne ions (species %d to %d).\n', ne_ion_indices(1), ne_ion_indices(end));

        % --- 检查所需数据是否存在 ---
        if ~isfield(plasma, 'vaecrb') || ~isfield(plasma, 'na')
            warning('Case %s: "vaecrb" or "na" field not found. Skipping calculation.', dirName);
            continue; 
        end
        max_idx = max(ne_ion_indices);
        if size(plasma.vaecrb, 4) < max_idx || size(plasma.na, 3) < max_idx
            warning('Case %s: Not enough species data in "vaecrb" (size %d) or "na" (size %d) for the specified Ne ion range up to index %d. Skipping calculation.', ...
                    dirName, size(plasma.vaecrb, 4), size(plasma.na, 3), max_idx);
            continue;
        end

        % --- 提取氖离子的密度和速度 ---
        ne_densities = plasma.na(:, :, ne_ion_indices);       % 尺寸: (nx, ny, num_ne_species)
        ne_vel_pol = plasma.vaecrb(:, :, 1, ne_ion_indices);  % 尺寸: (nx, ny, num_ne_species)
        ne_vel_rad = plasma.vaecrb(:, :, 2, ne_ion_indices);  % 尺寸: (nx, ny, num_ne_species)

        % --- 计算氖离子总密度 ---
        total_ne_density = sum(ne_densities, 3);

        % --- 计算密度加权的速度 ---
        % 初始化全网格的速度
        vel_pol_full = zeros(nx_orig, ny_orig);
        vel_rad_full = zeros(nx_orig, ny_orig);

        % 创建一个掩码，只在总氖离子密度大于零的单元格进行计算，以避免除以零
        valid_density_mask = total_ne_density > 1e-6; 

        % (密度 * 速度) 的总和
        weighted_sum_pol = sum(ne_vel_pol .* ne_densities, 3);
        weighted_sum_rad = sum(ne_vel_rad .* ne_densities, 3);

        % 仅在密度有效的区域计算加权平均速度
        vel_pol_full(valid_density_mask) = weighted_sum_pol(valid_density_mask) ./ total_ne_density(valid_density_mask);
        vel_rad_full(valid_density_mask) = weighted_sum_rad(valid_density_mask) ./ total_ne_density(valid_density_mask);

        % --- 切片速度数据以去除保护单元 ---
        vel_pol_plot = vel_pol_full(2:nx_orig-1, 2:ny_orig-1);
        vel_rad_plot = vel_rad_full(2:nx_orig-1, 2:ny_orig-1);

        % 速度大小 (基于切片后的数据 for plot region)
        velocity_magnitude_for_plot_region = sqrt(vel_pol_plot.^2 + vel_rad_plot.^2);
        
        % Ensure velocity_magnitude_for_plot_region contains only non-negative, finite values.
        velocity_magnitude_for_plot_region(isnan(velocity_magnitude_for_plot_region) | isinf(velocity_magnitude_for_plot_region) | velocity_magnitude_for_plot_region < 0) = 0;

        % Create a full-sized data matrix for surfplot
        velocity_magnitude_full_grid = zeros(nx_orig, ny_orig);
        velocity_magnitude_full_grid(2:nx_orig-1, 2:ny_orig-1) = velocity_magnitude_for_plot_region;

        % --- 创建用于 surfplot 的对数速度数据 ---
        % 使用一个小的正数替换零值，以避免log10(0)错误
        velocity_magnitude_log_for_surfplot = log10(max(velocity_magnitude_full_grid, eps)); 

        % 归一化速度方向 (用于箭头，基于切片后的数据)
        vel_pol_norm_plot = zeros(size(vel_pol_plot));
        vel_rad_norm_plot = zeros(size(vel_rad_plot));

        non_zero_vel_mask = velocity_magnitude_for_plot_region > 1e-9; % Avoid division by zero
        vel_pol_norm_plot(non_zero_vel_mask) = vel_pol_plot(non_zero_vel_mask) ./ velocity_magnitude_for_plot_region(non_zero_vel_mask);
        vel_rad_norm_plot(non_zero_vel_mask) = vel_rad_plot(non_zero_vel_mask) ./ velocity_magnitude_for_plot_region(non_zero_vel_mask);
        
        % --- 计算物理网格单元中心 ---
        R_centers_plot = zeros(nx_plot, ny_plot);
        Z_centers_plot = zeros(nx_plot, ny_plot);
        for ix_p = 1:nx_plot
            for iy_p = 1:ny_plot
                % (ix_p+1, iy_p+1) 是原始 gmtry 中的索引
                R_centers_plot(ix_p, iy_p) = mean(gmtry.crx(ix_p+1, iy_p+1, :));
                Z_centers_plot(ix_p, iy_p) = mean(gmtry.cry(ix_p+1, iy_p+1, :));
            end
        end

        % --- 创建图形 ---
        fig_title_name = sprintf('Physical Grid ExB Drift - %s', dirName);
        figure('Name', fig_title_name, ...
               'NumberTitle', 'off', 'Color', 'w', ...
               'Units', 'inches', 'Position', [1, 0.5, 15, 12]);
        ax = axes;
        hold(ax, 'on');

        % --- 绘制背景色图 (速度大小) using surfplot ---
        surfplot(gmtry, velocity_magnitude_log_for_surfplot); % 使用对数转换后的数据
        shading(ax, 'interp');
        view(ax, 2);
        h_cb = colorbar(ax);
        
        % --- 设置颜色栏范围、刻度和标签 ---
        relevant_vel_values = velocity_magnitude_for_plot_region(velocity_magnitude_for_plot_region > 0 & isfinite(velocity_magnitude_for_plot_region));

        if ~isempty(relevant_vel_values)
            min_val = min(relevant_vel_values);
            max_val = max(relevant_vel_values);

            % Handle case where all values are the same or very close
            if abs(min_val - max_val) < eps
                log_val = log10(min_val);
                log10_cmin_final = log_val - 0.5;
                log10_cmax_final = log_val + 0.5;
            else
                log10_cmin_final = log10(min_val);
                log10_cmax_final = log10(max_val);
            end

            % Ensure the range is not excessively small for visualization
            if (log10_cmax_final - log10_cmin_final) < 0.1
                mid_log = (log10_cmin_final + log10_cmax_final) / 2;
                log10_cmin_final = mid_log - 0.5;
                log10_cmax_final = mid_log + 0.5;
            end
        else
            % Fallback to a default range if no valid data exists
            log10_cmin_final = 2; % Corresponds to 1e2 m/s
            log10_cmax_final = 4; % Corresponds to 1e4 m/s
        end
        
        % Final check for non-finite values or inverted range before setting caxis
        if ~all(isfinite([log10_cmin_final, log10_cmax_final])) || log10_cmin_final >= log10_cmax_final
            warning('Calculated caxis range is invalid. Using default range [1e2, 1e4] m/s.');
            log10_cmin_final = 2;
            log10_cmax_final = 4;
        end
        
        try
            caxis(ax, [log10_cmin_final, log10_cmax_final]);
        catch ME
            if strcmp(ME.identifier, 'MATLAB:hg:props:InvalidLimits')
                warning('Failed to set caxis with calculated range [%f, %f]. Using default range. Error: %s', ...
                        log10_cmin_final, log10_cmax_final, ME.message);
                caxis(ax, [2, 4]);
            else
                rethrow(ME);
            end
        end

        num_ticks = 5;
        log_tick_positions = linspace(log10_cmin_final, log10_cmax_final, num_ticks);
        
        base_exponent = floor(log10_cmin_final); 

        tick_labels_str_cell = cell(1, num_ticks);
        for i_tick = 1:num_ticks
            coeff = 10^(log_tick_positions(i_tick) - base_exponent);
            if abs(coeff - round(coeff)) < 1e-3
                tick_labels_str_cell{i_tick} = sprintf('%d', round(coeff));
            elseif coeff < 10 && coeff >=1
                tick_labels_str_cell{i_tick} = sprintf('%.1f', coeff);
            else
                tick_labels_str_cell{i_tick} = sprintf('%.2g', coeff);
            end
        end

        h_cb.Ticks = log_tick_positions;
        h_cb.TickLabels = tick_labels_str_cell;
        h_cb.TickLabelInterpreter = 'latex'; 
        
        axes_font_size = get(0, 'DefaultAxesFontSize');
        colorbar_tick_font_size = axes_font_size - 2;
        if colorbar_tick_font_size < 10, colorbar_tick_font_size = 10; end
        h_cb.FontSize = colorbar_tick_font_size;

        colorbar_label_main_str = '$\mathbf{E \times B}$ Drift Velocity (m/s)';
        exponent_title_str = ['$\mathbf{\times 10^{' num2str(base_exponent) '}}$'];

        h_cb.Label.String = colorbar_label_main_str;
        h_cb.Label.Interpreter = 'latex';
        h_cb.Label.FontSize = axes_font_size;

        title(h_cb, exponent_title_str, 'Interpreter', 'latex', 'FontSize', axes_font_size);
        
        colormap(ax, 'jet');
        
        % --- 绘制箭头 (流方向) ---
        arrow_scale_factor = 0.5; % 箭头缩放因子
        
        % U_quiver from radial velocity, V_quiver from poloidal velocity
        quiver(ax, R_centers_plot, Z_centers_plot, ...
               vel_rad_norm_plot, vel_pol_norm_plot, ...
               arrow_scale_factor, 'k', 'LineWidth', 0.7);

        % --- 叠加分离器/结构 ---
        plot3sep(gmtry, 'color','w','LineStyle','--','LineWidth',2.0);
        
        % --- 设置坐标轴和标题 ---
        xlabel(ax, '$R$ (m)', 'FontSize', 18);
        ylabel(ax, '$Z$ (m)', 'FontSize', 18);
        title(ax, ['$\mathbf{E \times B}$ Drift Velocity (Physical Grid)'], 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
        
        % 指定绘制后展示的区域为上单零位形区域
        xlim(ax, [1.30, 2.00]); % 上偏滤器区域 R 范围
        ylim(ax, [0.50, 1.20]); % 上偏滤器区域 Z 范围
        
        axis(ax, 'equal'); 
        box(ax, 'on');
        grid(ax, 'off');
        
        hold(ax, 'off');

        % --- 保存图像 ---
        saveFigureWithTimestamp(gcf, sprintf('PhysicalGrid_ExB_Drift_%s', createSafeFilename(dirName)));
    
    end % End loop over cases
    fprintf('\n>>> Completed: ExB drift velocity on Physical Grid for all cases.\n');
end % End main function

% Helper functions copied from plot_impurity_flow_on_physical_grid.m

function safeName = createSafeFilename(originalName)
    safeName = regexprep(originalName, '[^a-zA-Z0-9_\-\.]', '_');
    if strlength(safeName) > 100
        safeName = safeName(1:100);
    end
end

function saveFigureWithTimestamp(figHandle, baseName)
    set(figHandle,'PaperPositionMode','auto');
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    figFile = sprintf('%s_%s.fig', baseName, timestampStr);
    pngFile = sprintf('%s_%s.png', baseName, timestampStr);
    try
        savefig(figHandle, figFile);
        fprintf('MATLAB figure saved to: %s\n', figFile);
    catch ME_save
        fprintf('Warning: Failed to save figure. Error: %s\n', ME_save.message);
    end
end 