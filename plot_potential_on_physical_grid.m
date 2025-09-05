function plot_potential_on_physical_grid(all_radiationData, domain)
    % =========================================================================
    % 功能：
    %   针对每个算例，在 2D 物理网格上绘制电势分布，并叠加内偏滤器和外偏滤器
    %   的固定极向位置线条，同时创建径向电势分布剖面图和分离面外第一个网格的极向电势分布。
    %
    % 输入参数：
    %   all_radiationData : cell 数组，每个元素包含至少：
    %       .dirName (string)   : 当前算例名称/目录名
    %       .gmtry   (struct)   : 与 read_b2fgmtry 类似的几何结构
    %       .plasma  (struct)   : 与 read_b2fplasmf 类似的等离子体数据(包含 po)
    %
    %   domain            : 用户选择的绘图区域 (0=全域, 1=上偏滤器, 2=下偏滤器)
    %
    % 输出图形：
    %   1. 2D电势分布图 + 内外偏滤器极向位置线条（内偏滤器实线，外偏滤器虚线）
    %   2. 径向电势分布剖面图（内偏滤器实线 + 外偏滤器虚线）
    %   3. 分离面内外网格的极向电势分布对比图（双子图）：
    %      - 上子图：分离面内网格(径向网格13)的极向电势分布，突出显示芯部区域(26-73)
    %      - 下子图：分离面外网格(径向网格14)的极向电势分布，突出显示主SOL区域(26-73)
    %
    % 依赖函数：
    %   - surfplot.m
    %   - plot3sep.m
    %   - saveFigureWithTimestamp (本脚本中附带)
    % =========================================================================

    %% ========================== 全局参数设置 ================================
    % 全局默认字体（运行期间一次设置即可）
    set(0,'DefaultAxesFontName','Times New Roman');
    set(0,'DefaultTextFontName','Times New Roman');

    fontSize = 32;          % 统一字体大小

    %% ======================== 遍历所有算例并绘图 ============================
    totalDirs = length(all_radiationData);
    for iDir = 1 : totalDirs

        % ------------------- 1) 获取当前算例数据 -------------------
        dataStruct   = all_radiationData{iDir};
        gmtry_tmp    = dataStruct.gmtry;
        plasma_tmp   = dataStruct.plasma;
        currentLabel = dataStruct.dirName;

        % 检查 'po' 字段是否存在
        if ~isfield(plasma_tmp, 'po')
            fprintf('Warning: Potential data (po) not found in case: %s. Skipping plot.\n', currentLabel);
            continue;
        end
        potential_data = plasma_tmp.po;

        % ------------------- 2) 创建图窗并设置全局字体 -------------------
        figName = sprintf('Potential Distribution: %s', currentLabel);
        figure('Name', figName, 'NumberTitle','off', 'Color','w',...
               'Units','pixels','Position',[100 50 1600 1200]);
        applyTimesFont(gcf, fontSize); % 统一字体

        hold on;

        % (2.1) 调用 surfplot 绘制电势分布
        surfplot(gmtry_tmp, potential_data);
        shading interp;
        view(2);
        % 使用默认jet colormap
        colormap(jet);

        % 固定colorbar范围为-150到150V
        caxis([-150, 150]);

        h_colorbar = colorbar;
        % 统一用 Label 属性设置（确保 LaTeX 正确渲染）
        h_colorbar.Label.String = '$\phi$ (V)';   % 若想显示词语可改成 '$\mathrm{Potential}~(V)$'
        h_colorbar.Label.Interpreter = 'latex';
        h_colorbar.Label.FontSize = fontSize-2;
        h_colorbar.Label.FontWeight = 'bold';
        h_colorbar.Label.FontName = 'Times New Roman';
        set(h_colorbar, 'FontSize', fontSize-6, 'LineWidth', 1.5, 'FontName','Times New Roman');

        % (2.3) 叠加分离器/结构
        plot3sep(gmtry_tmp, 'color','w','LineStyle','--','LineWidth',1.5);

        % (2.4) 设置标题及坐标轴标签 (恢复 LaTeX)
        xlabel('$R$ (m)', 'FontSize', fontSize, 'FontName','Times New Roman','Interpreter','latex');
        ylabel('$Z$ (m)', 'FontSize', fontSize, 'FontName','Times New Roman','Interpreter','latex');

        % (2.5) 设置坐标轴属性
        axis equal tight;
        box on;
        grid on;
        set(gca, 'FontSize', fontSize, 'FontName', 'Times New Roman', 'LineWidth', 1.5);

        % ------------------- 3) 根据 domain 裁剪绘制区域 -------------------
        if domain ~= 0
            switch domain
                case 1  % 上偏滤器示例区域
                    xlim([1.30, 2.00]);
                    ylim([0.50, 1.20]);
                case 2  % 下偏滤器示例区域
                    xlim([1.30, 2.05]);
                    ylim([-1.15, -0.40]);
            end

            if isfield(dataStruct, 'structure')
                plotstructure(dataStruct.structure, 'color', 'k', 'LineWidth', 2);
            end
        end

        %% =========================================================================
        %   叠加内偏滤器和外偏滤器固定极向位置线条到第一个图中
        % =========================================================================

        % 定义内偏滤器腿区域的极向网格范围
        iXpoint_inner = 74;  % 内偏滤器 X点
        inner_div_start = iXpoint_inner;  % 从X点开始
        inner_div_end = 97;   % 内偏滤器末端

        % 选择内偏滤器区域的多个固定极向位置进行径向分析
        poloidal_indices_inner = [74, 76, 80, 92];  % 内偏滤器区域的极向网格编号

        % 选择外偏滤器区域的多个固定极向位置进行径向分析
        poloidal_indices_outer = [7, 19, 24, 25];   % 外偏滤器区域的极向网格编号

        [nxd, nyd] = size(gmtry_tmp.crx);

        % 验证内偏滤器极向索引的有效性
        valid_inner = poloidal_indices_inner(poloidal_indices_inner >= inner_div_start & ...
                                           poloidal_indices_inner <= min(inner_div_end, nxd));
        if length(valid_inner) < length(poloidal_indices_inner)
            fprintf('Warning: Some inner divertor poloidal indices exceed grid bounds for case %s. Using valid indices: %s\n', ...
                    currentLabel, mat2str(valid_inner));
            poloidal_indices_inner = valid_inner;
        end

        % 验证外偏滤器极向索引的有效性
        valid_outer = poloidal_indices_outer(poloidal_indices_outer >= 1 & poloidal_indices_outer <= nxd);
        if length(valid_outer) < length(poloidal_indices_outer)
            fprintf('Warning: Some outer divertor poloidal indices exceed grid bounds for case %s. Using valid indices: %s\n', ...
                    currentLabel, mat2str(valid_outer));
            poloidal_indices_outer = valid_outer;
        end

        % 计算网格中心坐标
        [rCenter, zCenter] = computeCellCentersFromCorners(gmtry_tmp.crx, gmtry_tmp.cry);

        % 合并所有极向索引用于颜色分配
        all_poloidal_indices = [poloidal_indices_inner, poloidal_indices_outer];
        total_lines = length(all_poloidal_indices);

        if total_lines > 0
            % 为所有极向位置分配颜色
            colors = lines(total_lines);
            line_count = 0;

            % 叠加内偏滤器固定极向位置（沿径向方向的线，使用实线）
            for k = 1:length(poloidal_indices_inner)
                ix_idx = poloidal_indices_inner(k);
                if ix_idx <= nxd
                    line_count = line_count + 1;
                    % 使用网格中心坐标绘制固定极向位置沿径向方向的线
                    R_line = rCenter(ix_idx, :);
                    Z_line = zCenter(ix_idx, :);
                    plot(R_line, Z_line, 'Color', colors(line_count,:), 'LineWidth', 3, ...
                         'LineStyle', '-');  % 内偏滤器使用实线
                end
            end

            % 叠加外偏滤器固定极向位置（沿径向方向的线，使用虚线）
            for k = 1:length(poloidal_indices_outer)
                ix_idx = poloidal_indices_outer(k);
                if ix_idx <= nxd
                    line_count = line_count + 1;
                    % 使用网格中心坐标绘制固定极向位置沿径向方向的线
                    R_line = rCenter(ix_idx, :);
                    Z_line = zCenter(ix_idx, :);
                    plot(R_line, Z_line, 'Color', colors(line_count,:), 'LineWidth', 3, ...
                         'LineStyle', '--');  % 外偏滤器使用虚线
                end
            end
        end

        % ------------------- 4) 保存带时间戳的图窗 -------------------
        saveFigureWithTimestamp(sprintf('Potential_Distribution_with_Poloidal_Lines'));

        hold off;

        %% =========================================================================
        %   新增功能1: 创建径向电势分布剖面图（内偏滤器+外偏滤器）
        % =========================================================================
        try
            % 检查是否有有效的极向索引
            if ~isempty(poloidal_indices_inner) || ~isempty(poloidal_indices_outer)
                % 创建径向电势分布剖面图
                figName_radial = sprintf('Radial Potential Distribution (Inner & Outer Divertor): %s', currentLabel);
                figure('Name', figName_radial, 'NumberTitle','off', 'Color','w',...
                       'Units','pixels','Position',[200 100 1400 900]);
                applyTimesFont(gcf, fontSize-2);

                hold on;

                % 径向距离坐标改为按每条曲线分别计算（见下方循环）
                % 原因：不同极向位置 ix 的 hy 可能不同，且分离面位于13-14号网格交界

                % 统一配色（内+外）
                inner_count = length(poloidal_indices_inner);
                outer_count = length(poloidal_indices_outer);
                colors_combined = lines(inner_count + outer_count);

                % 为内偏滤器极向位置绘制径向电势剖面（逐条计算径向坐标）
                for k = 1:inner_count
                    ix_idx = poloidal_indices_inner(k);
                    if ix_idx <= nxd
                        % 径向几何长度（该极向位置）
                        radial_lengths_k = gmtry_tmp.hy(ix_idx, :);
                        y_edge_k = zeros(length(radial_lengths_k)+1, 1);
                        for jPos = 1:length(radial_lengths_k)
                            y_edge_k(jPos+1) = y_edge_k(jPos) + radial_lengths_k(jPos);
                        end
                        y_center_k = 0.5 * (y_edge_k(1:end-1) + y_edge_k(2:end));

                        % 分离面位于 13 与 14 号网格交界：13号中心 + 0.5*hy(ix,13) = y_edge(14)
                        if length(y_center_k) >= 14
                            y_sep_k = y_center_k(13) + 0.5 * radial_lengths_k(13);
                        else
                            y_sep_k = y_center_k(1);
                            fprintf('Warning: Not enough radial cells to locate separatrix (need >=14) for case %s at ix=%d. Using first point as reference.\n', currentLabel, ix_idx);
                        end

                        % 相对分离面的径向坐标（cm）
                        y_relative_k = (y_center_k - y_sep_k) * 100;

                        % 电势径向剖面
                        potential_profile = potential_data(ix_idx, :);

                        % 绘制（内偏滤器用实线）
                        plot(y_relative_k, potential_profile, 'Color', colors_combined(k,:), ...
                             'LineWidth', 2.5, 'LineStyle', '-', ...
                             'DisplayName', sprintf('ix=%d (Inner)', ix_idx));
                    end
                end

                % 为外偏滤器极向位置绘制径向电势剖面（逐条计算径向坐标）
                for k = 1:outer_count
                    ix_idx = poloidal_indices_outer(k);
                    if ix_idx <= nxd
                        % 径向几何长度（该极向位置）
                        radial_lengths_k = gmtry_tmp.hy(ix_idx, :);
                        y_edge_k = zeros(length(radial_lengths_k)+1, 1);
                        for jPos = 1:length(radial_lengths_k)
                            y_edge_k(jPos+1) = y_edge_k(jPos) + radial_lengths_k(jPos);
                        end
                        y_center_k = 0.5 * (y_edge_k(1:end-1) + y_edge_k(2:end));

                        % 分离面位于 13 与 14 号网格交界：13号中心 + 0.5*hy(ix,13) = y_edge(14)
                        if length(y_center_k) >= 14
                            y_sep_k = y_center_k(13) + 0.5 * radial_lengths_k(13);
                        else
                            y_sep_k = y_center_k(1);
                            fprintf('Warning: Not enough radial cells to locate separatrix (need >=14) for case %s at ix=%d. Using first point as reference.\n', currentLabel, ix_idx);
                        end

                        % 相对分离面的径向坐标（cm）
                        y_relative_k = (y_center_k - y_sep_k) * 100;

                        % 电势径向剖面
                        potential_profile = potential_data(ix_idx, :);

                        % 绘制（外偏滤器用虚线）
                        plot(y_relative_k, potential_profile, 'Color', colors_combined(inner_count + k,:), ...
                             'LineWidth', 2.5, 'LineStyle', '--', ...
                             'DisplayName', sprintf('ix=%d (Outer)', ix_idx));
                    end
                end

                % 标记分离面位置
                ylims = ylim;
                plot([0, 0], ylims, 'k-', 'LineWidth', 2, 'DisplayName', 'Separatrix');

                % 设置坐标轴和标签
                xlabel('Radial distance from separatrix (cm)', 'FontSize', fontSize, 'FontName','Times New Roman');
                ylabel('$\phi$ (V)', 'FontSize', fontSize, 'FontName','Times New Roman','Interpreter','latex');

                grid on;
                box on;
                legend('Location', 'best', 'FontSize', fontSize-8, 'FontName', 'Times New Roman');

                % 设置合适的显示范围 - 径向范围通常更大
                xlim([-5, 15]);  % 径向范围，负值为核心侧，正值为SOL侧

                hold off;

                % 保存径向电势分布剖面图
                saveFigureWithTimestamp(sprintf('Radial_Potential_Distribution_Combined'));
            end

        catch ME
            fprintf('Error generating radial potential distribution plot for case %s: %s\n', currentLabel, ME.message);
        end

        %% =========================================================================
        %   新增功能2: 创建分离面内外网格的极向电势分布对比图（双子图）
        % =========================================================================
        try
            % 径向网格13对应分离面内最后一个网格（芯部侧）
            % 径向网格14对应分离面外第一个网格（SOL侧）
            radial_grid_core = 13;  % 分离面内（芯部侧）
            radial_grid_sol = 14;   % 分离面外（SOL侧）

            % 检查径向网格索引是否有效
            [nxd, nyd] = size(potential_data);
            if radial_grid_core <= nyd && radial_grid_sol <= nyd
                % 创建极向电势分布对比图（双子图）
                figName_poloidal = sprintf('Poloidal Potential Distribution Comparison (Core vs SOL): %s', currentLabel);
                figure('Name', figName_poloidal, 'NumberTitle','off', 'Color','w',...
                       'Units','pixels','Position',[300 150 1600 1000]);
                applyTimesFont(gcf, fontSize-2);

                % 芯部区域定义（极向网格26-73，参考plot_impurity_flux_comparison_analysis.m）
                core_pol_start = 26;
                core_pol_end = 73;

                % 创建极向网格索引（1到nxd）
                poloidal_indices = 1:nxd;

                % ================= 子图1: 分离面内网格(径向网格13)的极向电势分布 =================
                subplot(2, 1, 1);
                hold on;

                % 提取径向网格13处的极向电势分布
                potential_core = potential_data(:, radial_grid_core);

                % 绘制极向电势分布
                plot(poloidal_indices, potential_core, 'r-', 'LineWidth', 3, ...
                     'DisplayName', sprintf('Radial Grid %d (Core Side)', radial_grid_core));

                % 标记关键极向位置
                % 内偏滤器X点位置
                iXpoint_inner = 74;
                if iXpoint_inner <= nxd
                    plot(iXpoint_inner, potential_core(iXpoint_inner), 'ko', ...
                         'MarkerSize', 10, 'MarkerFaceColor', 'k', 'LineWidth', 2, ...
                         'DisplayName', 'Inner X-point');
                end

                % 外偏滤器关键位置
                outer_key_positions = [7, 25];
                for k = 1:length(outer_key_positions)
                    pos = outer_key_positions(k);
                    if pos <= nxd
                        plot(pos, potential_core(pos), 'mo', ...
                             'MarkerSize', 8, 'MarkerFaceColor', 'm', 'LineWidth', 2, ...
                             'DisplayName', sprintf('Outer Div Key Pos %d', pos));
                    end
                end

                % 芯部区域标记（极向网格26-73）
                if core_pol_start <= nxd && core_pol_end <= nxd
                    % 添加芯部区域的背景色
                    ylims = ylim;
                    fill([core_pol_start, core_pol_end, core_pol_end, core_pol_start], ...
                         [ylims(1), ylims(1), ylims(2), ylims(2)], ...
                         'c', 'FaceAlpha', 0.3, 'EdgeColor', 'none', ...
                         'DisplayName', 'Core Region (26-73)');
                end

                % 设置坐标轴和标签
                xlabel('Poloidal Grid Index', 'FontSize', fontSize-2, 'FontName','Times New Roman');
                ylabel('$\phi$ (V)', 'FontSize', fontSize-2, 'FontName','Times New Roman','Interpreter','latex');
                title(sprintf('Poloidal Potential at Radial Grid %d (Core Side of Separatrix)', radial_grid_core), ...
                      'FontSize', fontSize-4, 'FontName','Times New Roman');

                % 设置网格和图例
                grid on;
                box on;
                legend('Location', 'best', 'FontSize', fontSize-10, 'FontName', 'Times New Roman');

                % 设置坐标轴属性
                set(gca, 'FontSize', fontSize-4, 'FontName', 'Times New Roman', 'LineWidth', 1.5);
                xlim([1, nxd]);

                hold off;

                % ================= 子图2: 分离面外网格(径向网格14)的极向电势分布 =================
                subplot(2, 1, 2);
                hold on;

                % 提取径向网格14处的极向电势分布
                potential_sol = potential_data(:, radial_grid_sol);

                % 绘制极向电势分布
                plot(poloidal_indices, potential_sol, 'b-', 'LineWidth', 3, ...
                     'DisplayName', sprintf('Radial Grid %d (SOL Side)', radial_grid_sol));

                % 标记关键极向位置
                % 内偏滤器X点位置
                if iXpoint_inner <= nxd
                    plot(iXpoint_inner, potential_sol(iXpoint_inner), 'ko', ...
                         'MarkerSize', 10, 'MarkerFaceColor', 'k', 'LineWidth', 2, ...
                         'DisplayName', 'Inner X-point');
                end

                % 外偏滤器关键位置
                for k = 1:length(outer_key_positions)
                    pos = outer_key_positions(k);
                    if pos <= nxd
                        plot(pos, potential_sol(pos), 'mo', ...
                             'MarkerSize', 8, 'MarkerFaceColor', 'm', 'LineWidth', 2, ...
                             'DisplayName', sprintf('Outer Div Key Pos %d', pos));
                    end
                end

                % 主SOL区域标记（极向网格26-73）
                if core_pol_start <= nxd && core_pol_end <= nxd
                    % 添加主SOL区域的背景色
                    ylims = ylim;
                    fill([core_pol_start, core_pol_end, core_pol_end, core_pol_start], ...
                         [ylims(1), ylims(1), ylims(2), ylims(2)], ...
                         'y', 'FaceAlpha', 0.3, 'EdgeColor', 'none', ...
                         'DisplayName', 'Main SOL Region (26-73)');
                end

                % 设置坐标轴和标签
                xlabel('Poloidal Grid Index', 'FontSize', fontSize-2, 'FontName','Times New Roman');
                ylabel('$\phi$ (V)', 'FontSize', fontSize-2, 'FontName','Times New Roman','Interpreter','latex');
                title(sprintf('Poloidal Potential at Radial Grid %d (SOL Side of Separatrix)', radial_grid_sol), ...
                      'FontSize', fontSize-4, 'FontName','Times New Roman');

                % 设置网格和图例
                grid on;
                box on;
                legend('Location', 'best', 'FontSize', fontSize-10, 'FontName', 'Times New Roman');

                % 设置坐标轴属性
                set(gca, 'FontSize', fontSize-4, 'FontName', 'Times New Roman', 'LineWidth', 1.5);
                xlim([1, nxd]);

                hold off;

                % 调整子图间距
                sgtitle(sprintf('Poloidal Potential Distribution: Core vs SOL Comparison (%s)', currentLabel), ...
                        'FontSize', fontSize-2, 'FontName','Times New Roman', 'FontWeight', 'bold');

                % 保存极向电势分布对比图
                saveFigureWithTimestamp(sprintf('Poloidal_Potential_Distribution_Core_vs_SOL_Comparison'));

            else
                fprintf('Warning: Radial grid indices %d or %d exceed grid bounds (%d) for case %s. Skipping poloidal potential plot.\n', ...
                        radial_grid_core, radial_grid_sol, nyd, currentLabel);
            end

        catch ME
            fprintf('Error generating poloidal potential distribution plot for case %s: %s\n', currentLabel, ME.message);
        end

    end % 结束 iDir 循环

    fprintf('\n>>> Completed: Potential distribution plots for all cases.\n');

