function Analyze_NeD_LineRadiation(all_radiationData, domain, use_global_clim)
    % =========================================================================
    % 功能：绘制每个算例中Ne离子各价态（1+~10+）的线辐射分布
    %       新增选项控制是否统一colorbar范围，绘图后自动保存 .fig 文件，并
    %       统计每个算例各价态的总线辐射强度并保存到CSV文件中。
    %       新增功能：
    %       1. 对比每个算例中线辐射和中性粒子辐射总强度的柱状图 (修改为只对比线辐射和中性粒子辐射)
    %       2. CSV文件中新增线、中性辐射总强度字段 (修改为只保留线、中性辐射总强度)
    %       3. 在各算例总线辐射强度对比柱状图中增加D+总线辐射强度柱
    %       4. 在各算例总线辐射强度对比柱状图中增加D原子总线辐射强度柱 (新增功能)
    %       5. 修正: 计算总辐射量时考虑网格体积，将辐射密度(W/m³)乘以体积得到功率(W)
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
    %       .linrad_ns       (m×n×13矩阵，第3维1:13对应D0, D+, Ne的0~10价态)
    %       .linrad_D        (m×n矩阵，D的线辐射) % 实际代码中未使用，linrad_ns(:,:,1:2)已包含D0, D+
    %       .linrad_Ne       (m×n矩阵，Ne的线辐射) % 实际代码中未使用，linrad_ns(:,:,3:13)已包含Ne0~10+
    %       .neurad_Ne       (m×n矩阵，Ne的中性粒子辐射)
    %       .volcell         (m×n矩阵，表示每个网格单元的体积)
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

                % 使用线辐射
                total_rad = radInfo.linrad_ns(:,:,layer);

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
        fig = figure('Name',  ['Ne Charge States Line Radiation: ', radInfo.dirName], ...
                    'NumberTitle', 'off', ...
                    'Color',      'w', ...
                    'Position',   [100 100 1200 1600]);

        % 添加总标题
        if exist('sgtitle', 'file') == 2
            sgtitle(['Ne Ion Line Radiation Distribution - ', radInfo.dirName], ...
                    'FontSize', 14, 'Interpreter', 'none');
        else
            axes('Position', [0.1 0.95 0.8 0.05], 'Visible', 'off');
            text(0.5, 0.5, ['Ne Ion Line Radiation Distribution - ', radInfo.dirName], ...
                'FontSize', 14, 'Interpreter', 'none', ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        end

        % 初始化存储该算例的数据表
        case_data = table();
        case_data.charge_state = (1:10)';
        case_data.total_radiation = zeros(10, 1);   % 总辐射（线辐射）
        case_data.linrad = zeros(10, 1);            % 线辐射分量

        % 遍历1~10价态
        for charge = 1:10
            layer = 3 + charge; % 第3维索引：4~13

            % 提取线辐射分量
            linrad = radInfo.linrad_ns(:,:,layer);
            total_rad = linrad; % 只使用线辐射

            % 记录各分量强度 - 乘以体积将辐射密度(W/m³)转换为功率(W)
            case_data.linrad(charge) = sum(sum(linrad .* radInfo.volcell));
            case_data.total_radiation(charge) = sum(sum(total_rad .* radInfo.volcell)); % 总辐射就是线辐射

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

            title(sprintf('Ne^{%d+} Line Radiation (W/m^3)', charge), 'FontSize', 12);
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
        figFilename = sprintf('NeLineRadiation_case%d_%s.fig', iDir, timeSuffix);
        savefig(fig, fullfile(pwd, figFilename));
        fprintf('Figure saved: %s\n', figFilename);

        %% 3.2) 计算并保存各辐射分量总强度
        % 计算线、中性辐射总强度（整个算例）- 考虑网格体积
        total_neurad = sum(sum(radInfo.neurad_Ne .* radInfo.volcell));   % 中性粒子辐射总和

        total_linrad = 0; % 重新计算总线辐射，包含Ne 1+~10+
        for charge = 1:10
            layer = 3 + charge;
            temp = radInfo.linrad_ns(:,:,layer);
            total_linrad = total_linrad + sum(sum(temp .* radInfo.volcell)); % 乘以体积计算总功率
        end

        % 将总强度添加到数据表
        case_data.total_linrad = repmat(total_linrad, 10, 1);
        case_data.total_neurad = repmat(total_neurad, 10, 1);
        case_data.dirName = repmat({radInfo.dirName}, 10, 1);

        all_case_data{iDir} = case_data;

        %% 3.3) 绘制各分量对比柱状图
        comp_fig = figure('Name', ['Ne Radiation Components: ', radInfo.dirName], ...
                        'NumberTitle', 'off', ...
                        'Color', 'w', ...
                        'Position', [200 200 600 400]);

        % 绘制柱状图
        components = [total_linrad, total_neurad];
        bar(components);
        xticklabels({'Line Radiation', 'Neutral Particle'});
        ylabel('Total Radiation (W)'); % 单位为 W
        title(['Ne Radiation Components - ', radInfo.dirName], 'Interpreter', 'none');
        grid on;

        % 保存对比图
        comp_filename = sprintf('NeRadiationComponents_case%d_%s.fig', iDir, timeSuffix);
        savefig(comp_fig, fullfile(pwd, comp_filename));
        fprintf('Component figure saved: %s\n', comp_filename);
    end

    %% 4) 合并数据并保存到CSV
    all_data_table = vertcat(all_case_data{:});
    output_filename = sprintf('NeLineRadiation_summary_%s.csv', timeSuffix);
    writetable(all_data_table, output_filename);
    fprintf('Radiation data saved to: %s\n', output_filename);

    %% 5) 绘制各算例总线辐射强度柱状图 (改进版)
    figure('Name', 'Total Line Radiation Comparison', 'Color', 'w', 'Position', [200 200 1200 700]);

    num_cases = length(all_radiationData);
    num_charges = 10;
    % 共有 12 种离子/原子种类：D0, Ne1+~Ne10+, D+
    species_count = num_charges + 2; 

    % 准备绘图数据
    bar_data = zeros(species_count, num_cases);
    case_names = cell(1, num_cases);

    for iDir = 1:num_cases
        radInfo = all_radiationData{iDir};
        case_data = all_case_data{iDir};
        
        % Ne 1+~10+ 数据放在第2到第11行
        bar_data(2:num_charges+1, iDir) = case_data.total_radiation;
        
        % D+ 数据放在最后一行
        D_plus_rad = radInfo.linrad_ns(:,:,2); % D+ 对应 linrad_ns 的第2层
        bar_data(species_count, iDir) = sum(sum(D_plus_rad .* radInfo.volcell)); % 乘以体积计算总功率
        
        % D0 数据放在第一行
        D_atom_rad = radInfo.linrad_ns(:,:,1); % D0 对应 linrad_ns 的第1层
        bar_data(1, iDir) = sum(sum(D_atom_rad .* radInfo.volcell)); % 乘以体积计算总功率
        
        case_names{iDir} = radInfo.dirName;
    end

    % 生成x轴位置
    x = 1:species_count;
    width = 0.8 / num_cases; % 柱宽度
    offset = linspace(-0.4 + width/2, 0.4 - width/2, num_cases); % 每组柱的偏移量

    % 创建分组柱状图
    hold on;
    for iCase = 1:num_cases
        % 为每个算例创建一组柱
        h(iCase) = bar(x + offset(iCase), bar_data(:,iCase), width);
        % 设置颜色，确保每个算例有不同颜色
        set(h(iCase), 'DisplayName', case_names{iCase});
    end
    hold off;

    % 设置图表属性
    title('Line Radiation Intensity for Each Species Across Cases', 'FontSize', 14);
    xlabel('Ion/Atom Species', 'FontSize', 12);
    ylabel('Line Radiation Intensity (W)', 'FontSize', 12);
    grid on;

    % 创建标签
    charge_labels = cell(1, species_count);
    charge_labels{1} = 'D^0';
    for i = 1:num_charges
        charge_labels{i+1} = sprintf('Ne^{%d+}', i);
    end
    charge_labels{species_count} = 'D^+';

    % 设置x轴刻度和标签
    set(gca, 'XTick', x, 'XTickLabel', charge_labels, 'XTickLabelRotation', 45, 'FontSize', 11);

    % 添加图例
    legend(h, 'Interpreter', 'none', 'Location', 'best');

    % 优化布局
    set(gcf, 'PaperPositionMode', 'auto');
    tight_layout = false;
    if exist('tight', 'file') == 2 && tight_layout
        tight;
    end

    % 保存柱状图
    barFigFilename = sprintf('Total_LineRadiation_Intensity_Bar_%s.fig', timeSuffix);
    savefig(fullfile(pwd, barFigFilename));
    fprintf('Bar figure saved: %s\n', barFigFilename);

    % 同时保存为PNG格式，方便查看
    print(gcf, '-dpng', '-r300', strrep(barFigFilename, '.fig', '.png'));
    fprintf('Bar figure also saved as PNG: %s\n', strrep(barFigFilename, '.fig', '.png'));

    %% 6) 提示色标使用情况
    if use_global_clim
        fprintf('\nColor ranges unified across all cases.\n');
    else
        fprintf('\nColor ranges adjusted individually for each case.\n');
    end
end