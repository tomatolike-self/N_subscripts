function plot_ne_radiation(all_radiationData, domain, use_global_clim)
    % =========================================================================
    % 功能：绘制每个算例中Ne离子各价态（1+~10+）的总辐射分布（线辐射+韧致辐射）
    %       新增选项控制是否统一colorbar范围，绘图后自动保存 .fig 文件，并
    %       统计每个算例各价态的总辐射强度并保存到CSV文件中。
    %       新增功能：
    %       1. 对比每个算例中线辐射、韧致辐射和中性粒子辐射总强度的柱状图
    %       2. CSV文件中新增线、韧致、中性辐射总强度字段
    %
    % 输入参数：
    %   all_radiationData  - 包含各算例辐射信息的 cell 数组
    %   domain             - 绘图区域范围 (0/1/2)
    %   use_global_clim    - 是否统一色标范围（true/false）
    %
    % 结构体要求：
    %   radInfo需包含以下字段：
    %       .dirName         (string)
    %       .gmtry           (网格几何信息)
    %       .structure       (真空室结构信息)
    %       .linrad_ns       (m×n×13矩阵，第3维3:13对应Ne的0~10价态)
    %       .brmrad_ns       (m×n×13矩阵，第3维3:13对应Ne的0~10价态)
    %       .linrad_D        (m×n矩阵，D的线辐射)
    %       .brmrad_D        (m×n矩阵，D的韧致辐射)
    %       .linrad_Ne       (m×n矩阵，Ne的线辐射)
    %       .brmrad_Ne       (m×n矩阵，Ne的韧致辐射)
    %       .neurad_Ne       (m×n矩阵，Ne的中性粒子辐射)
    % =========================================================================

    %% 0) 参数检查
    if nargin < 3
        use_global_clim = true; % 默认启用统一色标
    end

    %% 1) 计算全局color范围（如果启用）
    if use_global_clim
        % 初始化存储各价态全局极值的数组（1~10价对应索引1~10）
        global_min = inf(1, 10);
        global_max = -inf(1, 10);

        % 遍历所有算例和价态
        for iDir = 1:length(all_radiationData)
            radInfo = all_radiationData{iDir};

            % 遍历1~10价（对应linrad_ns的4~13层）
            for charge = 1:10
                layer = 3 + charge; % 第3维索引：4~13

                % 计算总辐射（线+韧致）
                total_rad = radInfo.linrad_ns(:,:,layer) + ...
                            radInfo.brmrad_ns(:,:,layer);

                % 更新全局极值
                current_min = min(total_rad(:));
                current_max = max(total_rad(:));

                if current_min < global_min(charge)
                    global_min(charge) = current_min;
                end
                if current_max > global_max(charge)
                    global_max(charge) = current_max;
                end
            end
        end
    end

    %% 2) 生成时间戳用于文件名
    timeSuffix = datestr(now,'yyyymmdd_HHMMSS');

    %% 3) 逐个算例处理：绘制价态分布、统计辐射强度
    all_case_data = {}; % 用于保存所有算例的辐射数据
    for iDir = 1:length(all_radiationData)
        radInfo = all_radiationData{iDir};

        %% 3.1) 绘制各价态辐射分布图
        fig = figure('Name',  ['Ne Charge States: ', radInfo.dirName], ...
                    'NumberTitle', 'off', ...
                    'Color',      'w', ...
                    'Position',   [100 100 1200 1600]);

        % 添加总标题
        if exist('sgtitle', 'file') == 2
            sgtitle(['Ne Ion Radiation Distribution - ', radInfo.dirName], ...
                    'FontSize', 14, 'Interpreter', 'none');
        else
            axes('Position', [0.1 0.95 0.8 0.05], 'Visible', 'off');
            text(0.5, 0.5, ['Ne Ion Radiation Distribution - ', radInfo.dirName], ...
                'FontSize', 14, 'Interpreter', 'none', ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        end

        % 初始化存储该算例的数据表
        case_data = table();
        case_data.charge_state = (1:10)';
        case_data.total_radiation = zeros(10, 1);   % 总辐射（线+韧致）
        case_data.linrad = zeros(10, 1);            % 线辐射分量
        case_data.brmrad = zeros(10, 1);            % 韧致辐射分量

        % 遍历1~10价态
        for charge = 1:10
            layer = 3 + charge; % 第3维索引：4~13

            % 提取辐射分量
            linrad = radInfo.linrad_ns(:,:,layer);
            brmrad = radInfo.brmrad_ns(:,:,layer);
            total_rad = linrad + brmrad;

            % 记录各分量强度
            case_data.linrad(charge) = sum(linrad(:));
            case_data.brmrad(charge) = sum(brmrad(:));
            case_data.total_radiation(charge) = sum(total_rad(:));

            % 绘制分布图
            subplot(5, 2, charge);
            surfplot(radInfo.gmtry, total_rad);
            shading interp; view(2); hold on;

            plot3sep(radInfo.gmtry, 'color', 'w', 'LineStyle', '--', 'LineWidth', 1.0);
            if domain ~= 0
                plotstructure(radInfo.structure, 'color', 'k', 'LineWidth', 2);
            end

            colormap(jet);
            cb = colorbar;
            if use_global_clim
                caxis([global_min(charge), global_max(charge)]);
            else
                caxis([min(total_rad(:)), max(total_rad(:))]);
            end

            title(sprintf('Ne^{%d+} Radiation (W/m^3)', charge), 'FontSize', 12);
            set(gca, 'FontSize', 10, 'Box', 'on');
            axis square;

            % 设置显示范围
            if domain ~= 0
                if domain == 1       % 上偏滤器
                    xlim([1.30, 2.00]); ylim([0.50, 1.20]);
                elseif domain == 2  % 下偏滤器
                    xlim([1.30, 2.05]); ylim([-1.15, -0.40]);
                end
            end
        end

        % 保存分布图
        figFilename = sprintf('NeRadiation_case%d_%s.fig', iDir, timeSuffix);
        savefig(fig, fullfile(pwd, figFilename));
        fprintf('Figure saved: %s\n', figFilename);
        % close(fig); % 关闭图形释放内存  <--- 注释掉此行，不自动关闭 figure

        %% 3.2) 计算并保存各辐射分量总强度
        % 计算线、韧致、中性辐射总强度（整个算例）
        total_linrad = sum(radInfo.linrad_Ne(:));   % 所有价态线辐射总和
        total_brmrad = sum(radInfo.brmrad_Ne(:));   % 所有价态韧致辐射总和
        total_neurad = sum(radInfo.neurad_Ne(:));   % 中性粒子辐射总和

        % 将总强度添加到数据表
        case_data.total_linrad = repmat(total_linrad, 10, 1);
        case_data.total_brmrad = repmat(total_brmrad, 10, 1);
        case_data.total_neurad = repmat(total_neurad, 10, 1);
        case_data.dirName = repmat({radInfo.dirName}, 10, 1);

        all_case_data{iDir} = case_data;

        %% 3.3) 绘制各分量对比柱状图
        comp_fig = figure('Name', ['Ne Radiation Components: ', radInfo.dirName], ...
                        'NumberTitle', 'off', ...
                        'Color', 'w', ...
                        'Position', [200 200 600 400]);

        % 绘制柱状图
        components = [total_linrad, total_brmrad, total_neurad];
        bar(components);
        xticklabels({'Line Radiation', 'Bremsstrahlung', 'Neutral Particle'});
        ylabel('Total Radiation (W/m^3)');
        title(['Ne Radiation Components - ', radInfo.dirName], 'Interpreter', 'none');
        grid on;

        % 保存对比图
        comp_filename = sprintf('NeRadiationComponents_case%d_%s.fig', iDir, timeSuffix);
        savefig(comp_fig, fullfile(pwd, comp_filename));
        fprintf('Component figure saved: %s\n', comp_filename);
        % close(comp_fig); % 关闭对比图  <--- 注释掉此行，不自动关闭 figure
    end

    %% 4) 合并数据并保存到CSV
    all_data_table = vertcat(all_case_data{:});
    output_filename = sprintf('NeRadiation_summary_%s.csv', timeSuffix);
    writetable(all_data_table, output_filename);
    fprintf('Radiation data saved to: %s\n', output_filename);

    %% 5) 绘制各算例总辐射强度折线图
    figure('Name', 'Total Radiation Comparison', 'Color', 'w');
    hold on;
    legend_labels = cell(length(all_radiationData),1);
    for iDir = 1:length(all_case_data)
        case_data = all_case_data{iDir};
        plot(case_data.charge_state, case_data.total_radiation, '-o', ...
            'DisplayName', all_radiationData{iDir}.dirName);
        legend_labels{iDir} = all_radiationData{iDir}.dirName;
    end
    title('Total Radiation Intensity for Each Charge State');
    xlabel('Charge State (+)');
    ylabel('Total Radiation Intensity (W/m^3)');
    legend(legend_labels, 'Interpreter', 'none', 'Location', 'best');
    grid on;

    % 保存折线图
    lineFigFilename = sprintf('Total_Radiation_Intensity_Line_%s.fig', timeSuffix);
    savefig(fullfile(pwd, lineFigFilename));
    fprintf('Line figure saved: %s\n', lineFigFilename);

    %% 6) 提示色标使用情况
    if use_global_clim
        fprintf('\nColor ranges unified across all cases.\n');
    else
        fprintf('\nColor ranges adjusted individually for each case.\n');
    end
end