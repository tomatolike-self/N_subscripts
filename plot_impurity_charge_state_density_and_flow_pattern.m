function plot_impurity_charge_state_density_and_flow_pattern(all_radiationData)
% PLOT_IMPURITY_CHARGE_STATE_DENSITY_AND_FLOW_PATTERN 绘制各价态杂质离子密度分布及在计算网格中的粒子流模式图
%
%   此函数为每个提供的SOLPS算例数据，针对每种杂质离子价态，
%   绘制其密度分布（背景色图）和计算网格中的粒子流模式（箭头）。
%   基于 plot_impurity_charge_state_flow_pattern.m 修改。
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

        fprintf('Processing case for impurity charge state density and flow patterns: %s\n', dirName);

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

            % --- 检查是否存在所需的数据 ---
            if size(plasma.fna_mdf, 4) < i_species
                warning('Case %s, Species %d (Ne%d+): Not enough species in plasma.fna_mdf (max index %d) for flux data. Skipping this charge state.', ...
                        dirName, i_species, charge_state, size(plasma.fna_mdf, 4));
                continue; 
            end
            if size(plasma.na, 3) < i_species % na_mdf has dimensions (ix, iy, species)
                warning('Case %s, Species %d (Ne%d+): Not enough species in plasma.na (max index %d) for density data. Skipping this charge state.', ...
                        dirName, i_species, charge_state, size(plasma.na, 3));
                continue;
            end
            
            % --- 计算特定价态的粒子通量 (基于原始完整数据) ---
            fna_pol_single_species_full = plasma.fna_mdf(:, :, 1, i_species);
            fna_rad_single_species_full = plasma.fna_mdf(:, :, 2, i_species);

            % --- 获取特定价态的粒子密度 (基于原始完整数据) ---
            density_single_species_full = plasma.na(:, :, i_species);

            % --- 切片通量和密度数据以去除保护单元 ---
            fna_pol_plot = fna_pol_single_species_full(2:nx_orig-1, 2:ny_orig-1);
            fna_rad_plot = fna_rad_single_species_full(2:nx_orig-1, 2:ny_orig-1);
            density_plot = density_single_species_full(2:nx_orig-1, 2:ny_orig-1);

            % --- 获取并切片体积数据 ---
            if isfield(gmtry, 'vol')
                vol_full = gmtry.vol; % (nx_orig, ny_orig)
                vol_plot = vol_full(2:nx_orig-1, 2:ny_orig-1); % (nx_plot, ny_plot)
            else
                warning('Case %s: gmtry.vol not found. Cannot calculate particle count. Skipping this species.', dirName);
                continue;
            end
            
            % --- 计算每个单元中的粒子数 (密度 * 体积) ---
            particle_count_plot = density_plot .* vol_plot;

            % 计算通量大小 (用于可能的显示或调试，但不用于背景色)
            flux_magnitude_plot = sqrt(fna_pol_plot.^2 + fna_rad_plot.^2);

            % 归一化通量方向 (用于箭头，基于切片后的数据)
            u_norm_plot = zeros(size(fna_pol_plot));
            v_norm_plot = zeros(size(fna_rad_plot));

            non_zero_flux = flux_magnitude_plot > 1e-9; % Avoid division by zero or very small numbers
            u_norm_plot(non_zero_flux) = fna_pol_plot(non_zero_flux) ./ flux_magnitude_plot(non_zero_flux);
            v_norm_plot(non_zero_flux) = fna_rad_plot(non_zero_flux) ./ flux_magnitude_plot(non_zero_flux);

            % --- 创建图形 ---
            fig_title_name = sprintf('Density and Flow Pattern Ne%d+ - Comp. Grid (no guard) - %s', charge_state, dirName);
            figure('Name', fig_title_name, ...
                   'NumberTitle', 'off', 'Color', 'w', ...
                   'Units', 'inches', 'Position', [1, 1, 15, 10.5]);
            ax = axes;
            hold(ax, 'on');

            % --- 绘制背景色图 (杂质离子密度) ---
            x_coords_plot = 1:nx_plot;
            y_coords_plot = 1:ny_plot;
            [X_mesh_main, Y_mesh_main] = meshgrid(x_coords_plot, y_coords_plot);

            surf(ax, X_mesh_main, Y_mesh_main, zeros(size(X_mesh_main)), density_plot', 'EdgeColor', 'none');
            shading(ax, 'interp');
            view(ax, 2);
            h_cb = colorbar(ax);
            set(ax, 'ColorScale', 'log'); 
            
            % 使用 density_plot 计算显示范围
            density_display_floor = 1e10; % Minimum density to display, m^-3
            default_clim_range_density = [1e10, 1e16]; % Default CLim range for density
            calculation_threshold = 1e-9; % Smallest positive density to consider for min/max

            positive_densities = density_plot(density_plot > calculation_threshold);
            
            if isempty(positive_densities)
                min_val_disp = density_display_floor; 
                max_val_disp = []; 
            else
                min_val_disp = max(density_display_floor, min(positive_densities));
                max_val_disp = max(positive_densities);
            end
            
            if ~isempty(min_val_disp) && ~isempty(max_val_disp) && min_val_disp < max_val_disp
                set(ax, 'CLim', [min_val_disp, max_val_disp]);
            elseif ~isempty(max_val_disp) && max_val_disp > 0 
                 new_lower_bound = max(max_val_disp/1000, density_display_floor);
                 if new_lower_bound >= max_val_disp 
                     if max_val_disp > density_display_floor 
                        new_lower_bound = max(max_val_disp/10, density_display_floor);
                        if new_lower_bound >= max_val_disp 
                           set(ax, 'CLim', default_clim_range_density); 
                        else
                           set(ax, 'CLim', [new_lower_bound, max_val_disp]);
                        end
                     else 
                        set(ax, 'CLim', default_clim_range_density); 
                     end
                 else
                    set(ax, 'CLim', [new_lower_bound, max_val_disp]);
                 end
            else 
                 set(ax, 'CLim', default_clim_range_density);
            end
            % 固定 colorbar 范围
            set(ax, 'CLim', [2e16, 2e18]);

            ylabel(h_cb, sprintf('Ne$^{%d+}$ Density (m$^{-3}$)', charge_state), 'FontSize', 16);
            colormap(ax, 'jet'); % Or 'jet', 'viridis', etc.
            set(ax, 'YDir', 'normal');

            % --- BEGIN: Add custom data cursor ---
            dcm_obj = datacursormode(gcf);
            set(dcm_obj, 'Enable', 'on');
            % Pass density_plot, fna_pol_plot, fna_rad_plot, and vol_plot for the current charge state
            set(dcm_obj, 'UpdateFcn', {@myDataCursorUpdateFcn_DensityAndFlow, nx_plot, ny_plot, density_plot, fna_pol_plot, fna_rad_plot, vol_plot});
            % --- END: Add custom data cursor ---

            % --- 绘制箭头 (流方向) ---
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

            % 边界线语义与主库保持一致：
            % 分离面以下（Core-PFR）实线；分离面以上（SOL）虚线；OMP/IMP 全高虚线
            plot(ax, [inner_div_pol_end_fixed + 1, inner_div_pol_end_fixed + 1], [1, isep_idx_fixed + 1], 'k-', 'LineWidth', 1.0);
            plot(ax, [inner_div_pol_end_fixed + 1, inner_div_pol_end_fixed + 1], [isep_idx_fixed + 1, ny_plot], 'k--', 'LineWidth', 1.0);
            plot(ax, [outer_div_pol_start_fixed, outer_div_pol_start_fixed], [1, isep_idx_fixed + 1], 'k-', 'LineWidth', 1.0);
            plot(ax, [outer_div_pol_start_fixed, outer_div_pol_start_fixed], [isep_idx_fixed + 1, ny_plot], 'k--', 'LineWidth', 1.0);
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
            % Title is set by figure name
            % title(ax, sprintf('Ne%d+ Density and Flow (Comp. Grid: %dx%d)', charge_state, nx_plot, ny_plot), 'FontSize', 16, 'FontWeight', 'bold');

            axis(ax, [1, nx_plot, 1, ny_plot]);
            set(ax, 'XTick', unique(sort([1, inner_div_pol_end_fixed, omp_pol_idx_fixed, imp_pol_idx_fixed, outer_div_pol_start_fixed, nx_plot])));
            set(ax, 'YTick', unique(sort([1, isep_idx_fixed, ny_plot])));

            box(ax, 'on');
            grid(ax, 'off');
            hold(ax, 'off');

            % --- 保存图像 ---
            saveFigureWithTimestamp(gcf, sprintf('DensityFlowPattern_Ne%d_CompGrid_NoGuard_%s', charge_state, createSafeFilename(dirName)));
        
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
    % Create 'Figures' subdirectory if it doesn't exist
    if ~exist('Figures', 'dir')
       mkdir('Figures');
    end
    figPath = fullfile('Figures', figFile);

    try
        savefig(figHandle, figPath);
        fprintf('MATLAB figure saved to: %s\n', figPath);
    catch ME_fig
        fprintf('Warning: Failed to save .fig file. Error: %s\n', ME_fig.message);
    end
end

function output_txt = myDataCursorUpdateFcn_DensityAndFlow(~, event_obj, nx_p, ny_p, density_data, fna_pol_data, fna_rad_data, vol_data_plot)
% myDataCursorUpdateFcn_DensityAndFlow 自定义数据游标更新函数 for density and flow plots
    pos = get(event_obj, 'Position');
    x_clicked = pos(1);
    y_clicked = pos(2);

    % Determine if clicked on a surf point or near an arrow
    target = get(event_obj,'Target');
    target_type = get(target,'Type');

    if strcmp(target_type, 'surface') % Clicked on the density surface
        ix_surf = round(x_clicked);
        iy_surf = round(y_clicked);
        
        validated_ix_surf = max(1, min(ix_surf, nx_p));
        validated_iy_surf = max(1, min(iy_surf, ny_p));
        
        density_val = density_data(validated_ix_surf, validated_iy_surf);
        volume_val = vol_data_plot(validated_ix_surf, validated_iy_surf);
        particle_count_val = density_val * volume_val;
        pol_flux_val = fna_pol_data(validated_ix_surf, validated_iy_surf); % Approx flux at cell center
        rad_flux_val = fna_rad_data(validated_ix_surf, validated_iy_surf); % Approx flux at cell center
        flux_mag_val = sqrt(pol_flux_val^2 + rad_flux_val^2);

        output_txt = {sprintf('Cell (ix, iy): (%d, %d)', validated_ix_surf, validated_iy_surf), ...
                      sprintf('  Density: %.3e m^{-3}', density_val), ...
                      sprintf('  Volume: %.3e m^3', volume_val), ...
                      sprintf('  Particles in Cell: %.3e', particle_count_val), ...
                      sprintf('  Poloidal Flux (approx): %.3e s^{-1}', pol_flux_val), ...
                      sprintf('  Radial Flux (approx): %.3e s^{-1}', rad_flux_val), ...
                      sprintf('  Flux Magnitude (approx): %.3e s^{-1}', flux_mag_val)};

    elseif strcmp(target_type, 'quivergroup') % Clicked on or near an arrow
        if nx_p > 1 && ny_p > 1
            % Find the nearest arrow center to the click
            % Arrow centers are at (i+0.5, j+0.5) for cells (i,j) up to (nx_p-1, ny_p-1)
            x_arrow_q_centers = (1:(nx_p-1)) + 0.5;
            y_arrow_q_centers = (1:(ny_p-1)) + 0.5;

            [~, idx_pol_arrow_cell] = min(abs(x_arrow_q_centers - x_clicked)); % This is the index for the arrow
            [~, idx_rad_arrow_cell] = min(abs(y_arrow_q_centers - y_clicked));
            
            % The arrow at (idx_pol_arrow_cell, idx_rad_arrow_cell) represents flow from cell (idx_pol_arrow_cell, idx_rad_arrow_cell)
            % to (idx_pol_arrow_cell+1, idx_rad_arrow_cell) for poloidal and (idx_pol_arrow_cell, idx_rad_arrow_cell+1) for radial.
            % Data arrays are indexed 1 to nx_plot, 1 to ny_plot.
            
            pol_flux_val = fna_pol_data(idx_pol_arrow_cell, idx_rad_arrow_cell);
            rad_flux_val = fna_rad_data(idx_pol_arrow_cell, idx_rad_arrow_cell);
            density_val_cell1 = density_data(idx_pol_arrow_cell, idx_rad_arrow_cell);
            volume_val_cell1 = vol_data_plot(idx_pol_arrow_cell, idx_rad_arrow_cell);
            particle_count_cell1 = density_val_cell1 * volume_val_cell1;
            % density_val_cell2 (poloidal neighbor)
            % density_val_cell3 (radial neighbor)
            
            actual_arrow_x = x_arrow_q_centers(idx_pol_arrow_cell);
            actual_arrow_y = y_arrow_q_centers(idx_rad_arrow_cell);
            flux_mag_val = sqrt(pol_flux_val^2 + rad_flux_val^2);

            output_txt = {sprintf('Arrow near Cell (ix, iy): (%d, %d)', idx_pol_arrow_cell, idx_rad_arrow_cell), ...
                          sprintf('  Arrow Center Coords: (X=%.2f, Y=%.2f)', actual_arrow_x, actual_arrow_y), ...
                          sprintf('  Density (tail cell): %.3e m^{-3}', density_val_cell1), ...
                          sprintf('  Volume (tail cell): %.3e m^3', volume_val_cell1), ...
                          sprintf('  Particles (tail cell): %.3e', particle_count_cell1), ...
                          sprintf('  Poloidal Flux: %.3e s^{-1}', pol_flux_val), ...
                          sprintf('  Radial Flux: %.3e s^{-1}', rad_flux_val), ...
                          sprintf('  Flux Magnitude: %.3e s^{-1}', flux_mag_val)};
        else
            output_txt = {'Quiver data not available for this grid size.'};
        end
    else % Fallback for other targets or if logic is complex
        ix_surf = round(x_clicked);
        iy_surf = round(y_clicked);
        validated_ix_surf = max(1, min(ix_surf, nx_p));
        validated_iy_surf = max(1, min(iy_surf, ny_p));
        density_val = density_data(validated_ix_surf, validated_iy_surf);
        volume_val = vol_data_plot(validated_ix_surf, validated_iy_surf);
        particle_count_val = density_val * volume_val;
        output_txt = {sprintf('Cell (ix, iy): (%d, %d)', validated_ix_surf, validated_iy_surf), ...
                      sprintf('  Density: %.3e m^{-3}', density_val), ...
                      sprintf('  Volume: %.3e m^3', volume_val), ...
                      sprintf('  Particles in Cell: %.3e', particle_count_val), ...
                      sprintf('  (Flux data interpretation complex for this click)')};
    end
end 
