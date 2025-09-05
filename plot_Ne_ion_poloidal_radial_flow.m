function plot_Ne_ion_poloidal_radial_flow(all_radiationData)
% PLOT_NE_ION_POLOIDAL_RADIAL_FLOW 绘制各价态Ne离子的极向和径向流分布
%
%   此函数为每个提供的SOLPS算例数据，针对每种Ne离子价态，
%   绘制计算网格中的极向流和径向流分布。
%   每个价态生成一个figure，包含两个子图：
%   - 左子图：极向流分布
%   - 右子图：径向流分布
%   基于 plot_impurity_charge_state_flow_pattern.m 修改。
%
%   参数:
%     all_radiationData - 包含所有SOLPS仿真数据的结构体数组，
%                         每个结构体至少需要包含 'dirName', 'gmtry', 'plasma' 字段。

    %%%% 全局字体和绘图属性设置
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');
    set(0, 'DefaultAxesFontSize', 14);
    set(0, 'DefaultTextFontSize', 14);
    set(0, 'DefaultLineLineWidth', 1.5);
    set(0, 'DefaultUicontrolFontName', 'Times New Roman');
    set(0, 'DefaultUitableFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontName', 'Times New Roman');
    set(0, 'DefaultLegendFontSize', 14);
    set(0, 'DefaultTextInterpreter', 'latex');
    set(0, 'DefaultAxesTickLabelInterpreter', 'latex');
    set(0, 'DefaultLegendInterpreter', 'latex');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'latex');

    % 自定义字体大小设置
    colorbar_label_fontsize = 14;      % colorbar标签字体大小
    colorbar_tick_fontsize = 36;       % colorbar数字字体大小
    axis_label_fontsize = 14;          % 坐标轴标签字体大小
    axis_tick_fontsize = 32;           % 坐标轴刻度数字字体大小
    region_label_fontsize = 18;        % 区域标签字体大小

    for i_case = 1:length(all_radiationData)
        radData = all_radiationData{i_case};
        gmtry = radData.gmtry;
        plasma = radData.plasma;
        dirName = radData.dirName;

        fprintf('Processing case for Ne ion poloidal and radial flow: %s\n', dirName);

        %%%% 获取原始网格维度
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

        %%%% 计算用于绘图的网格维度 (去除保护单元)
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
            charge_state = i_species - (min_species_idx - 1); % 例如，物种4对应1+

            fprintf('  Processing charge state Ne%d+ (species index %d) for case: %s\n', charge_state, i_species, dirName);

            %%%% 计算特定价态的粒子通量 (基于原始完整数据)
            % fna_mdf(ix,iy,direction,species), direction: 1=极向, 2=径向
            if size(plasma.fna_mdf, 4) < i_species
                warning('Case %s, Species %d (Ne%d+): Not enough species in plasma.fna_mdf (max index %d). Skipping this charge state.', ...
                        dirName, i_species, charge_state, size(plasma.fna_mdf, 4));
                continue; % 跳过此价态
            end

            fna_pol_single_species_full = plasma.fna_mdf(:, :, 1, i_species);
            fna_rad_single_species_full = plasma.fna_mdf(:, :, 2, i_species);

            %%%% 切片通量数据以去除保护单元
            fna_pol_plot = fna_pol_single_species_full(2:nx_orig-1, 2:ny_orig-1);
            fna_rad_plot = fna_rad_single_species_full(2:nx_orig-1, 2:ny_orig-1);

            %%%% 创建图形 - 包含两个子图
            fig_title_name = sprintf('Ne%d+ Poloidal and Radial Flow - %s', charge_state, dirName);
            figure('Name', fig_title_name, ...
                   'NumberTitle', 'off', 'Color', 'w', ...
                   'Units', 'inches', 'Position', [1, 1, 24, 12]);

            % 创建坐标网格（两个子图共用）
            x_coords_plot = 1:nx_plot;
            y_coords_plot = 1:ny_plot;
            [X_mesh_main, Y_mesh_main] = meshgrid(x_coords_plot, y_coords_plot);

            %%%% 子图1: 极向流分布
            subplot(1, 2, 1);
            ax1 = gca;
            hold(ax1, 'on');

            % 绘制背景色图 (极向流) - 使用线性映射
            surf(ax1, X_mesh_main, Y_mesh_main, zeros(size(X_mesh_main)), fna_pol_plot', 'EdgeColor', 'none');
            shading(ax1, 'interp');
            view(ax1, 2);
            h_cb1 = colorbar(ax1);

            ylabel(h_cb1, sprintf('Ne$^{%d+}$ Poloidal Flow', charge_state), 'FontSize', colorbar_label_fontsize, 'Interpreter', 'latex');
            % 设置colorbar数字字体大小
            set(h_cb1, 'FontSize', colorbar_tick_fontsize);
            colormap(ax1, 'jet');
            set(ax1, 'YDir', 'normal');

            % 添加区域划分和标签
            addRegionLabels(ax1, nx_plot, ny_plot, region_label_fontsize);

            % 设置坐标轴和标题
            xlabel(ax1, '$\mathrm{i_x}$ (Poloidal Cell Index)', 'FontSize', axis_label_fontsize, 'Interpreter', 'latex');
            ylabel(ax1, '$\mathrm{i_y}$ (Radial Cell Index)', 'FontSize', axis_label_fontsize, 'Interpreter', 'latex');

            axis(ax1, [1, nx_plot, 1, ny_plot]);
            setAxisTicks(ax1, nx_plot, ny_plot);
            % 设置坐标轴刻度数字字体大小
            set(ax1, 'FontSize', axis_tick_fontsize);
            box(ax1, 'on');
            grid(ax1, 'off');
            hold(ax1, 'off');

            %%%% 子图2: 径向流分布
            subplot(1, 2, 2);
            ax2 = gca;
            hold(ax2, 'on');

            % 绘制背景色图 (径向流) - 使用线性映射
            surf(ax2, X_mesh_main, Y_mesh_main, zeros(size(X_mesh_main)), fna_rad_plot', 'EdgeColor', 'none');
            shading(ax2, 'interp');
            view(ax2, 2);
            h_cb2 = colorbar(ax2);

            ylabel(h_cb2, sprintf('Ne$^{%d+}$ Radial Flow', charge_state), 'FontSize', colorbar_label_fontsize, 'Interpreter', 'latex');
            % 设置colorbar数字字体大小
            set(h_cb2, 'FontSize', colorbar_tick_fontsize);
            colormap(ax2, 'jet');
            set(ax2, 'YDir', 'normal');

            % 添加区域划分和标签
            addRegionLabels(ax2, nx_plot, ny_plot, region_label_fontsize);

            % 设置坐标轴和标题
            xlabel(ax2, '$\mathrm{i_x}$ (Poloidal Cell Index)', 'FontSize', axis_label_fontsize, 'Interpreter', 'latex');
            ylabel(ax2, '$\mathrm{i_y}$ (Radial Cell Index)', 'FontSize', axis_label_fontsize, 'Interpreter', 'latex');

            axis(ax2, [1, nx_plot, 1, ny_plot]);
            setAxisTicks(ax2, nx_plot, ny_plot);
            % 设置坐标轴刻度数字字体大小
            set(ax2, 'FontSize', axis_tick_fontsize);
            box(ax2, 'on');
            grid(ax2, 'off');
            hold(ax2, 'off');

            %%%% 保存图像
            saveFigureWithTimestamp(gcf, sprintf('Ne%d_PoloidalRadialFlow_%s', charge_state, createSafeFilename(dirName)));
        
        end % 结束物种循环
    end % 结束算例循环
end % 结束主函数

function addRegionLabels(ax, nx_plot, ny_plot, label_font_size)
    % 添加区域划分和标签的辅助函数
    isep_idx_fixed = 12;
    inner_div_pol_end_fixed = 24;
    omp_pol_idx_fixed       = 41;
    imp_pol_idx_fixed       = 58;
    outer_div_pol_start_fixed = 73;

    plot(ax, [inner_div_pol_end_fixed + 1, inner_div_pol_end_fixed + 1], [1, ny_plot], 'k--', 'LineWidth', 1.0);
    plot(ax, [outer_div_pol_start_fixed, outer_div_pol_start_fixed], [1, ny_plot], 'k--', 'LineWidth', 1.0);
    plot(ax, [omp_pol_idx_fixed, omp_pol_idx_fixed], [1, ny_plot], 'k--', 'LineWidth', 1.0);
    plot(ax, [imp_pol_idx_fixed, imp_pol_idx_fixed], [1, ny_plot], 'k--', 'LineWidth', 1.0);
    plot(ax, [1, nx_plot], [isep_idx_fixed + 1, isep_idx_fixed + 1], 'k-', 'LineWidth', 1.5);

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
end

function setAxisTicks(ax, nx_plot, ny_plot)
    % 设置坐标轴刻度的辅助函数
    isep_idx_fixed = 12;
    inner_div_pol_end_fixed = 24;
    omp_pol_idx_fixed       = 41;
    imp_pol_idx_fixed       = 58;
    outer_div_pol_start_fixed = 73;
    
    set(ax, 'XTick', unique(sort([1, inner_div_pol_end_fixed, omp_pol_idx_fixed, imp_pol_idx_fixed, outer_div_pol_start_fixed, nx_plot])));
    set(ax, 'YTick', unique(sort([1, isep_idx_fixed, ny_plot])));
end

function safeName = createSafeFilename(originalName)
    % 创建安全的文件名，替换特殊字符
    safeName = regexprep(originalName, '[^a-zA-Z0-9_\-\.]', '_');
    if strlength(safeName) > 100
        safeName = safeName(1:100);
    end
end

function saveFigureWithTimestamp(figHandle, baseName)
    % 保存带时间戳的图形文件
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
