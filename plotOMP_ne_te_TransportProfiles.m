function plotOMP_ne_te_TransportProfiles(all_radiationData, groupDirs, usePresetLegends)
    % 绘制上游外中平面电子密度、电子温度和输运系数的径向分布比较图
    % 输入参数与plot_3x3_subplots相同
    % usePresetLegends: 逻辑值，指示是否使用预设图例名称

    % ================== 预定义参数 ==================
    line_colors = lines(20);
    font_size = 32;  % 增大字体大小到32
    xlabel_font_size = 50;  % 特别增大xlabel的字体大小
    sep_color = [0.5 0.5 0.5];
    sep_style = '--';
    preset_legend_names = {'fav. $B_{\mathrm{T}}$', 'unfav. $B_{\mathrm{T}}$', 'w/o drift'};

    % ================== 输运系数数据 ==================
    r_rsep_D_n = [-5.00E-02, -1.90E-02, -1.60E-02, -1.40E-02, -0.20E-02, 0.00E-02,  0.10E-02,  0.40E-02,  1.50E-02,  3.00E-02];
    r_rsep_X = [-5.00E-02, -2.75E-02, -1.60E-02, -1.40E-02, -0.20E-02, 0.00E-02,  0.10E-02,  0.80E-02,  1.50E-02,  3.00E-02];
    D_n = [2.50, 2.50, 1.50, 0.90, 1.10, 1.50, 3.00, 3.50, 4.00, 4.00];
    X_i = [2.60, 2.60, 1.40, 0.90, 0.90, 1.10, 3.00, 3.50, 4.00, 4.00];
    X_e = [2.60, 2.60, 1.40, 1.00, 1.00, 1.40, 3.00, 3.50, 4.00, 4.00];
    
    % ================== 对输运系数数据进行线性插值 ==================
    % 创建更密集的插值点集
    r_interp = linspace(-0.05, 0.03, 500);
    
    % 使用线性插值
    D_n_interp = interp1(r_rsep_D_n, D_n, r_interp, 'linear', 'extrap');
    X_i_interp = interp1(r_rsep_X, X_i, r_interp, 'linear', 'extrap');
    X_e_interp = interp1(r_rsep_X, X_e, r_interp, 'linear', 'extrap');
    
    % 固定的横轴范围
    x_axis_range = [-0.025, 0.025];
    % 固定的横轴刻度点
    x_axis_ticks = [-0.025, -0.0125, 0, 0.0125, 0.025];

    % ================== 遍历每组 ==================
    for g = 1:length(groupDirs)
        currentGroup = groupDirs{g};
        
        % 创建图形窗口
        fig = figure('Name', sprintf('Outer Midplane Comparison - Group %d', g), ...
                    'Color', 'w', ...
                    'Position', [100 100 1200 1500]);  % 调整图形尺寸更大

        % 设置全局字体
        set(gcf, 'DefaultAxesFontName', 'Times New Roman');
        set(gcf, 'DefaultTextFontName', 'Times New Roman');

        % 使用subplot创建三个紧密贴合的子图
        ax1 = subplot(3,1,1); hold on;
        ax2 = subplot(3,1,2); hold on;
        ax3 = subplot(3,1,3); hold on;
        
        % 确保所有子图的box属性都是on
        set([ax1, ax2, ax3], 'Box', 'on');

        % 调整子图间距，使其紧密贴合
        % 设置第一个子图位置
        pos1 = [0.15 0.7 0.80 0.25];
        % 第二个子图的顶部应该与第一个子图的底部精确重合
        pos2 = [0.15 pos1(2)-0.25 0.80 0.25];
        % 第三个子图的顶部应该与第二个子图的底部精确重合
        pos3 = [0.15 pos2(2)-0.25 0.80 0.25];
        
        set(ax1, 'Position', pos1);
        set(ax2, 'Position', pos2);
        set(ax3, 'Position', pos3);

        % ========== 初始化图例参数 ==========
        ax1_handles = gobjects(0);
        ax1_entries = {};
        ax2_handles = gobjects(0);
        ax2_entries = {};
        ax3_handles = gobjects(0);
        ax3_entries = {};
        
        % 用于存储所有x_upstream数据的矩阵，以确定ne、te的实际横坐标范围
        all_x_upstream = [];

        % ========== 遍历组内目录 ==========
        for k = 1:length(currentGroup)
            currentDir = currentGroup{k};
            idx = findDirIndexInRadiationData(all_radiationData, currentDir);
            if idx < 0, continue; end
            data = all_radiationData{idx};

            % 获取物理坐标
            gmtry = data.gmtry;
            outer_j = 42;
            [x_upstream, ~] = calculate_separatrix_coordinates(gmtry, outer_j);
            
            % 收集所有的横坐标数据用于后续确定有物理量的横坐标范围
            all_x_upstream = [all_x_upstream; x_upstream];

            % 提取数据
            ne = data.plasma.ne(outer_j, :);
            te = data.plasma.te_ev(outer_j, :);

            % 设置图例名称
            if usePresetLegends && (k <= length(preset_legend_names))
                shortName = preset_legend_names{k};
            else
                shortName = getShortDirName(data.dirName);
            end
            lineColor = line_colors(mod(k-1, size(line_colors,1)) + 1, :);

            % 绘制密度和温度
            h1 = plot(ax1, x_upstream, ne, '-', ...
                     'Color', lineColor, ...
                     'LineWidth', 1.5, ...
                     'DisplayName', shortName);
            set(h1, 'UserData', currentDir);

            h2 = plot(ax2, x_upstream, te, '-', ...
                     'Color', lineColor, ...
                     'LineWidth', 1.5, ...
                     'DisplayName', shortName);
            set(h2, 'UserData', currentDir);

            % 保存图例参数
            ax1_handles(end+1) = h1;
            ax1_entries{end+1} = shortName;
            ax2_handles(end+1) = h2;
            ax2_entries{end+1} = shortName;
        end
        
        % ========== 根据ne和te数据确定实际的横坐标范围 ==========
        if ~isempty(all_x_upstream)
            % 计算所有ne、te数据的实际横坐标范围
            x_min_data = min(all_x_upstream(:));
            x_max_data = max(all_x_upstream(:));
            
            % 截取插值后的输运系数数据，只保留ne、te横坐标范围内的数据
            valid_idx_interp = r_interp >= x_min_data & r_interp <= x_max_data;
            r_interp_valid = r_interp(valid_idx_interp);
            D_n_interp_valid = D_n_interp(valid_idx_interp);
            X_i_interp_valid = X_i_interp(valid_idx_interp);
            X_e_interp_valid = X_e_interp(valid_idx_interp);
            
            % ========== 绘制插值和截取后的输运系数 ==========
            h3_Dn = plot(ax3, r_interp_valid, D_n_interp_valid, 'k-', 'LineWidth', 1.5, 'DisplayName', '$D_{\mathrm{n}}$');
            h3_Xi = plot(ax3, r_interp_valid, X_i_interp_valid, 'b-', 'LineWidth', 1.5, 'DisplayName', '$\chi_{\mathrm{i}}$');
            h3_Xe = plot(ax3, r_interp_valid, X_e_interp_valid, 'r-', 'LineWidth', 1.5, 'DisplayName', '$\chi_{\mathrm{e}}$');
        else
            % 如果没有ne、te数据，则使用全部插值后的输运系数数据
            h3_Dn = plot(ax3, r_interp, D_n_interp, 'k-', 'LineWidth', 1.5, 'DisplayName', '$D_{\mathrm{n}}$');
            h3_Xi = plot(ax3, r_interp, X_i_interp, 'b-', 'LineWidth', 1.5, 'DisplayName', '$\chi_{\mathrm{i}}$');
            h3_Xe = plot(ax3, r_interp, X_e_interp, 'r-', 'LineWidth', 1.5, 'DisplayName', '$\chi_{\mathrm{e}}$');
        end

        ax3_handles = [h3_Dn, h3_Xi, h3_Xe];
        ax3_entries = {'$D_{\mathrm{n}}$', '$\chi_{\mathrm{i}}$', '$\chi_{\mathrm{e}}$'};

        % ========== 图形设置 ==========
        for ax = [ax1, ax2, ax3]
            % 绘制分离面参考线
            plot(ax, [0 0], ylim(ax), 'LineStyle', sep_style, ...
                 'Color', sep_color, 'LineWidth', 1.2);

            % 网格和边框设置
            grid(ax, 'on');
            set(ax, 'FontSize', font_size, 'Layer', 'top');
            
            % 设置固定的横轴范围和刻度
            xlim(ax, x_axis_range);
            set(ax, 'XTick', x_axis_ticks);
            
            % 上面两个子图不显示刻度值
            if ax ~= ax3
                set(ax, 'XTickLabel', []);
            end

            % 针对不同子图进行特殊设置
            if ax == ax2 % 中间子图
                ylim(ax, [0, 500]);
                yticks = [0, 100, 200, 300, 400, 500];
                set(ax, 'YTick', yticks);
                % 不显示最大值500
                set(ax, 'YTickLabel', {'0', '100', '200', '300', '400', ''})
            elseif ax == ax3 % 底部子图
                ylim(ax, [0, 5]);
                yticks = [0, 1, 2, 3, 4, 5];
                set(ax, 'YTick', yticks);
                % 不显示最大值5
                set(ax, 'YTickLabel', {'0', '1', '2', '3', '4', ''});
            else
                % 顶部子图保持原有设置
                y_lim = ylim(ax);
                y_lim(1) = floor(y_lim(1)*10)/10;
                y_lim(2) = ceil(y_lim(2)*10)/10;
                ylim(ax, y_lim);
                set(ax, 'YTick', linspace(y_lim(1), y_lim(2), 5));
            end
        end

        % 设置标签和图例
        ylabel(ax1, '$n_{\mathrm{e}}$ (m$^{-3}$)', 'FontSize', font_size, 'Interpreter', 'latex');
        ylabel(ax2, '$T_{\mathrm{e}}$ (eV)', 'FontSize', font_size, 'Interpreter', 'latex');
        ylabel(ax3, '$D_{\mathrm{n}}$, $\chi_{\mathrm{i}}$, $\chi_{\mathrm{e}}$ (m$^{2}$/s)', 'FontSize', font_size, 'Interpreter', 'latex');
        
        % 只在底部子图显示x轴标签，使用更大的字体大小
        xlabel(ax3, '$r - r_{\mathrm{sep}}$ (m)', 'FontSize', xlabel_font_size, 'Interpreter', 'latex');

        % 设置图例
        legend(ax1, ax1_handles, ax1_entries, 'Location', 'northwest', 'Interpreter', 'latex', 'FontSize', font_size);
        legend(ax2, ax2_handles, ax2_entries, 'Location', 'northwest', 'Interpreter', 'latex', 'FontSize', font_size);
        legend(ax3, ax3_handles, ax3_entries, 'Location', 'northwest', 'Interpreter', 'latex', 'FontSize', font_size);

        % 同步横轴范围
        linkaxes([ax1, ax2, ax3], 'x');

        % 设置Data Cursor
        dcm = datacursormode(gcf);
        set(dcm, 'UpdateFcn', @myDataCursorUpdateFcn);

        % 保存图形
        saveFigureWithTimestamp(sprintf('OMP_ne_te_TransportProfiles_group%d', g));
    end
