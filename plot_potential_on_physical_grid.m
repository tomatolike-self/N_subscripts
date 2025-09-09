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
    %      - 使用渐变式颜色方案：外偏滤器蓝色系递进，内偏滤器红色系递进
    %   2. 径向电势分布剖面图（内偏滤器实线 + 外偏滤器虚线）
    %      - 双子图：上子图为外偏滤器区域，下子图为内偏滤器区域
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

    fontSize = 48;          % 统一字体大小（大幅增加）

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
        h_colorbar.Label.FontSize = fontSize+4;  % 大幅增加colorbar标签字体
        h_colorbar.Label.FontWeight = 'bold';
        h_colorbar.Label.FontName = 'Times New Roman';
        set(h_colorbar, 'FontSize', fontSize-4, 'LineWidth', 2.0, 'FontName','Times New Roman');
        % 确保colorbar刻度数字使用Times New Roman字体
        set(h_colorbar, 'TickLabelInterpreter', 'latex');

        % (2.3) 叠加分离器/结构
        plot3sep(gmtry_tmp, 'color','w','LineStyle','--','LineWidth',1.5);

        % (2.4) 设置标题及坐标轴标签 (恢复 LaTeX)
        xlabel('$R$ (m)', 'FontSize', fontSize+8, 'FontName','Times New Roman','Interpreter','latex');
        ylabel('$Z$ (m)', 'FontSize', fontSize+8, 'FontName','Times New Roman','Interpreter','latex');

        % (2.5) 设置坐标轴属性
        axis equal tight;
        box on;
        grid on;
        set(gca, 'FontSize', fontSize+4, 'FontName', 'Times New Roman', 'LineWidth', 2.0);
        % 确保坐标轴刻度数字使用Times New Roman字体
        set(gca, 'XTickLabelMode', 'manual', 'YTickLabelMode', 'manual');
        set(gca, 'TickLabelInterpreter', 'latex');

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

        % 定义与fig2统一的渐变式颜色方案
        % 外偏滤器区域 [7, 19, 24, 25] - 从亮蓝色(7)向暗蓝/黑色(25)过渡
        outer_colors = [0.0, 0.6, 1.0; 0.0, 0.4, 0.8; 0.0, 0.25, 0.5; 0.0, 0.1, 0.2];
        % 内偏滤器区域 [74, 76, 80, 92] - 从暗红/黑色(74)向亮红色(92)过渡
        inner_colors = [0.2, 0.0, 0.0; 0.5, 0.0, 0.0; 0.8, 0.0, 0.0; 1.0, 0.2, 0.2];

        % 叠加内偏滤器固定极向位置（沿径向方向的线，使用实线）
        for k = 1:length(poloidal_indices_inner)
            ix_idx = poloidal_indices_inner(k);
            if ix_idx <= nxd
                % 使用网格中心坐标绘制固定极向位置沿径向方向的线
                R_line = rCenter(ix_idx, :);
                Z_line = zCenter(ix_idx, :);

                % 内偏滤器颜色递进（92是最外侧亮红色，向内侧74逐渐变暗）
                if k <= size(inner_colors, 1)
                    color_to_use = inner_colors(k, :);
                else
                    color_to_use = [1.0, 0.2, 0.2]; % 默认亮红色
                end

                plot(R_line, Z_line, 'Color', color_to_use, 'LineWidth', 3, ...
                     'LineStyle', '-');  % 内偏滤器使用实线
            end
        end

        % 叠加外偏滤器固定极向位置（沿径向方向的线，使用虚线）
        for k = 1:length(poloidal_indices_outer)
            ix_idx = poloidal_indices_outer(k);
            if ix_idx <= nxd
                % 使用网格中心坐标绘制固定极向位置沿径向方向的线
                R_line = rCenter(ix_idx, :);
                Z_line = zCenter(ix_idx, :);

                % 外偏滤器颜色递进
                if k <= size(outer_colors, 1)
                    color_to_use = outer_colors(k, :);
                else
                    color_to_use = [0.0, 0.6, 1.0]; % 默认亮蓝色
                end

                plot(R_line, Z_line, 'Color', color_to_use, 'LineWidth', 3, ...
                     'LineStyle', '--');  % 外偏滤器使用虚线
            end
        end

        % ------------------- 4) 保存带时间戳的图窗 -------------------
        saveFigureWithTimestamp(sprintf('Potential_Distribution_with_Poloidal_Lines'));

        hold off;

        %% =========================================================================
        %   新增功能1: 创建径向电势分布剖面图（内偏滤器+外偏滤器双子图）
        % =========================================================================
        try
            % 检查是否有有效的极向索引
            if ~isempty(poloidal_indices_inner) || ~isempty(poloidal_indices_outer)
                % 创建径向电势分布剖面图（双子图）
                figName_radial = sprintf('Radial Potential Distribution (Inner & Outer Divertor): %s', currentLabel);
                figure('Name', figName_radial, 'NumberTitle','off', 'Color','w',...
                       'Units','pixels','Position',[200 100 1600 1200]);
                applyTimesFont(gcf, fontSize);

                % 定义颜色方案
                % 外偏滤器区域 [7, 19, 24, 25] - 从亮蓝色(7)向暗蓝/黑色(25)过渡
                outer_colors = [0.0, 0.6, 1.0; 0.0, 0.4, 0.8; 0.0, 0.25, 0.5; 0.0, 0.1, 0.2];
                % 内偏滤器区域 [74, 76, 80, 92] - 从暗红/黑色(74)向亮红色(92)过渡
                inner_colors = [0.2, 0.0, 0.0; 0.5, 0.0, 0.0; 0.8, 0.0, 0.0; 1.0, 0.2, 0.2];

                % 计算统一的径向坐标范围和Y轴范围
                all_y_relative = [];
                all_potentials = [];

                % 收集所有数据以确定统一的坐标范围
                for k = 1:length(poloidal_indices_inner)
                    ix_idx = poloidal_indices_inner(k);
                    if ix_idx <= nxd
                        radial_lengths_k = gmtry_tmp.hy(ix_idx, :);
                        y_edge_k = zeros(length(radial_lengths_k)+1, 1);
                        for jPos = 1:length(radial_lengths_k)
                            y_edge_k(jPos+1) = y_edge_k(jPos) + radial_lengths_k(jPos);
                        end
                        y_center_k = 0.5 * (y_edge_k(1:end-1) + y_edge_k(2:end));

                        if length(y_center_k) >= 14
                            y_sep_k = y_center_k(13) + 0.5 * radial_lengths_k(13);
                        else
                            y_sep_k = y_center_k(1);
                        end

                        y_relative_k = (y_center_k - y_sep_k) * 100;
                        potential_profile = potential_data(ix_idx, :);

                        all_y_relative = [all_y_relative; y_relative_k(:)];
                        all_potentials = [all_potentials; potential_profile(:)];
                    end
                end

                for k = 1:length(poloidal_indices_outer)
                    ix_idx = poloidal_indices_outer(k);
                    if ix_idx <= nxd
                        radial_lengths_k = gmtry_tmp.hy(ix_idx, :);
                        y_edge_k = zeros(length(radial_lengths_k)+1, 1);
                        for jPos = 1:length(radial_lengths_k)
                            y_edge_k(jPos+1) = y_edge_k(jPos) + radial_lengths_k(jPos);
                        end
                        y_center_k = 0.5 * (y_edge_k(1:end-1) + y_edge_k(2:end));

                        if length(y_center_k) >= 14
                            y_sep_k = y_center_k(13) + 0.5 * radial_lengths_k(13);
                        else
                            y_sep_k = y_center_k(1);
                        end

                        y_relative_k = (y_center_k - y_sep_k) * 100;
                        potential_profile = potential_data(ix_idx, :);

                        all_y_relative = [all_y_relative; y_relative_k(:)];
                        all_potentials = [all_potentials; potential_profile(:)];
                    end
                end

                % 计算统一的X轴坐标范围
                x_min = floor(min(all_y_relative));
                x_max = ceil(max(all_y_relative));
                x_range = [x_min, x_max];

                % ================= 子图1: 外偏滤器区域径向电势分布 =================
                subplot(2, 1, 1);
                hold on;

                % 为外偏滤器极向位置绘制径向电势剖面
                for k = 1:length(poloidal_indices_outer)
                    ix_idx = poloidal_indices_outer(k);
                    if ix_idx <= nxd
                        % 径向几何长度（该极向位置）
                        radial_lengths_k = gmtry_tmp.hy(ix_idx, :);
                        y_edge_k = zeros(length(radial_lengths_k)+1, 1);
                        for jPos = 1:length(radial_lengths_k)
                            y_edge_k(jPos+1) = y_edge_k(jPos) + radial_lengths_k(jPos);
                        end
                        y_center_k = 0.5 * (y_edge_k(1:end-1) + y_edge_k(2:end));

                        % 分离面位于 13 与 14 号网格交界
                        if length(y_center_k) >= 14
                            y_sep_k = y_center_k(13) + 0.5 * radial_lengths_k(13);
                        else
                            y_sep_k = y_center_k(1);
                        end

                        % 相对分离面的径向坐标（cm）
                        y_relative_k = (y_center_k - y_sep_k) * 100;

                        % 电势径向剖面
                        potential_profile = potential_data(ix_idx, :);

                        % 绘制（外偏滤器用虚线，颜色递进）
                        if k <= size(outer_colors, 1)
                            color_to_use = outer_colors(k, :);
                        else
                            color_to_use = [0.0, 0.6, 1.0]; % 默认亮蓝色
                        end

                        plot(y_relative_k, potential_profile, 'Color', color_to_use, ...
                             'LineWidth', 2.5, 'LineStyle', '--', ...
                             'DisplayName', sprintf('ix=%d', ix_idx));
                    end
                end

                % 标记分离面位置（使用虚线）
                y_limits = ylim; % 获取当前Y轴范围
                plot([0, 0], y_limits, 'k--', 'LineWidth', 2, 'DisplayName', 'Separatrix');

                % 设置坐标轴和标签（上子图不显示X轴标签，但显示Y轴刻度和数值）
                % 隐藏X轴刻度标签，但保留刻度线
                set(gca, 'XTickLabel', []);
                % Y轴显示刻度和数值，但不设置Y轴标题
                % 移除子图标题

                % 设置X轴范围，Y轴使用MATLAB自动设置
                xlim(x_range);

                grid on;
                box on;
                % 移除图例
                set(gca, 'FontSize', fontSize+4, 'FontName', 'Times New Roman', 'LineWidth', 2.0);
                % 确保Y轴刻度数字正常显示，使用Times New Roman字体
                set(gca, 'YTickLabelMode', 'auto');  % 确保Y轴标签自动显示
                set(gca, 'TickLabelInterpreter', 'latex');

                % 调整子图纵横比：横轴长度约为纵轴长度的2倍
                pbaspect([2, 1, 1]);  % 设置纵横比为2:1

                hold off;

                % ================= 子图2: 内偏滤器区域径向电势分布 =================
                subplot(2, 1, 2);
                hold on;

                % 为内偏滤器极向位置绘制径向电势剖面
                for k = 1:length(poloidal_indices_inner)
                    ix_idx = poloidal_indices_inner(k);
                    if ix_idx <= nxd
                        % 径向几何长度（该极向位置）
                        radial_lengths_k = gmtry_tmp.hy(ix_idx, :);
                        y_edge_k = zeros(length(radial_lengths_k)+1, 1);
                        for jPos = 1:length(radial_lengths_k)
                            y_edge_k(jPos+1) = y_edge_k(jPos) + radial_lengths_k(jPos);
                        end
                        y_center_k = 0.5 * (y_edge_k(1:end-1) + y_edge_k(2:end));

                        % 分离面位于 13 与 14 号网格交界
                        if length(y_center_k) >= 14
                            y_sep_k = y_center_k(13) + 0.5 * radial_lengths_k(13);
                        else
                            y_sep_k = y_center_k(1);
                        end

                        % 相对分离面的径向坐标（cm）
                        y_relative_k = (y_center_k - y_sep_k) * 100;

                        % 电势径向剖面
                        potential_profile = potential_data(ix_idx, :);

                        % 绘制（内偏滤器用实线，颜色递进）
                        % 92是最外侧亮红色，向内侧74逐渐变暗
                        if k <= size(inner_colors, 1)
                            color_to_use = inner_colors(k, :);
                        else
                            color_to_use = [1.0, 0.2, 0.2]; % 默认亮红色
                        end

                        plot(y_relative_k, potential_profile, 'Color', color_to_use, ...
                             'LineWidth', 2.5, 'LineStyle', '-', ...
                             'DisplayName', sprintf('ix=%d', ix_idx));
                    end
                end

                % 标记分离面位置（使用虚线）
                y_limits = ylim; % 获取当前Y轴范围
                plot([0, 0], y_limits, 'k--', 'LineWidth', 2, 'DisplayName', 'Separatrix');

                % 设置坐标轴和标签（下子图显示X轴标签，Y轴显示刻度和数值但无标题）
                xlabel('$r - r_{\mathrm{sep}}$ (cm)', 'FontSize', fontSize+8, 'FontName','Times New Roman','Interpreter','latex');
                % Y轴显示刻度和数值，但不设置Y轴标题（由整体标题提供）
                % 移除子图标题

                % 设置X轴范围，Y轴使用MATLAB自动设置
                xlim(x_range);

                grid on;
                box on;
                % 移除图例
                set(gca, 'FontSize', fontSize+4, 'FontName', 'Times New Roman', 'LineWidth', 2.0);
                % 确保Y轴刻度数字正常显示，使用Times New Roman字体
                set(gca, 'YTickLabelMode', 'auto');  % 确保Y轴标签自动显示
                set(gca, 'TickLabelInterpreter', 'latex');

                % 调整子图纵横比：横轴长度约为纵轴长度的2倍
                pbaspect([2, 1, 1]);  % 设置纵横比为2:1

                hold off;

                % 保存径向电势分布剖面图
                saveFigureWithTimestamp(sprintf('Radial_Potential_Distribution_Subplots'));
            end

        catch ME
            fprintf('Error generating radial potential distribution plot for case %s: %s\n', currentLabel, ME.message);
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
    if nargin < 2, baseFontSize = 48; end  % 增大默认字体
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