function plot_OMP_IMP_impurity_distribution(all_radiationData, groupDirs, usePresetLegends)
    % Plot comparison of density, temperature and nitrogen (N) impurity ion density at OMP and IMP
    % OMP: Outer Midplane, IMP: Inner Midplane
    % Input parameters:
    %   all_radiationData: Cell array containing radiation data
    %   groupDirs: Cell array of cell arrays, each containing directories to be grouped
    %   usePresetLegends: Logical, indicates whether to use preset legend names (optional)
    
    % If usePresetLegends is not provided, default to false
    if nargin < 3
        usePresetLegends = false;
    end

    % ================== Predefined parameters ==================
    line_colors = lines(20);
    line_markers = {'o','s','d','^','v','>','<','p','h','*','+','x'};
    xlabelsize = 24; % Increased label font size
    ylabelsize = 24; % Increased label font size
    legendsize = 24; % Increased legend font size
    tick_fontsize = 24; % Increased tick font size
    sep_color = [0.5 0.5 0.5]; % Separatrix line color
    sep_style = '--';
    preset_legend_names = {'fav. $B_\mathrm{T}$', 'unfav. $B_\mathrm{T}$', 'w/o drift'}; % Preset legend names using LaTeX
    
    % Set global default font to Times New Roman
    set(0, 'DefaultAxesFontName', 'Times New Roman');
    set(0, 'DefaultTextFontName', 'Times New Roman');

    % ================== Loop through each group ==================
    for g = 1:length(groupDirs)
        currentGroup = groupDirs{g};
        % Adjust figure size: increase width to 1200, keep height at 900
        fig = figure('Name',sprintf('OMP & IMP Nitrogen Impurity Distribution - Group %d',g),...
                     'Color','w','Position',[100 100 1200 900]); % Width modified to 1200

        % Create 2x2 subplots
        ax1 = subplot(2,2,1); hold on; % OMP ne
        ax2 = subplot(2,2,2); hold on; % OMP te
        ax3 = subplot(2,2,3); hold on; % OMP n_N_tot (nitrogen impurity)
        ax4 = subplot(2,2,4); hold on; % IMP n_N_tot (nitrogen impurity)

        % ========== Initialize legend parameters ==========
        ax1_handles = gobjects(0);
        ax1_entries = {};
        ax2_handles = gobjects(0);
        ax2_entries = {};
        ax3_handles = gobjects(0);
        ax3_entries = {};
        ax4_handles = gobjects(0);
        ax4_entries = {};

        % ========== Loop through directories in group ==========
        for k = 1:length(currentGroup)
            currentDir = currentGroup{k};
            idx = findDirIndexInRadiationData(all_radiationData, currentDir);
            if idx < 0, continue; end
            data = all_radiationData{idx};

            % Get physical coordinates
            gmtry = data.gmtry;

            % 原始网格索引（包含保护单元）
            outer_j_original = 42; % 外中平面索引 (OMP) - 原始网格
            inner_j_original = 59; % 内中平面索引 (IMP) - 原始网格

            % 转换为裁剪网格索引（去除保护单元后）
            outer_j_cropped = outer_j_original - 1; % 裁剪网格中的索引（原始索引-1）
            inner_j_cropped = inner_j_original - 1; % 裁剪网格中的索引（原始索引-1）

            [x_upstream_omp, ~] = calculate_separatrix_coordinates(gmtry, outer_j_original);
            [x_upstream_imp, ~] = calculate_separatrix_coordinates(gmtry, inner_j_original);

            % 创建去除保护单元的2D数据
            ne_2D = data.plasma.ne(2:end-1, 2:end-1);
            te_2D = data.plasma.te_ev(2:end-1, 2:end-1);
            na_2D = data.plasma.na(2:end-1, 2:end-1, :);

            % 提取OMP数据（使用裁剪网格索引）
            ne_omp = ne_2D(outer_j_cropped, :);
            te_omp = te_2D(outer_j_cropped, :);

            % 动态确定氮(N)杂质离子价态的索引范围
            % 氮的原子序数为7，所以氮离子价态为N1+到N7+
            num_species = size(na_2D, 3);
            if num_species >= 10
                % 如果有足够的价态，使用N1+到N7+（索引4-10）
                impurity_indices = 4:10;
            elseif num_species >= 7
                % 如果价态数较少，使用从N1+开始到数组末尾
                impurity_indices = 4:num_species;
            else
                % 如果价态数更少，使用从第4个开始到最后
                impurity_indices = 4:num_species;
            end

            % 计算氮杂质离子总密度：统计N1+到N7+价态，不包含中性粒子
            n_imp_tot_omp = sum(na_2D(outer_j_cropped, :, impurity_indices), 3); % 对氮杂质离子价态求和

            % 提取IMP数据（使用裁剪网格索引）
            % 计算氮杂质离子总密度：使用相同的价态索引范围
            n_imp_tot_imp = sum(na_2D(inner_j_cropped, :, impurity_indices), 3); % 对氮杂质离子价态求和

            % Get short directory name
            shortName = getShortDirName(data.dirName);
            
            % Set legend name
            if usePresetLegends && (k <= length(preset_legend_names))
                shortName = preset_legend_names{k}; % Use preset legend name based on k index
            end

            % ====== Assign color and marker ======
            color_idx = mod(k-1, size(line_colors,1)) + 1;

            % ====== Plot OMP data ======
            if usePresetLegends && (k <= length(preset_legend_names))
                h1 = plot(ax1, x_upstream_omp, ne_omp, '-',...
                        'LineWidth', 1.5,...
                        'DisplayName', shortName);
            else
                h1 = plot(ax1, x_upstream_omp, ne_omp, '-',...
                        'Color', line_colors(color_idx,:),...
                        'LineWidth', 1.5,...
                        'DisplayName', shortName);
            end
            set(h1, 'UserData', currentDir);

            if usePresetLegends && (k <= length(preset_legend_names))
                h2 = plot(ax2, x_upstream_omp, te_omp, '-',...
                        'LineWidth', 1.5,...
                        'DisplayName', shortName);
            else
                h2 = plot(ax2, x_upstream_omp, te_omp, '-',...
                        'Color', line_colors(color_idx,:),...
                        'LineWidth', 1.5,...
                        'DisplayName', shortName);
            end
            set(h2, 'UserData', currentDir);

            if usePresetLegends && (k <= length(preset_legend_names))
                h3 = plot(ax3, x_upstream_omp, n_imp_tot_omp, '-',...
                        'LineWidth', 1.5,...
                        'DisplayName', shortName);
            else
                h3 = plot(ax3, x_upstream_omp, n_imp_tot_omp, '-',...
                        'Color', line_colors(color_idx,:),...
                        'LineWidth', 1.5,...
                        'DisplayName', shortName);
            end
            set(h3, 'UserData', currentDir);

            % ====== Plot IMP data ======
            if usePresetLegends && (k <= length(preset_legend_names))
                h4 = plot(ax4, x_upstream_imp, n_imp_tot_imp, '-',...
                        'LineWidth', 1.5,...
                        'DisplayName', shortName);
            else
                h4 = plot(ax4, x_upstream_imp, n_imp_tot_imp, '-',...
                        'Color', line_colors(color_idx,:),...
                        'LineWidth', 1.5,...
                        'DisplayName', shortName);
            end
            set(h4, 'UserData', currentDir);

            % Save legend parameters
            ax1_handles(end+1) = h1;
            ax1_entries{end+1} = shortName;
            ax2_handles(end+1) = h2;
            ax2_entries{end+1} = shortName;
            ax3_handles(end+1) = h3;
            ax3_entries{end+1} = shortName;
            ax4_handles(end+1) = h4;
            ax4_entries{end+1} = shortName;
        end

        % ========== Figure settings ==========
        % Common settings for first three subplots (OMP-related)
        for ax = [ax1, ax2, ax3]
            % Draw separatrix reference line
            plot(ax, [0 0], ylim(ax), 'LineStyle', sep_style,...
                'Color', sep_color, 'LineWidth', 1.2);

            % Grid and border settings
            grid(ax, 'on');
            box(ax, 'on'); % Enable border
            set(ax, 'FontSize', tick_fontsize, 'Layer', 'top', 'FontName', 'Times New Roman'); % Ensure ticks are on top layer with Times New Roman font

            % Force x-axis ticks to include limit values
            xlim(ax, [-0.03, 0.03]);
            set(ax, 'XTick', -0.03:0.01:0.03); % Ensure all ticks including boundary values are displayed

            % Optimize y-axis tick display
            y_lim = ylim(ax);
            y_lim(1) = floor(y_lim(1)*10)/10; % Round down to nearest 0.1 multiple
            y_lim(2) = ceil(y_lim(2)*10)/10;  % Round up to nearest 0.1 multiple
            ylim(ax, y_lim);
            set(ax, 'YTick', linspace(y_lim(1), y_lim(2), 5)); % Generate 5 evenly spaced ticks

        end

        % Separate settings for fourth subplot (IMP-related)
        % Draw separatrix reference line
        plot(ax4, [0 0], ylim(ax4), 'LineStyle', sep_style,...
            'Color', sep_color, 'LineWidth', 1.2);

        % Grid and border settings
        grid(ax4, 'on');
        box(ax4, 'on');
        set(ax4, 'FontSize', tick_fontsize, 'Layer', 'top', 'FontName', 'Times New Roman');

        % IMP plot uses wider x-axis range
        xlim(ax4, [-0.06, 0.06]);
        set(ax4, 'XTick', -0.06:0.02:0.06);

        % Optimize y-axis tick display
        y_lim = ylim(ax4);
        y_lim(1) = floor(y_lim(1)*10)/10;
        y_lim(2) = ceil(y_lim(2)*10)/10;
        ylim(ax4, y_lim);
        set(ax4, 'YTick', linspace(y_lim(1), y_lim(2), 5));

        % Subplot 1 settings (OMP density)
        xlabel(ax1, '$r - r_{\mathrm{sep}}$ (m)', 'FontSize', xlabelsize, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        ylabel(ax1, '$n_{e}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        
        lg1 = legend(ax1, ax1_handles, ax1_entries, 'Location', 'best', 'Interpreter', 'latex');
        set(lg1, 'FontName', 'Times New Roman', 'FontSize', legendsize);

        % Subplot 2 settings (OMP electron temperature)
        xlabel(ax2, '$r - r_{\mathrm{sep}}$ (m)', 'FontSize', xlabelsize, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        ylabel(ax2, '$T_{e}$ (eV)', 'FontSize', ylabelsize, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        
        lg2 = legend(ax2, ax2_handles, ax2_entries, 'Location', 'best', 'Interpreter', 'latex');
        set(lg2, 'FontName', 'Times New Roman', 'FontSize', legendsize);

        % Subplot 3 settings (OMP nitrogen impurity ion density)
        xlabel(ax3, '$r - r_{\mathrm{sep}}$ (m)', 'FontSize', xlabelsize, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        ylabel(ax3, '$n_{\mathrm{N}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'FontName', 'Times New Roman', 'Interpreter', 'latex');

        lg3 = legend(ax3, ax3_handles, ax3_entries, 'Location', 'best', 'Interpreter', 'latex');
        set(lg3, 'FontName', 'Times New Roman', 'FontSize', legendsize);

        % Subplot 4 settings (IMP nitrogen impurity ion density)
        xlabel(ax4, '$r - r_{\mathrm{sep}}$ (m)', 'FontSize', xlabelsize, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        ylabel(ax4, '$n_{\mathrm{N}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        
        lg4 = legend(ax4, ax4_handles, ax4_entries, 'Location', 'best', 'Interpreter', 'latex');
        set(lg4, 'FontName', 'Times New Roman', 'FontSize', legendsize);

        % ----------------- Synchronize Y-axis range -----------------
        % Get current Y-axis range of two subplots
        ylim_omp = ylim(ax3);
        ylim_imp = ylim(ax4);
        % Take smaller lower limit and larger upper limit as unified range
        common_ylim = [min(ylim_omp(1), ylim_imp(1)), max(ylim_omp(2), ylim_imp(2))];
        % Synchronize Y-axis range for both subplots
        ylim(ax3, common_ylim);
        ylim(ax4, common_ylim);
        % Optional: Set unified ticks (e.g., 5)
        set(ax3, 'YTick', linspace(common_ylim(1), common_ylim(2), 5));
        set(ax4, 'YTick', linspace(common_ylim(1), common_ylim(2), 5));
        % ----------------------------------------------------------------

        % Synchronize x-axis range and apply final adjustments
        % linkaxes([ax1, ax2, ax3, ax4], 'x'); % Commented out or removed
        linkaxes([ax1, ax2, ax3], 'x'); % Only synchronize x-axis of first three plots

        % ========== Data Cursor mode (optional) ==========
        dcm = datacursormode(gcf);
        set(dcm,'UpdateFcn',@myDataCursorUpdateFcn);
        
        % Save
        saveFigureWithTimestamp(sprintf('OMP_IMP_nitrogen_impurity_distribution_Group%d', g));
    end
end

function [x_upstream, separatrix] = calculate_separatrix_coordinates(gmtry, plane_j)
    % 使用指定平面索引plane_j计算分离面坐标
    % 参考 plot_downstream_pol_profiles.m 的正确实现

    % 网格说明：
    % - 原始网格（包含保护单元）：98×28
    % - 裁剪网格（去除保护单元）：96×26，对应原始网格(2:97, 2:27)
    % - 分离面：位于裁剪网格12和13之间，即第12个网格的末端边界
    separatrix_radial_index = 12;  % 分离面所在的网格索引（裁剪网格中的径向索引）

    % 获取网格宽度（去除保护单元）
    Y = gmtry.hy(plane_j+1, 2:end-1);  % +1因为gmtry包含保护单元
    W = [0.5*Y(1), 0.5*(Y(2:end)+Y(1:end-1))];
    hy_center = cumsum(W);

    % 分离面位置：第12个网格的末端位置（12号和13号网格的交界面）
    % 第12个网格的中心位置加上半个网格宽度
    separatrix = hy_center(separatrix_radial_index) + 0.5*Y(separatrix_radial_index);
    x_upstream = hy_center - separatrix;
end


function idx = findDirIndexInRadiationData(all_radiationData, dirName)
    % Find index of directory in radiationData cell array
    idx = -1;
    for i = 1:length(all_radiationData)
        if strcmp(all_radiationData{i}.dirName, dirName)
            idx = i;
            return;
        end
    end
end

function shortName = getShortDirName(fullPath)
    % Extract the last part of the directory path as short name
    parts = strsplit(fullPath, filesep);
    shortName = parts{end};
end

function saveFigureWithTimestamp(baseName)
    % Adjust figure size to match display size (width 1200px)
    set(gcf,'Units','pixels','Position',[100 50 1200 900]); % Synchronized width at 1200px
    set(gcf,'PaperPositionMode','auto');
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    outFile = sprintf('%s_%s.fig', baseName, timestampStr);
    savefig(outFile);
    fprintf('Figure saved: %s\n', outFile);
end

function txt = myDataCursorUpdateFcn(~, event_obj)
    % Custom data cursor text update function
    pos = get(event_obj,'Position');
    target = get(event_obj,'Target');
    dirPath = get(target,'UserData');
    if ~isempty(dirPath)
        txt = {
            ['r - r_{sep}: ', num2str(pos(1)), ' m'],...
            ['y: ', num2str(pos(2))],...
            ['Dir: ', dirPath]
        };
    else
        txt = {
            ['r - r_{sep}: ', num2str(pos(1)), ' m'],...
            ['y: ', num2str(pos(2))]
        };
    end
end