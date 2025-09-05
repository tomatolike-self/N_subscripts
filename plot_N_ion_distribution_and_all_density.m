function plot_N_ion_distribution_and_all_density(all_radiationData, domain)
    % =========================================================================
    % 功能：绘制每个算例的 N 离子态分布，并统一 colorbar 范围。
    %       数据结构说明：
    %               索引1: 中性D
    %               索引2: D+
    %               索引3: 中性N
    %               索引4-10: N1+ 到 N7+ (N离子态)
    %       最新修改：
    %               1) 第一个Figure包含8个子图：总杂质密度分布（N1+到N7+的总和）+ N1+到N7+的单独分布
    %               2) 删除原来的第二个Figure（N6+到N7+），因为只关心N1+到N7+
    %               3) 总杂质密度计算包含N1+到N7+，保持物理合理性
    %               4) 所有文字使用Times New Roman字体，标题使用LaTeX渲染
    %
    % 输入参数：
    %   all_radiationData  - 由主脚本收集的包含各算例信息的 cell 数组
    %   domain             - 用户选择的绘图区域范围 (0/1/2)
    %
    % 注意：
    %   第一个Figure显示总杂质密度 + 7个N离子态 (N1+ ~ N7+)，共8个子图 (3x3布局，最后一个位置空白)。
    %   总杂质密度包含N1+到N7+的总和。
    %   数据索引：N1+对应索引4，N2+对应索引5，...，N7+对应索引10
    %
    % 主要改动：
    %   1) 重新设计Figure布局：一个Figure包含8个子图 (3x3，最后一个空白)
    %   2) 第一个子图显示总杂质密度分布 (N1+到N7+总和)
    %   3) 后续7个子图显示N1+到N7+的单独分布
    %   4) 使用Times New Roman字体和LaTeX渲染
    %   5) 统计数据基于N1+到N7+
    % =========================================================================

    %% 1) 初始化全局变量和数据存储结构
    num_ions_display = 7; % 显示的N 离子价态数量 (N1+ 到 N7+)
    num_ions_total = 7; % 总的N 离子价态数量 (N1+ 到 N7+，用于计算总杂质密度)
    all_N_min = +Inf(num_ions_display, 1); % 初始化全局最小值，用于统一 colorbar 下限 (各价态)
    all_N_max = -Inf(num_ions_display, 1); % 初始化全局最大值，用于统一 colorbar 上限 (各价态)
    all_total_N_min = +Inf; % 初始化全局最小值，用于统一 colorbar 下限 (总杂质密度)
    all_total_N_max = -Inf; % 初始化全局最大值，用于统一 colorbar 上限 (总杂质密度)


    % 存储所有算例的离子统计数据 (预分配 cell 数组)
    num_cases = length(all_radiationData);
    all_case_ion_stats = cell(num_cases, 1);

    % 初始化矩阵用于存储所有算例的全局和偏滤器离子总数，用于绘制柱状图
    all_cases_global_counts = zeros(num_cases, num_ions_display);
    all_cases_divertor_counts = zeros(num_cases, num_ions_display);

    % 生成时间后缀，用于保存图片和统计数据文件，避免文件名重复
    timeSuffix = datestr(now, 'yyyymmdd_HHMMSS');

    %% 2) 数据计算循环 (遍历每个算例和离子态，计算统计数据)
    for iDir = 1:num_cases % 遍历每个算例
        radInfo = all_radiationData{iDir}; % 获取当前算例的辐射数据信息
        dirName = radInfo.dirName; % 获取当前算例的目录名，用于标识

        % 初始化存储当前算例离子统计数据的结构体
        ion_stats = struct();
        ion_stats.ion_names = cell(num_ions_display, 1); % 存储离子态名称 (N1+, N2+, ..., N7+)
        ion_stats.global_counts = zeros(num_ions_display, 1); % 存储全局离子总数
        ion_stats.divertor_counts = zeros(num_ions_display, 1); % 存储偏滤器区域离子总数
        ion_stats.divertor_percentages = zeros(num_ions_display, 1); % 偏滤器占比 (相对于单价态全局)
        ion_stats.global_total_percentage = zeros(num_ions_display, 1); % 全局占比 (相对于所有价态全局总和)
        ion_stats.divertor_total_percentage = zeros(num_ions_display, 1); % 偏滤器占比 (相对于所有价态偏滤器总和)


        % 获取几何信息和网格体积
        gmtry = radInfo.gmtry; % 获取几何信息
        volcell = gmtry.vol(2:end-1,2:end-1); % 获取网格体积 (去除边界网格)
        nxd = size(radInfo.plasma.na, 1); % 获取 x 方向网格数

        % 确定偏滤器区域索引 (如果几何信息中包含偏滤器定义)
        if isfield(gmtry,'leftcut') && isfield(gmtry,'rightcut')
            index_div = [1:gmtry.leftcut+1, gmtry.rightcut+2 : (nxd-2)]; % 偏滤器区域的网格索引
        else
            index_div = []; % 如果没有偏滤器定义，则偏滤器区域索引为空
        end

        total_global_ion_count_case = 0; % 存储当前算例所有价态全局总数
        total_divertor_ion_count_case = 0; % 存储当前算例所有价态偏滤器总数

        % 计算总杂质密度 (包含N1+到N7+)
        total_N_density = sum(radInfo.plasma.na(:,:,4:10), 3); % N1+到N7+对应索引4到10
        total_N_density_sliced = total_N_density(2:end-1, 2:end-1);
        all_total_N_min = min(all_total_N_min, min(total_N_density_sliced(:)));
        all_total_N_max = max(all_total_N_max, max(total_N_density_sliced(:)));

        % 计算所有价态(N1+到N7+)的总数，用于百分比计算
        for iIon = 1:num_ions_total % 遍历所有离子态 (N1+ ~ N7+)
            current_N_data = radInfo.plasma.na(:,:,3 + iIon);
            current_N_data_sliced = current_N_data(2:end-1, 2:end-1);
            global_ion_count = sum(current_N_data_sliced(:) .* volcell(:));
            divertor_ion_count = 0;
            if ~isempty(index_div)
                divertor_data = current_N_data_sliced(index_div, :);
                divertor_volcell = volcell(index_div, :);
                divertor_ion_count = sum(divertor_data(:) .* divertor_volcell(:));
            end
            total_global_ion_count_case = total_global_ion_count_case + global_ion_count;
            total_divertor_ion_count_case = total_divertor_ion_count_case + divertor_ion_count;
        end

        % 只处理显示的离子态 (N1+ ~ N7+)
        for iIon = 1:num_ions_display % 遍历显示的离子态 (N1+ ~ N7+)
            % 获取当前 iIon 对应的 N 离子态数据 (注意：原始数据中 N1+ 对应索引 4, N2+ 对应 5, ...)
            current_N_data = radInfo.plasma.na(:,:,3 + iIon);
            current_N_data_sliced = current_N_data(2:end-1, 2:end-1); % 去除边界网格数据

            % 更新全局 min/max 值 (用于 colorbar 统一，确保所有离子态使用相同的颜色范围)
            all_N_min(iIon) = min(all_N_min(iIon), min(current_N_data(:)));
            all_N_max(iIon) = max(all_N_max(iIon), max(current_N_data(:)));

            % 计算离子总数 (积分网格体积得到总数)
            global_ion_count = sum(current_N_data_sliced(:) .* volcell(:)); % 全局离子总数
            divertor_ion_count = 0; % 初始化偏滤器离子总数
            if ~isempty(index_div) % 如果偏滤器区域索引不为空，则计算偏滤器区域离子总数
                divertor_data = current_N_data_sliced(index_div, :); % 提取偏滤器区域的离子数据
                divertor_volcell = volcell(index_div, :); % 提取偏滤器区域的网格体积
                divertor_ion_count = sum(divertor_data(:) .* divertor_volcell(:)); % 偏滤器区域离子总数
            end
            divertor_percentage = (divertor_ion_count / global_ion_count) * 100; % 计算偏滤器离子数占全局离子数的百分比

            % 存储单价态离子统计数据
            ion_stats.ion_names{iIon} = sprintf('N^{%d+}', iIon); % 存储离子态名称，例如 N1+, N2+
            ion_stats.global_counts(iIon) = global_ion_count; % 存储全局离子总数
            ion_stats.divertor_counts(iIon) = divertor_ion_count; % 存储偏滤器区域离子总数
            ion_stats.divertor_percentages(iIon) = divertor_percentage; % 存储偏滤器占比

            all_cases_global_counts(iDir, iIon) = global_ion_count; % 存储当前算例和离子态的全局离子数，用于绘制柱状图
            all_cases_divertor_counts(iDir, iIon) = divertor_ion_count; % 存储当前算例和离子态的偏滤器离子数，用于绘制柱状图

        end % end for iIon (单算例内离子态循环结束)

        % 计算各价态离子数占总离子数的百分比 (相对于当前算例的所有价态总数)
        for iIon = 1:num_ions_display
            ion_stats.global_total_percentage(iIon) = (ion_stats.global_counts(iIon) / total_global_ion_count_case) * 100; % 全局占比
            ion_stats.divertor_total_percentage(iIon) = (ion_stats.divertor_counts(iIon) / total_global_ion_count_case) * 100; % 偏滤器占比 (这里分母统一使用全局总数，方便比较)
        end

        % 保存当前算例的离子统计数据到结构体数组
        all_case_ion_stats{iDir} = ion_stats;

        % 输出离子统计数据到文本文件
        statsFilename = sprintf('NIonStats_%d_%s.txt', iDir, timeSuffix); % 统计数据文件名，包含算例序号和时间后缀
        statsFullPath = fullfile(pwd, statsFilename); % 统计数据文件完整路径
        fid = fopen(statsFullPath, 'w'); % 打开文件准备写入
        fprintf(fid, 'Case: %s\n', dirName); % 写入算例目录名
        fprintf(fid, '----------------------------------------------------------------------------------------------------\n');
        fprintf(fid, '%-8s | %-15s | %-15s | %-20s | %-25s | %-25s\n', ...
                'Ion State', 'Global Count', 'Divertor Count', 'Divertor Percentage (%)', 'Global Total Percentage (%)', 'Divertor Total Percentage (%)'); % 写入表头
        fprintf(fid, '----------------------------------------------------------------------------------------------------\n');
        for iIon = 1:num_ions_display
            fprintf(fid, '%-8s | %-15.4e | %-15.4e | %-20.2f%% | %-25.2f%% | %-25.2f%%\n', ...
                    ion_stats.ion_names{iIon}, ...
                    ion_stats.global_counts(iIon), ...
                    ion_stats.divertor_counts(iIon), ...
                    ion_stats.divertor_percentages(iIon), ...
                    ion_stats.global_total_percentage(iIon), ...
                    ion_stats.divertor_total_percentage(iIon)); % 写入每一行统计数据
        end
        fclose(fid); % 关闭文件
        fprintf('Ion statistics data has been saved to: %s\n', statsFullPath); % 提示统计数据保存路径

    end % end for iDir (所有算例数据计算循环结束)


    %% 3) 图片绘制循环 (遍历每个算例，绘制分布云图和统计图)
    for iDir = 1:num_cases % 遍历每个算例
        radInfo = all_radiationData{iDir}; % 获取当前算例的辐射数据信息
        dirName = radInfo.dirName; % 获取当前算例目录名
        ion_stats = all_case_ion_stats{iDir}; % 获取预先计算好的当前算例的统计数据

        % ============== 第一个 Figure，绘制总杂质密度分布和 N1+~N7+ 的分布云图 ==============
        fig1 = figure('Name', ['N Ion Distribution: ', dirName], ...
                      'NumberTitle', 'off', ... % 窗口标题不显示编号
                      'Color', 'w', ... % 背景颜色白色
                      'Units', 'normalized', ... % 单位归一化
                      'Position', [0, 0, 1, 1]); % 全屏显示

        % 首先绘制总杂质密度分布 (第一个子图)
        subplot(3, 3, 1); % 创建第一个子图 (3行3列)
        total_N_density = sum(radInfo.plasma.na(:,:,4:10), 3); % N1+到N7+对应索引4到10
        surfplot(radInfo.gmtry, total_N_density);
        shading interp;
        view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.5);
        colormap(jet);
        colorbar;
        caxis([all_total_N_min, all_total_N_max]); % 使用全局统一 colorbar 范围

        set(gca, 'fontsize', 16, 'FontName', 'Times New Roman'); % 设置字体
        xlabel('R (m)', 'fontsize', 16, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        ylabel('Z (m)', 'fontsize', 16, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        title('Total N Density ($\mathrm{m^{-3}}$)', 'FontSize', 16, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
        axis square;
        box on;

        % 添加结构绘制（所有domain都绘制）
        if isfield(radInfo, 'structure')
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end

        if domain ~= 0
            switch domain
                case 1
                    xlim([1.30, 2.00]);
                    ylim([0.50, 1.20]);
                case 2
                    xlim([1.30, 2.05]);
                    ylim([-1.15, -0.40]);
            end
        end

        % 然后绘制 N1+ 到 N7+ 的分布云图
        for iIon_plot = 1:7 % 绘制 N1+ 到 N7+
            iIon = iIon_plot; % 保持 iIon 代表实际的离子态索引 (1-7)
            subplot(3, 3, iIon_plot + 1); % 创建子图 (从第2个子图开始)

            current_N_data = radInfo.plasma.na(:,:,3 + iIon); % 获取原始数据，用于绘图
            surfplot(radInfo.gmtry, current_N_data); % 绘制曲面图
            shading interp; % 表面平滑处理
            view(2); % 俯视角度
            hold on; % 保留当前坐标轴和图形，允许绘制更多图形
            plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.5); % 绘制分隔线
            colormap(jet); % 使用 jet 颜色映射
            colorbar; % 显示颜色bar
            caxis([all_N_min(iIon), all_N_max(iIon)]); % 使用全局统一 colorbar 范围

            set(gca, 'fontsize', 16, 'FontName', 'Times New Roman'); % 设置字体
            xlabel('R (m)', 'fontsize', 16, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
            ylabel('Z (m)', 'fontsize', 16, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
            title(sprintf('$\\mathrm{N^{%d+}}$ Density ($\\mathrm{m^{-3}}$)', iIon), 'FontSize', 16, 'FontName', 'Times New Roman', 'Interpreter', 'latex');
            axis square; % 坐标轴长宽比设置为 1:1
            box on; % 显示坐标轴边框

            % 添加结构绘制（所有domain都绘制）
            if isfield(radInfo, 'structure')
                plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2); % 绘制结构
            end

            if domain ~= 0 % 如果用户选择了绘图区域范围 (domain ~= 0)
                switch domain
                    case 1 % domain = 1
                        xlim([1.30, 2.00]); % 限制 x 轴范围
                        ylim([0.50, 1.20]); % 限制 y 轴范围
                    case 2 % domain = 2
                        xlim([1.30, 2.05]); % 限制 x 轴范围
                        ylim([-1.15, -0.40]); % 限制 y 轴范围
                end
            end
        end

        figFilename1 = sprintf('NIonDist_%d_%s.fig', iDir, timeSuffix); % 图片文件名
        figFullPath1 = fullfile(pwd, figFilename1); % 图片文件完整路径
        savefig(fig1, figFullPath1); % 保存 Figure 到文件
        fprintf('N Ion Distribution Figure has been saved to: %s\n', figFullPath1); % 提示图片保存路径




        % ============== 第二个 Figure，绘制离子统计百分比 (柱状图) ==============
        statsFigPercentage = figure('Name', ['N Ion Statistics Percentage: ', dirName], ...
                          'NumberTitle', 'off', ...
                          'Color', 'w', ...
                          'Units', 'normalized', ...
                          'Position', [0.2, 0.2, 0.6, 0.6]); % 窗口大小和位置

        bar_percent_groups = [ion_stats.global_total_percentage, ion_stats.divertor_total_percentage]; % 柱状图数据，全局和偏滤器占比
        bar_percent_chart = bar(bar_percent_groups); % 绘制柱状图
        set(gca, 'XTickLabel', ion_stats.ion_names); % 设置 x 轴刻度标签为离子态名称
        legend('Global Percentage', 'Divertor Percentage', 'FontName', 'Times New Roman', 'FontSize', 14); % 显示图例
        ylabel('Percentage (\%)', 'FontName', 'Times New Roman', 'FontSize', 16, 'Interpreter', 'latex'); % y 轴标签
        % 处理算例名称中的特殊字符，避免LaTeX解释器错误
        safe_dirName = strrep(dirName, '_', '\_'); % 转义下划线
        title(['N Ion Percentage for Case: ', safe_dirName], 'FontName', 'Times New Roman', 'FontSize', 16, 'Interpreter', 'latex'); % 图表标题
        set(gca, 'fontsize', 14, 'FontName', 'Times New Roman'); % 设置字体大小
        rotateXLabels(gca, 45); % 旋转 x 轴标签，避免重叠
        grid on; % 显示网格

        statsFigPercentageFilename = sprintf('NIonStatsPercentage_%d_%s.fig', iDir, timeSuffix); % 图片文件名，包含算例序号和时间后缀
        statsFigPercentageFullPath = fullfile(pwd, statsFigPercentageFilename); % 图片文件完整路径
        savefig(statsFigPercentage, statsFigPercentageFullPath); % 保存 Figure 到文件
        fprintf('Ion statistics percentage figure has been saved to: %s\n', statsFigPercentageFullPath); % 提示图片保存路径


        % ============== 第三个 Figure，绘制离子总数统计 (柱状图) ==============
        statsFigCounts = figure('Name', ['N Ion Counts: ', dirName], ...
                          'NumberTitle', 'off', ...
                          'Color', 'w', ...
                          'Units', 'normalized', ...
                          'Position', [0.2, 0.2, 0.6, 0.6]); % 窗口大小和位置

        bar_counts_groups = [ion_stats.global_counts, ion_stats.divertor_counts];
        bar_counts_chart = bar(bar_counts_groups);
        set(gca, 'XTickLabel', ion_stats.ion_names);
        legend('Global Count', 'Divertor Count', 'FontName', 'Times New Roman', 'FontSize', 14);
        ylabel('Ion Count', 'FontName', 'Times New Roman', 'FontSize', 16, 'Interpreter', 'latex');
        % 处理算例名称中的特殊字符，避免LaTeX解释器错误
        safe_dirName = strrep(dirName, '_', '\_'); % 转义下划线
        title(['N Ion Counts for Case: ', safe_dirName], 'FontName', 'Times New Roman', 'FontSize', 16, 'Interpreter', 'latex');
        set(gca, 'fontsize', 14, 'FontName', 'Times New Roman');
        rotateXLabels(gca, 45);
        grid on;
        box on;

        statsFigCountsFilename = sprintf('NIonStatsCountsBar_%d_%s.fig', iDir, timeSuffix); % 图片文件名，修改为 Bar
        statsFigCountsFullPath = fullfile(pwd, statsFigCountsFilename);
        savefig(statsFigCounts, statsFigCountsFullPath);
        fprintf('Ion statistics counts bar figure has been saved to: %s\n', statsFigCountsFullPath); % 提示图片保存路径


    end % end for iDir (所有算例图片绘制循环结束)


    %% 4) 绘制所有算例的离子总数变化趋势对比图 (柱状图)
    statsFigCountsCompare = figure('Name', ['N Ion Counts Comparison'], ...
                               'NumberTitle', 'off', ...
                               'Color', 'w', ...
                               'Units', 'normalized', ...
                               'Position', [0.2, 0.2, 0.7, 0.7]); % 窗口大小和位置，稍微调整宽度

    ion_names = all_case_ion_stats{1}.ion_names; % 获取离子名称，假设所有算例的离子名称相同
    x = 1:num_ions_display;
    bar_width = 0.8 / num_cases; % 设置柱状图宽度，根据算例数量调整，保证不重叠

    for iDir = 1:num_cases
        dirName = all_radiationData{iDir}.dirName;
        % 处理算例名称中的特殊字符，避免LaTeX解释器错误
        safe_dirName = strrep(dirName, '_', '\_'); % 转义下划线
        positions_global = x + (iDir - 1 - (num_cases - 1)/2) * bar_width; % 计算每个case的柱子位置，错开一些
        bar(positions_global, all_cases_global_counts(iDir, :), bar_width, 'DisplayName', [safe_dirName, ' Global']);
        hold on;
        %positions_divertor = x + (iDir - 1 - (num_cases - 1)/2) * bar_width + bar_width/2; % Divertor 柱子稍微偏移，如果需要可以画在一起
        %bar(positions_divertor, all_cases_divertor_counts(iDir, :), bar_width/2, 'DisplayName', [dirName, ' Divertor'], 'FaceColor', get(gca, 'ColorOrderIndex')); % 使用相同的颜色
    end

    set(gca, 'XTick', x);
    set(gca, 'XTickLabel', ion_names);
    legend('Location', 'northwest', 'FontName', 'Times New Roman', 'FontSize', 14);
    ylabel('Ion Count', 'FontName', 'Times New Roman', 'FontSize', 16, 'Interpreter', 'latex');
    xlabel('Ion State', 'FontName', 'Times New Roman', 'FontSize', 16, 'Interpreter', 'latex');
    title('Comparison of N Ion Counts Across Cases', 'FontName', 'Times New Roman', 'FontSize', 16);
    set(gca, 'fontsize', 14, 'FontName', 'Times New Roman');
    rotateXLabels(gca, 45);
    grid on;
    box on;
    xlim([0.5, num_ions_display + 0.5]); % 调整 x 轴范围，避免柱状图被裁剪

    statsFigCompareFilename = sprintf('NIonStatsCountsCompareBar_%s.fig', timeSuffix); % 图片文件名，修改为 Bar
    statsFigCompareFullPath = fullfile(pwd, statsFigCompareFilename);
    savefig(statsFigCountsCompare, statsFigCompareFullPath);
    fprintf('Comparison figure of ion statistics counts (bar) has been saved to: %s\n', statsFigCompareFullPath);


end


function rotateXLabels(ax, angle)
    %Rotate X axis labels using built-in XTickLabelRotation
    set(ax, 'XTickLabelRotation', angle);
end
