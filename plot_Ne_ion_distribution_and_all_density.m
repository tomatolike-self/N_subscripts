function plot_Ne_ion_distribution_and_all_density(all_radiationData, domain)
    % =========================================================================
    % 功能：绘制每个算例的 Ne 离子态分布，并统一 colorbar 范围。
    %       原先在一个 Figure 中绘制 10 个子图（Ne1 ~ Ne10+）。
    %       现需求将 10 个子图拆分到两个 Figure 中（每个 Figure 上 5 个子图）。
    %       新增功能：输出各离子态全局总数、偏滤器区域总数及占比，并绘制统计图。
    %               数据计算和绘图模块拆分，新增各价态占比和总数统计及绘图。
    %       进一步修改：将第四张子图的柱状图修改为折线图，反映各价态离子总数的变化趋势。
    %               将所有算例的折线变化绘制到同一张图上，带有图例，横轴为离子价态。
    %               用实线代表全局总离子数，虚线代表偏滤器区域离子总数。
    %       最新修改：
    %               1) 新增一个图，绘制总的杂质密度分布。
    %               2) 将所有算例的离子总数变化趋势对比图从折线图改为柱状图。
    %
    % 输入参数：
    %   all_radiationData  - 由主脚本收集的包含各算例信息的 cell 数组
    %   domain             - 用户选择的绘图区域范围 (0/1/2)
    %
    % 注意：
    %   每张图显示 5 个 Ne 离子态，共 2 张 Figure，总计 10 个离子态 (Ne1+ ~ Ne10+)。
    %
    % 主要改动：
    %   1) 在每个算例下，分别创建两个 Figure (Ne1+-Ne5+, Ne6+-Ne10+)，用于显示离子分布云图。
    %   2) 每个 Figure 都使用全屏显示，以获得更好的可视化效果。
    %   3) 数据计算和绘图模块拆分，提高代码可读性和维护性。
    %   4) 新增各离子态全局和偏滤器离子数占总离子数的百分比和总数计算及绘图。
    %   5) 修改第四张子图为折线图，展示各算例离子总数随价态的变化趋势。
    %   6) 新增总杂质密度分布云图。
    %   7) 将所有算例离子总数变化趋势对比图改为柱状图。
    % =========================================================================

    %% 1) 初始化全局变量和数据存储结构
    num_ions = 10; % Ne 离子价态数量 (Ne1+ 到 Ne10+)
    all_Ne_min = +Inf(num_ions, 1); % 初始化全局最小值，用于统一 colorbar 下限 (各价态)
    all_Ne_max = -Inf(num_ions, 1); % 初始化全局最大值，用于统一 colorbar 上限 (各价态)
    all_total_Ne_min = +Inf; % 初始化全局最小值，用于统一 colorbar 下限 (总杂质密度)
    all_total_Ne_max = -Inf; % 初始化全局最大值，用于统一 colorbar 上限 (总杂质密度)


    % 存储所有算例的离子统计数据 (预分配 cell 数组)
    num_cases = length(all_radiationData);
    all_case_ion_stats = cell(num_cases, 1);

    % 初始化矩阵用于存储所有算例的全局和偏滤器离子总数，用于绘制柱状图
    all_cases_global_counts = zeros(num_cases, num_ions);
    all_cases_divertor_counts = zeros(num_cases, num_ions);

    % 生成时间后缀，用于保存图片和统计数据文件，避免文件名重复
    timeSuffix = datestr(now, 'yyyymmdd_HHMMSS');

    %% 2) 数据计算循环 (遍历每个算例和离子态，计算统计数据)
    for iDir = 1:num_cases % 遍历每个算例
        radInfo = all_radiationData{iDir}; % 获取当前算例的辐射数据信息
        dirName = radInfo.dirName; % 获取当前算例的目录名，用于标识

        % 初始化存储当前算例离子统计数据的结构体
        ion_stats = struct();
        ion_stats.ion_names = cell(num_ions, 1); % 存储离子态名称 (Ne1+, Ne2+, ..., Ne10+)
        ion_stats.global_counts = zeros(num_ions, 1); % 存储全局离子总数
        ion_stats.divertor_counts = zeros(num_ions, 1); % 存储偏滤器区域离子总数
        ion_stats.divertor_percentages = zeros(num_ions, 1); % 偏滤器占比 (相对于单价态全局)
        ion_stats.global_total_percentage = zeros(num_ions, 1); % 全局占比 (相对于所有价态全局总和)
        ion_stats.divertor_total_percentage = zeros(num_ions, 1); % 偏滤器占比 (相对于所有价态偏滤器总和)


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

        % 计算总杂质密度
        total_Ne_density = sum(radInfo.plasma.na(:,:,3:end), 3);
        total_Ne_density_sliced = total_Ne_density(2:end-1, 2:end-1);
        all_total_Ne_min = min(all_total_Ne_min, min(total_Ne_density_sliced(:)));
        all_total_Ne_max = max(all_total_Ne_max, max(total_Ne_density_sliced(:)));


        for iIon = 1:num_ions % 遍历每个离子态 (Ne1+ ~ Ne10+)
            % 获取当前 iIon 对应的 Ne 离子态数据 (注意：原始数据中 Ne1+ 对应索引 4, Ne2+ 对应 5, ...)
            current_Ne_data = radInfo.plasma.na(:,:,3 + iIon);
            current_Ne_data_sliced = current_Ne_data(2:end-1, 2:end-1); % 去除边界网格数据

            % 更新全局 min/max 值 (用于 colorbar 统一，确保所有离子态使用相同的颜色范围)
            all_Ne_min(iIon) = min(all_Ne_min(iIon), min(current_Ne_data(:)));
            all_Ne_max(iIon) = max(all_Ne_max(iIon), max(current_Ne_data(:)));

            % 计算离子总数 (积分网格体积得到总数)
            global_ion_count = sum(current_Ne_data_sliced(:) .* volcell(:)); % 全局离子总数
            divertor_ion_count = 0; % 初始化偏滤器离子总数
            if ~isempty(index_div) % 如果偏滤器区域索引不为空，则计算偏滤器区域离子总数
                divertor_data = current_Ne_data_sliced(index_div, :); % 提取偏滤器区域的离子数据
                divertor_volcell = volcell(index_div, :); % 提取偏滤器区域的网格体积
                divertor_ion_count = sum(divertor_data(:) .* divertor_volcell(:)); % 偏滤器区域离子总数
            end
            divertor_percentage = (divertor_ion_count / global_ion_count) * 100; % 计算偏滤器离子数占全局离子数的百分比

            % 存储单价态离子统计数据
            ion_stats.ion_names{iIon} = sprintf('Ne^{%d+}', iIon); % 存储离子态名称，例如 Ne1+, Ne2+
            ion_stats.global_counts(iIon) = global_ion_count; % 存储全局离子总数
            ion_stats.divertor_counts(iIon) = divertor_ion_count; % 存储偏滤器区域离子总数
            ion_stats.divertor_percentages(iIon) = divertor_percentage; % 存储偏滤器占比

            total_global_ion_count_case = total_global_ion_count_case + global_ion_count; % 累加当前算例所有价态全局总数
            total_divertor_ion_count_case = total_divertor_ion_count_case + divertor_ion_count; % 累加当前算例所有价态偏滤器总数

            all_cases_global_counts(iDir, iIon) = global_ion_count; % 存储当前算例和离子态的全局离子数，用于绘制柱状图
            all_cases_divertor_counts(iDir, iIon) = divertor_ion_count; % 存储当前算例和离子态的偏滤器离子数，用于绘制柱状图


        end % end for iIon (单算例内离子态循环结束)

        % 计算各价态离子数占总离子数的百分比 (相对于当前算例的所有价态总数)
        for iIon = 1:num_ions
            ion_stats.global_total_percentage(iIon) = (ion_stats.global_counts(iIon) / total_global_ion_count_case) * 100; % 全局占比
            ion_stats.divertor_total_percentage(iIon) = (ion_stats.divertor_counts(iIon) / total_global_ion_count_case) * 100; % 偏滤器占比 (这里分母统一使用全局总数，方便比较)
        end

        % 保存当前算例的离子统计数据到结构体数组
        all_case_ion_stats{iDir} = ion_stats;

        % 输出离子统计数据到文本文件
        statsFilename = sprintf('NeIonStats_%d_%s.txt', iDir, timeSuffix); % 统计数据文件名，包含算例序号和时间后缀
        statsFullPath = fullfile(pwd, statsFilename); % 统计数据文件完整路径
        fid = fopen(statsFullPath, 'w'); % 打开文件准备写入
        fprintf(fid, 'Case: %s\n', dirName); % 写入算例目录名
        fprintf(fid, '----------------------------------------------------------------------------------------------------\n');
        fprintf(fid, '%-8s | %-15s | %-15s | %-20s | %-25s | %-25s\n', ...
                'Ion State', 'Global Count', 'Divertor Count', 'Divertor Percentage (%)', 'Global Total Percentage (%)', 'Divertor Total Percentage (%)'); % 写入表头
        fprintf(fid, '----------------------------------------------------------------------------------------------------\n');
        for iIon = 1:num_ions
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

        % ============== 第一个 Figure，绘制 iIon = 1~5 (Ne1+~Ne5+) 的分布云图 ==============
        fig1 = figure('Name', ['Ne Ion Distribution (Part 1): ', dirName], ...
                      'NumberTitle', 'off', ... % 窗口标题不显示编号
                      'Color', 'w', ... % 背景颜色白色
                      'Units', 'normalized', ... % 单位归一化
                      'Position', [0, 0, 1, 1]); % 全屏显示

        for iIon_plot = 1:5 % 注意这里循环变量改为了 iIon_plot，避免和外层数据计算循环混淆
            iIon = iIon_plot; % 保持 iIon 代表实际的离子态索引 (1-10)
            subplot(2, 3, iIon_plot); % 创建子图 (2行3列)

            current_Ne_data = radInfo.plasma.na(:,:,3 + iIon); % 获取原始数据，用于绘图
            surfplot(radInfo.gmtry, current_Ne_data); % 绘制曲面图
            shading interp; % 表面平滑处理
            view(2); % 俯视角度
            hold on; % 保留当前坐标轴和图形，允许绘制更多图形
            plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0); % 绘制分隔线
            colormap(jet); % 使用 jet 颜色映射
            colorbar; % 显示颜色bar
            caxis([all_Ne_min(iIon), all_Ne_max(iIon)]); % 使用全局统一 colorbar 范围

            set(gca, 'fontsize', 14); % 设置坐标轴字体大小
            xlabel('R (m)', 'fontsize', 14); % x 轴标签
            ylabel('Z (m)', 'fontsize', 14); % y 轴标签
            title(sprintf('Ne^{%d+} Density (m^{-3})', iIon), 'FontSize', 14); % 子图标题，显示离子态
            axis square; % 坐标轴长宽比设置为 1:1
            box on; % 显示坐标轴边框

            if domain ~= 0 % 如果用户选择了绘图区域范围 (domain ~= 0)
                switch domain
                    case 1 % domain = 1
                        xlim([1.30, 2.00]); % 限制 x 轴范围
                        ylim([0.50, 1.20]); % 限制 y 轴范围
                    case 2 % domain = 2
                        xlim([1.30, 2.05]); % 限制 x 轴范围
                        ylim([-1.15, -0.40]); % 限制 y 轴范围
                end
                plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2); % 绘制结构
            end
        end
        uicontrol('Style', 'text', ... % 在 Figure 上添加文本框
                  'String', ['Case: ', dirName, ' (Part 1)'], ... % 显示算例名和 part 编号
                  'Units', 'normalized', ... % 单位归一化
                  'FontSize', 10, ... % 字体大小
                  'BackgroundColor', 'w', ... % 背景颜色白色
                  'ForegroundColor', 'k', ... % 前景颜色黑色
                  'Position', [0.2 0.97 0.6 0.02], ... % 文本框位置
                  'Parent', fig1); % 文本框父对象为当前 Figure
        figFilename1 = sprintf('NeIonDist_%d_part1_%s.fig', iDir, timeSuffix); % 图片文件名，包含算例序号, part 编号和时间后缀
        figFullPath1 = fullfile(pwd, figFilename1); % 图片文件完整路径
        savefig(fig1, figFullPath1); % 保存 Figure 到文件
        fprintf('First Figure (Part 1) has been saved to: %s\n', figFullPath1); % 提示图片保存路径


        % ============== 第二个 Figure，绘制 iIon = 6~10 (Ne6+~Ne10+) 的分布云图 ==============
        fig2 = figure('Name', ['Ne Ion Distribution (Part 2): ', dirName], ...
                      'NumberTitle', 'off', ...
                      'Color', 'w', ...
                      'Units', 'normalized', ...
                      'Position', [0, 0, 1, 1]);

        for iIon_plot = 6:10
            iIon = iIon_plot;
            subplot(2, 3, iIon_plot - 5); % 注意这里子图编号为 iIon_plot - 5，从 1 开始

            current_Ne_data = radInfo.plasma.na(:,:,3 + iIon);
            surfplot(radInfo.gmtry, current_Ne_data);
            shading interp;
            view(2);
            hold on;
            plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
            colormap(jet);
            colorbar;
            caxis([all_Ne_min(iIon), all_Ne_max(iIon)]); % 使用全局统一 colorbar 范围

            set(gca, 'fontsize', 14);
            xlabel('R (m)', 'fontsize', 14);
            ylabel('Z (m)', 'fontsize', 14);
            title(sprintf('Ne^{%d+} Density (m^{-3})', iIon), 'FontSize', 14);
            axis square;
            box on;

            if domain ~= 0
                switch domain
                    case 1
                        xlim([1.30, 2.00]);
                        ylim([0.50, 1.20]);
                    case 2
                        xlim([1.30, 2.05]);
                        ylim([-1.15, -0.40]);
                end
                plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
            end
        end
        uicontrol('Style', 'text', ...
                  'String', ['Case: ', dirName, ' (Part 2)'], ...
                  'Units', 'normalized', ...
                  'FontSize', 10, ...
                  'BackgroundColor', 'w', ...
                  'ForegroundColor', 'k', ...
                  'Position', [0.2 0.97 0.6 0.02], ...
                  'Parent', fig2);
        figFilename2 = sprintf('NeIonDist_%d_part2_%s.fig', iDir, timeSuffix); % 图片文件名，包含算例序号, part 编号和时间后缀
        figFullPath2 = fullfile(pwd, figFilename2); % 图片文件完整路径
        savefig(fig2, figFullPath2); % 保存 Figure 到文件
        fprintf('Second Figure (Part 2) has been saved to: %s\n', figFullPath2); % 提示图片保存路径

        % ============== 第三个 Figure，绘制总杂质密度分布云图 ==============
        fig3 = figure('Name', ['Total Ne Impurity Density: ', dirName], ...
                      'NumberTitle', 'off', ...
                      'Color', 'w', ...
                      'Units', 'normalized', ...
                      'Position', [0, 0, 1, 1]);

        total_Ne_density = sum(radInfo.plasma.na(:,:,3:end), 3); % 重新计算总杂质密度，虽然之前计算过，这里为了代码结构更清晰
        surfplot(radInfo.gmtry, total_Ne_density);
        shading interp;
        view(2);
        hold on;
        plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
        colormap(jet);
        colorbar;
        caxis([all_total_Ne_min, all_total_Ne_max]); % 使用全局统一 colorbar 范围

        set(gca, 'fontsize', 14);
        xlabel('R (m)', 'fontsize', 14);
        ylabel('Z (m)', 'fontsize', 14);
        title('Total Ne Impurity Density (m^{-3})', 'FontSize', 14);
        axis square;
        box on;

        if domain ~= 0
            switch domain
                case 1
                    xlim([1.30, 2.00]);
                    ylim([0.50, 1.20]);
                case 2
                    xlim([1.30, 2.05]);
                    ylim([-1.15, -0.40]);
            end
            plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
        end

        uicontrol('Style', 'text', ...
                  'String', ['Case: ', dirName, ' (Total Ne Density)'], ...
                  'Units', 'normalized', ...
                  'FontSize', 10, ...
                  'BackgroundColor', 'w', ...
                  'ForegroundColor', 'k', ...
                  'Position', [0.2 0.97 0.6 0.02], ...
                  'Parent', fig3);
        figFilename3 = sprintf('NeTotalDensity_%d_%s.fig', iDir, timeSuffix);
        figFullPath3 = fullfile(pwd, figFilename3);
        savefig(fig3, figFullPath3);
        fprintf('Total Ne Density Figure has been saved to: %s\n', figFullPath3);


        % ============== 第四个 Figure，绘制离子统计百分比 (柱状图) ==============
        statsFigPercentage = figure('Name', ['Ne Ion Statistics Percentage: ', dirName], ...
                          'NumberTitle', 'off', ...
                          'Color', 'w', ...
                          'Units', 'normalized', ...
                          'Position', [0.2, 0.2, 0.6, 0.6]); % 窗口大小和位置

        bar_percent_groups = [ion_stats.global_total_percentage, ion_stats.divertor_total_percentage]; % 柱状图数据，全局和偏滤器占比
        bar_percent_chart = bar(bar_percent_groups); % 绘制柱状图
        set(gca, 'XTickLabel', ion_stats.ion_names); % 设置 x 轴刻度标签为离子态名称
        legend('Global Percentage', 'Divertor Percentage'); % 显示图例
        ylabel('Percentage (%)'); % y 轴标签
        title(['Ne Ion Percentage for Case: ', dirName]); % 图表标题
        set(gca, 'fontsize', 12); % 设置字体大小
        rotateXLabels(gca, 45); % 旋转 x 轴标签，避免重叠
        grid on; % 显示网格

        statsFigPercentageFilename = sprintf('NeIonStatsPercentage_%d_%s.fig', iDir, timeSuffix); % 图片文件名，包含算例序号和时间后缀
        statsFigPercentageFullPath = fullfile(pwd, statsFigPercentageFilename); % 图片文件完整路径
        savefig(statsFigPercentage, statsFigPercentageFullPath); % 保存 Figure 到文件
        fprintf('Ion statistics percentage figure has been saved to: %s\n', statsFigPercentageFullPath); % 提示图片保存路径


        % ============== 第五个 Figure，绘制离子总数统计 (柱状图) ==============
        statsFigCounts = figure('Name', ['Ne Ion Counts: ', dirName], ...
                          'NumberTitle', 'off', ...
                          'Color', 'w', ...
                          'Units', 'normalized', ...
                          'Position', [0.2, 0.2, 0.6, 0.6]); % 窗口大小和位置

        bar_counts_groups = [ion_stats.global_counts, ion_stats.divertor_counts];
        bar_counts_chart = bar(bar_counts_groups);
        set(gca, 'XTickLabel', ion_stats.ion_names);
        legend('Global Count', 'Divertor Count');
        ylabel('Ion Count');
        title(['Ne Ion Counts for Case: ', dirName]);
        set(gca, 'fontsize', 12);
        rotateXLabels(gca, 45);
        grid on;
        box on;

        statsFigCountsFilename = sprintf('NeIonStatsCountsBar_%d_%s.fig', iDir, timeSuffix); % 图片文件名，修改为 Bar
        statsFigCountsFullPath = fullfile(pwd, statsFigCountsFilename);
        savefig(statsFigCounts, statsFigCountsFullPath);
        fprintf('Ion statistics counts bar figure has been saved to: %s\n', statsFigCountsFullPath); % 提示图片保存路径


    end % end for iDir (所有算例图片绘制循环结束)


    %% 4) 绘制所有算例的离子总数变化趋势对比图 (柱状图)
    statsFigCountsCompare = figure('Name', ['Ne Ion Counts Comparison'], ...
                               'NumberTitle', 'off', ...
                               'Color', 'w', ...
                               'Units', 'normalized', ...
                               'Position', [0.2, 0.2, 0.7, 0.7]); % 窗口大小和位置，稍微调整宽度

    ion_names = all_case_ion_stats{1}.ion_names; % 获取离子名称，假设所有算例的离子名称相同
    x = 1:num_ions;
    bar_width = 0.8 / num_cases; % 设置柱状图宽度，根据算例数量调整，保证不重叠

    for iDir = 1:num_cases
        dirName = all_radiationData{iDir}.dirName;
        positions_global = x + (iDir - 1 - (num_cases - 1)/2) * bar_width; % 计算每个case的柱子位置，错开一些
        bar(positions_global, all_cases_global_counts(iDir, :), bar_width, 'DisplayName', [dirName, ' Global']);
        hold on;
        %positions_divertor = x + (iDir - 1 - (num_cases - 1)/2) * bar_width + bar_width/2; % Divertor 柱子稍微偏移，如果需要可以画在一起
        %bar(positions_divertor, all_cases_divertor_counts(iDir, :), bar_width/2, 'DisplayName', [dirName, ' Divertor'], 'FaceColor', get(gca, 'ColorOrderIndex')); % 使用相同的颜色
    end

    set(gca, 'XTick', x);
    set(gca, 'XTickLabel', ion_names);
    legend('Location', 'northwest');
    ylabel('Ion Count');
    xlabel('Ion State');
    title('Comparison of Ne Ion Counts Across Cases');
    set(gca, 'fontsize', 12);
    rotateXLabels(gca, 45);
    grid on;
    box on;
    xlim([0.5, num_ions + 0.5]); % 调整 x 轴范围，避免柱状图被裁剪

    statsFigCompareFilename = sprintf('NeIonStatsCountsCompareBar_%s.fig', timeSuffix); % 图片文件名，修改为 Bar
    statsFigCompareFullPath = fullfile(pwd, statsFigCompareFilename);
    savefig(statsFigCountsCompare, statsFigCompareFullPath);
    fprintf('Comparison figure of ion statistics counts (bar) has been saved to: %s\n', statsFigCompareFullPath);


end


function rotateXLabels(ax, angle)
    %Rotate X axis labels using built-in XTickLabelRotation
    set(ax, 'XTickLabelRotation', angle);
end