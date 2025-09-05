function plot_OMP_IMP_impurity_distribution(all_radiationData, groupDirs, usePresetLegends)
    % Plot comparison of density, temperature and impurity ion density at OMP and IMP
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
        fig = figure('Name',sprintf('OMP & IMP Impurity Distribution - Group %d',g),...
                     'Color','w','Position',[100 100 1200 900]); % Width modified to 1200

        % Create 2x2 subplots
        ax1 = subplot(2,2,1); hold on; % OMP ne
        ax2 = subplot(2,2,2); hold on; % OMP te
        ax3 = subplot(2,2,3); hold on; % OMP n_imp_tot
        ax4 = subplot(2,2,4); hold on; % IMP n_imp_tot

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
            outer_j = 42; % Outer midplane index (OMP)
            inner_j = 59; % Inner midplane index (IMP)

            [x_upstream_omp, separatrix_omp] = calculate_separatrix_coordinates(gmtry, outer_j);
            [x_upstream_imp, separatrix_imp] = calculate_separatrix_coordinates(gmtry, inner_j);


            % Extract OMP data
            ne_omp = data.plasma.ne(outer_j, :);
            te_omp = data.plasma.te_ev(outer_j, :);
            n_imp_tot_omp = sum(data.plasma.na(outer_j, :, 4:end), 3); % Sum over all impurity charged states

            % Extract IMP data
            n_imp_tot_imp = sum(data.plasma.na(inner_j, :, 4:end), 3); % Sum over all impurity charged states

            % Get short directory name
            shortName = getShortDirName(data.dirName);
            
            % Set color and name
            lineColor = line_colors(mod(k-1, size(line_colors,1)) + 1, :);
            if usePresetLegends && (k <= length(preset_legend_names))
                shortName = preset_legend_names{k}; % Use preset legend name based on k index
            end

            % ====== Assign color and marker ======
            color_idx = mod(k-1, size(line_colors,1)) + 1;
            marker_idx = mod(k-1, length(line_markers)) + 1;

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
            set(ax, 'XTick', [-0.03:0.01:0.03]); % Ensure all ticks including boundary values are displayed

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
        set(ax4, 'XTick', [-0.06:0.02:0.06]);

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

        % Subplot 3 settings (OMP total impurity ion density)
        xlabel(ax3, '$r - r_{\mathrm{sep}}$ (m)', 'FontSize', xlabelsize, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        ylabel(ax3, '$n_{\mathrm{imp,tot}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        
        lg3 = legend(ax3, ax3_handles, ax3_entries, 'Location', 'best', 'Interpreter', 'latex');
        set(lg3, 'FontName', 'Times New Roman', 'FontSize', legendsize);

        % Subplot 4 settings (IMP total impurity ion density)
        xlabel(ax4, '$r - r_{\mathrm{sep}}$ (m)', 'FontSize', xlabelsize, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        ylabel(ax4, '$n_{\mathrm{imp,tot}}$ (m$^{-3}$)', 'FontSize', ylabelsize, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        
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
        saveFigureWithTimestamp(sprintf('OMP_IMP_impurity_distribution_Group%d', g));
    end
end

function [x_upstream, separatrix] = calculate_separatrix_coordinates(gmtry, plane_j)
    % Calculate separatrix coordinates using specified plane index plane_j
    Y = gmtry.hy(plane_j, :);
    W = [0.5*Y(1), 0.5*(Y(2:end)+Y(1:end-1))];
    hy_center = cumsum(W);
    separatrix = (hy_center(14) + hy_center(15)) / 2; % Assuming separatrix is between grid 14 and 15
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