end % 主函数结束




%% =========================================================================
%% (A) 带时间戳保存图窗
%% =========================================================================
function saveFigureWithTimestamp(baseName)
    set(gcf,'Units','pixels','Position',[100 50 1600 1200]);
    set(gcf,'PaperPositionMode','auto');

    timestampStr = datestr(now,'yyyymmdd_HHMMSS');

    figFile = sprintf('%s_%s.fig', baseName, timestampStr);
    savefig(figFile);
    fprintf('MATLAB图形文件已保存: %s\n', figFile);

end

%% 辅助函数：统一当前图窗内所有文本/坐标轴字体为 Times New Roman
function applyTimesFont(figHandle, baseFontSize)
    if nargin < 2, baseFontSize = 32; end
    set(figHandle, 'DefaultAxesFontName','Times New Roman', ...
                   'DefaultTextFontName','Times New Roman', ...
                   'DefaultAxesFontSize', baseFontSize, ...
                   'DefaultTextFontSize', baseFontSize);
    % 已存在的对象也强制刷新
    allObjs = findall(figHandle);
    for k = 1:numel(allObjs)
        try
            if isprop(allObjs(k),'FontName')
                set(allObjs(k),'FontName','Times New Roman');
            end
            if isprop(allObjs(k),'FontSize')
                % 不覆盖 colorbar 等较小字体的自定义缩放，可按需要调整
            end
        catch
        end
    end
end

%% =========================================================================
%% (C) 计算网格中心坐标
%% =========================================================================
function [rCenter, zCenter] = computeCellCentersFromCorners(crx, cry)
    % 说明：
    %   - 通过四角坐标平均计算网格中心

    rCenter = mean(crx, 3); % 第三维度平均
    zCenter = mean(cry, 3);
end