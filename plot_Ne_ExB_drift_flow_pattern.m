function plot_Ne_ExB_drift_flow_pattern(all_radiationData)
% PLOT_NE_EXB_DRIFT_FLOW_PATTERN 绘制各价态Ne离子在计算网格中的ExB漂移速度分布图
%
%   此函数为每个提供的SOLPS算例数据，针对每种Ne离子价态，
%   绘制计算网格中的ExB漂移速度分布。
%   它会显示一个背景色图，表示ExB漂移速度的大小，并在每个网格单元上
%   叠加箭头以指示速度的方向。
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

        fprintf('Processing case for Ne ExB drift velocity patterns: %s\n', dirName);
        
        if ~isfield(plasma, 'vaecrb')
            warning('Case %s: plasma.vaecrb field not found. Skipping ExB drift velocity plots for this case.', dirName);
            continue;
        end

        % --- 获取原始网格维度 ---
        nx_orig = 0;
        ny_orig = 0;
        if isfield(gmtry, 'crx')
            s = size(gmtry.crx);
            nx_orig = s(1); % 第一个维度是极向网格数
            ny_orig = s(2); % 第二个维度是径向网格数
            fprintf('Info: Original grid dimensions for case %s: nx_orig = %d, ny_orig = %d (from size(gmtry.crx)).\n', dirName, nx_orig, ny_orig);
        elseif isfield(gmtry, 'cry')
            s = size(gmtry.cry);
            nx_orig = s(1);
            ny_orig = s(2);
            fprintf('Info: Original grid dimensions for case %s: nx_orig = %d, ny_orig = %d (from size(gmtry.cry)).\n', dirName, nx_orig, ny_orig);
        else
            warning('Grid coordinate fields (crx or cry) not found in gmtry structure for case %s. Skipping this case.', dirName);
            continue;
        end

        if nx_orig < 3 || ny_orig < 3
            warning('Original grid dimensions (nx_orig=%d, ny_orig=%d) are too small for case %s. Skipping this case.', nx_orig, ny_orig, dirName);
            continue;
        end

        % --- 计算用于绘图的网格维度 (去除保护单元) ---
        nx_plot = nx_orig - 2;
        ny_plot = ny_orig - 2;
        fprintf('Info: Plotting grid dimensions after removing guard cells: nx_plot = %d, ny_plot = %d.\n', nx_plot, ny_plot);

        if nx_plot <= 0 || ny_plot <= 0
            warning('Plotting grid dimensions are non-positive after removing guard cells for case %s (nx_plot=%d, ny_plot=%d). Skipping this case.', dirName, nx_plot, ny_plot);
            continue;
        end

        % 假设杂质是Ne，物种索引4-13对应Ne1+到Ne10+
        min_species_idx = 4;
        max_species_idx = 13;

        for i_species = min_species_idx:max_species_idx
            charge_state = i_species - (min_species_idx - 1); % e.g., species 4 is 1+

            fprintf('  Processing charge state Ne%d+ (species index %d) for case: %s\n', charge_state, i_species, dirName);

            % --- 计算特定价态的ExB漂移速度 (基于原始完整数据) ---
            % vaecrb(ix,iy,direction,species), direction: 1=poloidal, 2=radial
            if size(plasma.vaecrb, 4) < i_species
                warning('Case %s, Species %d (Ne%d+): Not enough species in plasma.vaecrb (max index %d). Skipping this charge state.', ...
                        dirName, i_species, charge_state, size(plasma.vaecrb, 4));
                continue; % Skip this charge state
            end
            
            vexb_pol_full = plasma.vaecrb(:, :, 1, i_species);
            vexb_rad_full = plasma.vaecrb(:, :, 2, i_species);

            % --- 切片速度数据以去除保护单元 ---
            vexb_pol_plot = vexb_pol_full(2:nx_orig-1, 2:ny_orig-1);
            vexb_rad_plot = vexb_rad_full(2:nx_orig-1, 2:ny_orig-1);

            % 特定价态ExB漂移速度大小 (基于切片后的数据)
            velocity_magnitude_plot = sqrt(vexb_pol_plot.^2 + vexb_rad_plot.^2);

            % 归一化速度方向 (用于箭头，基于切片后的数据)
            u_norm_plot = zeros(size(vexb_pol_plot));
            v_norm_plot = zeros(size(vexb_rad_plot));

            non_zero_velocity = velocity_magnitude_plot > 1e-9; % Avoid division by zero or very small numbers
            u_norm_plot(non_zero_velocity) = vexb_pol_plot(non_zero_velocity) ./ velocity_magnitude_plot(non_zero_velocity);
            v_norm_plot(non_zero_velocity) = vexb_rad_plot(non_zero_velocity) ./ velocity_magnitude_plot(non_zero_velocity);

            % --- 创建图形 ---
            fig_title_name = sprintf('ExB Drift Velocity Ne%d+ - Comp. Grid (no guard) - %s', charge_state, dirName);
            figure('Name', fig_title_name, ...
                   'NumberTitle', 'off', 'Color', 'w', ...
                   'Units', 'inches', 'Position', [1, 1, 16, 12]);
            ax = axes;
            hold(ax, 'on');

            % --- 绘制背景色图 (速度大小) ---
            x_coords_plot = 1:nx_plot;
            y_coords_plot = 1:ny_plot;
            [X_mesh_main, Y_mesh_main] = meshgrid(x_coords_plot, y_coords_plot);

            surf(ax, X_mesh_main, Y_mesh_main, zeros(size(X_mesh_main)), velocity_magnitude_plot', 'EdgeColor', 'none');
            shading(ax, 'interp');
            view(ax, 2);
            h_cb = colorbar(ax);
            set(ax, 'ColorScale', 'log'); 
            
            ylabel(h_cb, sprintf('Ne$^{%d+}$ ExB Drift Velocity Magnitude (m/s)', charge_state), 'FontSize', 16);
            colormap(ax, 'jet');
            set(ax, 'YDir', 'normal');

            % --- BEGIN: Add custom data cursor ---
            dcm_obj = datacursormode(gcf);
            set(dcm_obj, 'Enable', 'on');
            set(dcm_obj, 'UpdateFcn', {@myDataCursorUpdateFcn_ExB, nx_plot, ny_plot, vexb_pol_plot, vexb_rad_plot, velocity_magnitude_plot});
            % --- END: Add custom data cursor ---

            % --- 绘制箭头 (速度方向) ---
            arrow_scale = 0.4;

            if nx_plot > 1 && ny_plot > 1
                x_coords_quiver_centers = (1:(nx_plot-1)) + 0.5;
                y_coords_quiver_centers = (1:(ny_plot-1)) + 0.5;
                [X_mesh_quiver, Y_mesh_quiver] = meshgrid(x_coords_quiver_centers, y_coords_quiver_centers);

                u_norm_plot_for_quiver = u_norm_plot(1:nx_plot-1, 1:ny_plot-1);
                v_norm_plot_for_quiver = v_norm_plot(1:nx_plot-1, 1:ny_plot-1);

                quiver(ax, X_mesh_quiver, Y_mesh_quiver, ...
                       u_norm_plot_for_quiver', v_norm_plot_for_quiver', ...
                       arrow_scale, 'k', 'LineWidth', 0.5);
            else
                fprintf('Info: Not enough grid cells (nx_plot=%d, ny_plot=%d) to draw flow arrows for Ne%d+ in case %s. Skipping quiver plot.\n', nx_plot, ny_plot, charge_state, dirName);
            end

            % --- 添加区域划分和标签 ---
            isep_idx_fixed = 12;
            inner_div_pol_end_fixed = 24;
            omp_pol_idx_fixed       = 41;
            imp_pol_idx_fixed       = 58;
            outer_div_pol_start_fixed = 73;

            plot(ax, [inner_div_pol_end_fixed + 1, inner_div_pol_end_fixed + 1], [1, isep_idx_fixed+1], 'k-', 'LineWidth', 1.0);
            plot(ax, [inner_div_pol_end_fixed + 1, inner_div_pol_end_fixed + 1], [isep_idx_fixed+1, ny_plot], 'k--', 'LineWidth', 1.0);
            plot(ax, [outer_div_pol_start_fixed, outer_div_pol_start_fixed], [1, isep_idx_fixed+1], 'k-', 'LineWidth', 1.0);
            plot(ax, [outer_div_pol_start_fixed, outer_div_pol_start_fixed], [isep_idx_fixed+1, ny_plot], 'k--', 'LineWidth', 1.0);
            plot(ax, [omp_pol_idx_fixed, omp_pol_idx_fixed], [1, ny_plot], 'k--', 'LineWidth', 1.0);
            plot(ax, [imp_pol_idx_fixed, imp_pol_idx_fixed], [1, ny_plot], 'k--', 'LineWidth', 1.0);
            plot(ax, [1, nx_plot], [isep_idx_fixed + 1, isep_idx_fixed + 1], 'k-', 'LineWidth', 1.5);

            label_font_size = 16;
            top_label_y_pos = ny_plot + 1.2;
            text(ax, 1, top_label_y_pos, 'OT', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'VerticalAlignment', 'bottom');
            text(ax, inner_div_pol_end_fixed, top_label_y_pos, 'ODE', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'VerticalAlignment', 'bottom');
            text(ax, omp_pol_idx_fixed, top_label_y_pos, 'OMP', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'VerticalAlignment', 'bottom');
            text(ax, imp_pol_idx_fixed, top_label_y_pos, 'IMP', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'VerticalAlignment', 'bottom');
            text(ax, outer_div_pol_start_fixed, top_label_y_pos, 'IDE', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'VerticalAlignment', 'bottom');
            text(ax, nx_plot, top_label_y_pos, 'IT', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'VerticalAlignment', 'bottom');

            core_sol_x_pos = round(nx_plot / 2);
            core_y_pos = round(isep_idx_fixed * 0.6);
            sol_y_pos = isep_idx_fixed + round((ny_plot - isep_idx_fixed) * 0.65);

            text(ax, core_sol_x_pos, core_y_pos, 'Core', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontWeight', 'bold');
            text(ax, core_sol_x_pos, sol_y_pos, 'SOL', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontWeight', 'bold');

            PFR_x_left = round(inner_div_pol_end_fixed * 0.5);
            PFR_x_right = round(outer_div_pol_start_fixed + (nx_plot - outer_div_pol_start_fixed) * 0.5);
            text(ax, PFR_x_left, core_y_pos, 'PFR', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontWeight', 'bold');
            text(ax, PFR_x_right, core_y_pos, 'PFR', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontWeight', 'bold');
            text(ax, round(nx_plot/2), isep_idx_fixed + 2, 'Separatrix', 'FontSize', label_font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold', 'BackgroundColor','none');
            
            % --- 设置坐标轴和标题 ---
            xlabel(ax, '$\mathrm{i_x}$ (Poloidal Cell Index)', 'FontSize', 18, 'Interpreter', 'latex');
            ylabel(ax, '$\mathrm{i_y}$ (Radial Cell Index)', 'FontSize', 18, 'Interpreter', 'latex');

            axis(ax, [1, nx_plot, 1, ny_plot]);
            set(ax, 'XTick', unique(sort([1, inner_div_pol_end_fixed, omp_pol_idx_fixed, imp_pol_idx_fixed, outer_div_pol_start_fixed, nx_plot])));
            set(ax, 'YTick', unique(sort([1, isep_idx_fixed, ny_plot])));

            box(ax, 'on');
            grid(ax, 'off');
            hold(ax, 'off');

            % --- 保存图像 ---
            saveFigureWithTimestamp(gcf, sprintf('ExB_Drift_Velocity_Ne%d_CompGrid_NoGuard_%s', charge_state, createSafeFilename(dirName)));
        
        end % End loop over species
    end % End loop over cases
end % End main function

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
    try
        savefig(figHandle, figFile);
        fprintf('MATLAB figure saved to: %s\n', figFile);
    catch ME_fig
        fprintf('Warning: Failed to save .fig file. Error: %s\n', ME_fig.message);
    end
end

function output_txt = myDataCursorUpdateFcn_ExB(~, event_obj, nx_p, ny_p, vexb_pol_data, vexb_rad_data, velocity_mag_data)
% myDataCursorUpdateFcn_ExB 自定义数据游标更新函数 for ExB drift velocity plots
    pos = get(event_obj, 'Position');
    x_clicked = pos(1);
    y_clicked = pos(2);

    if nx_p > 1 && ny_p > 1
        x_arrow_q_centers = (1:(nx_p-1)) + 0.5;
        y_arrow_q_centers = (1:(ny_p-1)) + 0.5;

        [~, idx_pol_cell] = min(abs(x_arrow_q_centers - x_clicked));
        [~, idx_rad_cell] = min(abs(y_arrow_q_centers - y_clicked));
        
        pol_vel_val = vexb_pol_data(idx_pol_cell, idx_rad_cell);
        rad_vel_val = vexb_rad_data(idx_pol_cell, idx_rad_cell);
        mag_vel_val = velocity_mag_data(idx_pol_cell, idx_rad_cell);
        
        actual_arrow_x = x_arrow_q_centers(idx_pol_cell);
        actual_arrow_y = y_arrow_q_centers(idx_rad_cell);

        output_txt = {sprintf('Arrow at Cell (ix, iy): (%d, %d)', idx_pol_cell, idx_rad_cell), ...
                      sprintf('  Arrow Center Coords: (X=%.2f, Y=%.2f)', actual_arrow_x, actual_arrow_y), ...
                      sprintf('  Poloidal Velocity: %.3e m/s', pol_vel_val), ...
                      sprintf('  Radial Velocity: %.3e m/s', rad_vel_val), ...
                      sprintf('  Velocity Magnitude: %.3e m/s', mag_vel_val)};
    else
        ix_surf = round(x_clicked);
        iy_surf = round(y_clicked);
        
        validated_ix_surf = max(1, min(ix_surf, nx_p));
        validated_iy_surf = max(1, min(iy_surf, ny_p));
        
        z_value = velocity_mag_data(validated_ix_surf, validated_iy_surf);
        
        output_txt = {sprintf('Surf Data - Poloidal Cell: %d', validated_ix_surf), ...
                      sprintf('Surf Data - Radial Cell: %d', validated_iy_surf), ...
                      sprintf('Surf Data - Velocity Magnitude: %.3e m/s', z_value)};
    end
end 