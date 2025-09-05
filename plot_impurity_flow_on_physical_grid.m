function plot_impurity_flow_on_physical_grid(all_radiationData)
% PLOT_IMPURITY_FLOW_ON_PHYSICAL_GRID 绘制各价态杂质离子在物理网格中的粒子流模式图
%
%   此函数为每个提供的SOLPS算例数据，针对每种杂质离子价态，
%   在物理网格上绘制粒子流模式。
%   背景色图表示特定价态粒子通量的大小 (sqrt(flux_pol^2 + flux_rad^2))。
%   在每个物理网格单元中心叠加箭头以指示粒子流的方向。
%   箭头R分量来自径向通量，Z分量来自极向通量。
%
%   基于 plot_impurity_charge_state_flow_pattern.m (计算网格流图)
%   和 plot_Ne_plus_ionization_source.m (物理网格surfplot) 修改。
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

        fprintf('Processing case for physical grid impurity flow patterns: %s\n', dirName);

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
        
        % --- 创建用于 surfplot 的 gmtry_plot 结构体 ---
        % This gmtry_plot is not suitable for surfplot, which expects full gmtry with cut fields.
        % gmtry_plot = struct;
        % gmtry_plot.crx = gmtry.crx(2:nx_orig-1, 2:ny_orig-1, :);
        % gmtry_plot.cry = gmtry.cry(2:nx_orig-1, 2:ny_orig-1, :);
        % gmtry_plot.nx = nx_plot;
        % gmtry_plot.ny = ny_plot;

        % 假设杂质是Ne，物种索引4-13对应Ne1+到Ne10+
        min_species_idx = 4;
        max_species_idx = 13;

        for i_species = min_species_idx:max_species_idx
            charge_state = i_species - (min_species_idx - 1); 

            fprintf('  Processing charge state Ne%d+ (species index %d) for physical grid plot: %s\n', charge_state, i_species, dirName);

            % --- 计算特定价态的粒子通量 (基于原始完整数据) ---
            % fna_mdf(ix,iy,direction,species), direction: 1=poloidal, 2=radial
            if size(plasma.fna_mdf, 4) < i_species
                warning('Case %s, Species %d (Ne%d+): Not enough species in plasma.fna_mdf (max index %d). Skipping this charge state.', ...
                        dirName, i_species, charge_state, size(plasma.fna_mdf, 4));
                continue; 
            end
            
            fna_pol_single_species_full = plasma.fna_mdf(:, :, 1, i_species);
            fna_rad_single_species_full = plasma.fna_mdf(:, :, 2, i_species);

            % --- 切片通量数据以去除保护单元 ---
            fna_pol_plot = fna_pol_single_species_full(2:nx_orig-1, 2:ny_orig-1);
            fna_rad_plot = fna_rad_single_species_full(2:nx_orig-1, 2:ny_orig-1);

            % 特定价态总通量大小 (基于切片后的数据 for plot region)
            flux_magnitude_for_plot_region = sqrt(fna_pol_plot.^2 + fna_rad_plot.^2);
            
            % Ensure flux_magnitude_for_plot_region contains only non-negative, finite values.
            % Replace NaNs, Infs with 0. Also ensure no negatives (e.g. from complex sqrt if inputs were bad)
            flux_magnitude_for_plot_region(isnan(flux_magnitude_for_plot_region) | isinf(flux_magnitude_for_plot_region) | flux_magnitude_for_plot_region < 0) = 0;

            % Create a full-sized data matrix for surfplot
            flux_magnitude_full_grid = zeros(nx_orig, ny_orig);
            flux_magnitude_full_grid(2:nx_orig-1, 2:ny_orig-1) = flux_magnitude_for_plot_region;

            % --- 创建用于 surfplot 的对数通量数据 ---
            % 使用一个小的正数替换零值，以避免log10(0)错误
            flux_magnitude_log_for_surfplot = log10(max(flux_magnitude_full_grid, eps)); 

            % 归一化通量方向 (用于箭头，基于切片后的数据)
            fna_pol_norm_plot = zeros(size(fna_pol_plot));
            fna_rad_norm_plot = zeros(size(fna_rad_plot));

            non_zero_flux_mask = flux_magnitude_for_plot_region > 1e-9; % Avoid division by zero
            fna_pol_norm_plot(non_zero_flux_mask) = fna_pol_plot(non_zero_flux_mask) ./ flux_magnitude_for_plot_region(non_zero_flux_mask);
            fna_rad_norm_plot(non_zero_flux_mask) = fna_rad_plot(non_zero_flux_mask) ./ flux_magnitude_for_plot_region(non_zero_flux_mask);
            
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
            fig_title_name = sprintf('Physical Grid Flow Ne%d+', charge_state);
            figure('Name', fig_title_name, ...
                   'NumberTitle', 'off', 'Color', 'w', ...
                   'Units', 'inches', 'Position', [1, 0.5, 15, 12]); % Adjusted size - Increased figure size
            ax = axes;
            hold(ax, 'on');

            % --- 绘制背景色图 (通量大小) using surfplot ---
            % Pass the original gmtry and the full_grid data to surfplot
            surfplot(gmtry, flux_magnitude_log_for_surfplot); % 使用对数转换后的数据
            shading(ax, 'interp');
            view(ax, 2);
            h_cb = colorbar(ax);
            
            % --- 设置颜色栏范围、刻度和标签 (参考 plot_ionization_source_and_poloidal_stagnation_point.m) ---
            relevant_flux_values = flux_magnitude_for_plot_region(flux_magnitude_for_plot_region > 0 & isfinite(flux_magnitude_for_plot_region));

            if ~isempty(relevant_flux_values)
                min_actual_flux = min(relevant_flux_values);
                max_actual_flux = max(relevant_flux_values);

                log10_cmin_val = log10(min_actual_flux);
                log10_cmax_val = log10(max_actual_flux);

                if abs(log10_cmin_val - log10_cmax_val) < 1e-6 % 对数值非常接近
                    % 扩展范围，例如在对数尺度上各扩展0.5
                    log10_cmin_final = log10_cmin_val - 0.5;
                    log10_cmax_final = log10_cmax_val + 0.5;
                    % 如果扩展后范围仍无效 (例如原始值是eps)，则使用默认值
                    if log10_cmin_final >= log10_cmax_final
                        log10_cmin_final = 12; 
                        log10_cmax_final = 16;
                    end
                else
                    log10_cmin_final = log10_cmin_val;
                    log10_cmax_final = log10_cmax_val;
                end
                
                % 确保颜色栏至少有一个小的跨度
                if (log10_cmax_final - log10_cmin_final) < 0.1 
                    mid_log = (log10_cmin_final + log10_cmax_final) / 2;
                    log10_cmin_final = mid_log - 0.25; % 总共扩展0.5个数量级
                    log10_cmax_final = mid_log + 0.25;
                end
            else
                % 没有有效的通量数据，使用默认的对数范围
                log10_cmin_final = 12; % 对应 1e12
                log10_cmax_final = 16; % 对应 1e16
            end
            caxis(ax, [log10_cmin_final, log10_cmax_final]);

            num_ticks = 5;
            log_tick_positions = linspace(log10_cmin_final, log10_cmax_final, num_ticks);
            
            base_exponent = floor(log10_cmin_final); 
            % 如果刻度最大值跨越了下一个整数幂次，可以考虑调整 base_exponent
            if floor(log10_cmax_final) > base_exponent && (log10_cmax_final - floor(log10_cmax_final) > 0.1) && (num_ticks > 2 && 10^(log_tick_positions(end) - floor(log10_cmax_final)) < 1.5)
                 % Heuristic: if the max tick is small factor of a higher power, maybe use that higher power's floor as base.
                 % Or more simply, if the range significantly covers orders of magnitude, base_exponent = floor(log10_cmin_final) is fine.
            end


            tick_labels_str_cell = cell(1, num_ticks);
            for i_tick = 1:num_ticks
                coeff = 10^(log_tick_positions(i_tick) - base_exponent);
                if abs(coeff - round(coeff)) < 1e-3 % 接近整数
                    tick_labels_str_cell{i_tick} = sprintf('%d', round(coeff));
                elseif coeff < 10 && coeff >=1 % 1到10之间，一位小数
                    tick_labels_str_cell{i_tick} = sprintf('%.1f', coeff);
                else % 其他情况，科学计数法或更通用格式
                    tick_labels_str_cell{i_tick} = sprintf('%.2g', coeff);
                end
            end

            h_cb.Ticks = log_tick_positions;
            h_cb.TickLabels = tick_labels_str_cell;
            h_cb.TickLabelInterpreter = 'latex'; % 与全局设置一致
            
            % 设置颜色栏字体大小 (参考全局设置)
            axes_font_size = get(0, 'DefaultAxesFontSize');
            colorbar_tick_font_size = axes_font_size - 2;
            if colorbar_tick_font_size < 10, colorbar_tick_font_size = 10; end % 最小字体
            h_cb.FontSize = colorbar_tick_font_size;

            % 设置颜色栏标签和指数标题
            colorbar_label_main_str = sprintf('Ne$^{%d+}$ Ion Flux (particles/s)', charge_state);
            exponent_title_str = ['$\mathbf{\times 10^{' num2str(base_exponent) '}}$']; % Robust construction

            h_cb.Label.String = colorbar_label_main_str;
            h_cb.Label.Interpreter = 'latex';
            h_cb.Label.FontSize = axes_font_size; % 标签使用轴字体大小

            title(h_cb, exponent_title_str, 'Interpreter', 'latex', 'FontSize', axes_font_size);
            
            colormap(ax, 'jet');
            
            % --- 绘制箭头 (流方向) ---
            arrow_scale_factor = 0.5; % Adjust as needed for physical coordinates
            
            % U_quiver from radial flux, V_quiver from poloidal flux
            % This is a convention: assumes R-axis for quiver U, Z-axis for quiver V.
            quiver(ax, R_centers_plot, Z_centers_plot, ...
                   fna_rad_norm_plot, fna_pol_norm_plot, ...
                   arrow_scale_factor, 'k', 'LineWidth', 0.7);

            % --- 叠加分离器/结构 ---
            % Use original gmtry for plot3sep as it expects full grid info
            % The original gmtry should contain necessary fields like isepx, isepy, wall, bb if plot3sep is to work correctly.
            plot3sep(gmtry, 'color','w','LineStyle','--','LineWidth',2.0);
            
            % --- 设置坐标轴和标题 ---
            xlabel(ax, '$R$ (m)', 'FontSize', 18);
            ylabel(ax, '$Z$ (m)', 'FontSize', 18);
            title(ax, sprintf('Ne$^{%d+}$ Flow Pattern (Physical Grid)', charge_state), 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
            
            % 指定绘制后展示的区域为上单零位形区域
            xlim(ax, [1.30, 2.00]); % 上偏滤器区域 R 范围
            ylim(ax, [0.50, 1.20]); % 上偏滤器区域 Z 范围
            
            axis(ax, 'equal'); % Keep aspect ratio physical
            % axis(ax, 'tight'); % This line might override xlim and ylim
            box(ax, 'on');
            grid(ax, 'off'); % Typically off for surfplot visualizations
            
            hold(ax, 'off');

            % --- 保存图像 ---
            saveFigureWithTimestamp(gcf, sprintf('PhysicalFlowPattern_Ne%d_%s', charge_state, createSafeFilename(dirName)));
        
        end % End loop over species
    end % End loop over cases
    fprintf('\n>>> Completed: Impurity flow pattern on Physical Grid for all cases.\n');
end % End main function

% Helper function: createSafeFilename (if not already in path or defined locally)
function safeName = createSafeFilename(originalName)
    safeName = regexprep(originalName, '[^a-zA-Z0-9_\-\.]', '_');
    if strlength(safeName) > 100 % Max filename length considerations
        safeName = safeName(1:100);
    end
end

% Helper function: saveFigureWithTimestamp (if not already in path or defined locally)
function saveFigureWithTimestamp(figHandle, baseName)
    set(figHandle,'PaperPositionMode','auto'); % Preserve aspect ratio and size
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    figFile = sprintf('%s_%s.fig', baseName, timestampStr);
    pngFile = sprintf('%s_%s.png', baseName, timestampStr);
    try
        savefig(figHandle, figFile);
        fprintf('MATLAB figure saved to: %s\n', figFile);
        % saveas(figHandle, pngFile);
        % fprintf('MATLAB figure saved to: %s\n', pngFile);
    catch ME_save
        fprintf('Warning: Failed to save figure. Error: %s\n', ME_save.message);
    end
end

% Minimal plot3sep if the full one is complex or causes issues without full gmtry fields.
% This is a placeholder, ideally the existing plot3sep from the project should be used.
% function plot3sep_minimal(gmtry_s, varargin)
%     % gmtry_s is the sliced gmtry (gmtry_plot)
%     % This function would need to know where separatrix is based on gmtry_s.
%     % For example, if gmtry_s had an 'isepx' field (poloidal index of sep)
%     % and 'isepy' (radial index of sep)
%     if isfield(gmtry_s, 'isepx') && isfield(gmtry_s, 'isepy')
%         % Simplified plotting of a line representing separatrix
%         % This is highly dependent on how 'isepx' and 'isepy' are defined
%         % plot(gmtry_s.crx(gmtry_s.isepx, :, 1), gmtry_s.cry(gmtry_s.isepx, :, 1), p{2:end});
%     end
% end 