end

function [x_upstream, separatrix] = calculate_separatrix_coordinates(gmtry, outer_j)
    Y = gmtry.hy(outer_j, :);
    W = [0.5*Y(1), 0.5*(Y(2:end)+Y(1:end-1))];
    hy_center = cumsum(W);
    separatrix = (hy_center(14) + hy_center(15)) / 2;
    x_upstream = hy_center - separatrix;
end

function idx = findDirIndexInRadiationData(all_radiationData, dirName)
    idx = -1;
    for i = 1:length(all_radiationData)
        if strcmp(all_radiationData{i}.dirName, dirName)
            idx = i;
            return;
        end
    end
end

function shortName = getShortDirName(fullPath)
    parts = strsplit(fullPath, filesep);
    shortName = parts{end};
end

function saveFigureWithTimestamp(baseName)
    % 调整保存图形的尺寸与显示尺寸一致（宽度更大，例如 1800）
    fig_width_save = 1800; %  保存时使用更大的宽度
    fig_height_save = fig_width_save * (9/12); % 保持比例
    set(gcf,'Units','pixels','Position',[100 50 fig_width_save fig_height_save]); % 同步修改宽度为1800, 高度按比例调整
    set(gcf,'PaperPositionMode','auto');
    timestampStr = datestr(now,'yyyymmdd_HHMMSS');
    outFile = sprintf('%s_%s.fig', baseName, timestampStr);
    savefig(outFile);
    fprintf('Figure saved: %s\n', outFile);
end
function txt = myDataCursorUpdateFcn(~, event_obj)
    pos = get(event_obj,'Position');
    target = get(event_obj,'Target');
    dirPath = get(target,'UserData');
    
    % 创建数据光标文本内容
    if ~isempty(dirPath)
        txt = {
            ['$X$: ', num2str(pos(1))],...
            ['$Y$: ', num2str(pos(2))],...
            ['Dir: ', dirPath]
        };
    else
        txt = {
            ['$X$: ', num2str(pos(1))],...
            ['$Y$: ', num2str(pos(2))]
        };
    end
    
    % 设置数据光标的解释器为LaTeX
    set(event_obj, 'Interpreter', 'latex');
end